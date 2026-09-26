# Upstream Compatibility Contract

## Adopted baselines

| Component | Version | Commit/evidence |
|---|---:|---|
| Spec Kit CLI and tracked source | 1.0.12 | `e77daa9021d20db26b878f7dfa5640fe5a42d04e` |
| Superpowers | 6.4.2 | `8ca22dba9a94f28898bbce59f2537ff4d87c747d` |
| Bridge release | 1.3.0 | release metadata and published artifact |

## Spec Kit hook handling

1. Read `.specify/extensions.yml` when present.
2. If YAML is missing or malformed, report the parser error and state that no hooks were checked, including mandatory hooks; continue the core command normally.
3. Skip disabled hooks.
4. Skip hooks with non-empty conditions because condition evaluation belongs to the upstream HookExecutor.
5. Render command IDs by replacing dots with hyphens for the active agent.
6. Show optional hooks for confirmation.
7. Emit Spec Kit's phase-specific mandatory automatic-hook directive, invoke the rendered command, and wait for its result.
8. Stop on a mandatory hook failure. An optional decline does not fail the lifecycle.
9. Run `after_implement` before handoff `complete`; leave the handoff non-complete if a mandatory post-hook fails.

## Superpowers delegation and task adapter

Spec Kit `tasks.md` remains the sole requirements contract and continues to use checkbox IDs such as `T001`. Before invoking `superpowers:executing-plans`, the bridge creates a disposable adapter outside the native `.superpowers/sdd/` workspace (for example, a stable repository/feature-derived OS temporary file reused on resume). Each adapter entry has a `### Task N: T###` heading and the exact canonical task text; it also points to the Spec Kit spec, plan, and global constraints. The adapter is execution scaffolding, not a second source of requirements, and is removed after the run. The bridge verifies canonical `tasks.md` completion before the handoff can complete.

Under v6.4.2 the native executor runs this adapter inline. The bridge then invokes verification, code review, and branch-finishing skills explicitly. It does not invoke `writing-plans` or `brainstorming` for an active Spec Kit feature. `subagent-driven-development` is an upstream alternative, not a new bridge command.

## Preserved bridge invariants

- Three bridge commands and five registered bridge hooks.
- Handoff v1 fields and transitions, actor logging, snapshots, and guard rules.
- Stable latest-release download alias.
- Runtime floor `>=0.8.10`.
- Identical Codex and Claude skill peers in contract and ordering.
