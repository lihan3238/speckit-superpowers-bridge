# Implementation Plan: Bridge Hardening & 0.5.0 Cleanup Release

**Branch**: `008-bridge-hardening-0-5-0` | **Date**: 2026-05-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/008-bridge-hardening-0-5-0/spec.md`

**Note**: Filled by `/speckit-plan`. Spec is settled (6 Clarifications resolved). This plan adds research, data-model, contracts, quickstart — and an explicit Constitution Check that gates the implementation phase.

## Summary

Primary requirement: ship **v0.5.0** as a release that (a) hardens the bridge against the session/agent-resume drift that produced G1/G2/G3 in v0.4.2 + v0.4.3, (b) realigns the existing 003/007 design artifacts to actual shipped state, (c) decides and documents the official catalog-update policy, (d) consolidates the long-running `003-cross-platform-cleanup` branch back to `main`, and (e) records the constitution v1.2.0 sandbox verification for v0.5.0.

Technical approach: implement FR-001..FR-005 as a single shared helper (`bridge-state.ps1` / `bridge-state.sh` — internal helper file, NOT a new public subcommand per Q3=C) sourced by both `update-handoff.{ps1,sh}` and `guard-command.{ps1,sh}`. The helper computes the canonical pending-tasks count using regex `^- \[ \] T\d+` (Q4=A), respects only section-header exemptions matching the FR-005 regex (Q6=A), prints a `[bridge state]` summary block including `prior_actor`, and emits the FR-003 warning on `complete`-with-unchecked transitions. All other US (docs alignment, catalog research, branch merge, verification) are sequenced behind the runtime change so US1's drift detection actively backs US2's hygiene fixes.

## Technical Context

**Language/Version**: PowerShell 5.1+ (Windows flavor) + bash 4.0+ (Linux/macOS flavor) — matches existing `.specify/extensions/speckit-superpowers-bridge/scripts/{powershell,bash}/` flavors.

**Primary Dependencies**:
- `jq >= 1.6` (bash flavor, already required by the project per `marketplace/catalog-entry.json`).
- Spec Kit `>= 0.8.10` (unchanged from prior releases).
- No new dependencies — adheres to Constitution Principle I (Lightweight & Repo-Local).

**Storage**: Filesystem only.
- State: `.specify/superpowers-handoff.json` (handoff state), `.specify/feature.json` (active feature pointer) — unchanged schema.
- Event log: `.specify/bridge-events.jsonl` — adds `prior_actor` field on handoff transitions (additive, JSONL consumers continue to parse).
- Verification record: `specs/008-bridge-hardening-0-5-0/verification.md` (new file, per FR-018).

**Testing**: Existing PowerShell smoke test harness under `tests/`. Adds `tests/test-bridge-state-summary.ps1` (TDD), which internally dispatches both PS and bash flavors using the existing path-translation strategy chain from v0.4.2 B2. Reuses `tests/test-handoff-shape.ps1` patterns.

**Target Platform**: Windows PowerShell + WSL Linux bash for v0.5.0 sandbox PASS rows; macOS bash PENDING (FR-020).

**Project Type**: Spec Kit extension — repo-local PowerShell/bash scripts + Markdown skills + JSON state, packaged as `.zip` release artifact. Not a typical web/CLI app project. Source-code layout reflects the extension package structure, not a single `src/` tree.

**Performance Goals**: Per-invocation overhead from the new state-summary helper < 50 ms on a typical dev box (spec Assumptions). Measured by `Measure-Command` on Windows and `time` on bash during test development.

**Constraints**:
- Handoff JSON byte-stable (no new fields in handoff.json itself — `prior_actor` lives in event log only). Inherited from constitution Principle IV.
- SC-013 north-star: changes confined to `.specify/extensions/speckit-superpowers-bridge/`; no new Spec Kit commands or Superpowers skills introduced.
- Bridge runtime byte-frozen across v0.4.3 → v0.5.0 EXCEPT for the surgical drift-hardening additions in `update-handoff.{ps1,sh}` + `guard-command.{ps1,sh}` + the new helper.

**Scale/Scope**: Single-user dev workflow per the existing model. One active feature per repository at a time (constitution Principle IV). Tasks.md files in this repo are ≤ 300 task lines; the regex-based pending-count is O(n) per file scan and runs once per script invocation — well within the 50ms budget.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Pass? | Notes |
|---|---|---|
| **I. Lightweight & Repo-Local** | ✅ Pass | Adds one internal helper file per flavor (`bridge-state.{ps1,sh}`); no new daemons, services, dependencies, or global modifications. Total added lines ≤ ~80 combined per spec Assumptions. |
| **II. Design/Implementation Separation** | ✅ Pass | US1 adds a *bridge-boundary surfacing* of state — it does NOT introduce planning, brainstorming, TDD, or any other discipline into the bridge. Spec Kit still owns `tasks.md` content; Superpowers still owns implementation execution. SC-013 codifies this as a checkable invariant. |
| **III. Agent-Neutral Protocol** | ✅ Pass | Both PS and bash flavors must ship the helper. Both `update-handoff` flavors print the same summary fields. `prior_actor` is logged in both flavors. New regression test (`test-bridge-state-summary.ps1`) dispatches both flavors via the v0.4.2 B2 path-translation chain. |
| **IV. Smooth Bidirectional Handoff** | ✅ Pass | Enhances handoff fidelity: `prior_actor` is now first-class in the event log; state summary printed on every script run means a resuming agent (Claude or Codex) can read the current `feature_directory`, `status`, `artifact_owner`, and pending count from the first command output without manual JSON parsing. Snapshot mechanism is untouched. |
| **V. Vendor-Managed Boundaries** | ✅ Pass | Changes are exclusively under `.specify/extensions/speckit-superpowers-bridge/`. Vendor-managed `.agents/skills/speckit-*` and `.claude/skills/speckit-*` are NOT touched (except the `speckit-superpowers-bridge` skill peers, which are our package and not vendor-managed per `CLAUDE.md`). |

### Release gate (constitution §"End-User Verification Sandbox", v1.2.0+)

v0.5.0 ships a release artifact (`extension.yml` bump → tag → workflow → ZIP). The sandbox verification is planned as **US5** with FR-018 + FR-019 specifying the row schema and the deliberate-mismatch test that exercises the new drift-hardening output. macOS row stays PENDING per FR-020 / Clarifications Q1. Sandbox sequence inherited unchanged from the v0.4.2 / v0.4.3 cycles.

**Verdict**: Gates pass. No complexity-tracking exceptions required. Phase 0 research may proceed.

## Project Structure

### Documentation (this feature)

```text
specs/008-bridge-hardening-0-5-0/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── bridge-state-summary.md       # State-block format printed by helper
│   ├── event-log-prior-actor.md      # bridge-events.jsonl new field
│   └── catalog-update-policy.md      # FR-009/FR-010 process contract
├── checklists/
│   └── requirements.md  # Spec quality checklist (already populated)
├── verification.md      # Release sandbox record (created during US5 execution)
└── tasks.md             # /speckit-tasks output (NOT created here)
```

### Source Code (repository root)

This project is a Spec Kit extension, not a conventional `src/` codebase. Real layout:

```text
.specify/extensions/speckit-superpowers-bridge/
├── extension.yml                            # version bump → 0.5.0
├── commands/                                # Spec Kit command surface (unchanged)
├── scripts/
│   ├── powershell/
│   │   ├── update-handoff.ps1               # MODIFIED: source bridge-state.ps1, print summary, log prior_actor, emit warning
│   │   ├── guard-command.ps1                # MODIFIED: print state summary on every allow/deny
│   │   ├── bridge-state.ps1                 # NEW: shared helper computing pending count + summary block
│   │   ├── common-actor-resolution.ps1      # unchanged
│   │   └── ... (other existing scripts unchanged)
│   └── bash/
│       ├── update-handoff.sh                # MODIFIED: source bridge-state.sh, same behavior as PS
│       ├── guard-command.sh                 # MODIFIED: same
│       ├── bridge-state.sh                  # NEW: shared helper, bash flavor
│       └── ... (other existing scripts unchanged)
└── ... (manifest + commands unchanged)

.agents/skills/speckit-superpowers-bridge/SKILL.md       # MODIFIED: refresh version refs ONLY (no banner per Q3=C)
.claude/skills/speckit-superpowers-bridge/SKILL.md       # MODIFIED: refresh version refs ONLY

tests/
├── test-bridge-state-summary.ps1            # NEW: regression for SC-001/SC-002/SC-003
├── test-handoff-shape.ps1                   # unchanged
├── test-guard-hardcoded-rules.ps1           # unchanged
└── test-claude-codex-skill-parity.ps1       # unchanged (will run green by construction)

marketplace/
├── catalog-entry.json                       # MODIFIED: version 0.5.0, new download_url
├── extension-submission-body.md             # MODIFIED: version + URLs + SHA placeholder
├── extensions-readme-row.md                 # MODIFIED: aligned per FR-012
└── README.md                                # MODIFIED: FR-009 policy + upstream citation + Q5 (minor/major-only)

specs/003-bridge-cross-platform-scripts/
└── tasks.md                                 # MODIFIED: align per FR-007 (move deferred to "## Deferred (...)" section)

specs/007-catalog-distribution-polish/
├── tasks.md                                 # MODIFIED: T022-T028 checked per FR-006
└── verification.md                          # MODIFIED: append "## Gate evidence" subsection per FR-008

CHANGELOG.md                                 # MODIFIED: append [0.5.0] section with Compatibility subsection (FR-014)
AGENTS.md                                    # MODIFIED: prune pre-0.4.2 references per FR-015
extension.yml                                # (already aliased — the source of truth is .specify/extensions/.../extension.yml)
```

**Structure Decision**: Direct edits to the extension package directory tree (the published artifact). No new top-level dirs introduced. Source code lives where it ships from — that is the constitution Principle I "Lightweight & Repo-Local" instantiation.

## Implementation strategy (phased)

Phase ordering is dictated by US dependencies + the spec's MVP discipline:

1. **Phase A — TDD foundation (US1 + tests)**: Write `tests/test-bridge-state-summary.ps1` first (RED), then implement `bridge-state.{ps1,sh}` + edit `update-handoff.{ps1,sh}` + `guard-command.{ps1,sh}` until tests pass (GREEN). This delivers the drift-hardening capability. Critically: this MUST land before US2 so the bridge actively backs the docs cleanup.

2. **Phase B — Docs/reality alignment (US2)**: Drive US2 with US1 actively running. Edit `specs/007-*/tasks.md` (T022-T028 → checked, T029 either checked or moved under `## Deferred`). Edit `specs/003-*/tasks.md` (move deferred user-side verification under `## Deferred (...)`). Append `## Gate evidence` to `specs/007-*/verification.md`. Verify the bridge no longer warns when running guard against 007 (status=complete).

3. **Phase C — Catalog research + materials (US3)**: Research `github/spec-kit` `CONTRIBUTING.md` and recent issues for any documented automated catalog-update path; record citation in `marketplace/README.md`. Update `marketplace/{catalog-entry.json, extension-submission-body.md, extensions-readme-row.md}` to v0.5.0. **Do not file the upstream issue yet** — that happens after the tag publishes (so the issue body can carry the actual SHA256).

4. **Phase D — Release prep (US4 incl. version bump + CHANGELOG + AGENTS)**: Bump `extension.yml` to `0.5.0`. Append `[0.5.0]` section to `CHANGELOG.md` with `### Compatibility` subsection naming v0.4.2 as the new minimum direct-upgrade baseline. Prune pre-0.4.2 references in `AGENTS.md`. Run `tests/*.ps1` + `scripts/release/validate-release-readiness.ps1 -Version 0.5.0` — all green.

5. **Phase E — Tag, release, sandbox (US5 + tail of US4)**: Tag `v0.5.0`. Watch the GH Actions release run. Capture SHA256 from the workflow Step Summary. Run sandbox install on `..\test_specify_superpower` for Windows PS + WSL Linux bash. Record PASS rows + the FR-019 deliberate-mismatch test result in `verification.md`. macOS row → PENDING.

6. **Phase F — Catalog issue + close v0.4.3 (tail of US3)**: File the v0.5.0 catalog-update issue against `github/spec-kit` (because 0.5.0 IS a minor bump per Q5=C). Close the existing v0.4.3 issue with a pointer to the v0.5.0 issue.

7. **Phase G — Main merge (tail of US4 — per Q2=B)**: Open a PR from `008-bridge-hardening-0-5-0` → `main`. The PR carries everything from the 003 cycle backlog plus 008. Merge using GitHub's standard (squash or merge commit per upstream norm; whichever preserves linear history best). Mark handoff `complete`.

## Open research items (Phase 0 inputs)

These are pinned to research.md so they're answered before Phase A:

- **R1**: Where exactly to insert the state-summary print in `update-handoff.ps1` / `update-handoff.sh` — before or after the actual JSON write? (Affects what `status`/`actor` values the summary reflects when the operation fails mid-stream.)
- **R2**: Regex parity between PowerShell `-match` (with `(?i)` flag) and bash `grep -E` for FR-005's header pattern. Confirm both engines produce identical exemption decisions on a fixture tasks.md.
- **R3**: PowerShell `Get-Content -ReadCount` vs `.Split("\n")` for streaming the pending-count scan — pick whichever is reproducible under the 50ms budget.
- **R4**: Bash side: should we use `awk` or pure `grep`/`sed` to compute the pending count with section-header awareness? `awk` is more readable; `grep`-only would require a two-pass approach.
- **R5**: Upstream catalog-update flow as of 2026-05-16 — what does `github/spec-kit/CONTRIBUTING.md` (current main) actually say about re-bumping an already-accepted entry? Citation needs the specific section/anchor URL.
- **R6**: PR #2586 thread (the merge that accepted v0.4.1) — any maintainer comment establishing precedent for v0.4.x → v0.5.x updates? Open issues referencing `extensions/catalog.community.json` since merge?

## Re-evaluation of Constitution Check (post-design)

To be re-run at end of Phase 1 (after research.md + data-model.md + contracts/ land). Expected to remain ✅ across all 5 principles. Re-check will note any design choices that drift from the planned structure above; if any do, return to the Constitution Check section and document them under Complexity Tracking with explicit justification.

## Complexity Tracking

No constitutional violations expected. If any surface during research:

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| _(none expected)_ | _(none)_ | _(none)_ |

## Out of Plan

These were considered and explicitly NOT planned for v0.5.0:

- Bridge subcommand for status (`bridge-state` as a public command) — rejected per Q3=C.
- `--strict` flag on `update-handoff` that turns the FR-003 warning into a blocking error — rejected per Q3=C.
- SKILL.md banner advertising state — rejected per Q3=C.
- Front-matter `deferred:` list at top of tasks.md — rejected per Q6=A (only section headers).
- Inline `(deferred)` token recognition — rejected per Q6=A.
- macOS sandbox row — deferred per FR-020 / Clarifications Q1.
- Per-release upstream catalog issue for patch bumps — rejected per Q5=C.
- Schema additions to `superpowers-handoff.json` — out of scope per spec (`prior_actor` is event-log only).
- New Spec Kit commands or Superpowers skills — prohibited by SC-013.
