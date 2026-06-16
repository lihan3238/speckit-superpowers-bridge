<p align="center">
  <img src="https://raw.githubusercontent.com/lihan3238/speckit-superpowers-bridge/main/assets/social/github-social-preview.png" alt="speckit-superpowers-bridge: Spec Kit writes WHAT. Superpowers enforces HOW." width="960" />
</p>

<p align="center">
  <em>Spec Kit writes WHAT. Superpowers enforces HOW. This bridge only carries the handoff.</em>
</p>

<p align="center">
  <a href="./LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square" /></a>
  <a href="https://github.com/lihan3238/speckit-superpowers-bridge/releases"><img alt="Bridge version" src="https://img.shields.io/github/v/release/lihan3238/speckit-superpowers-bridge?style=flat-square&label=bridge" /></a>
  <a href="https://github.com/github/spec-kit"><img alt="Spec Kit verified 0.10.2" src="https://img.shields.io/badge/Spec_Kit-verified_0.10.2-success?style=flat-square" /></a>
  <a href="https://github.com/obra/superpowers"><img alt="Superpowers verified 6.0.0" src="https://img.shields.io/badge/Superpowers-verified_6.0.0-success?style=flat-square" /></a>
  <a href="https://github.com/github/spec-kit/blob/main/docs/community/extensions.md"><img alt="Spec Kit Marketplace listed" src="https://img.shields.io/badge/Spec_Kit_Marketplace-listed-blueviolet?style=flat-square" /></a>
</p>

# speckit-superpowers-bridge

> 中文版：[README.zh-CN.md](README.zh-CN.md)

**speckit-superpowers-bridge is the handoff layer between Spec Kit design artifacts and Superpowers implementation discipline.** Spec Kit stays the source of truth for design (constitution → spec → plan → tasks). Superpowers executes implementation with TDD, verification, and review, invoked **explicitly** at named lifecycle phases. Codex and Claude Code share the same repo-local protocol.

No daemon. No service. No database. No second workflow engine. No custom discipline beyond native Superpowers.

> The design intent is documented in the [Spec Kit vs Superpowers comparison article](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj) — this extension is the minimal wiring that lets the two tools cooperate.

---

## At a glance

| If you want... | The bridge gives you... |
|---|---|
| Spec Kit artifacts to remain canonical | Spec Kit keeps owning `spec.md`, `plan.md`, and `tasks.md`. |
| Superpowers discipline without replanning | `tasks.md` is handed to native Superpowers execution, verification, review, and branch-finishing skills. |
| Codex and Claude Code to cooperate | A shared `.specify/superpowers-handoff.json` contract with identical bridge skills for both agents. |
| Windows and Linux coverage | One ZIP ships bash and Windows PowerShell flavors, with release gates for both. |
| Marketplace-friendly confidence | `bridge-status --readiness`, package validation, deterministic release ZIPs, and published SHA evidence. |
| Minimal operational footprint | 3 commands, 5 hooks, 6 small state scripts per shell flavor, and no runtime service. |

Install the current stable release:

```bash
specify extension add speckit-superpowers-bridge \
  --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

## Why speckit-superpowers-bridge

Spec Kit is excellent at producing durable design artifacts (constitution, spec, plan, tasks, checklists, analysis), but its bundled `speckit.implement` is a one-shot LLM run with no TDD, no subagent fan-out, no structured review.

Superpowers is excellent at *execution* discipline (TDD, systematic debugging, subagent-driven development, verification, code review, finishing a development branch), but it natively expects to drive design through its own `brainstorming` and `writing-plans` skills, not from a Spec Kit `tasks.md`.

The bridge is the thinnest possible glue that lets the two cooperate without either side colonizing the other's role: a single `superpowers-handoff.json` state file, five hardcoded guard rules, six small scripts per shell flavor, and one orchestrator skill that invokes native Superpowers in order against the Spec Kit `tasks.md`. **No runtime matrix, no audit loop, no implementation validation pass, no command-parity subsystem, no custom DSL — just the smallest contract that makes the cycle work.**

## Quick Start

```bash
specify init my-project --integration claude   # or --integration codex
cd my-project
specify extension add speckit-superpowers-bridge \
  --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

What this does, in 7 steps:

1. `specify init` bootstraps a Spec Kit project with your chosen agent integration.
2. `specify extension add ... /releases/latest/download/...` installs the bridge from the stable-alias URL (always resolves to the latest released bridge — never goes stale on subsequent releases).
3. Spec Kit registers the bridge's 3 commands and 5 hooks in `.specify/extensions.yml`.
4. Bridge writes its boundary guard at `.specify/extensions/speckit-superpowers-bridge/scripts/`.
5. Drive a feature: `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks`.
6. The `after_tasks` hook fires automatically — bridge writes `.specify/superpowers-handoff.json` with status `executing`.
7. `/speckit-superpowers-bridge` (Claude Code) or `$speckit-superpowers-bridge` (Codex) drives native `superpowers:executing-plans` against `tasks.md`, then verification + code review + branch finishing. Handoff transitions to `complete`.

> [!TIP]
> Have only a vague idea? Run `superpowers:brainstorming` *before* `/speckit-specify`. The bridge guard allows it in the pre-spec window — the resulting design doc at `docs/superpowers/specs/<date>-<topic>-design.md` can be referenced in your `/speckit-specify` description so the LLM picks it up as context. See feature [010-prespec-brainstorming](specs/010-prespec-brainstorming/spec.md) for the documented lifecycle decision.

## 1.0.x Readiness and Support

v1.0.0 is a stable protocol release: no new workflow engine, no daemon, no service, no database, and no replacement for native Spec Kit or Superpowers behavior. The release adds stricter package/readiness checks and evidence for the supported platforms and agents.

v1.0.1 is a documentation and development-checkout cleanup patch on the same protocol surface.

v1.0.2 is a discoverability and launch-asset patch: README hero image, social cards, marketplace wording, and small contributor-doc fixes; runtime bridge behavior is unchanged.

v1.0.3 is a Spec Kit 0.10.x compatibility-alignment patch: re-verified on Spec Kit CLI `0.10.2`, declares the new `category`/`effect` manifest fields, and refreshes bootstrap docs for 0.10.0's opt-in git extension; runtime bridge behavior is unchanged.

v1.1.0 is a Superpowers 6.0.0 compatibility-alignment release: the verified-against-Superpowers baseline moves `5.1.0` → `6.0.0` (a major upstream bump) with **zero bridge runtime change**. Superpowers 6.0.0's breaking changes are all internal to upstream skills (the `subagent-driven-development` reviewer-prompt consolidation, worktrees relocating to project `.worktrees/`, vendor-neutral prose, three new harnesses) and transparent to the thin bridge, which invokes Superpowers by skill name only. See [`specs/016-superpowers-6-0-0-alignment/research.md`](specs/016-superpowers-6-0-0-alignment/research.md) for the grep-backed impact analysis.

| Target | Status | Evidence |
|---|---|---|
| Linux bash | Verified | Full bash smoke suite plus release-artifact sandbox cycle. |
| Windows PowerShell 5.1+ | Verified | Native PowerShell smoke plus release-artifact sandbox cycle. Set `PYTHONUTF8=1` if an older Windows Spec Kit CLI renders Rich symbols through a GBK console. |
| Codex | Verified | Bounded sandbox run with `codex-cli 0.137.0`. |
| Claude Code | Verified | Bounded sandbox run with Claude Code `2.1.162`. |

Run the lightweight readiness check after install:

```bash
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh --readiness --actor codex
bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh --readiness --json --actor codex
```

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\bridge-status.ps1 -Readiness -Actor claude
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\bridge-status.ps1 -Readiness -Json -Actor claude
```

The readiness report is read-only. It checks script flavor, required tools, command namespace, package files, current bridge state, verified agent metadata, and the next recommended action.

### Demo: user flow

<p align="center">
  <img src="docs/demo/hero.gif" alt="User flow demo — install, Spec Kit design commands, bridge execution" width="760" />
</p>

## Positioning

How the bridge differs from doing nothing, doing only one side, or using a peer hybrid:

| | Owns design | Owns implementation | Cross-agent | Bridge-style overhead |
|---|---|---|---|---|
| **Just `speckit.implement`** | Spec Kit | Spec Kit (one-shot LLM run) | partial (agent-aware via Spec Kit) | none |
| **Just Superpowers (no Spec Kit)** | Superpowers (`brainstorming` + `writing-plans`) | Superpowers (TDD + subagents) | yes (Claude Code + Codex via OS-level skills) | none |
| **Superspec** | Spec-first workflow | Plugin-managed implementation flow | varies by agent | higher — useful doctor/status ideas, but 1.0.0 install failures showed catalog id / namespace drift risk |
| **SuperB** | Superpowers-centered planning | Superpowers-centered implementation | yes | higher — richer orchestration, but more lifecycle ownership than this bridge wants |
| **Comet (rpamis/comet, OpenSpec + Superpowers)** | OpenSpec change/spec | Superpowers via Comet's state machine | yes (multi-platform npm installer) | medium — Comet has its own `.yaml` + guard scripts |
| **cc-spex (rhuss/cc-spex, formerly cc-sdd)** | Spec Kit (stays close to upstream, regular sync) | Spec Kit's explicit planning + selected Superpowers phases (guided brainstorming, intermediate spec/plan reviews, multi-subagent deep review) shipped as vanilla spec-kit extensions | Claude Code-focused | medium — opt-in extensions layered on spec-kit's flow |
| **speckit-superpowers-bridge** (this) | Spec Kit (vendor-owned) | Superpowers (vendor-owned) | yes (Codex + Claude Code, identical contract) | **extremely thin** — 1 guard script, 1 handoff JSON, 0 new state machinery |

The bridge's brand is **compatible with upstream growth + extremely lightweight**. Every release is graded against the constitution's [Principle VI Native-First gate](.specify/memory/constitution.md): does upstream already do this? Is upstream the right place to fix this? If either answer is "yes", the bridge does NOT add the feature.

---

<details>
<summary><strong>Workflow diagram</strong></summary>

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

</details>

<details>
<summary><strong>Installation (Codex / Claude Code / Both / dev / pinned)</strong></summary>

Spec Kit must be installed first. The extension is listed in the official Spec Kit community catalog for discovery and review.

Official listing: [docs/community/extensions.md](https://github.com/github/spec-kit/blob/main/docs/community/extensions.md) (accepted via [issue #2581](https://github.com/github/spec-kit/issues/2581) and [PR #2586](https://github.com/github/spec-kit/pull/2586)).

The community catalog is discovery-only by default, so the normal install command uses the stable latest-release ZIP.

**Pure Codex**

```powershell
specify init my-project --integration codex
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

No Claude Code dependency. The bridge runs entirely through Codex's `$speckit-*` invocation surface.

**Pure Claude Code**

```powershell
specify init my-project --integration claude
cd my-project
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

No Codex dependency. The bridge runs through Claude Code's `/speckit-*` slash commands.

**Both (cross-agent handoff)**

```powershell
specify init my-project --integration claude         # or --integration codex
cd my-project
specify integration install codex                     # or 'claude' if you started with codex
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

Both `.agents/skills/` (Codex) and `.claude/skills/` (Claude Code) receive the bridge skill peer files. You can design in one agent and implement in another by simply switching tabs.

**Local development usage** (for working on this bridge repo itself):

This source checkout already contains the bridge extension at
`.specify/extensions/speckit-superpowers-bridge/`, and
`.specify/extensions.yml` registers that local source as the installed
extension. Use the normal `$speckit-*` / `/speckit-*` commands from this repo;
do **not** install the published ZIP into the same checkout unless you
intentionally want to replace the local extension tree with release contents.

If a fresh `specify init --here ... --force` regenerated local install state and
the bridge needs to be re-registered, install from a temporary copy outside the
target extension directory:

```bash
tmp="$(mktemp -d)"
cp -a ./.specify/extensions/speckit-superpowers-bridge "$tmp"/
specify extension add --dev "$tmp/speckit-superpowers-bridge"
```

Do not pass `./.specify/extensions/speckit-superpowers-bridge` directly as the
`--dev` source from this source checkout. Spec Kit installs to that same target
path, so source and destination would be identical.

PowerShell equivalent:

```powershell
$tmp = New-Item -ItemType Directory -Path ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString()))
Copy-Item .\.specify\extensions\speckit-superpowers-bridge $tmp.FullName -Recurse
specify extension add --dev (Join-Path $tmp.FullName "speckit-superpowers-bridge")
```

Use the published ZIP only in a separate consumer project or in the sibling
release-verification sandbox `../test_specify_superpower`.

**Version-pinned install** (for reproducible installs of a specific release):

```powershell
specify extension add speckit-superpowers-bridge --from https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v1.1.0/speckit-superpowers-bridge-v1.1.0.zip
```

</details>

<details>
<summary><strong>Prerequisites</strong></summary>

Windows users need PowerShell 5.1+ (preinstalled on supported Windows releases). Linux and macOS users run the same extension ZIP through the bash flavor and need:

- `bash >= 4.0`
- `jq >= 1.6`

Install examples:

```bash
sudo apt install bash jq      # Ubuntu / Debian
brew install bash jq          # macOS
sudo dnf install bash jq      # Fedora
```

Contributors who run the repository smoke tests on any OS use the WSL bash suite (`bash tests/run-all.sh`, post-009 cleanup). End users do not need PowerShell Core (`pwsh`) for normal bridge execution.

</details>

<details>
<summary><strong>Your first feature in 10 minutes</strong></summary>

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

<p align="center">
  <img src="docs/demo/full-cycle.gif" alt="Full bridge cycle — install, specify, clarify, plan, tasks, bridge execution, complete" width="820" />
</p>

</details>

<details>
<summary><strong>When to skip Spec Kit</strong></summary>

Not every change needs the full Spec Kit → bridge → Superpowers workflow. You decide the route:

| Change type | Recommended route |
|-------------|-------------------|
| Typo fix, single-line bug, tiny refactor | Invoke Superpowers directly. Skip `/speckit-specify`. |
| New feature, multi-file refactor, anything requiring design decisions | Full flow: `/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-superpowers-bridge`. |
| Investigation or spike with unknown scope | Start with Superpowers `brainstorming`; promote to the full flow if a spec emerges. See feature [010-prespec-brainstorming](specs/010-prespec-brainstorming/spec.md). |

The bridge no longer recommends this routing automatically (the previous `recommend-route` command was removed in 0.3.0). You make the call. The guard still enforces boundary rules either way — it does not block direct Superpowers use when there is no active Spec Kit handoff.

</details>

<details>
<summary><strong>Commands</strong></summary>

| Command (Claude Code) | Command (Codex) | Purpose |
|---|---|---|
| `/speckit-superpowers-bridge` | `$speckit-superpowers-bridge` | Run Spec Kit `tasks.md` through Superpowers via the bridge protocol |
| `/speckit-speckit-superpowers-bridge-handoff` | `$speckit-speckit-superpowers-bridge-handoff` | Create or update the Superpowers handoff state |
| `/speckit-speckit-superpowers-bridge-guard` | `$speckit-speckit-superpowers-bridge-guard` | Check whether a requested command is allowed under the current handoff state |
| `bash .specify/extensions/speckit-superpowers-bridge/scripts/bash/bridge-status.sh` (or `.ps1` on Windows) | same | **(v0.7.0+)** Print current bridge state + `Drift:` + `Next:` recommendation in under a second. Read-only. `--json` for machine output. In v1.0.0, add `--readiness` / `-Readiness` for install health. |

Fresh marketplace installs generate `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge` from the execute command alias. The canonical fallback remains `$speckit-speckit-superpowers-bridge-execute` / `/speckit-speckit-superpowers-bridge-execute`. Handoff and guard intentionally keep their canonical long names because they are advanced/internal commands.

If you see `.agents/skills/speckit-speckit-superpowers-bridge-*` or `.claude/skills/speckit-speckit-superpowers-bridge-*`, that is normal: Spec Kit generated those skills from extension commands. The source repository also contains short local bridge skill mirrors under `.agents/skills/speckit-superpowers-bridge/` and `.claude/skills/speckit-superpowers-bridge/`; do not expect those development mirrors to be copied directly from the extension ZIP.

The 6 meta-commands that existed in v0.2.x (`audit`, `validate`, `parity`, `recommend-route`, `submission-checklist`, `cleanup-audit`) were **removed in 0.3.0**. They duplicated discipline that native Superpowers already provides, or codified custom features beyond the thin-bridge scope. See `CHANGELOG.md`.

</details>

<details>
<summary><strong>Configuration (actor resolution)</strong></summary>

The bridge reads two layers of configuration in priority order: explicit script arguments > environment variables.

**Actor resolution**: when a bridge script needs to know which agent invoked it (`-Actor`), it resolves in this order:

1. Explicit `-Actor <codex|claude|unknown>` argument.
2. `SPECKIT_BRIDGE_ACTOR` environment variable.
3. Literal `"unknown"`.

Per-agent bridge `SKILL.md` files hardcode `-Actor` / `--actor` to their own agent — so in normal dialog use, you never need to set the env var. The chain matters for CI or manual script invocation.

See `AGENTS.md` for the master cross-agent protocol; `CLAUDE.md` for Claude-specific supplements.

</details>

<details>
<summary><strong>Troubleshooting</strong></summary>

| Symptom | Likely cause | Fix |
|---|---|---|
| `handoff stuck in executing` | Previous bridge run was interrupted before transitioning to `complete` or `blocked` | Inspect `superpowers-handoff.json`; if work is genuinely done, run `update-handoff.ps1 -Status complete` or `update-handoff.sh --status complete`; if abandoned, set `blocked` with a reason |
| `missing per-agent peer skill` | One agent's `.X/skills/<id>` exists but the other agent's does not | Mirror the SKILL.md from the agent that has it; or remove the orphan |
| only long `speckit-speckit-superpowers-bridge-*` skills appear | Installed `v0.4.0-rc.1` or an older package before the execute alias existed | Upgrade with the latest-release ZIP command above; the short execute alias is `$speckit-superpowers-bridge` / `/speckit-superpowers-bridge` |
| `specify extension info` throws `UnicodeEncodeError` on Windows | Legacy GBK console cannot render Rich's bullet character | Run `chcp 65001` or set PowerShell output to UTF-8. This is a Spec Kit CLI display issue, not a bridge install failure |
| guard denies an unexpected action | One of the 5 hardcoded rules in `guard-command.ps1` is firing | Read the deny reason printed by the guard; the rule set is small and inspectable |
| handoff JSON from an older install has v3 fields | Pre-0.3.0 handoff with `autonomous_mode` / `resume_context` / `archive_history` | No action needed. The 0.3.0+ bridge reads these tolerantly and silently drops them on the next write. |

> [!WARNING]
> **WSL users: do NOT set `git config --global http.proxy`.** Use the per-call env-var pattern from `AGENTS.md` (`https_proxy=http://10.77.0.11:10808 git push ...`). A global proxy config bakes the address into git config and breaks on every machine where that proxy is unreachable. The bridge's release runbook and smoke suite assume the env-var-per-call pattern.

</details>

<details>
<summary><strong>Maintenance and versioning</strong></summary>

This release (v1.1.0) is verified against:

- **Spec Kit** `0.10.2` on Linux bash; Windows PowerShell evidence retained from v1.0.0 (the `ps` script flavor is byte-identical), where the sandbox passed the bridge runtime floor with Spec Kit CLI `0.8.10`
- **Superpowers** `6.0.0`
- **Codex CLI** `0.137.0`
- **Claude Code** `2.1.162`

Verified metadata is captured in [`.specify/extensions/speckit-superpowers-bridge/verified-versions.json`](.specify/extensions/speckit-superpowers-bridge/verified-versions.json) — a project-owned additive schema refreshed once per bridge release. v1.1.0 records bridge, upstream tool, platform, and real-agent rows; missing or blocked rows are not advertised as verified.

When upstream tools ship a new release that breaks the bridge, we either patch the bridge scripts or pin the documented compatible versions in `CHANGELOG.md`.

Spec Kit `0.9.x` moved coding-agent context updates into the bundled `agent-context` extension. The bridge runtime does not depend on that extension, so `requires.speckit_version` stays at `>=0.8.10`; this repository tracks `agent-context` only to keep its own Spec Kit project bootstrap current.

> [!NOTE]
> **From v0.6.0 onward**, the marketplace `download_url` is decoupled from the version. It permanently points at `https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip` and resolves via GitHub's `/releases/latest/` alias. Future bridge releases never edit `download_url`; only `version` is bumped in `marketplace/catalog-entry.json`. This removes a recurring per-release edit class and a drift surface — one of the smallest possible Principle-VI wins.

</details>

<details>
<summary><strong>Architecture in 60 seconds</strong></summary>

> Adapted with attribution from the [Spec Kit vs Superpowers comparison article (truongpx396, dev.to)](https://dev.to/truongpx396/spec-kit-vs-superpowers-a-comprehensive-comparison-practical-guide-to-combining-both-52jj).

- **Spec Kit owns WHAT.** Constitution, spec, clarify, plan, tasks, checklists, analysis. These are durable design artifacts under `.specify/` and `specs/`.
- **Superpowers owns HOW.** TDD, debugging, executing-plans, requesting-code-review, verification-before-completion, finishing-a-development-branch. These are implementation discipline skills invoked at lifecycle phases.
- **The bridge orchestrates native skills and does not provide custom discipline.** It contributes only: generated extension command skills, six small scripts in PowerShell and bash flavors (`update-handoff`, `guard-command`, `auto-archive-handoff`, `bridge-state`, `bridge-status`, `common-actor-resolution`), and 5 hardcoded boundary rules. No runtime matrix, no audit loop, no implementation validation pass, no command-parity subsystem.

</details>

---

## Contributing and License

MIT — see [`LICENSE`](LICENSE).

This extension was developed using AI coding assistants (Claude Code for design + planning; Codex for implementation passes; Claude Code for the v0.3.0 trim and the v0.6.0 polish) per the AI-disclosure requirement in [Spec Kit CONTRIBUTING.md](https://github.com/github/spec-kit/blob/main/CONTRIBUTING.md). Every artifact passes human review before commit. Smoke tests under [`tests/`](tests/) (bash flavor as of 009) exercise the handoff schema, the 5 hardcoded guard rules, the bridge-state output, and cross-agent skill parity.

Issues and discussion: <https://github.com/lihan3238/speckit-superpowers-bridge/issues>
