# Implementation Plan: Complete Bridge Protocol

**Branch**: `002-complete-bridge-protocol` | **Date**: 2026-05-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/002-complete-bridge-protocol/spec.md`

**Planning Constraint**: Smallest, lightest, most boring repo-local diff that closes every confirmed parity gap and codifies the disposition matrix. No new runtime, no marketplace package, no global plugin edits. The user has explicitly stated that cross-agent parity is a hard requirement implemented by mirroring files, not by redesign.

## Summary

Close the four concrete bridge gaps observed during the Claude Code live run, codify the dispositions of every Spec Kit command and Superpowers skill at verified versions, and add a parity check that prevents regression. The bulk of the work is mechanical: (a) mirror the five `speckit-git-*` skills from `.agents/skills/` into `.claude/skills/` (sharing the existing PowerShell scripts); (b) extend the bridge guard's state machine so `complete` handoffs do not block subsequent features and so a fresh-feature first-touch automatically claims ownership; (c) write a single machine-readable disposition matrix file under `.specify/extensions/speckit-superpowers-bridge/` and wire the guard to consult it; (d) add a `parity-check.ps1` script and a per-agent slash/skill wrapper that surfaces it. The validation pass is this very session — every gap we hit gets a Compatibility Gap Record entry.

## Technical Context

**Language/Version**: PowerShell scripts (existing runtime: `powershell.exe` Desktop 5.1+ and `pwsh` 7.x), Markdown skill files, YAML hook config, JSON state files. No new languages introduced.
**Primary Dependencies**: Spec Kit `0.8.9` (per `.specify/init-options.json`), Superpowers skill pack as currently surfaced to the active agent, git ≥ 2.30.
**Storage**: Repository files only — `.specify/superpowers-handoff.json`, `.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/`, the new disposition matrix file, the new verified-versions file, the new parity-check script. No databases, no daemons.
**Testing**: PowerShell smoke tests (`Pester` not required — plain `.ps1` test scripts following the existing `test-bridge-guard.ps1` pattern), JSON-schema parse checks, end-to-end happy-path script that exercises the Claude validation flow.
**Target Platform**: Windows-first PowerShell workspace; `pwsh` 7 compatibility kept where the existing scripts already support it. Linux/macOS contributors are out of scope for v2 unless a Bash port is added (deferred — see Compatibility Gap CG-005 below).
**Project Type**: Local Spec Kit extension + per-agent skill pack — same shape as feature 001, no new top-level structure.
**Performance Goals**: Parity check under 30 seconds on a clean checkout (SC-005); bridge guard decision under 1 second (constitution Principle I implied; carried forward from feature 001 planning). Handoff transitions on `/speckit-specify` add at most ~200 ms (one extra PowerShell invocation).
**Constraints**: No edits to upstream Superpowers plugin cache; no hand edits to officially generated `.agents/skills/speckit-*` or `.claude/skills/speckit-*` (except adding the 5 missing Claude peers, which is the explicit gap-closure for this feature and is not "hand-editing" an existing official file); keep `speckit.implement` installed but blocked by guard when handoff says so.
**Scale/Scope**: One active handoff per repo (constitution Principle IV); ≤ 25 disposition matrix entries at current upstream surface area; ≤ 30 new/changed files in the repo for this feature.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Lightweight & Repo-Local | No new runtime, daemon, service, marketplace package; smallest diff that delivers the capability; no global plugin cache edits | **PASS** — all changes are repo-local files; bulk of work is `cp` of existing skill files + a single new disposition matrix file + a single new parity-check script |
| II. Design/Implementation Separation (NON-NEGOTIABLE) | No overlap between Spec Kit design ownership and Superpowers execution ownership; `speckit.implement` blocked by guard when handoff is active; disposition matrix is the source of non-overlap policy | **PASS** — disposition matrix is the formal codification of this principle; `speckit.implement` remains in the matrix as FORBID-UNDER-HANDOFF; constitution edits scoped per Q1 clarification |
| III. Agent-Neutral Protocol | Identical behavior on Codex and Claude Code; explicit syntax mapping; `-Actor` accepted; `AGENTS.md` master | **PASS** — feature itself closes the agent-neutrality gap; `AGENTS.md` and `CLAUDE.md` remain consistent; parity check enforces this principle mechanically going forward |
| IV. Smooth Bidirectional Handoff | Handoff state machine discoverable; pre-write snapshots; agent switch requires only `-Actor` change | **PASS** — handoff transitions extended (not invented) to cover `complete` → `ready` auto-archive; snapshot/log surface unchanged in shape |
| V. Vendor-Managed Boundaries | No hand-edits to `.agents/skills/speckit-*` or `.claude/skills/speckit-*` from upstream; custom behavior in `speckit-superpowers-bridge` skills + `.specify/extensions/` | **PASS** — the 5 new Claude peer skills are net-new files mirroring Codex peers; they share scripts via the existing `.specify/extensions/git/scripts/` location; no upstream-generated official file is modified |

**Initial Constitution Check**: PASS.
**Post-Design Re-check (after Phase 1)**: PASS — see contracts and data-model; no principle was relaxed to accommodate the design.

## Project Structure

### Documentation (this feature)

```text
specs/002-complete-bridge-protocol/
|-- spec.md                       # done (clarified)
|-- plan.md                       # this file
|-- research.md                   # Phase 0 output
|-- data-model.md                 # Phase 1 output
|-- quickstart.md                 # Phase 1 output
|-- contracts/
|   |-- disposition-matrix.schema.json   # JSON Schema for the matrix file
|   |-- parity-check-contract.md         # CLI/exit-code contract for parity-check.ps1
|   |-- handoff-transitions-contract.md  # state-machine extension contract
|   |-- compat-gap-record-contract.md    # schema + lifecycle for gap records
|-- checklists/
|   |-- requirements.md           # done (from /speckit-specify)
|   |-- protocol-quality.md       # done (from /speckit-checklist)
|-- compat-gaps.md                # Phase 1: live-recorded gap log for the Claude run
|-- tasks.md                      # (NOT created by /speckit-plan; left for /speckit-tasks)
```

### Source Code (repository root)

```text
.specify/
|-- superpowers-handoff.json                    # schema unchanged; transitions added
|-- bridge-events.jsonl                         # append-only; new event types added (auto_archive)
|-- bridge-snapshots/                           # unchanged
|-- extensions.yml                              # rebalanced: drop git/superpowers-guard from before_checklist if any; keep current shape
|-- extensions/
|   |-- speckit-superpowers-bridge/
|   |   |-- extension.yml                       # unchanged structure
|   |   |-- disposition-matrix.yml              # NEW: the canonical matrix
|   |   |-- verified-versions.yml               # NEW: pinned Spec Kit + Superpowers versions
|   |   |-- commands/
|   |   |   |-- speckit.superpowers.guard.md    # unchanged
|   |   |   |-- speckit.superpowers.handoff.md  # unchanged
|   |   |   |-- speckit.superpowers.parity.md   # NEW: invocation surface for parity check
|   |   `-- scripts/
|   |       `-- powershell/
|   |           |-- guard-command.ps1           # MODIFIED: consult matrix; treat complete as terminal-not-active
|   |           |-- restore-snapshot.ps1        # unchanged
|   |           |-- test-bridge-guard.ps1       # extended with new transition tests
|   |           |-- update-handoff.ps1          # MODIFIED: support complete -> ready auto-archive
|   |           |-- parity-check.ps1            # NEW
|   |           `-- auto-archive-handoff.ps1    # NEW: small helper called by /speckit-specify path
|   `-- git/                                    # unchanged
|       `-- scripts/
|           `-- powershell/                     # existing; reused by the new Claude peer skills

.agents/
`-- skills/                                     # unchanged; already complete

.claude/
`-- skills/
    |-- speckit-*/                              # vendor-managed; not edited
    |-- speckit-superpowers-bridge/SKILL.md     # MODIFIED: add references to /speckit-superpowers-parity and the new transition behavior
    |-- speckit-git-commit/SKILL.md             # NEW: 1-to-1 mirror of .agents/skills/speckit-git-commit/SKILL.md
    |-- speckit-git-feature/SKILL.md            # NEW
    |-- speckit-git-initialize/SKILL.md         # NEW
    |-- speckit-git-remote/SKILL.md             # NEW
    `-- speckit-git-validate/SKILL.md           # NEW

AGENTS.md                                       # MODIFIED: add §"Disposition Matrix" with link; add §"Auto-archive transitions"
CLAUDE.md                                       # MODIFIED: SPECKIT marker block re-targeted at this plan; supplement notes updated
```

**Structure Decision**: Keep the same shape as feature 001 — extension under `.specify/`, per-agent skills under `.agents/skills/` and `.claude/skills/`, shared scripts. The only structural additions are two YAML config files (matrix + verified-versions) and two new PowerShell scripts (parity check + auto-archive helper). Five new Claude SKILL.md files are pure mirrors of the Codex peers and reference the same scripts via relative paths.

## Design Decisions

1. **Disposition matrix file format**: YAML (`disposition-matrix.yml`) rather than JSON. Rationale: human-editable, comment-friendly, and the existing `.specify/extensions.yml` is already YAML — same parser, same review experience. A JSON Schema (`contracts/disposition-matrix.schema.json`) defines required fields; the loader validates against it.
2. **Verified-versions file format**: YAML (`verified-versions.yml`), single canonical location. Fields: `spec_kit_version`, `superpowers_skills` (list of `{name, version-or-hash}`), `verified_at`, `verified_by`. Drift = any mismatch with the live install.
3. **Parity check invocation surface**: One PowerShell script (`parity-check.ps1`), one extension command file (`commands/speckit.superpowers.parity.md`), and one peer SKILL.md per agent (`speckit-superpowers-parity`). The script accepts `-Json` and a non-zero exit on failure (see contract).
4. **Handoff state machine extension**: Add a single new transition `complete` → `ready` (driven by a new helper `auto-archive-handoff.ps1`). The auto-archive snapshots the prior state and resets `feature_directory`, `artifact_owner`, and `review_only_agents` to empty so the next feature starts clean. The guard's "treat complete as terminal-not-active" rule is a one-line change in `guard-command.ps1`.
5. **First-touch ownership claim**: When a fresh-feature command (e.g. `/speckit-specify`) runs and `artifact_owner` is unknown/empty, the wrapper claims ownership for the active actor before invoking the underlying script. This closes gap-4 without changing the existing guard semantics — ownership simply becomes set instead of empty.
6. **No override path**: Per clarify Q4, no forced-action API is added. Repair flows continue to use `blocked` status.
7. **Bridge-events schema**: Add one new event type `auto_archive` with fields `{prior_feature_directory, prior_status, snapshot_id, actor, reason}`. Existing event types untouched.
8. **Claude peer skill content**: Each new `.claude/skills/speckit-git-*/SKILL.md` is a verbatim copy of its `.agents/skills/` peer, with only the front-matter `name` unchanged and any agent-specific invocation example updated (e.g., references to `$speckit-*` flipped to `/speckit-*`). Scripts are referenced via the same `.specify/extensions/git/scripts/powershell/...` relative path.
9. **Parity-check trigger policy**: Two entry points — (a) the new `/speckit-superpowers-parity` / `$speckit-superpowers-parity` for on-demand audits; (b) an optional pre-tasks hook entry in `extensions.yml` (set `optional: true`) so maintainers can opt into auto-checks before tasks generation without forcing it on existing flows. Decision: ship as `optional: true` to keep lightweight-first.
10. **Out of scope (deferred)**: Bash port of the PowerShell scripts (Linux contributor path, CG-005 below); native Claude Code installer/setup; auto-classification heuristics for new upstream capabilities.

## Minimal Implementation Scope

The fastest usable implementation should make these changes only:

- Mirror 5 `speckit-git-*` SKILL.md files from `.agents/skills/` to `.claude/skills/` (gap-1 close).
- Add `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.yml` with one entry per Spec Kit command and per currently-surfaced Superpowers skill, all classified per the clarified rules.
- Add `verified-versions.yml` capturing Spec Kit 0.8.9 and the Superpowers skill snapshot.
- Modify `guard-command.ps1` to (a) load the matrix and consult it before the existing hard-coded rules, (b) treat `complete` as terminal-not-active for cross-feature contract changes.
- Modify `update-handoff.ps1` to allow `complete` → `ready` (with snapshot) and add `auto-archive-handoff.ps1` as the explicit transition helper.
- Add `parity-check.ps1` (and its commands/skill surface) that returns non-zero exit on any disposition gap, missing replacement, version drift, or missing per-agent surface.
- Extend `test-bridge-guard.ps1` with cases for: (a) cross-feature auto-archive, (b) constitution forbid scope `{executing}`, (c) checklist always allowed, (d) missing-skill-on-claude detection (positive test should now PASS because the mirrors exist).
- Update `AGENTS.md` and `CLAUDE.md` with the new disposition-matrix section and the auto-archive rule.
- Record every gap hit during this Claude run in `compat-gaps.md` for the feature.

## Compatibility Gap Records (from live Claude run, this session)

| ID | Severity | Description | Proposed Resolution | Status |
|---|---|---|---|---|
| CG-001 | P1 | `.claude/skills/speckit-git-{commit,feature,initialize,remote,validate}` missing → before-hooks for `/speckit-specify`, `/speckit-clarify`, `/speckit-plan` etc. cannot resolve their slash command on Claude Code | Mirror SKILL.md from `.agents/skills/`; share scripts | OPEN — closed by this feature |
| CG-002 | P1 | `speckit.superpowers.guard` / `speckit.superpowers.handoff` referenced by hooks but not surfaced as standalone slash commands on either agent (only the parent `speckit-superpowers-bridge` skill exists) | Add `commands/speckit.superpowers.parity.md` style command surfacing; both agent integration manifests already pick up extension commands automatically — verify on Claude Code | OPEN — partial close in this feature (parity command added; guard/handoff command surfacing pending integration-manifest verification) |
| CG-003 | P1 | Bridge guard treated a prior feature's `complete` handoff as a global block on a new feature's contract changes (`speckit.clarify` denied on fresh 002 because 001 was `complete`) | Treat `complete` as terminal-not-active; add `complete` → `ready` auto-archive transition | OPEN — closed by this feature |
| CG-004 | P1 | Bridge guard required explicit `artifact_owner` before a fresh feature could clarify; no automatic first-touch ownership claim | Wrapper auto-claims ownership for the active actor when `artifact_owner` is empty | OPEN — closed by this feature |
| CG-005 | P3 | Bridge scripts are PowerShell-only; Linux/macOS contributors cannot run guard/handoff/parity natively | Bash port of the 4 PowerShell scripts | DEFERRED — out of scope for v2; record but defer to follow-up feature |

CG-005 is the only deferred item and is explicitly P3 (no shipping blocker).

## Complexity Tracking

No constitution violations are required. The design avoids new services, packages, or global plugin edits. The single judgment call worth recording:

| Choice | Why Not Simpler | Why Not More Complete |
|---|---|---|
| Disposition matrix as YAML (vs. inline in `extensions.yml`) | Inline would couple non-overlap policy to extension config; separate file lets the matrix evolve independently and lets the parity check load only what it needs | Full schema validation in the loader is over-engineered for ~25 entries; we keep JSON Schema as the contract but only spot-check structure in the loader |
| Auto-archive on `/speckit-specify` (vs. requiring explicit `/speckit-archive`) | Lightweight-first; the user must not have to memorize an extra command to start the next feature | A fully-automated lifecycle that closes handoffs based on tasks.md completion is out of scope; keep manual `complete` transition for now |
