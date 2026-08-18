# Tasks: v1.2.0 Release Hardening and Upstream Alignment

**Input**: Design documents from `/specs/018-release-0-16-4-hardening/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `contracts/`, `quickstart.md`

**Tests**: Required. Runtime/script changes follow test-first implementation; instruction-only hook behavior requires both static contract checks and a live published-artifact bridge cycle.

**Organization**: Tasks are grouped by user story. `tasks.md` is the only implementation contract consumed by the bridge.

## Phase 1: Setup and Baseline Capture

**Purpose**: Preserve accepted contribution evidence and establish exact upstream baselines.

- [x] T001 Record PR #14 merge commit, Issue #13 scope, Spec Kit 0.16.4 tag/commit, Superpowers 6.3.0 tag/commit, and local tool versions in `specs/018-release-0-16-4-hardening/verification.md`
- [x] T002 Audit the current dirty tree after `specify init --force`, classify every generated versus project-owned delta, and record the disposition in `specs/018-release-0-16-4-hardening/research.md`
- [x] T003 Reapply the release-sandbox and Native-First governance callouts to `.specify/templates/plan-template.md` and the release-only validation example to `.specify/templates/tasks-template.md` while retaining Spec Kit 0.16.4 template updates

---

## Phase 2: Foundational Spec Kit State Refresh

**Purpose**: Bring tracked Spec Kit-owned bootstrap sources to 0.16.4 before bridge runtime work.

**CRITICAL**: Complete this phase before editing project-owned bridge peers, because integration/extension refresh may overwrite their alias paths.

- [x] T004 Refresh `.specify/extensions/git/` from the official Spec Kit 0.16.4 bundled source, including renamed bash/PowerShell branch scripts, Python scripts, branch-template configuration, and Conventional Commit support
- [x] T005 Refresh `.specify/extensions/agent-context/` from the official Spec Kit 0.16.4 bundled source, including defaults, multi-context configuration support, containment hardening, and Python scripts
- [x] T006 Install/upgrade both Claude and Codex integrations with Spec Kit 0.16.4, keep Claude as the default, and verify generated core skills include `speckit-converge` under `.claude/skills/` and `.agents/skills/`
- [x] T007 Safely re-register the local bridge extension from a temporary copy outside `.specify/extensions/speckit-superpowers-bridge/`, verify local install metadata reports v1.2.0, and document the installer collision behavior in `specs/018-release-0-16-4-hardening/verification.md`
- [x] T008 Restore the project-owned short bridge peers after generated-skill installation and make `.agents/skills/speckit-superpowers-bridge/SKILL.md` and `.claude/skills/speckit-superpowers-bridge/SKILL.md` body-parity tests pass
- [x] T009 Adopt `.specify/.gitignore`, update `.gitignore` for all current generated Spec Kit skills/state, update `.specify/extensions.yml`, and document the 0.16.4 bootstrap/local-state policy in `AGENTS.md`
- [x] T010 Configure the refreshed agent-context extension to update the canonical `AGENTS.md` marker and the `CLAUDE.md` import marker safely, then point both managed sections at `specs/018-release-0-16-4-hardening/plan.md`

**Checkpoint**: A fresh 0.16.4 bootstrap can be reproduced without losing project-owned bridge files or project governance gates.

---

## Phase 3: User Story 1 - macOS users can create bridge handoffs (Priority: P1) MVP

**Goal**: Remove the GNU coreutils dependency that makes the bash handoff path fail on macOS.

**Independent Test**: Run the focused test with a fake `realpath` that rejects `-m`, missing feature/artifact paths, `.` / `..`, and an in-repo symlink targeting outside; all expected handoff paths and states must match the path contract.

### Tests for User Story 1

- [x] T011 [US1] Add failing portability and path-contract cases in `tests/test-update-handoff-portability.sh`, including zero tolerance for shipped `realpath -m` calls

### Implementation for User Story 1

- [x] T012 [US1] Implement bounded, symlink-aware missing-path normalization inside `.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh` without adding a runtime dependency
- [x] T013 [US1] Run `tests/test-update-handoff-portability.sh`, `tests/test-handoff-shape.sh`, and `tests/test-bridge-status.sh`, then record exact outputs in `specs/018-release-0-16-4-hardening/verification.md`
- [x] T014 [US1] Add a macOS-hosted release gate that runs the bash suite and focused handoff portability test in `.github/workflows/release.yml`

**Checkpoint**: The bash handoff works with BSD-compatible tooling and preserves existing path/security semantics.

---

## Phase 4: User Story 2 - Implement hooks match current Spec Kit behavior (Priority: P1)

**Goal**: Harden PR #14 to Spec Kit 0.16.4's directive, invocation, ordering, and failure-state contract.

**Independent Test**: Static contract tests prove all three instruction surfaces agree on filters, `EXECUTE_COMMAND`, actual invocation, and ordering; a later public-artifact bridge cycle proves real hook behavior.

### Tests for User Story 2

- [x] T015 [US2] Strengthen `tests/test-implement-hooks-dispatch.sh` so it fails without standard mandatory-hook directives, explicit actual invocation/wait language, bridge-owned skip rules, and post-hook-before-complete ordering

### Implementation for User Story 2

- [x] T016 [US2] Update `.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.execute.md` to the contract in `specs/018-release-0-16-4-hardening/contracts/implement-hook-dispatch.md`
- [x] T017 [P] [US2] Update `.agents/skills/speckit-superpowers-bridge/SKILL.md` with the same current hook contract and lifecycle ordering
- [x] T018 [P] [US2] Update `.claude/skills/speckit-superpowers-bridge/SKILL.md` with the same current hook contract and lifecycle ordering
- [x] T019 [US2] Run hook contract/parity tests and update PR #14's release wording where necessary in `CHANGELOG.md` and `specs/018-release-0-16-4-hardening/verification.md`

**Checkpoint**: Both agents expose the same bridge lifecycle and cannot report completion before mandatory post-hooks succeed.

---

## Phase 5: User Story 3 - Maintainers can publish against current upstreams (Priority: P2)

**Goal**: Make every compatibility claim, install instruction, release field, and validation gate agree with the audited upstreams and v1.2.0 artifact.

**Independent Test**: Release validators, full source suites, hosted platform jobs, and public-URL sandbox cycles all pass with consistent version metadata.

### Compatibility and documentation

- [x] T020 [P] [US3] Refresh Spec Kit 0.16.4 compatibility guidance, badges, maintenance notes, bootstrap commands, and verified claims in `README.md` and `AGENTS.md`
- [x] T021 [P] [US3] Refresh the equivalent Spec Kit 0.16.4 and Superpowers 6.3.0 guidance in `README.zh-CN.md`, auditing first prose uses of English abbreviations and domain terms per the repository language rule
- [x] T022 [US3] Update `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` with Spec Kit 0.16.4, Superpowers 6.3.0, Codex/Claude versions, platform rows, and evidence-backed notes
- [x] T023 [US3] Rewrite the v1.2.0 section in `CHANGELOG.md` to include PR #14, current implement-hook semantics, Issue #13, Spec Kit 0.16.4, Superpowers 6.3.0, and the expanded 8-test/macOS gate
- [x] T024 [P] [US3] Update `marketplace/catalog-entry.json` and `marketplace/extensions-readme-row.md` with the final v1.2.0 compatibility baseline and 2026-08-18 timestamp
- [x] T025 [US3] Update `marketplace/extension-submission-body.md` with final version, support matrix, verification summary, proposed catalog entry, and stable-alias policy

### Source and package verification

- [x] T026 [US3] Run `git diff --check`, shell syntax checks, ShellCheck when available, and `bash tests/run-all.sh`; record the complete result set in `specs/018-release-0-16-4-hardening/verification.md`
- [x] T027 [US3] Run `scripts/release/test-validate-release-readiness.ps1`, `validate-release-readiness.ps1 -Version 1.2.0`, build the deterministic ZIP, run `tests/test-release-package.sh`, validate the ZIP, and record its local SHA256 in `specs/018-release-0-16-4-hardening/verification.md`
- [x] T028 [US3] Run `tests/test-release-powershell.ps1` and the release-readiness validator in native Windows PowerShell, recording exact evidence in `specs/018-release-0-16-4-hardening/verification.md`

### Publication and public-artifact sandbox

- [x] T029 [US3] Commit the release branch, push it, open a PR with Constitution/Native-First answers, wait for all available checks including macOS, review the final diff, and merge to `main`
- [x] T030 [US3] Tag merged `main` as `v1.2.0`, push the tag, wait for the release workflow, and verify both versioned and stable-alias ZIP assets plus published SHA256
- [x] T031 [US3] Install the public v1.2.0 ZIP in the WSL2 `../test_specify_superpower` sandbox, drive a full bridge cycle with synthetic implement hooks, and record the result in `specs/018-release-0-16-4-hardening/verification.md`
- [x] T032 [US3] Install the public v1.2.0 ZIP in the native Windows `..\test_specify_superpower` sandbox, drive a full bridge cycle, and record the result in `specs/018-release-0-16-4-hardening/verification.md`
- [x] T033 [US3] Commit and push post-release verification evidence, close GitHub Issue #13 with release/evidence links, and submit the upstream github/spec-kit Extension Submission issue using `marketplace/extension-submission-body.md`

**Checkpoint**: v1.2.0 is public, installable, evidence-backed, and coordinated upstream.

---

## Phase 6: Final Verification and Handoff Completion

**Purpose**: Ensure the implementation contract and repository state are genuinely complete.

- [ ] T034 Re-run `bash tests/run-all.sh` and release readiness after post-release evidence changes, confirm no non-deferred task remains unchecked in `specs/018-release-0-16-4-hardening/tasks.md`, and update `specs/018-release-0-16-4-hardening/verification.md`
- [ ] T035 Review `git status`, remote `main`, release assets, PR/Issue state, and `.specify/superpowers-handoff.json`, then transition the handoff to `complete` only after all mandatory post-implement hooks succeed

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts from merged PR #14 and the 0.16.4 local CLI.
- **Foundational (Phase 2)**: Depends on Setup; must finish before project-owned skill edits to avoid installer overwrites.
- **US1 and US2 (Phases 3-4)**: Depend on Foundational; runtime and instruction tests can proceed independently until shared verification/docs.
- **US3 (Phase 5)**: Depends on US1 + US2 source completion and all version/evidence decisions.
- **Final (Phase 6)**: Depends on published-artifact sandbox rows and coordination closure.

### User Story Dependencies

- **US1 (P1)**: Independent runtime portability fix after Spec Kit state refresh.
- **US2 (P1)**: Independent instruction-contract hardening after project-owned peers are restored.
- **US3 (P2)**: Consumes US1/US2 evidence and publishes the combined release.

### Parallel Opportunities

- T017 and T018 may be authored in parallel but must finish with byte-equivalent bodies except agent-specific frontmatter/invocations.
- T020 and T021 target separate language documents; T024 targets separate marketplace files.
- US1 focused tests and US2 contract tests touch separate files after Phase 2.

---

## Implementation Strategy

### MVP First

1. Refresh upstream-owned Spec Kit state without losing project-owned files.
2. Deliver US1 and prove macOS-compatible handoff creation.
3. Deliver US2 and prove the current hook contract plus correct failure-state ordering.
4. Only then update compatibility claims and publish US3.

### Verification Discipline

- Write focused tests before runtime/instruction changes.
- Treat grep-based instruction checks as contract checks, not live behavior evidence.
- Do not mark platform/agent rows verified without a real run or a clearly labeled retained evidence rationale.
- Do not mark the handoff complete until the public-URL sandbox gate and mandatory post-hooks are complete.
