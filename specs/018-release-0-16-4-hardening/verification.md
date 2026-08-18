# Verification: v1.2.0 Release Hardening and Upstream Alignment

**Feature**: `018-release-0-16-4-hardening` | **Started**: 2026-08-18

This file is populated during implementation and release. A row is marked PASS only with fresh command or hosted-run evidence.

## Source verification

| Check | Result | Evidence |
|---|---|---|
| PR #14 independent worktree suite | PASS | `bash tests/run-all.sh` on commit `9cd8999`: 7/7 |
| PR #14 merge | PASS | merged as `07c3c81e034a7461aa668131bee88404aa04605b` |
| Spec Kit 0.16.4 CLI install | PASS | `specify --version` → `specify 0.16.4` |
| Spec Kit source tag | PASS | `v0.16.4` commit `d1f50fcbe684a4222059c4ba7f2d7eabcca87402` |
| Spec Kit 0.11.1 → 0.16.4 audit | PASS | `research.md` R2/R4/R5/R6 |
| Superpowers 6.3.0 surface audit | PASS | tag commit `b36e0829c6d0140e93cfef2ca599b1b07d4a7797`; all six invoked skill paths present |
| Bundled git source refresh | PASS | project source matches Spec Kit 0.16.4 `extensions/git/`; PowerShell working-tree bytes differ only by repository-required CRLF normalization |
| Bundled agent-context source refresh | PASS | project source matches Spec Kit 0.16.4 `extensions/agent-context/` except project multi-context config |
| Claude + Codex integration refresh | PASS | both installed; Claude default; integration status reports zero modified/missing managed files |
| Local bridge dev registration | PASS | installed extension list reports v1.2.0, 3 commands, 5 hooks |
| Project-owned short skill restoration | PASS | installer collision reproduced; both tracked regular files restored; parity suite passes |
| macOS path regression | PASS | `bash tests/test-update-handoff-portability.sh` → `update-handoff-portability-tests-ok (bash)`; `bash tests/test-handoff-shape.sh` → PASS; `bash tests/test-bridge-status.sh` → 26/26 PASS; `bash -n update-handoff.sh` and `shellcheck -x update-handoff.sh` → PASS |
| implement-hook instruction contract | PASS | test-first failure on missing `EXECUTE_COMMAND`; after hardening, `bash tests/test-implement-hooks-dispatch.sh` and `bash tests/test-claude-codex-skill-parity.sh` both PASS |
| Source formatting and shell syntax | PASS | `git diff --check` clean; `bash -n` passed for every repository shell script; refreshed PowerShell sources restored to required CRLF |
| Targeted ShellCheck | PASS | `shellcheck -x update-handoff.sh`; release ZIP builder and package smoke also pass ShellCheck after removing GNU `sha256sum` dependence |
| Full bash suite | PASS | `bash tests/run-all.sh` → `All 8 bash smoke tests passed.` |
| Native Windows PowerShell smoke | PASS | Windows PowerShell `5.1.26100.9168`; `tests/test-release-powershell.ps1` → `release-powershell-tests-ok` |
| macOS hosted gate | PENDING | GitHub Actions run |
| Release-readiness self-tests | PASS | native Windows PowerShell: 26 positive/negative cases → `validate-release-readiness-tests-ok` |
| Release-readiness validator | PASS | native Windows PowerShell: source tree and candidate ZIP both → `Release readiness OK for version 1.2.0.` |
| Deterministic candidate ZIP | PASS | two consecutive builds produced SHA256 `52372474ee8c6e36a96bb08e58bfe49d912d4d39a9e7ba767efea44ae8b500f0`; package smoke PASS |

## Published artifact verification

| Platform | Spec Kit | Artifact | Status | Notes |
|---|---:|---|---|---|
| WSL2 Linux bash | 0.16.4 | v1.2.0 public ZIP | PENDING | full bridge cycle + implement hooks |
| Windows PowerShell 5.1+ | 0.16.4 target | v1.2.0 public ZIP | PENDING | full bridge cycle |
| macOS bash | 0.16.4 target | v1.2.0 public ZIP | DEFERRED | no local native host; hosted source/runtime regression required and must not be described as a local sandbox run |

## Release artifact

- Tag: `v1.2.0` (pending)
- Versioned URL: pending
- Stable-alias URL: pending
- Local candidate SHA256: `52372474ee8c6e36a96bb08e58bfe49d912d4d39a9e7ba767efea44ae8b500f0`
- Published SHA256: pending
- GitHub Actions run: pending

## Coordination

- PR #14: merged 2026-08-18 (`07c3c81`)
- Issue #13: OPEN as of 2026-08-18, pending published fix
- Upstream Spec Kit catalog submission: pending post-release

### Local registry/catalog distinction

The temporary-copy `--dev` registration correctly records installed bridge
v1.2.0. `specify extension info speckit-superpowers-bridge` still displays the
official community-catalog entry at v1.1.0 until the post-release upstream
submission lands; this is expected external-state lag, not a local install
failure.

## Local tool baseline

| Tool | Version |
|---|---:|
| Spec Kit CLI | 0.16.4 |
| Codex CLI | 0.147.0 |
| Claude Code | 2.1.233 |
| Bash | 5.2.21 |
| jq | 1.7.1 |
| GitHub CLI | 2.45.0 |
| ShellCheck | installed at `/home/lihan/.local/bin/shellcheck` |

## Known blockers and deferrals

- The macOS-hosted row cannot pass until the tag-triggered release workflow
  runs. It is a publication gate, not a local native-macOS sandbox claim.
- WSL2 and Windows public-ZIP sandbox rows require the published v1.2.0 asset
  and therefore remain pending until after the release workflow completes.
- Claude Code `2.1.233` integration files and project-owned skill parity are
  verified. A bounded live provider call did not complete under the workstation's
  current provider model mapping, so no new live-Claude behavioral claim is made.
