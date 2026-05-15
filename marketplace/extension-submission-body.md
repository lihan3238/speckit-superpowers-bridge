# Extension Submission: Superpowers Implementation Bridge

### Extension ID

speckit-superpowers-bridge

### Extension Name

Superpowers Implementation Bridge

### Version

0.4.2

### Description

Thin orchestrator between Spec Kit (design) and Superpowers (implementation). Cross-agent.

### Author

lihan3238

### Repository URL

https://github.com/lihan3238/speckit-superpowers-bridge

### Download URL

https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.2/speckit-superpowers-bridge-v0.4.2.zip

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

- Windows with Spec Kit `0.8.10`, Codex integration, and PowerShell flavor.
- WSL/Linux with Spec Kit from the official GitHub source, Claude Code integration, and bash flavor.
- Superpowers release baseline `v5.1.0`.

Release validation:

- `specify --version` -> `specify 0.8.10`
- Release workflow: https://github.com/lihan3238/speckit-superpowers-bridge/actions/runs/25934883753
- Release ZIP SHA256: `1758f75296f2de7ce1399bd91765c719d50a99700ce852a621a59cb6704e7cf2`
- `scripts/release/validate-release-readiness.ps1 -Version 0.4.2`
- `tests/test-handoff-shape.ps1`
- `tests/test-guard-hardcoded-rules.ps1`
- `tests/test-claude-codex-skill-parity.ps1`
- `scripts/release/test-validate-release-readiness.ps1`
- `bash -n .specify/extensions/speckit-superpowers-bridge/scripts/bash/*.sh`

Fresh install smoke:

- Windows + Codex: installed from the v0.4.2 release ZIP; verified short alias, canonical fallbacks, PowerShell handoff, and guard allow/deny decisions.
- WSL/Linux + Claude: installed from the v0.4.2 release ZIP; verified short alias, canonical fallbacks, bash handoff, and guard allow/deny decisions.
- ZIP structure: `extension.yml` at archive root; `commands/`, `scripts/powershell/`, and `scripts/bash/` use portable `/` separators.

### Example Usage

```powershell
specify init my-project --integration codex
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.2/speckit-superpowers-bridge-v0.4.2.zip

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
  "speckit-superpowers-bridge": {
    "id": "speckit-superpowers-bridge",
    "name": "Superpowers Implementation Bridge",
    "description": "Thin orchestrator between Spec Kit (design) and Superpowers (implementation). Cross-agent.",
    "author": "lihan3238",
    "version": "0.4.2",
    "license": "MIT",
    "repository": "https://github.com/lihan3238/speckit-superpowers-bridge",
    "homepage": "https://github.com/lihan3238/speckit-superpowers-bridge",
    "documentation": "https://github.com/lihan3238/speckit-superpowers-bridge#readme",
    "changelog": "https://github.com/lihan3238/speckit-superpowers-bridge/blob/main/CHANGELOG.md",
    "download_url": "https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.2/speckit-superpowers-bridge-v0.4.2.zip",
    "requires": {
      "speckit_version": ">=0.8.10",
      "tools": [
        { "name": "powershell", "version": ">=5.1", "required": false, "description": "Windows runtime flavor" },
        { "name": "bash", "version": ">=4.0", "required": false, "description": "Linux/macOS runtime flavor" },
        { "name": "jq", "version": ">=1.6", "required": false, "description": "Required by the bash runtime flavor" },
        { "name": "git", "version": ">=2.30", "required": false, "description": "Recommended for branch/worktree discipline" }
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
    "updated_at": "2026-05-16T00:00:00Z"
  }
}
```

### Additional Context

This is the clean v0.4.2 submission for `speckit-superpowers-bridge`. It supersedes the older exploratory issue #2575, whose body and comments describe earlier pre-trim releases.

The bridge combines Spec Kit and Superpowers by keeping their responsibilities separate:

- **Spec Kit owns WHAT**: constitution, spec, clarify, plan, tasks, checklists, and analysis remain the durable design artifacts.
- **Superpowers owns HOW**: TDD, systematic debugging, executing plans, code review, verification, and finishing the development branch remain native Superpowers implementation discipline.
- **The bridge only orchestrates**: it writes the handoff JSON, enforces five boundary guard rules, appends event logs/snapshots, and exposes generated command skills for Codex and Claude Code.
- **No overlap, no replacement**: the extension does not run `speckit.implement`, does not create a second planning system, does not edit the global Superpowers cache, and does not implement custom execution discipline.

This follows the design direction in [Spec Kit vs Superpowers - A Comprehensive Comparison & Practical Guide to Combining Both](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj): Spec Kit remains the source of truth for design, while Superpowers executes the implementation discipline explicitly at lifecycle phases.

### AI-Assistance Disclosure

Per the AI-disclosure requirement in [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md), this extension was developed using AI coding assistants. Claude Code handled design and planning across the Spec Kit artifacts. Codex handled implementation and release-alignment passes. Every artifact passed human review before commit.
