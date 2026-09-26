# Quickstart: Latest Upstream Alignment and v1.3.0

## Prerequisites

- Bash 5.2 or compatible Bash >=4.0, jq >=1.6, Git, GitHub CLI.
- Spec Kit CLI 1.0.12.
- Native Windows PowerShell 5.1+ for the Windows gate when available.
- `../test_specify_superpower` as the end-user sandbox.

## Bootstrap and source checks

```bash
specify --version
specify init --here --integration claude --script sh --extension git --extension agent-context --force
specify integration install codex --script sh --force
specify init --here --integration codex --script sh --extension git --extension agent-context --force
git diff --check
```

Expected: `specify 1.0.12`; generated state is current; project-owned bridge skills and governance gates remain present.

## Focused bridge checks

```bash
bash tests/test-implement-hooks-dispatch.sh
bash tests/test-claude-codex-skill-parity.sh
bash tests/test-handoff-shape.sh
bash tests/test-bridge-status.sh
bash tests/test-update-handoff-portability.sh
```

Expected: each focused test passes, including malformed extension-registry reporting and inline execution wording.

## Full and package checks

```bash
bash tests/run-all.sh
bash scripts/release/build-extension-zip.sh --version 1.3.0
bash tests/test-release-package.sh
```

Validate source and ZIP with `scripts/release/validate-release-readiness.ps1 -Version 1.3.0` on PowerShell. Record the ZIP SHA256 in `verification.md`.

## Sandbox and publication checks

Install the versioned public ZIP in `../test_specify_superpower` after the release workflow publishes both the versioned and stable-alias assets. Drive guard, handoff, status/readiness, archive, and a full bridge lifecycle on each available platform. Record platform, tool versions, asset SHA256, and result in `verification.md`. Mark unavailable native macOS evidence as hosted or deferred.
