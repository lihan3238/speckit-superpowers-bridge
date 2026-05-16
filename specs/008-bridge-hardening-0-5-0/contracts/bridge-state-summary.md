# Contract: Bridge State Summary Output

**Owner**: `update-handoff.{ps1,sh}` + `guard-command.{ps1,sh}` (v0.5.0+).

**Consumers**: Humans reading bridge output; any downstream automation that parses the bridge stdout for state. (Such automation does not exist today; this contract anticipates it.)

**Stability**: Output line shape is part of the published contract from v0.5.0 onward. Adding NEW lines is backward-compatible; reordering or removing the listed lines is a MAJOR-version break.

## Contract

After every successful `update-handoff` write OR every `guard-command` evaluation (allow OR deny), the script MUST emit the following block to stdout, in this exact order. Each line begins at column 1 with no leading whitespace.

```text
[bridge state]
  Feature directory: <path or "(none)">
  Status: <ready|executing|complete|blocked>
  Artifact owner: <claude|codex|human|unknown>
  Actor: <claude|codex|human>                      <-- omit "→ prior" suffix if prior == actor
  Actor: claude → codex                            <-- form when prior_actor differs (illustrative; only ONE Actor line per print)
  Pending tasks: <integer> | (no tasks.md)         <-- per FR-001 canonical regex + FR-005 exemptions
```

### Rules

- **R-OUT-1**: The literal header line `[bridge state]` MUST appear first.
- **R-OUT-2**: All five sub-fields MUST appear in this order: Feature directory, Status, Artifact owner, Actor, Pending tasks.
- **R-OUT-3**: When `prior_actor` is null OR equal to the new `actor`, the `Actor:` line takes the simple form `Actor: <actor>`. When they differ, the line takes the form `Actor: <prior_actor> → <actor>`.
- **R-OUT-4**: `Pending tasks: <integer>` is emitted when `<feature_directory>/tasks.md` exists; `Pending tasks: (no tasks.md)` otherwise. If the feature_directory itself is empty/missing, the line MUST read `Pending tasks: (no feature_directory)`.
- **R-OUT-5**: The block is followed by the script's existing output (e.g., `Guard allowed speckit.plan.`); the existing tail is unchanged from v0.4.3.
- **R-OUT-6**: When the `update-handoff` operation transitions `status` to `complete` AND `Pending tasks` > 0 (computed using the canonical regex + section exemptions), an ADDITIONAL line MUST be written to **stderr** (not stdout):

  ```text
  [bridge] WARNING: handoff is 'complete' but tasks.md has <N> unchecked tasks; review or move under a deferred section.
  ```

  This warning is ONLY emitted on the transition INTO `complete`, not on subsequent invocations against an already-complete handoff. The warning does NOT change the exit code (zero on success).

## Acceptance scenarios

### S1. Fresh executing state, 3 pending tasks

**Given** a feature with `feature_directory: specs/008-bridge-hardening-0-5-0`, handoff status `executing`, tasks.md with 3 `- [ ] T###` lines outside any deferred section.

**When** `update-handoff -Status executing -Actor claude` runs successfully.

**Then** stdout begins with:

```text
[bridge state]
  Feature directory: specs/008-bridge-hardening-0-5-0
  Status: executing
  Artifact owner: claude
  Actor: claude
  Pending tasks: 3
```

(Followed by the existing handoff-update success message.)

### S2. Actor switch claude → codex

**Given** a handoff where the persisted `actor` is `claude`, status `executing`.

**When** `update-handoff -Status executing -Actor codex` runs.

**Then** the printed block shows `Actor: claude → codex` and the event log entry contains `"actor":"codex"` AND `"prior_actor":"claude"` AND `"reason"` mentions the change.

### S3. Complete with unchecked tasks → WARNING

**Given** a feature with handoff `status: executing` and 2 unchecked tasks not under any deferred section.

**When** `update-handoff -Status complete -Actor claude` runs.

**Then**:
- stdout includes the block with `Status: complete` and `Pending tasks: 2`.
- stderr contains exactly one line: `[bridge] WARNING: handoff is 'complete' but tasks.md has 2 unchecked tasks; review or move under a deferred section.`
- Exit code is 0.

### S4. Complete with deferred tasks → NO warning

**Given** a feature with handoff `status: executing` and 5 unchecked `- [ ] T###` lines, all under a `## Deferred (...)` H2 section.

**When** `update-handoff -Status complete -Actor claude` runs.

**Then**:
- stdout block shows `Pending tasks: 0`.
- stderr is empty (no warning).

### S5. Inline `(deferred)` token does NOT exempt

**Given** a feature with `- [ ] T029 (deferred to v0.5.0+)` outside any deferred section header.

**When** `update-handoff -Status complete -Actor claude` runs.

**Then** that task counts toward `Pending tasks`. A warning fires. (Inline tokens are NOT recognized per Clarifications Q6.)

### S6. No tasks.md

**Given** a feature whose `<feature_directory>` does NOT contain a `tasks.md` (e.g., right after `/speckit-specify` before `/speckit-tasks`).

**When** any bridge script runs.

**Then** the block shows `Pending tasks: (no tasks.md)`. No warning is ever emitted in this state regardless of status.

### S7. No feature_directory

**Given** a freshly-archived handoff: `feature_directory: ""`, no active feature.

**When** any bridge script runs.

**Then** the block shows `Feature directory: (none)` and `Pending tasks: (no feature_directory)`. No warning fires.

## Constraints

- **C-1**: All fields MUST be present on every print, even if some are empty/unknown.
- **C-2**: Field labels are exact strings; do not localize, abbreviate, or pluralize.
- **C-3**: The 50ms performance budget (spec Assumption) covers the entire helper invocation including file I/O.
- **C-4**: PowerShell flavor MUST NOT emit ANSI color codes; bash flavor MAY emit color codes when stdout is a TTY but MUST suppress them when piped. (Standard `--color=auto` discipline.)
- **C-5**: Each line ends with a single line-feed (`\n`); PowerShell flavor uses `[Environment]::NewLine` translated through normal `Write-Host` which handles platform-correct line endings.
