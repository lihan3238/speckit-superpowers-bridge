# Release Baseline: v1.0.0 Stable Protocol Release Hardening

Captured on 2026-06-04 from branch `013-v1-0-release-hardening`.

## Current Tool Versions

| Tool | Observed version | Notes |
|---|---|---|
| Spec Kit CLI | `specify 0.9.3` | Current local CLI and 1.0.0 verification target unless refreshed before tagging. |
| Codex CLI | `codex-cli 0.137.0` | Current local Codex verification target. |
| Claude Code | `2.1.162 (Claude Code)` | Current local Claude verification target. |
| Superpowers | `5.1.0` | Current upstream release observed during research. |
| Bridge | `0.7.2` | Current source metadata before 1.0.0 bump. |

## Local Tool Availability

| Tool | Status | Observed path or note |
|---|---|---|
| `pwsh` | Missing in WSL PATH | Native Windows PowerShell 5.1+ validation must run outside this WSL shell. |
| `vhs` | Missing in WSL PATH | GIF regeneration cannot run here until installed. |
| `ttyd` | Available | `/home/lihan/.local/bin/ttyd` |
| `ffmpeg` | Available | `/home/lihan/anaconda3/bin/ffmpeg` |
| `jq` | Available | `/home/lihan/anaconda3/bin/jq` |
| `gh` | Available | `/usr/bin/gh` |
| `git` | Available | `/usr/bin/git` |

## Current Release Metadata

| File | Current value | 1.0.0 action |
|---|---|---|
| `.specify/extensions/speckit-superpowers-bridge/extension.yml` | `version: "0.7.2"` | Bump to `1.0.0`. |
| `marketplace/catalog-entry.json` | `"version": "0.7.2"` | Bump to `1.0.0`; keep stable alias download URL. |
| `.specify/extensions/speckit-superpowers-bridge/verified-versions.json` | `bridge_version: 0.7.2`, Spec Kit `0.9.1` | Refresh to bridge `1.0.0`, Spec Kit `0.9.3`, current agents, and platform rows. |

## Release Workflow Gap

`.github/workflows/release.yml` currently runs a PowerShell loop over `tests/*.ps1`, but this repository currently has bash smoke tests only. The 1.0.0 release must align the workflow with the actual test inventory and add focused Windows PowerShell release smoke coverage.

## Release File Inventory

### Bridge Package

```text
.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.execute.md
.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.guard.md
.specify/extensions/speckit-superpowers-bridge/commands/speckit.speckit-superpowers-bridge.handoff.md
.specify/extensions/speckit-superpowers-bridge/extension.yml
.specify/extensions/speckit-superpowers-bridge/scripts/bash/auto-archive-handoff.sh
.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-state.sh
.specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh
.specify/extensions/speckit-superpowers-bridge/scripts/bash/common-actor-resolution.sh
.specify/extensions/speckit-superpowers-bridge/scripts/bash/guard-command.sh
.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh
.specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1
.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-state.ps1
.specify/extensions/speckit-superpowers-bridge/scripts/powershell/bridge-status.ps1
.specify/extensions/speckit-superpowers-bridge/scripts/powershell/common-actor-resolution.ps1
.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1
.specify/extensions/speckit-superpowers-bridge/scripts/powershell/update-handoff.ps1
.specify/extensions/speckit-superpowers-bridge/verified-versions.json
```

### Release Tooling

```text
scripts/release/build-extension-zip.ps1
scripts/release/test-validate-release-readiness.ps1
scripts/release/validate-release-readiness.ps1
```

### Tests

```text
tests/fixtures/.gitkeep
tests/fixtures/pre-070-handoff.json
tests/fixtures/tasks-all-deferred.md
tests/fixtures/tasks-with-pending.md
tests/run-all.sh
tests/test-bridge-state-summary.sh
tests/test-bridge-status.sh
tests/test-claude-codex-skill-parity.sh
tests/test-guard-hardcoded-rules.sh
tests/test-handoff-shape.sh
```

### Documentation and Marketplace

```text
.github/workflows/release.yml
docs/demo/README.md
docs/demo/full-cycle.gif
docs/demo/full-cycle.tape
docs/demo/hero.gif
docs/demo/hero.tape
docs/release-runbook.md
marketplace/README.md
marketplace/catalog-entry.json
marketplace/extension-submission-body.md
marketplace/extensions-readme-row.md
```
