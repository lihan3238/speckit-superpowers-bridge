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
phases, dispatched by each agent's bridge `SKILL.md`.

## User-Facing Language Routing

- Detect the user's dominant language from the latest user message.
- Translate user intent to English internally before planning, tool use,
  subagent prompts, delegated agent instructions, and implementation reasoning.
- Keep internal prompts, delegated agent instructions, code comments unless
  otherwise appropriate, commit messages, command IDs, paths, schema fields,
  and logs in English.
- Translate user-facing assistant messages back to the detected user language.
- If the user explicitly requests a response language, that explicit request
  overrides automatic detection.
- Preserve literal code, commands, filenames, JSON/YAML keys, quoted source
  text, and API names without translation.
- For mixed Chinese/English messages, respond in the language used for the main
  request; if unclear, prefer the user's last sentence language.

## Spec Kit + Superpowers Bridge

- Spec Kit owns design-time artifacts: `.specify/memory/constitution.md`, `specs/<feature>/spec.md`, `specs/<feature>/plan.md`, `specs/<feature>/tasks.md`, checklists, and analysis.
- Superpowers owns implementation discipline: isolated workspaces, TDD, systematic debugging, task execution, code review, verification, and finishing the development branch.
- `specs/<feature>/tasks.md` is the only implementation contract. Do not use Superpowers `writing-plans` to replace Spec Kit `plan.md` or `tasks.md` once they exist.
- When `.specify/superpowers-handoff.json` declares `"status": "executing"`, do not run `speckit.implement`; execute the listed `tasks.md` through the bridge SKILL (`/speckit-superpowers-bridge` on Claude Code, `$speckit-superpowers-bridge` on Codex) instead.
- If implementation reveals missing or wrong requirements, stop implementation, mark the handoff `blocked`, and return to Spec Kit to update `spec.md`, `plan.md`, or `tasks.md`.
- When an active Spec Kit feature has `spec.md`, `plan.md`, and `tasks.md`, Superpowers `brainstorming` and `writing-plans` are disabled for that feature unless the user explicitly says to discard or replace the Spec Kit artifacts.
- Superpowers `subagent-driven-development` and `executing-plans` may run only through `speckit-superpowers-bridge` and must use Spec Kit `tasks.md` as the plan.
- Before crossing these boundaries, run the platform-selected bridge guard (`scripts/powershell/guard-command.ps1` for `ps`, `scripts/bash/guard-command.sh` for `sh`); every allow/deny decision is logged in `.specify/bridge-events.jsonl`.
- Pass `-Actor codex` / `--actor codex` from Codex and `-Actor claude` / `--actor claude` from Claude Code when invoking bridge guard or handoff scripts.
- If actor is omitted, bridge scripts resolve actor in three steps: explicit actor argument → `SPECKIT_BRIDGE_ACTOR` env var → `"unknown"`.
- Command IDs and agent invocations are different: internal Spec Kit command IDs use dots such as `speckit.plan`; Codex uses `$speckit-plan`; Claude Code uses slash commands generated from skill names such as `/speckit-plan`. Bridge extension commands use the namespace `speckit.speckit-superpowers-bridge.*` (three retained: `execute`, `handoff`, `guard`).
- `AGENTS.md` is the master bridge protocol. `CLAUDE.md` may add Claude-specific notes, but it must defer to `AGENTS.md` on conflicts.
- Do not hand-edit official generated `.agents/skills/speckit-*` or `.claude/skills/speckit-*`; put bridge-specific behavior in separate `speckit-superpowers-bridge` skills.
- Only one agent may own writes to Spec Kit control artifacts for an active feature at a time. Other agents may review only until ownership changes or the handoff is marked `blocked` for repair.

## Auto-archive transitions

- `.specify/superpowers-handoff.json` is repo-scoped: at most one active handoff at a time. When a feature finishes, its terminal `complete` status remains in the file until a new feature starts.
- A `complete` handoff for a prior feature must NOT block contract changes on a different, new feature. The bridge guard treats `complete` as terminal-not-active; cross-feature requests are allowed.
- Use the platform-selected auto-archive helper (`auto-archive-handoff.ps1 -Actor <codex|claude>` or `auto-archive-handoff.sh --actor <codex|claude>`) to archive a `complete` handoff. The helper is idempotent: when status is not `complete`, it is a no-op success exit.
- Auto-archive snapshots the prior feature's Spec Kit artifacts under `.specify/bridge-snapshots/<snapshot-id>/`, clears `feature_directory`, and appends an `archive` event to `.specify/bridge-events.jsonl`. (The pre-0.3.0 `auto_archive` event type, `archive_history` field, and matrix-driven dispositions are no longer used.)

## Guard rules

The bridge guard at `.specify/extensions/speckit-superpowers-bridge/scripts/{powershell,bash}/guard-command.*` enforces 5 hardcoded rules (no matrix lookup):

1. Deny `speckit.implement` when handoff status is `executing`.
2. Deny `superpowers:writing-plans` or `:brainstorming` when active feature has both `spec.md` and `plan.md`.
3. Deny `speckit.constitution` when handoff status is `executing`.
4. Allow any other `speckit.*` command.
5. Default allow.

Adding a new rule is a one-line edit to the script. There is no external data file.

## Handoff schema

The v1 schema (post-0.3.0) is documented in `specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json`. New writes emit only v1 fields. Reads tolerate older v2/v3 documents (unknown fields are silently ignored).

As of v0.4.1, the bridge ships both `scripts/powershell/` and `scripts/bash/` flavors. The protocol, handoff schema, guard rules, and actor semantics are identical; `.specify/init-options.json.script` (`ps` or `sh`) chooses the runtime flavor.

## End-user verification sandbox

`..\test_specify_superpower` (sibling directory to this source repo) is the canonical end-user simulation sandbox per constitution §"End-User Verification Sandbox" (v1.2.0+). Every feature that ships a release artifact MUST be verified there before its handoff transitions to `complete`: install the bridge via the published release URL (not local `--dev`), drive one full bridge cycle per supported platform (Windows PowerShell + Linux/macOS bash), and record outcomes in the feature's `quickstart.md` or `verification.md`. The sandbox catches install-time and cross-platform issues that in-repo smoke tests cannot — the same class of issues v0.4.0 hit during its three RC iterations.
