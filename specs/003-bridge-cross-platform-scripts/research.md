# Phase 0 Research: Bridge Cross-Platform Scripts

**Feature**: 003-bridge-cross-platform-scripts
**Date**: 2026-05-15

The Clarifications session in `spec.md` already resolved 6 high-level decisions (single-ZIP, init-options dispatch, tools schema, line endings, no flock, test auto-detect). This document captures the remaining implementation-level decisions surfaced while reading the existing 4 PS scripts and mapping each PS construct to a bash equivalent.

## R1 — JSON read/write in bash via `jq`

**Decision**: Use `jq` exclusively for handoff JSON I/O. No hand-rolled parsing. Read with `jq -r '.field'`; write with `jq` building from CLI args into a single object, then `> tempfile && mv tempfile $target` for atomicity.

**Rationale**:
- `jq` is already an established Spec Kit ecosystem dep (used by `.specify/extensions/git/scripts/bash/create-new-feature.sh`).
- The v1 handoff schema has nested `source_of_truth` + arrays (`capabilities`, `review_only_agents`, `supersedes`) — hand-rolled bash parsing would be fragile.
- Marked `required: false` in `extension.yml.requires.tools` (per Clarifications) so Windows users do not see false prereq; Linux/macOS users install it via `apt`/`brew`/`dnf`.

**Alternatives considered**:
- Pure bash with grep/sed: rejected (escaping nightmare for JSON string values; nested object handling is intractable).
- Python: rejected (heavier dep than `jq` and overkill for ~10 fields).

**Concrete jq patterns**:

```bash
# Read a single field
status=$(jq -r '.status // empty' "$handoff_path")

# Read a nested field (with default)
prior_dir=$(jq -r '.feature_directory // empty' "$handoff_path")

# Write a fresh document
jq -n \
  --arg version "1" \
  --arg ts "$timestamp" \
  --arg dir "$feature_dir" \
  --arg status "$status" \
  --arg owner "$artifact_owner" \
  '{
    schema_version: ($version | tonumber),
    updated_at: $ts,
    feature_directory: $dir,
    source_of_truth: { ... },
    status: $status,
    artifact_owner: $owner,
    ...
  }' > "$handoff_path.tmp" && mv "$handoff_path.tmp" "$handoff_path"
```

The atomic temp-then-rename pattern is light insurance against partial writes if the script is killed mid-write.

---

## R2 — Snapshot timestamp format parity

**Decision**: Use `date -u +"%Y%m%dT%H%M%S%3NZ"` for snapshot directory names, matching the PowerShell `ToString("yyyyMMddTHHmmssfffffffZ")` format **truncated to milliseconds**. Bash version uses 3-digit fractional seconds (`%3N`); PS uses 7-digit (100-nanosecond ticks).

**Rationale**:
- Snapshot directory names need to be unique per invocation and sortable. Both 3-digit ms and 7-digit ticks satisfy this.
- `%N` is GNU `date` (Linux). On macOS the BSD `date` lacks `%N` — but `coreutils` from Homebrew installs `gdate`. Since we already require `bash >= 4.0` (Homebrew on macOS), recommending `gdate` aliased to `date` is reasonable for macOS.
- Alternative: use the bash `EPOCHREALTIME` builtin (bash 5.0+) which gives microsecond precision portably. Trade-off: requires bash 5.0+, not 4.0+.

**Concrete format**:

```bash
# Linux GNU date, or macOS with `brew install coreutils && alias date=gdate`
ts=$(date -u +"%Y%m%dT%H%M%S%3NZ")

# Fallback for stock macOS bash 3.2 / BSD date — NOT supported, but a defensive
# message tells the user to install coreutils.
```

**Cross-flavor consequence**: PS produces e.g. `20260515T1234567890123Z-executing`; bash produces `20260515T123456789Z-executing`. Both are sortable; both are valid directory names. The handoff `last_snapshot_id` field stores whatever the writer produced. Readers don't parse it back — they only compare for equality.

**Alternatives considered**:
- Drop fractional seconds entirely (seconds-only): rejected — collision risk if two invocations happen in the same second (e.g., test loop).
- Pure bash `printf "%(...)T" -1` + `$EPOCHREALTIME`: requires bash 5.0+; rejected because bash 4.0 is the floor.

---

## R3 — Repo root + project path discovery

**Decision**: Use `git rev-parse --show-toplevel` first; if `git` is unavailable or the cwd is not in a git repo, fall back to `pwd`. Match the PS `Get-RepoRoot` helper behavior exactly.

**Rationale**: Already proven on PS side. Bash equivalent is a 3-line function:

```bash
get_repo_root() {
    local root
    if command -v git >/dev/null 2>&1; then
        root=$(git rev-parse --show-toplevel 2>/dev/null) || true
        if [ -n "$root" ]; then printf '%s\n' "$root"; return; fi
    fi
    pwd
}
```

For `Convert-ToProjectPath` (PS helper that normalizes absolute paths to repo-relative forward-slash form), bash equivalent uses `realpath --relative-to` (Linux) or `python3 -c` fallback. **Decision**: assume `realpath` from coreutils is available — it's standard on Linux and on macOS with Homebrew. Document the dep.

---

## R4 — Argument parsing (long-flag style)

**Decision**: Manual `case` loop in each bash script for long-flag parsing. NO `getopt` (GNU only, incompatible across distros) and NO `getopts` (POSIX, single-char only).

**Rationale**:
- Long flags (`--status`, `--feature-directory`, etc.) match the FR-009 mapping table for parity with PS `-Status`, `-FeatureDirectory`.
- A `case` loop is portable across all bash 4+ implementations.
- ~10 lines per script — short and obvious.

**Template** (every bash script starts with):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse long flags
STATUS=""
FEATURE_DIRECTORY=""
REASON=""
ACTOR=""
CLEAR_FEATURE_DIRECTORY=false
# ... other vars

while [ $# -gt 0 ]; do
    case "$1" in
        --status)               STATUS="$2"; shift 2 ;;
        --feature-directory)    FEATURE_DIRECTORY="$2"; shift 2 ;;
        --reason)               REASON="$2"; shift 2 ;;
        --actor)                ACTOR="$2"; shift 2 ;;
        --clear-feature-directory) CLEAR_FEATURE_DIRECTORY=true; shift ;;
        # ...
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done
```

**Alternatives considered**:
- Reuse a single arg-parser function from `common-actor-resolution.sh`: rejected — adds source/include complexity for marginal LOC savings. Each script's arg parsing is short and self-evident.

---

## R5 — Actor resolution (common-actor-resolution.sh)

**Decision**: Sibling helper script dot-sourced by the other three. Defines `resolve_bridge_actor` and `get_repo_root` functions. Mirrors the PS pattern exactly (same name, same 3-step chain: explicit → env → "unknown").

**Rationale**: Three callers; DRY beats inlining. Same convention as the PS side (which dot-sources `common-actor-resolution.ps1`).

**Contract**:

```bash
# Source it
. "$(dirname "$0")/common-actor-resolution.sh"

# Call it
ACTOR=$(resolve_bridge_actor "$ACTOR")
REPO_ROOT=$(get_repo_root)
```

**File size**: ~25 lines (vs PS's 41).

---

## R6 — Append to `bridge-events.jsonl`

**Decision**: Plain `printf '%s\n' "$line" >> "$path"`. NO `flock`, NO atomic-temp-rename. Mirrors PS's `Add-Content -Encoding UTF8`.

**Rationale**: Per Clarifications, bash must mirror PS's robustness — not exceed it. "只做兼容、不增功能."

**UTF-8 + no-BOM**: bash's stdout/stdin is byte-oriented; `printf` writes raw bytes. The bash flavor naturally produces no-BOM UTF-8, matching what PS *should* do (PS 5.1's default `Add-Content -Encoding UTF8` actually writes BOM; PS 7 + `utf8NoBOM` is what current PS scripts use). Bash and PS-7 produce identical bytes when both invoke the no-BOM path.

The event JSON is one line, compactly formatted via `jq -c`.

---

## R7 — Atomic-ish write for `superpowers-handoff.json`

**Decision**: Use `tempfile + mv` atomic-rename for the handoff JSON write. PS does not currently use atomic-rename — but `mv` is essentially free in bash and avoids partial-file corruption if the script is killed mid-write. This is NOT a behavior-improvement over PS — it's a safety net during normal operation.

Wait — this could be seen as "improving beyond PS" and violating compat-only. Let me reconsider. Looking at PS's `update-handoff.ps1` line 191: `$handoff | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $handoffPath -Encoding UTF8`. `Set-Content` is NOT atomic in PowerShell either — it writes through a file handle, can leave partial state if killed mid-write.

**Revised decision**: Match PS exactly. Bash writes directly to the target file via `> "$handoff_path"` (single jq pipeline output redirect). No temp-then-rename. Equivalent failure mode to PS. Strict compat.

**Rationale for revision**: User directive "只做兼容、不增功能" is the stronger signal. Atomic-rename is an objective robustness improvement — Out of scope.

---

## R8 — `.gitattributes` content

**Decision**: Add a minimal repo-root `.gitattributes`:

```gitattributes
# Bash scripts must keep LF line endings even on Windows clones.
*.sh text eol=lf

# PowerShell scripts use CRLF on Windows; pwsh on Linux/macOS reads both fine.
*.ps1 text eol=crlf

# Markdown is text; let git autodetect line endings per platform default.
*.md text

# JSON / YAML are text.
*.json text
*.yml text
*.yaml text

# Binary types — explicit safelist (none currently, but flag for future).
# *.zip binary
```

**Rationale**: Minimal but explicit. The `*.sh` rule is the load-bearing one (FR-020). The `*.ps1 eol=crlf` is for clarity — `Compress-Archive` doesn't reinterpret content, but git's `core.autocrlf=input` could in theory strip CRLF from .ps1; explicit pinning prevents that.

**Alternatives considered**:
- Just `*.sh text eol=lf` and nothing else: simpler but doesn't proactively protect other text files. Picked the slightly larger version for clarity.

---

## R9 — Validator extension

**Decision**: Add two new checks to `scripts/release/validate-release-readiness.ps1`:

1. **Bash/PS file-count parity**: when `scripts/bash/` exists, count `.sh` files and `.ps1` files. They MUST match. Names should also match (e.g., for every `X.ps1` there must be an `X.sh`). Implementation: a small `Get-ChildItem` + compare.

2. **`.gitattributes` presence**: file must exist at repo root and contain a line matching the regex `^\*\.sh\s+text\s+eol=lf\b`. Implementation: a `Select-String` check.

Both checks are added INSIDE the existing validator script. Both are tested by extending `test-validate-release-readiness.ps1` with 2 new TDD cases (negative + positive). Test count in `scripts/release/` goes from 5 to 7; release-tooling tests are separate from `tests/` so they don't count toward FR-012.

---

## R10 — Test extension: `Get-AvailableFlavors` helper inline

**Decision**: Each of the two extended tests (`test-handoff-shape.ps1`, `test-guard-hardcoded-rules.ps1`) defines its OWN local `Get-AvailableFlavors` function (~6 lines), iterates over the returned list, and runs its assertions for each flavor.

**Rationale**:
- Sharing the helper via a `.psm1` module would add a non-test `.ps1` (or `.psm1`) file. Whether that counts toward FR-012 "≤ 3 test scripts" is ambiguous. Cleanest: inline.
- 6 lines × 2 tests = 12 lines total. Acceptable duplication.
- Each test self-contained — readable in isolation.

**Helper template** (inlined in each test):

```powershell
function Get-AvailableFlavors {
    param([string]$BridgeRoot)
    $flavors = @()
    if (Test-Path -LiteralPath (Join-Path $BridgeRoot "scripts/powershell")) { $flavors += "ps" }
    if (Test-Path -LiteralPath (Join-Path $BridgeRoot "scripts/bash")) { $flavors += "bash" }
    return $flavors
}
```

Then each test does:

```powershell
foreach ($flavor in (Get-AvailableFlavors -BridgeRoot $bridgeRoot)) {
    # ... assertions, parameterized by $flavor ...
}
```

For invoking bash from pwsh on Windows (where bash may not exist): the test wraps with `if (Get-Command bash -ErrorAction SilentlyContinue)`. If bash is on PATH (Linux/macOS/Windows-with-WSL), the bash flavor runs; else it's skipped with a message.

---

## R11 — Single-ZIP wire-up in build-extension-zip.ps1

**Decision**: One added line in `scripts/release/build-extension-zip.ps1` right after the existing `Copy-Item ... scripts/powershell` line:

```powershell
Copy-Item -Recurse -LiteralPath (Join-Path $bridgeDir "scripts/bash") -Destination (Join-Path $stageDir "scripts/bash") -ErrorAction SilentlyContinue
```

The `-ErrorAction SilentlyContinue` lets the script keep working IF a hypothetical future release decides to ship PS-only. (Defensive but not load-bearing.)

**Rationale**: Mirrors the existing PowerShell-copy line in form. Net delta: +1 line. No restructure.

---

## R12 — extension.yml.requires.tools concrete shape

**Decision**: Final concrete list:

```yaml
requires:
  speckit_version: ">=0.8.10"
  tools:
    - { name: "powershell", version: ">=5.1", required: true }
    - { name: "bash", version: ">=4.0", required: false }
    - { name: "jq", version: ">=1.6", required: false }
    - { name: "git", version: ">=2.30", required: false }
```

**Rationale**: Confirmed against `agent-governance` and `azure-devops` live catalog entries. PowerShell is `required: true` because the test suite needs `pwsh` on every dev box and PS 5.1+ is the Windows install dependency. Bash/jq are `required: false` because Windows installs don't use them. `git` already softdep'd in v0.3.x; carried forward unchanged.

---

## R13 — Commit granularity for v0.4.0

**Decision**: Structure across **6 logical commits**:

1. `feat(bridge): add common-actor-resolution.sh + bash-cli-contract.md` (helper + contract doc). Smallest commit; sets up dot-sourcing pattern. Verifies dot-source works in subsequent scripts.
2. `feat(bridge): add update-handoff.sh (v1 schema writer + tolerant reader)` (~100 lines).
3. `feat(bridge): add guard-command.sh (5 hardcoded rules)` (~60 lines).
4. `feat(bridge): add auto-archive-handoff.sh` (~50 lines).
5. `chore: add .gitattributes; extend validator (file-count + gitattributes checks); extend tests for auto-detect`.
6. `release(bridge): bump to 0.4.0 — README/CHANGELOG/marketplace/extension.yml + build-script copy line`.

**Rationale**:
- 4 commits for the 4 new scripts (each independently reviewable + revertable).
- 1 commit for tooling extensions (validator, tests, .gitattributes).
- 1 commit for the version-bump + release-prep.
- Workflow then auto-builds + publishes on the v0.4.0 tag push.

**Trade-off**: 6 commits is slightly more than feature 003's "≥ 3 commits" target (no formal SC here, but feature 006 had SC-009 ≥ 3). This is correct — each commit is meaningful.

---

## Open items (none blocking)

All FR-001 through FR-022 are decision-complete. No `NEEDS CLARIFICATION` remains in spec.md. Plan is ready for Phase 1 design artifacts.
