# Feature Specification: Marketplace Alignment

**Feature Branch**: `005-marketplace-alignment`
**Created**: 2026-05-15
**Status**: Draft
**Input**: User description: "深度联网调研 specify 社区开发插件如何上架官方，调研优秀插件的风格和相关必须文件。我们希望在保证插件最轻量干净可迭代的前提下实现链接speckit、superpower功能，并对齐优秀的插件标准，成功上架并获得高star；同时我们的文档也要优化，清晰用户友好地结合实际使用表达出我们的工作流思路，并附上各种使用环境情况的配置说明；做做减法瘦身，该ignore的ignore，该清理的清理。"

## Clarifications

### Session 2026-05-15

- Q: What is the Spec Kit "catalog" and what shape does our entry take? → A: The catalog is a single JSON file at `extensions/catalog.community.json` in the upstream `github/spec-kit` repo — no separate marketplace endpoint. Our entry is one JSON object alphabetically ordered by `id`, containing the required fields (`id`, `name`, `description` ≤200 chars, `author`, `version`, `download_url`, `repository`, `license`, `requires.speckit_version`) plus recommended fields (`homepage`, `documentation`, `changelog`, `requires.tools[]`, `provides.commands`, `provides.hooks`, `tags`). Our entry — drafted in `marketplace/catalog-entry.json` in this repo — is what the upstream PR pastes verbatim into the catalog file. The corresponding row drafted for `extensions/README.md` is pasted alongside in the same PR.
- Q: Which Spec Kit version does this bridge target locally and as a requires constraint? → A: **Spec Kit 0.8.10** (per the live `.specify/init-options.json`). `extension.yml.requires.speckit_version` MUST be `">=0.8.10"` and `verified-versions.json.spec_kit_version` MUST be `"0.8.10"`. Earlier draft references to `0.8.9` are stale and MUST be updated in any spec, plan, README, or test fixture that mentions them.
- Q: What tag set should `extension.yml.tags` carry for catalog discovery? → A: **6 tags**, balancing what-we-are + what-we-do + who-we-support: `bridge, superpowers, cross-agent, governance, tdd, workflow`. Locked as the canonical tag vocabulary for the v0.1.x marketplace listing. Future additions/removals MUST be documented in CHANGELOG.md.

**Primary Design Reference**: [Spec Kit vs Superpowers — dev.to article (truongpx396)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)

**Research evidence**:
- [Spec Kit extensions/EXTENSION-PUBLISHING-GUIDE.md](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md) — official submission process.
- [Spec Kit extensions/EXTENSION-DEVELOPMENT-GUIDE.md](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-DEVELOPMENT-GUIDE.md) — schema details.
- [extensions/catalog.community.json](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json) — the catalog file to PR against.
- [extensions/README.md](https://github.com/github/spec-kit/blob/main/extensions/README.md) — the README to update alongside the catalog.
- [Extensify](https://speckit-community.github.io/extensions/extensify) — recommended scaffolding/validation tool; reference for high-quality extension structure.
- [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md) — AI-disclosure requirement for contributors.
- Notable peer extensions to model: AIDE, architect-preview, api-contract-evolution, impact-predictor.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Marketplace Listing Acceptance (Priority: P1)

A maintainer wants to submit this bridge to the official Spec Kit community catalog and pass the maintainers' verification on the first try (manifest schema, URL accessibility, file completeness, AI-disclosure). Every required artifact for the upstream PR exists in the repo, the catalog entry has all required and recommended fields, and the AI-assistance disclosure is part of the PR template.

**Why this priority**: This is the binary "did the plugin actually ship?" outcome. Without listing acceptance, all other polish is internal. The Spec Kit community catalog gates discoverability behind a single PR review; we want zero round-trips.

**Independent Test**: Can be tested by running an offline checklist that mirrors the maintainers' verification (manifest schema valid, every required file present, release ZIP downloadable from the published GitHub release URL, catalog entry fields complete) and confirming zero failing items. The actual upstream PR is the end-to-end test.

**Acceptance Scenarios**:

1. **Given** the repo at the proposed release tag, **When** a maintainer (or our local audit) validates the bridge against the official Spec Kit submission checklist, **Then** every required artifact exists (`extension.yml`, `README.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore`, `commands/`, optional `docs/`) and the manifest schema passes ExtensionManifest validation.
2. **Given** the proposed catalog entry for `extensions/catalog.community.json`, **When** validated against the catalog entry schema, **Then** every required field is present (`name`, `id`, `description` ≤200 chars, `author`, `version`, `download_url`, `repository`, `license`, `requires.speckit_version`), and 2–10 `tags` are declared.
3. **Given** the upstream PR description, **When** opened against `github/spec-kit`, **Then** it includes the mandated AI-assistance disclosure per Spec Kit CONTRIBUTING.md (extent of AI usage in code generation vs. documentation).
4. **Given** the published release ZIP URL, **When** fetched from a clean network, **Then** the file resolves with HTTP 200 and unpacks to a directory containing `extension.yml`, `README.md`, `LICENSE`, and the `commands/` tree.

---

### User Story 2 — User-Friendly Documentation Covering Multi-Environment Setup (Priority: P1)

A first-time visitor lands on our repository or the marketplace listing page and within 5 minutes understands (a) what the bridge does, (b) how to install it for their setup (pure Codex / pure Claude Code / both), (c) how to run the first feature end-to-end through agent dialog, and (d) where to read for troubleshooting and architecture deep-dives. The bilingual READMEs (EN + zh-CN) tell the same story with the same examples.

**Why this priority**: High-star adoption requires clear docs more than feature density. The current README is a usable v0.1.1 draft but lacks: a workflow diagram, per-environment installation paths, an end-to-end usage example, and a troubleshooting matrix. The bilingual files exist but the structure isn't optimized for marketplace landing-page reading.

**Independent Test**: Can be tested by giving the README to a developer who has never used Spec Kit or Superpowers; measuring whether they can install and complete a sample workflow in ≤30 minutes without external help. Bilingual parity is automatically checked by the existing `check-readme-bilingual-parity.ps1`.

**Acceptance Scenarios**:

1. **Given** a reader opens `README.md`, **When** they read the first 100 lines, **Then** they see (in order): the one-line value proposition, a workflow diagram or ASCII chart showing Spec Kit → bridge → Superpowers, install commands for the three setups (pure Codex, pure Claude, both), and a "first feature in 10 minutes" walkthrough.
2. **Given** a reader has Codex only (no Claude Code), **When** they follow the install section, **Then** they find a Codex-specific install path that explicitly says "no Claude Code required" and lists only the commands they need.
3. **Given** a reader has Claude Code only, **When** they follow the install section, **Then** they find an analogous Claude-only path, including the `specify integration add codex` instruction if they ever want to switch later.
4. **Given** a reader hits a known failure mode (handoff stuck in `executing`, parity check P1 finding, missing peer skill), **When** they check the README troubleshooting section, **Then** every documented failure has a one-paragraph cause + a concrete remediation command.
5. **Given** the bilingual READMEs, **When** the parity check runs, **Then** both files cover identical sections in identical order; translations differ only in body text.

---

### User Story 3 — Slim & Iterate (Priority: P2)

A maintainer wants the published plugin (the release ZIP that lands in a host project) to contain only the assets the host needs at runtime — no specs/, no tests/, no bridge events log, no snapshots, no scratch checklist files, no markdown that's only relevant to this development repo. Concurrently the source repo's `.gitignore` excludes everything that's per-developer state (already partly true), and the source repo is pruned of dead files left over from earlier feature iterations.

**Why this priority**: A bloated ZIP costs adoption (downloaders are wary of size); a noisy `git status` costs maintainer productivity; stale files cost reviewer attention. Lightweight is one of the constitution's non-negotiable principles.

**Independent Test**: Can be tested by simulating a marketplace install into a clean target directory and asserting the on-disk file count matches the `plugin-distribution-manifest.yml` exactly (no extras, no missing); and by running `git status` on a freshly-cloned repo and asserting no per-developer state appears.

**Acceptance Scenarios**:

1. **Given** the release ZIP for the next version, **When** unpacked into an empty host project, **Then** the file set equals the `includes:` list of `plugin-distribution-manifest.yml` byte-for-byte; no `specs/`, no `tests/`, no `.specify/bridge-events.jsonl`, no `.specify/bridge-snapshots/`, no `.specify/superpowers-handoff.json`, no `.specify/feature.json`.
2. **Given** the source repository at the release tag, **When** `git status` runs in a clean clone, **Then** zero per-developer state files appear (they are all gitignored).
3. **Given** the existing `docs/` directory under the extension, **When** audited, **Then** every file is referenced from `README.md` or `extension.yml`; files referenced from neither are deleted.
4. **Given** the source repo's root directory, **When** audited, **Then** no stale helper scripts (e.g. one-shot migration scripts from earlier features), no `.bak-*` backups, no editor scratch files exist. Any one-shot script that has finished its purpose is either deleted or moved into `specs/<feature>/scripts-archive/` with a `WHY-KEPT.md` note.
5. **Given** the release ZIP, **When** compared against the previous version (v0.1.1), **Then** the file count and total byte size do NOT grow without a corresponding entry in `CHANGELOG.md` explaining why.

---

### User Story 4 — Discoverability & Trust Signals (Priority: P3)

A user searching the Spec Kit catalog wants enough signal to install our bridge over alternatives: clear tags, a descriptive (≤200 char) summary, a real CHANGELOG, a visible LICENSE, working badges in the README (license, version, last commit), a link to the canonical north-star article (the dev.to comparison piece), and example screenshots or asciinema recordings of the actual workflow.

**Why this priority**: P3 because it's reputation/marketing rather than functional correctness, but high-star adoption depends on perceived quality, and the difference is often two minutes of polish per signal. Deferrable but cheap.

**Independent Test**: Can be tested by reviewing the README rendered on github.com and confirming the trust signals (badges, screenshot/diagram, north-star link, peer comparisons) are all present and link to working URLs.

**Acceptance Scenarios**:

1. **Given** the README renders on github.com, **When** a reader scans the top of the page, **Then** they see at least 4 working badges (license, version, downloads if available, last commit / activity) and a one-paragraph value proposition with a link to the dev.to article.
2. **Given** the README, **When** a reader looks for "is this maintained?", **Then** they find a CHANGELOG link, the most-recent release date, and an explicit maintenance commitment (e.g. "tracked against Spec Kit 0.8.9; re-verified on each minor release").
3. **Given** the extension.yml, **When** read, **Then** `tags:` lists 4–10 relevant terms (e.g. `superpowers`, `bridge`, `tdd`, `governance`, `workflow`, `cross-agent`, `claude-code`, `codex`) for catalog search discoverability.

---

### Edge Cases

- The upstream Spec Kit version this bridge requires (`>=0.8.10` in current `extension.yml`) does not match the version installed locally for development (`0.8.9` per `init-options.json`). Marketplace listing must either pin to a real shipped Spec Kit version or relax the constraint with a documented rationale.
- The maintainer cannot test the release ZIP locally because the ZIP is built by GitHub Releases from the source tree at a tag. The validation must run on the source tree at the would-be tag, not on a downloaded ZIP.
- A peer Spec Kit extension changes its catalog entry shape after we submit — our entry must be self-validating against the documented schema, not by copying another entry verbatim.
- The maintainers reject the submission with feedback (e.g. "your tags include too many"). The repo's audit checklist must surface the same finding before the PR is opened, so the rejection is preventable.
- The bilingual README parity check passes structurally but the zh-CN translation is stale (the EN version evolved since translation). The parity script's structural check does not catch content drift; humans must.
- A future Spec Kit release ships its own bilingual README convention different from ours — we must adapt without changing our user-facing structure.
- The marketplace listing is accepted but the bridge gets zero installs in the first month because the description doesn't differentiate from peer extensions. Tags + description quality is the lever; not a defect, but a feedback loop.
- A user installs the plugin into a project that has neither Codex nor Claude Code integration active. The bridge must surface an install-time hint (via `audit-install-state.ps1` or the post-install message) telling them how to proceed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST contain every required file the Spec Kit publishing guide names: `extension.yml`, `README.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore`, `commands/`. Missing files block submission.
- **FR-002**: `extension.yml` MUST declare every required field per the Spec Kit ExtensionManifest schema: `schema_version: "1.0"`, `extension.id`, `extension.name`, `extension.version`, `extension.description`, `extension.author`, `extension.repository`, `extension.license`, and `requires.speckit_version`. Plus 4–10 `tags`.
- **FR-003**: A `LICENSE` file MUST exist at repo root with the license text matching the `extension.license` field (`MIT`).
- **FR-004**: A `CHANGELOG.md` MUST exist at repo root following Keep-a-Changelog conventions, with at minimum a `[Unreleased]` section and the released v0.1.1 entry.
- **FR-005**: The proposed catalog entry for `extensions/catalog.community.json` MUST be drafted in this repo (e.g. `marketplace/catalog-entry.json` or inline in plan.md) with every required field: `name`, `id`, `description` ≤200 chars, `author`, `version`, `download_url`, `repository`, `license`, `requires.speckit_version`, plus `tags` (2–10).
- **FR-006**: The proposed snippet for `extensions/README.md` MUST be drafted (the same way) so the upstream PR can paste it directly.
- **FR-007**: The upstream PR description template MUST include the mandated AI-assistance disclosure per Spec Kit CONTRIBUTING.md.
- **FR-008**: An offline submission-checklist script MUST exist that mirrors the maintainers' verification (manifest schema, file presence, URL accessibility for `repository` and `download_url`, semver format, catalog entry field completeness). Exit zero means submission-ready.
- **FR-009**: `README.md` (English) MUST contain, within its first 100 lines, in this order: (a) one-paragraph value proposition with the dev.to article link, (b) a workflow diagram or ASCII chart, (c) install paths for pure Codex / pure Claude / both, (d) a "first feature in 10 minutes" walkthrough.
- **FR-010**: `README.md` MUST contain a Troubleshooting section covering at minimum: handoff stuck in `executing`, parity check P1 finding, missing per-agent peer skill, autonomous-mode not activating, validation-pass failing on first run.
- **FR-011**: `README.zh-CN.md` MUST cover the same sections as `README.md` in the same order (verified by `check-readme-bilingual-parity.ps1`).
- **FR-012**: The release ZIP, when unpacked into a clean host project, MUST contain exactly the files listed in `plugin-distribution-manifest.yml`'s `includes:` (no extras, no missing). The published version of the manifest MUST be the source of truth.
- **FR-013**: A repo-level cleanup audit MUST run as part of release-prep, identifying: (a) any file in `docs/` not referenced by `README.md` or `extension.yml`, (b) any one-shot/migration script that is no longer invoked, (c) any backup file (`*.bak*`, `*.orig`), (d) any per-feature scratch checklist whose status is "complete" and which is older than the latest feature. Findings → either delete the file or document keeping it in a new `cleanup-rationale.md`.
- **FR-014**: `.gitignore` MUST be re-audited to ensure: per-developer state (handoff JSON, events log, snapshots, `.specify/feature.json`, per-feature `checklists/protocol-quality.md`) is ignored; plugin assets are tracked; OS-junk and backup patterns are ignored. The audit MUST be re-runnable.
- **FR-015**: `extension.yml.tags` MUST be the canonical 6-tag set: `bridge, superpowers, cross-agent, governance, tdd, workflow`. Tags MUST be lowercase-hyphenated. The set is locked for the v0.1.x release cycle; any additions/removals require a CHANGELOG.md entry.
- **FR-016**: `extension.yml.requires.speckit_version` MUST be `">=0.8.10"` (matching the version installed locally per `.specify/init-options.json`). `verified-versions.json.spec_kit_version` MUST also be `"0.8.10"`. Any tightening above 0.8.10 in a future release MUST be documented in CHANGELOG.md.
- **FR-017**: The README MUST contain a "Maintenance & Versioning" section stating the upstream Spec Kit version this bridge is verified against (linking to `verified-versions.json`), the release cadence expectation, and the re-verification commitment.
- **FR-018**: The README MUST contain a one-section "Architecture in 60 seconds" summary that paraphrases (with attribution) the dev.to article's WHAT-vs-HOW split and links to our `disposition-matrix.json` as the codification.
- **FR-019**: Both English and Chinese READMEs MUST link to each other on the first non-empty line for language toggling.
- **FR-020**: The release process MUST be documented as a runbook (one markdown file under `docs/` or repo root) covering: bump version, update CHANGELOG, tag release, build/upload ZIP, draft upstream PR, paste catalog entry, paste extensions/README.md snippet, include AI disclosure.

### Key Entities

- **Submission Checklist Report**: The output of the offline submission-checklist script — pass/fail per checked item (file presence, schema validity, URL accessibility, field completeness, tag count, semver shape). Same envelope shape as the existing parity-check report.
- **Catalog Entry Draft**: The JSON snippet destined for `extensions/catalog.community.json`, drafted in this repo for review before the upstream PR.
- **Extensions README Snippet**: The Markdown row destined for `extensions/README.md`, drafted in this repo.
- **Release Runbook**: A markdown document enumerating the ordered steps to produce a new release (semver bump, CHANGELOG update, git tag, ZIP build, upstream PR draft).
- **Cleanup Audit Report**: The output of the cleanup audit — list of removable files, kept-with-rationale files, and unresolved items. Same envelope as install-state audit.
- **Tag Vocabulary**: The documented set of allowed tags for the `extension.yml.tags` field (4–10 chosen from the set).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The submission-checklist script exits 0 on this repo at the next release tag; all required files present, manifest schema valid, URLs reachable (HTTP 200), catalog entry complete.
- **SC-002**: A first-time reader, given only the published `README.md`, can complete one full feature workflow (constitution → specify → clarify → plan → tasks → bridge execute → validate) in under 30 minutes on a clean Codex-only OR Claude-only OR dual-agent setup.
- **SC-003**: Bilingual README parity check exits 0 — structural sections match between `README.md` and `README.zh-CN.md`.
- **SC-004**: Cleanup audit identifies and resolves at least 5 items (deleted files or documented-kept) on the first run; subsequent runs find zero new items unless new dead files have accumulated.
- **SC-005**: The release ZIP's unpacked file set equals `plugin-distribution-manifest.yml`'s `includes:` set (verified by `check-distribution-manifest.ps1 -SimulateInstall`); no missing files, no extras.
- **SC-006**: The upstream PR description includes the AI-assistance disclosure verbatim, and the catalog entry passes the Spec Kit maintainers' automated manifest validation on the first submission attempt (zero PR-amendment round-trips for schema/structural issues).
- **SC-007**: `extension.yml.tags` contains 4–10 tags from the documented vocabulary; `description` is ≤200 characters; `requires.speckit_version` is satisfied by a shipped Spec Kit version.
- **SC-008**: The README contains all four trust signals (badges, workflow diagram, dev.to article link, troubleshooting matrix) verified by a simple grep-based assertion in the checklist script.
- **SC-009**: Repository ZIP size (or unpacked size) after slimming does not exceed the previous version's size by more than 20% per release, and any increase is explained in CHANGELOG.md.
- **SC-010**: After listing, the project records at least one external install (downloads counter > 0 in the catalog entry's auto-updated field) within 30 days of acceptance — used as a feedback signal, not a hard gate.

## Assumptions

- The Spec Kit community catalog is the authoritative discovery endpoint (`extensions/catalog.community.json` in `github/spec-kit`). No separate marketplace registry endpoint exists at Spec Kit 0.8.x.
- The upstream submission workflow is the documented "fork + PR" process; maintainers don't review code, only verify catalog entry shape + URL accessibility + security signals. Source: [EXTENSION-PUBLISHING-GUIDE.md](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md).
- The release artifact is a GitHub-Releases-built ZIP from a tag. The `download_url` in the catalog entry points to this ZIP.
- AI-assistance disclosure is required by Spec Kit's CONTRIBUTING.md; the PR description MUST state both the extent (full code generation across features 001–005) and the human review process.
- The bilingual README convention (`README.md` + `README.zh-CN.md`, parity-checked structurally) is our own; Spec Kit itself does not specify a multilingual standard. If the upstream evolves, we follow.
- The constitution's "lightweight" principle binds this feature: no new runtime, no new global dependency, no scope creep. All work is repo-file edits + new scripts + new documentation.
- The dev.to article remains the project's design north star; the README's "Architecture in 60 seconds" section paraphrases it under fair-use attribution.
- The previously-deferred CG-005 (Bash port at `specs/003-bridge-cross-platform-scripts/`) remains a separate feature and is NOT a blocker for marketplace listing — the marketplace listing can ship Windows-first; Linux users can wait for the Bash port without affecting catalog acceptance.
- "High stars" is a marketing outcome that depends on factors beyond our control (Spec Kit's overall adoption, peer extension competition, blog-post visibility). The spec optimizes for the things we control (description quality, tag fit, docs clarity, trust signals); we treat stars as a downstream observation, not a controllable target.
