# Implementation Plan: Catalog Distribution Polish

**Branch**: `003-cross-platform-cleanup` | **Date**: 2026-05-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/007-catalog-distribution-polish/spec.md`

## Summary

v0.4.3 is a **catalog-distribution-polish** release. It adds nothing to the bridge runtime. It changes only the distribution surface — how users discover the bridge (via the official Spec Kit community catalog merged at PR #2586), how they install it (via a new stable-alias ZIP URL `releases/latest/download/speckit-superpowers-bridge.zip` that auto-tracks the latest GH release), and how future catalog bumps should be filed (via "Extension Submission" issues against `github/spec-kit`, not PRs against `extensions/catalog.community.json`).

Two implementation commits already shipped from Codex on this branch (`3659e6c` + `70f5c32`). The remaining work — and the scope of this retrospective spec — is to:

1. Record the v0.4.3 design rationale (this `plan.md` + the spec).
2. Relocate the v0.4.3 verification rows from `specs/003-bridge-cross-platform-scripts/verification.md` (where Codex appended them) to `specs/007-catalog-distribution-polish/verification.md` (their correct home per the constitution v1.2.0 gate).
3. Update `.specify/feature.json` to point at this feature.
4. Drive the 007 handoff through ready → executing → complete to produce a clean Spec Kit compliance trail.

The bridge runtime (handoff, guard, auto-archive, actor-resolution) and the bridge scripts under `.specify/extensions/speckit-superpowers-bridge/scripts/{powershell,bash}/` are **byte-frozen** across the v0.4.3 cycle (verified by SC-005: `git diff v0.4.2..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/` returns empty).

## Technical Context

**Language/Version**: PowerShell 5.1+ and Bash 4.0+ runtime flavors unchanged from v0.4.2. No language/runtime changes.

**Primary Dependencies**: Spec Kit `>=0.8.10`; Superpowers plugin (latest, both Codex `.agents/` and Claude Code `.claude/`). No new dependencies. v0.4.3 trims **one** declared dependency: `git` is dropped from `marketplace/catalog-entry.json` `requires.tools`, matching the v0.4.1 shape merged into upstream `extensions/catalog.community.json`. Git remains recommended workflow discipline but is not declared as an extension runtime tool.

**Storage**: Repo-local filesystem unchanged. The new artifact is the stable-alias ZIP uploaded as a release asset (lives on GitHub, not in-repo).

**Testing**: Three retained smoke tests (`tests/test-handoff-shape.ps1`, `tests/test-guard-hardcoded-rules.ps1`, `tests/test-claude-codex-skill-parity.ps1`) all green for v0.4.2 — and because v0.4.3 is byte-frozen on the bridge runtime, they remain green for v0.4.3 by construction. Re-run is optional, not required by this plan.

**Target Platform**: Same as v0.4.2 — Windows native PowerShell + WSL Linux bash verified; macOS bash deferred.

**Project Type**: Spec Kit extension package (`.specify/extensions/speckit-superpowers-bridge/`) plus mirrored skill folders (`.claude/skills/...`, `.agents/skills/...`) plus root-level marketplace listing (`marketplace/`) plus release tooling (`scripts/release/`).

**Performance Goals**: Stable-alias URL resolution is a GitHub HTTP redirect (sub-100 ms). Local build script unchanged otherwise.

**Constraints**:
- Bridge-runtime byte-freeze (FR-012, SC-005): scripts under `.specify/extensions/speckit-superpowers-bridge/scripts/{powershell,bash}/` MUST NOT be modified across the v0.4.3 cycle.
- Spec-history preservation (FR-013, SC-006): specs/001/002/004/005/006 MUST be byte-identical to the v0.4.1 tag.
- Verification-record hygiene (FR-008, FR-009, SC-003, SC-004): v0.4.3 rows live under this feature's `verification.md`; specs/003's `verification.md` returns to v0.4.2-only.

**Scale/Scope**: ~12 files touched across the two Codex commits (release.yml, build script, READMEs, marketplace docs, extension.yml, CHANGELOG). This retrospective adds 4 new spec files (spec/plan/tasks/verification) under `specs/007-*/`, modifies 1 existing file (`specs/003-*/verification.md`), and updates `.specify/feature.json`. Zero bridge-runtime files touched.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Justification |
|-----------|--------|---------------|
| **I. Lightweight & Repo-Local** | ✅ PASS | v0.4.3 ships zero new runtime code, zero new dependencies. The stable-alias ZIP is a build-output, not a new runtime. The catalog-entry shape slimming (drop git, drop tool descriptions) is a net negative on declared surface. |
| **II. Design/Implementation Separation (NON-NEGOTIABLE)** | ✅ PASS | The bridge runtime — handoff schema, guard rules, actor chain, auto-archive — is byte-frozen across v0.4.3. The retrospective spec records prior work in design-time files only; it does NOT modify implementation. |
| **III. Agent-Neutral Protocol** | ✅ PASS | Both `.claude/skills/speckit-superpowers-bridge/SKILL.md` and `.agents/skills/speckit-superpowers-bridge/SKILL.md` are unchanged in v0.4.3 (they were last touched by v0.4.2's B1 fix). The catalog-entry simplification is symmetric across agents. |
| **IV. Smooth Bidirectional Handoff** | ✅ PASS | Handoff JSON schema unchanged. The 007 cycle runs the same auto-archive → ready → executing → complete pattern as 003 did. `artifact_owner = claude` is preserved through the cycle. |
| **V. Vendor-Managed Boundaries** | ✅ PASS | The work modifies only `marketplace/`, `README.md` / `README.zh-CN.md`, `scripts/release/`, `.github/workflows/`, `CHANGELOG.md`, and the new `specs/007-*/` directory. Officially generated `.claude/skills/speckit-*` and `.agents/skills/speckit-*` are NOT touched. |

**Gate result**: PASS. No principle violations require Complexity Tracking.

### Post-Design Re-Check (after Phase 1 design captured below)

| Principle | Post-design status | Notes |
|-----------|--------------------|-------|
| **I. Lightweight & Repo-Local** | ✅ STILL PASS | Phase 1 design is documentation-only. Net code surface change: 0 lines of runtime code added, 0 removed. |
| **II. Design/Implementation Separation** | ✅ STILL PASS | Phase 1 confirms FR-012 byte-freeze: the design (stable-alias upload, catalog-shape slimming) does NOT need any script change to execute — the workflow YAML and the build script are release tooling, not bridge runtime. |
| **III. Agent-Neutral Protocol** | ✅ STILL PASS | Phase 1 design touches no agent-specific code path. |
| **IV. Smooth Bidirectional Handoff** | ✅ STILL PASS | Phase 1 plans the 007 handoff cycle using the same 5 hardcoded helpers (auto-archive + update-handoff) as 003 used. |
| **V. Vendor-Managed Boundaries** | ✅ STILL PASS | Phase 1 design names exactly the files Phase 0 research identified; no vendor-generated skill is touched. |

**Post-design gate result**: PASS.

## Phase 0: Research

**Inputs**: User's prompt referenced github/spec-kit issue #2581 and PR #2586. Goal: understand how upstream Spec Kit accepts catalog updates, and what install path is canonical for end-users.

### R1. PR #2586 review (the merged catalog entry)

- **What it added**: One row to `docs/community/extensions.md` and one entry to `extensions/catalog.community.json`, both pointing at v0.4.1 of this bridge.
- **Shape we MUST match for future bumps**: tools list = `[powershell, bash, jq]` (no `git`), no per-tool `description` field, no `verified: true` marker (it stays `false` until a maintainer reviews), `downloads` + `stars` start at 0.
- **Implication for v0.4.3**: `marketplace/catalog-entry.json` was carrying `git` in `requires.tools` and a `description` on every tool. Codex's commit `3659e6c` slimmed both. This is correct.

### R2. Upstream catalog update procedure

- **Authoritative source**: `marketplace/README.md` lines 45–54 (already in-repo): "**Manual post-release step (cross-repo, intentionally not automated):** 8. Open a catalog-submission issue... If the extension is already listed, state that this is an **existing-entry update**... 9. Use `marketplace/extension-submission-body.md` as the issue body... 10. The Spec Kit maintainer reviews and updates `catalog.community.json` directly. **Do NOT open a PR against `catalog.community.json` — the upstream guide explicitly requires issue-based submissions.**"
- **Implication**: v0.4.3 does NOT trigger an automatic upstream catalog bump. The catalog stays at v0.4.1 until someone files an existing-entry update issue. This is OPTIONAL follow-up after the retrospective spec lands.

### R3. Why a stable-alias URL is the user-facing answer

- The official catalog row's `download_url` is pinned to whatever version was current at submission time (v0.4.1). Users running the catalog-listed install command get v0.4.1 forever unless the maintainer applies a bump.
- GitHub's `releases/latest/download/<asset-name>` URL pattern always redirects to the latest GH release. By uploading a `speckit-superpowers-bridge.zip` asset (no version in the filename) on every release, we expose a URL that auto-tracks our latest version regardless of catalog staleness.
- This is the v0.4.3 win: users land on our README via the catalog, see the stable-alias URL in the install section, and get latest.

### R4. Build/upload mechanics

- `scripts/release/build-extension-zip.ps1` already emitted `dist/speckit-superpowers-bridge-v<version>.zip`. Codex's commit `3659e6c` added a `Copy-Item` step to also emit `dist/speckit-superpowers-bridge.zip` (identical content, no version in name).
- `.github/workflows/release.yml` `gh release create` line was extended to upload both assets.
- Both assets are byte-identical → identical SHA256 (`d3da5b97…`).

### R5. Verification record hygiene

- Constitution v1.2.0 §"End-User Verification Sandbox": "Each release that publishes an artifact appends one `## <version>` section here recording the sandbox-install verification across required platforms."
- "Here" = the **current feature's** `verification.md`. Codex appended v0.4.3 rows to specs/003's verification.md (wrong location). The retrospective moves them to specs/007's verification.md.
- specs/003's verification.md returns to v0.4.2-only after the move.

## Phase 1: Design

### D1. Files to create

- `specs/007-catalog-distribution-polish/spec.md` — this feature's spec (above sibling). DONE in this commit.
- `specs/007-catalog-distribution-polish/plan.md` — THIS file. DONE.
- `specs/007-catalog-distribution-polish/tasks.md` — task list, mostly `[x]` because Codex already did the work. DONE in this commit.
- `specs/007-catalog-distribution-polish/verification.md` — v0.4.3 sandbox rows, moved verbatim from specs/003. DONE in this commit.

### D2. Files to modify (one-line each)

- `specs/003-bridge-cross-platform-scripts/verification.md`: remove the `## v0.4.3` section (lines 8–14 of the post-Codex state).
- `.specify/feature.json`: change `"feature_directory"` to `"specs/007-catalog-distribution-polish"`.

### D3. Files NOT modified

- Anything under `.specify/extensions/speckit-superpowers-bridge/scripts/` — FR-012 byte-freeze.
- `extension.yml`, `release.yml`, `scripts/release/build-extension-zip.ps1`, `CHANGELOG.md`, `README.md`, `README.zh-CN.md`, `marketplace/**` — already at v0.4.3 from Codex's commits.
- The published GitHub release v0.4.3 itself — final, downloadCount > 0.

### D4. Handoff cycle

1. Auto-archive 003 (`status: complete` → cleared `feature_directory`). DONE before this commit.
2. `update-handoff -Status ready -FeatureDirectory specs/007-catalog-distribution-polish -ArtifactOwner claude -Actor claude` to open 007.
3. `update-handoff -Status executing -FeatureDirectory specs/007-catalog-distribution-polish -Actor claude` (omit `-ArtifactOwner`; the script preserves prior `claude` per v0.4.2 B1 fix).
4. `update-handoff -Status complete -Actor claude` once tasks.md tasks are all `[x]`.

### D5. Verification-record schema reuse

- The v0.4.2 contract (`specs/003-bridge-cross-platform-scripts/contracts/verification-record.md`) is reused as-is. The 007 `verification.md` follows the same `Platform / bridge_sha256 / Date (UTC) / Operator / Result / Notes` columns.
- No new contract file is created under `specs/007-*/contracts/` — the 003 contract is canonical project-wide.

## Phase 2: Tasks

`tasks.md` is generated in this same commit. Almost everything is `[x]` (already done by Codex). The remaining `[ ]` tasks are the handoff transitions + this retrospective commit itself.

## Phase 3: Verification

See Spec §"Success Criteria" (SC-001 through SC-007). The end-of-cycle verification is:

1. `gh release view v0.4.3 --json assets` shows 2 assets, both digest `sha256:d3da5b97…`.
2. `curl -fsSI https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip` redirects to the v0.4.3 versioned asset.
3. `cat specs/007-*/verification.md | grep -c '^## v'` returns `1`.
4. `cat specs/003-*/verification.md | grep -c '^## v'` returns `1`.
5. `git diff v0.4.2..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/` returns empty.
6. `git ls-tree -r HEAD specs/001-* specs/002-* specs/004-* specs/005-* specs/006-* | sort | git hash-object --stdin` equals v0.4.1's hash.
7. `.specify/superpowers-handoff.json` `.status == "complete"` && `.feature_directory == "specs/007-catalog-distribution-polish"` && `.artifact_owner == "claude"`.

## Out of Scope / Deferred

- **v0.4.3.1 release**: Not planned. v0.4.3 is final.
- **Upstream catalog bump (v0.4.1 → v0.4.3 in `extensions/catalog.community.json`)**: optional follow-up; filed via issue when the user decides.
- **macOS sandbox run**: Deferred per spec Clarifications Q3 — no host available; the WSL Linux bash flavor is byte-identical to what would run on macOS, satisfying constitution v1.2.0's "Windows + at least one Linux/macOS" requirement.

## Complexity Tracking

*Not applicable.* All 5 constitution principles pass pre- and post-design. No deviations to justify.
