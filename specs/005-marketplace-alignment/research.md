# Phase 0 Research: Marketplace Alignment

**Feature**: 005-marketplace-alignment
**Date**: 2026-05-15
**Status**: All plan-time unknowns resolved.

Source-of-truth references:
- [Spec Kit EXTENSION-PUBLISHING-GUIDE.md](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md)
- [Spec Kit EXTENSION-DEVELOPMENT-GUIDE.md](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-DEVELOPMENT-GUIDE.md)
- [extensions/catalog.community.json](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json)
- [extensions/README.md](https://github.com/github/spec-kit/blob/main/extensions/README.md)
- [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md)
- [Extensify scaffolding/validation](https://speckit-community.github.io/extensions/extensify)
- Primary design reference: [dev.to article (truongpx396)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)

---

## R1 — Release runbook order

**Decision**: The runbook lives in `docs/release-runbook.md` at repo root (a one-shot reference doc), with these ordered steps:

1. Update `extension.yml.version` (semver bump).
2. Update `CHANGELOG.md` (move `[Unreleased]` content into the new version section; add new `[Unreleased]` skeleton).
3. Update `verified-versions.json.verified_at` to today's ISO timestamp.
4. Run `submission-checklist.ps1` — must exit 0.
5. Run the full test suite (`test-bridge-guard.ps1` + every `tests/test-*.ps1`) — all green.
6. Run `parity-check.ps1` and `validation-pass.ps1` — both exit 0.
7. Commit + tag (`v0.x.y`).
8. Push tag → GitHub builds the release ZIP at `<repo>/releases/download/v0.x.y/speckit-superpowers-bridge-v0.x.y.zip`.
9. Edit `marketplace/catalog-entry.json` if `version` or `download_url` changed.
10. Fork `github/spec-kit`, paste catalog entry + extensions/README.md row into a feature branch, paste `marketplace/upstream-pr-body.md` into the PR description.
11. Submit upstream PR; respond to maintainer feedback.

**Rationale**: Runbook is a checklist, not code. Markdown is appropriate. Locating it at repo root (`docs/release-runbook.md`) makes it discoverable for contributors and excludable from distribution (the runbook is for maintainers, not host projects).

**Alternatives considered**:
- *Script-driven release (a `release.ps1` orchestrator)*: tempting but over-engineered for a Windows-only one-person workflow at this scale; rejected. May revisit when CG-005 lands.
- *Place runbook inside `marketplace/`*: rejected because the runbook covers more than the upstream PR (versioning, tagging, test runs).

---

## R2 — `submission-checklist.ps1` check set

**Decision**: 8 ordered checks, exit 0 only when all pass:

| # | Check | Severity if fail | Source |
|---|---|---|---|
| 1 | `LICENSE` present at repo root, non-empty | P0 | required-file gate |
| 2 | `CHANGELOG.md` present at repo root with at least one released-version section | P0 | recommended-but-effectively-required for trust |
| 3 | `extension.yml` parses + every required field present (id, name, version, description, author, repository, license, requires.speckit_version) | P0 | Spec Kit manifest schema |
| 4 | `extension.yml.tags` equals exactly the locked 6-tag set | P1 | clarify Q3 |
| 5 | `extension.yml.description` is ≤200 chars | P1 | catalog entry schema |
| 6 | `marketplace/catalog-entry.json` exists, parses, conforms to `contracts/catalog-entry.schema.json` | P0 | marketplace listing requirement |
| 7 | `marketplace/catalog-entry.json.download_url` resolves with HTTP 200 (HEAD or short GET) | P0 | upstream URL accessibility check mirrored |
| 8 | `marketplace/upstream-pr-body.md` contains the AI-disclosure paragraph (regex match) | P1 | CONTRIBUTING.md requirement |

**Output schema** mirrors `parity-check.ps1`'s ParityCheckReport (with `findings[]`, `summary.by_severity`, `exit_code`).

**Rationale**: 8 is small enough to keep the script under 150 lines; covers everything the upstream maintainer would catch automatically; HTTP 200 check uses .NET's `[System.Net.Http.HttpClient]` (Windows-native, no new deps).

**Alternatives considered**:
- *Run actual JSON Schema validation via a NuGet/PowerShell-Gallery package*: rejected — new dependency. Implement field-presence checks manually (~30 lines) instead.
- *Skip HTTP accessibility check*: rejected — that's exactly what the upstream maintainer's first round-trip rejection would be; cheaper to catch locally.

---

## R3 — `cleanup-audit.ps1` check set

**Decision**: 5 ordered checks:

| # | Check | Severity if fail |
|---|---|---|
| 1 | No `*.bak`, `*.bak-*`, `*.orig`, `*.tmp` files anywhere in the repo (excluding `.git/`) | P2 |
| 2 | Every file under `.specify/extensions/speckit-superpowers-bridge/docs/` referenced from `README.md` or `extension.yml` | P2 |
| 3 | No abandoned one-shot scripts at repo root (`bump-*.ps1`, `migrate-*.ps1` etc.) | P2 |
| 4 | `.gitignore` covers all 5 categories: per-developer state, OS junk, backup patterns, editor scratch, build artifacts | P1 |
| 5 | `plugin-distribution-manifest.yml.includes[]` paths all exist on disk; `excludes[]` paths NOT in `includes[]` | P0 |

Each finding includes a `suggested_fix` field naming the file path and the proposed action (delete / move-to-archive / add-to-gitignore / document-with-rationale).

**Rationale**: Cleanup is a quality concern, not a correctness gate — most findings are P2. P0 is reserved for the one thing that breaks installs (manifest path inconsistency).

**Alternatives considered**:
- *Run cleanup as part of `submission-checklist.ps1`*: rejected — different concern (source repo dev state vs published artifact correctness). Separate scripts keep each focused.

---

## R4 — README structure (mapping to FR-009/FR-010)

**Decision**: 11 sections in this order:

```text
[bilingual toggle line]
[badges row]
# speckit-superpowers-bridge

## What it does (one paragraph + link to dev.to article)
## Workflow diagram (ASCII chart)
## Installation
  ### Pure Codex
  ### Pure Claude Code
  ### Both (cross-agent)
## Your first feature in 10 minutes (walkthrough)
## Commands reference (table)
## Configuration (env vars + handoff fields)
## Troubleshooting (matrix)
## Maintenance & Versioning
## Architecture in 60 seconds
## Contributing & License
```

H2 anchors stay English in both files (`## installation`, `## troubleshooting`, etc.) for cross-link stability. zh-CN body translates the prose but keeps the same H2 structure; `check-readme-bilingual-parity.ps1` enforces this.

**Rationale**: Order optimizes for a first-time reader: what → how (visual) → install → try-it → reference. Trust signals (badges) are at the top because GitHub renders them prominently. Architecture-in-60-seconds is late because it's for evaluation, not first-use.

**Alternatives considered**:
- *Lead with Architecture*: rejected — adoption depends on "I can try this in 10 minutes," not "I understand the theory."
- *Hide install details behind a tabbed UI*: github.com markdown doesn't support tabs reliably; rejected.

---

## R5 — Should `marketplace/` ship in distributions?

**Decision**: **No.** Add `marketplace/**` to `plugin-distribution-manifest.yml.excludes` with `reason: "Upstream PR artifacts are source-repo-only; not relevant to host projects."`. Host projects installing the bridge get the runtime files, not our submission paperwork.

**Rationale**: `marketplace/catalog-entry.json` describes US, not the host. Shipping it would bloat the install and confuse host-side automation.

**Alternatives considered**:
- *Ship as documentation*: rejected — wrong audience.
- *Ship a redacted "this is how we listed ourselves" guide*: nice-to-have for users who want to publish their own derivative; out of scope for v0.2.

---

## R6 — `provides.commands` and `provides.hooks` counts

**Decision**: Inspect the live state and record:
- `provides.commands`: count of `.md` files under `.specify/extensions/speckit-superpowers-bridge/commands/` (currently **7** per the survey).
- `provides.hooks`: count of unique hook command IDs that reference this extension across `.specify/extensions.yml` (**0** at the moment — our extension *consumes* hooks via `git.commit` / `superpowers.guard` references, but does not *publish* hooks for external consumers; the integer reflects what we provide for others, not what we consume).

The catalog schema accepts integers; populate them at submission-checklist time by introspection.

**Rationale**: Static counts are stable per release; auto-derive at script time to avoid stale numbers in `extension.yml`.

**Alternatives considered**:
- *Hand-maintain the counts in `extension.yml`*: rejected — prone to drift. The submission-checklist script re-computes and asserts.

---

## R7 — Badges: which 4 and rendered how

**Decision**: 4 Shields.io badges at the top of `README.md`, in this order:

1. `![License: MIT](https://img.shields.io/github/license/lihan3238/speckit-superpowers-bridge)` — license badge
2. `![Latest release](https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge)` — version
3. `![Last commit](https://img.shields.io/github/last-commit/lihan3238/speckit-superpowers-bridge)` — maintenance signal
4. `![Spec Kit](https://img.shields.io/badge/spec--kit-%E2%89%A50.8.10-blue)` — Spec Kit compatibility badge (custom Shields.io endpoint, no remote query)

All four resolve at GitHub's CDN via Shields.io's existing public API; no setup required. The custom Spec Kit badge is a static `endpoint` style.

**Rationale**: 4 is the sweet spot — informative without ribbon-spam. Each badge gives a different signal (legal, freshness, maintenance, compatibility). License + last-commit are what Spec Kit's own README uses; we follow upstream norm.

**Alternatives considered**:
- *Add coverage / build-status badges*: rejected — no CI yet; would be misleading.
- *Add a downloads counter*: rejected — Shields.io does not (yet) surface Spec Kit catalog downloads; we'd need either a custom endpoint or GitHub Releases download counter (different number).

---

## R8 — CHANGELOG retroactive content

**Decision**: Three sections initially:

```text
## [Unreleased]
- Section to receive feature 005 / v0.2.0 content as work lands.

## [0.1.1] — 2026-05-XX (date of v0.1.1 commit `15d0376`)
### Added
- Bridge handoff schema v3: `autonomous_mode` + `resume_context` fields.
- `audit-install-state.ps1`, `validation-pass.ps1`, `parity-check.ps1` meta-commands.
- 5 mirrored `.claude/skills/speckit-git-*/SKILL.md` for cross-agent parity.
- Bilingual README scaffold (English + Simplified Chinese, structural parity-checked).
- `plugin-distribution-manifest.yml` declaring marketplace includes/excludes.
- 8 smoke test suites under `tests/`.
### Changed
- Bridge SKILL.md (both Codex and Claude) rewritten to explicit Skill-tool / `$skill-name` invocations at named phases.
- Actor resolution: `SPECKIT_BRIDGE_ACTOR` env → `.specify/integration.json.default_integration` → `unknown`. Hard-coded `-Actor codex` defaults removed.
### Fixed
- CG-006: handoff command no longer hardcodes `-Actor codex` (correct actor resolved per chain).
- CG-003: `complete` handoff no longer blocks cross-feature work (auto-archive path added).

## [0.1.0] — 2026-05-XX (initial bridge prototype merge)
### Added
- Bridge extension under `.specify/extensions/speckit-superpowers-bridge/`.
- Disposition matrix (31 entries) classifying every Spec Kit command + Superpowers skill.
- Parity check (`parity-check.ps1`) with 6 checks.
- Verified-versions pin (`verified-versions.json`).
- Codex + Claude bridge `SKILL.md` peers.
- Guard, handoff, snapshot, restore scripts.
```

Dates filled at release time from `git log`. Format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).

**Rationale**: Retroactive entries give history; future entries follow the same shape so the file is self-documenting.

**Alternatives considered**:
- *Start CHANGELOG at v0.2.0 (this feature)*: rejected — readers lose history; Spec Kit catalog reviewers might flag it as "thin trust".

---

## R9 — Where do the AI-disclosure paragraphs live?

**Decision**: Three locations, all sourcing from the same canonical text in `marketplace/upstream-pr-body.md`:

1. `marketplace/upstream-pr-body.md` — the PR description template (PRIMARY; submission-checklist asserts its presence).
2. `README.md` "Contributing & License" section — visible to anyone landing on the repo (transparency).
3. `CHANGELOG.md` — one line in the introduction paragraph: "Developed with AI coding assistants per Spec Kit CONTRIBUTING.md."

All three say the same thing in different word counts. The primary disclosure (for the maintainer) is the PR body; the others are public-trust signals.

**Rationale**: Disclosure is once for the maintainer + visible to consumers. Single source of truth (the PR body) prevents drift.

---

## R10 — Stale `0.8.9` references in historical artifacts

**Decision**: **Do not touch** historical feature 001/002/003/004 spec/plan/research files that reference `0.8.9`. Those are timestamped records of decisions made when that was the live version. Forward-facing artifacts only get the `0.8.10` update:

- `extension.yml` (current — modified)
- `verified-versions.json` (current — modified)
- `README.md` + `README.zh-CN.md` (current — modified)
- `marketplace/catalog-entry.json` (new)
- `submission-checklist.ps1` (new — asserts `>=0.8.10`)
- `feature 005 spec.md / plan.md / research.md` (current — uses 0.8.10)

The historical record is the historical record. The README "Maintenance & Versioning" section clarifies that 0.8.10 is the verified version as of this release.

**Rationale**: Respects the principle of "audit trail is append-only and reflects state at time of decision". Modifying historical specs would distort the design provenance.

**Alternatives considered**:
- *Rewrite history*: rejected.
- *Add a top-level "version drift note"* to old features: rejected — that's noise; the live `verified-versions.json` is the source of truth, and the parity check enforces it.

---

## Open items deferred to plan-time → tasks (no further research needed)

None. All 10 unknowns resolved.
