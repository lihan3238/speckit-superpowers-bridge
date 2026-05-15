---
description: "Audit bridge install state, integration parity, and remediable skill gaps"
---

# Bridge Install-State Audit

Run the bridge install-state audit when Codex/Claude integrations may be out of sync, after `specify integration upgrade`, or before publishing the bridge.

## Behavior

The audit reports:

- Spec Kit version and default integration
- Installed integration manifests
- Git extension presence and commands
- Codex/Claude skill parity and content divergence
- Script flavour (`ps` or `sh`)
- Concrete remediation commands, including `specify integration upgrade codex`, `specify integration upgrade claude`, and manual copy fallback notes

## Execution

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\audit-install-state.ps1 -Json
```

Actor resolution follows the shared bridge order: explicit `-Actor`, `SPECKIT_BRIDGE_ACTOR`, `default_integration`, `unknown`.
