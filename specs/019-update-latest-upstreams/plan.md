# Implementation Plan: Latest Spec Kit and Superpowers Alignment

**Branch**: `019-update-latest-upstreams` | **Date**: 2026-09-26 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/019-update-latest-upstreams/spec.md`

## Summary

Refresh the repository against Spec Kit v1.0.12 and Superpowers v6.4.2, update the bridge's upstream hook and execution-contract documentation, and publish the next verified bridge release. The implementation will copy only official Spec Kit-owned source changes into tracked bootstrap files, reapply the project's release/native-first gates, preserve the bridge protocol, and document Superpowers 6.4.2's execution-plan semantics without adding a competing planner.

## Technical Context

**Language/Version**: Bash >=4.0, Windows PowerShell 5.1+, Markdown/YAML/JSON; development CLI Spec Kit 1.0.12

**Primary Dependencies**: Spec Kit v1.0.12, Superpowers v6.4.2, jq >=1.6, GitHub CLI, existing bridge scripts and release tooling

**Storage**: Repository files: tracked Spec Kit sources/templates, project-owned bridge skills and extension manifests, handoff JSON, event JSONL, release metadata, verification records, deterministic ZIP

**Testing**: `bash tests/run-all.sh`, focused hook-contract and parity tests, `tests/test-release-powershell.ps1`, release-readiness self-tests/validator, package smoke, shell syntax/ShellCheck, canonical sibling sandbox, hosted macOS release gate

**Target Platform**: WSL/Linux bash, native Windows PowerShell 5.1+, macOS Bash >=4.0; Codex and Claude Code surfaces

**Project Type**: Spec Kit extension source repository with cross-platform shell scripts and Markdown orchestration

**Performance Goals**: Existing bridge commands remain under one second in normal repositories; no new runtime process or service

**Constraints**: Preserve three bridge commands, five registered bridge hooks, handoff v1 schema, guard rules, actor semantics, stable alias URL, and runtime floor >=0.8.10. Do not hand-edit vendor-generated agent skills. Do not add a parallel hook runner or planner.

**Scale/Scope**: Official git and agent-context source refresh, tracked spec/plan/tasks/checklist template placeholder refresh with project gates reapplied, bridge hook/execution wording in both peers and command, compatibility metadata/docs, focused regression coverage, release and sandbox evidence.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I. Lightweight & Repo-Local | Use official bundled sources and existing scripts; no daemon, service, database, or global bridge mechanism | PASS |
| II. Design/Implementation Separation | This spec, plan, and tasks are the only design contract; Superpowers executes these tasks and does not replace them | PASS |
| III. Agent-Neutral Protocol | Codex and Claude bridge peers remain identical in contract and differ only in invocation spelling | PASS |
| IV. Smooth Bidirectional Handoff | Existing v1 handoff, guard log, snapshots, and actor transitions remain unchanged | PASS |
| V. Vendor-Managed Boundaries | Refresh vendor-owned sources through Spec Kit; keep project-owned bridge skills and governance gates outside generated surfaces | PASS |
| VI. Native-First Compatibility | Spec Kit already owns hook execution/reporting and Superpowers already owns execution discipline; the bridge updates its contract wording and delegates to native skills without adding a runner or planner | PASS |

> **Release gate**: the new public ZIP will be installed from its published URL in `../test_specify_superpower` for each locally available platform before handoff completion; hosted macOS evidence will be labeled separately.
>
> **Native-First gate**: no new bridge surface is planned. The upstream hook parser/reporting and Superpowers execution skill remain upstream-owned; bridge changes are limited to compatibility wording, source refresh, tests, and metadata.

## Project Structure

### Documentation (this feature)

```text
specs/019-update-latest-upstreams/
├── spec.md
├── plan.md
├── research.md
├── quickstart.md
├── verification.md
├── contracts/
│   └── upstream-compatibility.md
└── tasks.md
```

### Source Code

```text
.specify/
├── extensions/git/                         # official v1.0.12 source refresh
├── extensions/agent-context/               # official v1.0.12 source refresh
├── templates/                              # upstream placeholders + project gates
└── extensions/speckit-superpowers-bridge/  # project-owned bridge and release metadata
.agents/skills/speckit-superpowers-bridge/SKILL.md
.claude/skills/speckit-superpowers-bridge/SKILL.md
README.md / README.zh-CN.md
CHANGELOG.md
marketplace/
tests/
.github/workflows/release.yml
```

**Structure Decision**: Keep the existing repository and extension package layout. Refresh only official upstream-owned files and restore project-owned bridge files after any installer collision. Compatibility evidence remains under the feature directory and version metadata remains in the existing release files.

## Phase 0: Research Decisions

See [research.md](research.md). The research records the official release tags and commits, Spec Kit v1.0.12 hook/parser and template changes, git/agent-context source changes, Superpowers v6.4.2 skill inventory and executing-plans semantics, and the selected bridge release version. All open technical questions are resolved before implementation.

## Phase 1: Design and Contracts

- [contracts/upstream-compatibility.md](contracts/upstream-compatibility.md) defines adopted upstream behavior, preserved bridge invariants, and evidence requirements.
- [quickstart.md](quickstart.md) defines bootstrap, focused regression, package, release, and sandbox checks.
- No data model is required because no persistent entity or schema changes.
- No new public command or state contract is introduced.

## Complexity Tracking

No constitution violations or added architectural surfaces.
