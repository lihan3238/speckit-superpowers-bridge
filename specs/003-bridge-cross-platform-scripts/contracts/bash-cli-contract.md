<!--
  Still valid as of v0.4.2 — the bash CLI surface shipped in v0.4.1 is byte-frozen by
  spec FR-013. This contract continues to pin parameter mapping and exit codes for
  both flavors. v0.4.2 changes ONE thing in update-handoff's contract: the
  artifact_owner field is now silently preserved from prior file value when no
  explicit --artifact-owner flag is passed (data-model.md Entity A, research.md R1).
-->

# Bash CLI Parity Contract

**Feature**: 003-bridge-cross-platform-scripts
**Purpose**: Pin the CLI surface area of each bash script so it remains externally interchangeable with its PowerShell sibling. Any future change to one flavor MUST update the other.

---

## Naming convention

| PowerShell | Bash |
|---|---|
| File extension `.ps1` | File extension `.sh` |
| Same base name (e.g., `update-handoff.ps1` ↔ `update-handoff.sh`) | |
| Parameters: `-PascalCase <value>` | Long flags: `--kebab-case <value>` |
| Switches: `-FlagName` (no value) | Switches: `--flag-name` (no value) |
| Validation in `[ValidateSet(...)]` | Validation by `case` statement in bash |

---

## Per-script CLI contract

### `update-handoff.{ps1,sh}`

| PowerShell parameter | Bash long flag | Type / values | Default | Required? |
|---|---|---|---|---|
| `-Status <ready\|executing\|complete\|blocked>` | `--status <...>` | enum | `"ready"` | yes |
| `-FeatureDirectory <path>` | `--feature-directory <path>` | string | `""` | no |
| `-Reason "<text>"` | `--reason "<text>"` | string | `""` | no |
| `-ArtifactOwner <codex\|claude\|unknown>` | `--artifact-owner <...>` | enum | `""` (auto from actor) | no |
| `-ReviewOnlyAgents <list>` | `--review-only-agents <comma-list>` | comma-separated | `""` | no |
| `-Actor <codex\|claude\|unknown>` | `--actor <...>` | enum | `""` (resolved chain) | no |
| `-ClearFeatureDirectory` | `--clear-feature-directory` | switch | absent | no |
| `-AppendArchiveEntry <psobject>` | `--append-archive-entry <json>` | accepted-but-ignored (v1 drops archive_history) | `null` | no |

**Exit codes**:

- `0` — handoff written successfully.
- `1` — error (missing required artifacts, unreadable handoff, etc.).
- `2` — usage error (unknown flag, invalid enum value).

**Side effects**:

- Always writes `.specify/superpowers-handoff.json` (overwrite).
- Snapshots `.specify/bridge-snapshots/<id>/` BEFORE writing (when feature_directory resolves).
- Appends one event line to `.specify/bridge-events.jsonl` with `action: "handoff"`.

---

### `guard-command.{ps1,sh}`

| PowerShell parameter | Bash long flag | Type / values | Default | Required? |
|---|---|---|---|---|
| `-Action <name>` | `--action <name>` | string | (none) | **yes** |
| `-Reason "<text>"` | `--reason "<text>"` | string | `""` | no |
| `-Actor <codex\|claude\|unknown>` | `--actor <...>` | enum | `""` (resolved chain) | no |
| `-TargetFeatureDirectory <path>` | `--target-feature-directory <path>` | string | `""` | no |

**Exit codes**:

- `0` — action allowed.
- `1` — action denied (a hardcoded rule fired).
- `2` — usage error.

**Side effects**:

- Appends one event line to `.specify/bridge-events.jsonl` with `action: "guard"`, `decision: "allow"` or `"deny"`.
- NO writes to handoff JSON or snapshots.

**Rule set** (both flavors implement identically; see research.md R3 of feature 006):

1. Deny `speckit.implement` when handoff status is `executing`.
2. Deny `superpowers:writing-plans` / `:brainstorming` when active feature has both `spec.md` AND `plan.md`.
3. Deny `speckit.constitution` when handoff status is `executing`.
4. Allow any other `speckit.*` action.
5. Default allow.

---

### `auto-archive-handoff.{ps1,sh}`

| PowerShell parameter | Bash long flag | Type / values | Default | Required? |
|---|---|---|---|---|
| `-Actor <codex\|claude\|unknown>` | `--actor <...>` | enum | `""` (resolved chain) | no |
| `-Reason "<text>"` | `--reason "<text>"` | string | default message | no |

**Exit codes**:

- `0` — archived (status was `complete`) OR no-op (status was NOT `complete`).
- `1` — error.

**Side effects when status IS `complete`**:

- Snapshots prior feature directory artifacts under `.specify/bridge-snapshots/<id>/`.
- Calls `update-handoff.{ps1,sh}` with `--status ready --clear-feature-directory --artifact-owner unknown`.
- Appends one event line with `action: "archive"`, `status: "archived"`.

**Side effects when status is NOT `complete`**:

- Prints "No complete handoff to archive (current status: '<status>')." to stdout.
- No file modifications.
- Exit 0.

---

### `common-actor-resolution.{ps1,sh}` (sourced, not invoked directly)

Both flavors define two functions / cmdlets:

| Function | PowerShell | Bash | Purpose |
|---|---|---|---|
| Repo-root discovery | `Get-BridgeRepoRoot` | `get_repo_root` | Return absolute path of repo root via `git rev-parse --show-toplevel`, fall back to `pwd` / `(Get-Location).Path`. |
| Actor resolution | `Resolve-BridgeActor` | `resolve_bridge_actor` | 3-step chain: explicit arg → `SPECKIT_BRIDGE_ACTOR` env → `"unknown"`. Returns one of `codex` / `claude` / `unknown`. |

Both files are dot-sourced (`. common-actor-resolution.sh` in bash; `. (Join-Path $PSScriptRoot "common-actor-resolution.ps1")` in PS).

---

## JSON I/O parity

For every script that reads/writes `superpowers-handoff.json`:

- **Read tolerance**: unknown fields (`autonomous_mode`, `resume_context`, `archive_history`, or any future field) are silently ignored. Identical behavior to feature 006 FR-009.
- **Write minimality**: v1-shape only. No v2/v3 fields emitted.
- **Encoding**: UTF-8 no-BOM, LF line endings inside the JSON body. Both flavors should produce byte-identical output for identical inputs **except for the `updated_at` and `last_snapshot_id` fields** (timestamp-dependent).

To compare two writes (one PS, one bash) for parity:

```bash
# pseudo-code
diff <(jq 'del(.updated_at, .last_snapshot_id) | tojson' ps-handoff.json) \
     <(jq 'del(.updated_at, .last_snapshot_id) | tojson' bash-handoff.json)
```

Expected: empty diff.

---

## Test obligations (FR-014, FR-015)

The `tests/test-handoff-shape.ps1` and `tests/test-guard-hardcoded-rules.ps1` smoke tests MUST:

1. Detect available flavors via the inline `Get-AvailableFlavors` helper.
2. For each detected flavor, run ALL assertions (not a subset).
3. For bash flavor: skip with informative message if `bash` is not on PATH (e.g., Windows without WSL).
4. For PS flavor: skip with informative message if `pwsh` invocation fails (extreme corner case).
5. Print a per-flavor summary line so a CI log shows: `handoff-shape-tests-ok (ps, bash)` or `handoff-shape-tests-ok (ps)` etc.

---

## Future evolution

If a new bridge script is added in a future feature:

- It MUST have both `.ps1` and `.sh` flavors at introduction time. The validator (FR-012) will fail otherwise.
- This contract document MUST be amended with a new per-script section.

If the v1 handoff schema gains a field (e.g., a future v2.0.0 release):

- Both flavors update in lockstep.
- This contract document does NOT need amendment unless the change touches CLI surface.
