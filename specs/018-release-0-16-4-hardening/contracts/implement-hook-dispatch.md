# Contract: Implement Hook Dispatch Through the Bridge

## Source

Read `.specify/extensions.yml` and select `hooks.before_implement` or `hooks.after_implement`. Missing or invalid YAML skips dispatch, matching Spec Kit core-command behavior.

## Filtering

For each configured hook in YAML order:

1. Skip `enabled: false`; missing `enabled` means enabled.
2. Skip a non-empty `condition`; condition evaluation remains upstream-owned.
3. Skip any hook whose `extension` is `speckit-superpowers-bridge` so the bridge never fires its own implement guard.

## Optional hooks

- Surface extension, command, description, prompt, and agent-native invocation.
- Run only after user confirmation.
- Declining an optional hook does not fail implementation.

## Mandatory hooks

- Emit the Spec Kit automatic-hook block, including `EXECUTE_COMMAND: <dotted-command-id>`.
- Actually invoke the command in the active agent (`$speckit-...` for Codex, `/speckit-...` for Claude Code) and wait for the result.
- Emitting the directive alone is not success.
- A failing mandatory hook stops the lifecycle.

## Lifecycle order

1. Dispatch mandatory/accepted optional `before_implement` hooks.
2. Only after they succeed, transition the handoff to `executing` and run the implementation discipline.
3. After tasks, verification, review, and branch-finishing steps succeed, dispatch `after_implement` hooks.
4. Only after mandatory post-hooks succeed, transition the handoff to `complete` and report completion.

## State guarantees

- Pre-hook failure leaves the handoff non-executing.
- Post-hook failure leaves the handoff non-complete and must be surfaced for recovery.
- Hook dispatch does not change handoff schema, guard rules, command count, or hook count.
