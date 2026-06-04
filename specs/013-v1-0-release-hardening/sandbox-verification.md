# Sandbox Verification Notes: v1.0.0 Stable Protocol Release Hardening

The sibling sandbox `../test_specify_superpower` is the release simulation target. This file records the execution details before they are summarized in `verification.md`.

## Linux Bash

- Environment: WSL bash 5.2 on `/mnt/c/.../test_specify_superpower/v1-0-linux-final-20260604T082312Z`
- Script flavor: `sh`
- Install source: `http://127.0.0.1:8765/speckit-superpowers-bridge-v1.0.0.zip` served from built `dist/` artifact
- Artifact SHA256: `f47c178ba5cc284385b2ce9a5e3aa68fde8acf4c2b44b31bb31645f202d1e5c0`
- Commands run: `git init`; `specify init --here --integration claude --script sh --force`; `specify extension add speckit-superpowers-bridge --from <localhost ZIP>`; `bridge-status.sh --readiness`; `update-handoff.sh --status ready`; `guard-command.sh --action speckit.plan`; `update-handoff.sh --status executing`; `bridge-status.sh --readiness --json`; `update-handoff.sh --status complete`; `auto-archive-handoff.sh`.
- Result: PASS
- Notes: Final package row uses an independent child git repo so bridge repo-root discovery does not resolve to the parent sandbox repo.

## Windows PowerShell

- Environment: Native Windows PowerShell 5.1 on `C:\lihan_work\ai_workplace\test_specify_superpower\v1-0-windows-final-20260604T082340Z`
- Script flavor: `ps`
- Install source: `http://127.0.0.1:8765/speckit-superpowers-bridge-v1.0.0.zip` served from built `dist/` artifact
- Artifact SHA256: `f47c178ba5cc284385b2ce9a5e3aa68fde8acf4c2b44b31bb31645f202d1e5c0`
- Commands run: `git init`; `specify init --here --integration claude --script ps --offline --force`; `specify extension add speckit-superpowers-bridge --from <localhost ZIP>` with `PYTHONUTF8=1`; `bridge-status.ps1 -Readiness`; `update-handoff.ps1 -Status ready`; `guard-command.ps1 -Action speckit.plan`; `update-handoff.ps1 -Status executing`; `bridge-status.ps1 -Readiness -Json`; `update-handoff.ps1 -Status complete`; `auto-archive-handoff.ps1`.
- Result: PASS
- Notes: Windows `specify 0.8.10` under the default GBK console emitted a Rich `UnicodeEncodeError` after successful extension install because of the `✓` character. Setting `PYTHONUTF8=1` and `PYTHONIOENCODING=utf-8` produced a clean install transcript. Bridge PowerShell output itself remained readable and ASCII-compatible.

## Codex

- Version: `codex-cli 0.137.0`
- Prompt: `specs/013-v1-0-release-hardening/agent-prompts/codex-verification.md`
- Sandbox path: `../test_specify_superpower/v1-0-linux-20260604T072552Z`
- Commands run: `codex --ask-for-approval never exec -C <sandbox> --sandbox workspace-write ...`; Codex then ran manifest/package inspection, `bridge-status.sh`, `guard-command.sh --action speckit.plan`, `update-handoff.sh --status ready`, `update-handoff.sh --status executing`, `update-handoff.sh --status complete`, and evidence writing inside `.specify/bridge-verification/`.
- Result: PASS
- Evidence path: `../test_specify_superpower/v1-0-linux-20260604T072552Z/.specify/bridge-verification/codex-v1.0.0-rc.md`

## Claude Code

- Version: `2.1.162 (Claude Code)`
- Prompt: `specs/013-v1-0-release-hardening/agent-prompts/claude-verification.md`
- Sandbox path: `../test_specify_superpower/v1-0-linux-20260604T072552Z`
- Commands run: `claude -p --permission-mode bypassPermissions --max-budget-usd 5 --output-format text`; Claude then ran manifest inspection, `bridge-status.sh`, `guard-command.sh --action speckit.plan`, `update-handoff.sh --status ready`, `update-handoff.sh --status executing`, `update-handoff.sh --status complete`, and evidence writing inside `.specify/bridge-verification/`.
- Result: PASS
- Evidence path: `../test_specify_superpower/v1-0-linux-20260604T072552Z/.specify/bridge-verification/claude-v1.0.0-rc.md`
