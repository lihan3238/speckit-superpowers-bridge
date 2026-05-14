# Phase 0 Research: Polish & Publish

**Feature**: 004-polish-and-publish
**Date**: 2026-05-15
**Status**: All 10 plan-time unknowns resolved; no `NEEDS CLARIFICATION` remain.

Following the project's primary design reference ([the dev.to comparison article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj)) for any architectural ambiguity.

---

## R1 — Actor detection: env var name and precedence

**Decision**: `SPECKIT_BRIDGE_ACTOR` (project-namespaced) as the env-var override. Resolution order:
1. Explicit `-Actor <value>` argument
2. `SPECKIT_BRIDGE_ACTOR` environment variable
3. `.specify/integration.json.default_integration` (the project's recorded default)
4. Literal `unknown` (deterministic terminal fallback)

**Rationale**: The project namespace prefix avoids collision with any Spec Kit-native env var (none observed in current 0.8.9). The 4-step order gives operators control at the right granularity: per-call (arg) → per-shell (env) → per-project (default_integration) → defensive (unknown). Choosing `default_integration` over `installed_integrations[0]` because the project has explicitly recorded a default.

**Alternatives considered**:
- *`CLAUDE_AGENT_NAME` / `CODEX_AGENT_NAME` / similar per-agent vars*: assumes the runtime sets these; not portable. Rejected.
- *No env var, only arg + default_integration*: forces every CI invocation to set the arg. Rejected.
- *Heuristic from working directory or file recency*: unreliable; depends on cosmetic state. Rejected.

---

## R2 — Autonomous-mode location

**Decision**: Single canonical location is `.specify/superpowers-handoff.json.autonomous_mode` (boolean, default `false`). Override via env var `SPECKIT_BRIDGE_AUTONOMOUS=1` (for CI / headless). No CLI flag on `/speckit-superpowers-bridge` (the bridge skill is loaded by the slash command, not parameterized through it).

**Rationale**: Handoff JSON is where all persistent bridge state lives; centralizing autonomy here makes it inspectable and resumable. Env-var override is for use cases where the user can't modify the handoff (read-only mount, CI).

**Alternatives considered**:
- *Separate `.specify/bridge-config.json`*: fragments bridge state. Rejected.
- *Inline in `extension.yml`*: confuses static extension config with runtime state. Rejected.
- *Default `true`*: violates the spec's "off by default" Assumption. Rejected.

---

## R3 — Bridge skill explicit invocation syntax

**Decision**: 
- **Claude Code**: the bridge SKILL.md instructs the agent to invoke each Superpowers skill via the `Skill` tool with `skill: "superpowers:<name>"` (matches the skill list format shown in the Claude system reminder).
- **Codex**: the bridge SKILL.md instructs the agent to invoke via the `$superpowers-<name>` slash-prefix form (Codex's documented invocation syntax for skills).

Each invocation is preceded by a `Bash` (or equivalent) call to `emit-skill-invocation.ps1` which writes the `skill_invocation` event to `.specify/bridge-events.jsonl`. The bridge skill must do this BEFORE the actual Skill invocation so the audit trail records intent even if the invocation fails.

**Rationale**: Both forms are first-class on their respective agents. Logging-before-invoke makes the audit trail durable; logging-after would lose failed-invocation traces. The validation pass (US3) reads the event log, not agent-runtime introspection, per FR-010.

**Alternatives considered**:
- *Single unified script invocation that wraps Skill tool calls*: can't easily forward arguments; loses the agent's native skill-invocation UX. Rejected.
- *Log after invocation*: failed invocations leave no trace. Rejected.

---

## R4 — `skill_invocation` event schema

**Decision**: New event type in `.specify/bridge-events.jsonl` with this shape:

```json
{
  "timestamp": "2026-05-15T...",
  "action": "skill_invocation",
  "status": "<handoff-status>",
  "feature_directory": "specs/004-polish-and-publish",
  "decision": "invoked",
  "reason": "<phase-name, e.g. before-implementation-task>",
  "actor": "claude",
  "snapshot_id": null,
  "skill_id": "superpowers:test-driven-development",
  "phase": "before-implementation-task",
  "task_id": "T012"
}
```

`skill_id`, `phase`, and (optional) `task_id` are NEW fields. Existing fields (timestamp, action, status, feature_directory, decision, reason, actor, snapshot_id) match the established event shape from feature 002. The contract schema is in `contracts/skill-invocation-event.schema.json`.

**Rationale**: Reusing the existing event envelope keeps all log consumers compatible. Adding additive fields (not changing existing ones) is consistent with the constitution's "lightweight, repo-local" principle.

**Alternatives considered**:
- *Separate `.specify/skill-invocations.jsonl` log*: fragments observability. Rejected.
- *Embed in handoff JSON as last_skill_invocation*: loses history. Rejected.

---

## R5 — Install-state audit output format

**Decision**: `audit-install-state.ps1` emits a single JSON document on stdout when invoked with `-Json`, human-readable summary otherwise. Output schema:

```json
{
  "schema_version": 1,
  "generated_at": "...",
  "spec_kit": {"version": "0.8.9", "default_integration": "codex"},
  "integrations": [{"name": "codex", "manifest_present": true}, {"name": "claude", "manifest_present": true}],
  "git_extension": {"installed": true, "version": "1.0.0", "commands": [...]},
  "skills_parity": {
    "missing_on_claude": [], "missing_on_codex": [],
    "diverged": [{"name": "speckit-superpowers-bridge", "agents_sha": "abc...", "claude_sha": "def..."}]
  },
  "script_flavour": "ps",
  "findings": [{"code": "skill_diverged", "severity": "P2", "target": "...", "message": "...", "suggested_fix": "..."}]
}
```

Exit codes mirror parity-check.ps1: 0 clean, 1 P0, 2 P1, 3 P2 if `-Strict`.

**Rationale**: Same envelope as parity-check.ps1 keeps the audit family of scripts uniform. JSON output is consumable by the validation pass (R5 + R6 combined output is what US3 verifies).

**Alternatives considered**:
- *Plain text only*: hard to validate programmatically. Rejected.
- *Per-finding files in a directory*: over-engineered for one-shot audit. Rejected.

---

## R6 — Spec Kit marketplace listing format

**Decision**: At Spec Kit 0.8.9, the "marketplace" is **catalog-driven via each extension's own `extension.yml`** — there is no separate package format, registry endpoint, or marketplace.json. Listing this plugin therefore means: (a) ensure `extension.yml` declares the canonical metadata fields (id, name, version, description, author, repository, license, requires, provides); (b) ensure the README documents install + usage; (c) when the upstream marketplace gains a richer format, re-verify and amend.

**Rationale**: Per [the dev.to article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj): *"Spec Kit's extension model is catalog-driven — you browse and adopt prebuilt pieces."* No separate package registry observed in the current Spec Kit version. The existing `.specify/extensions/speckit-superpowers-bridge/extension.yml` already declares the right schema. The only addition is making the README marketplace-presentable.

**Alternatives considered**:
- *Speculatively design a separate marketplace.yml*: violates "lightweight" + risks divergence when upstream actually ships a marketplace. Rejected.
- *Mirror an OpenSpec/Superpowers-style format*: each tool has its own; copying Superpowers' approach assumes a future Spec Kit will align, which is unproven. Rejected.

---

## R7 — Bilingual README convention

**Decision**: Two top-level files at repo root: `README.md` (English, primary marketplace landing) + `README.zh-CN.md` (Simplified Chinese). Each starts with a one-line language toggle linking to the other. Section anchors MUST match exactly (lowercase, dash-separated, identical heading text per language); `check-readme-bilingual-parity.ps1` enforces this.

**Rationale**: This is the standard GitHub repo convention used widely across open-source projects (e.g. `vuejs/vue`, `microsoft/vscode-docs-zh-cn`). Spec Kit itself ships only English at 0.8.9, so we are setting the bilingual precedent for this plugin rather than copying an upstream pattern.

**Alternatives considered**:
- *Single combined README with bilingual sections side-by-side*: hard to scan; doubles the cognitive load when reading. Rejected.
- *Separate `docs/zh-CN/README.md` location*: less discoverable for marketplace listings. Rejected.
- *Auto-translation tooling*: out of scope; humans own translations.

---

## R8 — Small-scope heuristic for US5 routing recommender

**Decision**: The recommender uses a simple AND-condition heuristic over the feature description:
- Total description length < 200 characters, AND
- Contains at least one of the keywords `["fix", "typo", "rename", "tweak", "bug", "patch"]` (case-insensitive), AND
- Does NOT contain any of the keywords `["architecture", "design", "framework", "system", "rewrite", "refactor"]`.

If all three conditions hold → emit recommendation. Otherwise proceed silently with the full pipeline. The heuristic is intentionally crude because P3 priority + AI-model-evolution sensitivity (per [[feedback_light_heavy_is_workflow_routing]]).

**Rationale**: The recommender's purpose is to nudge, not gate. A coarse heuristic that catches obvious "fix the typo" cases and ignores everything else is sufficient; sophisticated NLP would itself become brittle as model behavior changes.

**Alternatives considered**:
- *LLM-as-judge*: heavy, version-dependent, contradicts P3 lightness. Rejected.
- *Per-keyword scoring*: marginal value; rejected for simplicity.
- *Hardcoded list of "always recommend direct Superpowers" patterns*: too rigid. Rejected.

---

## R9 — Plugin distribution manifest format

**Decision**: YAML at `.specify/extensions/speckit-superpowers-bridge/plugin-distribution-manifest.yml`:

```yaml
schema_version: 1
includes:
  - path: .specify/extensions/speckit-superpowers-bridge/**
  - path: .agents/skills/speckit-superpowers-bridge/SKILL.md
  - path: .claude/skills/speckit-superpowers-bridge/SKILL.md
  - path: README.md
  - path: README.zh-CN.md
  - path: AGENTS.md          # bridge protocol; copied with care (host project may have one)
  - path: CLAUDE.md          # ditto
excludes:
  - path: .specify/bridge-events.jsonl
  - path: .specify/bridge-snapshots/**
  - path: .specify/superpowers-handoff.json
  - path: .specify/feature.json
  - path: specs/**           # all per-feature design artifacts are project-private
  - path: tests/**           # development-only tests
notes:
  - "AGENTS.md and CLAUDE.md installation is conditional: if the host project already has them, merge the 'Spec Kit + Superpowers Bridge' section rather than overwriting."
```

**Rationale**: Single source of truth for "what ships". YAML with comments lets each entry carry intent. The `check-distribution-manifest.ps1` script validates that the manifest's `includes` actually exist and that nothing in `excludes` is also in `includes`.

**Alternatives considered**:
- *JSON manifest*: no comments → harder to maintain rationale. Rejected.
- *Glob patterns alone in `.gitattributes` style*: less explicit; hard to document conditional installs. Rejected.

---

## R10 — `.gitignore` vs plugin distribution

**Decision**: Two-list discipline:

- **`.gitignore`** (tracks the *repo's own* private state): excludes `.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/`, `.specify/superpowers-handoff.json`, `.specify/feature.json`, `specs/*/checklists/protocol-quality.md` (working scratch), plus OS-junk (`.DS_Store`, `Thumbs.db`, `*.bak-parity-drift`).
- **`plugin-distribution-manifest.yml`** (R9; what *gets copied on install*): the orthogonal axis — files that ship to a host project. `.gitignore` is about THIS repo; the manifest is about TARGET repos.

A file can be in `.gitignore` AND `excludes:` (most project-private state), or tracked AND `excludes:` (`specs/`, `tests/` — kept in source repo, not shipped), or tracked AND `includes:` (plugin assets). A file should NEVER be in `.gitignore` AND `includes:` (would be a packaging defect).

**Rationale**: Separating the two axes prevents conflation. The verification scripts catch the four invalid combinations.

**Alternatives considered**:
- *Single source of truth*: would mean either over-ignoring (losing test fixtures) or under-ignoring (committing bridge state). Rejected.
- *No `.gitignore`*: re-committing snapshots and events log on every push would balloon the repo. Rejected.

---

## Cross-cutting research notes

- **Spec Kit 0.8.9 invocation syntax**: confirmed `/speckit-X` (hyphenated) for Claude, `$speckit-X` (dollar-hyphen) for Codex via runtime observation in feature 002's live tests. The dev.to article shows `/speckit.X` dotted form, which is an older Spec Kit version or convention drift; our code matches the live install, not the article.
- **Superpowers skill invocation in Claude Code**: the `Skill` tool requires either explicit user invocation in their message (`/<skill-name>`) OR the skill appearing in the runtime's `available-skills` list. Both apply for the bridge's named skills (TDD, verification, etc.) per the system reminder. Validated live during feature 002.
- **Article re-read for routing recommender**: the article doesn't explicitly recommend a heuristic format, but its *"these are not mutually exclusive"* + *"a team could realistically: use Spec Kit for the what … use Superpowers for the how"* framing supports the recommender's "advisory only" stance — never bypass the user's choice.

---

## Open items deferred to plan-time → tasks (no further research needed)

None. All 10 unknowns resolved; the work breakdown can proceed.
