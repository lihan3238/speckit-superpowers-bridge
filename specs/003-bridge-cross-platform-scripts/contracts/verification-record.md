# Verification Record Contract

**Feature**: 003-bridge-cross-platform-scripts (v0.4.2 cycle)
**File governed**: `specs/003-bridge-cross-platform-scripts/verification.md`
**Purpose**: Pin the row schema so future releases append uniformly.

This contract is markdown-based, not JSON Schema, because:

1. The verification record is human-driven and human-read.
2. A markdown table with fixed columns is self-validating to anyone reading it.
3. A formal JSON validator adds tool weight that the constitution gate doesn't justify.

---

## File structure

```markdown
# Verification Records

> Constitution v1.2.0 §"End-User Verification Sandbox" gate. Each release that
> publishes an artifact appends one `## <version>` section here recording the
> sandbox-install verification across required platforms.

## v<X.Y.Z>

| Platform | bridge_sha256 | Date (UTC) | Operator | Result | Notes |
|---|---|---|---|---|---|
| <platform-tag> | <hash> | <YYYY-MM-DD> | <operator> | <result> | <≤200 chars> |
| ... | ... | ... | ... | ... | ... |

## v<X.Y.Z-1>
...
```

Newest release section appears FIRST (top of file, just under the H1 + intro).

---

## Field reference

### `Platform` (enum)

Exactly one of:

- `windows-powershell` — Spec Kit initialized with `--script ps`; PowerShell ≥ 5.1 active.
- `wsl-linux-bash` — Spec Kit initialized with `--script sh` inside WSL on Windows; bash flavor active.
- `linux-native-bash` — Spec Kit on a native Linux host (Ubuntu/Debian/Fedora container, real VM, or hardware).
- `macos-bash` — Spec Kit on macOS host with Homebrew bash ≥ 4.0.

Per spec FR-008 + Clarifications Q3, v0.4.2 requires PASS rows for `windows-powershell` and `wsl-linux-bash`; `macos-bash` is `PENDING` per Q3.

### `bridge_sha256` (string, lowercase hex)

The SHA256 of the release asset ZIP installed in the sandbox for that platform's run. MUST equal what the workflow step summary reported for the release. Recipe:

- From the workflow Step Summary: copy the SHA256 line.
- From a local download: `Get-FileHash <zip> -Algorithm SHA256` (PowerShell) or `sha256sum <zip>` (bash).
- From the GitHub release page: `gh release view v<X.Y.Z> --json assets` does NOT expose the SHA — fetch the file and hash locally.

If two platform rows in the same release section have different `bridge_sha256` values, that is a bug — the same release MUST install identically across platforms.

### `Date (UTC)` (ISO 8601 date)

`YYYY-MM-DD` format only (no time component). Multiple runs on the same day for the same platform append a new row (don't overwrite); the table grows.

### `Operator` (enum)

Exactly one of:

- `claude` — Claude Code agent drove the verification (typically via this skill or `superpowers:executing-plans`).
- `codex` — Codex agent drove the verification.
- `human` — User drove the verification manually.

Recorded for accountability, not for automated dispatch.

### `Result` (enum)

Exactly one of:

- `PASS` — full bridge cycle completed end-to-end without operator intervention beyond the documented procedure. Acceptance scenarios 1–4 of US4 in spec.md ALL met.
- `FAIL` — any acceptance scenario failed. Notes column MUST cite the failing scenario number. Release that has any required-platform FAIL has its handoff transitioned to `blocked`.
- `PENDING` — platform exists but verification not yet run (e.g., macOS for v0.4.2 — no hardware). MUST be replaced by `PASS` / `FAIL` once the run happens. Does not block the release.
- `SKIPPED` — explicitly out of scope for this release (e.g., a release that's PS-only and macOS doesn't apply). Notes column MUST cite the scope decision.

### `Notes` (free text, ≤ 200 chars)

Free-form observations. Common patterns:

- For PASS: brief sanity line like "full cycle clean" or "after jq install".
- For FAIL: scenario number + symptom, e.g., "scenario 2: handoff JSON missing `source_of_truth`".
- For PENDING: "no host" / "deferred to vX.Y.Z+1".
- For SKIPPED: "n/a — PS-only release".

If observations exceed 200 chars, write a brief summary in Notes and add a follow-up `### Detail: v<X.Y.Z> <platform>` subsection below the table with the full narrative.

---

## Lifecycle rules

1. **Creation**: First release verified populates the file. v0.4.2 is that release for this repo.
2. **Append-only**: New release sections go at the top, under the H1+intro and before any prior `## <version>` section.
3. **In-place edits allowed for**: `PENDING` → `PASS` / `FAIL` after the run happens; Notes refinement; typo fixes.
4. **In-place edits FORBIDDEN for**: changing a `PASS` to `FAIL` retroactively (cut a new release row instead), changing `bridge_sha256` after recording (would imply rebuild — non-deterministic, forbidden by [[speckit-extension-release-strategy]]).
5. **Cross-link to release tags**: each `## v<X.Y.Z>` heading is a human bookmark; no anchor automation required.

---

## Validation (during release verification, not at commit time)

Spec FR-008 SC-005 verification:

- Open `verification.md`; find the `## v<X.Y.Z>` section.
- Confirm row count ≥ required platform count for this release class:
  - Patch / minor / major releases: Windows PS + at least one of {WSL Linux, native Linux, macOS} = at least 2 PASS rows.
  - macOS row MAY be `PENDING` if hardware unavailable (current state for v0.4.2 per Clarifications Q3).
- Confirm all `bridge_sha256` values in the section match each other (single release, single asset).
- Confirm all `Result` values are `PASS` or acceptable `PENDING`. Any `FAIL` MUST be resolved (handoff blocked, follow-up release) before the section is considered closed.

---

## Future evolution

If a future release adds a new supported platform (e.g., FreeBSD bash, Alpine Linux, ARM-native macOS, …):

- This contract gains a new entry in the `Platform` enum.
- Every prior `## v<X.Y.Z>` section MAY back-fill a `PENDING` row for the new platform OR be left as-is. Honest "we didn't yet support this back then" is fine.

If the constitution gate is later automated (e.g., a workflow job that runs the sandbox in containers):

- This contract stays the source of truth for the format.
- The automation writes rows programmatically using the same schema.
- The `Operator` field gains a `ci` value.
