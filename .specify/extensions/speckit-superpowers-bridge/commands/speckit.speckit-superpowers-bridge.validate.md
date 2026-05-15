---
description: "Run the bridge end-to-end validation pass"
---

# Bridge Validation Pass

Run the validation pass before marking a bridged feature complete. It checks handoff state, disposition matrix coverage, install-state audit, feature artifacts, explicit Superpowers skill invocation events, bridge skill wording, and the core guard smoke suite.

## Execution

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1 -Json
```

The script appends a `validation_pass` bridge event and, on failure, records compatibility gap rows in the active feature's `compat-gaps.md`.
