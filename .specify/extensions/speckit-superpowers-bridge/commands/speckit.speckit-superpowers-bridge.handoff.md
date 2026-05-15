---
description: "Create or update the Superpowers implementation handoff state"
---

# Superpowers Handoff

Create `.specify/superpowers-handoff.json` so Spec Kit artifacts explicitly hand implementation to Superpowers.

## Behavior

1. Resolve the active feature directory from `.specify/feature.json`.
2. Verify the feature has `spec.md`, `plan.md`, and `tasks.md`.
3. Write `.specify/superpowers-handoff.json` with:
   - `feature_directory`
   - `source_of_truth`
   - `supersedes: ["speckit.implement"]`
   - `executor: "superpowers"`
   - Superpowers capabilities for implementation discipline
   - `status`
   - `artifact_owner`
   - `review_only_agents`
4. Tell the implementation agent to invoke the bridge:
   - Codex: `$speckit-superpowers-bridge`
   - Claude Code: `/speckit-superpowers-bridge`

## Execution

Run this from the repository root. Use `.specify/init-options.json.script` to choose the flavor (`ps` => PowerShell, `sh` => bash).

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready
```

```bash
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh --status ready
```

Actor resolution order is:

1. Explicit `-Actor <codex|claude|unknown>` / `--actor <codex|claude|unknown>`
2. Environment variable `SPECKIT_BRIDGE_ACTOR`
3. Deterministic fallback `unknown`

If required feature artifacts are missing, the script writes status `blocked`. In that case, return to Spec Kit and regenerate or repair the missing artifacts before implementation.
