# Extension Submission: Superpowers Implementation Bridge

### Extension ID

speckit-superpowers-bridge

### Extension Name

Superpowers Implementation Bridge

### Version

0.6.0

### Description

Thin orchestrator between Spec Kit (design) and Superpowers (implementation). Cross-agent.

### Author

lihan3238

### Repository URL

https://github.com/lihan3238/speckit-superpowers-bridge

### Download URL

https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip

(Version-pinned alternative for reproducible installs:)

https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.6.0/speckit-superpowers-bridge-v0.6.0.zip

> **Note for catalog maintainers**: as of v0.6.0 the canonical `download_url` is the GitHub `/releases/latest/download/` stable-alias (above). Every release tag attaches BOTH the versioned and the stable-aliased asset (verified for v0.5.0: 44708-byte identical content). The decoupling means the catalog `download_url` does NOT need editing on future bridge releases — only the `version` field bumps for audit trail.

### License

MIT

### Homepage (optional)

https://github.com/lihan3238/speckit-superpowers-bridge

### Documentation URL (optional)

https://github.com/lihan3238/speckit-superpowers-bridge#readme

### Changelog URL (optional)

https://github.com/lihan3238/speckit-superpowers-bridge/blob/main/CHANGELOG.md

### Required Spec Kit Version

>=0.8.10

(Verified compatibility for v0.6.0: Spec Kit `0.8.16`. The floor stays at `>=0.8.10` because v0.6.0 ships zero behavioral changes requiring a newer Spec Kit — bumping the floor would force needless upgrade pressure on existing users.)

### Required Tools (optional)

- PowerShell `>=5.1` for the Windows runtime flavor.
- Bash `>=4.0` and `jq >=1.6` for the Linux/macOS runtime flavor.
- Superpowers `v5.1.0` skills in the active agent runtime when users want Superpowers implementation discipline.
- Codex and Claude Code are both supported; Spec Kit renders the generated commands into each integration's native command style.

### Number of Commands

3

### Number of Hooks (optional)

5

### Tags

bridge, superpowers, cross-agent, tdd, workflow

### Key Features

- Keeps Spec Kit as the design source of truth: constitution, spec, clarify, plan, tasks, checklists, and analyze stay Spec Kit-owned.
- Uses Superpowers as the implementation discipline: TDD, systematic debugging, executing plans, review, verification, and branch finishing stay native Superpowers capabilities.
- Adds a thin handoff/guard layer so the two systems do not duplicate planning or execution ownership.
- Supports Windows, Linux, and macOS through one ZIP containing PowerShell and bash script flavors.
- Supports Codex, Claude Code, or both; the short entrypoint is `$speckit-superpowers-bridge` for Codex and `/speckit-superpowers-bridge` for Claude Code.
- **New in v0.6.0**: hero-led + bilingual README with a 5-badge row, `## Why` / `## Quick Start` / `## Positioning` sections above the fold, and 10 collapsed `<details>` sections — modelled on the rpamis/comet structural pattern using native Markdown + GitHub-flavored alerts only (no JS / CSS / build step).
- **New in v0.6.0**: `verified-versions.json` artifact at the bridge package root capturing the exact `{spec_kit_version, superpowers_version, bridge_version, notes, verified_at}` snapshot for each release — a 5-field locked schema with an additive-only future-extension policy.
- **New in v0.6.0**: marketplace `download_url` permanently decoupled from the version pin (this submission's `Download URL` field). Future bridge releases never edit `download_url` again — only `version` bumps for audit trail.

### Testing Checklist

- [x] Extension installs successfully via download URL
- [x] All commands execute without errors
- [x] Documentation is complete and accurate
- [x] No security vulnerabilities identified
- [x] Tested on at least one real project

### Submission Requirements

- [x] Valid `extension.yml` manifest included
- [x] README.md with installation and usage instructions
- [x] LICENSE file included
- [x] GitHub release created with version tag
- [x] All command files exist and are properly formatted
- [x] Extension ID follows naming conventions (lowercase-with-hyphens)

### Testing Details

Tested on:

- WSL Ubuntu bash 5.2+ with Spec Kit `0.8.16`, Claude Code integration, and bash flavor (post-009 dev environment alignment — primary).
- Windows PowerShell 5.1+ with Spec Kit `0.8.10+`, Codex integration, and PowerShell flavor (script flavor parity unchanged; functional parity verified via spec 003).
- Superpowers release baseline `v5.1.0` (grep-verified clean against v5.1.0's removed slash commands and removed `superpowers:code-reviewer` named agent — bridge invokes by skill name only).

Release validation:

- `specify --version` -> `specify 0.8.16` (maintainer dev environment); floor `>=0.8.10` carried forward.
- Release ZIP SHA256: `a0928cbd9ab288cb7bd77425b2d1a77c87271b8583f03c657e6c65db52e33113` (versioned and stable-alias copies identical content).
- `bash tests/run-all.sh` -> 4/4 smoke tests pass on WSL bash (`test-bridge-state-summary.sh`, `test-claude-codex-skill-parity.sh`, `test-guard-hardcoded-rules.sh`, `test-handoff-shape.sh`).
- Version triplet consistency: `extension.yml.extension.version == catalog-entry.json.version == verified-versions.json.bridge_version == "0.6.0"`.
- `jq -e '.verified_at and .spec_kit_version and .superpowers_version and .bridge_version and .notes' .specify/extensions/speckit-superpowers-bridge/verified-versions.json` -> exit 0 (5-field schema validates).
- README structural assertions (R6, see [`specs/011-v060-comet-polish/contracts/readme-structure.md`](https://github.com/lihan3238/speckit-superpowers-bridge/blob/main/specs/011-v060-comet-polish/contracts/readme-structure.md)) verified inline at commit time: hero block / 5-badge row / language-toggle blockquote / Quick Start before Installation / EN-ZH H2 parity (4/4) / EN-ZH `<details>` parity (10/10) — all PASS.

Fresh install smoke:

- WSL bash + Claude: installed from the v0.6.0 stable-alias URL; verified short alias `/speckit-superpowers-bridge`, canonical fallbacks, bash handoff, all 5 guard allow/deny decisions, the `[bridge state]` block on every script invocation, and the FR-003 drift warning on complete-with-unchecked.
- Windows + Codex: installed from the same stable-alias URL (resolves to the same ZIP via GitHub `/releases/latest/` redirect); verified short alias `$speckit-superpowers-bridge`, canonical fallbacks, PowerShell handoff, all 5 guard decisions, `[bridge state]` block, FR-003 warning.
- ZIP structure: `extension.yml` at archive root; `commands/`, `scripts/powershell/`, `scripts/bash/`, and the new `verified-versions.json` at archive root all use portable `/` separators.

### Example Usage

```powershell
specify init my-project --integration codex
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip

$speckit-specify
$speckit-clarify
$speckit-plan
$speckit-tasks
$speckit-superpowers-bridge
```

Claude Code users run the same flow with slash commands:

```text
/speckit-specify
/speckit-clarify
/speckit-plan
/speckit-tasks
/speckit-superpowers-bridge
```

### Proposed Catalog Entry

```json
{
  "name": "Superpowers Implementation Bridge",
  "id": "speckit-superpowers-bridge",
  "description": "Thin orchestrator between Spec Kit (design) and Superpowers (implementation). Cross-agent.",
  "author": "lihan3238",
  "version": "0.6.0",
  "download_url": "https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip",
  "repository": "https://github.com/lihan3238/speckit-superpowers-bridge",
  "homepage": "https://github.com/lihan3238/speckit-superpowers-bridge",
  "documentation": "https://github.com/lihan3238/speckit-superpowers-bridge#readme",
  "changelog": "https://github.com/lihan3238/speckit-superpowers-bridge/blob/main/CHANGELOG.md",
  "license": "MIT",
  "requires": {
    "speckit_version": ">=0.8.10",
    "tools": [
      { "name": "powershell", "version": ">=5.1", "required": false },
      { "name": "bash", "version": ">=4.0", "required": false },
      { "name": "jq", "version": ">=1.6", "required": false }
    ]
  },
  "provides": {
    "commands": 3,
    "hooks": 5
  },
  "tags": ["bridge", "superpowers", "cross-agent", "tdd", "workflow"],
  "verified": false,
  "downloads": 0,
  "stars": 0,
  "created_at": "2026-05-16T00:00:00Z",
  "updated_at": "<filled-by-maintainer-on-merge>"
}
```

### Additional Context

This is the **v0.6.0 update** for the already accepted `speckit-superpowers-bridge` community catalog entry. Prior issue history: initial listing accepted via issue #2581 / PR #2586; v0.4.3 update via issue #2600; v0.5.0 update via the prior catalog-update issue (closed once accepted). v0.6.0 supersedes those.

**Two catalog edits requested in this issue:**

1. Bump `version` from `0.5.0` to `0.6.0`.
2. **Replace `download_url`** with the GitHub `/releases/latest/download/speckit-superpowers-bridge.zip` stable-alias URL. After this one-time edit, the catalog's `download_url` does NOT need editing on future bridge releases — GitHub's `/releases/latest/` alias always resolves to the current published tag's asset, and every bridge release tag attaches both the versioned and the stable-aliased ZIP at identical content (already true as of v0.5.0). This eliminates a recurring per-release catalog-edit class for everyone.

The bridge combines Spec Kit and Superpowers by keeping their responsibilities separate:

- **Spec Kit owns WHAT**: constitution, spec, clarify, plan, tasks, checklists, and analysis remain the durable design artifacts.
- **Superpowers owns HOW**: TDD, systematic debugging, executing plans, code review, verification, and finishing the development branch remain native Superpowers implementation discipline.
- **The bridge only orchestrates**: it writes the handoff JSON, enforces five boundary guard rules, appends event logs/snapshots, and exposes generated command skills for Codex and Claude Code.
- **No overlap, no replacement**: the extension does not run `speckit.implement`, does not create a second planning system, does not edit the global Superpowers cache, and does not implement custom execution discipline.

v0.6.0 is a **documentation + metadata** release: 0 lines changed in bridge scripts, 0 lines changed in `commands/*.md`, 0 changes to the 5 hardcoded guard rules, 0 new hooks in `.specify/extensions.yml`. The only new file in the bridge package is `verified-versions.json` (5 fields, 9 lines, additive-only schema). README polished to a hero-led + bilingual layout modelled on the rpamis/comet structural pattern.

This follows the design direction in [Spec Kit vs Superpowers - A Comprehensive Comparison & Practical Guide to Combining Both](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj): Spec Kit remains the source of truth for design, while Superpowers executes the implementation discipline explicitly at lifecycle phases.

### AI-Assistance Disclosure

Per the AI-disclosure requirement in [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md), this extension was developed using AI coding assistants. Claude Code handled design and planning across the Spec Kit artifacts. Codex handled implementation and release-alignment passes. The v0.6.0 polish + decoupling work was driven end-to-end by Claude Code (Opus 4.7) following the project's bridge protocol (specify → clarify → plan → tasks → bridge), with every artifact passing human review before commit.
