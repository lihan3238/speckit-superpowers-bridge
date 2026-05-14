# Quickstart: Spec Kit Superpowers Bridge

## 1. Verify integrations

```powershell
specify integration list
Get-Content .specify\integration.json
```

Expected for dual-agent testing:

```json
{
  "installed_integrations": ["codex", "claude"],
  "default_integration": "codex"
}
```

`default_integration` may be `codex` or `claude`; it must not change the bridge contract.

## 2. Install the missing integration if needed

Codex-first setup:

```powershell
specify init . --integration codex
specify integration install claude
```

Claude-first setup:

```powershell
specify init . --integration claude
specify integration install codex
```

Upgrade both generated integration skill sets when Spec Kit is upgraded:

```powershell
specify integration upgrade codex
specify integration upgrade claude
```

Do not hand-edit official `.agents\skills\speckit-*` or `.claude\skills\speckit-*`.

## 3. Confirm context files

`AGENTS.md` must contain the master bridge protocol.

`CLAUDE.md` must tell Claude Code to read `AGENTS.md` first and must only add Claude-specific guidance.

Concrete invocation examples:

```text
Codex:       $speckit-plan
Claude Code: /speckit-plan
Internal id: speckit.plan
```

## 4. Run the Spec Kit trunk

Codex example:

```text
$speckit-specify <feature description>
$speckit-clarify
$speckit-plan
$speckit-tasks
$speckit-analyze
```

Claude Code example:

```text
/speckit-specify <feature description>
/speckit-clarify
/speckit-plan
/speckit-tasks
/speckit-analyze
```

Only one agent should own Spec Kit artifact writes during these steps. The other agent can review.

## 5. Create the Superpowers handoff

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status ready -Actor codex
```

Validate the state:

```powershell
Get-Content .specify\superpowers-handoff.json
```

Expected:

- `executor` is `superpowers`
- `supersedes` includes `speckit.implement`
- `source_of_truth` points to `spec.md`, `plan.md`, and `tasks.md`
- `artifact_owner` is set to the active writer, usually `codex` or `claude`
- `review_only_agents` lists installed agents that may review but not write

## 6. Execute through the bridge, not speckit.implement

Codex uses:

```text
$speckit-superpowers-bridge
```

Claude Code uses:

```text
/speckit-superpowers-bridge
```

The bridge skill must read `spec.md`, `plan.md`, `tasks.md`, and `.specify/superpowers-handoff.json` before implementation.

## 7. Validate guard, log, and rollback

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action speckit.implement -Actor codex
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\guard-command.ps1 -Action superpowers.writing-plans -Actor codex
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\test-bridge-guard.ps1
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\test-bridge-context.ps1
```

Inspect events:

```powershell
Get-Content .specify\bridge-events.jsonl
```

Restore a control-artifact snapshot:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\restore-snapshot.ps1 -SnapshotId <snapshot-id>
```

## 8. Complete or repair

When implementation is complete and verified:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status complete -Actor codex
```

If implementation reveals wrong or missing Spec Kit artifacts:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\update-handoff.ps1 -Status blocked -Reason "Describe the missing or wrong Spec Kit artifact" -Actor codex
```

Then return to Spec Kit with the current artifact owner and repair `spec.md`, `plan.md`, or `tasks.md`.

## 9. Validate extension and workflow listings on Windows

PowerShell sessions using legacy Windows encodings may need UTF-8 output settings for Spec Kit list commands:

```powershell
$env:PYTHONIOENCODING = "utf-8"
specify extension list
specify workflow list
```
