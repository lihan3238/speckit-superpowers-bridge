# README structural contract — v0.6.0

Flat, checkable form of `spec.md` FR-001 + research D1..D7. Both `README.md` and `README.zh-CN.md` MUST satisfy ALL of the following structural assertions in order (failing any assertion fails US1 / US2 acceptance scenarios). Heading TEXT is translated for the Chinese mirror; structure/ordering is identical (FR-003 + SC-003).

---

## R1 — Top-to-bottom skeleton (must be in this order)

| # | Element | Required form |
|---|---|---|
| 1 | Centered hero block | `<p align="center">…title…</p>` followed by `<p align="center">…tagline…</p>` — both centered HTML `<p>` tags |
| 2 | Centered badge row | `<p align="center">` containing the badge anchor/img sequence from R3 |
| 3 | H1 | `# speckit-superpowers-bridge` |
| 4 | Language-toggle blockquote | `README.md`: `> 中文版：[README.zh-CN.md](README.zh-CN.md)`<br>`README.zh-CN.md`: `> English: [README.md](README.md)` |
| 5 | Bold value-prop sentence | One **bold** Markdown line stating the project's value in ≤ 1 sentence |
| 6 | Division-of-labor paragraphs | 1–3 short paragraphs explaining Spec Kit / Superpowers / bridge roles |
| 7 | `## Why speckit-superpowers-bridge` (or `## Why` in Chinese mirror) | Section explaining the gap the bridge fills |
| 8 | `## Quick Start` | Copy-paste-ready install one-liner inside a fenced bash block + numbered "what this does" list + at least one `> [!TIP]` callout |
| 9 | `## Positioning` (or equivalent Chinese heading) | 4-column × 4-row comparison table per research D2 |
| 10 | Collapsed `<details>` sections | All of: Installation / Prerequisites / First Feature in 10 Minutes / When to Skip Spec Kit / Commands / Configuration / Troubleshooting / Maintenance / Architecture — each wrapped in its own `<details><summary>…</summary>…</details>` block (per research D3) |
| 11 | `## Contributing and License` | Always-open close, short |

---

## R2 — TOC

- GitHub's auto-generated H2 sidebar TOC counts as satisfying FR-002. NO manual TOC required.
- If a manual TOC is added (optional), it MUST be inside its own `<details>` block at the top, between R1#4 and R1#5, and MUST be auto-generatable (no hand-maintained anchor lists).

---

## R3 — Badge row content (per research D1)

Left-to-right order, with link-target requirement per badge:

| # | Image (shields.io URL) | Link target | Mandatory? |
|---|---|---|---|
| 1 | `https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square` | `./LICENSE` | yes |
| 2 | `https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge?style=flat-square&label=bridge` | `https://github.com/lihan3238/speckit-superpowers-bridge/releases` | yes |
| 3 | `https://img.shields.io/badge/Spec_Kit-verified_0.8.16-success?style=flat-square` | `https://github.com/github/spec-kit` | yes (verified-version label updated per release) |
| 4 | `https://img.shields.io/badge/Superpowers-verified_5.1.0-success?style=flat-square` | `https://github.com/obra/superpowers` | yes (verified-version label updated per release) |
| 5 | `https://img.shields.io/badge/Spec_Kit_Marketplace-listed-blueviolet?style=flat-square` | catalog entry permalink (if stable) | OPTIONAL — drop if no stable permalink |

All badge URLs MUST use `style=flat-square` for visual consistency. All badges MUST be wrapped in anchor (`<a href>`) tags so they are clickable. Alt-text MUST be set on each `<img>` for graceful degradation (per spec edge case "badge service downtime").

---

## R4 — Bilingual parity invariants (per FR-003 / SC-003)

- Same number of H2 sections in `README.md` and `README.zh-CN.md`.
- Same order of H2 sections.
- Same number of badges in R3 (same shields.io URLs; only the labels in badges 3-4 may be localized).
- Same number of comparison-table rows in the positioning table (per research D2).
- Same number of `<details>` blocks.
- Code blocks, commands, paths, file names, JSON/YAML keys stay in English in both files (per Assumption "bilingual parity is structural, not literal").

---

## R5 — Native-Markdown-only invariant (per SC-010)

The polished READMEs MUST use ONLY:

- Standard CommonMark Markdown.
- GitHub-flavored Markdown alerts (`> [!TIP]`, `> [!NOTE]`, `> [!WARNING]`, `> [!CAUTION]`).
- The following inline-HTML constructs that GitHub renders natively: `<p align="center">`, `<img>` (only for badges), `<a href>`, `<picture>` (NOT used in v0.6.0 — D4), `<details><summary>`.

MUST NOT use:

- `<script>`, `<style>`, custom CSS classes, external JavaScript.
- Build steps, preprocessors, SVG mirrors of badges, generated HTML.
- Custom fonts, color palettes outside shields.io's `?color=` parameter.
- iframes, video embeds, or any element that breaks GitHub's sandbox.

---

## R6 — Acceptance test (smoke-suite compatible)

A tasks-phase smoke test ([tests/test-readme-structure.sh](tests/test-readme-structure.sh) or similar; ≤ 5-line delta budget per SC-009 — could amend an existing test) MUST assert at minimum:

1. `README.md` contains the EXACT centered-HTML hero-block pattern from R1#1.
2. `README.md` contains a `<p align="center">` block with ≥ 4 `<img>` tags and ≥ 4 shields.io URLs (badge row).
3. `README.md` contains the EXACT language-toggle line from R1#4.
4. `README.md` contains a `## Quick Start` heading appearing BEFORE any `## Installation` heading.
5. `README.md` H2 section count == `README.zh-CN.md` H2 section count.
6. `README.md` and `README.zh-CN.md` contain identical numbers of `<details>` blocks.

Test failure messages MUST point at the failing R-clause for fast localization.
