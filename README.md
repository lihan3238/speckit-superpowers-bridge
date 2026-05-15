[简体中文](README.zh-CN.md)

![License](https://img.shields.io/github/license/lihan3238/speckit-superpowers-bridge)
![Latest release](https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge)
![Last commit](https://img.shields.io/github/last-commit/lihan3238/speckit-superpowers-bridge)
![Spec Kit](https://img.shields.io/badge/spec--kit-%E2%89%A50.8.10-blue)

# speckit-superpowers-bridge

**Spec Kit + Superpowers, formally combined.** Spec Kit stays the source of truth for design (constitution → spec → plan → tasks). Superpowers executes implementation with TDD, verification, and review — invoked **explicitly** at named lifecycle phases. Cross-agent: works on Codex, Claude Code, or both. Lightweight repo-local protocol; no daemon, no service, no global plugin patching.

> The design intent is documented in the [Spec Kit vs Superpowers comparison article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj) — this extension turns its combination pattern into an enforced contract.

## workflow

```text
                  ┌───────────────────── Spec Kit phase ─────────────────────┐
  user ─► /speckit-constitution ─► /speckit-specify ─► /speckit-clarify ─►
          /speckit-plan ─► /speckit-tasks
                                                       │
                                                       │ after_tasks hook
                                                       ▼
                          ┌──────── speckit-superpowers-bridge ─────────┐
                          │  guard / handoff / disposition matrix /     │
                          │  parity check / audit / validate            │
                          └──────────────────┬──────────────────────────┘
                                             │
                  ┌────────── Superpowers phase (explicit invocations) ───────┐
                  ▼                                                            ▼
       superpowers:test-driven-development            superpowers:verification-before-completion
       superpowers:systematic-debugging               superpowers:requesting-code-review
       superpowers:executing-plans (vs tasks.md)      superpowers:finishing-a-development-branch
                                             │
                                             │ every invocation logged as skill_invocation event
                                             ▼
                                   .specify/bridge-events.jsonl
```

## installation

Spec Kit must be installed first. Then pick one of the three install paths below.

### Pure Codex

```powershell
specify init my-project --integration codex
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.2.0/speckit-superpowers-bridge-v0.2.0.zip
```

No Claude Code dependency. The bridge runs entirely through Codex's `$speckit-*` invocation surface.

### Pure Claude Code

```powershell
specify init my-project --integration claude
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.2.0/speckit-superpowers-bridge-v0.2.0.zip
```

No Codex dependency. The bridge runs through Claude Code's `/speckit-*` slash commands.

### Both (cross-agent handoff)

```powershell
specify init my-project --integration claude         # or --integration codex
cd my-project
specify integration add codex                         # or 'claude' if you started with codex
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.2.0/speckit-superpowers-bridge-v0.2.0.zip
```

Both `.agents/skills/` (Codex) and `.claude/skills/` (Claude Code) receive the bridge skill peer files. You can design in one agent and implement in another by simply switching tabs.

### Local development install

For working on the bridge itself:

```powershell
specify extension add --dev .\.specify\extensions\speckit-superpowers-bridge
```

## your first feature in 10 minutes

```text
1. /speckit-constitution            (one time per project)
2. /speckit-specify "add OAuth2 sign-in"
3. /speckit-clarify                 (the bridge asks 2–5 targeted Qs)
4. /speckit-plan                    (writes plan.md + research.md + data-model.md + contracts/)
5. /speckit-tasks                   (writes tasks.md)
                       │
                       │ after_tasks hook fires → handoff JSON written; status=ready
                       ▼
6. /speckit-speckit-superpowers-bridge-execute
       │
       │ bridge SKILL.md loads; explicit Superpowers skill invocations begin:
       │   • superpowers:test-driven-development per task
       │   • superpowers:verification-before-completion at phase boundary
       │   • superpowers:requesting-code-review then :finishing-a-development-branch at end
       ▼
7. handoff → complete; /speckit-speckit-superpowers-bridge-validate confirms green
```

When you start the next feature, `/speckit-specify` triggers `auto-archive-handoff.ps1`, which moves the previous `complete` handoff to `ready` and clears `feature_directory` — no manual handoff cleanup needed.

## commands

| Command (Claude Code) | Command (Codex) | Purpose |
|---|---|---|
| `/speckit-speckit-superpowers-bridge-execute` | `$speckit-speckit-superpowers-bridge-execute` | Run Spec Kit `tasks.md` through Superpowers via the bridge protocol |
| `/speckit-speckit-superpowers-bridge-handoff` | `$speckit-speckit-superpowers-bridge-handoff` | Create or update the Superpowers handoff state |
| `/speckit-speckit-superpowers-bridge-guard` | `$speckit-speckit-superpowers-bridge-guard` | Check whether a requested command is allowed under the current handoff state |
| `/speckit-speckit-superpowers-bridge-audit` | `$speckit-speckit-superpowers-bridge-audit` | Inspect install state: integrations, git extension, per-agent skill parity |
| `/speckit-speckit-superpowers-bridge-validate` | `$speckit-speckit-superpowers-bridge-validate` | End-to-end validation pass (handoff state + matrix + skill invocations + tests) |
| `/speckit-speckit-superpowers-bridge-parity` | `$speckit-speckit-superpowers-bridge-parity` | Audit disposition matrix, version pins, and agent parity |
| `/speckit-speckit-superpowers-bridge-recommend-route` | `$speckit-speckit-superpowers-bridge-recommend-route` | Advisory hint: full Spec Kit pipeline vs. direct Superpowers route |
| `/speckit-speckit-superpowers-bridge-submission-checklist` | `$…submission-checklist` | Local mirror of upstream catalog submission verification |
| `/speckit-speckit-superpowers-bridge-cleanup-audit` | `$…cleanup-audit` | Pre-release source-repo cleanup audit |

## configuration

The bridge reads three layers of configuration in priority order: explicit script arguments > environment variables > project state.

### actor resolution

When a bridge script needs to know which agent invoked it (`-Actor`), it resolves in this order:

1. Explicit `-Actor <codex|claude|unknown>` argument.
2. `SPECKIT_BRIDGE_ACTOR` environment variable.
3. `.specify/integration.json.default_integration`.
4. Literal `"unknown"`.

Per-agent bridge `SKILL.md` files hardcode `-Actor` to their own agent — so in normal dialog use, you never need to set the env var. The chain matters for CI or manual script invocation.

### autonomous mode

Set `autonomous_mode: true` on the handoff JSON (or `SPECKIT_BRIDGE_AUTONOMOUS=1` as a per-shell override) to suppress task-boundary confirmation prompts during `/speckit-speckit-superpowers-bridge-execute`. Default is off; only named review checkpoints (verification, code-review, finishing-branch) still pause for confirmation.

### resume context

On any session interrupt the bridge writes the active task ID + active Superpowers skill + next-expected-action into `superpowers-handoff.json.resume_context`. The next session's first non-tool output names them within 200 characters so the agent picks up cleanly.

See `AGENTS.md` for the master cross-agent protocol; `CLAUDE.md` for Claude-specific supplements. Detailed parameter reference for every bridge script is in [`.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md`](.specify/extensions/speckit-superpowers-bridge/docs/parameter-reference.md).

## troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `handoff stuck in executing` | Previous bridge run was interrupted before transitioning to `complete` or `blocked` | Inspect `superpowers-handoff.json`; if work is genuinely done, run `update-handoff.ps1 -Status complete`; if abandoned, `-Status blocked -Reason "abandoned"` |
| `parity check P1 finding` | New Spec Kit / Superpowers capability appeared upstream without a disposition entry | Add an entry to `disposition-matrix.json` with the chosen disposition and `verified_against`; re-run parity check |
| `missing per-agent peer skill` | One agent's `.X/skills/<id>` exists but the other agent's does not | Mirror the SKILL.md from the agent that has it; or remove the orphan; re-run audit |
| `autonomous mode not activating` | Handoff `autonomous_mode` field is `false` (default) | Run `update-handoff.ps1 -AutonomousMode $true` or set `SPECKIT_BRIDGE_AUTONOMOUS=1` |
| `validation-pass failing on first run` | One of the 10 ordered checks doesn't pass yet (matrix incomplete, missing skill invocations, etc.) | Read the report's findings — each carries a `suggested_fix`; address top-to-bottom |
| `download_url_unreachable` during submission-checklist | Release ZIP not yet built or URL wrong | Wait 2–5 minutes after pushing the tag; re-run; or fix `marketplace/catalog-entry.json.download_url` |

## maintenance and versioning

This release is verified against:

- **Spec Kit** `0.8.10` (pinned in `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`)
- **Superpowers** skill pack `5.1.0`

`parity-check.ps1` reports drift the moment either tool ships a release that adds or renames a capability. The contract is: when drift appears, we either update the matrix and bump `verified-versions.json`, or pin the bridge to the prior version. Either decision is documented in `CHANGELOG.md`.

## architecture in 60 seconds

> Adapted with attribution from the [Spec Kit vs Superpowers comparison article (truongpx396, dev.to)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj).

- **Spec Kit owns WHAT.** Constitution, spec, clarify, plan, tasks, checklists, analysis. These are durable design artifacts under `.specify/` and `specs/`.
- **Superpowers owns HOW.** TDD, debugging, executing-plans, requesting-code-review, verification-before-completion, finishing-a-development-branch. These are implementation discipline skills invoked at lifecycle phases.
- **The bridge formalizes their combination.** A [`disposition-matrix.json`](.specify/extensions/speckit-superpowers-bridge/disposition-matrix.json) classifies every Spec Kit command + Superpowers skill as `COMBINE` / `FORBID-UNDER-HANDOFF` / `SUPERSEDED-BY` / `REVIEW-ONLY` with explicit rationale. The guard consults the matrix before every potentially-overlapping action. The article warns auto-trigger can derail sessions, so the bridge SKILL.md issues **explicit** Superpowers invocations at named phases, each logged as a `skill_invocation` event for audit.

### how the bridge differs from peer extensions

| Extension | Focus | How the bridge differs |
|---|---|---|
| [AIDE](https://github.com/mnriem/spec-kit-extensions) | 7-step structured project-genesis workflow | AIDE adds a workflow on top of Spec Kit; this bridge **connects** Spec Kit to Superpowers' execution layer |
| [architect-preview](https://github.com/UmmeHabiba1312/spec-kit-architect-preview) | Continuous architecture governance for AI-assisted dev | Architect-preview reviews specs/plans/code for drift; this bridge enforces non-overlap policy across two tools |
| api-contract-evolution | API contract evolution, breaking-change detection | Different layer entirely; this bridge is meta over Spec Kit + Superpowers, not API-shaped |
| impact-predictor | Predicts architectural impact / risks of proposed changes | Predictive vs. our bridge being prescriptive about non-overlap |

## contributing and license

MIT — see [`LICENSE`](LICENSE).

This extension was developed using AI coding assistants (Claude Code for design + planning; Codex for implementation passes) per the AI-disclosure requirement in [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md). Every artifact passes human review before commit; the bridge's own `validation-pass.ps1` + 17 smoke tests are the verification surface.

Issues and discussion: <https://github.com/lihan3238/speckit-superpowers-bridge/issues>
