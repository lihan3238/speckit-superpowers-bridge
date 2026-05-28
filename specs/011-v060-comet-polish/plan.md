# Implementation Plan: v0.6.0 — Comet-Style README Polish + Upstream Alignment

**Branch**: `011-v060-comet-polish` | **Date**: 2026-05-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/011-v060-comet-polish/spec.md`

## Summary

A **release-cycle, documentation-and-metadata-only** feature that delivers three pillars at once: (a) polish `README.md` and `README.zh-CN.md` to a hero-led, badged, language-toggled layout modelled on the rpamis/comet structural pattern (using native Markdown + GitHub-flavored alerts only — no JS/CSS/build step); (b) record the v0.6.0 verified-pair (Superpowers v5.1.0 + Spec Kit v0.8.16) in a new project-owned `verified-versions.json` artifact at the bridge package root; (c) bump the bridge version 0.5.0 → 0.6.0 across `extension.yml`, `marketplace/catalog-entry.json`, and `CHANGELOG.md`, while **one-shot decoupling** the catalog `download_url` to the GitHub `/releases/latest/download/speckit-superpowers-bridge.zip` stable-alias URL so future releases never edit that field again. Strict adherence to constitution principle VI (Native-First) — codified by the spec's new **SC-010 lightness budget**: zero new script lines, zero new SKILL.md behavioral instructions, exactly one new file in the bridge package, native-Markdown-only README, zero new hooks/commands/state files.

Technical approach (per Phase 0 research):

- README polish uses only native GitHub-rendered Markdown constructs (`<p align="center">`, `<picture>` tag, `<details>` blocks, `> [!TIP]`/`> [!NOTE]` alerts, shields.io image links).
- Stable-alias asset already exists on every release tag (empirically verified — v0.5.0's release page carries both `speckit-superpowers-bridge-v0.5.0.zip` AND `speckit-superpowers-bridge.zip`, identical 44708 bytes). Switching the catalog `download_url` to the latest-alias URL is a zero-risk single-line edit.
- `verified-versions.json` is the only new artifact in the bridge package; its 5-field schema (verified_at / spec_kit_version / superpowers_version / bridge_version / notes) is locked in this feature with an additive-only future-extension rule.
- Bridge scripts, guard rules, SKILL.md behavioral text, and `extensions.yml` hook entries are all explicitly **byte-frozen** by FR-009..FR-012 and SC-005/SC-008/SC-010.

## Technical Context

**Language/Version**: N/A (Markdown content + JSON metadata + YAML metadata + version-string edits)

**Primary Dependencies**: GitHub Releases `/releases/latest/download/<asset>` URL pattern (well-documented platform behavior); shields.io for badge images (graceful fallback to GitHub's image-failure alt-text rendering on outage); existing release runbook (`docs/release-runbook.md`); existing bash smoke suite under `tests/`.

**Storage**: filesystem only — Markdown (`README.md`, `README.zh-CN.md`, `CHANGELOG.md`), JSON (`marketplace/catalog-entry.json`, new `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`), YAML (`.specify/extensions/speckit-superpowers-bridge/extension.yml`).

**Testing**: existing `tests/test-*.sh` bash smoke suite on WSL bash (per 009 alignment). No new tests added (FR-013). Expected version-string deltas in 1-2 tests at most (≤ 5 lines total per SC-009).

**Target Platform**: WSL bash dev environment for source edits; GitHub Releases as the consumer-facing distribution surface; rendered Markdown on GitHub for the README polish UX; sandbox at `..\test_specify_superpower` on WSL for the constitution sandbox gate.

**Project Type**: Spec Kit extension package (the bridge IS the project). Single-package layout, no `src/` tree, no test framework beyond the bash smoke suite. README + metadata files live at the project root and at well-defined package paths.

**Performance Goals**: SC-001 — cold reader answers "what does this do?" in **under 30 s** using only the first viewport of the polished README. SC-002 — badge row renders within **5 s** of GitHub page load with graceful degradation on shields.io outage.

**Constraints**:

- Constitution Principle VI (Native-First) — codified as SC-010 lightness budget.
- Principle II — vendor-managed `.{claude,agents}/skills/speckit-*` skills MUST NOT be edited.
- Principle V — only the project-owned `speckit-superpowers-bridge` skills MAY receive cosmetic version-line updates.
- 5 hardcoded guard rules in `guard-command.{ps1,sh}` MUST remain byte-identical (FR-010, SC-005).
- Total new files in the bridge extension package = exactly 1 (`verified-versions.json`).

**Scale/Scope**: 1 release artifact (v0.6.0); 2 README files updated; 1 new JSON file created; 4-5 metadata field updates across `extension.yml` + `catalog-entry.json` + `CHANGELOG.md`; 0 new scripts; 0 new commands; 0 new hooks. Estimated total diff ≤ 600 LoC across all files (README polish dominates).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| **I. Lightweight & Repo-Local** | ✅ PASS | Adds 0 daemons, 0 services, 0 new infrastructure. Closes one long-standing gap (verified-versions.json was referenced by runbook but did not exist) with a single 5-field, ≤30-line JSON file. SC-010 codifies the budget. |
| **II. Design/Implementation Separation (NON-NEGOTIABLE)** | ✅ PASS | Vendor-managed `.{claude,agents}/skills/speckit-*` skills untouched (FR-011). Bridge surface (scripts + guard rules + SKILL.md behavioral text) byte-frozen (FR-009, FR-010, SC-005). The polish is pure outward-facing documentation. |
| **III. Agent-Neutral Protocol** | ✅ PASS | README + CHANGELOG + verified-versions.json + catalog-entry.json are agent-agnostic — same content reaches Codex and Claude consumers. No agent-specific branching introduced. |
| **IV. Smooth Bidirectional Handoff** | ✅ PASS | No handoff state file or event-log schema changes; v0.6.0 ships the same `.specify/superpowers-handoff.json` schema and the same `bridge-events.jsonl` format as v0.5.0. |
| **V. Vendor-Managed Boundaries** | ✅ PASS | Vendor-managed skills untouched. Project-owned `speckit-superpowers-bridge` SKILL.md peers MAY receive cosmetic version-line refreshes; behavioral instruction lines unchanged (SC-010). |
| **VI. Native-First Compatibility (Trust Upstream Growth)** | ✅ PASS (with gate answers) | See below. |

### Native-First gate (constitution §VI, v1.3.0+)

This feature introduces exactly ONE piece of new bridge surface — the `verified-versions.json` file. Per the gate template:

- **Q1: Does upstream Spec Kit / Superpowers already do this?** No. Upstream Spec Kit tracks its own version internally and Superpowers tracks its own; neither maintains a "verified-pair" snapshot for downstream extensions. The Spec Kit extension marketplace schema does not currently surface a verified-version field. Status: **no, upstream does not do this**.
- **Q2: Is upstream the right place to fix this?** No — this is an **extension-author audit trail** specific to each extension's compatibility-testing discipline. Spec Kit ecosystem-wide standardization would be welcome long-term but is multi-quarter work; the bridge's release runbook references this file by name today, so closing the local gap is the right immediate move. Status: **no, this is local-owned**.

Both gate answers are "no" → the new surface is justified. Total new surface: **1 file, 5 fields, ≤ 30 lines, additive-only schema extension policy**. No new state files beyond it. No new hooks, commands, or scripts.

### Release gate (constitution §"End-User Verification Sandbox", v1.2.0+)

v0.6.0 ships a release artifact → sandbox gate applies. Polish phase MUST include one task: install the v0.6.0 ZIP fresh in `..\test_specify_superpower` via the published release URL (which after this feature WILL be the stable-alias `releases/latest/download/speckit-superpowers-bridge.zip`), run one complete bridge cycle on WSL bash, record outcome in `specs/011-v060-comet-polish/verification.md`. (009's bash-only smoke surface narrows the sandbox-platform list to WSL bash; future PowerShell coverage is a separate feature.)

## Project Structure

### Documentation (this feature)

```text
specs/011-v060-comet-polish/
├── plan.md              # This file
├── research.md          # Phase 0 — decision log for the 9 open polish/release decisions
├── data-model.md        # Phase 1 — README/JSON entity schemas (very thin)
├── quickstart.md        # Phase 1 — maintainer's v0.6.0 release walkthrough (decoupled-URL aware)
├── contracts/
│   ├── verified-versions.schema.json   # JSON schema for the new file
│   ├── readme-structure.md             # Checkable structural contract (FR-001 in flat form)
│   └── catalog-entry-shape.md          # Post-decoupling catalog-entry.json field contract
├── checklists/
│   └── requirements.md  # Spec quality (already passing 16/16 from /speckit-clarify)
└── tasks.md             # Phase 2 — created by /speckit-tasks, not this command
```

### Source / artifact paths touched (repo root)

```text
README.md                                            # FR-001 polish
README.zh-CN.md                                      # FR-003 mirror polish
CHANGELOG.md                                         # FR-005 [0.6.0] section
docs/release-runbook.md                              # retire the "edit catalog download_url" step
AGENTS.md                                            # OPTIONAL: 1-line mention of decoupled URL in the marketplace policy section
CLAUDE.md                                            # SPECKIT marker block updated by this command (plan reference)

.specify/extensions/speckit-superpowers-bridge/
├── extension.yml                                    # FR-006: version 0.5.0 -> 0.6.0
├── verified-versions.json                           # FR-004: NEW — only new file (≤ 30 lines)
└── (scripts/, commands/ — UNCHANGED, byte-frozen per FR-009/FR-010)

marketplace/
└── catalog-entry.json                               # FR-007: version 0.5.0 -> 0.6.0 + download_url decoupling

dist/
└── speckit-superpowers-bridge-v0.6.0.zip            # FR-008: NEW build artifact (not tracked source)
(dist/speckit-superpowers-bridge.zip                 # stable-alias dist refresh, existing convention)

.claude/skills/speckit-superpowers-bridge/SKILL.md   # OPTIONAL cosmetic version-line refresh ONLY (SC-010)
.agents/skills/speckit-superpowers-bridge/SKILL.md   # OPTIONAL cosmetic version-line refresh ONLY (SC-010)

tests/                                               # ≤ 5 lines delta across the suite (SC-009)
```

**Structure Decision**: The project is a Spec Kit extension package; the structure above is the existing v0.5.0 layout with one added file (`verified-versions.json`) at the bridge package root. No directory creation, no new top-level folders. The decoupling change is a single-line edit in `marketplace/catalog-entry.json`; the rest is documentation and metadata.

## Complexity Tracking

> No Constitution Check violations. Section intentionally empty.

The only candidate "complexity" item — introducing a new file in the bridge package — was evaluated against principle VI's Native-First gate (Q1+Q2 both "no") and found to be justified extension-local audit infrastructure, not new framework surface. Total new file count: 1. Total new script lines: 0. Total new SKILL.md behavioral lines: 0.

## Post-Design Constitution Re-check (after Phase 1)

Re-run after [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), and [quickstart.md](quickstart.md) were written. Same 6 principles, same table form — all still pass, and Phase 1 added concrete evidence:

| Principle | Status | Phase-1 evidence |
|---|---|---|
| **I. Lightweight & Repo-Local** | ✅ STILL PASS | data-model.md Entity 4 caps `verified-versions.json` at 5 fields / ≤ 30 lines; contract [verified-versions.schema.json](contracts/verified-versions.schema.json) is a 1-file additive-only schema. No service, no daemon, no global mod. |
| **II. Design/Implementation Separation (NON-NEGOTIABLE)** | ✅ STILL PASS | data-model.md "Files NOT changed in v0.6.0" explicitly lists vendor-managed skills, scripts, guard rules, and `extensions.yml` hooks as byte-frozen. quickstart.md Step 7 verifies via smoke tests. |
| **III. Agent-Neutral Protocol** | ✅ STILL PASS | All Phase 1 contracts are agent-agnostic: README structure works identically on Claude Code + Codex; verified-versions.json is data, not behavior; catalog-entry shape is agent-agnostic ecosystem metadata. |
| **IV. Smooth Bidirectional Handoff** | ✅ STILL PASS | No handoff JSON schema change; no `bridge-events.jsonl` schema change; quickstart.md Step 11–12 reuses the existing v0.5.0 handoff flow verbatim. |
| **V. Vendor-Managed Boundaries** | ✅ STILL PASS | data-model.md negative-space section caps SKILL.md edits to cosmetic version-line refreshes; no vendor skill touched. |
| **VI. Native-First Compatibility (Trust Upstream Growth)** | ✅ STILL PASS | research.md Output 1 (Superpowers v5.1.0 surface grepped clean), Output 2 (stable-alias asset already published), Output 3 (`requires.speckit_version` floor stays permissive) all reinforce native-first. New surface = 1 file, justified by Q1+Q2 gate. The `download_url` decoupling REMOVES future per-release churn — net surface DECREASE relative to status quo. |

**Native-First gate re-check**: Q1 ("does upstream do this?") still "no" after Phase 1 — Spec Kit's marketplace schema continues to not surface verified-version metadata. Q2 ("is upstream the right place?") still "no" — this is extension-local audit. New surface justified. The fact that v0.6.0 actually *reduces* the per-release edit surface (catalog `download_url` retires from runbook) is a Principle VI win, not a violation.

**Release gate re-check**: quickstart.md Step 11 codifies the sandbox verification on WSL bash with concrete `specify init` + `specify extension add` + bridge-cycle commands and a `verification.md` deliverable. Gate planned.

**SC-010 lightness budget re-check**: every Phase 1 artifact reaffirms the budget. data-model.md Entity 4 caps the 1 new file at 30 lines. contracts/verified-versions.schema.json enforces additive-only future extensions. readme-structure.md R5 enforces native-Markdown-only. quickstart.md Step 4 implementation uses only native Markdown + GFM alerts.

**Conclusion**: design phase complete, all gates pass, ready for `/speckit-tasks`.
