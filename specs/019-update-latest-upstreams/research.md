# Research: Latest Upstream Alignment

**Date**: 2026-09-26

## R1. Official release baselines

**Decision**: Adopt Spec Kit v1.0.12 and Superpowers v6.4.2.

**Evidence**:
- Spec Kit release tag `v1.0.12`, commit `e77daa9021d20db26b878f7dfa5640fe5a42d04e`, published 2026-09-25.
- Superpowers release tag `v6.4.2`, commit `8ca22dba9a94f28898bbce59f2537ff4d87c747d`.
- Local development tools after upgrade: `specify 1.0.12`, Codex CLI `0.157.1`, Claude Code `2.1.283`.

**Rationale**: These are the latest stable official releases available on the feature date. Pre-release and development tags are excluded.

## R2. Spec Kit hook contract

**Decision**: Update bridge documentation and focused contract tests to report malformed `.specify/extensions.yml` with the parser error and state that no hooks, including mandatory hooks, were checked; continue normally. Keep the existing filtering, command rendering, mandatory `EXECUTE_COMMAND:` directive, actual invocation/wait, and failure-transition rules.

**Evidence**: Spec Kit v1.0.12 `templates/commands/implement.md` changes the invalid-YAML instruction from silent skipping to explicit reporting. The bridge's current project-owned peers and execute command still contain the older silent-skip wording. The v1.0.12 implement hook contract does not change the mandatory/optional invocation semantics introduced in v1.2.0.

**Alternative rejected**: Implementing a second YAML parser or hook runner in the bridge would duplicate upstream behavior and violate Native-First Compatibility. The bridge updates its agent-facing contract only.

## R3. Spec Kit tracked source refresh

**Decision**: Refresh tracked `.specify/extensions/git/` and `.specify/extensions/agent-context/` from v1.0.12, including extension version 1.0.1, POSIX/ASCII-safe branch-name normalization, and the `muse` agent default. Refresh command placeholders in tracked templates, then reapply project-owned release and Native-First gate callouts.

**Evidence**: Official v1.0.12 source diff against the v0.16.4 baseline shows the git branch script's `LC_ALL=C`, `sed 's/--*/-/g'`, and safe `printf` changes; agent-context configuration/defaults and extension metadata changed; plan/tasks templates use command placeholders. The bridge-owned release gates are not upstream and must remain.

## R4. Superpowers execution semantics

**Decision**: Keep the bridge's explicit invocation of `superpowers:executing-plans`, but derive an ephemeral adapter plan outside the native `.superpowers/sdd/` workspace at a stable repository/feature-derived temporary path. The adapter maps each canonical Spec Kit checkbox task ID to a `Task N` heading required by v6.4.2, while exact task text, requirements, and completion status remain in `tasks.md`. Document that v6.4.2 executes the adapter inline in the current session and does not dispatch an implementer/reviewer subagent for every task. Continue invoking the bridge's explicit verification, code-review, and finishing skills after task execution. Do not switch the bridge to `subagent-driven-development` because that would change the established orchestration contract; that skill remains available as a native upstream option.

**Evidence**: v6.4.2 retains all bridge-invoked skill identifiers. Its `executing-plans` description and process are materially rewritten for inline execution, and its `task-brief` extractor requires `#+ Task N` headings. Spec Kit tasks-template continues to use checkbox IDs, so direct invocation against `tasks.md` would fail. `subagent-driven-development` remains the separate per-task subagent route.

## R5. Bridge invariants

**Decision**: Keep the runtime floor `>=0.8.10`, three bridge commands, five registered bridge hooks, handoff v1 schema, actor semantics, guard rules, and stable-alias URL.

**Evidence**: Spec Kit v1.0.12's extension manifest validator accepts the current bridge manifest and all three commands/aliases. No upstream change requires new bridge state or a schema field. The focused smoke suite remains the required regression boundary.

## R6. Release version

**Decision**: Publish bridge v1.3.0.

**Rationale**: This release advances both supported upstream compatibility baselines and refreshes tracked vendor sources and agent-facing contract semantics. It does not alter the bridge protocol, so the version is a backward-compatible minor release.
