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
| macOS hosted gate | PASS | successful release run `32093305991` passed the full bash suite and Issue #13 regression on merge `38ac465`; initial run `32092840757` remains evidence that the gate caught three test-only BSD/GNU assumptions (`/tmp` → `/private/tmp`, `stat -c`, `find -printf`) before publication |
| Release-readiness self-tests | PASS | native Windows PowerShell: 26 positive/negative cases → `validate-release-readiness-tests-ok` |
| Release-readiness validator | PASS | native Windows PowerShell: source tree and candidate ZIP both → `Release readiness OK for version 1.2.0.` |
| Deterministic candidate ZIP | PASS | two consecutive builds produced SHA256 `52372474ee8c6e36a96bb08e58bfe49d912d4d39a9e7ba767efea44ae8b500f0`; package smoke PASS |
| Post-release evidence rerun | PASS | after public-sandbox and coordination evidence changes: `bash tests/run-all.sh` → `All 8 bash smoke tests passed.`; native Windows `validate-release-readiness.ps1 -Version 1.2.0` → `Release readiness OK for version 1.2.0.` |

## Published artifact verification

| Platform | Spec Kit | Artifact | Status | Notes |
|---|---:|---|---|---|
| WSL2 Linux bash | 0.16.4 | v1.2.0 public ZIP | PASS | sandbox `../test_specify_superpower/v1-2-0-linux-20260818T025324Z`; mandatory pre/post hooks ran in order, executing-state guard denied `speckit.implement`, final state `complete` with zero pending tasks and no drift; local evidence `.specify/bridge-verification/v1.2.0-linux.md` |
| Windows PowerShell 5.1+ | 0.16.4 | v1.2.0 public ZIP | PASS | native sandbox `..\test_specify_superpower\v1-2-0-windows-20260818T030242Z`; mandatory pre/post hooks ran in order, executing-state guard denied `speckit.implement`, final state `complete` with zero pending tasks and no drift; readiness core checks ready; local evidence `.specify\bridge-verification\v1.2.0-windows.md` |
| macOS bash | 0.16.4 target | v1.2.0 public ZIP | DEFERRED | no local native host; successful hosted release run `32093305991` covers the full source suite and portable handoff regression, but is not represented as a local public-ZIP sandbox run |

## Release artifact

- Tag: [`v1.2.0`](https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v1.2.0), re-pointed to merge `38ac46555a3dcbd3b347a54b72811c4467166340` after the macOS test-only portability fix
- Versioned URL: `https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v1.2.0/speckit-superpowers-bridge-v1.2.0.zip`
- Stable-alias URL: `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`
- Local candidate SHA256: `52372474ee8c6e36a96bb08e58bfe49d912d4d39a9e7ba767efea44ae8b500f0`
- Published SHA256: `52372474ee8c6e36a96bb08e58bfe49d912d4d39a9e7ba767efea44ae8b500f0` for both byte-identical ZIP assets
- GitHub Actions run: [`32093305991`](https://github.com/lihan3238/speckit-superpowers-bridge/actions/runs/32093305991) — Linux, Windows, macOS, and publish jobs PASS

## Coordination

- PR #14: merged 2026-08-18 (`07c3c81`)
- PR #15: merged 2026-08-18 (`a8736d0`), initial v1.2.0 release commit
- PR #16: merged 2026-08-18 (`38ac465`), portable macOS test-gate fix and final tagged release commit
- Issue #13: [CLOSED](https://github.com/lihan3238/speckit-superpowers-bridge/issues/13) on 2026-08-18 with v1.2.0, successful macOS-hosted run, and post-release evidence links
- Upstream Spec Kit catalog submission: [github/spec-kit#4180](https://github.com/github/spec-kit/issues/4180), opened 2026-08-18 with the v1.2.0 support matrix and proposed catalog entry

### Local registry/catalog distinction

The temporary-copy `--dev` registration correctly records installed bridge
v1.2.0. `specify extension info speckit-superpowers-bridge` still displays the
official community-catalog entry at v1.1.0 until the post-release upstream
submission lands; this is expected external-state lag, not a local install
failure.

## Final completion review

- Working tree and branch: clean on `chore/v1.2.0-post-release-evidence` before final task bookkeeping; PR #17 is open, non-draft, mergeable, and reports a clean merge state. This repository has no pull-request-triggered workflow, so no hosted PR check is expected.
- Remote release refs: `origin/main` and peeled `v1.2.0^{}` both resolve to `38ac46555a3dcbd3b347a54b72811c4467166340`.
- Release assets: both `speckit-superpowers-bridge-v1.2.0.zip` and `speckit-superpowers-bridge.zip` are uploaded, 82,506 bytes each, with verified SHA256 `52372474ee8c6e36a96bb08e58bfe49d912d4d39a9e7ba767efea44ae8b500f0`.
- Coordination state: repository Issue #13 is closed as completed, no repository issue remains open, and upstream catalog update issue `github/spec-kit#4180` is open.
- Bridge state before the terminal transition: `executing`, actor `codex`, with only T034/T035 pending; artifact drift is limited to the expected `tasks.md` completion updates.

## Local tool baseline

| Tool | Version |
|---|---:|
| Spec Kit CLI | 0.16.4 |
| Spec Kit CLI (native Windows) | 0.16.4 |
| Codex CLI | 0.147.0 |
| Claude Code | 2.1.233 |
| Bash | 5.2.21 |
| jq | 1.7.1 |
| GitHub CLI | 2.45.0 |
| ShellCheck | installed at `/home/lihan/.local/bin/shellcheck` |

## Known blockers and deferrals

- The first macOS-hosted tag run failed in the test harness, not the shipped
  runtime: canonical `/private/tmp` output was compared with lexical `/tmp`,
  and two older tests used GNU-only `stat`/`find` flags. PR #16 corrected those
  tests, the tag was re-pointed, and successful run `32093305991` passed every
  platform job. Native macOS public-ZIP sandbox evidence remains honestly
  deferred because no local macOS host is available.
- WSL2 and native Windows public-ZIP sandbox cycles both pass against the
  published SHA256. Each sandbox is a nested Git repository so bridge root
  discovery cannot escape into the parent simulation directory.
- Claude Code `2.1.233` integration files and project-owned skill parity are
  verified. A bounded live provider call did not complete under the workstation's
  current provider model mapping, so no new live-Claude behavioral claim is made.
