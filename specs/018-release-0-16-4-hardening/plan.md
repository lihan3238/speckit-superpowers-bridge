# Implementation Plan: v1.2.0 Release Hardening and Upstream Alignment

**Branch**: `018-release-0-16-4-hardening` | **Date**: 2026-08-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/018-release-0-16-4-hardening/spec.md`

## Summary

Finish and publish bridge v1.2.0 after accepting PR #14. The release combines four bounded workstreams: (1) correct the implement-hook composition against Spec Kit 0.16.4's current mandatory-hook contract; (2) fix Issue #13 by replacing GNU-only `realpath -m` calls with portable, symlink-aware path normalization inside the existing bash handoff script; (3) refresh the repository's tracked Spec Kit templates, git/agent-context extension sources, generated-state policy, and documentation to the 0.16.4 baseline while preserving project-owned gates and skill peers; and (4) audit Superpowers 6.3.0, run cross-platform and release-sandbox verification, then publish and close the issue. Bridge version remains 1.2.0 because PR #14 already selected the unreleased MINOR version.

## Technical Context

**Language/Version**: Bash >=4.0 for the bridge bash flavor (tested on WSL2 Bash 5.2 and macOS-hosted Bash), Windows PowerShell 5.1 for the PowerShell flavor, Markdown/YAML/JSON for command and release metadata

**Primary Dependencies**: Spec Kit CLI 0.16.4 for development/bootstrap; bridge runtime floor `>=0.8.10` retained pending compatibility audit; Superpowers 6.3.0 verified source baseline; `jq >=1.6`; portable `readlink` plus shell built-ins for path normalization

**Storage**: Flat repository files: handoff JSON, append-only event JSONL, Spec Kit artifacts, extension manifests, Markdown command/skill files, deterministic ZIP release artifact

**Testing**: `bash tests/run-all.sh` (target 8 tests), focused path/hook behavior tests, `tests/test-release-powershell.ps1`, release-readiness self-tests, shell syntax/lint where available, GitHub-hosted macOS source regression, canonical sibling release sandbox on WSL2 Linux and native Windows PowerShell

**Target Platform**: Linux bash, native Windows PowerShell 5.1+, and macOS with Bash >=4.0; Codex and Claude Code agent surfaces remain behaviorally identical

**Project Type**: Spec Kit extension source repository with cross-agent Markdown orchestration and small cross-platform shell scripts

**Performance Goals**: Path normalization and hook filtering remain negligible relative to agent execution; handoff/status commands complete in under one second in normal local repositories

**Constraints**: No new bridge command, hook, state file, schema field, guard rule, custom hook runner, daemon, or runtime dependency; preserve `download_url` stable alias, 3 command / 5 hook counts, handoff v1 schema, actor semantics, and runtime floor unless the audit disproves compatibility

**Scale/Scope**: One bash runtime script, both project-owned bridge skill peers and execute command, 1-2 focused tests, Spec Kit tracked bootstrap sources/templates, release metadata/docs, CI release gate, and feature verification records

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Lightweight & Repo-Local | Replace six non-portable calls with one helper inside the existing script; no new runtime or service | PASS |
| II. Design/Implementation Separation | This plan and the generated `tasks.md` remain the only implementation contract; no Superpowers planning artifact replaces them | PASS |
| III. Agent-Neutral Protocol | Execute command plus both project-owned skill peers receive the same hook contract; actor and invocation differences remain explicit | PASS |
| IV. Smooth Bidirectional Handoff | Handoff schema and transitions remain intact; completion moves only after mandatory post-hooks succeed | PASS |
| V. Vendor-Managed Boundaries | Core generated skills are refreshed through Spec Kit, never hand-edited; the project-owned short bridge peers are restored after installer collision | PASS |
| VI. Native-First Compatibility | Spec Kit 0.16.4 still dispatches core-command extension hooks through command instructions; `specify event run` serves agent-native runtime events and does not emit `before_implement` / `after_implement`. The bridge therefore composes the native hook contract rather than adding a runner. The macOS bug exists in bridge-owned code and cannot be fixed upstream | PASS |

> **Release gate** (constitution §"End-User Verification Sandbox"):
> v1.2.0 ships a release artifact. The public ZIP must be installed from its
> release URL in `../test_specify_superpower` (Windows spelling:
> `..\test_specify_superpower`) and complete locally available platform cycles
> before handoff completion. Native macOS hardware is unavailable locally, so
> macOS evidence is a hosted source/runtime regression and is not described as
> a local published-artifact sandbox run.
>
> **Native-First gate** (constitution Principle VI):
> (1) Does upstream already dispatch these hooks? Yes, but only inside each core
> command's agent instructions; the bridge replaces `speckit.implement`, so it
> must compose that existing contract. (2) Is upstream the right place to fix
> the missing bridge dispatch or bridge-owned GNU path call? No. The bridge owns
> both integration points. No new parallel hook engine is introduced.

### Post-Design Re-check

The selected design keeps all changes inside existing bridge/script/template surfaces, adds only regression tests and CI coverage, and preserves protocol/schema/guard invariants. No Complexity Tracking entry is required.

## Project Structure

### Documentation (this feature)

```text
specs/018-release-0-16-4-hardening/
├── spec.md
├── plan.md
├── research.md
├── quickstart.md
├── verification.md
├── contracts/
│   ├── implement-hook-dispatch.md
│   └── portable-path-normalization.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

No `data-model.md` is required: the release changes behavior over existing handoff/hook entities and introduces no persistent data entity or schema.

### Source Code (repository root)

```text
.specify/
├── .gitignore                                             # new 0.16.1+ managed local-state ignore policy
├── extensions.yml                                        # refreshed hook metadata
├── extensions/git/                                       # exact 0.16.4 bundled source refresh
├── extensions/agent-context/                             # exact 0.16.4 bundled source refresh
├── extensions/speckit-superpowers-bridge/
│   ├── commands/speckit.speckit-superpowers-bridge.execute.md
│   ├── scripts/bash/update-handoff.sh
│   └── verified-versions.json
└── templates/                                            # latest upstream content + project-owned release/native-first gates
.agents/skills/speckit-superpowers-bridge/SKILL.md
.claude/skills/speckit-superpowers-bridge/SKILL.md
.github/workflows/release.yml                             # macOS source/runtime gate
.gitignore
AGENTS.md
README.md / README.zh-CN.md
CHANGELOG.md
marketplace/
tests/
└── test-update-handoff-portability.sh                    # new behavior-focused regression
```

**Structure Decision**: Keep the existing single-repository extension layout. Refresh upstream-owned Spec Kit sources from the official 0.16.4 tag, then reapply only documented project-owned deltas. The portable path helper stays private to `update-handoff.sh` because no other bridge script needs missing-path canonicalization.

## Phase 0: Research Decisions

See [research.md](research.md). All unknowns are resolved: the native event subsystem does not replace command lifecycle hooks; a component-wise `readlink` normalizer preserves `realpath -m` semantics without GNU coreutils; the bundled git/agent-context sources have material 0.16.4 updates; and all bridge-invoked Superpowers skill names remain present in 6.3.0.

## Phase 1: Design and Contracts

- [portable-path-normalization.md](contracts/portable-path-normalization.md) defines absolute normalization, symlink handling, missing components, repository-relative rendering, and failure behavior.
- [implement-hook-dispatch.md](contracts/implement-hook-dispatch.md) defines filtering, standard directives, actual invocation, ordering, and failure-state rules.
- [quickstart.md](quickstart.md) defines reproducible local, hosted, sandbox, and release checks.
- No new data model or public API contract is introduced.

## Complexity Tracking

No constitution violations or added architectural surfaces.
