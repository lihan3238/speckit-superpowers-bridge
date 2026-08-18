# Quickstart: Validate v1.2.0 Release Hardening

## Prerequisites

- Spec Kit CLI `0.16.4`
- Superpowers source tag `v6.3.0` available for the compatibility audit
- Bash >=4.0, `jq`, `git`, `gh`, and PowerShell for cross-platform checks
- Canonical sibling sandbox at `../test_specify_superpower`

## 1. Verify tracked Spec Kit alignment

```bash
specify --version
specify extension list
specify integration status
git diff --check
```

Expected: Spec Kit reports `0.16.4`; git and agent-context are installed from refreshed bundled sources; Claude and Codex integration files exist; project-owned bridge peers retain their orchestrator contract.

## 2. Run focused regressions

```bash
bash tests/test-update-handoff-portability.sh
bash tests/test-implement-hooks-dispatch.sh
```

Expected: path normalization succeeds when a fake macOS-style `realpath` rejects `-m`; hook tests verify standard directive, actual-invocation language, skip rules, and completion ordering.

## 3. Run the full source gates

```bash
bash tests/run-all.sh
pwsh -NoProfile -File scripts/release/test-validate-release-readiness.ps1
pwsh -NoProfile -File scripts/release/validate-release-readiness.ps1 -Version 1.2.0
```

On native Windows PowerShell:

```powershell
.\tests\test-release-powershell.ps1
.\scripts\release\validate-release-readiness.ps1 -Version 1.2.0
```

## 4. Build and inspect the release archive

```bash
bash scripts/release/build-extension-zip.sh --version 1.2.0
bash tests/test-release-package.sh
pwsh -NoProfile -File scripts/release/validate-release-readiness.ps1 \
  -Version 1.2.0 \
  -PackageZip dist/speckit-superpowers-bridge-v1.2.0.zip
sha256sum dist/speckit-superpowers-bridge-v1.2.0.zip
```

## 5. Publish and verify the public asset

After the release commit is merged to `main`, tag and push `v1.2.0`. Wait for the release workflow's Linux, Windows, macOS, and publish jobs.

Install from the public URL, never the in-repo `--dev` source:

```bash
echo y | specify extension add speckit-superpowers-bridge --force \
  --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v1.2.0/speckit-superpowers-bridge-v1.2.0.zip
```

Run a complete bridge cycle in the WSL sandbox and the native Windows sandbox, including synthetic implement hooks. Record the downloaded asset SHA256, handoff transitions, hook observations, and platform result in [verification.md](verification.md).

## 6. Close release coordination

- Confirm the stable latest-release alias downloads the same archive.
- Close Issue #13 with the release and verification links.
- Submit the upstream Spec Kit Extension Submission issue using `marketplace/extension-submission-body.md`.
