# Phase 0 Research: Complete Bridge Protocol

**Feature**: 002-complete-bridge-protocol
**Date**: 2026-05-15
**Status**: All unknowns resolved; no `NEEDS CLARIFICATION` remain.

Plan-time unknowns and the decisions taken to resolve them. Each section follows the
`Decision / Rationale / Alternatives considered` shape.

---

## R1 — Disposition matrix file format

**Decision**: Single YAML file at `.specify/extensions/speckit-superpowers-bridge/disposition-matrix.yml` with a JSON Schema contract at `contracts/disposition-matrix.schema.json`.

**Rationale**: The repo already uses YAML for `.specify/extensions.yml` and its extension manifests; same parser (PowerShell's `ConvertFrom-Yaml` via the `powershell-yaml` module or a tiny embedded loader), same review experience, comment support for rationales. JSON Schema gives a precise contract without forcing us to write a TypeScript-style validator.

**Implementation deviation (recorded during execution)**: Shipped as `disposition-matrix.json` rather than `.yml`. PowerShell 5.1 has no native YAML parser; adding the `powershell-yaml` module would have introduced a global tooling dependency that violates constitution Principle I (lightweight, no global module installs). JSON keeps the loader trivial (`Get-Content | ConvertFrom-Json`) and the JSON Schema in `contracts/disposition-matrix.schema.json` applies directly to the JSON file. The same deviation applies to `verified-versions.json` (R2). Comment support was the main YAML benefit and it turned out to be non-essential at this scale (~30 entries; each entry has a one-line `rationale` field that covers the same need).

**Alternatives considered**:
- *Inline in `.specify/extensions.yml`*: Couples non-overlap policy to extension config. Rejected: the matrix evolves with upstream Spec Kit / Superpowers releases independently of hook config.
- *JSON file*: No comment support; rationales would have to live in a parallel `.md` and drift. Rejected — but eventually adopted with rationales inlined as fields, see deviation note above.
- *Multiple per-tool files (`spec-kit.yml`, `superpowers.yml`)*: Doubles loader complexity for no real benefit at this scale (~25 entries total). Rejected.

---

## R2 — Verified-versions storage

**Decision**: `.specify/extensions/speckit-superpowers-bridge/verified-versions.yml` next to the disposition matrix. Fields: `spec_kit_version` (semver string), `superpowers_skills` (list of `{name, version}` pairs; version is either an upstream semver, the string `"runtime-exposed"` for skills surfaced only via agent runtime with no version, or a commit hash), `verified_at` (ISO 8601 UTC), `verified_by` (free text — author).

**Rationale**: Co-locates the version pin with the matrix it governs. Single file = single source of drift truth.

**Alternatives considered**:
- *Embed in matrix file header*: Mixes data domains. Rejected.
- *`.specify/init-options.json`*: That file is the Spec Kit init record; mixing in Superpowers metadata pollutes ownership. Rejected.

---

## R3 — Parity check trigger policy

**Decision**: Two on-demand entry points (one per agent: `/speckit-superpowers-parity` for Claude, `$speckit-superpowers-parity` for Codex), plus an *optional, off-by-default* `before_tasks` hook entry that maintainers can enable to auto-run the parity check before tasks generation.

**Rationale**: On-demand respects the lightweight-first principle. The optional pre-tasks hook gives teams who want a hard gate an easy switch without forcing the cost on everyone. Pre-commit and CI integration are out of scope for this feature (no CI currently configured in this repo).

**Alternatives considered**:
- *Mandatory pre-commit hook*: Heavy; tooling beyond PowerShell would be needed for cross-platform git hooks. Rejected.
- *Mandatory hook on every Spec Kit command*: Adds latency to every flow; over-engineered for a check we expect to be green ≥99% of the time. Rejected.
- *On-demand only, no hook entry*: Loses the "fails build" affordance for teams that want it. Rejected — the optional hook costs ~5 lines of YAML.

---

## R4 — Handoff state-machine extension

**Decision**: Extend `update-handoff.ps1` with one new valid transition (`complete` → `ready`) gated by a new helper script `auto-archive-handoff.ps1`. The auto-archive helper takes a snapshot first, then writes the new state. The state machine remains otherwise identical (statuses: `ready`, `executing`, `blocked`, `complete`).

**Rationale**: Minimum diff. The current `update-handoff.ps1` already supports all four statuses; the only thing missing was a path from `complete` back to `ready` without manual file editing. A dedicated helper makes the auto-archive operation discoverable and testable.

**Alternatives considered**:
- *New "archived" status*: Adds a state to the machine, requires schema migration, and every consumer needs to learn it. Rejected.
- *Auto-archive on every read*: Surprising mutation on a read path; rejected as it makes the file's behavior non-obvious.
- *Manual `/speckit-archive` command*: Adds friction the user must remember; lightweight-first rejects this. Auto-archive on `/speckit-specify` (where it is needed) is invisible to the user when things work.

---

## R5 — First-touch artifact-ownership claim

**Decision**: When a `before_specify` flow runs and `.specify/superpowers-handoff.json` has `artifact_owner` empty or `"unknown"`, the auto-archive wrapper (R4) claims ownership for the active actor as part of resetting the file to `ready`.

**Rationale**: Closes CG-004 without inventing a new "ownership claim" API. The auto-archive step is already running on `/speckit-specify`; piggybacking the ownership claim costs one extra `-ArtifactOwner` flag on the existing call.

**Alternatives considered**:
- *Explicit `/speckit-claim` command*: User has to remember it. Rejected.
- *Implicit claim on first guard call*: Spreads the side effect across many call sites. Rejected — keep it in one place.

---

## R6 — Surfacing the bridge extension commands as agent slash commands

**Decision**: Spec Kit's extension framework already auto-generates agent slash commands from `extension.yml` `commands:` entries when the extension is installed; the gap I hit (`/speckit-superpowers-guard` not resolving in Claude Code) most likely means the Claude integration manifest is not re-emitted after extension changes. The fix is in two parts: (a) add an explicit task to re-run `speckit-cli refresh-integration --integration claude` (or the equivalent — confirm in implementation) so Claude sees the existing `commands/*.md`; (b) add the new `speckit.superpowers.parity.md` to the same `commands/` directory so the same refresh picks it up.

**Rationale**: Don't reinvent slash-command registration; reuse the upstream mechanism. Verify behavior during the live Claude validation run and record any residual gap as a new CG entry.

**Alternatives considered**:
- *Hand-write Claude slash files*: Bypasses the upstream mechanism; future Spec Kit upgrades would clobber them. Rejected per constitution Principle V (vendor-managed boundaries).
- *Drop the bridge-extension commands and inline everything in `speckit-superpowers-bridge` SKILL.md*: Loses the per-command slash entry-point. Rejected — extension framework is the right place for these.

---

## R7 — Claude peer skill content for `speckit-git-*`

**Decision**: Each new `.claude/skills/speckit-git-*/SKILL.md` is a byte-for-byte copy of its `.agents/skills/` peer, with these surgical edits only:
1. `name:` frontmatter unchanged (already matches the directory name in both trees).
2. Invocation examples: `$speckit-git-feature ...` → `/speckit-git-feature ...` where the example shows the user-facing command form.
3. Cross-references to `.agents/skills/` flipped to `.claude/skills/` in the "Sibling skill" lines where present.
4. Underlying script paths (`.specify/extensions/git/scripts/powershell/...`) unchanged — both agents share the same scripts.

**Rationale**: This is exactly the user's stated mental model ("都存在，只是名称用法不同") — content identical, invocation syntax flipped.

**Alternatives considered**:
- *Single shared SKILL.md symlinked into both trees*: Windows symlinks need admin or developer-mode; portability suffers. Rejected.
- *Generate Claude peers at install time from Codex peers*: Adds build tooling for ~5 files. Rejected — manual mirror is cheaper at this scale and shows up in `git diff` for review.

---

## R8 — Disposition vocabulary for currently-surfaced Superpowers skills

**Decision**: Classify the current Superpowers skill set as follows. Final entries land in `disposition-matrix.yml`; this section captures the rationale for each. Cross-check against the skills exposed in this session's `system-reminder` block:

| Skill | Disposition | Rationale |
|---|---|---|
| `superpowers:brainstorming` | FORBID-UNDER-HANDOFF `{executing, complete}` | Spec Kit `spec.md` is the brainstorming-equivalent contract; re-brainstorming a feature with a complete spec resets the contract |
| `superpowers:writing-plans` | FORBID-UNDER-HANDOFF `{executing, complete}` | Spec Kit `plan.md` is the plan; Superpowers plan would compete |
| `superpowers:subagent-driven-development` | COMBINE | Used by the bridge to execute Spec Kit `tasks.md` — the legitimate executor |
| `superpowers:executing-plans` | COMBINE | Same — bridge-driven executor |
| `superpowers:test-driven-development` | COMBINE | Implementation discipline; orthogonal to Spec Kit |
| `superpowers:systematic-debugging` | COMBINE | Implementation discipline |
| `superpowers:using-git-worktrees` | COMBINE | Implementation discipline |
| `superpowers:requesting-code-review` | COMBINE | Implementation discipline; complements Spec Kit checklist (which is requirements quality) |
| `superpowers:verification-before-completion` | COMBINE | Implementation discipline; orthogonal to Spec Kit checklist |
| `superpowers:finishing-a-development-branch` | COMBINE | Implementation discipline |
| `superpowers:dispatching-parallel-agents` | COMBINE | Implementation discipline |
| `superpowers:receiving-code-review` | COMBINE | Implementation discipline |
| `superpowers:using-superpowers` | COMBINE | Meta-skill; bridge does not regulate skill discovery |
| `superpowers:writing-skills` | COMBINE | Out of feature scope; not a Spec Kit overlap |

**Rationale**: The bridge's job is to prevent *plan-and-design* skills from competing with Spec Kit ownership. Implementation-discipline skills are exactly what we want Superpowers to provide. The `brainstorming` / `writing-plans` pair are the only Superpowers skills with direct Spec Kit overlap; both are already addressed by `AGENTS.md` and become formal entries in the matrix.

**Alternatives considered**:
- *Forbid `writing-plans` and `brainstorming` always*: Would block legitimate use before any feature exists. Rejected — FORBID-UNDER-HANDOFF with scope `{executing, complete}` matches the constitution's "no replacing existing Spec Kit artifacts" rule.

---

## R9 — Disposition vocabulary for Spec Kit commands at 0.8.9

**Decision**: Classify each Spec Kit command surfaced by `/speckit-*` and `$speckit-*` skills. Final entries land in `disposition-matrix.yml`:

| Command | Disposition | Rationale |
|---|---|---|
| `speckit.constitution` | FORBID-UNDER-HANDOFF `{executing}` | Per clarify Q1 |
| `speckit.specify` | COMBINE | Spec creation; design ownership |
| `speckit.clarify` | COMBINE | Spec refinement; design ownership |
| `speckit.plan` | COMBINE | Plan creation; design ownership |
| `speckit.tasks` | COMBINE | Task generation; design ownership; triggers handoff transition |
| `speckit.analyze` | COMBINE | Spec consistency analysis; design ownership |
| `speckit.checklist` | COMBINE | Per clarify Q2 |
| `speckit.taskstoissues` | COMBINE | Task export to GitHub issues; design ownership |
| `speckit.implement` | FORBID-UNDER-HANDOFF `{ready, executing, blocked, complete}` | Always blocked when a handoff exists (the canonical case from feature 001); the matrix records the previously-hard-coded rule explicitly |
| `speckit.git.initialize` | COMBINE | Repo bootstrap; no overlap |
| `speckit.git.feature` | COMBINE | Feature branch creation; no overlap |
| `speckit.git.commit` | COMBINE | Auto-commit hooks; no overlap |
| `speckit.git.remote` | COMBINE | Remote config; no overlap |
| `speckit.git.validate` | COMBINE | Repo state validation; no overlap |
| `speckit.superpowers.guard` | COMBINE (meta-command; always available) | The guard cannot guard itself |
| `speckit.superpowers.handoff` | COMBINE (meta-command) | Same |
| `speckit.superpowers.parity` (NEW) | COMBINE | New meta-command introduced by this feature |

**Rationale**: Every Spec Kit command except `speckit.implement` is design-time or workflow-utility; `speckit.implement` is the canonical replaced-by-Superpowers case. `speckit.constitution` is the special case from Q1.

**Alternatives considered**:
- *Mark `speckit.implement` as SUPERSEDED-BY `superpowers:executing-plans`*: Semantically cleaner (it's literally replaced), but the bridge's behavior on SUPERSEDED-BY is to "surface the replacement"; we actually want a hard block, so FORBID is the better fit. The matrix can include a `superseded_by` pointer alongside the FORBID disposition to preserve the human guidance.

---

## R10 — Live Claude validation evidence

**Decision**: The Claude Code validation run that User Story 3 demands is this very session. The four CG records in [plan.md](plan.md#compatibility-gap-records-from-live-claude-run-this-session) are the evidence. Future sessions starting from this branch should re-run the happy path and append any new gaps to `compat-gaps.md`.

**Rationale**: User explicitly said "顺便测测 claudecode 兼容性" — this session IS the test. The validation pass is observable in:
- `git log --branches=002-complete-bridge-protocol` for the artifacts produced.
- `.specify/bridge-events.jsonl` for the guard decisions (allow on `speckit.clarify`, allow on `speckit.plan`).
- `.specify/superpowers-handoff.json` for the artifact-owner trail (initially `codex` for feature 001, transitioned to `claude` for feature 002).

**Alternatives considered**: None — this is by definition the live-evidence pass.
