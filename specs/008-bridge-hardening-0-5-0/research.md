# Research: Bridge Hardening & 0.5.0 Cleanup

**Phase 0 output for** [plan.md](./plan.md). Resolves R1-R6 raised in the plan's "Open research items" section, plus 2 bonus items that surfaced during research.

## R1 — Position of state-summary print in `update-handoff.{ps1,sh}`

**Decision**: Print state summary AFTER successful JSON write + event-log append. If the operation fails mid-stream, the existing error handler runs and the summary is NOT printed.

**Rationale**: A summary printed before the write would report what the operation INTENDED to do but not what it ACTUALLY did. If the write fails (e.g., file-lock contention), the user sees a summary that misrepresents on-disk truth. Printing after the write guarantees the summary reflects committed state. The `try { ... } catch { ... }` chain in PS / `set -e` in bash naturally short-circuits the print on failure.

**Alternatives considered**:
- Print BEFORE write: rejected (see above).
- Print TWICE (before + after, with `[planned]` / `[committed]` prefixes): rejected as noisy. The bridge prints already-verbose output; doubling it defeats the "first 20 lines visibility" target in SC-001.
- Print on exit via PowerShell `END { ... }` block: PS-only construct, no clean bash equivalent. Rejected for cross-flavor parity (Constitution Principle III).

## R2 — Regex parity between PowerShell and bash for FR-005 header pattern

**Decision**: Use the regex `^#+[[:space:]]+.*\b(deferred|optional|out of scope|won.?t do|future|wontfix|backlog)\b` with case-insensitive matching. In PowerShell use `-imatch` (case-insensitive `-match`). In bash use `grep -Ei`. Both engines accept POSIX ERE `\b` word boundary and POSIX character class `[[:space:]]`.

**Rationale**:
- PowerShell .NET regex supports POSIX-style word boundaries (`\b`) directly; `-imatch` handles case insensitivity without extra flags.
- `grep -E` (POSIX ERE) supports `\b` and `[[:space:]]`. `grep -Ei` adds case insensitivity.
- The pattern is identical bytes between the two engines, eliminating the most common source of cross-flavor bugs (regex dialect drift).

**Validation**: A fixture file `tests/fixtures/sample-deferred-sections.md` (created in Phase A) contains all 7 header variants. The Phase A test runs both flavors against the fixture and asserts identical hit counts.

**Alternatives considered**:
- Use Perl-compatible regex via `pcregrep` or PS `[regex]::IsMatch`: rejected because the simple POSIX subset suffices.
- Use a pre-compiled engine in each language: rejected as over-engineering — header detection runs O(headers) per file, ~30 headers max per tasks.md, negligible cost.

## R3 — PowerShell pending-count scanning method

**Decision**: Use `Get-Content -LiteralPath $tasksPath` (which streams lines) piped into a `foreach`-loop that tracks the current section and emits one count value at end. Avoid `Select-String -Pattern` because it does not preserve the line-order context needed for "is this line under a deferred section?".

**Rationale**:
- `Get-Content` returns an array of strings; on a 300-line tasks.md it's ~1 ms.
- A single-pass scan with a `$inExemptSection` boolean flag is the simplest data structure that satisfies FR-001 + FR-005 together.
- `Select-String` only matches per line; tracking section state across lines would require post-processing, doubling the work.
- The whole counter operation measures < 5 ms on a 300-line file (estimated; will be confirmed in Phase A tests with `Measure-Command`).

**Implementation sketch** (PowerShell pseudo-code, real version in `bridge-state.ps1`):

```powershell
$lines = Get-Content -LiteralPath $tasksPath -ErrorAction SilentlyContinue
$inExempt = $false
$pending = 0
foreach ($line in $lines) {
    if ($line -match '^#+[[:space:]]+') {
        $inExempt = ($line -imatch '\b(deferred|optional|out of scope|won.?t do|future|wontfix|backlog)\b')
    } elseif (-not $inExempt -and $line -match '^- \[ \] T\d+') {
        $pending++
    }
}
```

**Alternatives considered**:
- `[System.IO.File]::ReadAllLines()`: faster but requires Windows .NET path; for our 50ms budget the cost is invisible. Rejected for negligible benefit + reduced readability.
- `Get-Content -Raw` + `.Split("`n")`: roughly equivalent; the streaming pipeline form is more idiomatic for PS scripts in this repo.

## R4 — bash pending-count scanning method

**Decision**: Use `awk` for the section-aware scan. Single pass, native regex, no jq dependency for this counter.

**Rationale**:
- `awk` supports the POSIX ERE regex (matching R2). One process invocation per file scan.
- A pure-`grep` two-pass approach would require either `grep -n` + post-processing in shell (fragile) or `grep --before-context` (doesn't generalize to "between this header and the next sibling header").
- `awk` is universally available on Linux + macOS + WSL (busybox awk also supports the subset we need).

**Implementation sketch** (`bridge-state.sh`):

```bash
awk '
  BEGIN { in_exempt = 0; pending = 0; IGNORECASE = 1 }
  /^#+[[:space:]]+/ {
    if ($0 ~ /\b(deferred|optional|out of scope|won.?t do|future|wontfix|backlog)\b/) in_exempt = 1
    else in_exempt = 0
    next
  }
  !in_exempt && /^- \[ \] T[0-9]+/ { pending++ }
  END { print pending }
' "$tasksPath"
```

Note: `gawk`'s `IGNORECASE=1` is the cleanest approach; for POSIX awk compatibility we may need to lowercase the line in the comparison instead. Phase A will test this against `busybox awk` to confirm portability. If `gawk` is required, fall back to a portable form using `tolower()`.

**Alternatives considered**:
- `grep -c '^- \[ \] T[0-9]\+'` plus a header-stripping prefilter: rejected — multi-pass + temp files complicates failure modes.
- `sed` state machine: less readable than awk for this case. Rejected.

## R5 — Upstream catalog-update flow research

**Research targets** (to execute in Phase C — research is part of US3 work, not pre-empted here):
1. `https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md` — search for "extension submission", "update", "version bump", "catalog".
2. `https://github.com/github/spec-kit/blob/main/docs/community/extensions.md` — header sections describing how the table is maintained.
3. `https://github.com/github/spec-kit/pull/2586` — full discussion thread for any maintainer comment establishing precedent on re-bumps.
4. `https://github.com/github/spec-kit/issues?q=is%3Aissue+catalog+update` — open + closed issues mentioning catalog updates.
5. Search closed PRs touching `extensions/catalog.community.json` for the merge pattern (issue → maintainer commits → close, vs PR → squash → close).

**Expected finding** (hypothesis, to confirm):
The upstream policy is **one "Extension Submission" issue per release**, with the maintainer applying the bump as a commit on their side. No automated path. The `stable-alias` URL added in our v0.4.3 is the user-facing escape hatch.

**Decision impact**:
- If hypothesis confirmed → adopt Clarifications Q5=C policy (minor/major only). Document the upstream URL + the policy in `marketplace/README.md`.
- If hypothesis disproved (an automated path exists) → adopt that lighter path; record citation.
- If upstream silent → fall back to Q5=C (default-by-clarification).

**Deliverable**: A 1-3 line citation in `marketplace/README.md` dated 2026-05-16 with a permalink to the source.

## R6 — PR #2586 thread review

**Decision**: Read once, in Phase C, before filing the v0.5.0 catalog-update issue. Capture (a) the maintainer's name/handle for the v0.4.1 acceptance, (b) any procedural comment that constrains how the v0.5.0 issue should be filed (template, labels, body shape), (c) the SHA of the upstream commit that landed v0.4.1.

**Rationale**: Filing v0.5.0 in the form maintainer expects increases acceptance speed and avoids the rework that surfaced during the v0.4.3 issue.

## R7 (bonus) — Test infrastructure: new file vs extend existing

**Decision**: New file `tests/test-bridge-state-summary.ps1`. Drive both PS and bash flavors via the v0.4.2 B2 path-translation strategy chain. Reuse `tests/test-handoff-shape.ps1`'s fixture-setup helpers if they are reusable; otherwise inline a small fixture builder.

**Rationale**:
- The new tests address a distinct concern (state summary correctness, pending count, warning emission). Co-locating them in `test-handoff-shape.ps1` would mix concerns and make either test harder to read.
- Three existing test files are byte-frozen since v0.4.2; adding a fourth file aligns with the pattern: one concern per file.
- New file makes the v0.5.0 diff trivial to audit (one new file under `tests/`).

**Alternative considered**:
- Extend `test-handoff-shape.ps1`: rejected because handoff-shape tests SHAPE invariants (JSON schema); state-summary tests OUTPUT contracts (printed lines, regex matches). Different concern.

## R8 (bonus) — Gate-evidence file shape (FR-008)

**Decision**: Append a `## Gate evidence` H2 subsection inside `specs/007-catalog-distribution-polish/verification.md`, right after the existing `## v0.4.3` table. Single file, single concern (verification of one release cycle).

**Schema**:

```markdown
## Gate evidence

| Gate | Computed value | Notes |
|---|---|---|
| SC-005 (byte-freeze) | 0 lines diff | `git diff v0.4.2..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/` |
| SC-006 (spec-history checksum) | `<sha256>` | `git ls-tree -r HEAD specs/001-* specs/002-* specs/004-* specs/005-* specs/006-* \| sort \| git hash-object --stdin`; equals value at v0.4.1 tag |
| Date / Operator | 2026-05-16 / claude | |
```

**Rationale**: One verification.md per release dir keeps every gate-record co-located with the release it audits. A sibling file (e.g., `gate-evidence.md`) would split related records across files for no auditing benefit.

**Alternative considered**:
- Standalone `gate-evidence.md` sibling file: rejected — splits the audit narrative across files; readers tracking a release would need to open two files.
- Inline into the existing v0.4.3 table as a new column: rejected — the table is per-platform (Windows/Linux/macOS); gate evidence is per-release. Different axis.

## Summary

| ID | Topic | Outcome |
|---|---|---|
| R1 | Summary print position | After successful write |
| R2 | Regex parity | POSIX ERE `\b` + `[[:space:]]`, `-imatch` / `grep -Ei` |
| R3 | PS scanning method | `Get-Content` + single-pass `foreach` with `$inExempt` flag |
| R4 | bash scanning method | `awk` with `IGNORECASE=1` (fallback `tolower()` if needed) |
| R5 | Upstream catalog flow | Research in Phase C; expected: one issue per release |
| R6 | PR #2586 review | Read once in Phase C before filing v0.5.0 issue |
| R7 | Test file location | New `tests/test-bridge-state-summary.ps1` |
| R8 | Gate-evidence shape | `## Gate evidence` subsection inside 007 `verification.md` |

All NEEDS CLARIFICATION items from the plan's Phase 0 are resolved. Phase 1 (data-model, contracts, quickstart) may proceed.
