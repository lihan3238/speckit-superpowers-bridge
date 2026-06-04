# Contract: Release Readiness Validation

## Purpose

Define the mandatory release checks that must pass before tagging `v1.0.0`.

## Inputs

- Target version, expected `1.0.0`.
- Repository root.
- Optional packaged ZIP path for package-content inspection.

## Required Checks

### Version Synchronization

The validator must check:

- `.specify/extensions/speckit-superpowers-bridge/extension.yml`
- `marketplace/catalog-entry.json`
- `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`
- `CHANGELOG.md`
- release notes or runbook references where version is explicitly asserted

All release-version fields must match `1.0.0`.

### Namespace Alignment

The validator must check:

- `extension.id` is `speckit-superpowers-bridge`
- catalog id matches `extension.id`
- every bridge command name starts with `speckit.speckit-superpowers-bridge.`
- every bridge hook command starts with `speckit.speckit-superpowers-bridge.`
- documentation does not instruct users to install or invoke a stale namespace as the canonical 1.0.0 path

### Package Contents

When a ZIP path is provided, the validator must check:

- `extension.yml` exists at archive root
- `commands/` files exist
- `scripts/bash/` files exist
- `scripts/powershell/` files exist
- `verified-versions.json` exists
- README, Chinese README, license, changelog, and `.gitattributes` are included when expected
- ZIP entry names use `/` separators

### Platform Evidence

The validator or release runbook must require recorded evidence for:

- Linux bash smoke suite
- Linux bash sandbox install cycle
- Windows PowerShell smoke or equivalent package-install cycle
- Windows PowerShell sandbox install cycle

The exact verification record may live in `verification.md`, but missing mandatory rows block release completion.

### Agent Evidence

The validator or release runbook must require recorded Codex and Claude rows:

- `pass` rows may be claimed in release notes
- `blocked` rows must include exact reason and must not be advertised as verified
- missing rows block completion

## Output

Human output:

```text
Release readiness OK for version 1.0.0.
```

or

```text
Release readiness FAILED for version 1.0.0:
  - <problem>
  - <problem>
```

Machine-readable output may be added if useful but is not required for 1.0.0.

## Exit Codes

- `0`: all required checks passed
- `1`: readiness failed
- `2`: usage error or repository root missing

## Regression Requirement

Self-tests must include at least one failing fixture for:

- mismatched version
- command namespace mismatch
- hook namespace mismatch
- missing script flavor in ZIP
- stale catalog id
- release workflow referencing nonexistent tests
