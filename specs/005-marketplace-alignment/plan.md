# Implementation Plan: Marketplace Alignment

**Branch**: `005-marketplace-alignment` | **Date**: 2026-05-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/005-marketplace-alignment/spec.md`

**Primary Design Reference**: [Spec Kit vs Superpowers — dev.to article (truongpx396)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj). Consulted for any architectural ambiguity about WHAT-vs-HOW ownership; the bridge already codifies it via feature 002's disposition matrix.

**Planning Constraint**: This feature is **documentation + packaging + cleanup**, not new bridge behavior. Lightest possible diff that:
1. Closes the four required-file gaps (LICENSE, CHANGELOG, complete `extension.yml`, catalog entry draft).
2. Reflows the README to the FR-009/FR-010 order with multi-environment install paths.
3. Audits the gitignore + distribution manifest + repo tree for stale content.
4. Adds discoverability trust signals (badges, tags, north-star link).

No new runtime, no new bridge state, no new scripts beyond the submission/cleanup audit helpers. The disposition matrix (feature 002) and skill-invocation events (feature 004) are unchanged.

## Summary

Five focused work-streams, all repo-file edits + 2 small new scripts:

1. **Required-file gap closure (US1)**: create `LICENSE` (MIT), `CHANGELOG.md` (Keep-a-Changelog, retroactive entries for v0.1.0 + v0.1.1), update `extension.yml` (`tags`, `requires.speckit_version: ">=0.8.10"`, `provides.commands`/`hooks` counts), draft `marketplace/catalog-entry.json` + `marketplace/extensions-readme-row.md`, draft `marketplace/upstream-pr-body.md` with AI disclosure.
2. **Submission checklist script (US1)**: new `submission-checklist.ps1` mirroring the upstream maintainers' automated verification (manifest schema, file presence, URL HTTP 200, tag count, semver shape). Exit 0 = submission-ready.
3. **README reflow (US2)**: rewrite `README.md` to the FR-009/FR-010 ordered structure (value prop → workflow diagram → install paths for pure-Codex/pure-Claude/dual-agent → first-feature-in-10-min walkthrough → troubleshooting → maintenance-and-versioning → architecture-in-60-seconds → trust badges). Mirror to `README.zh-CN.md`; existing parity check enforces structural alignment.
4. **Slim + cleanup (US3)**: extend the existing `audit-install-state.ps1` (or add a small companion `cleanup-audit.ps1`) to identify stale files (unreferenced `docs/`, abandoned scripts, `.bak-*`, scratch checklists). Re-audit `.gitignore`. Tighten `plugin-distribution-manifest.yml` if anything moved.
5. **Trust signals (US4)**: badges in README (license, version, last-commit, downloads if available), tag set locked at the 6 from clarify (`bridge, superpowers, cross-agent, governance, tdd, workflow`), Architecture-in-60-seconds section paraphrasing the dev.to article with attribution.

## Technical Context

**Language/Version**: PowerShell 5.1+/7.x (Windows-first; Linux/macOS via deferred 003 feature), Markdown, JSON, YAML. No new languages.
**Primary Dependencies**: Spec Kit `0.8.10` (per `.specify/init-options.json`; locked by clarify Q2), Superpowers runtime-exposed skill set, git ≥ 2.30. No new external dependencies.
**Storage**: Repository files only. No state schema changes (handoff schema v3 from feature 004 stays). One new bridge event type `submission_check` is optional polish.
**Testing**: Existing 15-test smoke suite stays green; this feature adds at most 2 new suites — `tests/test-submission-checklist.ps1`, `tests/test-cleanup-audit.ps1` — and updates `test-readme-bilingual-parity.ps1` if the README structure changes its anchor set.
**Target Platform**: Windows-first; Spec Kit catalog accepts any platform — submission is platform-agnostic; runtime support is Windows-only until CG-005 (feature 003) closes.
**Project Type**: Local Spec Kit extension + per-agent skill pack — same shape as features 001/002/004.
**Performance Goals**: Submission checklist runs under 30 seconds (network-bounded by 2 HTTP HEAD requests for repo URL + release ZIP). README parity check unchanged (~1 second). Cleanup audit under 5 seconds.
**Constraints**: No new bridge state schema; the disposition matrix, verified-versions record, and handoff schema are frozen for this feature. AI-assistance disclosure MUST appear in the upstream PR description. README MUST be valid markdown rendering on github.com (no extension-specific shortcodes). Bilingual READMEs MUST stay structurally parity-checked.
**Scale/Scope**: ≤ 20 new/changed files. README + zh-CN twin = bulk of the diff. ~4 new files in `marketplace/` directory + 1 LICENSE + 1 CHANGELOG + 1-2 new scripts + 1-2 new tests.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Lightweight & Repo-Local | No new runtime, daemon, service, marketplace package format; smallest diff | **PASS** — pure docs + manifest edits + 1-2 small scripts; ZERO bridge runtime changes |
| II. Design/Implementation Separation (NON-NEGOTIABLE) | No overlap between Spec Kit design ownership and Superpowers execution ownership; matrix is source of policy | **PASS** — this feature does not touch the disposition matrix, the guard logic, or any Superpowers invocation pattern |
| III. Agent-Neutral Protocol | Identical behavior on Codex and Claude Code; explicit syntax mapping | **PASS** — README documents install paths for pure-Codex / pure-Claude / dual-agent; tag set is agent-agnostic |
| IV. Smooth Bidirectional Handoff | Handoff state machine discoverable | **PASS** — no handoff state changes |
| V. Vendor-Managed Boundaries | No hand-edits to `.agents/skills/speckit-*` or `.claude/skills/speckit-*` (upstream-generated) | **PASS** — this feature edits only repo-root files (README/LICENSE/CHANGELOG/`.gitignore`), `marketplace/` directory (new), and `extension.yml`. Upstream-generated skill files untouched |

**Initial Constitution Check**: PASS. **Post-Design Re-check (after Phase 1)**: PASS — see contracts; no principle relaxed.

## Project Structure

### Documentation (this feature)

```text
specs/005-marketplace-alignment/
|-- spec.md                       # done (3 clarifications recorded)
|-- plan.md                       # this file
|-- research.md                   # Phase 0 output (~6 unknowns resolved)
|-- data-model.md                 # Phase 1 output (4 new entities)
|-- quickstart.md                 # Phase 1 output (release runbook validation)
|-- contracts/
|   |-- catalog-entry.schema.json
|   |-- submission-checklist-contract.md
|   |-- release-runbook-contract.md
|   |-- cleanup-audit-contract.md
|-- checklists/
|   `-- requirements.md           # done (from /speckit-specify)
|-- compat-gaps.md                # initialized empty; validation may append
|-- tasks.md                      # (NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
README.md                                                # MODIFIED: full reflow per FR-009/FR-010
README.zh-CN.md                                          # MODIFIED: mirror reflow; structural parity
LICENSE                                                  # NEW: MIT license text
CHANGELOG.md                                             # NEW: Keep-a-Changelog with retro entries
.gitignore                                               # MODIFIED: re-audited per cleanup decisions

marketplace/                                             # NEW directory
|-- catalog-entry.json                                   # NEW: the JSON object to paste into upstream catalog.community.json
|-- extensions-readme-row.md                             # NEW: the Markdown row to paste into upstream extensions/README.md
|-- upstream-pr-body.md                                  # NEW: PR description template incl. AI-disclosure section
|-- README.md                                            # NEW: brief notes on how this directory feeds the upstream PR

.specify/
|-- extensions/
|   |-- speckit-superpowers-bridge/
|   |   |-- extension.yml                                # MODIFIED: tags (6 from clarify), requires.speckit_version >=0.8.10, provides.commands/hooks counts, complete metadata
|   |   |-- verified-versions.json                       # MODIFIED: spec_kit_version "0.8.10"
|   |   |-- plugin-distribution-manifest.yml             # MODIFIED: ensure LICENSE + CHANGELOG.md are in includes
|   |   |-- scripts/
|   |   |   `-- powershell/
|   |   |       |-- submission-checklist.ps1             # NEW: mirrors upstream maintainer verification
|   |   |       `-- cleanup-audit.ps1                    # NEW (or extension of audit-install-state.ps1)

tests/                                                   # MODIFIED + NEW
|-- test-submission-checklist.ps1                        # NEW
|-- test-cleanup-audit.ps1                               # NEW
|-- test-readme-bilingual-parity.ps1                     # MODIFIED if anchor set changes (the parity rules don't change)

docs/                                                    # POSSIBLY NEW or augmenting existing extension docs/
`-- (nothing required at repo root; existing extension's docs/parameter-reference.md stays where it is)
```

**Structure Decision**: Keep the existing repo shape. The only structural addition is the new top-level `marketplace/` directory holding the upstream-PR-ready artifacts (catalog entry JSON, README row, PR body). Everything else is in-place edits.

## Design Decisions

1. **`marketplace/` directory layout** — A single top-level directory containing exactly the files the upstream PR pastes verbatim. Reviewers see "yes these are the proposed entries" without scanning the whole repo. Lives at repo root (not under `.specify/`) because the marketplace artifacts are meta to this repo, not project state.

2. **`submission-checklist.ps1` reuses parity-check.ps1's `Finding` shape and exit-code convention** — same envelope (P0/P1/P2 severity, JSON or human output, exit codes 0/1/2/3) so the maintainer or CI can treat all our audit scripts uniformly. Implementation pattern: dot-source common helpers from existing scripts; don't reinvent.

3. **`cleanup-audit.ps1` as a small companion** — separate script (not an extension of `audit-install-state.ps1`) because audit-install-state is about the host's install state at install time; cleanup-audit is about the source repo at development time. Different concerns; separate scripts. ~80 lines of PowerShell expected.

4. **README reflow strategy** — destructive rewrite (not incremental edits) because the FR-009/FR-010 order is materially different from the current shape. Preserve existing useful prose (the install command, the architecture paragraph) but in the new order. Generate `README.zh-CN.md` as a structural twin (anchors first, body re-translated by humans; the parity check enforces structure only).

5. **Trust badges** — github.com auto-rendered Shields.io badges only. No external image hosting, no CI-rendered badges. Concretely: `![license MIT](https://img.shields.io/badge/license-MIT-blue)`, `![version](https://img.shields.io/github/v/tag/lihan3238/speckit-superpowers-bridge)`, `![last commit](https://img.shields.io/github/last-commit/lihan3238/speckit-superpowers-bridge)`. Downloads badge added after first release tracks accrue.

6. **CHANGELOG retro entries** — `v0.1.0` covers features 001+002 (initial bridge, disposition matrix, parity check, 5 Claude mirrors). `v0.1.1` covers feature 004 (schema v3, autonomous mode, resume context, install-state audit, validation pass, bridge SKILL.md explicit invocations, bilingual README scaffolding, distribution manifest). Upcoming `v0.2.0` covers this feature (marketplace listing prep, README polish, cleanup). Each version section follows Keep-a-Changelog (Added/Changed/Fixed/Deprecated/Removed).

7. **AI-disclosure language** — explicit paragraph in `marketplace/upstream-pr-body.md`: "This extension was developed using AI coding assistants (Claude Code for design + planning, Codex for implementation), per the AI-disclosure requirement in Spec Kit CONTRIBUTING.md. Every artifact passed human review before commit; the bridge's own validation pass and 15+ smoke tests are the verification surface." Submission-checklist script greps for this paragraph in the PR body to confirm presence.

8. **Tag set is closed for v0.1.x** — Per clarify Q3, locked at the 6 chosen. Future tag changes need a CHANGELOG entry. The `extension.yml` validator (part of submission-checklist.ps1) asserts exactly this set.

9. **`requires.speckit_version: ">=0.8.10"`** — Per clarify Q2. `verified-versions.json.spec_kit_version: "0.8.10"`. Stale `0.8.9` references in plan.md / research.md / quickstart.md / contracts of feature 002 and 004 are NOT touched by this feature (those are historical records); only forward-facing assets (extension.yml, verified-versions.json, README, catalog entry, submission checklist) carry the current pin.

10. **Spec Kit catalog entry alphabetical insertion** — Per the catalog convention, our `id: speckit-superpowers-bridge` inserts between whichever existing entries flank "speckit-superpowers-bridge" alphabetically. The PR body notes the surrounding entries so reviewers can verify position.

## Minimal Implementation Scope

The fastest usable diff covers these in order:

- `LICENSE` (MIT text, ~22 lines)
- `CHANGELOG.md` with retro v0.1.0/v0.1.1 + upcoming v0.2.0 sections
- `extension.yml` update: `tags: [bridge, superpowers, cross-agent, governance, tdd, workflow]`, `requires.speckit_version: ">=0.8.10"`, `provides.commands: <count>`, `provides.hooks: <count>`
- `verified-versions.json`: `spec_kit_version: "0.8.10"`
- `README.md` reflow per FR-009/FR-010
- `README.zh-CN.md` mirror reflow
- `marketplace/catalog-entry.json` with the JSON object to paste upstream
- `marketplace/extensions-readme-row.md` with the table row to paste upstream
- `marketplace/upstream-pr-body.md` with AI-disclosure paragraph
- `marketplace/README.md` documenting what the directory is for
- `submission-checklist.ps1` (~120 lines, dot-sourcing common helpers)
- `cleanup-audit.ps1` (~80 lines)
- `tests/test-submission-checklist.ps1` (~40 lines)
- `tests/test-cleanup-audit.ps1` (~40 lines)
- `.gitignore` re-audited (likely small additions/removals)
- `plugin-distribution-manifest.yml` re-confirmed includes LICENSE + CHANGELOG; updated if `marketplace/` should ship in distributions (decision in research §R5)

## Carried-forward Compatibility Gaps

None new from prior features. CG-006 already CLOSED-IN-FEATURE-004. CG-005 stays DEFERRED to 003.

## Complexity Tracking

No constitution violations. Two judgment calls:

| Choice | Why Not Simpler | Why Not More Complete |
|---|---|---|
| Separate `marketplace/` directory (vs inline catalog entry in plan.md) | Inline would mean reviewers / submission-checklist must extract the JSON from prose; harder to validate | Generating the upstream PR via a CLI command would be over-engineering for a one-shot artifact |
| Trust badges via Shields.io only (vs CI-generated coverage / quality badges) | CI-generated badges require setting up a CI pipeline first, which is out of scope for a docs-and-packaging feature | Quality badges (coverage, codecov, codacy) would over-promise polish we haven't earned with this codebase yet |
