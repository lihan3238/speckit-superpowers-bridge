# Feature Specification: Optional Pre-Specify Brainstorming Handoff

**Feature Branch**: `010-prespec-brainstorming`

**Created**: 2026-05-17

**Status**: Draft

**Input**: User description: "我希望参考我们的设计思路，考虑将superpowers的头脑风暴加入我们的流程，请你联网调研官方代码文档与设计思路及社区讨论，研究下要不要加入，该放在哪 ？我们这次spec开始针对superpowers的头脑风暴"

---

## Context (research-derived; not a contract)

The Superpowers `brainstorming` skill is a Socratic, gate-enforced pre-design
dialogue maintained upstream by Jesse Vincent ([obra/superpowers](https://github.com/obra/superpowers/blob/main/skills/brainstorming/SKILL.md))
and distributed via the Anthropic Claude Code plugin marketplace since
2026-01-15. Its native flow asks one question at a time, proposes 2–3
approaches, presents the design in 200–300 word sections for approval,
saves the resulting design doc to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`,
and — since v4.3.0 — uses **hard gates** to block implementation until
the user explicitly approves the design. Brainstorming's only sanctioned
post-skill handoff is `writing-plans`, but in this repo `writing-plans` is
denied while a Spec Kit feature has design artifacts (constitution §II).

Inside this repo, brainstorming today is purely a **deny rule** in the
bridge guard ([guard-command.ps1](.specify/extensions/speckit-superpowers-bridge/scripts/powershell/guard-command.ps1)):
it is blocked when an active feature already has `spec.md` and `plan.md`.
There is **no positive integration**, no documented lifecycle slot, no
artifact-handoff convention, and no path from a brainstorming design doc
into `/speckit-specify`. The only acknowledgement of pre-spec brainstorming
is one informal line in [README.md:144](README.md#L144) / [README.zh-CN.md:142](README.zh-CN.md#L142)
that suggests starting with brainstorming for "investigation/spike with
unknown scope" — but nothing else in the repo wires that suggestion.

This feature decides whether and where to formalize that pre-spec slot,
under the new constitution principle VI ("Native-First Compatibility —
Trust Upstream Growth") which forbids reimplementing or shadowing
upstream skills and pushes us toward the thinnest possible compatibility
layer over native capabilities.

---

## Clarifications

### Session 2026-05-17

- Q: Where does the integration content actually need to live so end-users
  benefit (given that `specify extension add` does NOT touch the consumer's
  AGENTS.md / CLAUDE.md / README on install)?
  → A: Option C — **the integration is fully implicit; this feature ships
  ZERO new bridge surface**. The actionable deliverable is a tip in this
  repo's **README** (and zh-CN mirror) telling users they can run
  Superpowers brainstorming before `/speckit-specify` and reference the
  resulting design doc in the description argument. AGENTS.md gets a
  brief maintainer-facing cross-reference. **This spec is "complete"
  once those doc edits land — no `/speckit-plan` / `/speckit-tasks` /
  `/speckit-implement` phase is required.** The end-user discovery
  channel is the OSS README on GitHub (linked from the marketplace
  catalog), not session-startup context injection.

## Scope (post-clarification)

- **In scope** (the only deliverables this feature ships):
  - One short workflow-tip section added to [README.md](README.md)
    explaining: when to brainstorm first; where the design doc lives
    (upstream-canonical path); how to feed it into `/speckit-specify`
    (paste a reference in the description argument).
  - The same tip mirrored in [README.zh-CN.md](README.zh-CN.md).
  - A brief maintainer-facing cross-reference in [AGENTS.md](AGENTS.md)
    (workflow section) noting the lifecycle decision rule and pointing
    at the README tip as the canonical user-facing source.
  - Optionally a one-line note in [CLAUDE.md](CLAUDE.md) cross-ref'ing
    AGENTS.md for the brainstorming convention.
  - This spec.md plus its checklist as the design-of-record.
- **Explicitly out of scope** (constitution principle VI applied):
  - No new files under `.specify/extensions/speckit-superpowers-bridge/`.
  - No edits to the bridge SKILL.md files
    (`.{claude,agents}/skills/speckit-superpowers-bridge/SKILL.md`).
  - No new command in the extension package.
  - No new install-time mechanism (e.g. `AGENTS.md` fragment injection).
  - No `.specify/templates/spec-template.md` callout.
  - No edits to vendor-managed `.{claude,agents}/skills/speckit-*` skills.
  - No `/speckit-plan` / `/speckit-tasks` / `/speckit-implement` phase
    for this feature; doc edits land as a normal commit on this branch
    once the spec is approved.
- **Distribution model the spec relies on**: end-users find the
  workflow tip by reading the OSS README (linked from the marketplace
  catalog entry's `documentation` field). The bridge contributes nothing
  shipped-to-consumer for this feature; the implicit integration relies
  on Superpowers' own `using-superpowers` skill to auto-trigger
  `brainstorming` when the user describes a vague idea, and on the
  existing guard's default-allow behavior in the pre-spec window.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Vague idea matures into a Spec Kit feature via brainstorming (Priority: P1)

A user with a half-formed idea ("we need something for X, but I'm not
sure what") wants to refine that idea into a clear, testable
specification before committing to the heavy Spec Kit lifecycle. They
invoke Superpowers brainstorming first; it runs its native Socratic
dialogue, surfaces alternatives, and produces a saved design doc. When
the user is satisfied, they invoke `/speckit-specify` referencing that
design doc, and the resulting `spec.md` captures the refined intent
without losing the rationale developed during brainstorming.

**Why this priority**: This is the single user-visible value of this
feature. Without it, vague-scope users have only two choices today:
(a) skip brainstorming and write a thin/imprecise spec, or (b) use
brainstorming informally and manually retype its output. The first
produces low-quality specs; the second wastes the design doc upstream
already created.

**Independent Test**: A user starting from a vague description in a
session with no active Spec Kit feature MUST be able to run native
brainstorming, end up with a design doc at the upstream-canonical path,
then invoke `/speckit-specify` with a reference to that doc and obtain
a `spec.md` that visibly inherits the brainstorming outcome (cited
sections, FRs traceable to brainstormed approaches, no NEEDS
CLARIFICATION on the items brainstorming already resolved).

**Acceptance Scenarios**:

1. **Given** no Spec Kit feature is active and the user has only a vague
   idea, **When** they invoke Superpowers brainstorming, **Then** the
   bridge guard MUST allow the invocation (no deny path triggers in the
   pre-spec window).
2. **Given** brainstorming has finished and saved a design doc to its
   upstream-canonical location, **When** the user invokes
   `/speckit-specify` referencing that doc in the description argument,
   **Then** the resulting `spec.md` MUST cite the design doc by relative
   path and MUST NOT contradict any decision the user explicitly approved
   during brainstorming.
3. **Given** the user prefers to skip brainstorming, **When** they invoke
   `/speckit-specify` directly with their own description, **Then** the
   behavior MUST be identical to today: no new prompts, no new gates, no
   blocking on a missing design doc.

---

### User Story 2 - Documentation answers "do I brainstorm first?" without code reading (Priority: P2)

A user (often new to the bridge) needs to decide whether their next
piece of work should start with brainstorming or jump straight to
`/speckit-specify`. Today they have to grep the repo or read the guard
script to discover that brainstorming is sometimes allowed and
sometimes denied. After this feature ships, a single documented
lifecycle decision in the **OSS `README.md` (English) and
`README.zh-CN.md` (Chinese mirror)** — discoverable from the
marketplace catalog's `documentation` link — answers the question in
under one minute of reading. `AGENTS.md` carries a short cross-reference
for maintainers but is NOT the load-bearing audience surface (since the
bridge's install does not propagate AGENTS.md into the consumer's
project).

**Why this priority**: The integration value is wasted if users cannot
discover it. But it is lower priority than US1 because a user who knows
about brainstorming can use it today; this story improves
discoverability rather than enabling new behavior.

**Independent Test**: A first-time reader of `README.md` (e.g., a user
who clicks through from the marketplace catalog) MUST be able to
answer "should I run brainstorming before specify for this idea?"
in under 60 seconds, citing only the README itself (no trips to
obra/superpowers or to guard-command.ps1, no requirement that the
reader has already cloned the repo or read AGENTS.md).

**Acceptance Scenarios**:

1. **Given** a user reading `README.md` cold (e.g., arriving from the
   marketplace catalog link), **When** they reach the workflow section,
   **Then** they MUST find a documented decision rule distinguishing
   "vague scope → brainstorm first" from "clear scope → specify
   directly".
2. **Given** the same user, **When** they look up where the brainstorming
   design doc is saved, **Then** they MUST find the upstream-canonical
   path (`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`)
   documented in `README.md` — not a relocated path invented by the
   bridge, and not a path the user would have to dig out of upstream
   obra/superpowers docs.

---

### User Story 3 - Active-feature invariant preserved (Priority: P3)

When a Spec Kit feature is mid-flight (has at least `spec.md` and
`plan.md`), brainstorming MUST continue to be denied by the bridge
guard, exactly as it is today. This story exists to capture the
**negative-space invariant**: this feature MUST NOT loosen the existing
deny rule. It is also a fast regression guard.

**Why this priority**: Lowest priority because it preserves existing
behavior rather than adding new behavior, but it is in scope because
the natural temptation when adding a positive integration is to also
relax adjacent guard rules. This story prevents that drift.

**Independent Test**: After this feature ships, the existing
guard-rule smoke test for "deny brainstorming when active feature has
spec + plan" MUST still pass, byte-identical, with no rule re-numbering
and no new conditional branches added.

**Acceptance Scenarios**:

1. **Given** an active Spec Kit feature with `spec.md` and `plan.md`,
   **When** any actor (Codex or Claude) invokes
   `superpowers:brainstorming`, **Then** the guard MUST deny it via the
   existing hardcoded rule.
2. **Given** the same active feature, **When** the user wants to
   discard Spec Kit ownership and start over from brainstorming, **Then**
   they MUST first transition the handoff to `blocked` or remove the
   artifacts — exactly as today; this feature MUST NOT add a new
   "force-brainstorm" escape hatch.

---

### Edge Cases

- **Brainstorming yields multiple sub-projects** (the skill's documented
  decomposition behavior): the bridge MUST treat each sub-project as a
  separate `/speckit-specify` invocation. The bridge MUST NOT attempt to
  batch-create multiple Spec Kit features from a single brainstorming
  design doc; the user (or the LLM) drives the split.
- **Brainstorming design doc mentions a tech stack** (e.g. "React vs.
  Vue"): `spec.md` MUST remain technology-agnostic per Spec Kit's spec
  template; the user/LLM is responsible for translating tech-flavored
  brainstormed decisions into tech-neutral functional requirements.
  Tech details belong in `plan.md`, not `spec.md`.
- **User abandons brainstorming mid-session**: no cleanup story is owned
  by the bridge — the partial design doc (if any) stays where upstream
  put it; nothing in the bridge depends on its existence.
- **Brainstorming on Codex**: the bridge MUST behave the same on Codex
  as on Claude Code (constitution principle III). If Codex's skill
  loader does not surface a `superpowers:brainstorming` equivalent, the
  documented workflow MUST degrade gracefully — the user simply does
  not get brainstorming on that agent, with no error and no broken
  reference. The bridge MUST NOT special-case agents.
- **Two-stage scope shift**: user starts brainstorming → realises mid-way
  it is actually two features → stops, then invokes brainstorming again
  for the second piece. Both design docs coexist at the upstream-canonical
  path with different dates/topics; both feed independent `/speckit-specify`
  calls. No bridge state tracks this — file-system convention only.
- **Brainstorming design doc edited after spec.md is created**: this is
  user discretion; the bridge MUST NOT auto-resync. The `spec.md`
  reference to the design doc is a citation, not a live link.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The bridge MUST document an OPTIONAL pre-`/speckit-specify`
  brainstorming workflow available to users whose scope is vague or
  contested. The **canonical user-facing venue is the OSS `README.md`**
  (and its Chinese mirror `README.zh-CN.md`), which end-users discover
  via the marketplace catalog's `documentation` link. `AGENTS.md` MAY
  carry a short cross-reference for maintainer / cross-agent runtime
  context, but `AGENTS.md` is NOT propagated into consumer projects by
  `specify extension add` and MUST NOT be treated as the end-user
  discovery channel.
- **FR-002**: The bridge MUST NOT re-implement, shadow, wrap, or fork
  the upstream `superpowers:brainstorming` skill. Invocation MUST go
  through whatever native mechanism each agent already supports
  (Claude Code skill / Codex equivalent); the bridge contributes
  documentation and convention only. (Constitution principle VI.)
- **FR-003**: The brainstorming output (design doc) MUST remain at its
  upstream-canonical location (`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`).
  The bridge MUST NOT relocate, rename, copy, or template-ize that file.
  If upstream changes the path, the bridge follows.
- **FR-004**: A user MUST be able to feed a brainstorming design doc into
  `/speckit-specify` without any new flag, environment variable, or
  argument to `/speckit-specify`. The supported convention is to reference
  the design doc's relative path inside the description argument the user
  already passes to `/speckit-specify` (e.g. "…see
  docs/superpowers/specs/2026-05-17-foo-design.md for full context").
- **FR-005**: When `/speckit-specify` is invoked with a description that
  references an existing brainstorming design doc by relative path, the
  command's LLM step SHOULD treat that doc as authoritative additional
  context for spec drafting — meaning the resulting `spec.md` cites the
  design doc and does not contradict approved decisions in it. This is
  **best-effort LLM behavior driven by the user's pasted reference**;
  the bridge does NOT enforce it via any new prompt injection, hook,
  or guard. If a future model fails to honor a pasted reference, the
  remedy is upstream (Spec Kit prompt evolution / model evolution), not
  a bridge-side workaround.
- **FR-006**: The bridge guard MUST continue to deny
  `superpowers:brainstorming` when an active Spec Kit feature has both
  `spec.md` and `plan.md` (the existing hardcoded rule). This feature
  MUST NOT modify, re-number, or relax that rule.
- **FR-007**: The bridge guard MUST allow `superpowers:brainstorming`
  whenever no Spec Kit feature is active OR when the active feature is
  in pre-spec stage (no `spec.md` yet) — this is the existing default-allow
  behavior; this feature MUST verify it via the existing smoke tests and
  document it, with NO new guard rule added.
- **FR-008**: The documentation MUST present a single explicit lifecycle
  decision rule distinguishing "vague scope / spike / unknown" (start
  with brainstorming) from "clear scope / known requirement" (start with
  `/speckit-specify`). The rule MUST be visible from the workflow
  section of the OSS `README.md` (and `README.zh-CN.md` mirror); a
  one-line maintainer cross-reference MAY appear in `AGENTS.md` but is
  not load-bearing for end-user discovery.
- **FR-009**: The documentation MUST cover the scope-decomposition edge
  case: if brainstorming yields multiple sub-projects, each one becomes
  its own Spec Kit feature via its own `/speckit-specify` invocation.
- **FR-010**: The documentation MUST cover the agent-neutrality
  expectation: brainstorming integration is documented identically for
  Codex and Claude Code; if either agent surface lacks brainstorming
  natively, the workflow degrades gracefully (the user skips that step)
  with no bridge-side error.
- **FR-011**: This feature MUST NOT introduce any new state file,
  hook (in `extensions.yml`), script under `.specify/extensions/`,
  guard rule, bridge command file under
  `.specify/extensions/speckit-superpowers-bridge/commands/`, or edit
  to either bridge `SKILL.md` peer. Total changes MUST fit within:
  documentation edits to `README.md`, `README.zh-CN.md`, a brief
  maintainer cross-reference in `AGENTS.md`, optionally one line in
  `CLAUDE.md`, and the spec/checklist artifacts under
  `specs/010-prespec-brainstorming/`. (Constitution principle VI
  native-first gate; reaffirmed by Clarifications §Session 2026-05-17.)
- **FR-012**: The existing constitution Principle II prohibition —
  "Superpowers `brainstorming` MUST NOT replace Spec Kit `plan.md` or
  `tasks.md` while those artifacts exist for the active feature" —
  MUST NOT be weakened, restated, or contradicted by any documentation
  added in this feature. The new docs MUST cross-reference Principle II
  where the deny boundary is described.

### Key Entities

- **Brainstorming design doc**: a Markdown file produced by the
  upstream `superpowers:brainstorming` skill at
  `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. Attributes:
  date, topic slug, decision sections, approved approach. Lifecycle:
  created during a brainstorming session, optionally referenced from
  zero or more `specs/<NNN>-*/spec.md` files, never owned by the
  bridge.
- **Lifecycle decision rule**: the textual rule in `AGENTS.md`
  distinguishing "brainstorm-first" from "specify-first" paths. Not a
  data structure; documentation prose with a one-table decision matrix.
- **Spec doc back-reference**: an inline citation in `spec.md` that
  names the brainstorming design doc as input. Plain Markdown link.
  Not validated by code; trust convention.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user with a vague description can produce an approved
  `spec.md` referencing a brainstorming design doc in **under 30 minutes
  of total elapsed time** in one session (brainstorming dialogue +
  `/speckit-specify` run + checklist pass), on either Claude Code or
  Codex provided that agent surfaces brainstorming natively.
- **SC-002**: After this feature ships, **zero new lines of script code**
  (PowerShell, bash, JavaScript, Python) exist under
  `.specify/extensions/`, `.claude/skills/speckit-superpowers-bridge/`,
  `.agents/skills/speckit-superpowers-bridge/`, or the project root.
  The diff is **documentation + spec artifacts only**. (Native-First
  invariant from constitution VI.)
- **SC-003**: The existing 5 hardcoded rules in
  `guard-command.ps1` (and its bash sibling) MUST remain
  **byte-identical** after this feature, verified by the existing
  guard-rules smoke test passing without any test edits.
- **SC-004**: A first-time reader of `README.md` (arriving via the
  marketplace catalog's documentation link, with no prior repo clone
  and no AGENTS.md exposure) answers "should I brainstorm first for
  this idea?" correctly in **under 60 seconds** of reading, citing only
  `README.md` itself. (Measured by a one-shot documentation-readability
  review during PR.)
- **SC-005**: When the user skips brainstorming entirely,
  `/speckit-specify` behavior is **functionally unchanged** versus the
  pre-feature baseline — no new prompts, no new arguments, no extra
  files written, no extra time spent (within 5% of baseline elapsed
  time on the same input).
- **SC-006**: Since this feature ships **no new artifact into a
  consumer's project** (per Clarifications §Session 2026-05-17 and
  FR-011), the End-User Verification Sandbox run is **scoped to a
  documentation-only check**: install the bridge in the sandbox, open
  the rendered `README.md` (the one linked from the marketplace catalog
  entry), and confirm a reader can answer SC-004 in under 60 seconds.
  No full bridge cycle is needed for this feature's sandbox pass;
  ordinary release-time sandbox cycles for other features continue
  unchanged.

---

## Assumptions

- The upstream `superpowers:brainstorming` skill is available natively
  on Claude Code via its plugin marketplace install, and its
  documented design-doc path (`docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`)
  remains stable for the lifetime of this feature. If upstream renames
  or moves the path, the bridge documentation follows at the next
  amendment (Principle VI migration rule).
- **End-user discovery of bridge workflow conventions happens via the
  OSS `README.md` on GitHub**, linked from the marketplace catalog
  entry's `documentation` field. The extension's install procedure
  (`specify extension add`) does NOT modify the consumer's `AGENTS.md`,
  `CLAUDE.md`, `GEMINI.md`, or `README.md`; only files under
  `.specify/extensions/<name>/` and registered hook entries in
  `.specify/extensions.yml` reach the consumer. (Empirically verified
  during clarify; see Clarifications §Session 2026-05-17.)
- The Codex agent surface has an equivalent invocation route for
  brainstorming. If it does not, the workflow degrades to "Codex users
  skip brainstorming" and the README tip explicitly notes that
  possibility; no bridge code attempts to emulate brainstorming on
  Codex.
- `/speckit-specify` is a vendor-managed skill (`.claude/skills/speckit-specify/`,
  `.agents/skills/speckit-specify/`) per constitution principle V and
  MUST NOT be hand-edited. The integration is therefore a *convention*
  consumed by the LLM at prompt time (via a reference the user pastes
  into the description argument), not a flag or argument compiled into
  the skill.
- The existing informal mention of brainstorming in `README.md:144` /
  `README.zh-CN.md:142` will be replaced or upgraded by the formal
  workflow tip this feature adds, not duplicated.
- The constitution amendment to v1.3.0 (principle VI Native-First,
  ratified 2026-05-17) has already landed and is the controlling
  authority for every design decision in this feature.
- "Vague scope" vs. "clear scope" is a judgment call left to the user
  and the LLM at session start; the bridge does NOT define a checklist
  to mechanically classify ideas.
- **This feature's lifecycle stops at "spec approved + doc edits
  landed"**: there is no `/speckit-plan`, `/speckit-tasks`,
  `/speckit-implement`, or Superpowers handoff for this feature. The
  doc edits are mechanical follow-up applied as a normal commit on the
  `010-prespec-brainstorming` branch and merged via the usual PR flow.
  (Per Clarifications §Session 2026-05-17: "本spec编辑完文档更新即结束".)
