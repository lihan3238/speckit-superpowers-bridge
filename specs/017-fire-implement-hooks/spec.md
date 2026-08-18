# Feature Specification: Fire speckit.implement before/after hooks from the bridge

**Feature Branch**: `017-fire-implement-hooks`

**Created**: 2026-08-17

**Status**: Draft

**Input**: User description: "This extension is installed, and I have hooks installed in my speckit — one of them is the `after` of `speckit.implement`, but it is not being triggered because my project also uses this extension. I want this extension to also fire the `speckit.implement` hook (`after` and `before`) so it is truly plug-and-play."

## Context

Spec Kit fires extension hooks (declared in `.specify/extensions.yml`) as part of
its command workflows, and the `implement` command fires `before_implement` and
`after_implement` hooks through **markdown instructions** in the command file
(`core_pack/commands/implement.md` — the "Pre-Execution Checks" and "Mandatory
Post-Execution Hooks" sections). There is no CLI or script that fires hooks; the
agent reads `.specify/extensions.yml`, filters the hook list, and invokes each
hook command by name.

The bridge **replaces** `speckit.implement` with its own `execute` command,
which never reads those hook lists. The result is a plug-and-play gap: any hook
a user or another extension registers under `hooks.before_implement` /
`hooks.after_implement` (for example the git extension's `speckit.git.commit`
auto-commit, or a user's own custom hook) silently stops firing once the project
uses the bridge. The bridge must fire the same hooks to behave as a true drop-in
replacement.

One bridge-specific subtlety drives most of the design: the bridge registers its
**own** `before_implement` hook (`speckit.speckit-superpowers-bridge.guard`),
whose purpose is to **block `speckit.implement`** while Superpowers owns
execution (guard rule 1). If the bridge fired `before_implement` hooks naively,
it would fire its own guard and block itself. The bridge must therefore skip its
own hooks when firing `before_implement` / `after_implement`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A user's implement hooks keep firing through the bridge (Priority: P1)

A user who has registered `before_implement` and/or `after_implement` hooks
(e.g. the git extension's auto-commit, or their own hook) switches a Spec Kit
feature from `speckit.implement` to the bridge and expects those hooks to keep
firing at the same points in the lifecycle.

**Why this priority**: This is the exact defect reported. Without it the bridge
is not plug-and-play — it silently drops a user's hooks, which can skip
auto-commits or other workflow steps they rely on.

**Independent Test**: In a project with a hook registered under
`hooks.before_implement` and `hooks.after_implement`, run a bridge cycle and
confirm both hooks are dispatched (before the handoff `executing` transition and
after the `complete` transition respectively).

**Acceptance Scenarios**:

1. **Given** `.specify/extensions.yml` has an enabled hook under `hooks.before_implement`, **When** the bridge execute command runs, **Then** the bridge dispatches that hook's command before transitioning the handoff to `executing`.
2. **Given** `.specify/extensions.yml` has an enabled hook under `hooks.after_implement`, **When** the bridge finishes implementation and transitions the handoff to `complete`, **Then** the bridge dispatches that hook's command.
3. **Given** a hook with `enabled: false`, **When** the bridge fires implement hooks, **Then** that hook is skipped.
4. **Given** an optional hook (`optional: true`), **When** the bridge fires it, **Then** the bridge surfaces its `prompt` and executes only on user confirmation.

---

### User Story 2 - The bridge does not block itself on its own guard (Priority: P1)

The bridge must not fire its own `before_implement` guard hook, whose job is to
deny `speckit.implement` while the handoff is `executing`.

**Why this priority**: Firing the bridge's own guard would make the bridge deny
its own execution (guard rule 1 fires because the handoff is `executing`),
breaking the feature entirely. This is the critical correctness constraint that
distinguishes the bridge from a naive "fire every hook" approach.

**Independent Test**: Confirm the documented dispatch rules and the smoke test
both state that hooks whose `extension` is `speckit-superpowers-bridge` are
skipped when the bridge fires implement hooks.

**Acceptance Scenarios**:

1. **Given** the bridge's own `before_implement` guard hook is registered, **When** the bridge fires `before_implement` hooks, **Then** the bridge skips it (does not invoke `speckit.speckit-superpowers-bridge.guard`).
2. **Given** a non-bridge hook on `before_implement`, **When** the bridge fires `before_implement` hooks, **Then** it still fires that non-bridge hook.

---

### User Story 3 - The dispatch contract is documented and testable (Priority: P2)

A maintainer (or future agent) can verify — without a live agent run — that the
bridge's execute command and both per-agent skill peers carry the correct
hook-dispatch contract.

**Why this priority**: The dispatch is instruction-only (mirroring Spec Kit's
own mechanism), so the only deterministic, CI-able assertion is that the
instruction contract is present and consistent across the three authoritative
files.

**Independent Test**: Run `bash tests/test-implement-hooks-dispatch.sh`; it
passes only if `execute.md` and both SKILL peers reference `before_implement` /
`after_implement`, the skip-own-guard rule, and the before/after ordering.

**Acceptance Scenarios**:

1. **Given** the release commit, **When** the smoke test runs, **Then** it asserts the dispatch contract exists in `execute.md`, `.agents/.../SKILL.md`, and `.claude/.../SKILL.md`.

---

### Edge Cases

- `.specify/extensions.yml` is missing or unparseable: skip hook dispatch silently (same as Spec Kit's own `implement` command).
- A hook has a non-empty `condition`: skip it and leave condition evaluation to the upstream HookExecutor (same as Spec Kit).
- A hook is `optional: false` (mandatory): execute it and wait for its result before continuing; a failure should surface, matching Spec Kit's "wait for the result" behavior.
- The bridge fires `after_implement` but registers no hook there itself: the skip-own rule still applies uniformly (harmless, future-proof).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The bridge `execute` command (`commands/speckit.speckit-superpowers-bridge.execute.md`) MUST instruct the agent to fire the `before_implement` extension hooks from `.specify/extensions.yml` before transitioning the handoff to `executing`.
- **FR-002**: The bridge `execute` command MUST instruct the agent to fire the `after_implement` extension hooks from `.specify/extensions.yml` after transitioning the handoff to `complete`.
- **FR-003**: The dispatch MUST skip hooks whose `extension` is `speckit-superpowers-bridge` (so the bridge never fires its own `before_implement` guard and blocks itself).
- **FR-004**: The dispatch MUST mirror Spec Kit's own `implement` command filtering: skip hooks with `enabled: false` (treat missing `enabled` as enabled), and skip hooks with a non-empty `condition`.
- **FR-005**: The dispatch MUST render each hook's `command` per agent — `speckit.git.commit` → `/speckit-git-commit` (Claude Code) or `$speckit-git-commit` (Codex) — and must respect `optional`: mandatory hooks execute and wait, optional hooks prompt first.
- **FR-006**: Both per-agent bridge skill peers (`.agents/skills/speckit-superpowers-bridge/SKILL.md` and `.claude/skills/speckit-superpowers-bridge/SKILL.md`) MUST carry the same hook-dispatch contract, so both agents behave identically (constitution Principle III).
- **FR-007**: A smoke test (`tests/test-implement-hooks-dispatch.sh`) MUST assert the dispatch contract (before/after references, skip-own-guard rule, and ordering) exists in `execute.md` and both SKILL peers.
- **FR-008**: The bridge version MUST be bumped `1.1.0` → `1.2.0` (MINOR) across the release-bump checklist (extension.yml, catalog-entry.json, CHANGELOG, verified-versions.json, README EN + zh-CN, marketplace/extensions-readme-row.md, marketplace/extension-submission-body.md).
- **FR-009**: The full bash smoke suite (`bash tests/run-all.sh`) MUST stay green on every commit, now at 7 tests.

### Key Entities

- **Extension hook** (from `.specify/extensions.yml`): `extension`, `command`, `enabled`, `optional`, `prompt`, `condition`. The bridge consumes the same shape Spec Kit does; no new entity is introduced.
- **Dispatch contract** (new, instruction-only): the textual rules describing which hooks fire at which lifecycle point and the skip-own-guard exclusion. It is a convention documented in the execute command and SKILL peers, not a new state file or script.

## Success Criteria *(mandatory)*

- **SC-001**: A project with a `before_implement` and `after_implement` hook gets both hooks dispatched by the bridge (verified in the end-user sandbox).
- **SC-002**: The bridge never fires its own `speckit-superpowers-bridge` hooks during implement dispatch (verified by the documented skip rule + smoke test).
- **SC-003**: `bash tests/run-all.sh` is 7/7 green on the release commit, including the new `test-implement-hooks-dispatch.sh`.
- **SC-004**: All seven release-checklist files carry `1.2.0` so a tag run of `validate-release-readiness.ps1 -Version 1.2.0` passes on version grounds.

## Assumptions

- Spec Kit's hook dispatch is markdown/instruction-driven (confirmed by inspecting `core_pack/commands/implement.md` in the installed Spec Kit CLI); the bridge mirrors that mechanism rather than adding a script (constitution Principle VI).
- The bridge's only `before_implement` hook is its guard; skipping all hooks with `extension == speckit-superpowers-bridge` is equivalent to skipping just the guard today and is future-proof.
- The release/tag publish step (and its published-artifact sandbox cycle) is deferred to the maintainer, as in prior features; this feature lands the in-repo change and commits it.
