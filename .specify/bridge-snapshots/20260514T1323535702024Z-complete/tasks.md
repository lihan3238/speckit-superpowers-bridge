# Tasks: Spec Kit Superpowers Bridge

**Input**: Design documents from `specs/001-spec-superpowers-bridge/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)
**Tests**: Included because the feature explicitly depends on guard, rollback, context discovery, and workflow validation.
**Organization**: Tasks are grouped by user story so each story can be implemented and tested independently after shared foundations are in place.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel with other tasks in the same phase because it touches different files and has no dependency on incomplete tasks.
- **[Story]**: User story label for story phases only.
- Every task includes concrete file paths.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare the smallest missing structure for dual-agent bridge implementation.

- [X] T001 [P] Create the Claude bridge skill target file `.claude/skills/speckit-superpowers-bridge/SKILL.md` with placeholder frontmatter and bridge heading.
- [X] T002 [P] Create the context/workflow verification test harness `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1`.
- [X] T003 [P] Confirm dual integration expectations in `specs/001-spec-superpowers-bridge/quickstart.md` stay aligned with `.specify/integration.json`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Update shared state and command plumbing required by all user stories.

**Critical**: No user story implementation should begin until these shared script surfaces are ready.

- [X] T004 Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` to write backward-compatible `artifact_owner` and `review_only_agents` fields.
- [X] T005 Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` to accept optional `-Actor <codex|claude|unknown>` without breaking existing calls.
- [X] T006 Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1` fixture setup to assert the new handoff ownership fields.

**Checkpoint**: Shared script APIs are ready for story-specific behavior.

---

## Phase 3: User Story 1 - Hand Off Spec Kit Work To Superpowers (Priority: P1) MVP

**Goal**: A completed Spec Kit feature can be handed to Superpowers as executor while preserving Spec Kit artifacts as the only implementation contract.

**Independent Test**: Prepare a feature with `spec.md`, `plan.md`, and `tasks.md`; run handoff; verify `.specify/superpowers-handoff.json` points to the active feature and declares Superpowers as executor.

### Tests for User Story 1

- [X] T007 [P] [US1] Add handoff source-of-truth assertions to `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`.
- [X] T008 [P] [US1] Add schema validation coverage for `specs/001-spec-superpowers-bridge/contracts/handoff.schema.json` in `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`.

### Implementation for User Story 1

- [X] T009 [US1] Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` to refresh stale handoff state from `.specify/feature.json`.
- [X] T010 [US1] Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` to write both Codex and Claude bridge skill references in `instructions`.
- [X] T011 [US1] Update `.specify/extensions/speckit-superpowers-bridge/commands/speckit.superpowers.handoff.md` to describe Codex `$speckit-superpowers-bridge` and Claude `/speckit-superpowers-bridge` usage.
- [X] T012 [US1] Run `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1` and verify handoff tests pass.

**Checkpoint**: User Story 1 is independently testable as the MVP handoff path.

---

## Phase 4: User Story 2 - Prevent Overlapping Planning And Implementation (Priority: P2)

**Goal**: The bridge denies commands and skills that would cause Spec Kit and Superpowers to overlap responsibilities.

**Independent Test**: Attempt prohibited actions against a bridged feature and verify each denial has a clear reason and a JSONL event.

### Tests for User Story 2

- [X] T013 [P] [US2] Add `speckit.implement`, `superpowers.writing-plans`, and `superpowers.brainstorming` denial cases to `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`.
- [X] T014 [P] [US2] Add `speckit.tasks` denial while status is `executing` and allow while status is `blocked` to `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`.
- [X] T015 [P] [US2] Add actor mismatch denial coverage for `-Actor claude` when `artifact_owner` is `codex` in `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`.

### Implementation for User Story 2

- [X] T016 [US2] Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` to normalize Superpowers action names using both `superpowers.writing-plans` and `superpowers:writing-plans`.
- [X] T017 [US2] Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` to deny Spec Kit artifact writes when `-Actor` differs from `artifact_owner`.
- [X] T018 [US2] Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` to preserve blocked-state repair allowances for `speckit.clarify`, `speckit.plan`, and `speckit.tasks`.
- [X] T019 [US2] Update `.specify/extensions/speckit-superpowers-bridge/commands/speckit.superpowers.guard.md` with `-Actor` usage and the single-writer denial rule.
- [X] T020 [US2] Run `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1` and verify overlap-denial tests pass.

**Checkpoint**: User Story 2 denies responsibility overlap without deleting official skills.

---

## Phase 5: User Story 4 - Use The Bridge From Codex Or Claude Code (Priority: P2)

**Goal**: Codex and Claude Code can both discover and use the same bridge protocol with their own command syntax.

**Independent Test**: With both integrations installed, verify `AGENTS.md`, `CLAUDE.md`, Codex bridge skill, Claude bridge skill, and workflow metadata are all consistent.

### Tests for User Story 4

- [X] T021 [P] [US4] Add `AGENTS.md` master-protocol assertions to `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1`.
- [X] T022 [P] [US4] Add `CLAUDE.md` supplement assertions to `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1`.
- [X] T023 [P] [US4] Add bridge skill presence assertions for `.agents/skills/speckit-superpowers-bridge/SKILL.md` and `.claude/skills/speckit-superpowers-bridge/SKILL.md` to `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1`.
- [X] T024 [P] [US4] Add workflow integration assertions for `.specify/workflows/speckit-superpowers/workflow.yml` to `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1`.

### Implementation for User Story 4

- [X] T025 [US4] Implement `.claude/skills/speckit-superpowers-bridge/SKILL.md` by adapting `.agents/skills/speckit-superpowers-bridge/SKILL.md` for Claude slash-hyphen invocation examples.
- [X] T026 [US4] Update `CLAUDE.md` to require reading `AGENTS.md` first and to point to `.claude/skills/speckit-superpowers-bridge/SKILL.md`.
- [X] T027 [US4] Update `AGENTS.md` to keep the Codex `$speckit-*`, Claude `/speckit-*`, and internal dotted command ID mapping explicit.
- [X] T028 [US4] Update `.specify/workflows/speckit-superpowers/workflow.yml` so `requires.integrations.any` includes both `codex` and `claude`.
- [X] T029 [US4] Run `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1` and verify Codex/Claude context tests pass.

**Checkpoint**: User Story 4 is usable from both agent environments without modifying official generated Spec Kit skills.

---

## Phase 6: User Story 3 - Audit And Recover Handoff State (Priority: P3)

**Goal**: Handoff state changes, guard decisions, snapshots, and rollback actions are logged and recoverable without touching implementation source files.

**Independent Test**: Trigger handoff, guard decisions, snapshot creation, and snapshot restore; verify JSONL events and restored Spec Kit control artifacts.

### Tests for User Story 3

- [X] T030 [P] [US3] Add JSONL event field assertions for `actor`, `decision`, `reason`, and `snapshot_id` to `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`.
- [X] T031 [P] [US3] Add rollback non-source-file mutation coverage using a temporary source file in `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`.

### Implementation for User Story 3

- [X] T032 [US3] Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1` event logging to include ownership metadata and snapshot ids.
- [X] T033 [US3] Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1` event logging to include `actor` and normalized action names.
- [X] T034 [US3] Update `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/restore-snapshot.ps1` to append rollback events with restored control artifact paths.
- [X] T035 [US3] Run `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1` and verify audit/rollback tests pass.

**Checkpoint**: User Story 3 can be validated through event logs and snapshot restore.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation alignment across the complete bridge.

- [X] T036 [P] Update `specs/001-spec-superpowers-bridge/quickstart.md` with final tested commands for Codex, Claude Code, guard, handoff, and rollback.
- [X] T037 [P] Update `specs/001-spec-superpowers-bridge/contracts/guard-command-contract.md` if final guard parameters differ from the contract.
- [X] T038 [P] Update `specs/001-spec-superpowers-bridge/contracts/agent-context-contract.md` if final context-file wording changes during implementation.
- [X] T039 Run JSON/YAML parsing checks for `.specify/integration.json`, `.specify/extensions/speckit-superpowers-bridge/extension.yml`, `.specify/workflows/speckit-superpowers/workflow.yml`, and `specs/001-spec-superpowers-bridge/contracts/handoff.schema.json`.
- [X] T040 Run `specify extension list` with UTF-8 output settings and verify `speckit-superpowers-bridge` is enabled.
- [X] T041 Run `specify workflow list` with UTF-8 output settings and verify `speckit-superpowers` is listed.
- [X] T042 Run `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1` and `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1`.
- [X] T043 Run `$speckit-analyze` or `/speckit-analyze` on `specs/001-spec-superpowers-bridge/spec.md`, `plan.md`, and `tasks.md`.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Setup and blocks all user story implementation.
- **User Story 1 (Phase 3)**: Depends on Foundational; recommended MVP.
- **User Story 2 (Phase 4)**: Depends on Foundational and can proceed after or alongside User Story 1 tests are defined.
- **User Story 4 (Phase 5)**: Depends on Foundational and can proceed in parallel with User Story 2 after Setup.
- **User Story 3 (Phase 6)**: Depends on Foundational and benefits from User Story 1/2 logging paths being stable.
- **Polish (Phase 7)**: Depends on all selected user stories.

### User Story Dependencies

- **US1 (P1)**: Required MVP handoff path. No dependency on other user stories after Foundational.
- **US2 (P2)**: Requires guard parameter plumbing from Foundational; does not require Claude context work.
- **US4 (P2)**: Requires setup target files and context test harness; does not require audit/rollback work.
- **US3 (P3)**: Requires handoff, guard, and snapshot flows to exist; should run after US1 and US2 implementation paths are stable.

### Within Each User Story

- Write or update tests first and verify they fail or catch the current gap.
- Implement the minimum file changes for the story.
- Run the story-specific test command.
- Stop at the checkpoint before starting lower-priority story work.

## Parallel Opportunities

- T001, T002, and T003 can run in parallel.
- T007 and T008 can run in parallel.
- T013, T014, and T015 can run in parallel before guard implementation.
- T021, T022, T023, and T024 can run in parallel because they validate different files.
- T030 and T031 can run in parallel before audit implementation.
- T036, T037, and T038 can run in parallel during polish.

## Parallel Example: User Story 4

```text
Task: "Add AGENTS.md master-protocol assertions to .specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1"
Task: "Add CLAUDE.md supplement assertions to .specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1"
Task: "Add bridge skill presence assertions for .agents/skills/speckit-superpowers-bridge/SKILL.md and .claude/skills/speckit-superpowers-bridge/SKILL.md"
Task: "Add workflow integration assertions for .specify/workflows/speckit-superpowers/workflow.yml"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 for handoff correctness.
3. Run `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`.
4. Confirm `.specify/superpowers-handoff.json` points to `specs/001-spec-superpowers-bridge`.

### Incremental Delivery

1. Deliver US1 so tasks can be handed to Superpowers.
2. Deliver US2 so overlap and accidental planning/execution conflicts are denied.
3. Deliver US4 so Codex and Claude Code can both use the same bridge.
4. Deliver US3 so logs and rollback are complete.
5. Finish Phase 7 verification before marking handoff complete.

### Superpowers Execution Notes

- Execute this `tasks.md` through `speckit-superpowers-bridge`, not through `speckit.implement`.
- Use Superpowers TDD discipline for implementation tasks with tests.
- If any task reveals a missing or wrong Spec Kit artifact, stop implementation and mark the handoff `blocked`.
