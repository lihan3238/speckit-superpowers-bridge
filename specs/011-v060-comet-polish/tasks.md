---

description: "Task list for v0.6.0 — Comet-style README polish + upstream alignment"
---

# Tasks: v0.6.0 — Comet-Style README Polish + Upstream Alignment

**Input**: Design documents from `specs/011-v060-comet-polish/`

**Prerequisites**: [plan.md](plan.md) ✅, [spec.md](spec.md) ✅, [research.md](research.md) ✅, [data-model.md](data-model.md) ✅, [contracts/](contracts/) ✅, [quickstart.md](quickstart.md) ✅

**Tests**: Light — no new test files added. Existing `tests/test-*.sh` suite gets ≤ 5 lines of version-string updates per SC-009. One small structural smoke test for the polished README is added by amending an existing test (per contracts/readme-structure.md R6).

**Organization**: Tasks grouped by user story. **US1 (English README polish)** is the MVP and ships standalone. **US2 (Chinese mirror)** parallelizes with US1 once the structural contract is in hand. **US3 (release mechanics)** parallelizes with US1+US2 since it touches different files. Polish phase wraps everything for release tag + sandbox verification.

## Format: `[TaskID] [P?] [Story?] Description`

- **[P]** = different file, no dependency on incomplete tasks → can run in parallel
- **[Story]** = `[US1]` / `[US2]` / `[US3]` ; setup/polish phases have no story label

---

## Phase 1: Setup (Shared)

**Purpose**: Confirm working state before edits.

- [ ] T001 Verify working tree is on `011-v060-comet-polish` branch with clean status (`git status` reports only untracked specs/011 artifacts from prior phases); verify WSL proxy reachable per CLAUDE.md (`curl -sI --proxy http://10.88.0.6:10808 https://github.com | head -1` returns `HTTP/2 200`).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: None. This is a documentation + metadata feature; no shared models, services, or schemas need to exist before user-story work begins. Skipped intentionally.

**Checkpoint**: Foundation ready — all user-story phases can begin in parallel.

---

## Phase 3: User Story 1 — First-time visitor decides in 30 seconds (Priority: P1) 🎯 MVP

**Goal**: Polish [README.md](../../README.md) to the hero-led + badge-row + collapsed-details layout defined in [contracts/readme-structure.md](contracts/readme-structure.md), so a cold reader can answer "what does this do?" in under 30 seconds from the first viewport (SC-001).

**Independent Test**: Open the polished `README.md` rendered on GitHub. Without scrolling past the first viewport (~600 px), a cold reader can name (a) the problem the bridge solves, (b) which two upstreams it connects, (c) which AI agents it supports, (d) the install one-liner. SC-001 met.

> NOTE: All US1 tasks edit the same file (`README.md`) and must therefore be sequential — no `[P]` markers within US1.

- [ ] T002 [US1] Insert centered hero block at top of [README.md](../../README.md): `<p align="center">` containing project title `# speckit-superpowers-bridge` and the ≤80-char tagline `Thinnest possible bridge from Spec Kit (design) to Superpowers (implementation).` per [research D5](research.md#d5--tagline-the-80-char-hero-block-second-line). No logo image (per D4).
- [ ] T003 [US1] Insert centered badge row directly after the hero in [README.md](../../README.md): `<p align="center">` containing 4 mandatory badges (License MIT, Bridge version, Spec Kit verified-0.8.16, Superpowers verified-5.1.0) + optional Marketplace badge per [contracts/readme-structure.md R3](contracts/readme-structure.md#r3--badge-row-content-per-research-d1). All badges use `style=flat-square`, wrapped in `<a href>`, with descriptive `alt` text for graceful degradation.
- [ ] T004 [US1] Insert H1 `# speckit-superpowers-bridge` (if not already present) then the language-toggle blockquote `> 中文版：[README.zh-CN.md](README.zh-CN.md)` immediately after, per [contracts/readme-structure.md R1#3-#4](contracts/readme-structure.md#r1--top-to-bottom-skeleton-must-be-in-this-order).
- [ ] T005 [US1] Insert bold value-prop sentence + 1–3 short paragraphs explaining division of labor (Spec Kit owns design / Superpowers owns execution / bridge orchestrates handoff) in [README.md](../../README.md) immediately after the language toggle, per [contracts/readme-structure.md R1#5-#6](contracts/readme-structure.md#r1--top-to-bottom-skeleton-must-be-in-this-order).
- [ ] T006 [US1] Add `## Why speckit-superpowers-bridge` section in [README.md](../../README.md) explaining the gap the bridge fills (3 short paragraphs max). Then add `## Quick Start` section BEFORE the existing `## Installation` block — a copy-paste-ready fenced bash one-liner for `specify extension add` + a numbered list of what that command does + exactly one `> [!TIP]` callout cross-referring to `superpowers:brainstorming` for vague-scope ideas, per [research D7](research.md#d7--tip--note--warning-placement).
- [ ] T007 [US1] Insert `## Positioning` section in [README.md](../../README.md) immediately after Quick Start: 4-column × 4-row Markdown table per [research D2](research.md#d2--positioning--comparison-table-column--row-choices) (rows: `Just speckit.implement` / `Just Superpowers` / `rpamis/comet` / `speckit-superpowers-bridge`; columns: Owns design / Owns implementation / Cross-agent / Bridge-style overhead). Factual cell content only.
- [ ] T008 [US1] Wrap existing factual sections in [README.md](../../README.md) (`## Installation`, `## Prerequisites`, `## Your First Feature in 10 Minutes`, `## When to Skip Spec Kit`, `## Commands`, `## Configuration`, `## Troubleshooting`, `## Maintenance and Versioning`, `## Architecture in 60 Seconds`) inside `<details><summary>…</summary>…</details>` blocks per [research D3](research.md#d3--which-existing-readme-sections-collapse-to-details-vs-stay-open). Preserve all factual content verbatim (FR-014) — collapse only. Inside the collapsed Maintenance section, add the `> [!NOTE]` about the post-v0.6.0 `download_url` decoupling; inside collapsed Troubleshooting, add the `> [!WARNING]` about not setting a global git proxy on WSL (cross-ref CLAUDE.md), per [research D7](research.md#d7--tip--note--warning-placement).
- [ ] T009 [US1] Keep `## Contributing and License` section open at the bottom of [README.md](../../README.md) per [contracts/readme-structure.md R1#11](contracts/readme-structure.md#r1--top-to-bottom-skeleton-must-be-in-this-order). No structural change beyond ensuring it lives at the bottom; existing content preserved.

**Checkpoint US1**: [README.md](../../README.md) polished and renders correctly on GitHub; first-viewport check satisfies SC-001 (verify by previewing on GitHub or via `glow`/`mdcat`).

---

## Phase 4: User Story 2 — Bilingual mirror stays trustworthy (Priority: P2)

**Goal**: Mirror every US1 structural element in [README.zh-CN.md](../../README.zh-CN.md) with translated prose but identical structure (same hero, same badge row, same section count/order, same comparison-table row count, same `<details>` count), per [FR-003](spec.md) + [contracts/readme-structure.md R4](contracts/readme-structure.md#r4--bilingual-parity-invariants-per-fr-003--sc-003).

**Independent Test**: `diff <(grep -c '^## ' README.md) <(grep -c '^## ' README.zh-CN.md)` reports 0 differences; `diff <(grep -c '<details>' README.md) <(grep -c '<details>' README.zh-CN.md)` reports 0 differences. A Chinese-only reader can find every piece of information without leaving `README.zh-CN.md`. SC-003 met.

> NOTE: All US2 tasks edit the same file (`README.zh-CN.md`) sequentially. US2 CAN parallelize with US3 since they touch different files.

- [ ] T010 [P] [US2] Mirror the hero block + badge row in [README.zh-CN.md](../../README.zh-CN.md) — same `<p align="center">` HTML structure, same `<a href>` + `<img>` badge sequence with identical shields.io URLs; Chinese tagline `「极薄」桥接：Spec Kit 负责「设计」，Superpowers 负责「实现」。` per [research D5](research.md#d5--tagline-the-80-char-hero-block-second-line). Language-toggle blockquote inverted: `> English: [README.md](README.md)`.
- [ ] T011 [P] [US2] Translate the bold value-prop sentence + division-of-labor paragraphs + `## Why` section + `## Quick Start` (commands stay English; prose translated) in [README.zh-CN.md](../../README.zh-CN.md). Keep `> [!TIP]` alerts but localize their body text. Per `## CLAUDE.md` "preserve literal code, commands, filenames, JSON/YAML keys" rule.
- [ ] T012 [P] [US2] Mirror the `## Positioning` table in [README.zh-CN.md](../../README.zh-CN.md) — same 4×4 shape, translated headers + cell prose; technical identifiers (e.g., `speckit.implement`) stay English. Mirror the `<details>`-wrapped factual sections with translated headings + translated prose; commands/paths/code blocks stay English. Preserve `> [!NOTE]` and `> [!WARNING]` placements.

**Checkpoint US2**: [README.zh-CN.md](../../README.zh-CN.md) has structural parity with `README.md` (verify via the diff commands in Independent Test above).

---

## Phase 5: User Story 3 — Maintainer ships v0.6.0 cleanly (Priority: P3)

**Goal**: Refresh all release-time metadata (version strings, verified-versions snapshot, CHANGELOG, marketplace catalog with decoupled URL) and document the runbook retirement of the per-release `download_url` edit, so the v0.6.0 release follows the existing runbook with zero ad-hoc fixes.

**Independent Test**: `extension.yml.extension.version`, `marketplace/catalog-entry.json.version`, and the topmost concrete CHANGELOG header all show `0.6.0`. `verified-versions.json` exists, parses, and contains exactly the 5 required fields. `marketplace/catalog-entry.json.download_url` is the `releases/latest/download/speckit-superpowers-bridge.zip` stable-alias. The release runbook no longer instructs editing `download_url` per release. SC-004 + SC-006 met.

- [ ] T013 [P] [US3] Bump [.specify/extensions/speckit-superpowers-bridge/extension.yml](../../.specify/extensions/speckit-superpowers-bridge/extension.yml) `extension.version`: `"0.5.0"` → `"0.6.0"`. Leave `requires.speckit_version: ">=0.8.10"` unchanged (per FR-006 + Clarifications §Session 2026-05-17).
- [ ] T014 [P] [US3] Create [.specify/extensions/speckit-superpowers-bridge/verified-versions.json](../../.specify/extensions/speckit-superpowers-bridge/verified-versions.json) with the 5 required fields per [contracts/verified-versions.schema.json](contracts/verified-versions.schema.json): `verified_at` (current ISO-8601 UTC), `spec_kit_version: "0.8.16"`, `superpowers_version: "5.1.0"`, `bridge_version: "0.6.0"`, `notes` carrying the Superpowers v5.1.0 + worktree-cleanup + Spec Kit v0.8.16-transparent caveats. Total file ≤ 30 lines.
- [ ] T015 [P] [US3] Update [marketplace/catalog-entry.json](../../marketplace/catalog-entry.json) per [contracts/catalog-entry-shape.md](contracts/catalog-entry-shape.md): `.version` `"0.5.0"` → `"0.6.0"`; `.download_url` switched to `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip` (one-shot decoupling). All other fields untouched.
- [ ] T016 [US3] Update [CHANGELOG.md](../../CHANGELOG.md) per [data-model.md Entity 5](data-model.md): move current `[Unreleased]` content into a new `[0.6.0] - YYYY-MM-DD` section with sub-sections `### Added` / `### Changed` / `### Compatibility` / `### Upstream notes (informational)` (per Entity 5 table); add fresh empty `[Unreleased]` skeleton at the top; update the link references at the bottom of the file.
- [ ] T017 [US3] Update [docs/release-runbook.md](../../docs/release-runbook.md) per [research D9](research.md#d9--release-runbook-retirement-of-the-catalog-download_url-edit-step): (a) remove or replace any step instructing per-release edit of `marketplace/catalog-entry.json.download_url` with a permanent note stating it is stable-aliased as of v0.6.0; (b) ensure a step exists that refreshes `verified-versions.json` immediately after the version bump; (c) add a `Verify:` line confirming the dual ZIP upload (both versioned and stable-aliased asset) and a post-publish `curl -fsLI` check that the stable-alias URL resolves 200.
- [ ] T018 [P] [US3] OPTIONAL: add a one-line cross-reference in [AGENTS.md](../../AGENTS.md) (under the existing marketplace catalog policy / publishing section) noting the v0.6.0 `download_url` decoupling. Single line; do NOT restate the full policy. Skip if it would create AGENTS.md churn for v0.6.0.

**Checkpoint US3**: all version-bearing files agree on `0.6.0`; `verified-versions.json` parses; `catalog-entry.json.download_url` is stable-alias; runbook step retired.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Wrap-up smoke verification, release publish, sandbox gate, and cosmetic SKILL.md refresh.

- [ ] T019 Run the existing smoke suite on WSL bash: `bash tests/run-all.sh`. Total test-file delta MUST be ≤ 5 lines (per SC-009) for any version-string updates that fall out of the version bumps in T013/T015/T016. If a test asserts the catalog version equals the bridge version, update its expectation string and re-run.
- [ ] T020 Add a minimal README structural smoke check per [contracts/readme-structure.md R6](contracts/readme-structure.md#r6--acceptance-test-smoke-suite-compatible): amend an existing `tests/test-*.sh` (or create one ≤ 30 lines if no suitable host) to assert (1) `README.md` contains the centered hero `<p align="center">` block, (2) `README.md` contains a `<p align="center">` with ≥ 4 `<img>` shields.io tags, (3) `## Quick Start` heading appears before `## Installation` in `README.md`, (4) `README.md` and `README.zh-CN.md` have equal `^## ` count, (5) equal `<details>` count. Total test-file delta across the suite must STILL be ≤ 5 lines net (so if you're amending an existing test, keep the additions minimal; if creating a new tiny test file, the suite's net new lines count toward the budget).
- [ ] T021 [P] OPTIONAL cosmetic refresh: bump the `(v0.5.0+)` and `From v0.5.0 onward` mentions inside [.claude/skills/speckit-superpowers-bridge/SKILL.md](../../.claude/skills/speckit-superpowers-bridge/SKILL.md) and [.agents/skills/speckit-superpowers-bridge/SKILL.md](../../.agents/skills/speckit-superpowers-bridge/SKILL.md) to `(v0.6.0+)` and `From v0.6.0 onward`. **Zero behavioral-instruction edits** (per SC-010 + FR-011). If the SKILL.md text does not reference a version, skip this task.
- [ ] T022 Build the v0.6.0 release ZIP per [quickstart.md Step 8](quickstart.md) — produce both `dist/speckit-superpowers-bridge-v0.6.0.zip` (versioned) and refresh `dist/speckit-superpowers-bridge.zip` (stable-alias, identical byte content). Verify both files exist and have matching SHA256.
- [ ] T023 Commit on `011-v060-comet-polish` and open the PR per [quickstart.md Step 9](quickstart.md) — title `v0.6.0 — Comet-style README polish + upstream alignment`; body cites Constitution VI gate Q1+Q2 answers, SC-010 lightness budget verification, and the test plan checklist. Verify PR opens cleanly via `gh pr create`.
- [ ] T024 After PR merge to `main`: tag `v0.6.0`, publish GitHub release with both ZIPs attached, post-publish `curl -fsLI https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip` returns 200 (after redirect chain). Per [quickstart.md Step 10](quickstart.md).
- [ ] T025 Execute End-User Verification Sandbox per constitution §"End-User Verification Sandbox" and [quickstart.md Step 11](quickstart.md): in `..\test_specify_superpower`, `specify init . --integration claude --script sh --here --force`; `specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`; drive one complete bridge cycle (specify → plan → tasks → handoff → execute → complete) on WSL bash. Record outcome in `specs/011-v060-comet-polish/verification.md`: bridge SHA256, platform = WSL bash, pass/fail per US1 + US2 + US3 acceptance scenarios. Per FR-015 + SC-007.
- [ ] T026 Transition the bridge handoff to `complete` for feature 011 per [quickstart.md Step 12](quickstart.md): `bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status complete --actor claude`. Verify bridge-state output reports `Pending tasks: 0` (= all of T001..T026 ticked here).

---

## Dependencies & Story Ordering

```text
T001 (Setup)
   │
   ├─→ US1: T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009
   │           (all sequential — same file: README.md)
   │
   ├─→ US2: T010 → T011 → T012      [P with US1, US3]
   │           (all sequential — same file: README.zh-CN.md)
   │
   └─→ US3: T013 ┬ T014 ┬ T015 → T016 → T017 → T018      [P with US1, US2]
                │       │
                └ all P ┘ (different files)
                 (T016/T017 follow T015 because they cite the new download_url + version)

Polish: T019 ──→ T020      [P-with-each-other]
        T021 [P]            (optional, independent)
        T022 → T023 → T024 → T025 → T026
        (release tag/publish/sandbox are sequential per quickstart Steps 8-12)
```

### Parallel execution windows

- **Cross-story parallelism**: US1, US2, and US3 can all progress simultaneously since they edit different files. A single developer typically batches US1+US2 (the README polish) together and runs US3 (metadata bumps) in parallel.
- **Within-US3 parallelism**: T013, T014, T015, T018 are all `[P]` (different files); T016 depends on T015 (CHANGELOG cites the new catalog version), T017 depends on T015 (runbook mentions decoupled URL).
- **Polish phase**: T019, T020 can run in parallel; T021 [P] is optional and parallel with everything; T022 → T023 → T024 → T025 → T026 must be sequential (build → commit → release → sandbox → handoff).

---

## Independent Test Criteria Per Story

| Story | Independent Test |
|-------|------------------|
| US1 (P1) — MVP | Cold reader at the first viewport of polished `README.md` can name (a) problem solved, (b) two upstreams connected, (c) supported agents, (d) install one-liner — within 30 seconds. SC-001 met. |
| US2 (P2) | `grep -c '^## '` returns equal counts for `README.md` and `README.zh-CN.md`; `grep -c '<details>'` returns equal counts; a Chinese-only reader finds every command/install/troubleshooting answer without leaving `README.zh-CN.md`. SC-003 met. |
| US3 (P3) | All version-bearing files agree on `0.6.0`; `verified-versions.json` parses with all 5 fields; catalog `download_url` is stable-alias; runbook no longer instructs per-release URL edit. SC-004 + SC-006 met. |

---

## Implementation Strategy

**MVP (US1 alone, ~9 tasks)**: ship the polished English README and call it a v0.6.0-pre prerelease. Skip US2 (Chinese mirror would still mirror old structure). Skip US3 (catalog stays on v0.5.0 URL). This delivers SC-001 on its own and is shippable as a doc-only PR — but the user explicitly asked for v0.6.0 publish, so MVP-only is the wrong scope.

**Recommended scope for v0.6.0**: ALL of US1 + US2 + US3 + Polish. Plan-phase research locked every decision; tasks are mechanical; estimated wall-clock ≈ 30–60 min for a single maintainer on WSL bash (per quickstart.md). The catalog `download_url` decoupling alone (T015 + T017) saves churn on every future release — high leverage relative to its 2-line diff.

**Constitution VI invariants** (re-stated for execution discipline):

- Zero new lines added under `.specify/extensions/speckit-superpowers-bridge/scripts/`.
- Exactly one new file added under `.specify/extensions/speckit-superpowers-bridge/` — `verified-versions.json` — and it MUST be ≤ 30 lines.
- Zero new entries in `.specify/extensions.yml.hooks`.
- Zero new commands under `.specify/extensions/speckit-superpowers-bridge/commands/`.
- Zero behavioral-instruction edits to the project-owned bridge `SKILL.md` peers (cosmetic version-line refresh is the only allowed delta).
- Vendor-managed `.{claude,agents}/skills/speckit-*` skills untouched.
- 5 hardcoded guard rules byte-identical to v0.5.0.

If any task feels like it requires violating one of these invariants, **stop, mark the handoff `blocked`, and return to Spec Kit for spec/plan repair** — do not improvise.
