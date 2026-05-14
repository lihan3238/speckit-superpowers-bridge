# Feature Specification: Polish & Publish

**Feature Branch**: `004-polish-and-publish`
**Created**: 2026-05-15
**Status**: Draft
**Input**: User description: "1.speckit init的 默认模型有git相关skill，integration的没有，调研这个是特性还是bug，并兼容（自动检测项目default是什么，并改动所有涉及speckit.git.commit相关调用）；2. 轻重任务流；3. 不够自动化多处打断，特别是开发执行阶段希望全自动无人监管；4. 无论被动主动中断，提示继续是否需要带上正在进行的任务的skill指令；5. .\\.specify\\extensions\\speckit-superpowers-bridge\\scripts\\powershell\\update-handoff.ps1 -Status ready 不能自动识别codex和claude，所以有时搞错；6. 确定下流程在claudecode中主要功能是否正常，有无其他大bug，superpower和speckit都在该执行的地方调用了吗；7. codex和claude的skill是否同步更新，需要与否及如何使用specify integration upgrade；8. 我期望将我们的插件上架到speckit官方市场，参考其他插件对齐双语readme和合适的文档，如果需要的话；9. 考虑到插件上架，是否有功能和文件需要gitignore或在以插件形式被其他人安装时遗漏。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Autonomous Implementation with Light/Heavy Task Flow (Priority: P1)

A maintainer running an implementation pass through `/speckit-superpowers-bridge` wants the bridge to drive long stretches of mechanical tasks without prompting, while still pausing at architecturally significant tasks. When work is interrupted (auto or manual), the resume signal must carry which task and which skill were in flight so the next session picks up at the exact context, not at the top.

**Why this priority**: The current bridge interrupts the user at roughly every phase boundary and at many task boundaries. Live test runs show this prevents truly hands-off implementation passes — the user's stated goal. Without classification + auto-resume context, longer features become painful and the bridge loses its core value of letting Spec Kit + Superpowers cooperate cleanly.

**Independent Test**: Can be tested by adding a `[Auto]` (or equivalent classification) marker to a sample subset of tasks, running the bridge under autonomous mode, and verifying the bridge proceeds through marked tasks without confirmation prompts; then interrupting mid-run and confirming the resume message includes the active task ID and the in-progress Superpowers skill name.

**Acceptance Scenarios**:

1. **Given** `tasks.md` carries a classification per task (light vs heavy), **When** `/speckit-superpowers-bridge` runs in autonomous mode, **Then** light tasks proceed without confirmation pauses and heavy tasks pause for explicit approval with a one-line rationale.
2. **Given** an implementation session is interrupted (auto, by tool limit, or by user), **When** the next session resumes, **Then** the resume signal explicitly names the last in-progress task ID, the active Superpowers skill (e.g. `superpowers:executing-plans`), and the next expected action, so the agent can pick up without re-reading the full plan from scratch.
3. **Given** autonomous mode is enabled, **When** the bridge encounters a task with no classification, **Then** it defaults to safe (treats as heavy, pauses) rather than auto-running with no signal.
4. **Given** a maintainer disables autonomous mode (default off), **When** any task runs, **Then** the bridge falls back to the current confirmation behavior with no regressions.

---

### User Story 2 — Correct Cross-Agent Skill Sync and Actor Detection (Priority: P1)

A maintainer who installs Codex first and Claude Code later (or vice versa) wants the bridge to detect what's actually installed (git extension yes/no, which integrations are active, which is `default_integration`) and adapt every reference to `speckit.git.*` accordingly. Separately, when any bridge script runs without an explicit `-Actor`, it must auto-detect the calling agent rather than defaulting to a hard-coded one and silently flipping artifact ownership.

**Why this priority**: Live tests during features 002 + 003 surfaced two distinct gaps: (a) the git extension's per-agent skill files do not auto-mirror when a new integration is added later, so hooks referencing `speckit.git.commit` may silently fail for the late-added agent; (b) `update-handoff.ps1 -Status ready` hard-codes `-Actor "speckit-superpowers-bridge"` and the per-command template hard-codes `-Actor codex`, both of which flip ownership incorrectly when invoked from the other agent. Both are reproducible bridge defects.

**Independent Test**: Can be tested by (a) inspecting any project where Codex was installed first and Claude added later, running the bridge's installation-state audit, and verifying the audit reports the git extension presence + integration state + default integration without manual configuration; (b) invoking `update-handoff.ps1 -Status ready` from Claude Code without `-Actor`, and confirming `artifact_owner` ends up as `claude`, not as `codex` or `unknown`.

**Acceptance Scenarios**:

1. **Given** the bridge is invoked in a project where the git extension is installed but only one agent integration is active, **When** the install-state audit runs, **Then** the audit reports the active integrations, the default integration, the git extension state, and any per-agent skill gaps with a concrete remediation command.
2. **Given** a maintainer ran `specify init` with one agent and later `specify integration add <other>`, **When** the bridge runs, **Then** it detects the new integration is missing the git-extension peer skills and either offers to mirror them or invokes `specify integration upgrade` per the documented protocol.
3. **Given** `update-handoff.ps1` is invoked without an explicit `-Actor`, **When** the script runs, **Then** it auto-detects the calling agent from the project's `default_integration` (and/or any agent-identifying environment signal) rather than hard-coding a value.
4. **Given** the bridge surfaces a hook command (e.g. `speckit.git.commit`) for an agent that lacks the underlying peer skill, **When** the agent invocation surface is missing, **Then** the bridge reports a remediable error naming the precise sync command, not a silent skip.

---

### User Story 3 — End-to-End Claude Code Validation Pass (Priority: P1)

A maintainer wants confidence that the full Spec Kit + Superpowers workflow operates correctly under Claude Code, with every hook firing where it should, every Superpowers skill invoked at its intended point in the lifecycle, and no silently-skipped steps. Any newly-discovered gap must be recorded with severity and proposed fix, just like feature 002.

**Why this priority**: Codex was validated in feature 001; Claude Code was validated in feature 002 but only for the bridge plugin itself, not for every interaction with every upstream Spec Kit command + Superpowers skill. Without a checked end-to-end matrix, regressions can hide in any of the ~30 entry points the disposition matrix lists.

**Independent Test**: Can be tested by running a "validation pass" command that walks the documented happy path (`/speckit-constitution` → `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-superpowers-bridge` → completion) under Claude Code, asserts each step's expected before/after state, and outputs a per-step pass/fail report.

**Acceptance Scenarios**:

1. **Given** a fresh feature branch under Claude Code, **When** the validation pass runs, **Then** every Spec Kit core command resolves through its Claude slash command (zero PowerShell-direct invocations as unsanctioned workarounds), every extension hook fires, every Superpowers skill is invoked at its intended phase, and the bridge events log records each step.
2. **Given** the validation pass discovers a step that fails or behaves unexpectedly, **When** the run completes, **Then** that step is captured as a new compatibility-gap record (CG-NNN) in `compat-gaps.md` with severity, observed-vs-expected behavior, and proposed fix.
3. **Given** the validation pass completes with zero P0/P1 gaps, **When** the maintainer marks the feature ready, **Then** the bridge records a `feature_validation_pass` event referencing the validated revision.
4. **Given** the validation pass identifies that Superpowers `requesting-code-review` or `verification-before-completion` was NOT invoked at the bridge's completion phase, **When** this is reported, **Then** the bridge documentation (`AGENTS.md`, `CLAUDE.md`, bridge SKILL.md) explicitly lists which Superpowers skills are mandatory at which lifecycle points.

---

### User Story 4 — Marketplace Publication Readiness (Priority: P2)

A maintainer wants the bridge to be installable from the Spec Kit official marketplace by other users with one command (or however official extensions are distributed), with documentation that matches the conventions other Spec Kit plugins use (including bilingual Chinese/English READMEs), and with a clear boundary between "plugin code that ships" and "project state that stays local".

**Why this priority**: The bridge has value beyond this repository, but only if it can be cleanly packaged. Marketplace packaging surfaces packaging discipline issues (gitignore, lockfile hygiene, sample state files, schema files) that need to be addressed before publication. Lower priority than the other three because the bridge can be used here-and-now without marketplace presence.

**Independent Test**: Can be tested by cloning the repo into a clean directory, installing the bridge via the documented installation path (the same way Spec Kit marketplace listings advertise install), and verifying: (a) only the plugin-relevant files land in the target project, (b) no user-private state from the source repo is copied, (c) the bilingual README renders correctly and matches at least one peer plugin's structure, (d) the installed plugin passes its own parity check.

**Acceptance Scenarios**:

1. **Given** the marketplace listing metadata exists in the repo, **When** a user runs the documented install command, **Then** the bridge extension lands at `.specify/extensions/speckit-superpowers-bridge/`, the bridge skills land in both `.agents/skills/` and `.claude/skills/` (per active integrations), and zero user-private state files (handoff, events log, snapshots, feature directories) are copied.
2. **Given** the README is opened on the marketplace listing page, **When** the reader switches between Chinese and English, **Then** both versions cover the same install steps, the same usage example, and the same configuration surface, with mutual links between language variants.
3. **Given** the installed plugin runs in a host project, **When** the parity check executes, **Then** the disposition matrix, verified-versions record, and all expected files are present and valid (the same `exit 0` signal as in the home repo).
4. **Given** the repository's `.gitignore` is reviewed for marketplace readiness, **When** it is inspected, **Then** project-private state (`.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/`, `.specify/superpowers-handoff.json`, `.specify/feature.json`, optionally `specs/`) is excluded from the plugin distribution, and the rationale is recorded next to each ignore rule.

---

### Edge Cases

- A project has the git extension installed but no integrations active (uncommon but possible during init); hook commands referencing `speckit.git.*` cannot resolve to any skill.
- A project has multiple integrations but `default_integration` is unset; actor detection must have a deterministic fallback.
- A bridge script runs inside a CI environment where no agent is "active"; actor detection must accept an explicit override via env var.
- A task in `tasks.md` is misclassified (heavy task tagged as light); autonomous mode runs it without confirmation and breaks downstream — the bridge must still log enough context to recover.
- The user pauses mid-task; the next resume should not redo completed work in the same task (idempotency at task granularity).
- The marketplace install lands the bridge into a repo that already has a partially-installed earlier version; install must be safe (no overwrite of user-modified files; clear report of conflicts).
- `specify integration upgrade` is run between releases of upstream Spec Kit; the bridge's own files must not be clobbered (vendor-managed boundary respected).
- The bilingual README falls out of sync between Chinese and English; the build/check should flag this rather than ship inconsistent docs.
- A user installs the plugin in an environment that has Codex but not Claude Code, or vice versa; the install must succeed for the available integration(s) and clearly defer the missing peer until that integration is added.
- The bridge's parity check itself is part of the validation pass (US3); if the parity check is broken, the validation pass must still detect that brokenness, not silently succeed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The bridge MUST provide an install-state audit that reports, for the current project: installed integrations, default integration, git extension presence, per-agent skill parity, and the project's `script` flavour (ps/sh), in a single machine-readable output.
- **FR-002**: When the git extension is installed and any integration adds a new agent later, the bridge MUST detect the resulting per-agent skill gap and provide an explicit remediation path (either auto-mirror or a documented `specify integration upgrade` invocation) rather than failing silently at hook time.
- **FR-003**: All bridge scripts that currently default `-Actor` to a hard-coded value MUST instead resolve the actor in this order: (a) explicit `-Actor` argument, (b) an agent-identifying environment variable, (c) `.specify/integration.json.default_integration`, (d) a single deterministic fallback documented in `AGENTS.md`. The bridge MUST NOT default `-Actor codex` simply because Codex was historically first.
- **FR-004**: `tasks.md` MUST support a classification marker per task — at minimum a binary "auto-runnable vs needs-confirmation" signal — that the bridge consults when running in autonomous mode. Tasks without a classification MUST be treated as needs-confirmation by default (safe-by-default).
- **FR-005**: The bridge MUST support an explicit autonomous-mode flag (off by default). When autonomous mode is on, the bridge proceeds through auto-runnable tasks without prompting; when off, current behavior is preserved.
- **FR-006**: Whenever the bridge is interrupted (auto or manual), the bridge MUST persist the last-active task ID, the active Superpowers skill (if any), the active phase, and the next-expected action, in a deterministic location readable on resume.
- **FR-007**: A resumed bridge session MUST emit a one-line resume signal naming the active task ID, the active skill, and the next-expected action before any other output.
- **FR-008**: The bridge MUST provide an end-to-end Claude Code validation pass that walks the documented happy path, asserts each step's expected before/after state, captures any deviation as a Compatibility Gap Record, and produces a deterministic pass/fail report.
- **FR-009**: The validation pass MUST verify that Superpowers skills (`test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `finishing-a-development-branch`) are invoked at their intended lifecycle points, and report missing invocations as findings.
- **FR-010**: The bridge protocol documentation (`AGENTS.md`, `CLAUDE.md`, bridge SKILL.md on each agent) MUST list, for each Superpowers skill the bridge consumes, the exact lifecycle phase at which it is invoked and what triggers it.
- **FR-011**: The bridge MUST provide a documented procedure for keeping Codex and Claude skill copies in sync, including the canonical invocation of `specify integration upgrade` and the manual fallback when the upstream Spec Kit CLI does not auto-mirror extension skills.
- **FR-012**: The bridge MUST surface, in its install-state audit, whenever Codex-side and Claude-side bridge skill files have diverged in content (post-upgrade or post-edit) and recommend a re-sync.
- **FR-013**: The repository MUST include marketplace-listing metadata in the format the Spec Kit marketplace requires (concrete format determined by upstream conventions; see Assumptions).
- **FR-014**: The repository MUST ship a bilingual README (Chinese + English) at the root and/or as `README.md` + `README.zh-CN.md` (per Spec Kit convention) with mutually-linked navigation. Both language versions MUST cover identical scope: installation, usage example, configuration surface, troubleshooting.
- **FR-015**: The repository MUST include a `.gitignore` that excludes project-private bridge state (`.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/`, `.specify/superpowers-handoff.json`, `.specify/feature.json`) from the plugin distribution while keeping the plugin's own assets (scripts, schemas, command files, agent skill files, matrices, verified-versions) tracked.
- **FR-016**: A clean install of the plugin into a host project MUST land only the plugin's own files (scripts, schemas, agent skill mirrors per the host's active integrations, command files); no `specs/`, no `bridge-events.jsonl`, no snapshots from the source repo MUST be copied.
- **FR-017**: The marketplace install path MUST be idempotent: re-installing on top of an existing install MUST NOT clobber user-modified files; conflicts MUST be reported with concrete actions.
- **FR-018**: The bilingual README MUST be checked for parity (same section anchors, same key examples) by a small validator (script or CI check); divergence between language versions MUST be flagged before publication.

### Key Entities

- **Install-State Audit Report**: A snapshot of the host project's bridge-relevant state — active integrations, default integration, git extension presence, per-agent skill gaps, script flavour, parity-check result — emitted in JSON.
- **Task Classification**: A per-task marker on `tasks.md` lines distinguishing auto-runnable tasks from those requiring explicit confirmation; consumed by the bridge in autonomous mode.
- **Bridge Resume Context**: The persisted state needed to resume an interrupted bridge run: active task ID, active Superpowers skill name, active phase, next-expected action, last verification command output.
- **Autonomous Mode Flag**: A boolean (off by default) controlling whether the bridge runs auto-runnable tasks without prompting.
- **Skill Sync Report**: The output of the install-state audit's per-agent parity section, naming any divergence between `.agents/skills/<id>/SKILL.md` and `.claude/skills/<id>/SKILL.md` (by hash or by hook-coverage gap).
- **Marketplace Listing Metadata**: The set of files the Spec Kit marketplace requires to discover and install this plugin (concrete shape per upstream conventions).
- **Plugin Distribution Manifest**: An enumerated list of files that the marketplace install copies into a host project, and the list of files explicitly excluded.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of bridge scripts that previously had hard-coded `-Actor` defaults now resolve the actor from explicit argument → env var → `default_integration` → documented fallback, with at least one positive and one negative test per script.
- **SC-002**: A new install of the plugin into a host project where Codex was installed first and Claude was added later results in `.claude/skills/speckit-git-*` peer files being present (either auto-mirrored or after a one-line documented remediation), and the parity check exits 0 on first run after install.
- **SC-003**: With autonomous mode enabled and ≥10 auto-runnable tasks classified, the bridge completes all 10 tasks in a single session with zero interactive prompts; with autonomous mode disabled, the bridge prompts at task boundaries as today (zero regressions).
- **SC-004**: After any bridge interrupt (auto or manual), the next session's first non-tool message names the active task ID and active skill within the first 200 characters of output.
- **SC-005**: The Claude Code end-to-end validation pass runs in under 10 minutes on this repository and emits a deterministic pass/fail report covering every command in the documented happy path.
- **SC-006**: The validation pass produces zero new P0 / P1 Compatibility Gap Records on a clean checkout; any newly-discovered gaps from a fresh run are recorded and triaged per the same CG schema feature 002 established.
- **SC-007**: Bilingual READMEs (`README.md` English; `README.zh-CN.md` Chinese, or per Spec Kit convention) cover identical sections; a structural parity check (anchor lists + section count) reports zero divergence.
- **SC-008**: The plugin install path drops only the documented Plugin Distribution Manifest into a host project; verified by a clean-room install test that lists every newly-created file and confirms each is on the manifest.
- **SC-009**: `.gitignore` excludes every file in the "user-private state" category (snapshots, events log, handoff state, feature.json, specs/* if applicable) AND tracks every file in the "plugin assets" category; covered by a verification command listed in the bridge documentation.
- **SC-010**: `specify integration upgrade` run on a project with this plugin installed does not overwrite the bridge's own custom files (vendor-managed boundary respected); verified by a before/after hash comparison.

## Assumptions

- The Spec Kit marketplace listing format and install mechanics are determined by upstream Spec Kit conventions; the exact metadata schema is a planning-time discovery, not a spec-level decision. The spec captures the requirement; the plan investigates the format.
- The `script` flavour (ps vs sh) of the host project is recorded in `.specify/init-options.json` and the bridge can adapt to either by selecting the matching script directory. PowerShell-only environments remain supported regardless of host's recorded flavour, with a clearly-documented constraint until the Bash port feature (`specs/003-bridge-cross-platform-scripts/`) closes that gap.
- "Autonomous mode" is opt-in. The default behavior of the bridge MUST remain the current confirmation-on-boundaries flow, so existing users see no regression. Users who want the autonomous flow must explicitly enable it (env var, CLI flag, or handoff field).
- The validation pass is allowed to assert against the live repository state during US3 evidence collection; subsequent runs in different projects will re-derive a fresh report.
- "Bilingual" specifically means Simplified Chinese + English. Traditional Chinese, Japanese, and other languages are out of scope for this feature.
- The disposition matrix (feature 002) remains the source of non-overlap truth; this feature adds operational polish, not new policy decisions on which commands overlap.
- The bridge plugin's marketplace name will mirror the directory name `speckit-superpowers-bridge` unless upstream Spec Kit conventions require a different naming scheme; finalized at planning time.
- The 002 follow-up CG-005 (Bash port at `specs/003-bridge-cross-platform-scripts/`) remains a separate feature; this feature does not duplicate its scope.
- This feature does not alter the disposition matrix entries themselves. If any of the new bridge meta-commands (audit, validation-pass, etc.) are introduced, they are added to the matrix as `bridge_meta_command` entries with disposition `COMBINE`.
