[简体中文](README.zh-CN.md)

![License](https://img.shields.io/github/license/lihan3238/speckit-superpowers-bridge)
![Latest release](https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge)
![Last commit](https://img.shields.io/github/last-commit/lihan3238/speckit-superpowers-bridge)
![Spec Kit](https://img.shields.io/badge/spec--kit-%E2%89%A50.8.10-blue)

# speckit-superpowers-bridge

**A thin orchestrating bridge between Spec Kit (design) and Superpowers (implementation).** Spec Kit stays the source of truth for design (constitution → spec → plan → tasks). Superpowers executes implementation with TDD, verification, and review — invoked **explicitly** at named lifecycle phases. Cross-agent: works on Codex, Claude Code, or both. Repo-local protocol; no daemon, no service, no custom discipline beyond what native Superpowers provides.

> The design intent is documented in the [Spec Kit vs Superpowers comparison article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj) — this extension is the minimal wiring that lets the two tools cooperate.

## workflow

```text
                  ┌───────────────────── Spec Kit phase ─────────────────────┐
  user ─► /speckit-constitution ─► /speckit-specify ─► /speckit-clarify ─►
          /speckit-plan ─► /speckit-tasks
                                                       │
                                                       │ after_tasks hook
                                                       ▼
                          ┌──────── speckit-superpowers-bridge ─────────┐
                          │  handoff (writes superpowers-handoff.json)  │
                          │  guard (5 hardcoded boundary rules)         │
                          │  execute (orchestrates native skills)       │
                          └──────────────────┬──────────────────────────┘
                                             │
                  ┌────────── Superpowers phase (explicit invocations) ───────┐
                  ▼                                                            ▼
       superpowers:executing-plans                   superpowers:verification-before-completion
       superpowers:test-driven-development           superpowers:requesting-code-review
       superpowers:systematic-debugging              superpowers:finishing-a-development-branch
                                             │
                                             │ handoff transitions logged
                                             ▼
                                   .specify/bridge-events.jsonl
```

## installation

Spec Kit must be installed first. The extension is listed in the official
Spec Kit community catalog for discovery and review:

Official listing: [docs/community/extensions.md](https://github.com/github/spec-kit/blob/main/docs/community/extensions.md) (accepted via [issue #2581](https://github.com/github/spec-kit/issues/2581) and [PR #2586](https://github.com/github/spec-kit/pull/2586)).

The community catalog is discovery-only by default, so the normal install
command uses the stable latest-release ZIP:

### Pure Codex

```powershell
specify init my-project --integration codex
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

No Claude Code dependency. The bridge runs entirely through Codex's `$speckit-*` invocation surface.

### Pure Claude Code

```powershell
specify init my-project --integration claude
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

No Codex dependency. The bridge runs through Claude Code's `/speckit-*` slash commands.

### Both (cross-agent handoff)

```powershell
specify init my-project --integration claude         # or --integration codex
cd my-project
specify integration install codex                     # or 'claude' if you started with codex
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

Both `.agents/skills/` (Codex) and `.claude/skills/` (Claude Code) receive the bridge skill peer files. You can design in one agent and implement in another by simply switching tabs.

### Local development install

For working on the bridge itself:

```powershell
specify extension add --dev .\.specify\extensions\speckit-superpowers-bridge
```

### Version-pinned install

Use the pinned ZIP when you need a reproducible install for a specific release:

```powershell
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v0.4.3/speckit-superpowers-bridge-v0.4.3.zip
```

## prerequisites

Windows users need PowerShell 5.1+ (preinstalled on supported Windows releases). Linux and macOS users run the same extension ZIP through the bash flavor and need:

- `bash >= 4.0`
- `jq >= 1.6`

Install examples:

```bash
sudo apt install bash jq      # Ubuntu / Debian
brew install bash jq          # macOS
sudo dnf install bash jq      # Fedora
```

Contributors who run the repository smoke tests on any OS also need PowerShell Core (`pwsh`) 7.x. End users on Linux/macOS do not need `pwsh` for normal bridge execution.

## your first feature in 10 minutes

```text
1. /speckit-constitution            (one time per project)
2. /speckit-specify "add OAuth2 sign-in"
3. /speckit-clarify                 (the bridge asks 2–5 targeted Qs)
4. /speckit-plan                    (writes plan.md + research.md + data-model.md + contracts/)
5. /speckit-tasks                   (writes tasks.md)
                       │
                       │ after_tasks hook fires → handoff JSON written; status=executing
                       ▼
6. /speckit-superpowers-bridge      (Claude Code)  or  $speckit-superpowers-bridge  (Codex)
       │
       │ bridge SKILL.md loads; native Superpowers skills run in order:
       │   • superpowers:executing-plans drives the per-task loop
       │   • superpowers:test-driven-development per code-modifying task
       │   • superpowers:verification-before-completion at phase boundary
       │   • superpowers:requesting-code-review then :finishing-a-development-branch at end
       ▼
7. handoff → complete; next /speckit-specify auto-archives the previous one
```

## When to Skip Spec Kit

Not every change needs the full Spec Kit → bridge → Superpowers workflow. You decide the route:

| Change type | Recommended route |
|-------------|-------------------|
| Typo fix, single-line bug, tiny refactor | Invoke Superpowers directly. Skip `/speckit-specify`. |
| New feature, multi-file refactor, anything requiring design decisions | Full flow: `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-superpowers-bridge`. |
| Investigation or spike with unknown scope | Start with Superpowers `brainstorming`; promote to the full flow if a spec emerges. |

The bridge no longer recommends this routing automatically (the previous `recommend-route` command was removed in 0.3.0). You make the call. The guard still enforces boundary rules either way — it does not block direct Superpowers use when there is no active Spec Kit handoff.

## commands

| Command (Claude Code) | Command (Codex) | Purpose |
|---|---|---|
| `/speckit-superpowers-bridge` | `$speckit-superpowers-bridge` | Run Spec Kit `tasks.md` through Superpowers via the bridge protocol |
| `/speckit-speckit-superpowers-bridge-handoff` | `$speckit-speckit-superpowers-bridge-handoff` | Create or update the Superpowers handoff state |
| `/speckit-speckit-superpowers-bridge-guard` | `$speckit-speckit-superpowers-bridge-guard` | Check whether a requested command is allowed under the current handoff state |

Fresh marketplace installs generate `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge` from the execute command alias. The canonical fallback remains `$speckit-speckit-superpowers-bridge-execute` / `/speckit-speckit-superpowers-bridge-execute`. Handoff and guard intentionally keep their canonical long names because they are advanced/internal commands.

If you see `.agents/skills/speckit-speckit-superpowers-bridge-*` or `.claude/skills/speckit-speckit-superpowers-bridge-*`, that is normal: Spec Kit generated those skills from extension commands. The source repository also contains short local bridge skill mirrors under `.agents/skills/speckit-superpowers-bridge/` and `.claude/skills/speckit-superpowers-bridge/`; do not expect those development mirrors to be copied directly from the extension ZIP.

The 6 meta-commands that existed in v0.2.x (`audit`, `validate`, `parity`, `recommend-route`, `submission-checklist`, `cleanup-audit`) were **removed in 0.3.0**. They duplicated discipline that native Superpowers already provides, or codified custom features beyond the thin-bridge scope. See `CHANGELOG.md`.

## configuration

The bridge reads two layers of configuration in priority order: explicit script arguments > environment variables.

### actor resolution

When a bridge script needs to know which agent invoked it (`-Actor`), it resolves in this order:

1. Explicit `-Actor <codex|claude|unknown>` argument.
2. `SPECKIT_BRIDGE_ACTOR` environment variable.
3. Literal `"unknown"`.

Per-agent bridge `SKILL.md` files hardcode `-Actor` / `--actor` to their own agent — so in normal dialog use, you never need to set the env var. The chain matters for CI or manual script invocation.

See `AGENTS.md` for the master cross-agent protocol; `CLAUDE.md` for Claude-specific supplements.

## troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `handoff stuck in executing` | Previous bridge run was interrupted before transitioning to `complete` or `blocked` | Inspect `superpowers-handoff.json`; if work is genuinely done, run `update-handoff.ps1 -Status complete` or `update-handoff.sh --status complete`; if abandoned, set `blocked` with a reason |
| `missing per-agent peer skill` | One agent's `.X/skills/<id>` exists but the other agent's does not | Mirror the SKILL.md from the agent that has it; or remove the orphan |
| only long `speckit-speckit-superpowers-bridge-*` skills appear | Installed `v0.4.0-rc.1` or an older package before the execute alias existed | Upgrade with the latest-release ZIP command above; the short execute alias is `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge` |
| `specify extension info` throws `UnicodeEncodeError` on Windows | Legacy GBK console cannot render Rich's bullet character | Run `chcp 65001` or set PowerShell output to UTF-8. This is a Spec Kit CLI display issue, not a bridge install failure |
| guard denies an unexpected action | One of the 5 hardcoded rules in `guard-command.ps1` is firing | Read the deny reason printed by the guard; the rule set is small and inspectable |
| handoff JSON from an older install has v3 fields | Pre-0.3.0 handoff with `autonomous_mode`/`resume_context`/`archive_history` | No action needed. The 0.3.0 bridge reads these tolerantly and silently drops them on the next write. |

## maintenance and versioning

This release is verified against:

- **Spec Kit** `0.8.10`
- **Superpowers** skill pack `v5.1.0`

Version compatibility is now verified by human inspection at release time (the previous automated `verified-versions.json` and `parity-check.ps1` were removed in 0.3.0). When upstream tools ship a new release that breaks the bridge, we either patch the 3 retained scripts or pin the documented compatible versions in `CHANGELOG.md`.

## architecture in 60 seconds

> Adapted with attribution from the [Spec Kit vs Superpowers comparison article (truongpx396, dev.to)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj).

- **Spec Kit owns WHAT.** Constitution, spec, clarify, plan, tasks, checklists, analysis. These are durable design artifacts under `.specify/` and `specs/`.
- **Superpowers owns HOW.** TDD, debugging, executing-plans, requesting-code-review, verification-before-completion, finishing-a-development-branch. These are implementation discipline skills invoked at lifecycle phases.
- **The bridge orchestrates native skills and does not provide custom discipline.** It contributes only: generated extension command skills, four small state scripts in PowerShell and bash flavors (`update-handoff`, `guard-command`, `auto-archive-handoff`, `common-actor-resolution`), and 5 hardcoded boundary rules. No matrix, no audits, no validation pass, no parity check.

### how the bridge differs from peer extensions

| Extension | Focus | How the bridge differs |
|---|---|---|
| [AIDE](https://github.com/mnriem/spec-kit-extensions) | 7-step structured project-genesis workflow | AIDE adds a workflow on top of Spec Kit; this bridge **connects** Spec Kit to Superpowers' execution layer |
| [architect-preview](https://github.com/UmmeHabiba1312/spec-kit-architect-preview) | Continuous architecture governance for AI-assisted dev | Architect-preview reviews specs/plans/code for drift; this bridge orchestrates two tools without adding discipline |
| api-contract-evolution | API contract evolution, breaking-change detection | Different layer entirely; this bridge is meta over Spec Kit + Superpowers, not API-shaped |
| impact-predictor | Predicts architectural impact / risks of proposed changes | Predictive vs. our bridge being mechanical |

## contributing and license

MIT — see [`LICENSE`](LICENSE).

This extension was developed using AI coding assistants (Claude Code for design + planning; Codex for implementation passes; Claude Code for the v0.3.0 trim itself) per the AI-disclosure requirement in [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md). Every artifact passes human review before commit. Three retained smoke tests under `tests/` exercise the handoff schema, the hardcoded guard rules, and cross-agent skill parity.

Issues and discussion: <https://github.com/lihan3238/speckit-superpowers-bridge/issues>
