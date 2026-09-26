# Verification: Latest Upstream Alignment and v1.3.0

**Feature**: `019-update-latest-upstreams`

A PASS requires a command result, hosted run, or public artifact check.

## Source checks

| Check | Result | Evidence |
|---|---|---|
| Spec Kit CLI 1.0.12 | PASS | `specify --version` → `specify 1.0.12`; `uv tool list` → `specify-cli v1.0.12` |
| Spec Kit v1.0.12 source/manifest audit | PASS | Tag `e77daa9021d20db26b878f7dfa5640fe5a42d04e`; extension manager accepted the bridge manifest with 3 commands/aliases and hooks |
| Superpowers v6.4.2 skill audit | PASS | Tag `8ca22dba9a94f28898bbce59f2537ff4d87c747d`; all invoked IDs exist; `task-brief` heading mismatch is adapted |
| Tracked source/template refresh | PASS | Official v1.0.12 git/agent-context refresh; templates use command placeholders and retain project gates |
| Hook and adapter regressions | PASS | Focused hook/parity/handoff tests and `superpowers-adapter-contract-tests-ok` |
| Full Bash suite | PASS | `bash tests/run-all.sh` → `All 9 bash smoke tests passed.` |
| Readiness, package, and PowerShell tooling | PASS | Source/ZIP readiness OK; `validate-release-readiness-tests-ok`; package smoke PASS; hosted Windows gate PASS |
| Shell syntax and ShellCheck | PASS | All repository `.sh` files pass `bash -n`; targeted ShellCheck and `git diff --check` pass |

## Published artifact verification

| Platform | Spec Kit | Artifact | Status | Evidence |
|---|---:|---|---|---|
| WSL2 Linux bash | 1.0.12 | v1.3.0 public ZIP | PASS | Fresh sibling sandbox `../test_specify_superpower/v1-3-0-linux-20260926T111500Z`; public install, 3-command/5-hook listing, readiness, allow/deny guard, executing/complete handoff, drift warning, archive, events, and snapshots exercised |
| Windows PowerShell 5.1+ | 1.0.12 | v1.3.0 public ZIP | PASS | Fresh sibling sandbox `../test_specify_superpower/v1-3-0-windows-20260926T111613Z` plus GitHub Actions Windows gate job `108392956607`; readiness, native PowerShell smoke, and release-tooling self-tests passed |
| macOS bash | 1.0.12 | v1.3.0 public ZIP | PASS | GitHub Actions macOS gate job `108392956699`; Homebrew Bash/jq, full 9-test suite, and portability regression passed; no local native macOS sandbox claim |

## Release artifact

- Tag: [`v1.3.0`](https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v1.3.0) at commit `8e687d59f0124ffeb969d048a308f73f35b23623`
- Workflow: [`36237907349`](https://github.com/lihan3238/speckit-superpowers-bridge/actions/runs/36237907349) — Linux, Windows, macOS, and publish jobs PASS
- Versioned URL: `https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v1.3.0/speckit-superpowers-bridge-v1.3.0.zip`
- Stable-alias URL: `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip`
- Both assets: 83,891 bytes; SHA256 `2caba4377f003a6229585f1d559de6dedc1d5654e7f2566dcf9b98462c154525`
- Two local candidate builds produced the same SHA256.

## Final compatibility review

- Spec Kit CLI: `1.0.12`; tracked git and agent-context extension sources: `1.0.1`; Claude and Codex integrations are installed in the source checkout.
- Superpowers: `6.4.2`; all bridge-invoked skill identifiers exist; the checkbox-to-`Task N` adapter contract is covered by `tests/test-superpowers-adapter-contract.sh`.
- Local plugin distribution: Codex has Superpowers `6.4.2`; the refreshed Claude official marketplace currently serves `6.4.1`, while the upstream `6.4.2` source audit passes and all bridge-invoked skill contracts remain present.
- Preserved invariants: 3 commands, 5 registered hooks, handoff v1, guard rules, actor semantics, stable-alias URL, and `>=0.8.10` runtime floor.
