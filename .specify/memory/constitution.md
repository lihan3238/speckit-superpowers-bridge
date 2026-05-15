<!--
SYNC IMPACT REPORT
==================
Version change: 1.1.0 -> 1.2.0
Bump rationale: Add a mandatory end-user verification workflow gate using a
fixed sibling sandbox directory (`..\test_specify_superpower`). This is new
materially-expanded guidance under "Development Workflow & Quality Gates",
not a change to any existing principle's semantics. MINOR per semver.

Modified sections:
  - "Development Workflow & Quality Gates" gained a new bullet group
    "End-User Verification Sandbox" (rule + rationale).

Added sections: none (expanded existing section).
Removed sections: none.

Templates requiring updates:
  - .specify/templates/plan-template.md           - PENDING: add a one-line
    note in the Constitution Check / Quality Gates section referencing the
    new sandbox verification expectation for release-shipping features.
  - .specify/templates/tasks-template.md          - PENDING: add a note in
    the Polish / final-verification phase pointing to the sandbox sequence
    for features that ship a release artifact.
  - .specify/templates/spec-template.md           - no change required.
  - .claude/skills/speckit-constitution/*         - vendor-managed; no edit.
  - .agents/skills/speckit-constitution/*         - vendor-managed; no edit.
  - AGENTS.md                                     - PENDING: brief mention
    of the sandbox in workflow / release context.
  - CLAUDE.md                                     - no change required.

Follow-up TODOs:
  - Wire the sandbox into the next feature's release polish phase
    (concrete tasks captured during /speckit-tasks for that feature).
  - Optionally add a small dev-time helper script to set up the sandbox
    project from scratch (not required by this amendment).
-->

# Spec Kit Superpowers Bridge Constitution

## Core Principles

### I. Lightweight & Repo-Local

The bridge MUST remain a repo-local protocol composed of small Markdown skills,
PowerShell scripts, JSON/YAML state files, and Spec Kit extension manifests.
No new runtime, daemon, service, database, or global plugin modification may
be introduced in order to satisfy a bridge requirement. Marketplace packaging
MAY be introduced only as a thin distribution layer for the same repo-local
assets. Changes MUST prefer the smallest diff that delivers the capability and
MUST NOT modify the global Superpowers plugin cache or any other tool's global
installation.

**Rationale**: The bridge's only reason to exist is to glue two existing
tools together. Any heavier infrastructure invalidates the premise, makes
the protocol hard to audit, and creates upgrade risk for both Spec Kit and
Superpowers.

### II. Design/Implementation Separation (NON-NEGOTIABLE)

Spec Kit is the single source of truth for design-time artifacts:
`.specify/memory/constitution.md`, `specs/<feature>/spec.md`,
`specs/<feature>/plan.md`, `specs/<feature>/tasks.md`, checklists, and
analysis. Superpowers is the single source of truth for implementation
discipline: isolated workspaces, TDD, systematic debugging, verification,
code review, and finishing the development branch. The two roles MUST NOT
overlap:

- Superpowers `writing-plans` and `brainstorming` MUST NOT replace Spec Kit
  `plan.md` or `tasks.md` while those artifacts exist for the active feature.
- `speckit.implement` MUST NOT run when
  `.specify/superpowers-handoff.json` declares `"executor": "superpowers"`;
  execution flows through `speckit-superpowers-bridge` against
  `tasks.md` instead.
- If implementation surfaces missing or wrong requirements, the executor
  MUST stop, mark the handoff `blocked`, and return control to Spec Kit
  for spec/plan/tasks repair before resuming.

**Rationale**: Allowing either side to silently take over the other's
artifacts creates two competing sources of truth and destroys the
hand-off contract. Marking this NON-NEGOTIABLE prevents drift over time.

### III. Agent-Neutral Protocol

The bridge MUST behave identically whether the active agent is Codex or
Claude Code. Operational guidance lives in `AGENTS.md` (master) with
agent-specific notes layered in `CLAUDE.md` and Codex-specific files;
`AGENTS.md` wins on conflict. Invocation syntax differences MUST be
documented explicitly and MUST NOT change behavior:

- Internal Spec Kit command IDs remain dotted (e.g. `speckit.plan`,
  `speckit.speckit-superpowers-bridge.guard`).
- Codex invokes via `$speckit-plan` style.
- Claude Code invokes via slash commands derived from skill names
  (e.g. `/speckit-plan`); hook command names with dots are rendered with
  hyphens for Claude.
- Bridge guard and handoff scripts MUST accept `-Actor codex` or
  `-Actor claude` and log the actor in `.specify/bridge-events.jsonl`.

**Rationale**: The promise of the bridge is interchangeable agents. If a
feature works on one agent only, that feature does not belong in the
bridge.

### IV. Smooth Bidirectional Handoff

Each side MUST be able to discover the other's current state without
human-in-the-middle translation:

- The handoff state file `.specify/superpowers-handoff.json` MUST exist
  whenever Superpowers owns execution and MUST encode at minimum the
  executing actor, the owning feature, the artifact write owner, the
  list of review-only agents, and the `tasks.md` path.
- Every allow/deny decision from the bridge guard MUST be appended to
  `.specify/bridge-events.jsonl` so either agent can reconstruct context
  on resume.
- A snapshot of Spec Kit control artifacts MUST be taken before any
  guarded write so rollback to Spec Kit ownership is mechanical.
- Switching the active agent mid-feature MUST require only updating the
  actor and re-reading `AGENTS.md` plus the handoff file; no Spec Kit
  artifact edits are required to change agents.

**Rationale**: Smooth handoff is the user-visible value of this project.
Anything that requires the user to manually translate state between
agents is a bridge defect.

### V. Vendor-Managed Boundaries

Officially generated Spec Kit integration skills under
`.agents/skills/speckit-*` and `.claude/skills/speckit-*` MUST NOT be
hand-edited. All custom bridge behavior MUST live in
`speckit-superpowers-bridge` skills, the `.specify/extensions/` extension
package, scripts under `.specify/extensions/.../scripts/`, or the
shared protocol files (`AGENTS.md`, `CLAUDE.md`, `.specify/extensions.yml`).
Only one agent at a time MUST hold write ownership of Spec Kit control
artifacts for an active feature; other agents are review-only until the
handoff is reassigned or marked `blocked`.

**Rationale**: Hand-edited vendor files silently break on upgrade and
make the bridge's true surface area invisible. A single named writer
prevents racey edits when both agents are co-resident in a workspace.

## Boundary & Ownership Rules

- The bridge guard script
  (`.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1`
  on Windows; the matching `.sh` under `scripts/bash/` on Linux/macOS)
  is the only sanctioned enforcement point; agents MUST call it before
  crossing a Spec Kit/Superpowers boundary and MUST honor its decision.
- `.specify/bridge-events.jsonl` is append-only; no agent may rewrite or
  truncate prior entries.
- `.specify/bridge-snapshots/` is the canonical recovery surface for
  Spec Kit control artifacts; implementation-source rollback remains the
  responsibility of Git/worktrees, not the bridge.
- Exactly one Superpowers handoff MAY be active per repository at a time.
- `speckit.implement` remains installed but MUST be blocked by the guard
  whenever a Superpowers handoff is active for the feature.

## Development Workflow & Quality Gates

- Every implementation plan MUST pass an explicit Constitution Check
  (per principle) before Phase 0 research and again after Phase 1 design.
- Tasks generated by `/speckit-tasks` are the only implementation contract
  consumed by Superpowers; tasks MUST be regenerated through Spec Kit
  rather than edited in place after handoff.
- Pre-push verification (format, lint, type, test, smoke) MUST run before
  any PR is opened; PowerShell smoke tests covering guard decisions,
  handoff schema, snapshot restore, and Codex/Claude context discovery
  MUST pass for any change to bridge scripts or skills.
- Every PR description MUST state which principle(s) the change touches
  and whether any new complexity required justification under
  Complexity Tracking.

### End-User Verification Sandbox

The sibling directory `..\test_specify_superpower` (relative to this
source repo's parent) is the **canonical end-user simulation sandbox**.
It is NOT a part of this repo; it is a separate Spec Kit project used
exclusively for verifying that a freshly released bridge artifact works
the way a real user encounters it. Every feature that ships a release
artifact (i.e., bumps `extension.yml.extension.version` and tags a
`vX.Y.Z` release) MUST be verified there BEFORE the feature's handoff
transitions to `complete`. The sequence is:

1. Initialize / reset the sandbox project (`specify init . --integration
   <codex|claude> --script <ps|sh> --here --force`) under the target
   platform's flavor.
2. Install the bridge via the **published release URL**, not via local
   `--dev` path:
   `specify extension add speckit-superpowers-bridge --from
   https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/vX.Y.Z/speckit-superpowers-bridge-vX.Y.Z.zip`.
3. Drive at least one complete bridge cycle in the sandbox:
   `/speckit-specify` → `/speckit-clarify` (if applicable) → `/speckit-plan`
   → `/speckit-tasks` → bridge orchestration → handoff `complete`.
4. Repeat for every platform the release supports (at minimum: Windows
   PowerShell; Linux bash; macOS bash once the bash flavor ships).
   Cross-platform coverage is the gate's primary value over the in-repo
   smoke tests.
5. Record the outcome in the source feature's `quickstart.md` (or a
   `verification.md` peer) — pass/fail per platform, the bridge SHA256
   exercised, and any observed gap. The sandbox's transient project
   files themselves are not committed; only the source-repo record is.

If any sandbox run fails, the handoff MUST move to `blocked` and the
spec MUST be revised to capture the gap before re-attempting release.

**Rationale**: In-repo smoke tests (under `tests/`) verify the bridge in
dogfood mode — all source files local and editable, no real install
step. They do NOT catch problems users actually hit on first contact:
hand-built ZIP shape, install-time skill generation, marketplace
`download_url` resolution, platform-script dispatch via
`init-options.json.script`, line-ending preservation through ZIP, and
absent local dev-mode mirrors after a fresh install. The v0.4.0 release
cycle required three RC tags before the published artifact installed
cleanly; a fixed sibling sandbox front-loads that discovery to the
spec-completion stage where fixing it costs hours, not days.

## Governance

- This constitution supersedes any conflicting guidance in skills,
  prompts, or scripts. Where `AGENTS.md`, `CLAUDE.md`, or a skill conflicts
  with this document, the constitution wins and the conflicting file MUST
  be amended in the same change set.
- Amendments MUST land via a PR that updates this file, bumps
  `CONSTITUTION_VERSION` per semver (MAJOR for incompatible removals or
  redefinitions, MINOR for added or materially expanded principles, PATCH
  for clarifications), updates `LAST_AMENDED_DATE`, and prepends a Sync
  Impact Report comment.
- Reviewers MUST verify principle compliance and call out any
  vendor-managed file edits as blocking.
- The `speckit-constitution` skill is the authoritative entry point for
  amendments; do not edit this file outside that workflow except for
  trivial typo fixes (PATCH, no Sync Impact Report required).
- Use `AGENTS.md` for runtime cross-agent guidance and `CLAUDE.md` for
  Claude-specific supplements.

**Version**: 1.2.0 | **Ratified**: 2026-05-14 | **Last Amended**: 2026-05-16
