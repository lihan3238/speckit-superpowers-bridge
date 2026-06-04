# Implementation Plan: v1.0.0 Stable Protocol Release Hardening

**Branch**: `013-v1-0-release-hardening` | **Date**: 2026-06-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/013-v1-0-release-hardening/spec.md`

**Note**: This plan keeps the bridge as a thin Spec Kit extension and release protocol. It improves release confidence, diagnostics, platform parity, and documentation without introducing a competing workflow engine.

## Summary

Prepare `speckit-superpowers-bridge` for a 1.0.0 stable protocol release. The implementation will synchronize version and marketplace metadata, harden release readiness validation, add or restore Windows PowerShell release smoke coverage, align the GitHub release workflow with the actual test inventory, record current upstream compatibility, document the product's lightweight positioning against community alternatives, and verify the packaged bridge in the sibling end-user sandbox with Linux bash, Windows PowerShell, real Codex, and real Claude Code evidence. Existing guard, handoff, execute, status, and archive semantics remain the runtime foundation.

## Technical Context

**Language/Version**: Bash 5.x-compatible scripts, Windows PowerShell 5.1+ scripts, Markdown documentation, YAML/JSON metadata, GitHub Actions workflow YAML

**Primary Dependencies**: Spec Kit CLI 0.9.3 verification target; Superpowers 5.1.0 verification target; Codex CLI 0.137.0 verification target; Claude Code 2.1.162 verification target; `git`; `jq`; `gh`; `zip`/PowerShell compression through existing release scripts; optional `vhs`, `ttyd`, and `ffmpeg` only for regenerated GIFs

**Storage**: Repo-local files only: `.specify/extensions/speckit-superpowers-bridge/*`, `scripts/release/*`, `.github/workflows/release.yml`, `tests/*`, `docs/*`, `marketplace/*`, `specs/013-v1-0-release-hardening/*`, and generated release artifacts under `dist/` during verification

**Testing**: Existing `bash tests/run-all.sh`; new/repaired release-readiness self-tests; Windows PowerShell smoke tests for bridge scripts; package inspection tests; sandbox install verification in `../test_specify_superpower`; bounded real `codex` and `claude` verification records

**Target Platform**: Windows PowerShell 5.1+ native path and Linux bash path are mandatory first-class release targets. WSL bash may satisfy Linux bash evidence but not Windows evidence.

**Project Type**: Repo-local Spec Kit community extension with bridge-owned skills, scripts, release tooling, documentation, and marketplace metadata

**Performance Goals**: Existing smoke suite remains fast enough for local release use; readiness/status checks complete in seconds; release readiness validation fails early on metadata/package issues; sandbox and real-agent verification may be slower but must produce explicit evidence

**Constraints**: No daemon, service, database, custom DSL, independent lifecycle state machine, parallel task runner, or global plugin mutation. No hand edits to vendor-managed generated Spec Kit skills. Preserve backward-compatible handoff reads from the 0.7.2 baseline. Any new readiness capability must be lightweight and may extend existing status/release validation surfaces.

**Scale/Scope**: One major release hardening feature across release metadata, validators, tests, docs, marketplace material, sandbox verification records, and optional demo refresh. Runtime bridge semantics should change only where needed for readiness diagnostics or release validation.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Lightweight & Repo-Local

Pass. The plan changes repo-local scripts, tests, docs, metadata, and evidence files only. It does not add any runtime service, daemon, database, installer service, or global plugin mutation.

### II. Design/Implementation Separation

Pass. Spec Kit remains owner of design artifacts. Superpowers remains owner of implementation discipline. The 1.0.0 work improves release gates and diagnostics; it does not let Superpowers replace `spec.md`, `plan.md`, or `tasks.md`.

### III. Agent-Neutral Protocol

Pass with required evidence. Codex and Claude Code must both have bounded sandbox verification records. Actor-specific syntax remains documented while the protocol behavior stays the same.

### IV. Smooth Bidirectional Handoff

Pass. Existing handoff, guard, archive, event log, and status semantics remain the bridge state contract. Readiness diagnostics may inspect them but must not create a second source of truth.

### V. Vendor-Managed Boundaries

Pass. No generated `.agents/skills/speckit-*` or `.claude/skills/speckit-*` files are in scope. Bridge-owned `speckit-superpowers-bridge` skills may be updated only to reflect actual 1.0.0 behavior.

### VI. Native-First Compatibility

Pass with explicit answers:

- Does upstream Spec Kit, Superpowers, Codex, or Claude already do this? Partially. Upstreams provide native workflows, skills, hooks, subagents, and command execution. They do not provide this bridge's release-specific namespace/package validation, cross-platform bridge smoke matrix, or project-specific marketplace evidence.
- Is upstream the right place to fix this? No for bridge release readiness and package verification, because the checks are specific to this repository's extension id, command namespace, ZIP layout, marketplace material, and Windows/Linux support claim. Yes for general agent orchestration, TDD discipline, subagents, dynamic workflows, and implementation planning; therefore this plan delegates those areas and does not recreate them.

### Release Gate

Pass with required tasks. Because this feature ships a release artifact, the plan requires end-user sandbox verification in `../test_specify_superpower` before completion. Both Linux bash and Windows PowerShell rows must be recorded. Published release URL verification happens after tag publication; before publication, the same checks may run against a release-equivalent packaged artifact and then be repeated or confirmed against the published asset.

## Project Structure

### Documentation (this feature)

```text
specs/013-v1-0-release-hardening/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── readiness-report-contract.md
│   ├── release-readiness-contract.md
│   └── verification-evidence-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
.github/workflows/
└── release.yml

.specify/extensions/speckit-superpowers-bridge/
├── extension.yml
├── verified-versions.json
├── commands/
└── scripts/
    ├── bash/
    └── powershell/

scripts/
├── release/
│   ├── build-extension-zip.sh
│   ├── build-extension-zip.ps1
│   ├── test-validate-release-readiness.ps1
│   └── validate-release-readiness.ps1
└── render-demos.sh

tests/
├── run-all.sh
├── test-*.sh
└── test-*.ps1 or equivalent Windows release smoke coverage

docs/
├── release-runbook.md
└── demo/

marketplace/
├── catalog-entry.json
├── extension-submission-body.md
└── extensions-readme-row.md

README.md
README.zh-CN.md
CHANGELOG.md
AGENTS.md
CLAUDE.md
```

**Structure Decision**: Use the existing repo-local extension layout. Release hardening belongs in existing release scripts, smoke tests, docs, marketplace metadata, and feature evidence files. The only new feature-local directory is `specs/013-v1-0-release-hardening/contracts/` for planning contracts.

## Complexity Tracking

No constitution violations are currently justified. Any task that proposes a new command, state file, runner, or lifecycle surface must return to the Constitution Check before implementation.

## Phase 0 Output

See [research.md](./research.md). All known technical uncertainties from the spec are resolved into concrete release-planning decisions.

## Phase 1 Output

See:

- [data-model.md](./data-model.md)
- [contracts/readiness-report-contract.md](./contracts/readiness-report-contract.md)
- [contracts/release-readiness-contract.md](./contracts/release-readiness-contract.md)
- [contracts/verification-evidence-contract.md](./contracts/verification-evidence-contract.md)
- [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

Pass. The design artifacts preserve the thin bridge stance. Readiness output is specified as diagnostic evidence over existing files, not a new state owner. Release readiness is specified as validator behavior over existing metadata and package contents. Verification evidence is feature-local documentation plus sandbox records, not runtime state. The plan keeps upstream-owned behavior delegated to Spec Kit, Superpowers, Codex, and Claude Code.
