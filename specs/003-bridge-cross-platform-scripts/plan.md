# Implementation Plan: Bridge Cross-Platform Scripts

**Branch**: `003-bridge-cross-platform-scripts` | **Date**: 2026-05-15 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/003-bridge-cross-platform-scripts/spec.md`

## Summary

Add four bash scripts (`update-handoff.sh`, `guard-command.sh`, `auto-archive-handoff.sh`, `common-actor-resolution.sh`) under `.specify/extensions/speckit-superpowers-bridge/scripts/bash/`, functionally equivalent to the existing four PowerShell scripts. Ship them in the same release ZIP alongside `scripts/powershell/`. Add `.gitattributes` to enforce LF line endings for `*.sh` files. Update the validator to verify PS/bash file-count parity. Update README + CHANGELOG. Bump to v0.4.0. Total expected diff: ~400 added lines (4 bash scripts ~80 lines each + .gitattributes ~10 lines + validator extension ~15 lines + build-script line + README/CHANGELOG/extension.yml edits). Zero PowerShell script edits — strict "compat only" per the user directive.

## Technical Context

**Language/Version**:

- PowerShell 5.1+ on Windows / PowerShell 7.x on macOS/Linux (existing surface, frozen).
- Bash ≥ 4.0 (new surface). Bash 3.x on stock macOS is NOT supported — macOS users install bash 5.x via Homebrew. (System bash 3.2 lacks `mapfile`, `${var^^}`, etc.) Required tools entry mandates `bash >= 4.0`.

**Primary Dependencies**:

- `jq >= 1.6` — used by bash scripts for JSON read/write of `superpowers-handoff.json`. Already used by Spec Kit's own git extension (`create-new-feature.sh`).
- `coreutils` (Linux/macOS) — `date -u`, `mkdir -p`, `cp -r`, `mv`, `printf`, `cat`. All standard.
- No new dependencies for the test suite — tests stay pwsh.

**Storage**: Same filesystem state as v0.3.1. `.specify/superpowers-handoff.json` (v1 shape), `.specify/bridge-events.jsonl` (append-only), `.specify/bridge-snapshots/<id>/`. Bash scripts read/write these via `jq` + `printf`/`cat >>`.

**Testing**: Same 3 pwsh smoke tests under `tests/`, extended with a `Get-AvailableFlavors` helper that auto-detects which script flavors exist and iterates over them. No new test files; no bash test files. Tests run under pwsh on Windows / Linux / macOS.

**Target Platform**:

- Windows 10+ (PowerShell 5.1)
- Linux (Ubuntu 22.04+, Debian 12+, Fedora 40+; bash 4+ + jq)
- macOS 13+ (with Homebrew bash 5+ + jq)
- WSL on Windows — covered by the Linux path.

**Project Type**: Spec Kit extension package — same as v0.3.1. Layout unchanged except `scripts/` directory now has a `bash/` peer to `powershell/`.

**Performance Goals**:

- Each bash script completes in ≤ 700 ms cold (PowerShell baseline is ≤ 500 ms; bash + `jq` is slightly slower per invocation but within an acceptable user-perceived delta).
- Not a hot path.

**Constraints**:

- **Strict "compat only"** — no behavior change beyond OS reach. PS scripts not edited.
- Each bash script ≤ 100 lines (PS counterparts: 41–189 lines; bash should match or be smaller because it lacks PS's parameter validation ceremony).
- Total bash-script lines ≤ 350 (target ≤ 250 if jq + careful shell composition allows).
- 3 retained tests stay at 3 files. Validator file-count check enforces this.
- Single release ZIP, both flavors inside.
- Workflow YAML at `.github/workflows/release.yml` does NOT change (FR-021).
- `.gitattributes` exists at repo root with `*.sh text eol=lf` (FR-020).

**Scale/Scope**:

- 4 new bash scripts.
- 1 new repo-root file (`.gitattributes`).
- Modified: `extension.yml`, `scripts/release/build-extension-zip.ps1`, `scripts/release/validate-release-readiness.ps1`, `scripts/release/test-validate-release-readiness.ps1`, 3 `tests/*.ps1` files, `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, `marketplace/catalog-entry.json`, `marketplace/upstream-pr-body.md`.
- ~14 files touched total. Net add ~400 lines, delete ~0 lines.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Justification |
|-----------|--------|---------------|
| **I. Lightweight & Repo-Local** | ✅ PASS | No new runtime, daemon, or service. Bash scripts are repo-local files alongside the existing PowerShell scripts. The only new tool the user might need to install is `jq` — already an established Spec Kit ecosystem dependency (used by `git` extension). Marketplace packaging shape unchanged. |
| **II. Design/Implementation Separation (NON-NEGOTIABLE)** | ✅ PASS | Bash `guard-command.sh` implements the same 5 hardcoded rules as the PS version. Same denylist: `speckit.implement` blocked during executing, `superpowers:writing-plans`/`:brainstorming` blocked when artifacts exist, `speckit.constitution` blocked during executing. |
| **III. Agent-Neutral Protocol** | ✅ PASS (strengthened) | This feature literally extends the protocol's reach to Linux/macOS agents. Both Codex and Claude Code on those OSes can now invoke the bridge. `--actor codex\|claude\|unknown` flag mirrors PS `-Actor`. |
| **IV. Smooth Bidirectional Handoff** | ✅ PASS | Bash scripts write the same v1 handoff JSON shape (verified by extended `tests/test-handoff-shape.ps1` auto-detecting both flavors and asserting). Snapshot directory layout identical. `bridge-events.jsonl` append shape identical. Backward read of v2/v3 still works (FR-005 carries forward FR-009 from feature 006). |
| **V. Vendor-Managed Boundaries** | ✅ PASS | New bash scripts live under `.specify/extensions/speckit-superpowers-bridge/scripts/bash/` (bridge-owned). NO edit to officially-generated `.claude/skills/speckit-*` or `.agents/skills/speckit-*` files outside the bridge's own peers (which are bridge-owned, not vendor). |

**Gate result**: PASS. No Complexity Tracking entries needed.

### Post-Design Re-Check

After writing `research.md`, `data-model.md`, `contracts/bash-cli-contract.md`, `quickstart.md`, and the CLAUDE.md pointer update:

| Principle | Post-design status | Notes |
|-----------|--------------------|-------|
| **I. Lightweight & Repo-Local** | ✅ STILL PASS | Phase 1 artifacts add no new runtime, no new persistent state, no new global tooling. `jq` and `bash` are user-installed prereqs (clearly marked `required: false` for non-Windows in `extension.yml`) — they don't constitute "new infrastructure" any more than `git` did. |
| **II. Design/Implementation Separation** | ✅ STILL PASS | The 5 hardcoded guard rules are mirrored exactly by `guard-command.sh` per contracts/bash-cli-contract.md. Data-model §1 confirms the v1 handoff schema is unchanged. Quickstart Step 5 exercises both flavors against the same rule assertions. |
| **III. Agent-Neutral Protocol** | ✅ STILL STRENGTHENED | This feature literally extends Principle III's reach to Linux/macOS agents. `--actor` long-flag mirrors PS `-Actor` (contracts table). No agent-specific divergence. |
| **IV. Smooth Bidirectional Handoff** | ✅ STILL PASS | Bash flavor writes the same v1 shape (data-model §1 parity contract); reads tolerate v2/v3 unknown fields (research.md R7); snapshots before write (research.md R7); appends to events.jsonl with same fields (data-model §2). All four legs of the handoff state machine preserved. |
| **V. Vendor-Managed Boundaries** | ✅ STILL PASS | Phase 1 artifacts are added under `specs/003-…/` (this feature's directory). No edits to officially generated `.claude/skills/speckit-*` or `.agents/skills/speckit-*` files. The bridge's own SKILL.md peers remain unchanged in this feature; their content is flavor-agnostic. |

**Re-check verdict**: PASS. No new complexity introduced by Phase 1 artifacts. Ready for `/speckit-tasks`.

## Project Structure

### Documentation (this feature)

```text
specs/003-bridge-cross-platform-scripts/
├── plan.md              # This file (/speckit-plan output)
├── spec.md              # /speckit-specify + /speckit-clarify output (existing)
├── research.md          # Phase 0 output (/speckit-plan)
├── data-model.md        # Phase 1 output (/speckit-plan)
├── quickstart.md        # Phase 1 output (/speckit-plan)
├── contracts/
│   └── bash-cli-contract.md   # Argument/exit-code parity contract between PS and bash
├── checklists/
│   └── requirements.md  # /speckit-specify output (5 sanity flags resolved by /clarify)
└── tasks.md             # /speckit-tasks output (NOT created by /speckit-plan)
```

### Post-implementation repository layout

```text
codex_specify_superpower/
├── .github/workflows/release.yml          # UNCHANGED — already cross-platform per v0.3.1
├── .gitattributes                         # NEW (FR-020)
│
├── .specify/
│   └── extensions/speckit-superpowers-bridge/
│       ├── extension.yml                  # version → 0.4.0; requires.tools list refined
│       └── scripts/
│           ├── powershell/                # 4 .ps1 files UNCHANGED (FR-002 byte-frozen)
│           │   ├── auto-archive-handoff.ps1
│           │   ├── common-actor-resolution.ps1
│           │   ├── guard-command.ps1
│           │   └── update-handoff.ps1
│           └── bash/                      # NEW directory (FR-001)
│               ├── auto-archive-handoff.sh
│               ├── common-actor-resolution.sh
│               ├── guard-command.sh
│               └── update-handoff.sh
│
├── scripts/release/
│   ├── build-extension-zip.ps1            # +1 Copy-Item line for scripts/bash
│   ├── validate-release-readiness.ps1     # +file-count parity check + .gitattributes check
│   └── test-validate-release-readiness.ps1 # extended with cases for the new checks
│
├── tests/                                 # STILL 3 files (FR-012 of feature 006 holds)
│   ├── test-handoff-shape.ps1             # extended: Get-AvailableFlavors + per-flavor loop
│   ├── test-guard-hardcoded-rules.ps1     # extended: same helper + per-flavor loop
│   └── test-claude-codex-skill-parity.ps1 # UNCHANGED — peer parity check is shell-agnostic
│
├── marketplace/
│   ├── catalog-entry.json                 # version → 0.4.0; download_url → v0.4.0 ZIP
│   └── upstream-pr-body.md                # "since v0.3.1" framing
│
├── README.md                              # cross-platform install section
├── README.zh-CN.md                        # bilingual mirror; H2 anchors preserved
└── CHANGELOG.md                           # new [0.4.0] section
```

**Files NOT touched by this feature**:

- `specs/001-…` through `specs/006-…` directories (SC-006: byte-identical).
- All 3 of `.specify/extensions/speckit-superpowers-bridge/commands/*.md` — flavor-agnostic prose.
- `.claude/skills/speckit-superpowers-bridge/SKILL.md` and `.agents/skills/speckit-superpowers-bridge/SKILL.md` — flavor selection is Spec Kit's `init-options.json.script` job.

**Structure Decision**: Mirror Spec Kit's first-party `.specify/extensions/git/scripts/{bash,powershell}/` convention. Bash scripts sit as siblings of PowerShell scripts under the same parent.

## Complexity Tracking

No constitution violations.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none) | (n/a) | (n/a) |
