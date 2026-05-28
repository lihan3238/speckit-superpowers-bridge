# Contract: `bridge-status` Output

**Owner**: `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/bridge-status.{sh,ps1}` (v0.7.0+).

**Consumers**: humans reading bridge output during interrupted-session recovery; future automation that parses bridge-status output (none today; this contract anticipates it).

**Stability**: line shape is part of the published contract from v0.7.0 onward. Adding NEW lines after the existing block is backward-compatible; reordering, removing, or changing the labels of the listed lines is a MAJOR-version break.

**Relationship to feature 008's `[bridge state]` contract**: this contract EXTENDS [008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md](../../008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md) by adding two new lines (`Drift:` and `Next:`). The 008 contract's R-OUT-1..R-OUT-6 rules still apply to `update-handoff` and `guard-command` outputs (per [research D4](../research.md#d4--print-contract-who-emits-the-new-drift-and-next-lines)); this contract adds R-OUT-7..R-OUT-12 specifically for `bridge-status`.

## Human-mode output

`bridge-status` MUST emit the following block to stdout, in this exact order:

```text
[bridge state]
  Feature directory: <path or "(none)">
  Status: <ready|executing|complete|blocked|(no handoff)|(corrupted handoff)>
  Artifact owner: <claude|codex|human|unknown>
  Actor: <claude|codex|human>                        <-- omit "→ prior" suffix; bridge-status does not record actor switches
  Pending tasks: <integer> | (no tasks.md) | (no feature_directory)
  Drift: <comma-separated filenames> | (none)        <-- present ONLY when handoff has artifacts_sha256
  Next: <recommendation string> | (none)
```

### Rules

- **R-OUT-7**: The literal header line `[bridge state]` MUST appear first (identical to 008/R-OUT-1).
- **R-OUT-8**: The first FIVE sub-fields (Feature directory through Pending tasks) MUST appear in the order and shape defined in 008/R-OUT-2..R-OUT-4. This is a verbatim reuse of the 008 contract; any change there must propagate here.
- **R-OUT-9**: The `Drift:` line MUST appear ONLY when the live handoff has a non-empty `artifacts_sha256` field AND at least one of (a) all stored hashes match the live files (→ `(none)`) or (b) at least one differs (→ comma-joined filenames in the order `spec.md, plan.md, tasks.md`). When the handoff lacks `artifacts_sha256`, the line MUST be omitted entirely (NOT printed as `Drift: (n/a)` or similar).
- **R-OUT-10**: The `Next:` line MUST appear on every successful invocation. The value is derived from the decision table at [next-command-decision-table.md](./next-command-decision-table.md). When no recommendation applies, the literal value `(none)` is emitted. The line MUST appear AFTER `Drift:` when both are present, or AFTER `Pending tasks` when only `Next:` is present.
- **R-OUT-11**: All field labels are exact strings (`Feature directory:`, `Status:`, `Artifact owner:`, `Actor:`, `Pending tasks:`, `Drift:`, `Next:`). Do not localize, abbreviate, pluralize, or reorder.
- **R-OUT-12**: `bridge-status` MUST NOT emit the `[bridge] WARNING:` stderr line that `update-handoff` emits on drift detection (per FR-007). Drift detection in bridge-status is read-only; it surfaces only via the `Drift:` stdout line.
- **R-OUT-13**: When the handoff file does not exist (FR-004 "fresh checkout"), the block fields take these literal values: `Feature directory: (none)`, `Status: (no handoff)`, `Artifact owner: unknown`, `Actor: <resolved actor>`, `Pending tasks: (no feature_directory)`. The `Drift:` line is omitted. The `Next:` line is derived normally from the decision table.
- **R-OUT-14**: When the handoff file exists but cannot be parsed as JSON (FR-004 corrupted state), the block fields take these literal values: `Feature directory: (unknown)`, `Status: (corrupted handoff)`, all other fields read `(unknown)` or `(none)`. The `Next:` value is the fixed string `inspect .specify/superpowers-handoff.json`. Stderr receives one line with the parse error. Exit code is 3.

### Performance constraint

- **C-S1**: A `bridge-status` invocation MUST complete in under 1 second on the reference WSL bash environment (SC-001). The dominant cost is `jq` parse + 3 × `sha256sum` invocations + `wc -l` style task counting; empirically < 200ms total.

### Color and line endings

- **C-S2**: PowerShell flavor MUST NOT emit ANSI color codes. Bash flavor MAY emit color codes when stdout is a TTY but MUST suppress them when piped (standard `--color=auto` discipline). Same as 008/C-4.
- **C-S3**: Each line ends with a single line-feed (`\n`); PowerShell uses `[Environment]::NewLine` via `Write-Host`. Same as 008/C-5.

## JSON-mode output (`--json` / `-Json`)

When invoked with `--json` (bash) or `-Json` (PowerShell), the command MUST emit a single-line JSON object on stdout in place of the human block. Shape:

```json
{"feature_directory":"specs/012-bridge-status-and-hash","status":"executing","artifact_owner":"claude","actor":"claude","pending_tasks":3,"drift":{"detected":true,"artifacts":["tasks.md"]},"next":"continue implementation via speckit-superpowers-bridge SKILL","exit_code":0}
```

### JSON-shape rules

- **R-JSON-1**: Exactly 8 top-level keys: `feature_directory`, `status`, `artifact_owner`, `actor`, `pending_tasks`, `drift`, `next`, `exit_code`. Order is not required but the test harness emits them in this canonical order for stable diffs.
- **R-JSON-2**: `feature_directory` is the relative path string, or JSON `null` when no feature is staged. NOT `"(none)"`.
- **R-JSON-3**: `status` is the lowercase enum value (`ready`, `executing`, `complete`, `blocked`) or the literal string `no_handoff` / `corrupted_handoff`. NOT prefixed with `(`.
- **R-JSON-4**: `artifact_owner`, `actor`: lowercase enum or JSON `null` if unresolved.
- **R-JSON-5**: `pending_tasks` is an integer ≥ 0, or JSON `null` when there is no tasks.md or no feature_directory.
- **R-JSON-6**: `drift` is either `null` (handoff has no `artifacts_sha256`) OR an object `{"detected": <bool>, "artifacts": [...]}` where `artifacts` is a possibly-empty array of filename strings.
- **R-JSON-7**: `next` is the recommendation string, never `null`. When no recommendation applies, the literal `(none)`.
- **R-JSON-8**: `exit_code` is the integer exit code that the process will use (0, 2, or 3). Provided as a body field for downstream automation that captures stdout without separately capturing the exit status.

### Acceptance scenarios

#### S-OUT-1. Executing state with all three artifacts present, no drift

**Given** feature `specs/012-bridge-status-and-hash/` with all three source-of-truth files present, handoff `status: executing`, `artifact_owner: claude`, three unchecked `- [ ] T###` tasks not in deferred sections, `artifacts_sha256` populated with hashes that match the current files.

**When** `bridge-status` runs in human mode.

**Then** stdout is exactly:

```text
[bridge state]
  Feature directory: specs/012-bridge-status-and-hash
  Status: executing
  Artifact owner: claude
  Actor: claude
  Pending tasks: 3
  Drift: (none)
  Next: continue implementation via speckit-superpowers-bridge SKILL
```

Exit code 0.

#### S-OUT-2. Executing state with tasks.md drifted

**Given** the same setup as S-OUT-1, but `tasks.md` has been modified after the `executing` snapshot.

**When** `bridge-status` runs.

**Then** the `Drift:` line reads `Drift: tasks.md` and the rest of the block is unchanged. No stderr output. Exit code 0.

#### S-OUT-3. No handoff yet (fresh checkout)

**Given** no `.specify/superpowers-handoff.json` exists, but `.specify/memory/constitution.md` exists.

**When** `bridge-status` runs.

**Then** stdout is:

```text
[bridge state]
  Feature directory: (none)
  Status: (no handoff)
  Artifact owner: unknown
  Actor: claude
  Pending tasks: (no feature_directory)
  Next: /speckit-specify
```

(No `Drift:` line.) Exit code 0.

#### S-OUT-4. Corrupted handoff JSON

**Given** `.specify/superpowers-handoff.json` exists but is malformed JSON.

**When** `bridge-status` runs.

**Then** stdout is:

```text
[bridge state]
  Feature directory: (unknown)
  Status: (corrupted handoff)
  Artifact owner: (unknown)
  Actor: claude
  Pending tasks: (unknown)
  Next: inspect .specify/superpowers-handoff.json
```

Stderr: one line with the parse error from `jq`. Exit code 3.

#### S-OUT-5. JSON mode on the S-OUT-2 state

**Given** same state as S-OUT-2.

**When** `bridge-status --json` runs.

**Then** stdout is exactly one line of JSON:

```json
{"feature_directory":"specs/012-bridge-status-and-hash","status":"executing","artifact_owner":"claude","actor":"claude","pending_tasks":3,"drift":{"detected":true,"artifacts":["tasks.md"]},"next":"continue implementation via speckit-superpowers-bridge SKILL","exit_code":0}
```

Exit code 0.
