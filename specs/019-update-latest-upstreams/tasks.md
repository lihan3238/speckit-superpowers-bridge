# Tasks: Latest Spec Kit and Superpowers Alignment

**Input**: Design documents from `/specs/019-update-latest-upstreams/`

**Prerequisites**: plan.md, spec.md, research.md, contracts/upstream-compatibility.md, quickstart.md

## Phase 1: Setup

- [x] T001 Record official Spec Kit v1.0.12 and Superpowers v6.4.2 tags, commits, and local CLI versions in `specs/019-update-latest-upstreams/verification.md`
- [x] T002 [P] Create the upstream compatibility contract and quickstart evidence skeleton in `specs/019-update-latest-upstreams/contracts/upstream-compatibility.md` and `specs/019-update-latest-upstreams/quickstart.md`
- [x] T003 [P] Install Spec Kit CLI v1.0.12 and Codex/Claude Superpowers v6.4.2 integrations without changing the source repository's bridge protocol files

## Phase 2: Foundational Upstream Refresh

- [x] T004 Refresh `.specify/extensions/git/` from Spec Kit v1.0.12, including extension metadata and portable branch-name normalization, while preserving repository-required line endings
- [x] T005 Refresh `.specify/extensions/agent-context/` from Spec Kit v1.0.12, including extension metadata, current defaults, and path/configuration guidance
- [x] T006 Update `.specify/templates/plan-template.md`, `.specify/templates/tasks-template.md`, and `.specify/templates/checklist-template.md` to current Spec Kit command placeholders, then reapply the project's release-sandbox, Native-First, and release-only validation gates
- [x] T007 Run Spec Kit v1.0.12 bootstrap for both Claude and Codex integrations in a temporary-copy-safe way, refresh generated install-time state, and restore/verify project-owned bridge peers under `.agents/skills/speckit-superpowers-bridge/` and `.claude/skills/speckit-superpowers-bridge/`
- [x] T008 Verify `.gitignore`, `.specify/.gitignore`, `.specify/extensions.yml`, and `AGENTS.md` still express the current generated-state policy without changing the bridge command, hook, schema, or actor contracts

**Checkpoint**: Tracked upstream sources are current and project-owned bridge surfaces remain intact.

## Phase 3: User Story 1 - Latest Spec Kit Contract (Priority: P1)

**Goal**: Align bridge hook instructions and tests with Spec Kit v1.0.12.

**Independent Test**: Focused hook-dispatch and parity tests pass and every bridge peer states the current malformed-registry behavior.

- [x] T009 [P] [US1] Update `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.execute.md` to report malformed `.specify/extensions.yml` parser errors and preserve mandatory/optional dispatch semantics
- [x] T010 [P] [US1] Update `.agents/skills/speckit-superpowers-bridge/SKILL.md` and `.claude/skills/speckit-superpowers-bridge/SKILL.md` with identical v1.0.12 hook wording and explicit Superpowers 6.4.2 inline execution semantics
- [x] T011 [US1] Extend `tests/test-implement-hooks-dispatch.sh` to assert malformed-registry reporting, inline execution wording, and unchanged mandatory post-hook ordering
- [x] T012 [US1] Run `tests/test-implement-hooks-dispatch.sh`, `tests/test-claude-codex-skill-parity.sh`, and `tests/test-handoff-shape.sh`; fix only regressions caused by the upstream contract refresh

**Checkpoint**: The bridge mirrors current Spec Kit hook behavior across the execute command and both agent peers.

## Phase 4: User Story 2 - Latest Superpowers Contract (Priority: P1)

**Goal**: Prove the bridge delegates to valid Superpowers 6.4.2 skills without creating a competing plan.

**Independent Test**: Every invoked skill identifier exists in the v6.4.2 source and the bridge documentation states the selected inline execution mode.

- [x] T013 [P] [US2] Add the v6.4.2 skill inventory, executing-plans semantic comparison, and preserved delegation decision to `specs/019-update-latest-upstreams/research.md` and `specs/019-update-latest-upstreams/verification.md`
- [x] T014 [US2] Update bridge implementation guidance in `.agents/skills/speckit-superpowers-bridge/SKILL.md`, `.claude/skills/speckit-superpowers-bridge/SKILL.md`, and the execute command to derive a disposable adapter outside `.superpowers/sdd/` at a stable repository/feature-derived temporary path with `Task N` headings, describe inline `superpowers:executing-plans` behavior, and retain explicit verification/review/finishing phases
- [x] T015 [US2] Verify bridge protocol invariants and extension manifest compatibility against Spec Kit v1.0.12 and Superpowers v6.4.2 in `tests/test-bridge-state-summary.sh` or a focused existing test without adding a new runtime surface

**Checkpoint**: Delegation remains native and the tasks.md ownership boundary remains explicit.

## Phase 5: User Story 3 - Verified Release (Priority: P1)

**Goal**: Publish bridge v1.3.0 with accurate compatibility metadata and evidence.

**Independent Test**: Readiness, smoke, package, and available public-ZIP sandbox checks pass for v1.3.0.

- [x] T016 [P] [US3] Update `.specify/extensions/speckit-superpowers-bridge/extension.yml`, `marketplace/catalog-entry.json`, `marketplace/extensions-readme-row.md`, and `marketplace/extension-submission-body.md` to v1.3.0 and current timestamps while preserving the stable-alias download URL
- [x] T017 [P] [US3] Update `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` with v1.0.12/v6.4.2 evidence, current Codex/Claude versions, and honest platform statuses
- [x] T018 [P] [US3] Add the v1.3.0 changelog section and refresh version/baseline/maintenance/install claims in `README.md` and `README.zh-CN.md`
- [x] T019 [US3] Run `bash tests/run-all.sh`, release-readiness self-tests, source validator, deterministic ZIP build, package smoke, and candidate-ZIP validation; record outputs and SHA256 in `specs/019-update-latest-upstreams/verification.md`
- [x] T020 [US3] Install the published v1.3.0 ZIP in `../test_specify_superpower` for each locally available supported platform, drive a full bridge cycle, and record artifact SHA256 and result in `specs/019-update-latest-upstreams/verification.md`
- [x] T021 [US3] Run or await the hosted macOS release gate and label unavailable native evidence honestly in `specs/019-update-latest-upstreams/verification.md`
- [x] T022 [US3] Commit the release, create tag `v1.3.0`, publish both versioned and stable-alias assets, and verify their reachability before transitioning the handoff

**Checkpoint**: v1.3.0 is installable, evidence-backed, and consistent across all release files.

## Phase 6: Polish

- [x] T023 [P] Update `docs/release-runbook.md` and `AGENTS.md` with the v1.0.12/v6.4.2 baseline and any changed upstream operational notes
- [x] T024 Run `git diff --check`, shell syntax checks, targeted ShellCheck, and final command/hook/schema/runtime-floor invariant audit; complete `specs/019-update-latest-upstreams/verification.md`
- [x] T025 Transition `.specify/superpowers-handoff.json` to `complete` only after mandatory post-implementation hooks and all non-deferred tasks are complete

## Dependencies & Execution Order

- Setup (Phase 1) precedes the upstream refresh.
- Foundational refresh (Phase 2) blocks user-story work.
- User Stories 1 and 2 can proceed in parallel after Phase 2, but both must pass before release metadata is finalized.
- User Story 3 depends on the contract and compatibility changes from User Stories 1 and 2.
- Polish follows the release checks and is required before the terminal handoff transition.

## Parallel Opportunities

- T002/T003 can run in parallel.
- T004/T005/T006 can run in parallel before T007 reconciles generated state.
- T009/T010 can run in parallel; T011 follows their shared contract.
- T016/T017/T018 can run in parallel after the release version is selected.
- T023 can run in parallel with evidence consolidation.

## Implementation Strategy

1. Refresh and reconcile upstream sources.
2. Update the bridge's agent-facing contracts and focused tests.
3. Update release metadata and documentation.
4. Run all gates, publish v1.3.0, verify the public artifact, and complete the handoff.
