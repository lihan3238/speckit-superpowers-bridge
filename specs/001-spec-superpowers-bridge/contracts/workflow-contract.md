# Contract: Spec Kit + Superpowers Workflow

## Workflow Identity

- Workflow id: `speckit-superpowers`
- Purpose: run Spec Kit design/task steps, then hand implementation to Superpowers without running `speckit.implement`.

## Supported Integrations

The workflow must allow either `codex` or `claude` when installed.

```yaml
requires:
  speckit_version: ">=0.8.9"
  integrations:
    any: ["codex", "claude"]
```

## Step Order

1. `speckit.specify`
2. spec review gate
3. `speckit.clarify`
4. `speckit.plan`
5. plan review gate
6. `speckit.tasks`
7. `speckit.analyze`
8. `speckit.superpowers.handoff`

## Forbidden Step

The workflow must not include `speckit.implement`.

## Handoff Output

After tasks are generated, the workflow must create or update `.specify/superpowers-handoff.json` with:

- active feature directory
- source-of-truth artifacts
- `executor: "superpowers"`
- `supersedes: ["speckit.implement"]`
- allowed Superpowers execution-discipline capabilities
- handoff status
- artifact write ownership metadata

## Agent Invocation Notes

Workflow command ids remain dotted internally. Agent-facing examples must use the local integration syntax:

- Codex example: `$speckit-plan`
- Claude Code example: `/speckit-plan`
