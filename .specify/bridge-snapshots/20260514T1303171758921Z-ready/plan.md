# Implementation Plan: Spec Kit Superpowers Bridge

**Branch**: `001-spec-superpowers-bridge` | **Date**: 2026-05-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-spec-superpowers-bridge/spec.md`

**Planning Constraint**: Prefer the smallest repo-local change set that makes the bridge usable quickly, while preserving the full ownership boundary, guard, log, rollback, and Codex/Claude Code compatibility requirements.

## Summary

Formalize the existing Spec Kit + Superpowers bridge prototype into a minimal local extension protocol. Spec Kit remains the source of truth for `spec.md`, `plan.md`, `tasks.md`, checklists, and analysis. Superpowers remains the implementation discipline after handoff. The current prototype already includes the extension, handoff/guard commands, event log, snapshot rollback, Codex bridge skill, and basic AGENTS rules; the plan focuses on closing the smallest gaps for Claude Code compatibility, explicit command syntax, vendor-managed official skills, and single-writer Spec Kit artifact ownership.

## Technical Context

**Language/Version**: PowerShell scripts, Markdown skills/docs, YAML workflows, JSON state files; Spec Kit `0.8.9` locally installed  
**Primary Dependencies**: Spec Kit local extension format, Codex integration skills under `.agents/skills`, Claude Code integration skills under `.claude/skills`, Superpowers skills in the agent runtime  
**Storage**: Repository files only: `.specify/superpowers-handoff.json`, `.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/`, `AGENTS.md`, `CLAUDE.md`, bridge skill files  
**Testing**: PowerShell smoke tests, JSON/YAML parse checks, guard decision tests, snapshot restore test, manual Codex/Claude context discovery checks  
**Target Platform**: Windows-first Spec Kit workspace using PowerShell; repo-local protocol usable by Codex and Claude Code  
**Project Type**: Local Spec Kit extension plus agent skills/protocol files  
**Performance Goals**: Guard command completes in under 1 second for normal feature artifact sets; handoff creation remains under 2 minutes after tasks generation; snapshot restore remains under 1 minute for Spec Kit control artifacts  
**Constraints**: Do not edit global Superpowers plugin cache; do not hand-edit official generated `.agents/skills/speckit-*` or `.claude/skills/speckit-*`; keep `speckit.implement` installed but blocked by guard; avoid a marketplace package in v1  
**Scale/Scope**: One active feature handoff per repository; Codex and Claude Code integrations may both be installed; only one agent owns Spec Kit artifact writes at a time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The current constitution file is still the generated template and does not define enforceable project-specific gates. No concrete constitution violation is present. This plan treats the feature spec as the controlling contract and keeps complexity low by adding repo-local files and small extensions to existing scripts instead of introducing a new runtime, service, or global plugin modification.

Post-design check: PASS. The design uses existing repo structure, keeps official integrations vendor-managed, and adds only local bridge protocol artifacts.

## Project Structure

### Documentation (this feature)

```text
specs/001-spec-superpowers-bridge/
|-- spec.md
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- agent-context-contract.md
|   |-- guard-command-contract.md
|   |-- handoff.schema.json
|   `-- workflow-contract.md
`-- tasks.md
```

### Source Code (repository root)

```text
.specify/
|-- extensions.yml
|-- integration.json
|-- superpowers-handoff.json
|-- bridge-events.jsonl
|-- bridge-snapshots/
|-- extensions/
|   `-- speckit-superpowers-bridge/
|       |-- extension.yml
|       |-- commands/
|       |   |-- speckit.superpowers.guard.md
|       |   `-- speckit.superpowers.handoff.md
|       `-- scripts/
|           `-- powershell/
|               |-- guard-command.ps1
|               |-- restore-snapshot.ps1
|               |-- test-bridge-guard.ps1
|               `-- update-handoff.ps1
|-- integrations/
|   |-- codex.manifest.json
|   |-- claude.manifest.json
|   `-- speckit.manifest.json
`-- workflows/
    `-- speckit-superpowers/
        `-- workflow.yml

.agents/
`-- skills/
    `-- speckit-superpowers-bridge/
        `-- SKILL.md

.claude/
`-- skills/
    |-- speckit-*/              # official generated Spec Kit skills, vendor-managed
    `-- speckit-superpowers-bridge/
        `-- SKILL.md            # local bridge skill, not an official generated skill

AGENTS.md
CLAUDE.md
```

**Structure Decision**: Keep the extension, guard scripts, and workflow in `.specify/`; keep agent-specific bridge skills beside each integration's skill directory; keep shared rules in `AGENTS.md` and only Claude-specific invocation/import guidance in `CLAUDE.md`.

## Design Decisions

1. Use `AGENTS.md` as the master protocol and make `CLAUDE.md` import or explicitly reference it.
2. Treat Spec Kit command IDs and agent invocation syntax separately:
   - Internal command IDs remain dotted, for example `speckit.plan` and `speckit.superpowers.guard`.
   - Codex skill invocation uses `$speckit-plan`.
   - Claude Code skill invocation uses slash commands generated from skill names, for example `/speckit-plan`; hook command names with dots are rendered with hyphens by the official Claude integration.
3. Add a Claude bridge skill as a separate local skill under `.claude/skills/speckit-superpowers-bridge/` instead of modifying official `.claude/skills/speckit-*`.
4. Extend the handoff state minimally with artifact write ownership metadata so the guard can deny concurrent Spec Kit artifact writes.
5. Keep existing log and snapshot behavior; implementation source rollback remains Git/worktree responsibility.

## Minimal Implementation Scope

The fastest usable implementation should make these changes only:

- Add `.claude/skills/speckit-superpowers-bridge/SKILL.md` by adapting the existing Codex bridge skill for Claude invocation syntax.
- Update `CLAUDE.md` to require reading `AGENTS.md` first and to list Claude-specific command examples.
- Update `AGENTS.md` with the explicit Codex/Claude syntax mapping, official-skill vendor policy, and single-writer rule.
- Update bridge handoff/guard scripts to carry and enforce `artifact_owner`, `review_only_agents`, and optional `-Actor`.
- Update extension workflow metadata to allow either `codex` or `claude`.
- Update tests to cover Claude bridge skill presence, context files, command syntax mapping, and artifact ownership denial.

## Complexity Tracking

No constitution violations are required. The design avoids extra services, package publishing, or global plugin edits.
