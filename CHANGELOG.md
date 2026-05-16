# Changelog

All notable changes to **speckit-superpowers-bridge** are documented in this file.

This project adheres to [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

> **AI-assistance disclosure**: This extension is developed with AI coding assistants (Claude Code for design + planning, Codex for implementation passes, Claude Code for the v0.3.0 trim), per the AI-disclosure requirement in [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md). Every artifact passes human review before commit. As of v0.3.0 the verification surface is three retained smoke tests under `tests/`.

## [0.5.0] - 2026-05-16

Bridge drift hardening + v0.5.0 cleanup release. The bridge now surfaces its own state on every script invocation and warns when a feature is marked `complete` while non-deferred tasks remain unchecked — the root-cause fix for the documentation-accuracy drift class of bug that surfaced in the v0.4.2 / v0.4.3 cycles. Resets the minimum direct-upgrade baseline to v0.4.2.

### Added

- **US1**: `bridge-state.{ps1,sh}` shared helper sourced by `update-handoff.{ps1,sh}` and `guard-command.{ps1,sh}`. Computes canonical `Pending tasks: N` count from `<feature_directory>/tasks.md` using the regex `^- \[ \] T\d+` (FR-001 / Clarifications Q4) and respects section-header deferred-exemption per FR-005 / Q6 (any task-ID line under `## Deferred|Optional|Out of Scope|Won't do|Future|Wontfix|Backlog` is excluded). Prints a `[bridge state]` block (Feature directory / Status / Artifact owner / Actor / Pending tasks) on every successful script invocation.
- **US1**: `update-handoff` now logs `prior_actor` in every `bridge-events.jsonl` handoff entry. When a transition changes the actor (e.g., `claude → codex`), the `reason` field is augmented with `actor change <prior> → <new>` (operator-supplied `-Reason` text is preserved with a `;` separator, never overwritten).
- **US1 / FR-003**: `update-handoff` emits `[bridge] WARNING: handoff is 'complete' but tasks.md has <N> unchecked tasks; review or move under a deferred section.` to stderr when transitioning to `complete` while non-deferred unchecked task-ID lines remain. Exit code stays 0 — the warning surfaces the drift; the operator decides how to resolve.
- **US1**: `tests/test-bridge-state-summary.ps1` regression covering SC-001/SC-002/SC-003. PowerShell flavor verified GREEN; bash flavor gated on `jq` + `awk` prerequisites with skip-on-failure semantics (same v0.4.2 B2 strategy chain).
- **US2**: `specs/007-catalog-distribution-polish/verification.md` gained a `## Gate evidence` subsection recording the SC-005 byte-freeze (`0 lines diff`) and SC-006 spec-history checksum (`96e3dffe…`, identical to v0.4.1 baseline) for the 007 cycle's complete point.
- **US3**: `marketplace/README.md` gained a `## Catalog update policy` section citing the upstream-documented method (`extensions/EXTENSION-PUBLISHING-GUIDE.md` at commit `81e9ecd`, dated 2026-05-16) and our Q5=C policy (minor/major releases file an issue; patch releases skip and rely on the stable-alias URL).

### Changed

- **US2**: `specs/007-catalog-distribution-polish/tasks.md` T022-T028 now correctly marked `[x]` with evidence pointers; T029 (optional upstream catalog-update issue) moved under a `## Deferred (per 008 Clarifications Q5)` H2.
- **US2**: `specs/003-bridge-cross-platform-scripts/tasks.md` all 56 v0.4.2-cleanup-tail task-ID checkboxes ticked `[x]`; new `## Deferred (user-side verification, inherited from v0.4.0 tasks.md)` subsection anchors the FR-005/Q6 exemption semantics for any future appended items.
- **US3 / FR-009**: `marketplace/extensions-readme-row.md` column-header comment realigned to upstream's current `Extension | Purpose | Category | Effect | URL` shape (changed since PR #2586's `Name | Description | Category | Permissions | Repository`). Cell content unchanged.
- **US3 / FR-011**: `marketplace/extension-submission-body.md` bumped to v0.5.0 with `<filled-by-workflow-on-tag>` placeholders for SHA256 and workflow URL. Fresh-install smoke notes mention the new `[bridge state]` block and FR-003 warning.
- **US3 / FR-011**: `marketplace/catalog-entry.json` version 0.4.3 → 0.5.0; download_url to the v0.5.0 versioned ZIP.
- **US4**: `extension.yml` `extension.version` 0.4.3 → 0.5.0.
- **US4 / FR-015**: `AGENTS.md` pruned of pre-0.4.2 version references outside historical context; new "Compatibility baseline" pointer declares v0.4.2 as the minimum direct-upgrade source per CHANGELOG `[0.5.0] § Compatibility`.

### Compatibility

- **Minimum direct-upgrade baseline**: **v0.4.2**. Users on v0.4.2 or v0.4.3 upgrade to v0.5.0 with no migration — the handoff schema (`.specify/superpowers-handoff.json`) and event log shape (`.specify/bridge-events.jsonl`) remain byte-stable. The new `prior_actor` field on handoff events is purely additive; pre-v0.5.0 readers ignore it (JSON), post-v0.5.0 readers see `null` on legacy lines.
- Users on **v0.4.0 / v0.4.1** should upgrade through v0.4.2 first OR re-install fresh via the stable-alias URL `releases/latest/download/speckit-superpowers-bridge.zip`. The v0.4.0 → v0.4.1 cycles are no longer called out in supporting docs (AGENTS.md, marketplace) outside historical / CHANGELOG context.
- The previous "branch = release line" pattern (v0.4.0 → v0.4.3 all tagged on `003-cross-platform-cleanup`) is discontinued — v0.5.0+ releases tag on `main`. Long-running release branches are not used going forward.

### Validation

- All 3 pre-existing smoke tests pass (`tests/test-handoff-shape.ps1`, `tests/test-guard-hardcoded-rules.ps1`, `tests/test-claude-codex-skill-parity.ps1`) — no regression from US1 runtime changes.
- New `tests/test-bridge-state-summary.ps1` passes (PowerShell flavor; bash flavor exercised in sandbox).
- Validator self-test passes (`scripts/release/test-validate-release-readiness.ps1`).
- Local pre-tag validator passes for version 0.5.0.
- Constitution v1.2.0 sandbox gate exercised on Windows PowerShell + WSL Linux bash (PASS rows in `specs/008-bridge-hardening-0-5-0/verification.md`); macOS row PENDING with reason "no host available" per Clarifications Q1.

### Compliance

- SC-013 north-star: `git diff v0.4.3..v0.5.0 -- .specify/extensions/speckit-superpowers-bridge/` is confined to `scripts/{powershell,bash}/` (5 files modified, 2 new helpers) plus the bridge SKILL.md peers. No new Spec Kit commands, no new Superpowers skills, no new top-level directories.
- AI-assistance disclosure: this release was designed and implemented with Claude Code (design + planning + Phase A-D implementation passes) and Codex (cross-flavor review). All artifacts passed human review before commit.

## [0.4.3] - 2026-05-16

Official catalog distribution polish. No bridge runtime behavior changed.

### Changed

- README install instructions now present the official Spec Kit community catalog as the discovery/trust surface, while using the stable latest-release ZIP URL for default installs because the community catalog is discovery-only by default.
- Release automation now uploads both the versioned ZIP and a stable `speckit-superpowers-bridge.zip` alias, enabling `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`.
- Version-pinned ZIP installation remains documented for reproducible installs.
- Marketplace materials were updated for the accepted official listing flow: initial listing accepted in github/spec-kit issue #2581 and PR #2586, future updates go through a new Extension Submission issue as an existing-entry update.
- `marketplace/extensions-readme-row.md` now matches the current upstream `docs/community/extensions.md` table shape: Name, Description, Category, Permissions, Repository.
- Tool metadata was slimmed to the official accepted catalog shape: optional PowerShell, bash, and jq only. Git remains recommended workflow discipline but is not declared as an extension runtime tool.

### Compatibility

Functionally identical to v0.4.2. Users on v0.4.1 or v0.4.2 may upgrade directly; no migration required.

## [0.4.2] - 2026-05-16

Patch / cleanup release with no new bridge capability. This release closes the v0.4.0 → v0.4.1 cleanup tail by addressing **B1**, **B2**, **C1**, **C4**, and **US4** — the five items left open after v0.4.1's marketplace alignment. The bridge runtime (handoff, guard, auto-archive, actor resolution) is byte-frozen aside from one surgical SKILL.md edit (B1).

This release also closes the first execution of the constitution v1.2.0 "End-User Verification Sandbox" gate — `..\test_specify_superpower` is the canonical sibling sandbox; every release artifact from v0.4.2 forward MUST be verified there before its handoff transitions to `complete`.

### Fixed

- **B1**: `.claude/skills/speckit-superpowers-bridge/SKILL.md` and `.agents/skills/speckit-superpowers-bridge/SKILL.md` no longer hardcode `-ArtifactOwner claude` / `--artifact-owner claude` in their step-3 update-handoff example. The 4-step actor-precedence chain inside `update-handoff.ps1` / `update-handoff.sh` was always correct (explicit arg → prior handoff value → resolved actor → `"unknown"`); the SKILL example was overriding step 2 unnecessarily and could clobber a valid prior `artifact_owner` on cross-agent handoff. Both peers now omit the flag and document that the script silently preserves the prior owner. (US1)
- **B2**: `tests/test-handoff-shape.ps1` and `tests/test-guard-hardcoded-rules.ps1` now translate Windows paths to bash-reachable paths through a 5-strategy chain (`cygpath` → `/mnt/<drive>` → MSYS shorthand `/<drive>` → native `bash.exe` direct → skip-with-reason). The bash flavor is also gated on a prerequisite probe; if `jq` or another dependency is missing, the flavor is skipped with a recorded reason instead of producing a false-red. PowerShell flavor remains the source of truth on Windows dev boxes. (US2)

### Changed

- **C1**: `.gitignore` now excludes install-time registry state — `.specify/workflows/workflow-registry.json`, `.specify/workflows/*/workflow.yml`, and `.specify/extensions/.registry`. These files are regenerated locally by `specify extension add` / `specify extension list` and should never be tracked. Existing tracked copies were removed from the index in this release. (US3)
- **C4**: `specs/003-bridge-cross-platform-scripts/tasks.md` was refreshed to a v0.4.2 task list focused on the cleanup tail (B1 + B2 + C1 + C4 + US4 sandbox), with a historical pointer to commit `a4aa833` for the original v0.4.0 task list. The previous tail of 17 work-in-progress tasks is absorbed by this redesign. (US3)
- `AGENTS.md` gained a new "Install-time registries are local state, not tracked" subsection documenting the C1 gitignore rule and the rationale (per-developer, locally generated, not vendored).
- `extension.yml`, `marketplace/catalog-entry.json`, and `marketplace/extension-submission-body.md` now target v0.4.2.

### Added

- **US4**: `specs/003-bridge-cross-platform-scripts/verification.md` records the sandbox-install verification run required by constitution v1.2.0 §"End-User Verification Sandbox". Each release from v0.4.2 forward appends one `## <version>` section with a row per supported platform (Windows PowerShell, Linux/macOS bash). Schema is pinned by `contracts/verification-record.md`. v0.4.2 records Windows PowerShell + WSL Linux bash as the two real-host runs; macOS is PENDING with the noted reason "no host available" per Clarifications Q3.

### Compatibility

Functionally identical to v0.4.1. The bridge runtime (handoff schema, guard rules, actor chain, auto-archive, audit log) is byte-frozen. Users on v0.4.0 or v0.4.1 may upgrade directly; no migration required.

### Validation

- All 3 bridge smoke tests green: `tests/test-handoff-shape.ps1`, `tests/test-guard-hardcoded-rules.ps1`, `tests/test-claude-codex-skill-parity.ps1`.
- Validator self-test green: `scripts/release/test-validate-release-readiness.ps1`.
- Local validator passes for version 0.4.2.
- Constitution v1.2.0 sandbox gate satisfied (`..\test_specify_superpower`): Windows PowerShell + WSL Linux bash recorded in `specs/003-bridge-cross-platform-scripts/verification.md`; macOS deferred per Clarifications Q3.

## [0.4.1] - 2026-05-16

Marketplace alignment patch. No bridge runtime behavior changed.

### Changed

- `extension.yml`, `marketplace/catalog-entry.json`, and install docs now target v0.4.1.
- Catalog tags reduced from six to the five-tag set required by the Extension Submission template: `bridge`, `superpowers`, `cross-agent`, `tdd`, `workflow`.
- Tool metadata now distinguishes the Windows PowerShell flavor from the Linux/macOS bash + jq flavor.
- GitHub Actions release workflow now uses `actions/checkout@v6`.
- Marketplace submission materials were rewritten around the bridge philosophy: Spec Kit owns WHAT, Superpowers owns HOW, and the bridge only orchestrates native capabilities.

### Compatibility

Existing v0.4.0 installs can upgrade directly. The handoff schema, commands, hooks, guard rules, and script behavior are unchanged.

## [0.4.0] - 2026-05-15

Cross-platform compatibility release. The bridge now ships one ZIP that contains both Windows PowerShell scripts and Linux/macOS bash scripts.

### Added

- Four bash runtime scripts under `.specify/extensions/speckit-superpowers-bridge/scripts/bash/`: `common-actor-resolution.sh`, `update-handoff.sh`, `guard-command.sh`, and `auto-archive-handoff.sh`.
- `.gitattributes` with `*.sh text eol=lf` so shell scripts keep LF line endings on Windows clones.
- `bash >= 4.0` and `jq >= 1.6` tool metadata in `extension.yml` and `marketplace/catalog-entry.json`.

### Changed

- The execute command now declares the short alias `speckit.superpowers-bridge`, so fresh marketplace installs generate `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge` in addition to the canonical fallback.
- `scripts/release/build-extension-zip.ps1` now packages `scripts/bash/` beside `scripts/powershell/`.
- `scripts/release/validate-release-readiness.ps1` now checks bash/PowerShell script parity and the `.gitattributes` shell-script LF rule.
- The retained smoke tests now auto-detect available script flavors and exercise both `ps` and `bash` when present.
- README prerequisites now document Linux/macOS runtime requirements and clarify that `pwsh` is only needed for contributors running the smoke tests.

### Fixed

- Fresh marketplace installs no longer leave users with only the long generated `$speckit-speckit-superpowers-bridge-execute` / `/speckit-speckit-superpowers-bridge-execute` entrypoint.
- Release ZIPs now place `extension.yml` directly at archive root and use portable `/` entry separators, matching Spec Kit's latest Linux/macOS installer expectations.

### Compatibility

Existing Windows installs continue using the PowerShell flavor. Linux/macOS installs use the bash flavor through Spec Kit's existing `init-options.json.script` setting. No handoff migration is required; both flavors read older v2/v3 handoff documents tolerantly and write the v1 shape.

### Validation

- `tests/test-handoff-shape.ps1` green with `(ps, bash)`.
- `tests/test-guard-hardcoded-rules.ps1` green with `(ps, bash)`.
- `tests/test-claude-codex-skill-parity.ps1` green.
- `scripts/release/test-validate-release-readiness.ps1` green with 7/7 cases.

## [0.3.1] - 2026-05-15

Tooling + alignment patch. No behavior changes in the bridge itself; this release ships the release-automation infrastructure that v0.3.0 didn't have, and aligns several stale references that were missed during the v0.3.0 cut.

### Added

- `.github/workflows/release.yml` — GitHub Actions workflow that fires on `v*.*.*` tag push and automates the build → release → asset upload chain. Runs the validator + bridge smoke tests + release-tooling self-tests before building; extracts the matching CHANGELOG section as release notes; emits SHA256 + asset URL to the workflow's step summary.
- `scripts/release/validate-release-readiness.ps1` — pre-flight validator checking four cross-references (extension.yml version, catalog-entry.json version, catalog-entry.json download_url, CHANGELOG section presence). Runnable locally before tagging and in CI.
- `scripts/release/test-validate-release-readiness.ps1` — 5-case TDD test suite (1 positive + 4 negative) for the validator.
- `scripts/release/build-extension-zip.ps1` — already added in v0.3.0; now made cross-platform (replaced `$env:TEMP` with `[System.IO.Path]::GetTempPath()` so it runs on ubuntu pwsh, not just Windows).

### Changed

- `extension.yml.extension.version` → `0.3.1`.
- `marketplace/catalog-entry.json` `version` + `download_url` → 0.3.1; description shortened earlier in this cycle to 91 chars to stay under the publishing-guide soft cap.
- `marketplace/README.md` — release procedure rewritten to reflect the automated workflow; distinguishes pre-tag manual edits, auto on tag push, and the cross-repo issue comment that stays manual.
- `marketplace/upstream-pr-body.md` — references corrected from auto-archive URL back to release-asset URL; "since v0.2.0" framing corrected to "since v0.1.1" (v0.2.0 was a CHANGELOG marker, never tagged).
- `.specify/workflows/speckit-superpowers/workflow.yml` — `workflow.version` `0.1.1` → `0.3.0` (the trim should have included this; caught during post-release sweep).
- `.specify/workflows/workflow-registry.json` — speckit-superpowers entry version bumped to 0.3.0 with refreshed `updated_at`.
- `.specify/extensions/.registry` — speckit-superpowers-bridge entry version bumped to 0.3.0; `registered_commands` trimmed from 7 (stale) to 3 (current).
- `.gitignore` — `docs/` rule (already in v0.3.0); obsolete cleanup-audit comment removed.

### Fixed

- 5 cross-reference drifts caught by code review on v0.3.0 (commit `f9f5490` in the v0.3.0 timeline):
  - `commands/speckit.speckit-superpowers-bridge.execute.md` referenced deleted `emit-skill-invocation.ps1` and the dropped `-ResumeContext` parameter.
  - `commands/speckit.speckit-superpowers-bridge.guard.md` documented guard rules that didn't match the actual hardcoded set, plus a non-existent `-AllowDiscardSpecArtifacts` parameter.
  - `commands/speckit.speckit-superpowers-bridge.handoff.md` described a 4-step actor chain that the trim collapsed to 3 steps.
  - `contracts/handoff.v1.schema.json` — `artifact_owner` enum was missing `"unknown"` while the script wrote it as default.
  - `contracts/handoff.v1.schema.json` — `supersedes` typed as `string|null` while the script wrote it as an array.

### Compatibility

Functionally identical to v0.3.0. Users on v0.3.0 can upgrade or skip; no migration required.

### Validation

- All 3 bridge smoke tests green.
- 5/5 validator TDD cases green.
- Local validator passes for version 0.3.1.
- Release artifact build verified locally to match `agent-governance` shape.

## [0.3.0] - 2026-05-15

A deliberate drastic trim — the bridge becomes the thin orchestrating layer it was always supposed to be. **~87% PowerShell line reduction**, no functional capability added. See [`specs/006-trim-to-thin-bridge/spec.md`](specs/006-trim-to-thin-bridge/spec.md) for the full rationale, and [`specs/006-trim-to-thin-bridge/cut-inventory.md`](specs/006-trim-to-thin-bridge/cut-inventory.md) for the enumerated removal list.

### Removed

PowerShell scripts (13 deletions):

- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/audit-install-state.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/validation-pass.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/cleanup-audit.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-distribution-manifest.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/check-readme-bilingual-parity.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/recommend-route.ps1` (replaced by README "When to Skip Spec Kit" section; routing decision is now user-driven)
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/emit-resume-signal.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/emit-skill-invocation.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/restore-snapshot.ps1` (snapshot rollback is now manual `cp -r`)
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-context.ps1`
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`

Bridge command markdowns (6 deletions):

- `commands/speckit.speckit-superpowers-bridge.parity.md`
- `commands/speckit.speckit-superpowers-bridge.audit.md`
- `commands/speckit.speckit-superpowers-bridge.validate.md`
- `commands/speckit.speckit-superpowers-bridge.submission-checklist.md`
- `commands/speckit.speckit-superpowers-bridge.cleanup-audit.md`
- `commands/speckit.speckit-superpowers-bridge.recommend-route.md`

Bridge data files (3 deletions):

- `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` (replaced by 5 hardcoded `if`/`elseif` rules inside `guard-command.ps1`)
- `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` (version compatibility is now human-inspection at release time, recorded in this CHANGELOG)
- `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml` (catalog-entry.json is sufficient)

Bridge contracts and docs (2 deletions):

- `.specify/extensions/speckit-superpowers-bridge/contracts/plugin-distribution-manifest.schema.json` (the schema for a now-removed manifest)
- `.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md` (parameters it documented no longer exist)

Tests under `tests/` (15 deletions; 2 more in commit 5 under `scripts/powershell/`):

- `test-parity-drift.ps1`, `test-install-state-audit.ps1`, `test-validation-pass.ps1`, `test-submission-checklist.ps1`, `test-cleanup-audit.ps1`, `test-distribution-manifest.ps1`, `test-routing-recommender.ps1`, `test-resume-signal.ps1`, `test-skill-invocation-event.ps1`, `test-extension-manifest-install.ps1`, `test-disposition-matrix.ps1`, `test-verified-versions.ps1`, `test-readme-bilingual-parity.ps1`, `test-actor-resolution.ps1`, `test-constitution-checklist-guard.ps1`, `test-guard-uses-matrix.ps1`, `test-hook-surface-resolution.ps1`

Handoff schema v3 fields (now `schema_version: 1` in new writes; older v2/v3 documents are still readable):

- `autonomous_mode`
- `resume_context`
- `archive_history`

Hooks in `.specify/extensions.yml`:

- `before_specify` hook entry removed entirely (its sole handler was `recommend-route`)
- Every hook referencing a removed command was deleted

`docs/` directory:

- `docs/release-runbook.md` and any future maintainer-only files under `docs/` are now gitignored (kept on the maintainer's local disk; not shipped in the repo).

### Changed

- `extension.yml.version` bumped to `0.3.0`.
- `extension.yml.provides.commands` reduced from 9 to 3 (`execute`, `handoff`, `guard`).
- `extension.yml.hooks` reduced from 6 to 5 (`before_specify` removed).
- `marketplace/catalog-entry.json`: version `0.3.0`, `provides.commands: 3`, `provides.hooks: 5`, refreshed description to "A thin orchestrating bridge between Spec Kit (design) and Superpowers (implementation). Cross-agent (Codex + Claude Code). Native skills only — no custom discipline."
- `marketplace/upstream-pr-body.md`: rewritten for 0.3.0; AI-assistance disclosure paragraph preserved verbatim.
- `marketplace/extensions-readme-row.md` + `marketplace/README.md`: updated for 0.3.0 description and the manual-submission workflow.
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1`: 393 → 189 lines. New writes use v1 schema. Reads tolerate v2/v3 unknown fields per FR-009 (the trim's explicit user-friendliness goal for in-flight upgrades).
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1`: 259 → 92 lines. Five hardcoded rules replace the matrix lookup.
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1`: 97 → 54 lines. Emits an `archive` event (renamed from `auto_archive`).
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/common-actor-resolution.ps1`: 58 → 41 lines. Three-step actor chain (explicit → env → "unknown"); dropped `.specify/integration.json` consultation.
- `.claude/skills/speckit-superpowers-bridge/SKILL.md`: 149 → 62 lines. Now describes orchestration only.
- `.agents/skills/speckit-superpowers-bridge/SKILL.md`: 146 → 59 lines. Content-identical Codex peer.
- `README.md` + `README.zh-CN.md`: rewritten to reflect the thin bridge; added new `## When to Skip Spec Kit` section replacing the deleted `recommend-route` advisory. Bilingual H2 parity preserved (10 H2s in each, English anchors).
- `AGENTS.md` + `CLAUDE.md`: removed references to deleted commands and to `disposition-matrix.json` / `verified-versions.json`.
- `.gitignore`: added `docs/`; removed an obsolete comment referencing `cleanup-audit`.
- The `bridge-events.jsonl` log no longer carries event types: `skill_invocation`, `parity_check`, `submission_check`, `auto_archive` (the last is now `archive` with `status: "archived"`).

### Compatibility notes

- **Reading old handoff JSON**: a 0.3.0 install reads handoff JSON written by 0.1.x / 0.2.x without error; v2/v3-only fields are silently ignored. The next write produces a clean v1 document. No migration step required.
- **CI / Make files**: if you reference any of the removed scripts (e.g., `parity-check.ps1`, `validation-pass.ps1`, `submission-checklist.ps1`, `cleanup-audit.ps1`, `recommend-route.ps1`), update or remove those references. The trim does not provide compatibility shims.
- **Routing recommendation**: the previous `recommend-route` command is gone. See the new README `## When to Skip Spec Kit` section; the user decides the route.
- **Snapshot rollback**: `restore-snapshot.ps1` is gone. Snapshots are still taken under `.specify/bridge-snapshots/`; rollback becomes a manual `cp -r <snapshot-dir>/* <destination>`.

### Verification

- Three retained smoke tests, all green: `tests/test-claude-codex-skill-parity.ps1` (renamed from `test-claude-skill-parity.ps1`), `tests/test-handoff-shape.ps1` (new), `tests/test-guard-hardcoded-rules.ps1` (new).
- `specs/001-spec-superpowers-bridge` through `specs/005-marketplace-alignment` are byte-identical to their pre-trim state (verified by checksum `1f09423e4e91ec5b9edb396b7c7f2fe4a0a2a56a`).
- PowerShell line surface: 2,984 → 376 (~87.4% reduction across the retained 3 scripts + 1 helper).

## [0.2.0] - 2026-05-15

### Added

- `LICENSE` at repo root (MIT) for upstream catalog submission completeness.
- `marketplace/` directory holding the upstream-PR-ready artifacts: `catalog-entry.json`, `extensions-readme-row.md`, `upstream-pr-body.md`, plus a directory `README.md` explaining their use. Excluded from distribution per `plugin-distribution-manifest.yml`.
- `submission-checklist.ps1` script + `tests/test-submission-checklist.ps1`: mirrors the Spec Kit maintainers' upstream verification (manifest schema, file presence, URL HTTP 200, tag set, semver shape, description length, AI-disclosure presence). Exit 0 = submission-ready.
- `cleanup-audit.ps1` script + `tests/test-cleanup-audit.ps1`: surfaces stale source-repo files (`*.bak`, unreferenced `docs/`, abandoned one-shot scripts, `.gitignore` gaps, distribution manifest inconsistencies). Includes an opt-in `-Fix` mode.
- `docs/release-runbook.md`: 11-step release procedure with explicit `Verify:` lines for every step.
- README badges (4): license, latest release, last commit, Spec Kit compatibility.
- README sections covering pure-Codex / pure-Claude / dual-agent install paths, "first feature in 10 minutes" walkthrough, troubleshooting matrix, maintenance & versioning, and Architecture-in-60-seconds (paraphrasing the [dev.to comparison article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj) with attribution).
- Peer-extension comparison paragraph naming AIDE, architect-preview, api-contract-evolution, impact-predictor.
- Two new bridge meta-commands: `speckit.speckit-superpowers-bridge.submission-checklist`, `speckit.speckit-superpowers-bridge.cleanup-audit` (both `COMBINE` in the disposition matrix).

### Changed

- `extension.yml.version` bumped to `0.2.0`.
- `extension.yml.tags` replaced with the locked 6-tag set (`bridge, superpowers, cross-agent, governance, tdd, workflow`) per feature 005 clarify Q3.
- `verified-versions.json.verified_at` refreshed to 2026-05-15T19:00:00Z.
- `README.md` reflowed to the 11-section structure optimized for first-time readers (bilingual toggle → badges → value prop → workflow diagram → install paths → walkthrough → commands → configuration → troubleshooting → maintenance → architecture → contributing).
- `README.zh-CN.md` mirror-reflowed to identical H2 structure; bilingual parity check exits 0.
- `.gitignore` re-audited and grouped by category (per-developer state, OS junk, backup patterns, editor scratch, build artifacts).
- `plugin-distribution-manifest.yml` re-confirmed: `LICENSE`, `CHANGELOG.md`, `docs/release-runbook.md` in includes; `marketplace/**` added to excludes with reason.

### Fixed

- `extension.yml.tags` was 4 generic terms (`superpowers, implementation, handoff, bridge`); now matches the discoverability-tuned 6-tag set chosen via feature 005's clarify.

## [0.1.1] - 2026-05-15

### Added

- Bridge handoff schema v3: `autonomous_mode` + `resume_context` fields.
- Bridge meta-commands `speckit.speckit-superpowers-bridge.audit`, `.validate`, `.parity`, `.recommend-route`, `.execute` with corresponding scripts (`audit-install-state.ps1`, `validation-pass.ps1`, `parity-check.ps1`, `recommend-route.ps1`).
- Five mirrored `.claude/skills/speckit-git-*/SKILL.md` for cross-agent parity (`speckit-git-commit`, `-feature`, `-initialize`, `-remote`, `-validate`).
- Bilingual README scaffold (`README.md` + `README.zh-CN.md`) with structural parity check.
- `plugin-distribution-manifest.yml` declaring marketplace includes/excludes.
- 8 smoke test suites under `tests/`.
- `disposition-matrix.json` (31 entries) classifying every Spec Kit command + Superpowers skill as COMBINE / FORBID-UNDER-HANDOFF / SUPERSEDED-BY / REVIEW-ONLY.
- `verified-versions.json` pinning Spec Kit and Superpowers skill-pack versions.

### Changed

- Bridge `SKILL.md` on both Codex and Claude rewritten to issue explicit `Skill` tool / `$skill-name` invocations at named lifecycle phases.
- Actor resolution rewritten to a 4-step chain: explicit `-Actor` argument → `SPECKIT_BRIDGE_ACTOR` env var → `.specify/integration.json.default_integration` → `unknown`. Hard-coded `-Actor codex` defaults removed.
- Bridge extension commands moved to the official namespace `speckit.speckit-superpowers-bridge.*`.

### Fixed

- **CG-006**: Handoff command no longer hardcodes `-Actor codex`; correct actor resolved per the chain.
- **CG-003**: A `complete` handoff for one feature no longer blocks contract changes on a different feature (auto-archive path + cross-feature guard exemption added).
- **CG-004**: First-touch artifact-ownership claim now happens automatically via the auto-archive helper.

## [0.1.0] - 2026-05-15

### Added

- Initial bridge protocol with handoff state file (`.specify/superpowers-handoff.json`), guard rules (`guard-command.ps1`), audit logging (`bridge-events.jsonl`), rollback snapshots (`bridge-snapshots/`).
- Codex (`.agents/skills/speckit-superpowers-bridge/SKILL.md`) and Claude Code (`.claude/skills/speckit-superpowers-bridge/SKILL.md`) bridge skills.
- Local validation scripts: `update-handoff.ps1`, `restore-snapshot.ps1`, `test-bridge-guard.ps1`.
- AGENTS.md as the master cross-agent protocol; CLAUDE.md as the Claude-specific supplement.
- Constitution (`.specify/memory/constitution.md`) ratifying 5 principles: lightweight & repo-local, design/implementation separation, agent-neutral protocol, smooth bidirectional handoff, vendor-managed boundaries.

[Unreleased]: https://github.com/lihan3238/speckit-superpowers-bridge/compare/v0.4.3...HEAD
[0.5.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.5.0
[0.4.3]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.4.3
[0.4.2]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.4.2
[0.4.1]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.4.1
[0.4.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.4.0
[0.3.1]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.3.1
[0.3.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.3.0
[0.2.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.2.0
[0.1.1]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.1.1
[0.1.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.1.0
