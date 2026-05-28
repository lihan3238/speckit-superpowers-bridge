# Feature Specification: v0.6.0 — Comet-Style README Polish + Upstream Alignment

**Feature Branch**: `011-v060-comet-polish`

**Created**: 2026-05-17

**Status**: Draft

**Input**: User description: "参考 https://github.com/rpamis/comet 的设计思路与 README 美化效果，对 speckit-superpowers-bridge 做一次轻量更新并发布到 v0.6.0：(1) README/README.zh-CN 视觉与结构升级（badges、目录、对比表、快速开始、安装/升级指引等，按 rpamis/comet 的清晰、视觉友好风格），(2) 针对上游最新 Superpowers 与 Spec Kit 版本做一次小幅兼容性对齐（verified-versions.json 刷新；如有简单的破坏性改动则在 CHANGELOG 中记录并最小化适配），(3) 版本号统一升到 v0.6.0、CHANGELOG 同步、marketplace catalog-entry.json 同步、dist 重新打包。严格遵守宪法 Principle VI（Native-First）—— 仅做最薄兼容与文档美化，不新增 daemon/服务/新机制，不修改 vendor 管理的 .{claude,agents}/skills/speckit-* 文件，不增删 guard 规则。"

---

## Context (research-derived; not a contract)

**Reference repo** — [rpamis/comet](https://github.com/rpamis/comet) is a peer
project ("OpenSpec + Superpowers dual-star development workflow") that bundles
the same two upstreams we bridge, in a different shape (OpenSpec instead of
Spec Kit). Its README is the inspirational reference for this feature's
visual polish: bilingual (`README.md` + `README-zh.md`), multi-platform
positioning, hero-led layout, structured value-prop above installation.
We borrow the *visual conventions*, NOT the assets, text, or branding.

**Upstream Superpowers latest = v5.1.0** ([release page](https://github.com/obra/superpowers/releases/tag/v5.1.0)).
Changes that touch the bridge surface:

- Removed slash commands `/brainstorm`, `/execute-plan`, `/write-plan`
  (deprecated stubs). Bridge already invokes by skill name
  (`superpowers:brainstorming`, `superpowers:executing-plans`,
  `superpowers:writing-plans`) — **verified clean in bridge surface by
  grep, no remediation needed**.
- Removed `superpowers:code-reviewer` named agent; persona+checklist
  merged into `skills/requesting-code-review/code-reviewer.md`. Bridge
  invokes `superpowers:requesting-code-review` (the skill) — **verified
  clean in bridge surface by grep, no remediation needed**.
- `finishing-a-development-branch` now only cleans worktrees inside
  `.worktrees/` (provenance-based cleanup). Behavior change inside the
  upstream skill; transparent to the bridge but worth a CHANGELOG note.
- Skills repo separated from plugin (`obra/superpowers-skills`).
  Transparent to bridge consumers; mentioning in `verified-versions.json`
  notes is sufficient.

**Upstream Spec Kit latest = v0.8.16** (maintainer-confirmed local
install per Clarifications §Session 2026-05-17). We're currently pinned
at `>=0.8.10` per `extension.yml.requires.speckit_version` and the dev
environment was at `0.8.11` per `.specify/init-options.json` before the
maintainer's local bump to 0.8.16. Changes since v0.8.11 appear
transparent to bridge consumers (smart JSON merging for
`.vscode/settings.json`, multi-install support per PR #2389, build/CI
fixes, and the incremental 0.8.12 → 0.8.16 patch series). No bridge
script change required.

**Current bridge state**:

- Version `0.5.0` per [extension.yml](.specify/extensions/speckit-superpowers-bridge/extension.yml).
- `verified-versions.json` is referenced by [docs/release-runbook.md Step 3](docs/release-runbook.md) **but does not exist in the bridge package today**. v0.6.0 closes this gap by creating the file fresh.
- `dist/` already contains v0.3.0, v0.4.0-rc.1..3, v0.4.0, v0.4.1, v0.4.3, and `speckit-superpowers-bridge.zip` (the stable-alias); v0.5.0 ZIP is missing from the local snapshot too (rebuilt at release time per runbook).
- README is technically accurate but visually plain: all-lowercase section
  titles, no hero block, no badges, no language toggle, no positioning
  table, no centered alignment, no TOC.

This feature is a **release-cycle feature**: it ships a versioned artifact
(`v0.6.0`) and therefore triggers the constitution's End-User Verification
Sandbox gate.

---

## Clarifications

### Session 2026-05-17

- Q: Should the marketplace catalog's `download_url` stay version-pinned
  (e.g. `releases/download/v0.6.0/...-v0.6.0.zip`) or switch to a
  version-decoupled stable-alias (`releases/latest/download/speckit-superpowers-bridge.zip`)?
  → A: **Decouple**. Empirically verified via `gh`-equivalent GitHub
  API call that the v0.5.0 release already uploads BOTH the versioned
  ZIP and the stable-aliased `speckit-superpowers-bridge.zip` (identical
  44 708 bytes). The release runbook is already producing the
  stable-aliased asset on every tag — switching the catalog to
  `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`
  is zero-risk and zero-runbook-change. **Going forward, only the
  `version` field in `catalog-entry.json` needs per-release update;
  `download_url` is one-shot decoupled.** FR-007 updated.
- Q: Which upstream Spec Kit version is the v0.6.0 verified pair —
  0.8.14 (initial web research) or a later version the maintainer
  has locally installed?
  → A: **0.8.16** (maintainer-confirmed). `verified-versions.json`
  (FR-004) and the Assumptions set updated from 0.8.14 → 0.8.16.
  `extension.yml.requires.speckit_version` (FR-006) STAYS at
  `>=0.8.10` (permissive floor) since nothing v0.6.0 ships actually
  requires a newer Spec Kit; bumping the floor would force upgrade
  pressure on existing users for no functional gain.
- Q: Is the spec safe from drifting into "heavyweight framework"
  territory the bridge's brand explicitly rejects ("极度轻量, 兼容上游")?
  → A: Codified as new **SC-010 (lightness budget)**: zero new script
  lines (PowerShell + bash); exactly one new file in the bridge
  extension package (`verified-versions.json`, ≤ 30 lines); zero new
  bridge `SKILL.md` instruction lines beyond version-line refreshes;
  README polish uses **native Markdown + GitHub-flavored Markdown
  alerts (`> [!TIP]`, `> [!NOTE]`)** only — no JavaScript, no CSS,
  no build step, no SVG mirror, no generated artifacts. The bridge's
  brand of "lightweight + compatible with upstream growth" is the
  controlling design constraint, reaffirming constitution Principle VI.
- Q: With WebFetch now reachable, did the spec's abstract visual
  references to rpamis/comet survive a concrete fetch?
  → A: Yes — the actual `rpamis/comet/README.md` was fetched. The
  structural pattern locked into FR-001 (centered hero + badge row +
  language toggle + "Why" before "Install" + Quick-Start + `> [!TIP]`
  alerts + collapsed `<details>` blocks + numbered install-step
  list) matches comet's actual layout while staying budget-light.
  Concrete per-element choices (exact badge list, exact comparison-table
  columns) remain in plan-phase scope to keep this spec from
  prescribing implementation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-time visitor decides in 30 seconds whether to install (Priority: P1)

A developer lands on `github.com/lihan3238/speckit-superpowers-bridge`
(or on the marketplace catalog link). Within the first scroll they see:
a centered hero block (title, one-line tagline, language toggle), a row
of status badges (license, version, Spec Kit verified-version, Superpowers
verified-version, build/test status if available), a brief value-prop
("what is this?" answered in 1–2 sentences), and a clear positioning
section ("how this differs from peer extensions / Comet / vanilla
`speckit.implement`") rendered as a comparison table. They can decide in
**under 30 seconds** whether the bridge fits their need, then jump
straight to a quick-start fenced block.

**Why this priority**: README is the only end-user-discoverable surface
the bridge has (per the 010 clarification — extension install does not
touch consumer's AGENTS.md/CLAUDE.md). A README that buries the value
proposition behind technical detail loses installs to better-packaged
peers like rpamis/comet. This is the *single largest perceived-quality
lever* the bridge can pull without writing new code.

**Independent Test**: A cold reader (no prior bridge exposure) loads
`README.md` in a GitHub-rendered view, scrolls only the visible first
viewport (~600px), and within 30 seconds answers correctly: (a) what
problem this solves, (b) which upstreams it connects, (c) which AI
agents it works with, (d) where to find the install command.

**Acceptance Scenarios**:

1. **Given** the GitHub-rendered `README.md`, **When** a cold reader
   opens it, **Then** the top viewport MUST contain a centered hero
   block (title + one-line tagline), a language-toggle link
   (English ↔ 简体中文), and a badge row with at minimum: license,
   current bridge version, Spec Kit verified-version, Superpowers
   verified-version.
2. **Given** the same README, **When** the reader scrolls one more
   viewport, **Then** they MUST encounter a positioning / comparison
   section (table form) distinguishing the bridge from `speckit.implement`
   alone, from raw Superpowers usage, and from peer hybrid tools
   (e.g., Comet). The comparison MUST be factual, not promotional.
3. **Given** the same README, **When** the reader looks for installation,
   **Then** a quick-start fenced code block MUST appear before the
   detailed installation matrix, with a copy-paste-ready one-liner
   for the most common case (`specify extension add` from marketplace).
4. **Given** the README's pre-polish content (workflow, prerequisites,
   commands, configuration, troubleshooting, architecture sections),
   **When** the polish lands, **Then** all factual technical content
   MUST be preserved — additive / reorganization only, no removal of
   working commands or accuracy regressions.

---

### User Story 2 - Bilingual mirror stays trustworthy after polish (Priority: P2)

A Chinese-speaking user lands on `README.zh-CN.md` (linked from the
English README's language toggle, or via search). They get the same
hero, the same badge row, the same section ordering, the same level
of technical detail. They never have to switch to English to find a
piece of information that the English README documents.

**Why this priority**: Half this project's likely user base reads
Chinese natively (the maintainer is bilingual; CLAUDE.md routes user-
facing language per detection). A polished English README paired with
a stale or skeletal Chinese mirror is a worse outcome than a uniformly
plain bilingual pair. Lower than US1 because US1 captures most users
on first contact.

**Independent Test**: A diff (semantic, not byte) between
`README.md` and `README.zh-CN.md` shows: identical section headings
in count and order; identical badge row contents (badges in same order,
just label text translated); identical comparison-table rows; identical
quick-start code blocks (Chinese readers don't lose copy-paste fidelity).

**Acceptance Scenarios**:

1. **Given** the post-polish `README.md` and `README.zh-CN.md`, **When**
   a reviewer compares section-heading counts and order, **Then** the
   two files MUST have the same number of H2 sections in the same order
   (heading TEXT translated; structure identical).
2. **Given** the same pair, **When** a reviewer compares the badge row,
   **Then** both files MUST display the same badges in the same order
   (badge label/link can be localized; the underlying URL and ordering
   are identical).
3. **Given** a Chinese-only reader, **When** they follow the README from
   top to bottom, **Then** every command, file path, code snippet, and
   technical identifier MUST remain in its canonical English form (e.g.,
   `specify extension add speckit-superpowers-bridge`, paths under
   `.specify/...`). Only prose is translated.

---

### User Story 3 - Maintainer ships v0.6.0 cleanly via the existing runbook (Priority: P3)

The maintainer follows [docs/release-runbook.md](docs/release-runbook.md)
to publish v0.6.0. Every step succeeds without ad-hoc fixes:
version bump in `extension.yml`, CHANGELOG entry, `verified-versions.json`
created/refreshed with the v5.1.0 + v0.8.16 upstreams, submission
checklist clean, test suite green on WSL bash (per 009's bash-only
smoke surface), parity/validation/cleanup audits clean,
`marketplace/catalog-entry.json` bumped to v0.6.0 with `download_url`
decoupled to the stable-alias URL (one-shot, per Clarifications §Session
2026-05-17), fresh `dist/speckit-superpowers-bridge-v0.6.0.zip` built,
sandbox verification passes.

**Why this priority**: Releases are mechanical when the spec already
constrains them. This story exists to capture the *release-time* invariants
this feature needs to satisfy (CHANGELOG sync, catalog sync, dist rebuild),
not to invent a new release mechanism.

**Independent Test**: Running the release runbook end-to-end on a clean
workspace produces a `dist/speckit-superpowers-bridge-v0.6.0.zip`
whose `extension.yml` declares `version: "0.6.0"`, whose
`verified-versions.json` carries today's `verified_at` and
`{spec_kit_version: "0.8.16", superpowers_version: "5.1.0"}`, whose
`marketplace/catalog-entry.json.download_url` points at
`releases/latest/download/speckit-superpowers-bridge.zip` (no version
suffix), and which installs cleanly in the sandbox per the
constitution's End-User Verification Sandbox sequence.

**Acceptance Scenarios**:

1. **Given** the runbook is followed top-to-bottom, **When** each
   `Verify:` line is executed, **Then** every verify MUST pass without
   ad-hoc fix-ups (the runbook itself does not require edits as part
   of this feature; if it does, that becomes its own scope item).
2. **Given** v0.6.0 has been installed in the sandbox, **When** the
   user invokes one full bridge cycle (specify → clarify-opt → plan →
   tasks → handoff → execute → complete), **Then** the cycle MUST
   complete without any guard rule firing unexpectedly and without
   any bridge script erroring out.
3. **Given** the v0.6.0 ZIP is published, **When** a user installs via
   `specify extension add speckit-superpowers-bridge --from <URL>`,
   **Then** the resulting `.specify/extensions/speckit-superpowers-bridge/`
   tree MUST include a `verified-versions.json` file (it does not
   today).

---

### Edge Cases

- **Badge service downtime**: if shields.io is unreachable when a user
  loads the README, the row MUST degrade to plain text alt-text inside
  the rendered image tags — no broken-image icons that imply the
  project itself is broken. We pick a badge service that returns alt
  text and rely on GitHub's image-failure rendering rather than
  inventing our own fallback.
- **Bilingual drift over time**: when the English README is edited
  post-v0.6.0, the Chinese mirror can fall behind. This feature
  documents the parity rule (same sections, same order) in
  `CONTRIBUTING.md` if one exists, or in a short maintainer note in
  the README itself. Mechanical drift detection is out of scope.
- **Upstream Superpowers ships v5.2.0 mid-release**: the bridge ships
  the verified-versions snapshot as of release time; users running
  against a newer Superpowers do so at their own risk and we encourage
  them to file an issue if the bridge breaks against a newer upstream.
- **rpamis/comet relicenses or removes README**: our spec references
  Comet as a visual *inspiration* (no assets borrowed); upstream
  changes there do not affect the bridge.
- **A consumer with `verified-versions.json` already present** (from a
  hand-built install): the v0.6.0 ZIP's file overwrites it, since the
  schema is project-owned and consumers should not edit this file.
  CHANGELOG entry warns about this on the upgrade-from-v0.5.0 path.
- **GitHub README rendering width** (default 980px desktop, ~360px
  mobile): the hero block, badge row, and comparison table MUST
  remain readable on mobile (one badge per row stacking is acceptable;
  comparison-table horizontal scroll is acceptable; centered hero text
  MUST NOT break).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Upgrade [README.md](README.md) to a hero-led layout
  modelled on the rpamis/comet structural pattern (verified by direct
  fetch, see Clarifications §Session 2026-05-17), using **native
  Markdown + GitHub-flavored Markdown alerts only — no JavaScript,
  CSS, SVG mirrors, or build step**. The top-to-bottom skeleton MUST
  include, in this order:
  1. Centered hero block (`<p align="center">`-wrapped) containing
     the project title and a ≤80-char tagline (logo image OPTIONAL;
     the bridge has no logo today and adding one is out of scope).
  2. Centered badge row (`<p align="center">`-wrapped, shields.io
     images, `style=flat-square`) carrying AT MINIMUM: license,
     current bridge version, Spec Kit verified-version, Superpowers
     verified-version. CI / downloads / DeepWiki badges OPTIONAL.
  3. Language-toggle line as a `>` blockquote pointing at the
     Chinese mirror (style: `> 中文版：[README.zh-CN.md](README.zh-CN.md)`).
  4. A bold one-line value-prop sentence followed by 1-3 short
     paragraphs explaining division of labor (Spec Kit owns design /
     Superpowers owns execution / bridge is the thin handoff).
  5. `## Why <bridge>` section explaining the gap the bridge fills.
  6. `## Quick Start` BEFORE the detailed installation matrix,
     containing a copy-paste-ready one-liner for the common case
     (`specify extension add` from marketplace) and a short numbered
     list of what that command does, with at least one `> [!TIP]`
     callout.
  7. The existing factual sections (Installation, Prerequisites,
     First Feature in 10 Minutes, When to Skip Spec Kit, Commands,
     Configuration, Troubleshooting, Maintenance, Architecture,
     Contributing) preserved post-Quick-Start, ideally with verbose
     ones moved into collapsed `<details>` blocks to keep the visible
     surface short.
  8. A positioning / comparison section in table form, distinguishing
     the bridge from `speckit.implement` alone, raw Superpowers usage,
     and at least one peer hybrid (e.g. rpamis/comet itself).
- **FR-002**: Provide a TOC (auto-generated by GitHub from H2 headings
  is acceptable; explicit `<details>`-wrapped TOC block also acceptable)
  so a reader can jump to any section without scrolling the whole
  document.
- **FR-003**: Mirror every FR-001 element in [README.zh-CN.md](README.zh-CN.md):
  same hero block (Chinese tagline), same badge row (badge labels can
  be localized; URLs identical; ordering identical), same section
  count and order (heading text translated), same comparison-table
  row count, same quick-start code block (commands stay English; prose
  translated).
- **FR-004**: Create OR refresh
  [.specify/extensions/speckit-superpowers-bridge/verified-versions.json](.specify/extensions/speckit-superpowers-bridge/verified-versions.json)
  carrying AT MINIMUM: `verified_at` (current ISO 8601 UTC timestamp),
  `spec_kit_version: "0.8.16"`, `superpowers_version: "5.1.0"`,
  `bridge_version: "0.6.0"`, `notes` (free-text containing any
  upstream caveats relevant to this verified pair, e.g. the v5.1.0
  removed-slash-commands note, the `.worktrees/`-scoped cleanup
  change). Total file size ≤ 30 lines; no schema additions beyond
  these five fields in v0.6.0.
- **FR-005**: Add a [CHANGELOG.md](CHANGELOG.md) `[0.6.0] - YYYY-MM-DD`
  section that (a) moves the current `[Unreleased]` content into it,
  (b) lists this feature's polish + verified-versions work, (c)
  documents the Superpowers v5.1.0 changes that may affect bridge
  users (removed slash commands, removed `code-reviewer` named agent,
  provenance-scoped worktree cleanup) so users coming from
  Superpowers v5.0.x know what changed *upstream*, and (d) adds a
  fresh empty `[Unreleased]` skeleton at the top.
- **FR-006**: Update [extension.yml](.specify/extensions/speckit-superpowers-bridge/extension.yml)
  `extension.version` from `"0.5.0"` to `"0.6.0"`. The
  `requires.speckit_version` constraint **stays at `>=0.8.10`** per
  Clarifications §Session 2026-05-17: bumping the floor would force
  upgrade pressure on existing users for no functional gain, since
  v0.6.0 ships zero behavioral changes that require Spec Kit > 0.8.10.
  The fact that the maintainer dev-environment is at 0.8.16 is captured
  separately in `verified-versions.json.spec_kit_version`.
- **FR-007**: Update [marketplace/catalog-entry.json](marketplace/catalog-entry.json)
  `version` from `"0.5.0"` to `"0.6.0"`. **Switch `download_url` from
  the version-pinned form to the version-decoupled GitHub stable-alias
  URL** — concretely:
  `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`.
  This is empirically safe per Clarifications §Session 2026-05-17:
  the release runbook already uploads BOTH a versioned
  (`speckit-superpowers-bridge-v<X.Y.Z>.zip`) and a stable-aliased
  (`speckit-superpowers-bridge.zip`) asset on every tag, verified on
  the v0.5.0 release. **After v0.6.0 ships, future releases need NO
  edit to `download_url`** — only the `version` field gets bumped
  per release (audit trail) while consumers always pull whatever
  GitHub's `/releases/latest/` alias resolves to. Net effect: one
  permanent fewer source-of-truth file to edit per release.
- **FR-008**: Build a new `dist/speckit-superpowers-bridge-v0.6.0.zip`
  per the existing release runbook (Step 7 / packaging step). The
  stable-alias `dist/speckit-superpowers-bridge.zip` MAY be refreshed
  to point at v0.6.0 contents (existing convention).
- **FR-009**: Bridge script surface
  ([guard-command.sh](.specify/extensions/speckit-superpowers-bridge/scripts/bash/guard-command.sh),
  [update-handoff.sh](.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh),
  [auto-archive-handoff.sh](.specify/extensions/speckit-superpowers-bridge/scripts/bash/auto-archive-handoff.sh),
  [bridge-state.sh](.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh),
  [common-actor-resolution.sh](.specify/extensions/speckit-superpowers-bridge/scripts/bash/common-actor-resolution.sh),
  and the PowerShell peers) MUST remain **byte-identical** at the
  script level. v0.6.0 ships **zero behavior changes** to the bridge
  itself. (Principle VI: thinnest compat layer.)
- **FR-010**: The 5 hardcoded guard rules in `guard-command.{ps1,sh}`
  MUST remain byte-identical. No rule additions, removals, renumbering,
  or condition changes.
- **FR-011**: The vendor-managed skills under
  `.claude/skills/speckit-*/` and `.agents/skills/speckit-*/` (excluding
  `speckit-superpowers-bridge/`) MUST NOT be edited. The project-owned
  bridge skills (`.{claude,agents}/skills/speckit-superpowers-bridge/SKILL.md`)
  MAY receive minor version-line updates (e.g. mentioning v0.6.0
  state-output content) but their behavioral instructions MUST remain
  semantically identical to v0.5.0.
- **FR-012**: No new state file, hook (in `extensions.yml`), script
  under `.specify/extensions/`, guard rule, or bridge command file
  introduced by v0.6.0. (Principle VI native-first gate.)
- **FR-013**: Existing smoke tests under [tests/](tests/) MUST pass
  unchanged on WSL bash (the post-009 dev environment). No test edits
  are required as part of this feature; if a test fails because of
  the version bump, the test gets updated as part of THIS feature
  (since tests verify versioned metadata), but no new test files are
  added.
- **FR-014**: The polish MUST NOT remove any working install command,
  working code snippet, or factual technical claim already present in
  the v0.5.0 README. Reorganization and rewording are allowed;
  accuracy regression is not.
- **FR-015**: End-User Verification Sandbox run (per constitution
  §"End-User Verification Sandbox", v1.2.0+) MUST be performed for
  this release: install the v0.6.0 ZIP fresh into `..\test_specify_superpower`
  via the published release URL, drive one complete bridge cycle on
  at least WSL bash, record outcome (pass/fail per platform, bridge
  SHA256, observed gaps) in
  `specs/011-v060-comet-polish/verification.md`.

### Key Entities

- **README hero block**: a top-of-document HTML fragment containing
  centered title, tagline, and language toggle. Attributes: title text,
  tagline (≤ 80 chars), language toggle URL pair. Lifecycle: written
  once at v0.6.0 polish, edited only when project rename or tagline
  redefinition.
- **Badge row**: an ordered list of shield-style image links rendered
  inline. Attributes: badge label, URL, link target, order. Lifecycle:
  individual badges may be added/removed without re-spec; the ROW
  STRUCTURE is defined here.
- **Positioning table**: a Markdown comparison table with columns
  describing dimensions (e.g., owns design / owns implementation /
  enforces handoff / supports cross-agent) and rows for the bridge,
  peer extensions, and the no-bridge baseline. Attributes: column set,
  row set. Lifecycle: refreshed whenever a peer changes positioning.
- **`verified-versions.json`**: project-owned JSON file at the bridge
  package root recording which exact upstream versions this bridge
  release was verified against. Schema (project-defined, this feature
  formalizes it): `{verified_at: ISO-8601 UTC string, spec_kit_version:
  semver string, superpowers_version: semver string, bridge_version:
  semver string, notes: string}`. Lifecycle: refreshed once per
  bridge release, prior versions overwritten (Git history is the
  audit trail).
- **CHANGELOG `[0.6.0]` section**: a Keep-a-Changelog formatted block
  recording Added / Changed / Removed / Deprecated / Fixed / Security
  buckets as applicable. Lifecycle: created during this feature,
  immutable post-release except for typo PATCH.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A cold reader of the polished `README.md` can answer
  "what problem does the bridge solve?" + "what does it connect?" in
  **under 30 seconds** of scrolling, using only the first viewport
  (~600px on desktop GitHub rendering).
- **SC-002**: Badge-row badges render successfully (live SVG OR
  alt-text rendered by GitHub's image-failure fallback) within
  **5 seconds** of the README being fetched, on a vanilla GitHub
  page load with no extensions/blockers.
- **SC-003**: `README.md` and `README.zh-CN.md` have an **identical
  H2 section count** (same number of `## ` lines), in the **same
  semantic order** (translated heading text is acceptable; ordering
  is not).
- **SC-004**: `extension.yml.extension.version`,
  `marketplace/catalog-entry.json.version`, and `CHANGELOG.md`'s
  topmost concrete release header ALL show `0.6.0` after the feature
  ships. Version-string discrepancy across these three sources is
  a release blocker.
- **SC-005**: The bridge scripts (PowerShell + bash) and the 5
  hardcoded guard rules are **byte-identical** to v0.5.0, verified
  by `git diff --numstat v0.5.0..HEAD -- .specify/extensions/speckit-superpowers-bridge/scripts/` returning `0 lines changed` (zero
  inserts, zero deletes) for `.ps1` + `.sh` files inside `scripts/`.
- **SC-006**: `verified-versions.json` exists at
  `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`,
  parses as valid JSON, and contains all five required fields per
  FR-004's schema. A `jq -e '.verified_at and .spec_kit_version and
  .superpowers_version and .bridge_version and .notes'` check exits 0.
- **SC-007**: End-User Verification Sandbox run on at least WSL bash
  passes for v0.6.0 (one full bridge cycle: specify → plan → tasks →
  handoff → execute → complete), with the outcome recorded in
  `specs/011-v060-comet-polish/verification.md` before the v0.6.0
  release tag is published.
- **SC-008**: **Zero new lines of script code** added under
  `.specify/extensions/speckit-superpowers-bridge/scripts/` or under
  `.{claude,agents}/skills/speckit-superpowers-bridge/SKILL.md`'s
  behavioral instruction sections. The diff is documentation,
  metadata, and verification artifacts only. (Principle VI invariant.)
- **SC-009**: All existing smoke tests under `tests/` pass on WSL
  bash without test-file edits OTHER than expected version-string
  updates (e.g., a test that asserts the catalog version equals
  bridge version). The total test-file delta is **≤ 5 lines** across
  the suite.
- **SC-010 (Lightness budget, codified per Clarifications §Session
  2026-05-17)**: The complete v0.6.0 diff MUST satisfy ALL of:
  - **Zero** new lines in any `.sh` or `.ps1` file under
    `.specify/extensions/speckit-superpowers-bridge/scripts/`.
  - **Exactly one** new file in the bridge extension package:
    `verified-versions.json` (≤ 30 lines).
  - **Zero** new behavioral-instruction lines in
    `.{claude,agents}/skills/speckit-superpowers-bridge/SKILL.md`.
    Version-line refreshes (e.g. "v0.5.0" → "v0.6.0" mentions) are
    allowed but flagged in PR review as cosmetic.
  - README polish uses **native Markdown + GitHub-flavored alerts
    only**: no JavaScript, no CSS, no SVG mirrors, no build step, no
    generated artifacts. Use of `<p align="center">`, `<picture>`,
    `<details>`, and `> [!TIP]` is permitted because GitHub renders
    them natively without external infrastructure.
  - **Zero** new entries in `.specify/extensions.yml` `hooks:`
    sections beyond what already exists in v0.5.0.
  - **Zero** new commands shipped under
    `.specify/extensions/speckit-superpowers-bridge/commands/`.

---

## Assumptions

- **rpamis/comet is a visual reference only.** No images, logos, badge
  designs, text snippets, or branding are copied. The bridge mirrors
  the structural conventions verified via direct fetch (centered hero,
  shields.io badge row with `style=flat-square`, language-toggle
  blockquote, "Why" → "Install" → "Quick Start" sequence, `> [!TIP]`
  alerts, `<details>` collapsed sections) — these are standard across
  modern OSS README aesthetics and not unique to rpamis/comet. License
  compatibility (rpamis/comet is MIT; the bridge is MIT) is therefore
  non-blocking even at a stricter interpretation.
- **shields.io is the canonical badge service.** If it goes down,
  GitHub's image-failure rendering shows the badge alt text (which
  encodes the label and value), so the README degrades gracefully.
  We do NOT mirror badge SVGs locally; that would be new infrastructure.
- **Bilingual parity is structural, not literal.** Heading TEXT is
  translated; section ORDER and COUNT are identical; commands, paths,
  code blocks, and technical identifiers stay in English in both
  files. This matches the user's CLAUDE.md "preserve literal code,
  commands, filenames, JSON/YAML keys" rule.
- **`verified-versions.json` schema is project-owned.** This feature
  formalizes the five-field schema; future bridge releases extend the
  schema additively (never remove fields). The release runbook
  already references this file by name; we are closing a long-standing
  schema gap. Total file size budget per SC-010: ≤ 30 lines.
- **The marketplace `download_url` is one-shot decoupled in v0.6.0**
  (per Clarifications §Session 2026-05-17). Future releases (v0.7.0+)
  only need to bump `catalog-entry.json.version` for audit-trail
  purposes; the `download_url` stays
  `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`
  permanently. The release runbook step "update marketplace
  download_url to <new versioned URL>" becomes a no-op after v0.6.0
  ships.
- **Upstream Superpowers v5.1.0 changes do NOT require bridge-script
  remediation.** Grep verified the bridge's invocation surface uses
  skill names (not removed slash commands) and `requesting-code-review`
  (not the removed `code-reviewer` named agent). Documentation
  CHANGELOG note is sufficient.
- **Upstream Spec Kit v0.8.16 is the verified pair for v0.6.0** (per
  Clarifications §Session 2026-05-17 — maintainer locally confirmed).
  `extension.yml.requires.speckit_version` stays permissive at
  `>=0.8.10` per FR-006 rationale (no v0.6.0 feature requires a
  newer Spec Kit; bumping the floor would create needless upgrade
  pressure).
- **The v0.6.0 release follows the existing
  `docs/release-runbook.md` step sequence**. If a runbook step is
  found to be wrong during this release, the fix lands as part of
  this feature; if a fundamentally new step is needed, that becomes
  a separate spec. The `download_url`-decoupling means the runbook
  step that edits `catalog-entry.json.download_url` retires after
  v0.6.0 — that retirement IS a runbook edit in scope for this
  feature.
- **Sandbox verification stays on WSL bash** (per 009's bash-only
  smoke surface). A future feature MAY re-add PowerShell sandbox
  coverage; v0.6.0 ships against the post-009 reality.
- **No `/speckit-plan` shadowing.** The polish + version-bump work
  is large enough to warrant a normal `/speckit-plan` + `/speckit-tasks`
  cycle (unlike feature 010 which was doc-only); we follow the standard
  Spec Kit lifecycle from here onward. Plan-phase MUST use WebFetch
  (now reachable per maintainer's enablement on 2026-05-17) to lock
  the exact badge list, comparison-table columns, and `<details>`-blocking
  decisions before tasks generation.
