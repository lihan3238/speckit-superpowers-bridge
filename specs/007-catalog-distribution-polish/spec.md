# Feature Specification: Catalog Distribution Polish

**Feature Branch**: `003-cross-platform-cleanup` (the 007 spec was added retrospectively on the same branch where the v0.4.3 commits already landed)
**Created**: 2026-05-16
**Status**: Retrospective — describes `v0.4.3` already shipped 2026-05-16
**Input**: User feedback after Codex completed v0.4.3 work outside the Spec Kit flow: *"我让codex刚又接着干你的活，但是似乎没完全走我们的spec的计划流程。你先收个尾，完成这次spec，0.4.3版本，注意调研官方的插件更新与下载方式，我们的插件已被官方收录，但是我似乎注意到版本发布更新和用户下载使用方式有点粗糙。"* (Paraphrased EN: "Close out the v0.4.3 work as a proper spec. Research the official catalog update / download mechanism — our extension is now in the official catalog, but the version-update and user-install paths feel rough.")

**Primary Design Reference**: [Spec Kit vs Superpowers — dev.to article (truongpx396)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj). This feature does not touch the bridge runtime; it polishes the **distribution surface** so the bridge stays aligned with upstream Spec Kit's `extensions/catalog.community.json` shape and so users can install the latest release without manually editing a hard-coded version URL.

## Clarifications

### Session 2026-05-16

- Q: Why is this a retrospective spec rather than a forward-looking one? → A: Codex implemented and shipped the v0.4.3 work directly (commits `3659e6c` "prepare v0.4.3 catalog-friendly distribution" + `70f5c32` "record v0.4.3 release verification") without first creating a `specs/007-*` design artifact. The shipped artifact is correct; what was missing is the Spec Kit compliance trail. This spec is the trail, recorded after the fact, and the verification record is relocated from `specs/003-bridge-cross-platform-scripts/verification.md` (where Codex appended it) to this feature's `verification.md`.
- Q: Does this require an upstream PR against `github/spec-kit`'s `extensions/catalog.community.json` to bump it from v0.4.1 → v0.4.3? → A: No. Per `marketplace/README.md` lines 45–54 and the upstream `CONTRIBUTING` guidance documented there, catalog bumps go through a fresh "Extension Submission" **issue** (not a PR). The stable-alias URL added in v0.4.3 (`releases/latest/download/speckit-superpowers-bridge.zip`) is the in-repo escape hatch that lets users get the latest regardless of catalog staleness. Filing an existing-entry update issue is OPTIONAL follow-up; the spec does not require it.
- Q: Does v0.4.3 inherit v0.4.2's macOS-deferral? → A: Yes. Constitution v1.2.0 §"End-User Verification Sandbox" requires Windows + at least one Linux/macOS verification; WSL Linux satisfies that. macOS remains PENDING (no host) per the same rationale as v0.4.2 Clarifications Q3.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Stable Latest-Release Install Path (Priority: P1) 🎯 MVP

A user discovers the bridge via the official Spec Kit community catalog (`github/spec-kit`'s `docs/community/extensions.md` table, merged at PR #2586). The catalog row links them here. They run `specify extension add ... --from <stable-alias-URL>` and get **whatever the latest released bridge version is**, without first reading our release page to find the current version number.

**Why this priority**: The official catalog row is the discovery surface. Once a user lands here, the install command needs to "just work" against the latest release, not against the version that was current when the catalog row was filed (v0.4.1). Without this story, every catalog-driven install would either get a stale version, or require the user to manually look up the latest tag and rewrite the URL. That is the "粗糙" (rough) install path the user flagged.

**Independent Test**: From a fresh Spec Kit project, run `specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`; confirm the installed extension reports version `0.4.3` (the current latest) via `specify extension info`; confirm both `/speckit-superpowers-bridge` (Claude Code) and `$speckit-superpowers-bridge` (Codex) skills are present.

**Acceptance Scenarios**:

1. **Given** a fresh Spec Kit `0.8.10+` project, **When** the user runs the stable-alias install command, **Then** `specify extension info speckit-superpowers-bridge` reports `version: 0.4.3`.
2. **Given** the GH release `v0.4.3`, **When** an HTTP client follows `releases/latest/download/speckit-superpowers-bridge.zip`, **Then** the redirect resolves to `releases/download/v0.4.3/speckit-superpowers-bridge.zip` and the asset content (37,126 bytes) is byte-identical to `releases/download/v0.4.3/speckit-superpowers-bridge-v0.4.3.zip` (digest `d3da5b97…`).
3. **Given** a user who wants reproducibility, **When** they read the `README.md` `### Version-pinned install` section, **Then** they find the hard-coded `v0.4.3` URL preserved as an explicit opt-in for pinned installs.

---

### User Story 2 — Upstream Catalog-Shape Compliance (Priority: P2)

A maintainer of `github/spec-kit` reviews a future "existing-entry update" issue we file. Our catalog metadata (in `marketplace/catalog-entry.json`) matches the **exact shape** of what was merged into `extensions/catalog.community.json` by PR #2586 — same fields, same tool-list shape, no extras that would force the maintainer to re-edit. Future bumps become a mechanical metadata transcription.

**Why this priority**: P2 because v0.4.1 is already accepted; "future bumps are mechanical" is a forward-looking ergonomic, not a today-blocker. But it matters: if our local `marketplace/catalog-entry.json` shape drifts from upstream's, every bump becomes a small reformatting argument with the maintainer.

**Independent Test**: `diff` the contents of `marketplace/catalog-entry.json` (post-v0.4.3) against the v0.4.1 entry in `github/spec-kit`'s merged `extensions/catalog.community.json` (PR #2586). The only differences should be: `version`, `download_url`, `created_at`/`updated_at`. No field-shape differences.

**Acceptance Scenarios**:

1. **Given** the v0.4.3 `marketplace/catalog-entry.json`, **When** inspected, **Then** the `requires.tools` list is exactly `[powershell, bash, jq]` (no `git`, no per-tool `description` field).
2. **Given** the v0.4.3 `marketplace/extensions-readme-row.md`, **When** inspected, **Then** the table columns match upstream's current `docs/community/extensions.md` shape: Name | Description | Category | Permissions | Repository.
3. **Given** the v0.4.3 `marketplace/extension-submission-body.md`, **When** inspected, **Then** it lists both the version-pinned URL (`/releases/download/v0.4.3/speckit-superpowers-bridge-v0.4.3.zip`) AND the stable alias (`/releases/latest/download/speckit-superpowers-bridge.zip`), with matching `d3da5b97…` SHA256 in both places.

---

### User Story 3 — Update-Procedure Clarity (Priority: P2)

A future contributor preparing the v0.5.x bump reads `marketplace/README.md` and understands within 30 seconds: (a) you do NOT open a PR against `extensions/catalog.community.json`; (b) you open an **issue** using the "Extension Submission" template with `marketplace/extension-submission-body.md` as the body; (c) the maintainer applies the bump.

**Why this priority**: P2 because the bump path is documented in upstream `CONTRIBUTING`, but the upstream doc is not co-located with our code. Without our local pointer, future bumps will repeat the "PR? issue? both?" investigation that v0.4.3 went through.

**Independent Test**: Open `marketplace/README.md`. Within the first 60 lines, find the explicit instruction that catalog bumps are filed as issues, not PRs. Confirm `marketplace/extension-submission-body.md` is up-to-date for v0.4.3.

**Acceptance Scenarios**:

1. **Given** `marketplace/README.md`, **When** read, **Then** it explicitly states: "Do NOT open a PR against `catalog.community.json` — the upstream guide explicitly requires issue-based submissions."
2. **Given** `marketplace/extension-submission-body.md`, **When** read, **Then** the version + URL + SHA256 fields are aligned to v0.4.3 (commit `3659e6c` did this work).

---

### User Story 4 — Verification Record Hygiene (Priority: P2)

A maintainer auditing `specs/` later wants each release's sandbox verification record to live in **the spec dir for that release**. `specs/003-*/verification.md` should contain only the rows it owned (v0.4.2's). v0.4.3's rows belong to v0.4.3's spec dir (this one).

**Why this priority**: P2 because the v0.4.3 rows are valid records — they're just in the wrong file. Moving them is a small relocation. But the constitution v1.2.0 gate says "each release that publishes an artifact appends one `## <version>` section here recording the sandbox-install verification"; "here" means each release's own verification.md, otherwise the per-release audit trail collapses.

**Independent Test**: `grep -c '^## v' specs/003-*/verification.md` should be 1 (only `v0.4.2`). `grep -c '^## v' specs/007-*/verification.md` should be 1 (only `v0.4.3`). The two PASS rows in 007 should carry the workflow-emitted SHA256 (`d3da5b97…`).

**Acceptance Scenarios**:

1. **Given** the retrospective spec lands, **When** `specs/003-*/verification.md` is inspected, **Then** it contains only the v0.4.2 section.
2. **Given** the retrospective spec lands, **When** `specs/007-*/verification.md` is inspected, **Then** it contains the v0.4.3 section with Windows PS + WSL Linux PASS rows (operator `codex`, recorded by Codex on 2026-05-16 07:14 UTC) plus the macOS PENDING row.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The GH release workflow `release.yml` MUST upload two assets per tag: `speckit-superpowers-bridge-v<version>.zip` (versioned) and `speckit-superpowers-bridge.zip` (stable alias). Both are byte-identical (SHA256 matches).
- **FR-002**: `scripts/release/build-extension-zip.ps1` MUST emit both the versioned and alias ZIP locally so `gh release create` can upload both.
- **FR-003**: `README.md` and `README.zh-CN.md` MUST present the stable-alias URL as the default install path, with the version-pinned URL preserved as a "Version-pinned install" opt-in section.
- **FR-004**: `marketplace/catalog-entry.json` `requires.tools` MUST contain only `powershell`, `bash`, `jq` (no `git`), and no per-tool `description` field. This matches the v0.4.1 shape merged by upstream at PR #2586.
- **FR-005**: `marketplace/extensions-readme-row.md` MUST present columns matching upstream's current `docs/community/extensions.md` table: Name, Description, Category, Permissions, Repository.
- **FR-006**: `marketplace/extension-submission-body.md` MUST reference both the versioned ZIP URL and the stable-alias URL, with matching SHA256.
- **FR-007**: `marketplace/README.md` MUST document the "issue-based submission" path explicitly and prohibit opening a PR against `catalog.community.json`.
- **FR-008**: A `specs/007-catalog-distribution-polish/verification.md` MUST exist with one `## v0.4.3` section containing rows for Windows PowerShell, WSL Linux bash, and macOS. The Windows + WSL rows MUST record `bridge_sha256 = d3da5b971b39590c66a21b2a76ab5e9c683528b812dd1ab3a71c8b31d959af01`. macOS row MUST be PENDING with documented reason (no host).
- **FR-009**: `specs/003-bridge-cross-platform-scripts/verification.md` MUST be restored to contain only the `## v0.4.2` section (the `## v0.4.3` section is moved out, not duplicated).
- **FR-010**: `.specify/feature.json` MUST point at `specs/007-catalog-distribution-polish` for the duration of the 007 handoff cycle.
- **FR-011**: The bridge handoff (`.specify/superpowers-handoff.json`) MUST progress through the canonical cycle for 007: archived(prior 003) → ready → executing → complete. `artifact_owner` MUST remain `claude` through the cycle.

### Non-Functional / Constraint Requirements

- **FR-012** (byte-freeze): `git diff v0.4.2..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/` MUST return empty. v0.4.3 is a distribution-polish release; bridge runtime is unchanged.
- **FR-013** (spec-history preservation): `git ls-tree -r HEAD specs/001-* specs/002-* specs/004-* specs/005-* specs/006-* | sort | git hash-object --stdin` MUST equal the same hash computed at the v0.4.1 tag. Only specs/003 (verification.md cleanup) and specs/007 (new) change.

### Key Entities

- **Stable alias ZIP**: `speckit-superpowers-bridge.zip` uploaded as a release asset whose contents match the versioned ZIP byte-for-byte. URL `releases/latest/download/speckit-superpowers-bridge.zip` always resolves to the latest GH release's asset.
- **Catalog entry**: `marketplace/catalog-entry.json` — local mirror of the upstream-accepted entry shape. Updated each release; submitted via issue (not PR) when the maintainer chooses to bump the upstream catalog.
- **Verification record**: per-release table in `specs/<feature>/verification.md` recording sandbox-install outcomes. Schema pinned by `specs/003-bridge-cross-platform-scripts/contracts/verification-record.md` (reused).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: GitHub release `v0.4.3` exists with both assets present, both reporting `digest: sha256:d3da5b971b39590c66a21b2a76ab5e9c683528b812dd1ab3a71c8b31d959af01`. *(Verified by `gh release view v0.4.3 --json assets`.)*
- **SC-002**: `curl -fsSL -o - https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip | sha256sum` returns the same digest as SC-001. *(Stable-alias URL resolves to the v0.4.3 asset.)*
- **SC-003**: `specs/007-catalog-distribution-polish/verification.md` contains 1 `## v0.4.3` section with 3 rows (2 PASS + 1 PENDING); both PASS rows carry the SC-001 digest.
- **SC-004**: `specs/003-bridge-cross-platform-scripts/verification.md` contains exactly 1 `## v` section (only v0.4.2).
- **SC-005**: `git diff v0.4.2..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/` returns empty. *(Bridge runtime byte-frozen across the v0.4.3 cycle.)*
- **SC-006**: Spec-history checksum (specs/001/002/004/005/006) matches v0.4.1 tag value.
- **SC-007**: `.specify/superpowers-handoff.json` ends the 007 cycle with `status: complete`, `feature_directory: specs/007-catalog-distribution-polish`, `artifact_owner: claude`.

## Out of Scope

- **No new release**: v0.4.3 stands. This spec records what shipped; it does NOT prepare a v0.4.3.1.
- **No bridge runtime changes**: scripts under `.specify/extensions/speckit-superpowers-bridge/scripts/{powershell,bash}/` are frozen.
- **No upstream PR**: bumping the public catalog from v0.4.1 → v0.4.3 is the maintainer's call, filed via issue. We surface it as optional follow-up after this spec lands.
- **No macOS sandbox run**: deferred per Clarifications Q3 (no host); inherited from v0.4.2.

## Dependencies and Assumptions

- Assumes the GitHub Actions release workflow has the permissions to upload multiple assets per release (it does — observed in run `25940895819`-equivalent for v0.4.3).
- Assumes upstream Spec Kit's catalog shape is stable for the lifetime of v0.4.x (PR #2586 merged on 2026-05-15; no breaking shape change has been observed since).
- Assumes WSL Linux bash 5.2.21 + jq 1.7 is representative of Linux/macOS bash environments for sandbox-gate purposes.
