# Feature Specification: Spec Kit Superpowers Bridge

**Feature Branch**: `001-spec-superpowers-bridge`  
**Created**: 2026-05-14  
**Status**: Draft  
**Input**: User description: "我们的最终目标是开发出一个spec kit 插件拓展，设计一种协议把superpower和speckit结合起来取长补短，以speckit为主干，同时兼容codex和claudecode。（接下来我也顺便采用我们的新流程进行开发，测试下功能如何，测试结果也将用于反馈改进）当前已经完成了初版的开发。"

## Clarifications

### Session 2026-05-14

- Q: How should the bridge handle shared protocol instructions across Codex and Claude Code? -> A: `AGENTS.md` is the master cross-agent protocol; `CLAUDE.md` is a Claude-only supplement that must instruct Claude Code to read and follow `AGENTS.md`.
- Q: How should the bridge handle Spec Kit's single `default_integration` when both Codex and Claude Code integrations are installed? -> A: The protocol must explicitly separate internal dotted command IDs from agent invocation syntax: Claude Code uses slash-hyphen commands such as `/speckit-plan`; Codex uses `$speckit-*`; switching `default_integration` must not change the feature contract.
- Q: How should official integration skill files be customized across Codex and Claude Code? -> A: Do not hand-edit official `.agents/skills/speckit-*` or `.claude/skills/speckit-*`; keep custom protocol in separate bridge skills and upgrade both integrations with official Spec Kit commands.
- Q: How should concurrent Codex and Claude Code access to Spec Kit artifacts be controlled? -> A: Only one agent may own write access to Spec Kit artifacts at a time; the other agent is review-only until ownership changes or the handoff is blocked for repair.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Hand Off Spec Kit Work To Superpowers (Priority: P1)

A project maintainer who uses Spec Kit for specification and planning wants implementation to be executed through Superpowers discipline without losing Spec Kit as the source of truth.

**Why this priority**: This is the core value of the feature. Without a reliable handoff, the two systems can create competing plans or execute the wrong implementation flow.

**Independent Test**: Can be tested by preparing a feature with completed specification, plan, and task artifacts, then verifying that the bridge declares Superpowers as the executor while preserving those artifacts as the only implementation contract.

**Acceptance Scenarios**:

1. **Given** a feature has completed Spec Kit artifacts, **When** the maintainer creates the bridge handoff, **Then** the handoff identifies the active feature, the source-of-truth artifacts, Superpowers as executor, and the Spec Kit implementation flow as superseded.
2. **Given** a handoff exists for an active feature, **When** an implementation agent starts work, **Then** it reads the Spec Kit artifacts before executing tasks and does not create a competing plan.
3. **Given** no active feature exists, **When** the handoff is refreshed, **Then** the system records a ready state with a clear note that no feature is active.

---

### User Story 2 - Prevent Overlapping Planning And Implementation (Priority: P2)

A maintainer wants the combined workflow to block actions that would cause Spec Kit and Superpowers to overlap responsibilities after a feature has reached the implementation handoff.

**Why this priority**: The workflow must prevent accidental divergence once real implementation begins, especially when agents automatically select skills or commands.

**Independent Test**: Can be tested by attempting prohibited actions against a bridged feature and verifying that they are denied with an actionable reason.

**Acceptance Scenarios**:

1. **Given** a bridged feature is assigned to Superpowers execution, **When** the Spec Kit implementation command is requested, **Then** the request is denied with an explanation that Superpowers owns execution.
2. **Given** a feature already has completed Spec Kit specification, plan, and task artifacts, **When** Superpowers planning or brainstorming is requested for that feature, **Then** the request is denied unless the user explicitly chooses to discard or replace the Spec Kit artifacts.
3. **Given** a handoff status is executing or complete, **When** a Spec Kit command would change the specification, plan, or task contract, **Then** the request is denied until the handoff is marked blocked for repair.

---

### User Story 3 - Audit And Recover Handoff State (Priority: P3)

A maintainer testing the new process wants lightweight logs and rollback points so the bridge behavior can be inspected and corrected without affecting implementation source code.

**Why this priority**: Early adoption and feedback require visibility into what the bridge allowed, denied, or changed, while keeping rollback focused and low risk.

**Independent Test**: Can be tested by creating a handoff, triggering guard decisions, restoring a snapshot, and reviewing the event log.

**Acceptance Scenarios**:

1. **Given** a handoff state changes, **When** the bridge records the transition, **Then** an event is appended with time, action, status, feature, decision, reason, actor, and snapshot reference.
2. **Given** a feature's control artifacts are snapshotted, **When** a maintainer restores a snapshot, **Then** the specification, plan, tasks, and handoff state return to the captured values.
3. **Given** implementation source files changed outside the Spec Kit control artifacts, **When** a bridge snapshot is restored, **Then** source changes are not modified by the bridge rollback.

---

### User Story 4 - Use The Bridge From Codex Or Claude Code (Priority: P2)

A maintainer wants the same bridge protocol to work when Spec Kit commands are run from either Codex or Claude Code, without relying on one agent reading the other agent's private instruction files.

**Why this priority**: The feature explicitly targets both Codex and Claude Code. If each agent sees different rules or command styles, the bridge can diverge even when the Spec Kit artifacts are correct.

**Independent Test**: Can be tested by installing both integrations, switching the default integration, and verifying that both agents discover the same ownership protocol while using their own command syntax.

**Acceptance Scenarios**:

1. **Given** both Codex and Claude Code integrations are installed, **When** Codex starts work, **Then** it reads the bridge rules from `AGENTS.md` and uses `$speckit-*` command references.
2. **Given** both integrations are installed, **When** Claude Code starts work, **Then** `CLAUDE.md` instructs Claude Code to read `AGENTS.md` first and uses slash-hyphen command references such as `/speckit-plan` only for Claude-specific invocation examples.
3. **Given** `specify integration use <key>` changes the default integration, **When** shared templates or generated instructions are refreshed, **Then** the bridge protocol still declares the explicit Codex and Claude Code command syntax mapping.
4. **Given** Codex is writing Spec Kit artifacts for an active feature, **When** Claude Code attempts to run a Spec Kit command that would modify the same artifacts, **Then** the action is denied or deferred as review-only until artifact write ownership changes.

---

### Edge Cases

- A user explicitly asks to discard or replace existing Spec Kit artifacts before using Superpowers planning.
- A feature has only some required artifacts, such as a specification without tasks.
- A handoff exists but points to a feature directory that was moved or removed.
- A maintainer uses Codex for one feature and Claude Code for another in the same repository.
- A command is requested while the handoff is marked complete but the user wants to reopen the feature.
- The initial bridge implementation itself is used as the test subject and reveals gaps in the protocol.
- Claude Code integration is installed after Codex and `.claude/skills` or `CLAUDE.md` is missing the bridge protocol.
- The default Spec Kit integration is switched mid-feature and generated command examples use a different command style than the current agent.
- Codex and Claude Code both attempt to modify `spec.md`, `plan.md`, `tasks.md`, checklists, or `.specify` bridge state at the same time.
- `AGENTS.md` and `CLAUDE.md` contain conflicting bridge rules.
- An official integration upgrade detects local edits in generated Spec Kit skill files and refuses to overwrite them.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST define a clear ownership boundary where Spec Kit owns specification, planning, task generation, consistency checks, and feature artifacts.
- **FR-002**: The system MUST define Superpowers as the owner of implementation discipline, including isolated execution, test-first work, debugging, reviews, verification, and finishing steps.
- **FR-003**: The system MUST provide a handoff record that identifies the active feature, source-of-truth artifacts, executor, superseded commands, current status, and actionable instructions.
- **FR-004**: The system MUST prevent the Spec Kit implementation flow from running for a feature handed off to Superpowers.
- **FR-005**: The system MUST prevent Superpowers brainstorming or planning from redefining a completed Spec Kit feature unless the user explicitly discards or replaces the existing Spec Kit artifacts.
- **FR-006**: The system MUST allow Superpowers execution workflows only when they use the Spec Kit task artifact as the implementation contract.
- **FR-007**: The system MUST allow Spec Kit repair commands when the handoff is intentionally marked blocked.
- **FR-008**: The system MUST record allow, deny, handoff, snapshot, and rollback events in an append-only audit log.
- **FR-009**: The system MUST provide rollback for Spec Kit control artifacts without modifying implementation source files.
- **FR-010**: The system MUST support both Codex and Claude Code as intended agent environments for the combined workflow.
- **FR-011**: The system MUST keep the original Spec Kit and Superpowers installations structurally intact rather than deleting bundled commands or global skills.
- **FR-012**: The system MUST make testing the bridge on its own development process an accepted feedback source for future refinements.
- **FR-013**: The system MUST treat `AGENTS.md` as the master cross-agent protocol for the bridge.
- **FR-014**: The system MUST provide `CLAUDE.md` as a Claude Code supplement that instructs Claude Code to read and follow `AGENTS.md` before applying Claude-specific command syntax.
- **FR-015**: The system MUST document the supported command syntax for each agent environment: internal command IDs use dotted names such as `speckit.plan`, Claude Code uses slash-hyphen commands such as `/speckit-plan`, and Codex uses `$speckit-*`.
- **FR-016**: The system MUST remain correct when `specify integration use <key>` changes Spec Kit's default integration and refreshes shared command references.
- **FR-017**: The system MUST keep custom bridge behavior in separate bridge skills for each agent integration rather than modifying official generated `speckit-*` skills.
- **FR-018**: The system MUST define an official upgrade procedure that upgrades both integrations with Spec Kit commands and treats generated integration skills as vendor-managed assets.
- **FR-019**: The system MUST enforce single-writer ownership for Spec Kit artifacts so Codex and Claude Code cannot concurrently modify the same active feature contract.
- **FR-020**: The system MUST allow the non-owner agent to review Spec Kit artifacts without writing them.

### Key Entities *(include if feature involves data)*

- **Bridge Handoff**: The current machine-readable ownership state for a feature, including feature directory, source-of-truth artifacts, executor, superseded flows, status, notes, and latest snapshot.
- **Guard Decision**: A recorded allow or deny outcome for a requested command or skill, including reason and feature context.
- **Bridge Event**: An audit entry that records handoff updates, guard decisions, snapshots, and rollbacks.
- **Bridge Snapshot**: A point-in-time copy of Spec Kit control artifacts used for rollback.
- **Feature Artifact Set**: The specification, plan, tasks, checklists, and related design artifacts that define a feature's contract.
- **Agent Context File**: A project instruction file read by a specific agent environment, including `AGENTS.md` for Codex and `CLAUDE.md` for Claude Code.
- **Integration Installation**: A Spec Kit integration entry and its generated command or skill files for a supported agent environment.
- **Artifact Write Ownership**: The current exclusive right for one agent environment to modify Spec Kit control artifacts for an active feature while other agents remain review-only.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A maintainer can complete the handoff from Spec Kit artifacts to Superpowers execution in under 2 minutes after tasks are generated.
- **SC-002**: 100% of prohibited overlap actions in the defined disruption matrix are denied with a clear reason during validation.
- **SC-003**: 100% of handoff state changes and guard decisions are recorded in the audit log during validation.
- **SC-004**: A maintainer can restore a previous Spec Kit control snapshot in under 1 minute without changing implementation source files.
- **SC-005**: The same documented workflow can be followed successfully in both Codex and Claude Code environments without changing the feature contract.
- **SC-006**: At least one real development pass using this bridge produces actionable feedback that can be traced to event logs, snapshots, or guard outcomes.
- **SC-007**: Both Codex and Claude Code can discover the same bridge protocol from their expected context files without reading each other's private skill directories.
- **SC-008**: Switching the Spec Kit default integration does not change the documented command mapping or ownership boundary for an active feature.
- **SC-009**: A validation attempt where two agents try to write the same Spec Kit artifact is denied, deferred, or logged before the artifact is overwritten.

## Assumptions

- Spec Kit remains the primary workflow trunk for feature discovery, specification, planning, task creation, and consistency checks.
- Superpowers is used as an implementation discipline layer, not as a replacement planning system once Spec Kit artifacts exist.
- The safest v1 approach is project-level protocol and guard enforcement, not editing global Superpowers plugin files.
- Compatibility with Codex and Claude Code means equivalent behavior and instructions across both environments, not identical internal integration mechanics.
- A repository may install both integrations in either order, such as initializing with Claude Code and installing Codex later, or initializing with Codex and installing Claude Code later.
- Spec Kit records one `default_integration` even when multiple integrations are installed; bridge rules must not depend on that value alone.
- Official integration skill directories such as `.agents/skills` and `.claude/skills` are separate generated copies and must be upgraded separately.
- Source-code rollback remains the responsibility of Git or isolated workspaces; bridge rollback is limited to Spec Kit control artifacts.
- The existing initial implementation is treated as a prototype that may be revised based on this formal specification and live workflow testing.
