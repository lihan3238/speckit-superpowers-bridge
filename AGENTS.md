<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

## Primary Design Reference

The canonical "north star" for this bridge's overall design direction is:

  **[Spec Kit vs Superpowers — A Comprehensive Comparison & Practical Guide to Combining Both](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)**

On any architectural question (which layer owns what, when each tool applies,
how they combine), consult this article first. The bridge codifies its
combination pattern: Spec Kit owns WHAT (constitution → spec → plan → tasks);
Superpowers owns HOW (TDD, worktrees, subagents, review). `tasks.md` is what
Superpowers' `executing-plans` is designed to consume — this is the contract
the bridge implements.

The article also warns that Superpowers auto-trigger can derail sessions; the
bridge therefore uses **explicit** invocation of Superpowers skills at named
phases (codified by feature 002's disposition matrix and feature 004's FR-009
/ FR-010).

## Spec Kit + Superpowers Bridge

- Spec Kit owns design-time artifacts: `.specify/memory/constitution.md`, `specs/<feature>/spec.md`, `specs/<feature>/plan.md`, `specs/<feature>/tasks.md`, checklists, and analysis.
- Superpowers owns implementation discipline: isolated workspaces, TDD, systematic debugging, task execution, code review, verification, and finishing the development branch.
- `specs/<feature>/tasks.md` is the only implementation contract. Do not use Superpowers `writing-plans` to replace Spec Kit `plan.md` or `tasks.md` once they exist.
- When `.specify/superpowers-handoff.json` declares `"executor": "superpowers"`, do not run `speckit.implement`; execute the listed `tasks.md` through the `speckit-superpowers-bridge` skill instead.
- If implementation reveals missing or wrong requirements, stop implementation, mark the handoff `blocked`, and return to Spec Kit to update `spec.md`, `plan.md`, or `tasks.md`.
- When an active Spec Kit feature has `spec.md`, `plan.md`, and `tasks.md`, Superpowers `brainstorming` and `writing-plans` are disabled for that feature unless the user explicitly says to discard or replace the Spec Kit artifacts.
- Superpowers `subagent-driven-development` and `executing-plans` may run only through `speckit-superpowers-bridge` and must use Spec Kit `tasks.md` as the plan.
- Before crossing these boundaries, run `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1`; every allow/deny decision is logged in `.specify/bridge-events.jsonl`.
- Pass `-Actor codex` from Codex and `-Actor claude` from Claude Code when invoking bridge guard or handoff scripts.
- If `-Actor` is omitted, bridge scripts resolve actor from `SPECKIT_BRIDGE_ACTOR`, then `.specify/integration.json.default_integration`, then `unknown`.
- Command IDs and agent invocations are different: internal Spec Kit command IDs use dots such as `speckit.plan`; Codex uses `$speckit-plan`; Claude Code uses slash commands generated from skill names such as `/speckit-plan`.
- Explicit Superpowers skill invocations must be logged as `skill_invocation` events before the skill is used; validation reads `.specify/bridge-events.jsonl` rather than trying to inspect an agent runtime.
- `AGENTS.md` is the master bridge protocol. `CLAUDE.md` may add Claude-specific notes, but it must defer to `AGENTS.md` on conflicts.
- Do not hand-edit official generated `.agents/skills/speckit-*` or `.claude/skills/speckit-*`; put bridge-specific behavior in separate `speckit-superpowers-bridge` skills.
- Only one agent may own writes to Spec Kit control artifacts for an active feature at a time. Other agents may review only until ownership changes or the handoff is marked `blocked` for repair.

## Auto-archive transitions

- `.specify/superpowers-handoff.json` is repo-scoped: at most one active handoff at a time. When a feature finishes, its terminal `complete` status remains in the file until a new feature starts.
- A `complete` handoff for a prior feature must NOT block contract changes on a different, new feature. The bridge guard now treats `complete` as terminal-not-active for cross-feature requests; same-feature requests against a `complete` handoff are still denied until the handoff is auto-archived or moved to `blocked`.
- Use `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/auto-archive-handoff.ps1 -Actor <codex|claude>` to archive a `complete` handoff. The helper is idempotent: when status is not `complete`, it is a no-op success exit.
- Auto-archive takes a snapshot of the prior feature's Spec Kit artifacts under `.specify/bridge-snapshots/<snapshot-id>/`, appends an entry to `superpowers-handoff.json.archive_history`, clears `feature_directory`, `artifact_owner`, and `review_only_agents`, and appends an `auto_archive` event to `.specify/bridge-events.jsonl`.
- When invoking the bridge guard from a known feature context, pass `-TargetFeatureDirectory <project-relative-path>` so the guard can distinguish same-feature from cross-feature requests. Omitting the flag defaults to same-feature semantics (preserves legacy behavior).

## Disposition Matrix

- The non-overlap policy is codified in `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json` (one entry per Spec Kit command + Superpowers skill). The bridge guard consults the matrix first; legacy rules only fire as a fallback.
- Four disposition kinds: `COMBINE` (always allowed), `FORBID-UNDER-HANDOFF` (denied while `applicability` matches the active handoff status), `SUPERSEDED-BY` (replaced by another entry; denied with a pointer), `REVIEW-ONLY` (only the artifact owner may invoke).
- `speckit.constitution` → FORBID-UNDER-HANDOFF with applicability `[executing]`. Allowed during `ready`, `blocked`, `complete`.
- `speckit.checklist` → COMBINE. Always allowed; orthogonal to Superpowers `verification-before-completion`.
- `speckit.implement` → FORBID-UNDER-HANDOFF with applicability `[ready, executing, blocked, complete]` and `superseded_by: superpowers:executing-plans`.
- `superpowers:brainstorming` and `superpowers:writing-plans` → FORBID-UNDER-HANDOFF with applicability `[executing, complete]`.
- Verified upstream versions live in `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`. The bridge parity check (`.specify/extensions/speckit-superpowers-bridge/scripts/powershell/parity-check.ps1`) reports drift, missing dispositions, missing per-agent skill mirrors, and doc-matrix inconsistencies.
- Run the parity check on demand via `/speckit-superpowers-parity` (Claude) or `$speckit-superpowers-parity` (Codex); exit code 0 = clean, 1 = P0 finding, 2 = P1 finding.
- Feature 004 adds three bridge meta-commands: `speckit.superpowers.audit` for install-state diagnostics, `speckit.superpowers.validate` for end-to-end validation, and `speckit.superpowers.recommend-route` for advisory light/heavy workflow routing.
- `skill_invocation` is a bridge event type for explicit Superpowers skill calls. Required fields include `skill_id`, `phase`, `task_id` when applicable, and `actor`.

## Format note: matrix files are JSON

The disposition matrix and verified-versions records ship as `.json` files rather than `.yml` (planned). PowerShell 5.1 has no native YAML parser, and adding a module dependency would violate constitution Principle I (lightweight, no new global tooling). JSON keeps the loader trivial. The contract schema in `specs/002-complete-bridge-protocol/contracts/disposition-matrix.schema.json` is a JSON Schema that applies directly.
