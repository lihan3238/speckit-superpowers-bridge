# Feature Specification: Trim To Thin Bridge

**Feature Branch**: `006-trim-to-thin-bridge`
**Created**: 2026-05-15
**Status**: Draft
**Input**: User description (paraphrased from the alignment thread): "Drastic 90% trim. The bridge should be the lightest, clearest plugin possible — it merges native Spec Kit and native Superpowers workflows only, with no custom features beyond what native skills provide. After invoking `/speckit-superpowers-bridge`, the bridge automatically orchestrates the relevant Superpowers skills to complete subsequent development. Constraints: do NOT break task handoff between agents; preserve all `specs/` history; keep only the most essential tests; cut a new version."

**Primary Design Reference**: [Spec Kit vs Superpowers — dev.to article (truongpx396)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj). The bridge's only job is to wire Spec Kit's `tasks.md` output into Superpowers' `executing-plans` skill, plus a tiny amount of state to track which feature is in implementation phase. Everything else should be native.

## Clarifications

### Session 2026-05-15

- Q: Should `marketplace/` artifacts (catalog-entry.json, extensions-readme-row.md, upstream-pr-body.md, README.md) survive the trim? → A: Keep all four. They serve the marketplace listing / alignment goal, which is the bridge's main external surface. (See FR-016 and new FR-019.)
- Q: How should `docs/release-runbook.md` (and any future maintainer-only docs) be handled? → A: Add `docs/` to `.gitignore` and remove it from git tracking. The runbook is maintainer-only; it stays on the maintainer's disk but is no longer shipped in the repo. (See new FR-020.)
- Q: What is the disposition of `recommend-route.ps1` and its `before_specify` hook? → A: Delete the script, its `commands/*.md`, and any matrix/hook references to it. Replace with a short README section explaining "when to skip Spec Kit and go direct to Superpowers" so users make the call manually. The removal is graceful: CHANGELOG documents it, the `before_specify` hook is cleared (no replacement command), and any code that imported it is purged rather than shimmed. (See new FR-021 and updated FR-011.)
- Q: Must the bridge keep backward-compatible read of v2/v3 handoff JSONs written by older installs? → A: Yes. Reading older handoff files gracefully (ignore unknown fields, never error) is a hard requirement; this lets existing users update without resetting their in-flight state. New writes use the simpler v1 shape and do not emit the dropped fields. (Reaffirms FR-009.)

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Thin Orchestrating Bridge (Priority: P1) 🎯 MVP

A maintainer wants the bridge plugin to be **a thin orchestrator**: invoking `/speckit-superpowers-bridge` automatically loads the active feature's Spec Kit artifacts and dispatches native Superpowers skills (`executing-plans`, `test-driven-development`, `verification-before-completion`, `requesting-code-review`, `finishing-a-development-branch`) at the right lifecycle phases. The plugin contains NO custom audit / validation / parity / cleanup / recommender features beyond this orchestration. The total bridge code surface shrinks to roughly 10% of its current size.

**Why this priority**: This is the entire point of the rewrite. The current bridge has grown a constellation of custom features (matrix, parity check, validation pass, install audit, cleanup audit, submission checklist, routing recommender, resume-context schema, skill-invocation event log) that duplicate or extend what native Superpowers already provides. Each custom feature adds maintenance burden, surface area for bugs, and divergence from native expectations. Cutting them brings the plugin in line with its stated purpose: a thin bridge.

**Independent Test**: From a fresh checkout, invoke `/speckit-superpowers-bridge` on a feature whose `tasks.md` exists; observe the bridge loads the Spec Kit artifacts and the agent proceeds through the documented happy path (TDD → verification → code review → finishing branch) without the bridge providing any of those discipline steps itself. Measure repo code surface and confirm the bridge's PowerShell + JSON Schema + custom command markdown footprint is ≤ 15% of pre-trim size.

**Acceptance Scenarios**:

1. **Given** the trimmed bridge installation, **When** a user invokes `/speckit-superpowers-bridge` on a feature with `spec.md` + `plan.md` + `tasks.md`, **Then** the bridge skill reads those files and instructs the agent to invoke native Superpowers skills at the named lifecycle phases — the bridge contributes ONLY the orchestration script, not the discipline implementations.
2. **Given** a contributor reads the bridge source repo, **When** they enumerate the bridge's PowerShell scripts and custom command markdown files, **Then** they find at most 3 scripts (`update-handoff.ps1`, `guard-command.ps1`, `auto-archive-handoff.ps1`) and at most 3 extension command markdown files (`execute`, `handoff`, `guard`). No `parity-check`, `audit-install-state`, `validation-pass`, `submission-checklist`, `cleanup-audit`, `recommend-route`, `emit-skill-invocation`, `emit-resume-signal`, `check-readme-bilingual-parity`, or `check-distribution-manifest` scripts remain.
3. **Given** the bridge's data files are inspected, **When** the maintainer searches for custom data schemas, **Then** the `disposition-matrix.json`, `verified-versions.json`, `plugin-distribution-manifest.yml`, and all `contracts/*.schema.json` from features 004 + 005 are removed; the bridge has at most one configuration file (a minimal `extension.yml` per Spec Kit's required format).
4. **Given** the bridge SKILL.md on each agent is opened, **When** read, **Then** it is concise (≤ 100 lines) and its content tells the agent how to orchestrate native skills — it does NOT define custom event types, custom phase names, custom invocation logging, or custom audit responsibilities.

---

### User Story 2 — Preserve Cross-Agent Task Handoff (Priority: P1)

A maintainer needs the cut to **not break the core handoff functionality** between Spec Kit and Superpowers across agents (Codex ↔ Claude Code). After trim, a feature designed in Claude Code must still be implementable in Codex (and vice versa) via the bridge.

**Why this priority**: Handoff is the bridge's purpose. If the cut removes pieces that handoff depends on, the bridge stops being a bridge. This story enumerates what handoff requires so we know what NOT to cut.

**Independent Test**: After the trim, complete one feature end-to-end where Claude Code does the design (`/speckit-specify` → `/speckit-tasks`) and Codex does the implementation (`/speckit-superpowers-bridge`); confirm the handoff JSON, the bridge SKILL.md, and the minimal guard correctly hand control between the two agents and Codex's session sees the correct artifacts.

**Acceptance Scenarios**:

1. **Given** the trimmed bridge, **When** Claude Code finishes `/speckit-tasks`, **Then** the after_tasks hook still writes a valid `.specify/superpowers-handoff.json` containing at minimum: `feature_directory`, `source_of_truth: { constitution, spec, plan, tasks }`, `status`, `artifact_owner`. (No schema_version-3 fields like `autonomous_mode`, `resume_context`, `archive_history` are required.)
2. **Given** Codex opens the project after Claude's handoff write, **When** the user invokes `$speckit-superpowers-bridge`, **Then** the bridge skill reads `superpowers-handoff.json`, locates the feature directory, and proceeds to orchestrate Superpowers skills against `tasks.md`.
3. **Given** any bridge script runs, **When** `-Actor` is omitted, **Then** a simple resolver picks the actor (explicit arg → env var → "unknown") — but the resolution chain is minimal (no `default_integration` consultation, no env var if the simpler 2-step chain suffices).
4. **Given** a new feature begins after a prior `complete` handoff, **When** `/speckit-specify` runs, **Then** the `auto-archive-handoff.ps1` helper still transitions the prior `complete` handoff to `ready` and clears `feature_directory`, so the new feature is unblocked. (This auto-archive is KEPT in the trim; it's lifecycle plumbing, not a custom feature.)
5. **Given** the guard is invoked, **When** a Spec Kit command would conflict with an active handoff, **Then** the guard denies based on a **small, hardcoded** rule set — no `disposition-matrix.json` consulted. The hardcoded rules cover at minimum: block `speckit.implement` when handoff status is `executing`; allow Spec Kit design commands at any status; deny `superpowers:writing-plans` and `superpowers:brainstorming` when an active Spec Kit feature exists.

---

### User Story 3 — Preserve Spec History (Priority: P2)

A maintainer wants the `specs/001-…` through `specs/005-…` directories preserved untouched. They are historical records of design decisions, clarifications, and the evolution of the bridge — including the clarifications captured during this very project that justify the trim.

**Why this priority**: P2 because it's a constraint on the cut, not an active scope item. The spec history has independent reference value for future maintainers and for the marketplace listing's transparency.

**Independent Test**: After the trim, every directory under `specs/` from features 001–005 still exists with its full content (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md, compat-gaps.md, tasks.md, checklists/). Only feature 006 is new.

**Acceptance Scenarios**:

1. **Given** the trimmed repo, **When** `ls specs/` runs, **Then** directories `001-spec-superpowers-bridge`, `002-complete-bridge-protocol`, `003-bridge-cross-platform-scripts`, `004-polish-and-publish`, `005-marketplace-alignment`, and the new `006-trim-to-thin-bridge` are all present.
2. **Given** any historical spec directory, **When** opened, **Then** its contents are byte-identical to the state at the time of its feature's completion (no retroactive edits to "make history look cleaner").
3. **Given** historical specs reference scripts that this trim removes (e.g., `validation-pass.ps1`, `parity-check.ps1`), **When** a reader follows those references, **Then** they encounter the broken link but see the history of why those scripts existed; this is acceptable and a documented characteristic of the historical record.

---

### User Story 4 — Core Tests Only, New Version (Priority: P2)

A maintainer wants the cut to keep **only the most essential sanity tests** (1–3 small scripts max), drop the 18-suite custom test infrastructure, and ship the trim under a new version (`v0.3.0`) with a CHANGELOG entry that documents the deliberate simplification.

**Why this priority**: P2 because it follows from US1 (most tests test the cut features). Versioning is a small but visible signal to anyone tracking the project that the trim is intentional.

**Independent Test**: After the trim, `tests/` contains at most 3 test scripts; each one tests a piece of native-bridging behavior (not a custom feature). `extension.yml.extension.version` is `0.3.0`. `CHANGELOG.md` has a `[0.3.0]` section describing the simplification.

**Acceptance Scenarios**:

1. **Given** the trimmed repo, **When** `ls tests/` runs, **Then** the count is ≤ 3. The retained tests cover at minimum: (a) handoff JSON shape after `update-handoff.ps1`, (b) guard denies `speckit.implement` when handoff exists. A third test for cross-agent skill mirror parity may be retained if cheap.
2. **Given** the cut, **When** `extension.yml` is read, **Then** `extension.version` is `0.3.0`. `requires.speckit_version` stays `">=0.8.10"` or relaxes to `>=0.8.0` if appropriate.
3. **Given** the cut, **When** `CHANGELOG.md` is read, **Then** an `[0.3.0]` section documents: what was removed (named scripts, named schemas, named commands), why (per maintainer's "thinnest bridge possible" directive recorded in `specs/006-…/spec.md`), and that the bridge now relies on native Superpowers + Spec Kit features.
4. **Given** the cut, **When** `marketplace/catalog-entry.json` is read, **Then** `version` is `0.3.0`, `description` is updated to reflect "thin orchestrating bridge" framing, `provides.commands` count drops to ≤ 3, and the locked tag set remains `bridge, superpowers, cross-agent, governance, tdd, workflow`.

---

### Edge Cases

- A user has an existing handoff JSON written by the v0.2.0 schema_version=3 format with `autonomous_mode` and `resume_context` fields. After the trim, the bridge reads the file, ignores the unrecognized fields, and works with the legacy shape. No migration step is required for backward read; new writes use the simpler schema.
- A user's CI/Make file references the deleted scripts (`parity-check.ps1`, `validation-pass.ps1`, etc.). The trim does not provide compatibility shims; the user is expected to update CI. The CHANGELOG calls this out explicitly.
- A user's repo has `marketplace/`, `docs/release-runbook.md`, or the deleted contract schemas under `specs/005-…/contracts/`. The trim KEEPS the live `marketplace/` directory at repo root (all four files retained, content refreshed for 0.3.0 per FR-019); `docs/` is removed from git tracking via `.gitignore` (FR-020); `specs/005-…/contracts/` stays as historical record.
- A future Spec Kit release adds a new core command (e.g., `speckit.deploy`). The thin bridge has no matrix to update; the only place this might need attention is the hardcoded guard rule set. Adding a rule there is a one-line change to one PowerShell script.
- A user installs the trimmed bridge from the marketplace; the install path generates `.claude/skills/<id>/SKILL.md` for each command in `extension.yml.provides.commands[]`. With only 3 commands listed (execute, handoff, guard), the user gets 3 slash commands. They invoke `/speckit-superpowers-bridge-execute` (or the parent `/speckit-superpowers-bridge` which is still the canonical orchestration entry).
- The `auto-archive-handoff.ps1` helper relies on update-handoff.ps1 to accept `-ClearFeatureDirectory` and `-AppendArchiveEntry`. The trim simplifies `update-handoff.ps1` but keeps these parameters because they're load-bearing for next-feature transitions. Other v3-only parameters (`-AutonomousMode`, `-ResumeContext`) are removed.
- Bridge SKILL.md content currently embeds the `disposition-matrix.json` policy explicitly. After the trim, the matrix is gone, so the SKILL.md prose carries the (small) policy directly: "Do not run speckit.implement when a handoff is active. Do not invoke superpowers:brainstorming or :writing-plans when active Spec Kit artifacts exist."
- The `superpowers-handoff.json` produced by Spec Kit's after_tasks hook may carry fields we want to drop. The trim makes those fields optional rather than required in the simpler schema; legacy fields are ignored gracefully.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The bridge MUST contain at most 3 PowerShell scripts under `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/`: `update-handoff.ps1`, `guard-command.ps1`, `auto-archive-handoff.ps1`. All other scripts from features 002 + 004 + 005 MUST be removed.
- **FR-002**: The bridge MUST contain at most 3 extension command markdown files under `commands/`: `speckit.speckit-superpowers-bridge.execute.md`, `speckit.speckit-superpowers-bridge.handoff.md`, `speckit.speckit-superpowers-bridge.guard.md`. All other `commands/*.md` from features 004 + 005 MUST be removed.
- **FR-003**: The bridge MUST NOT contain `disposition-matrix.json`, `verified-versions.json`, `plugin-distribution-manifest.yml`, `disposition-matrix.schema.json`, or any other contract schemas at runtime locations. The data files from features 002 + 004 + 005 MUST be removed from runtime locations. (Historical copies under `specs/<feature>/contracts/` MAY remain as historical record per US3.)
- **FR-004**: Each bridge `SKILL.md` (Codex and Claude Code peers) MUST be concise (target ≤ 100 lines, hard cap ≤ 150 lines). The content MUST tell the agent how to orchestrate native Spec Kit + Superpowers skills, not implement custom discipline.
- **FR-005**: Invoking `/speckit-superpowers-bridge` (Claude) or `$speckit-superpowers-bridge` (Codex) MUST cause the agent to: (a) read `.specify/superpowers-handoff.json` and the named source-of-truth files, (b) transition handoff status to `executing`, (c) invoke `superpowers:executing-plans` with `tasks.md` as the plan, (d) at completion invoke `superpowers:verification-before-completion` then `superpowers:requesting-code-review` then `superpowers:finishing-a-development-branch`, (e) transition handoff to `complete`. The bridge SKILL.md MUST issue these instructions explicitly.
- **FR-006**: The handoff JSON schema MUST be simplified back to a v1-style shape: top-level fields `schema_version`, `updated_at`, `feature_directory`, `source_of_truth { constitution, spec, plan, tasks }`, `supersedes`, `executor`, `capabilities`, `status`, `blocked_reason`, `artifact_owner`, `review_only_agents`, `notes`, `last_snapshot_id`, `instructions`. Fields introduced in v2 + v3 (`archive_history`, `autonomous_mode`, `resume_context`) MUST be either dropped or made optional. New writes MUST NOT include the dropped fields by default.
- **FR-007**: The guard MUST be a single small script that enforces a hardcoded rule set (no matrix lookup): block `speckit.implement` when an active handoff exists; deny `superpowers:writing-plans` / `superpowers:brainstorming` when a Spec Kit feature has full artifacts; allow everything else. Total guard rules MUST be ≤ 5; each MUST be a literal `if/elseif` branch in `guard-command.ps1`. No external data file dependency.
- **FR-008**: The actor resolver MUST be a minimal in-script helper (≤ 20 lines): explicit `-Actor` argument → `SPECKIT_BRIDGE_ACTOR` env var → `"unknown"`. The 4-step chain (which previously also consulted `default_integration`) MAY be simplified to this 3-step chain. The shared `common-actor-resolution.ps1` MAY be kept as a 20-line dot-sourced helper or inlined per-script — whichever is simpler.
- **FR-009**: `.specify/superpowers-handoff.json` MUST be readable by the trimmed bridge even when written by an older (v2/v3) update-handoff.ps1 — unknown fields are ignored, not errored on. Forward-write compatibility is NOT required (a v0.3.0 bridge writing handoff state for a v0.2.x consumer is out of scope).
- **FR-010**: `auto-archive-handoff.ps1` MUST be retained as a small helper (target ≤ 80 lines): snapshot prior feature artifacts under `bridge-snapshots/`, transition status `complete` → `ready`, clear `feature_directory`. Append-to-archive-history MAY be dropped (the simplification accepts losing the history field).
- **FR-011**: `.specify/extensions.yml` hooks MUST be trimmed to reference only the surviving commands: `before_clarify` / `before_plan` / `before_tasks` / `before_implement` reference the guard; `after_tasks` references the handoff command. The `before_specify` hook MUST be removed entirely (its only prior handler was `recommend-route`, which is being deleted per FR-021); it MUST NOT be replaced by an empty placeholder or a no-op. Hooks referencing removed commands (recommend-route, parity, audit, validate, submission-checklist, cleanup-audit) MUST be removed.
- **FR-012**: `tests/` MUST contain at most 3 PowerShell test scripts. At minimum it MUST cover: (a) handoff JSON shape after a write through `update-handoff.ps1`, (b) guard denial of `speckit.implement` when a handoff exists with status `executing`. Other tests MAY be retained only if they directly cover surviving native-orchestration behavior.
- **FR-013**: `extension.yml.extension.version` MUST be set to `0.3.0`. `extension.yml.provides.commands` MUST list at most 3 commands matching FR-002.
- **FR-014**: `CHANGELOG.md` MUST contain a new `[0.3.0]` section explicitly listing what was removed (named scripts, named schemas, named commands) and a one-paragraph rationale linking to `specs/006-trim-to-thin-bridge/spec.md`.
- **FR-015**: `README.md` and `README.zh-CN.md` MUST be updated so that: the commands reference table lists at most 3 commands; the workflow diagram is unchanged (still showing Spec Kit → bridge → Superpowers); the "Architecture in 60 seconds" section explicitly states "the bridge orchestrates native skills and does not provide custom discipline." Bilingual structural parity MUST still hold.
- **FR-016**: `marketplace/catalog-entry.json` MUST be updated to reflect the new version (0.3.0), the new `provides.commands` count (≤ 3), and the new `description` (no longer claiming the deeper audit/validation/parity features).
- **FR-017**: `specs/001-…` through `specs/005-…` directories MUST be left byte-identical to their state at the start of feature 006 (no retroactive edits, no deletions).
- **FR-018**: The trim MUST be reversible at the git level — every removal is a separate concern in the git history so an interested party can resurrect any one of the cut features by reverting a specific commit. (Implementation freedom on commit granularity; this requirement is a directional preference, not a hard count.)
- **FR-019**: All four files under `marketplace/` (`catalog-entry.json`, `extensions-readme-row.md`, `upstream-pr-body.md`, `README.md`) MUST be retained because they are the bridge's external listing surface. `marketplace/upstream-pr-body.md` MUST keep the AI-assistance disclosure paragraph required by Spec Kit CONTRIBUTING.md. Content updates to reflect 0.3.0 framing are required (per FR-016), but the file set is not cut.
- **FR-020**: `docs/` MUST be added to `.gitignore` and removed from git tracking (the directory may remain on the maintainer's local disk). After the trim, `git ls-files docs/` MUST return zero entries. No surviving runtime artifact MAY reference `docs/release-runbook.md` or any other file under `docs/` (so removal does not produce broken links in shipped material).
- **FR-021**: `recommend-route.ps1`, its `commands/speckit.speckit-superpowers-bridge.recommend-route.md`, its disposition-matrix entries, and any imports of it MUST be deleted with no replacement script. In place of the automated recommendation, `README.md` (and `README.zh-CN.md`) MUST add a short "When to skip Spec Kit" section explaining the user-driven choice: small fixes go direct to Superpowers; multi-step or design-heavy changes go through the full Spec Kit → bridge → Superpowers flow. The CHANGELOG `[0.3.0]` entry MUST note this deletion explicitly so existing users updating from 0.2.x understand the routing function is now manual.

### Key Entities

- **Trimmed Bridge Surface**: The set of files retained after the cut — bridge SKILL.md (Codex + Claude), 3 PowerShell scripts, 3 extension command markdown files, simplified `extensions.yml` hooks, `extension.yml`, `LICENSE`, `CHANGELOG.md`, `README.md` + `README.zh-CN.md`, `AGENTS.md`, `CLAUDE.md`.
- **Cut Inventory**: An enumerated list (one entry per removed file or group) recorded in `specs/006-trim-to-thin-bridge/cut-inventory.md` (created during planning) so reviewers can verify completeness.
- **Simplified Handoff Schema**: The v1-shape handoff JSON described in FR-006.
- **Hardcoded Guard Rules**: The ≤ 5 literal `if/elseif` branches inside `guard-command.ps1` that replace the disposition matrix lookup.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Bridge PowerShell code surface decreases from approximately 2,500 lines (pre-trim) to ≤ 300 lines (post-trim) — a ≥ 88% reduction.
- **SC-002**: Bridge extension command markdown files decrease from 9 to ≤ 3.
- **SC-003**: Test suite file count decreases from 18 to ≤ 3.
- **SC-004**: After the trim, invoking `/speckit-superpowers-bridge` on a feature with complete Spec Kit artifacts results in the agent invoking native Superpowers skills at the documented lifecycle phases without the bridge contributing custom discipline. Verified by manually walking the happy path in one session.
- **SC-005**: After the trim, a feature designed by Claude Code can be implemented by Codex (and vice versa) using the bridge — verified by completing one cross-agent feature.
- **SC-006**: `specs/` directories 001 through 005 are byte-identical between the start of feature 006 and the end of feature 006 (verified by `git diff --stat` showing zero changes under those paths).
- **SC-007**: `extension.yml.extension.version` is `0.3.0` and the catalog entry's `version` matches.
- **SC-008**: The CHANGELOG `[0.3.0]` section names ≥ 5 specific removed files/directories and includes a one-paragraph rationale.
- **SC-009**: The trim is committed in ≥ 3 distinct commits (or otherwise structured so each removal is independently revertable per FR-018).
- **SC-010**: Bilingual README parity is preserved (or a hand-equivalent check confirms identical H2 anchors) — even though the bilingual-parity script is being removed, the parity of the two READMEs themselves is preserved.

## Assumptions

- The dev.to article (`Spec Kit vs Superpowers`) remains the project's design north star; the trim aligns the project more tightly with the article's "these are not mutually exclusive" framing.
- Spec Kit's marketplace install path auto-generates per-command skill files in `.claude/skills/` and `.agents/skills/` from `extension.yml.provides.commands[]`. With only 3 commands listed post-trim, users get 3 slash commands. The trim does not maintain explicit per-command skill stub files in source.
- The `auto-archive-handoff.ps1` helper is load-bearing for cross-feature transitions and is therefore exempt from the "no helpers" cut. Its lines count toward the ≤ 300 PowerShell budget.
- The constitution principle of "lightweight, repo-local" was nominally upheld during features 002 + 004 + 005 but in spirit it was violated by the accumulated custom infrastructure. The trim restores spirit-level compliance.
- AI-disclosure language in the marketplace PR body remains required by Spec Kit CONTRIBUTING.md; the trim retains the disclosure paragraph in `marketplace/upstream-pr-body.md` (and the other three marketplace files) — see FR-019.
- The `verified-versions.json` removal accepts that we lose machine-readable version pinning. Verification of Spec Kit / Superpowers versions will be by human inspection at release time, recorded in CHANGELOG, not by automated drift detection.
- The `bridge-events.jsonl` log will still be appended to by `update-handoff.ps1` (single line per state transition) but will NOT carry new event types like `skill_invocation`, `parity_check`, `submission_check`, `auto_archive`. The trim accepts losing this observability surface in exchange for simplicity.
- Historical compat-gap records (CG-001 through CG-007) stay in their feature directories; the CG schema and feature 006 itself do not need to log new gaps unless validation surfaces issues.
- `docs/release-runbook.md` and any other files under `docs/` are maintainer-only working notes. They are added to `.gitignore` and untracked (per FR-020). No shipped artifact links into `docs/`.
- Tags in `extension.yml.tags` and the catalog entry stay the locked 6-tag set (`bridge, superpowers, cross-agent, governance, tdd, workflow`) — they describe the bridge's intent, not the count of custom features.
