# Feature Specification: Bridge Status Command + SHA256 Handoff Artifact Hash

**Feature Branch**: `012-bridge-status-and-hash`

**Created**: 2026-05-28

**Status**: Draft

**Input**: User description: "ok 这个 spec 实现借鉴前两点。" — referring to the two highest-ROI ideas from the rpamis/comet research conversation that preceded this `/speckit-specify` invocation: (1) a standalone read-only `bridge-status` introspection command modelled on Comet's `comet status` / `/comet continue` pattern, and (2) SHA256-traced artifact snapshots in the handoff modelled on Comet's `handoff_hash` design — both adapted to this project's Native-First discipline (constitution principle VI) so they ship as a thin additive layer over existing v0.5.0 scripts, with zero new daemons/services/state files and zero edits to vendor-managed `.{claude,agents}/skills/speckit-*` skills.

**Reference context** — Two complementary capabilities, one shared print contract:

- The bridge already emits a five-field `[bridge state]` block to stdout from `update-handoff` and `guard-command` (see [specs/008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md](../008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md)). What's missing is a way to print it **on demand** without performing a write or guard check — when a developer returns to an interrupted session and needs to know "where am I?", they currently have to `cat .specify/superpowers-handoff.json` and reason about it manually, or trigger a write/guard just for the side effect of the printout.
- The handoff file points to artifacts (`spec.md`, `plan.md`, `tasks.md`) by *path*, not by *content*. A developer (or another agent) can silently edit `tasks.md` mid-execution while the handoff says `status: executing`, and the bridge has no way to surface this drift. Comet solved this by adding a SHA256 hash of the deterministic context package to its state file; we adopt the same idea at the level of source-of-truth artifacts.

## Clarifications

### Session 2026-05-28

- Q: When `update-handoff` writes hashes on a fresh `executing` transition, what's the canonical artifact set?
  → A: The three `source_of_truth` paths already named in the v1 schema: `spec.md`, `plan.md`, `tasks.md`. Constitution.md is org-level (cross-feature) and excluded. Research.md / contracts/ / quickstart.md are reference, not contract — excluded.
- Q: What should `bridge-status` recommend as "next command" when the handoff is `complete` for the prior feature and no new feature is staged?
  → A: Suggest `/speckit-constitution` only if the constitution has never been authored (no `.specify/memory/constitution.md`); otherwise suggest `/speckit-specify` to start a new feature. Do **not** suggest `auto-archive-handoff` — the helper is idempotent and the prior feature's `complete` row is already terminal-not-active per AGENTS.md "Auto-archive transitions".
- Q: Should the SKILL.md files in `.claude/skills/speckit-superpowers-bridge/` (this project's own deliverable, not vendor-managed) be edited to mention the new command?
  → A: Yes, exactly one line each, under the existing "useful commands" / playbook section if present, or appended as a short note. This is a documentation-only addition, not a behavioral change. It does not violate Native-First because the bridge SKILL files are the *product*, not vendor-managed Spec Kit skills.

## User Scenarios & Testing

### User Story 1 — On-demand bridge state introspection (Priority: P1)

A developer returns to a long-running feature after closing Claude Code overnight. They open a new session, type a single command (or invoke a single skill), and within seconds see: which feature directory is active, what the handoff status is, which actor (claude/codex) owns the artifacts, how many tasks remain, and what command the bridge recommends running next. They do not have to read JSON, do not have to write the handoff just to trigger the print, and do not have to spawn a guard check against a fake command.

**Why this priority**: This is the foundational capability — it lets developers (and agents resuming work) re-orient in one step. Without it, the SHA256 drift-detection in US2 has no obvious surface to report against during routine session resumption. It also directly addresses Comet's strongest borrowable idea: turning the handoff from a passive file into a self-describing state machine you can interrogate.

**Independent Test**: Without implementing US2, after any sequence of `/speckit-{specify,plan,tasks}` and bridge SKILL invocations, running the new status command must print the same five-field `[bridge state]` block contracted in [008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md](../008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md), plus one additional line `Next: <recommended-command-or-(none)>` derived from current state. Output must be reproducible across consecutive invocations with no side effects on `superpowers-handoff.json` or `bridge-events.jsonl`.

**Acceptance Scenarios**:

1. **Given** a feature at `specs/012-bridge-status-and-hash/` with `spec.md` and `plan.md` present, no `tasks.md`, handoff `status: ready`, **When** the developer runs the status command, **Then** stdout shows `Status: ready`, `Pending tasks: (no tasks.md)`, and `Next: /speckit-tasks`.
2. **Given** a handoff `status: executing` with `artifact_owner: claude` and 3 unchecked tasks in tasks.md, **When** the status command runs, **Then** stdout shows `Status: executing`, `Pending tasks: 3`, and `Next: continue implementation via speckit-superpowers-bridge SKILL`.
3. **Given** a handoff `status: complete` for a prior feature, no new feature staged, and `.specify/memory/constitution.md` exists, **When** the status command runs, **Then** stdout shows `Status: complete` and `Next: /speckit-specify` (per Clarifications Q2).
4. **Given** the status command is invoked twice in a row in the same state, **When** the second invocation completes, **Then** `superpowers-handoff.json` mtime is unchanged, `bridge-events.jsonl` line count is unchanged, and stdout of the two invocations is byte-identical.
5. **Given** the handoff file does not exist (fresh checkout, before first `/speckit-specify`), **When** the status command runs, **Then** stdout shows `Feature directory: (none)`, `Status: (no handoff)`, `Next: /speckit-constitution` (or `/speckit-specify` if constitution exists), and exit code is 0 (this is not an error state).

---

### User Story 2 — SHA256 artifact-drift detection on phase transitions (Priority: P2)

A developer hands a feature off to Superpowers execution by transitioning the handoff to `status: executing`. Mid-execution, either they themselves or another agent (or a merge from upstream) modifies `tasks.md` or `plan.md` outside the implementation flow. When the implementing actor later transitions the handoff to `complete`, the bridge surfaces a stderr warning naming exactly which artifact(s) changed since the `executing` snapshot was taken. The warning does not block the transition; exit code stays 0. The integrity record is available for audit via the event log.

**Why this priority**: Builds on US1's print surface. Without US1 there is nowhere natural to surface a passive integrity finding; with US1 the introspection command can also report "Artifact drift since executing snapshot: tasks.md (hash mismatch)". P2 because it's a reliability/audit upgrade, not a recovery-from-interruption blocker.

**Independent Test**: With US1 already in place: write the handoff to `executing` (the script snapshots hashes). Modify `tasks.md` by adding a checkbox. Run the status command — it must report the mismatch in the output and on stderr exactly once. Transition the handoff to `complete` — stderr must contain the same drift warning exactly once. Exit codes stay 0. `bridge-events.jsonl` must contain an entry of type `artifact_drift_detected` with the offending filename(s) and the old/new SHA256s.

**Acceptance Scenarios**:

1. **Given** a handoff being written to `status: executing` for `specs/012-bridge-status-and-hash/`, **When** the write completes, **Then** the handoff JSON contains an `artifacts_sha256` object with three keys (`spec.md`, `plan.md`, `tasks.md`) mapping to lowercase-hex SHA256 strings of the current file contents, OR null for any artifact that does not yet exist on disk.
2. **Given** an `executing` handoff with `artifacts_sha256` populated, **When** `tasks.md` is modified outside the handoff write path and the handoff is transitioned to `status: complete`, **Then** stderr contains exactly one line: `[bridge] WARNING: artifact drift since executing snapshot: tasks.md (sha256 <old8>…→<new8>…)`. Exit code is 0. The `complete` write atomically updates `artifacts_sha256` to the new values.
3. **Given** the status command from US1 is invoked while the live files differ from the stored `artifacts_sha256`, **When** the command runs, **Then** the output block includes one additional line `Drift: tasks.md, plan.md` (comma-joined list of mismatched artifacts) above the `Next:` line, OR `Drift: (none)` when all match.
4. **Given** a handoff written before this feature shipped (no `artifacts_sha256` key), **When** any v0.7.0+ helper reads it, **Then** the helpers do not crash, do not fail; the next `executing` write populates the field. Drift detection silently skips this handoff (no false-positive warning) until the field exists.
5. **Given** an artifact that does not exist on disk (e.g., a fresh `executing` write before `tasks.md` is created by `/speckit-tasks`), **When** the hash is computed, **Then** the corresponding `artifacts_sha256` entry is the JSON literal `null`, not an empty string or omitted key. Drift detection compares null-to-null as match.

---

### Edge Cases

- What happens when the user invokes the status command from a non-repo directory? → Print a single error line to stderr (`[bridge] not inside a Spec Kit repository`) and exit 2. Do not attempt to synthesize state.
- What happens when `superpowers-handoff.json` exists but is malformed JSON? → Print `Status: (corrupted handoff)` and `Next: inspect .specify/superpowers-handoff.json` to stdout; print the parse error to stderr; exit 3. Do not auto-repair.
- What happens when `feature_directory` in the handoff points to a path that does not exist on disk? → Print `Feature directory: <path> (missing)`, all other fields based on what the handoff records, `Next: clear handoff or restore feature directory`, exit 0 (this is recoverable user state, not an error).
- What happens when the proposed `Next:` recommendation depends on a tasks.md count, but tasks.md is huge (10k+ lines)? → Same regex as the existing pending-tasks counter (per [008/contracts/bridge-state-summary.md R-OUT-4](../008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md)); performance budget is the same 50ms. No paging or sampling.
- What happens if two artifacts both drift between snapshot and complete? → Single warning line lists both, comma-joined: `tasks.md, plan.md`.
- What happens if drift detection finds a hash mismatch but the offending file is now *missing* (deleted)? → The new hash value is `null`. The drift report reads `tasks.md (sha256 <old8>…→deleted)`.

## Requirements

### Functional Requirements

- **FR-001**: A new read-only command MUST exist that prints the bridge state on demand without writing the handoff file, without appending to the event log, and without invoking guard logic. It MUST be available in both supported script flavors (bash + PowerShell) under `.specify/extensions/speckit-superpowers-bridge/scripts/{bash,powershell}/`, named `bridge-status.{sh,ps1}`.
- **FR-002**: The command output MUST reproduce the existing five-field `[bridge state]` block verbatim per [008/contracts/bridge-state-summary.md](../008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md) (Feature directory, Status, Artifact owner, Actor, Pending tasks), then append a sixth line: `  Next: <recommendation>`. When US2 is implemented, a `  Drift: <list>|(none)` line is inserted between Pending tasks and Next.
- **FR-003**: The `Next:` recommendation MUST be derived from current on-disk state using a deterministic decision table (no LLM call, no network, no shell-out other than file existence checks). The table covers all combinations of: handoff status × presence of constitution.md × presence of feature_directory × presence of spec.md / plan.md / tasks.md inside it.
- **FR-004**: The command MUST exit 0 in every non-error state (including "no handoff yet" and "feature_directory missing"), exit 2 when not inside a Spec Kit repository, and exit 3 when the handoff file exists but is unparseable.
- **FR-005**: When `update-handoff` writes `status: executing`, it MUST compute the SHA256 of each `source_of_truth` artifact (`spec.md`, `plan.md`, `tasks.md`) currently on disk and embed the lowercase-hex strings into a new top-level `artifacts_sha256` object in the handoff JSON. Files that do not exist MUST be recorded as JSON `null`.
- **FR-006**: When `update-handoff` writes `status: complete` AND the prior on-disk handoff had an `artifacts_sha256` field, the helper MUST recompute hashes against current files, compare them, and on any mismatch emit exactly one line to stderr in the form `[bridge] WARNING: artifact drift since executing snapshot: <comma-joined filenames> (sha256 mismatch)`. Exit code MUST remain 0. The `complete` write MUST atomically overwrite `artifacts_sha256` with the new values so subsequent reads see fresh data.
- **FR-007**: When `bridge-status` is invoked and the live handoff has an `artifacts_sha256` field, the command MUST compute drift in the same way as FR-006 and surface mismatches via the `Drift:` line described in FR-002. `bridge-status` MUST NOT write the handoff or update the stored hashes; drift detection is read-only.
- **FR-008**: An event of type `artifact_drift_detected` MUST be appended to `.specify/bridge-events.jsonl` exactly once per `update-handoff` invocation that detects drift, carrying fields: `event`, `timestamp`, `actor`, `feature_directory`, `drifted_artifacts` (array of `{path, old_sha256, new_sha256}`). `bridge-status` MUST NOT append events.
- **FR-009**: The v1 handoff schema at [specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json](../006-trim-to-thin-bridge/contracts/handoff.v1.schema.json) MUST be amended to declare `artifacts_sha256` as an optional object with three string-or-null properties (`spec.md`, `plan.md`, `tasks.md`). Existing handoffs that lack the field MUST validate and read successfully (no breaking change). New writes by v0.7.0+ MUST include the field whenever status is `executing` or `complete`.
- **FR-010**: Both bash and PowerShell flavors of the new helper, plus the modifications to `update-handoff.{sh,ps1}`, MUST stay within a strict lightness budget (see SC-010 below): bridge-status helper ≤ 200 source lines per flavor; update-handoff modifications ≤ 60 added lines per flavor; zero new event-type definitions beyond `artifact_drift_detected`; zero new top-level state files; zero edits to vendor-managed `.{claude,agents}/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}` files.
- **FR-011**: The bridge SKILL files at `.claude/skills/speckit-superpowers-bridge/SKILL.md` and `.agents/skills/speckit-superpowers-bridge/SKILL.md` MAY be edited to add exactly one line each referencing the new command (e.g., a bullet in the existing playbook or "useful commands" section). No other behavioral instructions in those files may change as part of this feature.
- **FR-012**: The smoke-test suite at `tests/` MUST grow exactly one new test file (`test-bridge-status.sh`) covering: the five US1 acceptance scenarios, the five US2 acceptance scenarios, and the six edge cases enumerated above. The new test file MUST run within the same `< 10s` total-suite budget per CLAUDE.md / AGENTS.md "Running the smoke-test suite".
- **FR-013**: A handoff document written before this feature shipped (no `artifacts_sha256` key) MUST be tolerated by all bridge scripts: read-side falls back to "no snapshot, no drift to report"; write-side populates the field on the next `executing` write. There is no migration script and no version-pin requirement.
- **FR-014**: README.md and README.zh-CN.md MUST gain a short note in the existing "Skills" or "Commands" details-collapsed section linking to the new `bridge-status` command. Total README delta budget for this feature: ≤ 25 lines added across both files combined. CHANGELOG.md gains one entry under a new `[0.7.0]` heading describing both pillars.
- **FR-015**: The feature MUST be verified end-to-end in the canonical sandbox at `..\test_specify_superpower` per the constitution's "End-User Verification Sandbox" section before its handoff transitions to `complete`. The verification record at `specs/012-bridge-status-and-hash/verification.md` MUST capture: bridge SHA256, platform = WSL bash, pass/fail per all US1 + US2 acceptance scenarios, and one demonstrated drift event.

### Key Entities

- **bridge-status command**: A platform-flavored script (`bash` + `PowerShell`) inside the bridge extension package. Read-only. Inputs: optional flag `--json` (or `-Json`) to emit machine-readable output instead of the human block. Outputs: the existing `[bridge state]` block plus a `Next:` line plus an optional `Drift:` line. Does not mutate any state file or event log.
- **artifacts_sha256 field**: A new optional object on the handoff JSON. Three keys, all strings-or-null. Lowercase hex, no `sha256:` prefix. Written by `update-handoff` on every `executing` or `complete` write. Read by `bridge-status` and by the next `update-handoff complete` write (for drift comparison).
- **Next-command decision table**: A deterministic mapping from (handoff status × constitution presence × feature artifact presence) to a single recommended command string. Defined inline in both script flavors. Exhaustive: every cell yields exactly one recommendation or the literal string `(none)`.
- **artifact_drift_detected event**: A new entry type in `.specify/bridge-events.jsonl`. Schema: `{event: "artifact_drift_detected", timestamp, actor, feature_directory, drifted_artifacts: [{path, old_sha256, new_sha256}]}`. Emitted by `update-handoff` only — never by `bridge-status`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: A developer resuming an interrupted session can identify the active feature, status, owner, pending task count, and recommended next command in **one command invocation** taking **under 1 second** on the reference WSL bash environment. (Compare baseline: today requires reading JSON and reasoning manually, typically 30-60 seconds.)
- **SC-002**: 100% of mid-execution edits to `spec.md`, `plan.md`, or `tasks.md` between an `executing` snapshot and a `complete` transition surface as a stderr warning and an `artifact_drift_detected` event log entry, with the offending filename(s) named explicitly. Verified by injecting drift into a controlled run and observing both surfaces.
- **SC-003**: `bridge-status` produces byte-identical output across two consecutive invocations in unchanged state (idempotent read; no hidden writes). Verified by `diff` of two captured outputs.
- **SC-004**: The next-command decision table covers 100% of reachable state combinations (status × constitution × feature-artifact-set) with no UNKNOWN or "fall through" cell. Verified by an exhaustiveness check listed in the smoke test.
- **SC-005**: Zero edits to vendor-managed `.{claude,agents}/skills/speckit-{analyze,checklist,clarify,constitution,implement,plan,specify,tasks,taskstoissues,git-*}/` files. Verified by `git diff main -- .claude/skills/speckit-*/ .agents/skills/speckit-*/` returning only changes to `speckit-superpowers-bridge/`.
- **SC-006**: Total smoke-test suite stays within the `< 10s` budget per AGENTS.md after the new `test-bridge-status.sh` is added. Verified by `time bash tests/run-all.sh`.
- **SC-007**: End-user sandbox verification recorded in `specs/012-bridge-status-and-hash/verification.md` (per FR-015) before handoff transitions to `complete`. The recorded run MUST demonstrate at least one passing scenario from each of US1 and US2.
- **SC-008**: No regression in the existing v0.5.0 `[bridge state]` print contract — every assertion in [008/contracts/bridge-state-summary.md](../008-bridge-hardening-0-5-0/contracts/bridge-state-summary.md) still passes after this feature ships. Verified by re-running the existing 008 test cases.
- **SC-009**: Reading a pre-0.7.0 handoff (no `artifacts_sha256` key) by any 0.7.0+ helper does not crash, does not emit a false-positive drift warning, and does not require a one-shot migration. Verified by checking in a fixture pre-0.7.0 handoff under `tests/fixtures/`.
- **SC-010 (Lightness budget — Principle VI gate)**: All of: (a) bash bridge-status ≤ 200 lines, (b) PowerShell bridge-status ≤ 200 lines, (c) update-handoff bash delta ≤ 60 added lines, (d) update-handoff PowerShell delta ≤ 60 added lines, (e) exactly one new event type, (f) exactly two new files in the bridge package per flavor (bridge-status + the new test), (g) zero new state files, (h) zero new commands at the slash/extension layer (the helper is a script, not a `speckit.*` command), (i) zero edits to vendor-managed Spec Kit skills. Tracked in the v0.7.0 row of [data-model.md](./data-model.md) once `/speckit-plan` runs.

## Assumptions

- The v0.5.0 `[bridge state]` print contract is the canonical surface for human-readable state, and adding a `Next:` line plus optional `Drift:` line is a backward-compatible additive change per its own R-OUT-2 constraint (the rule lists the *five* required fields in order — adding new lines after the listed block does not reorder or remove them).
- The v1 handoff schema's `additionalProperties: true` clause is the intended extension point for additive fields like `artifacts_sha256`. No schema-version bump is required (v0.5.0 schema_version remains 1).
- Constitution.md is org-level (cross-feature) and is intentionally **excluded** from the artifact hash set (per Clarifications Q1). If a constitution change happens mid-execution, that's a separate concern handled by the existing `before_constitution → before_specify → before_clarify → before_plan → before_tasks → before_implement` hook cascade and is out of scope for this feature.
- Other feature-directory files (`research.md`, `quickstart.md`, `data-model.md`, `contracts/*`) are reference and discovery materials, not the contract between Spec Kit and Superpowers — they're excluded from the snapshot.
- Drift detection treats deletion (live file missing while handoff has a hash) and modification (live file present but hash differs) symmetrically: both surface as drift; the new hash is `null` for the deleted case.
- The 50ms / 1s performance budget assumes WSL bash on the reference dev machine reading 3 small Markdown files (typically < 100KB each). PowerShell flavor has the same target; if Windows file I/O latency pushes it over, the budget relaxes to 2s but the contract phrasing remains "under 1 second on the reference WSL bash environment" per SC-001.
- The bridge SKILL.md edits in FR-011 are documentation, not behavior. Adding one bullet to a "useful commands" list does not change what the SKILL instructs the agent to do — it surfaces a discovery path. This stays inside the Principle VI envelope.
- The `..\test_specify_superpower` sandbox is currently aligned with the WSL-only smoke surface from feature 009. PowerShell verification of `bridge-status` is deferred to whichever future feature restores PowerShell smoke coverage; this is consistent with the v0.6.0 verification scope.
- The `tests/run-all.sh < 10s` total-suite budget is the binding ceiling, not a per-test budget. The new `test-bridge-status.sh` is expected to add ≤ 2s, leaving comfortable margin.
- Bumping the bridge version from 0.6.0 to 0.7.0 (across `extension.yml`, `marketplace/catalog-entry.json`, `CHANGELOG.md`) is consistent with semver-style "additive, non-breaking" releases that ship a meaningful new capability surface. The catalog `download_url` stays pinned to the stable-alias `releases/latest/download/speckit-superpowers-bridge.zip` per the v0.6.0 decoupling.
