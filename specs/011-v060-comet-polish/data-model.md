# Data Model — v0.6.0 polish + alignment

This feature is documentation + metadata only. There is no runtime data model in the traditional sense — no database, no service, no API state. "Entities" below are *content shapes* whose schemas are checked during PR review and via the bash smoke suite.

---

## Entity 1 — README hero block

**Surface**: top of `README.md` (and `README.zh-CN.md`), above the H1.

**Fields**:

| Field | Type | Cardinality | Constraint |
|-------|------|-------------|------------|
| `centered_title_html` | HTML (`<p align="center">`-wrapped) | 1 | Contains project name; no logo image in v0.6.0 (per research D4) |
| `tagline` | plain text | 1 | ≤ 80 chars; English in `README.md`, Chinese in mirror; content fixed by research D5 |
| `language_toggle_blockquote` | Markdown blockquote line | 1 | Exact form: `> 中文版：[README.zh-CN.md](README.zh-CN.md)` (or inverse in mirror) per research D6 |

**Lifecycle**: written once during v0.6.0 polish; edited only on project rename or tagline redefinition.

---

## Entity 2 — Badge row

**Surface**: immediately after the hero block, before the H1.

**Fields** (ordered list of badge objects):

| Position | Label | shields.io URL pattern | Link target | Mandatory? |
|----------|-------|------------------------|-------------|------------|
| 1 | License: MIT | `https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square` | `./LICENSE` | yes |
| 2 | Bridge version | `https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge?style=flat-square&label=bridge` | `https://github.com/lihan3238/speckit-superpowers-bridge/releases` | yes |
| 3 | Spec Kit verified | `https://img.shields.io/badge/Spec_Kit-verified_<version>-success?style=flat-square` | `https://github.com/github/spec-kit` | yes |
| 4 | Superpowers verified | `https://img.shields.io/badge/Superpowers-verified_<version>-success?style=flat-square` | `https://github.com/obra/superpowers` | yes |
| 5 | Marketplace listed | `https://img.shields.io/badge/Spec_Kit_Marketplace-listed-blueviolet?style=flat-square` | catalog entry permalink | optional |

**Lifecycle**: badges 1, 2, 5 stable across releases; badges 3, 4 refreshed once per release alongside `verified-versions.json` (same edit unit).

---

## Entity 3 — Positioning / comparison table

**Surface**: between `## Why` and the collapsed `## Installation` block.

**Schema** (4 columns × 4 rows; per research D2):

- Columns: `Owns design` / `Owns implementation` / `Cross-agent` / `Bridge-style overhead`
- Rows: `Just speckit.implement` / `Just Superpowers` / `rpamis/comet` / `speckit-superpowers-bridge` (this)

**Lifecycle**: cell content factual and stable; refreshed only when a peer changes positioning or a row's upstream changes scope.

---

## Entity 4 — verified-versions.json

**Surface**: `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` (the only new file shipped by v0.6.0).

**Fields** (all required):

| Field | Type | Constraint |
|-------|------|------------|
| `verified_at` | ISO-8601 UTC string ending `Z` | Generated at release time |
| `spec_kit_version` | semver string (no leading `v`) | `0.8.16` for v0.6.0 |
| `superpowers_version` | semver string (no leading `v`) | `5.1.0` for v0.6.0 |
| `bridge_version` | semver string (no leading `v`) | MUST equal `extension.yml.extension.version` AND `catalog-entry.json.version` |
| `notes` | string (multi-line allowed; may be `""`) | Concise upstream-change summary |

**Schema extensibility rule**: future releases MAY add new keys (additive); MUST NOT remove or rename existing keys; MUST NOT change value types.

**Lifecycle**: created in v0.6.0; refreshed once per subsequent release; never deleted.

**Cross-file invariants** (verified by tasks-phase smoke test):

- `verified-versions.json.bridge_version == extension.yml.extension.version`
- `verified-versions.json.bridge_version == marketplace/catalog-entry.json.version`
- `verified-versions.json.bridge_version == latest concrete release header in CHANGELOG.md`

---

## Entity 5 — CHANGELOG `[0.6.0]` section

**Surface**: `CHANGELOG.md`, immediately below the (now refreshed) `[Unreleased]` skeleton.

**Required sub-sections** (Keep-a-Changelog convention; empty subsections may be omitted):

| Sub-section | Content for v0.6.0 |
|---|---|
| `### Added` | New `verified-versions.json` artifact with locked 5-field schema. Hero-led README layout with badges + language toggle + comparison table + collapsed sections. |
| `### Changed` | `marketplace/catalog-entry.json.download_url` decoupled from per-release version pin to GitHub `/releases/latest/download/...` stable-alias (one-shot — future releases never edit this field). `extension.yml.extension.version` 0.5.0 → 0.6.0. `marketplace/catalog-entry.json.version` 0.5.0 → 0.6.0. |
| `### Compatibility` | Verified against Superpowers `5.1.0` and Spec Kit `0.8.16` (see `verified-versions.json`). `extension.yml.requires.speckit_version` floor stays at `>=0.8.10` — no behavioral change requires newer Spec Kit. |
| `### Upstream notes (informational)` | Superpowers v5.1.0 removed slash commands `/brainstorm`, `/execute-plan`, `/write-plan` (use skill names instead). Superpowers v5.1.0 removed the `superpowers:code-reviewer` named agent (use `superpowers:requesting-code-review` skill — bridge already does). Superpowers v5.1.0 `finishing-a-development-branch` now only cleans worktrees inside `.worktrees/`. Bridge surface unaffected (verified by grep — `specs/011-v060-comet-polish/research.md` Output 1). |
| `### Fixed` | (none — pure additive release) |
| `### Removed` | (none — backwards-compatible) |

**Lifecycle**: created during this feature; immutable post-release except for typo PATCH.

---

## Entity 6 — Marketplace catalog-entry.json

**Surface**: `marketplace/catalog-entry.json` (existing file).

**v0.6.0 deltas** (only):

- `.version` : `"0.5.0"` → `"0.6.0"`
- `.download_url` : `"https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.5.0/speckit-superpowers-bridge-v0.5.0.zip"` → `"https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip"` **(decoupled; one-shot)**

All other fields (id, name, description, author, license, repository, homepage, documentation, changelog, requires, provides, tags) unchanged.

**Lifecycle**: post-v0.6.0, only `.version` changes per release; `.download_url` is frozen.

---

## Files NOT changed in v0.6.0 (negative-space contract)

The following file paths MUST remain byte-identical to their v0.5.0 state (per FR-009..FR-012 and SC-005/SC-008/SC-010):

- `.specify/extensions/speckit-superpowers-bridge/scripts/bash/*.sh` (all 5 scripts)
- `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/*.ps1` (all 5 scripts)
- `.specify/extensions/speckit-superpowers-bridge/commands/*.md` (all 3 command files)
- `.specify/extensions.yml` (hooks unchanged)
- `.{claude,agents}/skills/speckit-superpowers-bridge/SKILL.md` **behavioral content** (cosmetic version-line refresh — e.g. "v0.5.0+" → "v0.6.0+" — is the only allowed delta)
- All vendor-managed `.{claude,agents}/skills/speckit-*` skills EXCEPT `speckit-superpowers-bridge` — untouched
- `.specify/memory/constitution.md` (no constitutional change)
- Existing `tests/test-*.sh` test files (≤ 5 lines delta across the suite for version-string updates only)

---

**Data model complete** — Phase 1 contracts derive directly from these entity shapes.
