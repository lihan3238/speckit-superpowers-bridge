# Feature Specification: Complete Bridge Protocol

**Feature Branch**: `002-complete-bridge-protocol`
**Created**: 2026-05-14
**Status**: Draft
**Input**: User description: "当前已经完成了基础功能实现，不过流程经过测试还有些瑕疵：1. 确定superpower最新全部功能和specify的最新全部功能都已纳入我们的协议考虑，该结合结合该禁止禁止；2. 目前测试发现 speckit的 constitution 和 checklist 似乎没设计在流程内，需确定是否纳入或禁止或被superpower替代；3. 目前经过了codex的流程测试，基本没问题，现在刚好执行这次开发任务，顺便测测claudecode兼容性。"

## Clarifications

### Session 2026-05-15

- Q: How is per-agent parity defined for Spec Kit + bridge skills (e.g. the `speckit-git-*` family)? -> A: 1-to-1 mirror. Every skill that exists in `.agents/skills/` MUST have a peer file under `.claude/skills/` (and vice-versa for any Claude-originating skills), sharing the underlying scripts. Only the invocation syntax differs. Cross-agent compatibility is a hard requirement of the bridge, not an aspirational goal, and is expected to be a small, fast, lightweight change rather than a redesign.
- Q: When is `speckit.constitution` allowed to run? -> A: FORBID-UNDER-HANDOFF with applicability scope `{executing}`. The bridge guard MUST deny `speckit.constitution` only when the active handoff status is `executing`; it MUST allow the command when status is `ready`, `blocked`, or `complete`. Rationale: `blocked` is the repair state where constitution edits may be exactly the fix; `complete` and `ready` carry no in-flight implementation that could be invalidated.
- Q: When is `speckit.checklist` allowed to run? -> A: COMBINE (always allowed). Spec Kit checklist generation produces per-feature spec-time artifacts (e.g. `checklists/requirements.md`); Superpowers `verification-before-completion` runs at implementation time. The two occupy different phases and do not overlap, so checklist runs MUST be permitted regardless of handoff status. The same rule already produced this feature's own requirements checklist during `/speckit-specify`.
- Q: Should bridge handoff state be per-feature or repo-scoped? -> A: Repo-scoped (one `.specify/superpowers-handoff.json`). The bridge MUST add explicit transition rules so that a completed feature's terminal handoff does not block the next feature: starting a new feature (e.g. via `/speckit-specify`) MUST auto-archive any `complete` handoff to `ready` (and snapshot the archived state for audit), and the guard MUST treat `complete` as terminal-but-no-longer-active rather than a global block. This preserves the constitution's "exactly one active handoff per repository" rule while closing the cross-feature blocking bug observed during this clarify session.
- Q: Should the bridge support an explicit override path for forbidden actions? -> A: No. The override mechanism is dropped from the spec (former FR-015 and SC-009 removed). The legitimate repair path is to transition the handoff to `blocked` (which already permits Spec Kit repair commands per the existing protocol); no parallel forced-action API is needed. This removes complexity from the guard, the logging schema, and the documentation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete Capability Disposition Matrix (Priority: P1)

A maintainer needs every Spec Kit command and every Superpowers skill at their currently
verified versions to have an explicit, documented disposition in the bridge protocol —
COMBINE, FORBID-UNDER-HANDOFF, SUPERSEDED-BY, or REVIEW-ONLY — so the workflow has no
silently-allowed or silently-broken capabilities.

**Why this priority**: The original v1 protocol focused on the obvious overlap
(`speckit.implement` vs Superpowers execution) but left many capabilities (constitution,
checklist, analyze, taskstoissues, brainstorming, requesting-code-review, finishing-a-development-branch,
etc.) unaddressed. Until every capability is classified, the bridge cannot guarantee
non-overlap, and upstream version bumps silently widen the gap.

**Independent Test**: Can be tested by listing every Superpowers skill the agent runtime
exposes and every command Spec Kit ships at the verified version, then verifying that
the bridge protocol assigns each one a disposition with a one-line rationale.

**Acceptance Scenarios**:

1. **Given** the bridge protocol is loaded, **When** a maintainer enumerates Superpowers skills and Spec Kit commands at the verified versions, **Then** every item maps to exactly one disposition with a rationale.
2. **Given** an upstream Superpowers or Spec Kit release adds a new capability, **When** the bridge parity check runs, **Then** the check fails until a disposition is recorded for the new capability.
3. **Given** the disposition matrix declares an item as FORBID-UNDER-HANDOFF, **When** that item is invoked while a Superpowers handoff is active, **Then** the bridge guard denies the action with the recorded rationale.
4. **Given** the disposition matrix declares an item as SUPERSEDED-BY, **When** a maintainer invokes the superseded command, **Then** the bridge surfaces the replacement and either redirects or denies based on the recorded policy.

---

### User Story 2 - Constitution and Checklist Workflow Position (Priority: P1)

A maintainer needs the two Spec Kit commands `speckit.constitution` and
`speckit.checklist` placed explicitly on the disposition map so the workflow makes a
deliberate choice between "always allowed", "FORBID while a Superpowers handoff is
active", or "SUPERSEDED-BY a Superpowers equivalent" — instead of the current state
where they are passively allowed without explicit reasoning.

**Why this priority**: Live workflow testing surfaced that these two commands sit
outside the protocol's stated ownership boundary. Constitution edits in particular can
silently change the rules the bridge enforces; checklist generation overlaps with
Superpowers' verification discipline. Both need a documented home.

**Independent Test**: Can be tested by reviewing the bridge protocol and verifying
that each of `speckit.constitution` and `speckit.checklist` has an explicit disposition
entry with a rationale and any required guard coverage in `.specify/extensions.yml`.

**Acceptance Scenarios**:

1. **Given** the protocol is loaded, **When** a maintainer reads the disposition entry for `speckit.constitution`, **Then** the entry records a policy decision (allow / forbid-under-handoff / superseded) and a rationale, and the guard configuration matches the recorded policy.
2. **Given** the protocol is loaded, **When** a maintainer reads the disposition entry for `speckit.checklist`, **Then** the entry records a policy decision (allow / forbid-under-handoff / superseded) and a rationale, and the guard configuration matches the recorded policy.
3. **Given** a Superpowers handoff is active and the recorded policy for one of these commands is FORBID-UNDER-HANDOFF, **When** the command is invoked, **Then** the bridge guard denies the action with the recorded rationale.
4. **Given** the recorded policy for one of these commands is "allow", **When** the command is invoked during a Superpowers handoff, **Then** the bridge guard allows the action and the event log records the allow decision with the policy reference.

---

### User Story 3 - Claude Code End-to-End Workflow Parity (Priority: P1)

A maintainer using Claude Code needs to run the documented bridge happy path
(constitution → specify → clarify → plan → tasks → handoff → bridge-driven implementation)
without falling back to Codex-only assets. Every gap discovered during the live Claude
Code validation run MUST be captured as a remediation item with a proposed fix, before
the feature is considered shipped.

**Why this priority**: Codex was already validated end-to-end. The Claude Code path has
known divergence at the hook layer (e.g., `.claude/skills/` lacks `speckit-git-*` slash
commands that `.specify/extensions.yml` references). Without explicit parity, the
"works in Codex and Claude Code" promise is aspirational rather than verified.

**Independent Test**: Can be tested by running the documented happy path from Claude
Code in this repository and recording each command that fails, each hook that points to
a non-existent slash command, and each script that requires an unsanctioned manual
workaround.

**Acceptance Scenarios**:

1. **Given** Claude Code is the active agent, **When** the maintainer runs each command in the documented happy path (constitution, specify, clarify, plan, tasks, handoff, bridge), **Then** every command executes through the standard Claude Code invocation surface (slash commands or registered skills) without invoking PowerShell scripts directly as an unsanctioned workaround.
2. **Given** `.specify/extensions.yml` declares a hook command, **When** the bridge parity check inspects each declared hook, **Then** the check fails if any declared hook command lacks an equivalent invocation surface for any supported agent unless the hook is explicitly marked agent-scoped.
3. **Given** a Claude Code validation run discovers a compatibility gap, **When** the run completes, **Then** every discovered gap is recorded as a remediation entry with a one-line proposed resolution in the feature artifacts.
4. **Given** the same documented happy path is run from Codex, **When** the maintainer compares the resulting bridge events and handoff state, **Then** the feature contract, artifact ownership transitions, and guard decisions are equivalent across agents (modulo the recorded actor field).

---

### User Story 4 - Verified Upstream Version Pinning (Priority: P2)

A maintainer needs the bridge to record which Spec Kit version and which Superpowers
version it has been verified against, so that disposition decisions are reproducible
and an upstream version bump becomes an explicit re-verification event rather than a
silent drift.

**Why this priority**: Disposition decisions depend on the exact set of commands and
skills available upstream. Without a verified-version pin, the matrix becomes stale
the next time either tool ships a release.

**Independent Test**: Can be tested by reading the bridge metadata, finding the
verified Spec Kit and Superpowers versions, and confirming that the parity check
compares the live installed versions against the verified ones and surfaces a warning
when they differ.

**Acceptance Scenarios**:

1. **Given** the bridge protocol is loaded, **When** the maintainer reads the verified-version metadata, **Then** the file declares an exact verified Spec Kit version and an exact verified Superpowers version.
2. **Given** the installed Spec Kit or Superpowers version differs from the verified version, **When** the parity check runs, **Then** the check reports the drift and recommends re-verification before relying on the disposition matrix.

---

### Edge Cases

- An upstream Superpowers release renames or removes a skill that the disposition matrix referenced — the parity check must surface the rename/removal, not silently treat the entry as missing.
- An upstream Spec Kit release adds a new command without a hook in `.specify/extensions.yml` — the parity check must still classify it.
- A hook in `.specify/extensions.yml` is registered for a command that only one agent has a peer skill for — this is the gap pattern that this feature must close, not paper over with agent-scoping.
- The active agent invokes a capability marked REVIEW-ONLY for that agent — the guard must allow read-only operations but deny writes.
- A maintainer manually invokes the underlying PowerShell or Bash script when the agent's slash command is missing — the bridge protocol must record this as a tracked compatibility gap with a proposed peer-skill fix, not as a long-term sanctioned recovery path.
- Constitution amendments occur while a Superpowers handoff for another feature is active — the protocol must specify whether constitution edits are scoped to the active handoff or are repo-wide and therefore guarded differently.
- A user explicitly forces a command that the disposition matrix forbids — out of scope. The bridge does not provide a forced-action override; the legitimate path is to transition the handoff to `blocked` for repair.
- The Claude Code happy-path run discovers more compat gaps than fit in a single feature — the protocol must allow deferring lower-priority gaps to a follow-up feature without leaving them un-recorded.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The bridge MUST maintain a machine-readable disposition matrix that lists every Spec Kit command and every Superpowers skill at the verified upstream versions, and assigns each item exactly one disposition: COMBINE, FORBID-UNDER-HANDOFF (with an applicability scope naming which handoff statuses trigger the forbid), SUPERSEDED-BY, or REVIEW-ONLY.
- **FR-002**: Each disposition entry MUST include a human-readable rationale and, where applicable, a pointer to the replacement command or skill. FORBID-UNDER-HANDOFF entries MUST also declare the handoff-status scope that triggers the deny (any non-empty subset of `executing`, `blocked`, `complete`).
- **FR-003**: The bridge guard MUST consult the disposition matrix when deciding allow/deny outcomes; the matrix is the source of truth for non-overlap policy.
- **FR-004**: The disposition matrix MUST classify `speckit.constitution` and `speckit.checklist` with an explicit decision and rationale. `speckit.constitution` is classified FORBID-UNDER-HANDOFF with applicability scope `{executing}`: the bridge guard denies the command only while the active handoff status is `executing`, and allows it when status is `ready`, `blocked`, or `complete`. `speckit.checklist` is classified COMBINE (always allowed) because Spec Kit checklist generation is a spec-time artifact orthogonal to Superpowers `verification-before-completion`.
- **FR-005**: The bridge MUST provide a parity check capability that reports, for the current installation, any item with no disposition, any disposition pointing to a missing replacement, and any guard configuration inconsistent with the matrix.
- **FR-006**: The bridge MUST record the verified Spec Kit and Superpowers versions in a single canonical location and MUST surface a drift warning when the installed versions differ from the verified versions.
- **FR-007**: For every hook command declared in `.specify/extensions.yml`, the bridge MUST provide a 1-to-1 invocation surface for every supported agent (a peer skill file under both `.agents/skills/` and `.claude/skills/`, sharing the underlying scripts); agent-scoping a hook is NOT an accepted resolution and any agent-scoped hook MUST cause the parity check to fail.
- **FR-008**: Spec Kit commands whose hook references a missing invocation surface for the active agent MUST surface a remediable error to the user, not be silently skipped; the long-term fix is to add the missing peer skill, not to mark the hook agent-scoped.
- **FR-009**: Every documented happy-path command MUST be executable from each supported agent via that agent's standard invocation surface (slash commands for Claude Code, `$speckit-*` commands for Codex); direct PowerShell or Bash script invocation is permitted only as a short-term recovery path with a recorded rationale and MUST become a tracked remediation item rather than a permanent state.
- **FR-010**: A live Claude Code validation pass MUST be performed for the documented happy path; every compatibility gap discovered MUST be recorded with a proposed resolution before the feature is considered complete.
- **FR-011**: Adding or upgrading a Superpowers skill or Spec Kit command MUST require explicit disposition entry before the parity check passes; the bridge MUST NOT auto-classify new capabilities.
- **FR-012**: When a disposition entry is FORBID-UNDER-HANDOFF, the bridge guard MUST deny the action only when an active Superpowers handoff exists for the affected feature; the action MUST be allowed when no active handoff is present.
- **FR-013**: When a disposition entry is SUPERSEDED-BY, the bridge MUST surface the named replacement to the user and either redirect the request or deny it based on the recorded policy.
- **FR-014**: The bridge protocol documentation (`AGENTS.md`, `CLAUDE.md`, the bridge skill files) MUST be consistent with the disposition matrix; any conflict MUST be flagged by the parity check.
- **FR-015**: The bridge MUST keep handoff state repo-scoped (one `.specify/superpowers-handoff.json`) and MUST define explicit transition rules so that a `complete` handoff does not block work on a subsequent feature. Specifically: when a new feature begins (e.g. via `/speckit-specify`), any existing `complete` handoff MUST be auto-archived to `ready` (with a snapshot retained for audit), and the guard MUST treat `complete` as terminal-but-no-longer-active rather than a global block on contract changes.

### Key Entities

- **Disposition Entry**: A single record naming a Spec Kit command or Superpowers skill, its disposition (COMBINE, FORBID-UNDER-HANDOFF, SUPERSEDED-BY, REVIEW-ONLY), a rationale, optional replacement pointer, and (for FORBID-UNDER-HANDOFF entries) an applicability scope: a non-empty subset of the handoff statuses `executing`, `blocked`, `complete` that triggers the deny.
- **Disposition Matrix**: The full set of disposition entries; the canonical non-overlap policy consulted by the bridge guard.
- **Verified Versions Record**: A pinned declaration of the Spec Kit version and Superpowers skill-pack version that the disposition matrix was verified against.
- **Parity Check Report**: The output of running the parity check — lists missing dispositions, missing per-agent surfaces, missing replacements, and version drift.
- **Compatibility Gap Record**: An entry surfaced by a Claude Code (or Codex) validation run describing one discovered gap, with severity and a proposed resolution.
- **Agent Invocation Surface**: For a given capability and agent, the actual command syntax the agent runtime exposes (a Claude Code slash command, a Codex `$speckit-*` command, a registered Superpowers skill, or "absent").

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of Spec Kit commands and Superpowers skills available at the verified versions are classified in the disposition matrix with a non-empty rationale.
- **SC-002**: `speckit.constitution` and `speckit.checklist` each carry an explicit, documented disposition and a guard configuration consistent with that disposition.
- **SC-003**: The documented happy path (constitution → specify → clarify → plan → tasks → handoff → bridge) completes end-to-end in Claude Code with at most one recorded sanctioned recovery path per command, and zero unrecorded fallbacks.
- **SC-004**: 0 hook commands in `.specify/extensions.yml` reference an invocation surface that is missing for a supported agent without being explicitly agent-scoped.
- **SC-005**: The parity check completes in under 30 seconds on a clean checkout and produces a deterministic report identifying any missing dispositions, replacements, or per-agent surfaces.
- **SC-006**: A simulated upstream version bump (introducing a new test capability) causes the parity check to fail until a disposition is added — verified at least once during validation.
- **SC-007**: Every compatibility gap surfaced during the Claude Code validation run is captured as a Compatibility Gap Record with severity and proposed resolution; 100% of P0/P1 gaps are resolved within this feature or explicitly deferred to a named follow-up.
- **SC-008**: Constitution and checklist behavior under an active Superpowers handoff matches the recorded policy in at least one positive and one negative test for each command.
- **SC-009**: Starting a new feature while a `complete` handoff exists for a prior feature succeeds without manual intervention: the prior handoff is auto-archived to `ready` (with a snapshot recorded) and the new feature's `/speckit-clarify`, `/speckit-plan`, `/speckit-tasks` pass the guard out of the box.

## Assumptions

- Spec Kit `0.8.9` (per `.specify/init-options.json`) and the Superpowers skill set currently exposed to the active agent are the verified baseline for this iteration; later versions are out of scope unless re-verified.
- The Claude Code validation run is performed in this repository using this feature's own workflow, so the validation evidence lives alongside the spec, plan, tasks, and event log for the feature.
- The disposition matrix can live as a machine-readable file inside the bridge extension (concrete file location and format are a planning decision, not a spec decision).
- Manual recovery paths (direct PowerShell or Bash script invocation) remain permitted for unblocking the workflow, but each one must be either sanctioned in the protocol with a rationale or surfaced as a remediation item.
- The bridge continues to follow the constitution: lightweight, repo-local, agent-neutral, smooth handoff, vendor-managed boundaries. Solving the gaps in this feature MUST NOT introduce a marketplace package, a daemon, or global plugin edits.
- Hooks currently registered as Codex-only (because Claude Code lacks the corresponding skill) are NOT acceptable as a permanent state. Each must be closed by adding a 1-to-1 peer skill under `.claude/skills/` (sharing the existing scripts) before the feature is considered complete; introducing an agent-scoping annotation as a workaround is explicitly out of scope.
- The currently active Superpowers handoff (for feature 001) is in `status: complete`; this feature establishes its own handoff after `/speckit-tasks`, owned by Claude Code as the active agent for this run.
