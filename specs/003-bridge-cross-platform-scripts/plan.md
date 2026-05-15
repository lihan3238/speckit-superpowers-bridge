# Implementation Plan: Bridge Cross-Platform Scripts — Cleanup Tail

**Branch**: `003-cross-platform-cleanup` | **Date**: 2026-05-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-bridge-cross-platform-scripts/spec.md` (redesign supersedes v0.4.0 draft preserved at commit `a4aa833`)

## Summary

v0.4.2 patch release closing the four open items left by v0.4.1: (B1) preserve prior `artifact_owner` in `update-handoff` on both flavors; (B2) make the cross-platform bash dispatch in the two extended smoke tests detect MSYS / WSL / native and translate paths correctly; (C1) sweep `tasks.md` of the original v0.4.0 spec to reflect ship state; (C4) gitignore the three install-time registry files and `git rm --cached` them. Plus the constitution v1.2.0 §"End-User Verification Sandbox" gate — first run, **mandatory P1**, covering Windows PowerShell + WSL Linux bash; macOS deferred (no hardware). Total expected diff: **~120 added lines, ~10 deleted, 5–6 commits**. Strict "compat only" — no new bridge capability, no schema changes, no workflow YAML edits.

## Technical Context

**Language/Version**: Same as v0.4.1.

- PowerShell 5.1+ on Windows, pwsh 7.x on Linux/macOS (test harness only on non-Windows).
- Bash ≥ 4.0 (MSYS git-bash on Windows for tests; WSL bash for Linux verification).

**Primary Dependencies**: All already required by v0.4.1.

- `jq ≥ 1.6` (still required for bash flavor; same conditional `required: false` on non-Windows in `extension.yml.requires.tools`).
- `cygpath` (NEW soft dependency — only invoked by the test harness, only on MSYS / Cygwin bash). Universally present in git-bash and Cygwin distributions; degrades to fallback strategies if absent.

**Storage**: No change. Same `.specify/superpowers-handoff.json` v1 schema, `.specify/bridge-events.jsonl` append-only log, `.specify/bridge-snapshots/<id>/` directories.

**Testing**: Same 3 retained smoke tests. Two of them (`test-handoff-shape.ps1`, `test-guard-hardcoded-rules.ps1`) get a small surgical edit to `Convert-ToBashPath`. NO new test files.

**Target Platform**:

- Windows 10+ (PowerShell 5.1) — primary dev box.
- WSL on Windows 10+ (Ubuntu, Claude Code installed inside) — Linux verification.
- macOS 13+ — **deferred, no hardware**.
- Linux native (Ubuntu/Debian/Fedora) — covered structurally by WSL verification; native run nice-to-have but not gating.

**Project Type**: Spec Kit extension package — same as v0.4.1. No layout change.

**Performance Goals**: No change. Each script ≤ 700 ms cold; not a hot path.

**Constraints**:

- **Strict "compat only"** — per spec FR-013, the bash and PowerShell scripts, build script, validator, workflow YAML, and test framework are all byte-frozen EXCEPT the surgical edits FR-001 and FR-003 require.
- Each modified file's diff target: ≤ 30 added lines per script edit.
- 5–6 commits per research.md §R5 commit-granularity plan.
- v0.4.2 cannot ship without Windows + WSL Linux sandbox PASS (per Clarifications Q1 + Q3).

**Scale/Scope**:

- 4 files surgically modified (update-handoff.ps1, update-handoff.sh, test-handoff-shape.ps1, test-guard-hardcoded-rules.ps1).
- 1 file modified non-surgically (tasks.md sweep — ~50 `[ ]` → `[x]` + ~17 (absorbed) annotations).
- 1 new file: `.gitignore` gains 3 lines. 3 files become git-untracked.
- 1 new spec artifact: `verification.md`.
- Release-cycle files (extension.yml, catalog-entry.json, CHANGELOG.md, README install URLs if any) bumped to 0.4.2.
- ~12–15 files touched in total.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Justification |
|-----------|--------|---------------|
| **I. Lightweight & Repo-Local** | ✅ PASS | Three surgical edits + a gitignore line + a verification.md file. No new runtime, no new persistent state, no new daemon. `jq` was already a dep; `cygpath` is universally bundled with bash environments that exist on Windows (git-bash, Cygwin, MSYS2). Zero new infrastructure. |
| **II. Design/Implementation Separation (NON-NEGOTIABLE)** | ✅ PASS | Bash and PowerShell stay locked. The B1 fix applies identical precedence logic in both flavors (FR-001's 4-step chain). The B2 fix is test-only — does not touch the production scripts. No spec contract changes. |
| **III. Agent-Neutral Protocol** | ✅ PASS | Protocol unchanged. `-Actor` flag semantics unchanged. The only "agent-touching" change is preserving prior `artifact_owner` on writes — which RESTORES protocol intent that drift broke. |
| **IV. Smooth Bidirectional Handoff** | ✅ PASS (strengthened) | The B1 fix directly restores Principle IV's intent — `artifact_owner` is part of the handoff state machine; silently mutating it on every write breaks rollback / cross-agent context discovery. The fix re-aligns implementation with principle. |
| **V. Vendor-Managed Boundaries** | ✅ PASS | All edits live under `.specify/extensions/speckit-superpowers-bridge/` (bridge-owned scripts) or repo-root config files (.gitignore, .gitattributes already-existing). Zero edits to officially generated `.claude/skills/speckit-*` or `.agents/skills/speckit-*`. |

**Gate result**: PASS. No Complexity Tracking entries needed.

### Post-Design Re-Check

After writing `research.md`, `data-model.md`, `contracts/verification-record.md`, `contracts/bash-cli-contract.md` (un-staled, no content change), `quickstart.md`, and confirming CLAUDE.md plan pointer:

| Principle | Post-design status | Notes |
|-----------|--------------------|-------|
| **I. Lightweight & Repo-Local** | ✅ STILL PASS | Phase 1 artifacts add zero runtime surface. The new `verification.md` is a design-time markdown file; the new `contracts/verification-record.md` is documentation pinning that file's row schema. Nothing executable added. |
| **II. Design/Implementation Separation** | ✅ STILL PASS | The bash + PS flavors stay locked per data-model.md Entity A. research.md R1's 4-step precedence chain applies identically to both flavors. No spec contract changes. |
| **III. Agent-Neutral Protocol** | ✅ STILL PASS | Protocol unchanged. The verification record records the operator (`claude`/`codex`/`human`) but does not branch logic on it. |
| **IV. Smooth Bidirectional Handoff** | ✅ STILL STRENGTHENED | The B1 fix restoration of `artifact_owner` preservation is, per data-model.md Entity A, a direct enforcement of Principle IV's intent (the handoff state machine must reflect who owns what). Quickstart Step 1 demonstrably exercises the preservation invariant. |
| **V. Vendor-Managed Boundaries** | ✅ STILL PASS | Phase 1 artifacts add files under `specs/003-…/` (this feature's dir). No `.claude/skills/speckit-*` or `.agents/skills/speckit-*` edits beyond the bridge's own peer skills (which themselves are NOT touched by this feature). |

**Re-check verdict**: PASS. Phase 1 introduces no new complexity, no new infrastructure, and no new constitutional risk. Ready for `/speckit-tasks`.

## Project Structure

### Documentation (this feature)

```text
specs/003-bridge-cross-platform-scripts/
├── plan.md              # This file (/speckit-plan output)
├── spec.md              # /speckit-specify + /speckit-clarify output (redesign, 3 clarifications integrated)
├── research.md          # Phase 0 output (5 R-decisions resolving plan-level flags)
├── data-model.md        # Phase 1 output (2 entities: ownership precedence chain + verification record)
├── quickstart.md        # Phase 1 output (8-step verification gate)
├── contracts/
│   ├── bash-cli-contract.md       # PRE-EXISTING from v0.4.0, still valid; STALE banner removed
│   └── verification-record.md     # NEW — schema for verification.md
├── checklists/
│   └── requirements.md  # /speckit-specify output (5 sanity flags resolved by /clarify + plan)
├── verification.md      # NEW — created during US4 sandbox run; appended per platform
└── tasks.md             # /speckit-tasks output (NOT created by /speckit-plan)
```

### Post-implementation repository layout (the surfaces this feature edits)

```text
codex_specify_superpower/
├── .gitignore                                  # +3 lines (FR-006)
│
├── .specify/extensions/speckit-superpowers-bridge/
│   ├── extension.yml                           # version → 0.4.2 (FR-010)
│   └── scripts/
│       ├── powershell/
│       │   └── update-handoff.ps1              # +B1 4-step ownership precedence (FR-001)
│       └── bash/
│           └── update-handoff.sh               # +B1 same precedence (FR-001)
│
├── tests/
│   ├── test-handoff-shape.ps1                  # +B2 multi-strategy Convert-ToBashPath (FR-003)
│   ├── test-guard-hardcoded-rules.ps1          # +B2 same (FR-003)
│   └── test-claude-codex-skill-parity.ps1      # UNCHANGED
│
├── marketplace/
│   ├── catalog-entry.json                      # version + download_url → 0.4.2 (FR-010)
│   └── extension-submission-body.md            # +v0.4.2 SHA256 + URL (FR-014)
│
├── CHANGELOG.md                                # new [0.4.2] section (FR-011)
├── README.md                                   # ONLY IF install URL is updated; otherwise UNCHANGED
├── README.zh-CN.md                             # mirror
├── AGENTS.md                                   # +1 short paragraph about install-time registries (FR-007)
│
├── specs/003-bridge-cross-platform-scripts/
│   ├── tasks.md (old v0.4.0 file)              # sweep ~50 [x] + ~17 (absorbed) (FR-005)
│   └── verification.md (NEW)                   # first 3 platform rows for v0.4.2 (FR-009)
│
└── (UNTRACKED after FR-006 commit:)
    ├── .specify/workflows/workflow-registry.json
    ├── .specify/workflows/*/workflow.yml          # 2 files: speckit + speckit-superpowers
    └── .specify/extensions/.registry
```

**Files NOT touched**:

- `specs/001-…` through `specs/006-…` (excluding this feature's own dir) — byte-identical per SC-009.
- All 4 `.specify/extensions/speckit-superpowers-bridge/scripts/{powershell,bash}/*` files EXCEPT update-handoff — frozen per FR-013.
- `.specify/extensions/speckit-superpowers-bridge/commands/*.md` — flavor-agnostic; no change.
- `.github/workflows/release.yml` — no change per FR-021 (which is now spec FR-021 → SC-008 for this feature).
- `.specify/memory/constitution.md` — no further amendment in this feature (v1.2.0 stands).
- `scripts/release/{build-extension-zip,validate-release-readiness,test-validate-release-readiness}.ps1` — frozen per FR-013.

**Structure Decision**: Surgical edit pattern, no new directories. Mirror Spec Kit's own convention of "patch releases touch the minimum surface".

## Complexity Tracking

No constitution violations.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | (n/a) | (n/a) |
