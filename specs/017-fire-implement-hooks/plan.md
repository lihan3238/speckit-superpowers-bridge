# Implementation Plan: Fire speckit.implement before/after hooks from the bridge

**Branch**: `017-fire-implement-hooks` | **Date**: 2026-08-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/017-fire-implement-hooks/spec.md`

## Summary

Minor release **v1.2.0**: make the bridge fire Spec Kit's `before_implement` /
`after_implement` extension hooks so it is a true plug-and-play drop-in for
`speckit.implement`. The bridge's `execute` command and both per-agent `SKILL.md`
peers gain markdown instructions (mirroring Spec Kit's own `implement` command)
that read `.specify/extensions.yml`, filter hooks, and dispatch them — with one
bridge-specific rule: **skip the bridge's own hooks** (`extension` is
`speckit-superpowers-bridge`) so it never fires its own `before_implement`
guard and self-blocks. No new command, hook, script, or state file — the
dispatch is instruction-only (constitution Principle VI). A new smoke test
asserts the dispatch contract; the suite grows 6 → 7 tests.

## Technical Context

**Language/Version**: Bash 5.2 (smoke suite), PowerShell 5.1 (parity flavor, untouched), Markdown (execute.md + SKILL.md), YAML/JSON metadata

**Primary Dependencies**: Spec Kit CLI (dev 0.9.2, runtime floor `>=0.8.10` unchanged), jq >=1.6, gh CLI; Superpowers 6.0.0 (unchanged baseline)

**Storage**: N/A (flat files; no new state — dispatch is instruction-only)

**Testing**: `bash tests/run-all.sh` (7 smoke tests incl. new `test-implement-hooks-dispatch.sh`); end-user sandbox in `../test_specify_superpower` (published-artifact cycle deferred to release/tag)

**Target Platform**: Linux bash (WSL2 primary), Windows PowerShell 5.1+ (unchanged bytes)

**Project Type**: Spec Kit extension (CLI-installed docs/scripts package)

**Performance Goals**: N/A (no runtime code paths change)

**Constraints**: No new bridge script/state file; handoff v1 schema, guard rules, actor semantics, command count (3), hook count (5), and `download_url` unchanged; dispatch mirrors Spec Kit's `implement` command

**Scale/Scope**: 3 instruction files edited (execute.md + 2 SKILL peers), 1 new test, 7 release-bump files, plus `specs/017-*/` artifacts

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Lightweight & Repo-Local | Instruction-only dispatch; no new script, runtime, or state file | PASS |
| II. Design/Implementation Separation | Hooks are Spec Kit-owned surface; the bridge composes them at the same lifecycle points as `speckit.implement` | PASS |
| III. Agent-Neutral Protocol | Both `.claude`/`.agents` SKILL peers updated identically; hook commands rendered per agent | PASS |
| IV. Smooth Bidirectional Handoff | Handoff schema/flow unchanged; hooks slot in at existing `executing`/`complete` transitions | PASS |
| V. Vendor-Managed Boundaries | No edits to generated `speckit-*` skills; only bridge-owned `execute.md` + SKILL peers | PASS |
| VI. Native-First Compatibility | **The point of this feature.** Q1 "does upstream already do this?" — yes, Spec Kit's `implement` command fires these hooks via markdown. Q2 "is upstream the right place?" — yes for the mechanism; the bridge reuses it rather than adding a script. The only bridge-specific addition is the skip-own-guard rule, which exists because the bridge's guard is a bridge-specific concern | PASS |

> **Native-First gate** (constitution §"VI", v1.3.0+): This feature adds a new
> *convention* (the bridge fires implement hooks), which is why it is a MINOR
> bump rather than patch-tier. The convention is implemented by reusing Spec
> Kit's own markdown-driven hook mechanism (not a new runner), so no new script,
> command, hook, or state file enters the surface. Nothing enters Complexity
> Tracking.
>
> **Release gate** (constitution §"End-User Verification Sandbox", v1.2.0+):
> v1.2.0 ships a release artifact, so the published-artifact sandbox cycle is
> REQUIRED before the handoff transitions to `complete`. As in 016, the
> publish/tag step is deferred to the maintainer; this feature lands the in-repo
> change, runs the 7/7 smoke suite, and commits, but does not drive the handoff
> to `complete` this session.

## Project Structure

### Documentation (this feature)

```text
specs/017-fire-implement-hooks/
├── plan.md              # This file
├── spec.md              # Full-tier spec
├── research.md          # Spec Kit hook-mechanism audit (R1-R6)
├── quickstart.md        # Validation/run guide
├── verification.md      # Evidence record (filled during implementation)
├── checklists/
│   └── requirements.md  # Full-tier spec-quality checklist
└── tasks.md             # Implementation contract
```

No `data-model.md` / `contracts/`: no new entities or interfaces — the dispatch
is a documented convention over the existing `.specify/extensions.yml` hook
shape.

### Source Code (repository root)

```text
.specify/extensions/speckit-superpowers-bridge/
├── commands/speckit.speckit-superpowers-bridge.execute.md   # + hook dispatch sections
└── extension.yml                                            # version 1.1.0 → 1.2.0
.agents/skills/speckit-superpowers-bridge/SKILL.md           # + hook steps + section
.claude/skills/speckit-superpowers-bridge/SKILL.md           # + hook steps + section
tests/test-implement-hooks-dispatch.sh                       # NEW smoke test
CHANGELOG.md                                                 # [1.2.0] section
verified-versions.json                                       # bridge 1.2.0 + evidence
README.md / README.zh-CN.md                                  # v1.2.0 description + install example
marketplace/catalog-entry.json                               # version + updated_at
marketplace/extensions-readme-row.md                         # v1.2.0 support summary
marketplace/extension-submission-body.md                     # v1.2.0 baseline + catalog entry
```

**Structure Decision**: Single existing repo layout; all edits in place. The
dispatch is instruction-only (no new script), mirroring Spec Kit's own
`implement` command.

## Phasing

- **Phase 0 — Research** (`research.md`, done): confirm the hook mechanism is markdown-driven and identify the self-guard hazard.
- **Phase 1 — Dispatch contract**: add hook-dispatch sections to `execute.md` + both SKILL peers; add `test-implement-hooks-dispatch.sh`.
- **Phase 2 — Release bump**: extension.yml, catalog-entry.json, CHANGELOG, verified-versions.json, READMEs, marketplace files → 1.2.0.
- **Phase 3 — Verify**: `bash tests/run-all.sh` 7/7; record evidence in `verification.md` (sandbox-publish step deferred to release).

## Complexity Tracking

No constitution violations; table intentionally empty.
