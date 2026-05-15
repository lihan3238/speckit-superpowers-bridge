---
description: "Recommend whether a small change should go direct to Superpowers instead of the full Spec Kit pipeline"
---

# Bridge Workflow Routing Recommendation

This command is normally reached through the `before_specify` hook so `/speckit-specify` can surface a one-line advisory before the full Spec Kit pipeline starts.

It never auto-routes. It only prints a suggestion when the feature description is short, contains a small-fix keyword, and does not contain a large-scope keyword.

## Execution

When invoked as a `before_specify` hook, use the feature description from the triggering `/speckit-specify` or `$speckit-specify` message if it is available:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\recommend-route.ps1 -Description "<feature description>"
```

If the hook runner does not expose the description, run the script without `-Description`. It exits 0 and emits no advisory, so the normal Spec Kit flow continues.

Use `-Json` for deterministic test output.
