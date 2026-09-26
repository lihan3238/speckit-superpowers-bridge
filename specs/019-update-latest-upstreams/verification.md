# Verification: Latest Upstream Alignment and v1.3.0

**Feature**: `019-update-latest-upstreams`

This file records fresh evidence. A PASS requires a command result, hosted run, or public artifact check.

## Source checks

| Check | Result | Evidence |
|---|---|---|
| Spec Kit CLI 1.0.12 | PASS | `specify --version` → `specify 1.0.12`; `uv tool list` → `specify-cli v1.0.12` |
| Spec Kit v1.0.12 source/manifest audit | PASS | tag `e77daa9021d20db26b878f7dfa5640fe5a42d04e`; extension manager accepted current manifest with 3 commands/aliases and hooks |
| Superpowers v6.4.2 skill audit | PASS | tag `8ca22dba9a94f28898bbce59f2537ff4d87c747d`; all invoked IDs present; `task-brief` heading mismatch documented |
| Tracked source/template refresh | PASS | official v1.0.12 git/agent-context refresh; templates use command placeholders and retain project gates |
| Hook contract and malformed-registry regression | PASS | `bash tests/test-implement-hooks-dispatch.sh`; parser-error/no-hooks-checked and adapter assertions pass |
| Codex/Claude peer parity | PASS | `bash tests/test-claude-codex-skill-parity.sh`; Spec Kit integration status reports 0 modified/missing files |
| Full bash suite | PASS | `bash tests/run-all.sh` → `All 9 bash smoke tests passed.` |
| Native Windows gate | RELEASE-GATED | `powershell.exe` readiness gates pass locally; native release smoke remains a hosted/sandbox gate |
| Readiness validator and package smoke | PASS | readiness source+ZIP → OK; self-tests → `validate-release-readiness-tests-ok`; package smoke PASS |
| Published sandbox cycles | PENDING | public ZIP evidence required after tag publication |

## Release artifact

- Bridge version: 1.3.0
- Versioned URL: pending publication
- Stable-alias URL: pending publication
- Candidate SHA256: `2caba4377f003a6229585f1d559de6dedc1d5654e7f2566dcf9b98462c154525` (two identical builds)
- Published SHA256: pending until GitHub release assets are reachable
- GitHub Actions run: pending

## Compatibility evidence

- Spec Kit: v1.0.12 / `e77daa9021d20db26b878f7dfa5640fe5a42d04e`
- Superpowers: v6.4.2 / `8ca22dba9a94f28898bbce59f2537ff4d87c747d`
- Bridge protocol invariants: pending focused audit
