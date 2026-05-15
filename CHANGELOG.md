# Changelog

All notable changes to **speckit-superpowers-bridge** are documented in this file.

This project adheres to [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

> **AI-assistance disclosure**: This extension is developed with AI coding assistants (Claude Code for design + planning, Codex for implementation), per the AI-disclosure requirement in [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md). Every artifact passes human review before commit; the bridge's own validation pass and 17+ smoke tests are the verification surface.

## [Unreleased]

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

[Unreleased]: https://github.com/lihan3238/speckit-superpowers-bridge/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.2.0
[0.1.1]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.1.1
[0.1.0]: https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v0.1.0
