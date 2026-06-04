# Verification: v1.0.0 Stable Protocol Release Hardening

## Artifact

- Version: 1.0.0
- ZIP path or URL: `dist/speckit-superpowers-bridge-v1.0.0.zip`
- SHA256: `b54e6f1a0b8acaca7499add926740912f87649eb80b3200e0dc66fca95bed711`
- Built at: `2026-06-04T09:26:17Z`
- Built from: bash-first release builder on `013-v1-0-release-hardening`; deterministic ZIP output and normalized ZIP modes verified by `tests/test-release-package.sh`.

## Platform Matrix

| Platform | Environment | Script flavor | Install source | Smoke | Sandbox cycle | Readiness | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| Linux bash | WSL bash 5.2 on `/mnt/c` checkout and sandbox | sh | `dist/speckit-superpowers-bridge-v1.0.0.zip` via localhost ZIP URL | PASS | PASS | PASS | PASS | Full bash suite and bash-built final-package sandbox bridge/readiness cycle passed in `../test_specify_superpower/v1-0-linux-readmepolish-20260604T092645Z`. |
| Windows PowerShell | Native Windows PowerShell 5.1 on host | ps | `dist/speckit-superpowers-bridge-v1.0.0.zip` via localhost ZIP URL | PASS | PASS | PASS | PASS | PowerShell smoke and bash-built final-package sandbox bridge/readiness cycle passed in `../test_specify_superpower/v1-0-windows-readmepolish-20260604T092715Z` with `PYTHONUTF8=1` for Spec Kit CLI install output. |

## Agent Matrix

| Agent | Version | Platform | Prompt boundary | Operations exercised | Result | Evidence | Notes |
|---|---|---|---|---|---|---|---|
| Codex | 0.137.0 | Linux bash / WSL2 | Sandbox-only; cwd inside `../test_specify_superpower/v1-0-linux-20260604T072552Z`; source repo writes forbidden | Manifest, package metadata, status/readiness, guard, ready/executing/complete handoff, evidence file | PASS | `../test_specify_superpower/v1-0-linux-20260604T072552Z/.specify/bridge-verification/codex-v1.0.0-rc.md` | `codex exec` noninteractive run. |
| Claude Code | 2.1.162 | Linux bash / WSL2 | Sandbox-only; cwd inside `../test_specify_superpower/v1-0-linux-20260604T072552Z`; source repo writes forbidden | Manifest, status/readiness, guard, ready/executing/complete handoff, evidence file | PASS | `../test_specify_superpower/v1-0-linux-20260604T072552Z/.specify/bridge-verification/claude-v1.0.0-rc.md` | `claude -p` noninteractive run. |

## Demo Evidence

| Asset | Type | Source run | Truth label | Result | Notes |
|---|---|---|---|---|---|
| docs/demo/hero.gif | GIF | Existing README asset | Illustrative, transcript-derived | LABELLED | Existing GIF predates 1.0.0 real-agent verification and is not claimed as a real Codex/Claude recording. |
| docs/demo/full-cycle.gif | GIF | Existing README asset | Illustrative, transcript-derived | LABELLED | Existing GIF predates 1.0.0 real-agent verification and is not claimed as a real Codex/Claude recording. |
| docs/demo/hero.tape | VHS tape | Scripted demo calling real bridge handoff script for state transitions | Illustrative, transcript-derived | PASS | `Truth label:` is present; Spec Kit/Superpowers/agent output is explicitly synthesized for README orientation. |
| docs/demo/full-cycle.tape | VHS tape | Scripted demo calling real bridge handoff script for state transitions | Illustrative, transcript-derived | PASS | `Truth label:` is present; Spec Kit/Superpowers/agent output is explicitly synthesized for README orientation. |

GIF regeneration decision: not regenerated for v1.0.0 because `vhs` is not available in WSL PATH. `ttyd` is available at `/home/lihan/.local/bin/ttyd` and `ffmpeg` is available at `/home/lihan/anaconda3/bin/ffmpeg`. `scripts/render-demos.sh` now fails clearly when any required renderer dependency is missing and warns maintainers not to present scripted GIFs as real sandbox/agent recordings.

## Implementation Checklist

- [x] SC-001: 100% of version-bearing release files report `1.0.0`.
- [x] SC-002: Namespace validator catches extension id, command, hook, and catalog mismatches.
- [x] SC-003: Linux/bash smoke suite and install-style sandbox cycle are recorded.
- [x] SC-004: Windows PowerShell 5.1+ package install and core script operations are recorded.
- [x] SC-005: Codex and Claude rows are present; only passed rows are claimed as verified.
- [x] SC-006: Packaged ZIP contains both script flavors, portable paths, and root manifest.
- [x] SC-007: Release workflow no longer references nonexistent tests.
- [x] SC-008: Readiness/status surface identifies script flavor, tools, namespace/package integrity, bridge state, and next action.
- [x] SC-009: README.md and README.zh-CN.md contain equivalent 1.0.0 claims.
- [x] SC-010: Release runbook reproduces the 1.0.0 gate sequence from a clean checkout.
- [x] SC-011: Demo/release evidence is truthful and labelled.
- [x] SC-012: No vendor-managed generated Spec Kit skill edits and no heavy runtime/state-machine components.
- [x] SC-013: Existing 0.7.2 behavior remains compatible and current bash smoke tests pass.
- [x] SC-014: Release evidence includes SHA256 for the package used in sandbox verification.
- [x] SC-015: No completion is claimed while mandatory rows are missing or failed.

## Known Blockers and Deferrals

- No platform, package, release workflow, published-asset, or real-agent verification blockers remain for v1.0.0.
- GIF regeneration is deferred because `vhs` is not available in WSL PATH. Existing demo assets are explicitly labelled illustrative/transcript-derived and are not used as release verification evidence.
- `v1.0.0` is published at `https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v1.0.0`; upstream Spec Kit catalog update issue is `https://github.com/github/spec-kit/issues/2844`.

## US1 Gate Evidence

| Check | Command or inspection | Result | Notes |
|---|---|---|---|
| Release readiness, source | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/validate-release-readiness.ps1 -Version 1.0.0` | PASS | Version, catalog, namespace, changelog, script parity, `.gitattributes`, workflow inventory. |
| Release readiness, package ZIP | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/validate-release-readiness.ps1 -Version 1.0.0 -PackageZip dist/speckit-superpowers-bridge-v1.0.0.zip` | PASS | Required ZIP root files, commands, bash scripts, PowerShell scripts, and portable entries. |
| Validator self-tests | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/test-validate-release-readiness.ps1` | PASS | Includes version mismatch, catalog id mismatch, command namespace mismatch, hook namespace mismatch, stale workflow reference, PowerShell package-builder rollback fixture, and missing package PowerShell flavor fixtures. |
| Package smoke | `bash tests/test-release-package.sh` | PASS | Source inventory, deterministic bash build, normalized ZIP modes, readiness output, README parity, and built ZIP inspection all passed. |
| Extension surface audit | `extension.yml` inspection + file counts | PASS | Commands: 3; hooks: 5; bash scripts: 6; PowerShell scripts: 6. Namespaces preserved as `speckit.speckit-superpowers-bridge.*`. |
| No-heavy-runtime audit | `grep -RInE 'daemon|database|sqlite|postgres|redis|node_modules|docker-compose' .specify/extensions/speckit-superpowers-bridge` | PASS | No heavy runtime/state-machine markers found in the bridge package. |
| Vendor-managed skill audit | `git diff --name-only -- .agents/skills .claude/skills` + `git ls-files '.agents/skills/speckit-*' '.claude/skills/speckit-*'` | PASS | No generated Spec Kit skill diffs; tracked skill files are only the project-owned bridge peers. |

## Build Script Decision

The CI release job now builds the package with `bash scripts/release/build-extension-zip.sh --version 1.0.0`. This avoids Linux runner differences in PowerShell hidden-file enumeration and makes WSL/Linux the preferred release-build path. The bash builder fixes ZIP entry ordering, timestamps, and permissions so repeated builds produce the same SHA256. It also normalizes ZIP modes (`scripts/bash/*.sh` as `0755`, all other files as `0644`) so WSL checkouts under `/mnt/c` match GitHub's clean checkout artifact. The PowerShell builder remains as a Windows-compatible fallback and was patched with `Get-ChildItem -Force` so dotfiles such as `.gitattributes` are not omitted if maintainers run it manually.

## US2 Platform Gate Evidence

| Check | Command or inspection | Result | Notes |
|---|---|---|---|
| Linux bash full suite | `bash tests/run-all.sh` | PASS | All 6 bash smoke tests passed, including `tests/test-release-package.sh` against the built 1.0.0 ZIP. |
| Windows PowerShell smoke | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/test-release-powershell.ps1` | PASS | Exercised `update-handoff.ps1`, `guard-command.ps1`, `bridge-status.ps1`, `auto-archive-handoff.ps1`, pending-task output, and CRLF-sensitive source checks. |
| Release workflow inventory | `.github/workflows/release.yml` inspection plus validator self-test | PASS | Workflow now has separate `linux-gate`, `windows-gate`, and `release` jobs; no removed `tests/*.ps1` scan remains; package build, release-note extraction, and summary generation are bash-first. |
| Release runbook | `docs/release-runbook.md` inspection | PASS | Documents Linux bash, native Windows PowerShell 5.1+, package validation, sandbox, real-agent, demo, tag, stable-alias, and upstream catalog steps. |
| Line-ending policy | `.gitattributes` inspection | PASS | Existing `*.sh text eol=lf` and `*.ps1 text eol=crlf` rules are already correct; no `.gitattributes` change required. |

## US4 Readiness and Documentation Evidence

| Check | Command or inspection | Result | Notes |
|---|---|---|---|
| Bash readiness human output | `bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh --readiness --actor codex` | PASS | Output includes script flavor, required tools, namespace, package files, bridge state, agents, and next action. |
| Bash readiness JSON output | `bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh --readiness --json --actor codex` | PASS | JSON includes `script_flavor`, `required_tools`, `namespace`, `package_files`, `bridge_state`, `agents`, `overall_status`, and `next`. |
| PowerShell readiness output | `tests/test-release-powershell.ps1` | PASS | Synthetic package fixture checks `-Readiness` and `-Readiness -Json` categories. |
| README parity | `bash tests/test-release-package.sh` | PASS | Both README files mention 1.0.0, Windows, Linux, readiness, Codex, Claude, Superspec, SuperB, and Comet. |
| Bridge skill docs | `.agents/skills/speckit-superpowers-bridge/SKILL.md` and `.claude/skills/speckit-superpowers-bridge/SKILL.md` inspection | PASS | Both peers document the v1.0.0 readiness mode. |

## US3 Real-Agent Evidence

| Agent | Command | Result | Evidence |
|---|---|---|---|
| Codex | `codex --ask-for-approval never exec -C ../test_specify_superpower/v1-0-linux-20260604T072552Z --sandbox workspace-write ...` | PASS | `../test_specify_superpower/v1-0-linux-20260604T072552Z/.specify/bridge-verification/codex-v1.0.0-rc.md` |
| Claude Code | `claude -p --permission-mode bypassPermissions --max-budget-usd 5 --output-format text` from the same sandbox | PASS | `../test_specify_superpower/v1-0-linux-20260604T072552Z/.specify/bridge-verification/claude-v1.0.0-rc.md` |

## US5 Publish Evidence

| Check | Command or inspection | Result | Notes |
|---|---|---|---|
| Demo truth labels | `bash tests/test-release-package.sh` | PASS | Checks `docs/demo/README.md`, `docs/demo/hero.tape`, and `docs/demo/full-cycle.tape` for `Truth label:` and illustrative wording. |
| Marketplace metadata checks | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/test-validate-release-readiness.ps1` | PASS | Self-tests cover catalog id/version/capability counts, official catalog fields, community README row support summary, stable alias, command/hook counts, support matrix, and validation summary. |
| Official publishing guide alignment | `scripts/release/validate-release-readiness.ps1` plus official guide inspection | PASS | Release runbook now uses GitHub's Extension Submission issue template and explicitly avoids direct PR edits to `extensions/catalog.community.json`; submission body includes testing checklist, requirements, testing details, example usage, and proposed catalog JSON. |
| Final evidence completeness checks | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/test-validate-release-readiness.ps1` | PASS | Self-tests cover artifact SHA256, Linux/Windows platform rows, Codex/Claude rows, release workflow evidence, and blocker section. |
| Release readiness, source | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/validate-release-readiness.ps1 -Version 1.0.0` | PASS | `Release readiness OK for version 1.0.0.` |
| Release readiness, package ZIP | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/validate-release-readiness.ps1 -Version 1.0.0 -PackageZip dist/speckit-superpowers-bridge-v1.0.0.zip` | PASS | `Release readiness OK for version 1.0.0.` |
| Validator self-tests | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/release/test-validate-release-readiness.ps1` | PASS | Ends with `validate-release-readiness-tests-ok`. |
| Final package build | `bash scripts/release/build-extension-zip.sh --version 1.0.0` | PASS | Built `dist/speckit-superpowers-bridge-v1.0.0.zip` and stable alias `dist/speckit-superpowers-bridge.zip`; both SHA256 values are `b54e6f1a0b8acaca7499add926740912f87649eb80b3200e0dc66fca95bed711`. Rebuilding twice in `tests/test-release-package.sh` produced the same SHA and normalized ZIP modes. |
| Linux bash final suite | `bash tests/run-all.sh` | PASS | All 6 bash smoke tests passed. |
| Windows PowerShell final smoke | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/test-release-powershell.ps1` | PASS | Ends with `release-powershell-tests-ok`; expected warning fixture verifies incomplete-task warning behavior. |
| Release workflow | `gh run watch <v1.0.0 tag run> --repo lihan3238/speckit-superpowers-bridge --exit-status` | PASS | Linux gate, Windows gate, and build/publish release job all passed for the final `v1.0.0` tag push. |
| Published release assets | `curl -fsSL` versioned ZIP and latest alias, then `sha256sum` | PASS | Versioned and stable-alias downloads both returned SHA256 `b54e6f1a0b8acaca7499add926740912f87649eb80b3200e0dc66fca95bed711`; HEAD checks returned 302 -> 200. |
| Publish tag/release | `git push --force ... v1.0.0` + release workflow | PASS | Release URL: `https://github.com/lihan3238/speckit-superpowers-bridge/releases/tag/v1.0.0`; workflow uploaded both the versioned ZIP and stable-alias ZIP. |
| Upstream catalog submission | GitHub issue | PASS | `https://github.com/github/spec-kit/issues/2844` opened using `marketplace/extension-submission-body.md` as the source body. |
