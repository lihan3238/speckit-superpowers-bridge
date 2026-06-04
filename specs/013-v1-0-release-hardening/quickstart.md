# Quickstart: v1.0.0 Release Candidate Verification

This quickstart describes the intended 1.0.0 verification flow after implementation tasks are complete.

## 1. Preflight

From the source repository root:

```bash
git status --short --branch
specify --version
codex --version
claude --version
```

Confirm:

- Active branch is `013-v1-0-release-hardening` or the final release branch.
- No unrelated dirty files will be included in the release commit.
- Spec Kit, Codex, and Claude versions are recorded in verification evidence.

## 2. Build a Release-Equivalent Artifact

Before the public tag exists, build a release-equivalent ZIP:

```powershell
.\scripts\release\validate-release-readiness.ps1 -Version 1.0.0
.\scripts\release\build-extension-zip.ps1 -Version 1.0.0
```

Record:

- `dist/speckit-superpowers-bridge-v1.0.0.zip`
- `dist/speckit-superpowers-bridge.zip`
- SHA256 from build output

After publication, repeat reachability checks against the GitHub release URL and stable alias.

## 3. Linux Bash Gate

From Linux bash or WSL bash:

```bash
bash tests/run-all.sh
```

Then install the packaged artifact into the sibling sandbox and run the Linux bridge cycle. The exact sandbox command may evolve during implementation, but the evidence must show:

- install source is the packaged ZIP or release URL
- script flavor is `sh`
- guard, handoff, status/readiness, and archive paths were exercised
- result is pass/fail

Record the row in `verification.md`.

## 4. Windows PowerShell Gate

From native Windows PowerShell 5.1+:

```powershell
$PSVersionTable.PSVersion
.\scripts\release\validate-release-readiness.ps1 -Version 1.0.0
```

Run the focused PowerShell bridge smoke checks created for this feature. The evidence must show:

- script flavor is `ps`
- package installs without requiring WSL or Git Bash
- guard, handoff, status/readiness, and archive paths were exercised
- line-ending and encoding-sensitive outputs are readable

Record the row in `verification.md`.

## 5. Real Codex Verification

In `../test_specify_superpower`, run a bounded Codex verification using the release artifact. Prefer noninteractive mode so the result is reproducible.

The prompt boundary must require Codex to:

- stay inside the sandbox
- inspect installed bridge state
- exercise status/readiness and guard/handoff boundaries
- avoid modifying the source repository
- report pass/fail with commands run

Record Codex version, platform, prompt boundary, result, and evidence path.

## 6. Real Claude Code Verification

In `../test_specify_superpower`, run a bounded Claude Code verification using the release artifact.

The prompt boundary must require Claude to:

- stay inside the sandbox
- load project instructions and bridge skill
- exercise the same bridge contract as the Codex run
- avoid modifying the source repository
- report pass/fail with commands run

Record Claude version, platform, prompt boundary, result, and evidence path.

## 7. Documentation and Demo Evidence

Verify README parity:

```bash
grep -n "1.0.0\\|Windows\\|Linux\\|readiness\\|Codex\\|Claude" README.md README.zh-CN.md
```

If demo tooling is available:

```bash
bash scripts/render-demos.sh
```

Only publish regenerated GIFs if they are tied to a real sandbox transcript or run. If tooling is unavailable, record transcript evidence instead and label existing demos accurately.

## 8. Final Release Readiness

Before tagging:

```bash
bash tests/run-all.sh
```

From PowerShell:

```powershell
.\scripts\release\validate-release-readiness.ps1 -Version 1.0.0
.\scripts\release\test-validate-release-readiness.ps1
.\scripts\release\build-extension-zip.ps1 -Version 1.0.0
```

Confirm `verification.md` contains:

- artifact SHA256
- passing Linux bash row
- passing Windows PowerShell row
- Codex row
- Claude row
- release workflow status
- demo or transcript status
- known blockers and deferrals

## 9. Tag and Publish

Follow `docs/release-runbook.md` after it has been updated by this feature. After publishing:

- verify versioned ZIP URL returns success
- verify stable alias URL resolves
- verify artifact hash matches the recorded release
- prepare upstream Spec Kit catalog submission from `marketplace/`
