# Phase 0 Research: WSL Development Environment Alignment

**Feature**: `009-wsl-dev-env-alignment` | **Date**: 2026-05-16 | **Plan**: [plan.md](./plan.md)

Resolves the five open research items (R1..R5) declared in [plan.md](./plan.md). Each item lists Decision / Rationale / Alternatives considered. Output of this file is the input to Phase 1 (data-model, contracts, quickstart).

---

## R1 — `specify init --here --script sh` behavior on a repo with existing `init-options.json.script=ps`

**Decision**: Phase A executes the bootstrap in two ordered steps:

1. Flip `.specify/init-options.json.script` from `"ps"` to `"sh"` by hand (one-line edit), commit.
2. Run `specify init --here --script sh --force` to regenerate the gitignored install-state with the new flavor as the source of truth.

**Rationale**: `specify init`'s help confirms `--here` initialises in the current directory and `--force` skips the "current directory not empty" confirmation. The help does NOT document a merge-vs-overwrite policy for an already-populated repo, so we treat `init` as **idempotent overwrite within its own surface** (the install-state files) and rely on `--force` to skip prompts. By pre-setting `init-options.json` we make the maintainer's intent explicit in git history — even if `init` later overwrites the JSON itself, the diff between the two states is one tracked field, which is auditable.

The actual byte-level behavior of `specify init` on this exact repo will be observed during Phase A's first execution and recorded in `verification.md`. If the observed behavior diverges from the assumption (e.g., `init` refuses to run without `--integration`, or wipes `.specify/extensions.yml`), Phase A halts and this plan is amended.

**Alternatives considered**:
- *Let `specify init --script sh` rewrite `init-options.json` itself* — rejected: the maintainer's choice would be invisible until after `init` ran, making rollback harder if `init` did something unexpected.
- *Use `specify init` first, then patch `init-options.json` if needed* — rejected for the same reason: makes ordering ambiguous and forces two commits.
- *Skip `specify init` entirely and hand-port the missing bash flavor files* — rejected per Clarifications Q1 + Q2 Policy: the whole point is to let `specify init` carry the burden of regeneration, not to reintroduce a parallel hand-maintained set.

---

## R2 — What does `specify init --here --script <flavor>` regenerate on an existing repo, and what is its blast radius?

**Decision**: For planning purposes, the surface that `specify init` is **expected** to regenerate on this repo is:

| Path | Expected behavior |
|---|---|
| `.specify/scripts/<flavor>/` | Created / overwritten with the chosen flavor (`bash/` or `powershell/`). The other flavor is NOT removed if already present — `init` only writes the selected one. |
| `.claude/skills/speckit-{analyze,checklist,clarify,implement,plan,tasks,taskstoissues}/SKILL.md` | Overwritten with the chosen-flavor paths embedded (`.specify/scripts/<flavor>/check-prerequisites.<ext>`). |
| `.agents/skills/speckit-{same set}/SKILL.md` | Same as above for codex side, when the project has codex integration installed (current repo has both). |
| `.specify/templates/*.md` | Likely overwritten (these are core Spec Kit assets). Not in this feature's scope — these are not in our edit set. |

**Expected NOT to be touched**:

- `.specify/extensions/` (third-party extensions; speckit-superpowers-bridge lives here).
- `.specify/extensions.yml` (hook registry; project's own config).
- `.specify/init-options.json` — **MIGHT** be rewritten by init; mitigation is R1's pre-flip + commit so any rewrite is visible in diff.
- `.specify/superpowers-handoff.json`, `.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/` (bridge state).
- `.specify/memory/constitution.md`.
- `.claude/skills/speckit-superpowers-bridge/`, `.agents/skills/speckit-superpowers-bridge/` (project deliverable).
- `AGENTS.md`, `CLAUDE.md`.
- `.gitignore`, `.gitattributes`.
- `tests/`, `marketplace/`, `specs/`, `scripts/` (project files outside `.specify/`).

**Validation strategy**: Phase A's first action after the `git rm -r --cached` + gitignore steps is to run `specify init --here --script sh --force` AND immediately diff the working tree to confirm only the expected paths changed. If `init` touches anything else, Phase A halts and we either (a) add the unexpected path to the gitignore policy (if it falls under "user-facing install-state" per the Q1+Q2 Policy), or (b) revert and re-plan.

**Rationale**: We cannot ship this plan with a "TBD" surface, but we also cannot run `init` during planning (it modifies the repo). The expected matrix above is derived from the visible Spec Kit codebase pattern — the skill files clearly reference `.specify/scripts/<flavor>/...` paths, which only `init` could have written. Phase A treats the observation as a hard gate.

**Alternatives considered**:
- *Run `specify init` in a throwaway worktree first to observe* — viable but adds setup overhead; the gain is marginal because Phase A already validates against the matrix.
- *Read the Spec Kit CLI source code to derive the exact write list* — rejected: brittle (`specify` 0.8.11 → 0.8.x may change the list); the empirical Phase A check is the durable answer.

---

## R3 — Bash idiom inventory for the four test ports

**Decision**: The bash ports use a fixed style guide derived from the existing `.specify/extensions/speckit-superpowers-bridge/scripts/bash/update-handoff.sh` and `guard-command.sh`:

| PowerShell construct in originals | Bash port equivalent |
|---|---|
| `$ErrorActionPreference = "Stop"` | `set -euo pipefail` (already standard in the repo's bash scripts) |
| `function Get-RepoRoot { git rev-parse --show-toplevel }` | `REPO_ROOT="$(git rev-parse --show-toplevel)"` |
| `function Assert-True { ... throw $m }` | `assert_true() { [ "$1" = "true" ] \|\| { echo "$2" >&2; exit 1; } }` |
| `Get-Content -Raw \| ConvertFrom-Json` | `jq` against the file directly (`jq -r '.field' file.json`) |
| `$obj.PSObject.Properties.Name -contains 'autonomous_mode'` | `jq -e 'has("autonomous_mode")' file.json` (exit 0 = true) |
| `Set-Content -LiteralPath $p -Value $json -Encoding UTF8` | `printf '%s\n' "$json" > "$p"` or `jq -n ... > "$p"` |
| `$h.status -in @("ready","executing","blocked","complete")` | `case "$status" in ready\|executing\|blocked\|complete) ;; *) fail ;; esac` |
| Path-translation chain (`cygpath`, `/mnt/<drive>`, MSYS) | **DROPPED** — the bash test runs natively in bash; no need to translate paths from a PowerShell host. This is the single biggest simplification the port enables. |
| `Convert-ToBashPath` / `Test-BashPathReachable` / `Invoke-UpdateHandoff -Flavor bash` flavor-dispatch | **DROPPED** — the bash test only exercises the bash flavor of bridge scripts. Cross-flavor parity remains the job of the existing PS test (until that PS test itself is deleted in Phase B). |
| Snapshot-and-restore handoff via `Get-Content` + `Set-Content -NoNewline` | `cp` to a temp file + `trap 'cp "$tmp" "$handoff_path"' EXIT` |
| `Write-Host "  (bash flavor not exercised: ...)"` skip messages | `printf '%s\n' "  [skip] ..."` — same skip semantics but written for SC-007 ("silent absence forbidden" — explicit skip lines required) |

The `tests/run-all.sh` runner is a 5-line loop: `for f in tests/test-*.sh; do echo "=== $f ==="; bash "$f" || { echo "FAIL: $f" >&2; exit 1; }; done`.

**Rationale**: Reusing the bridge-extension bash scripts' style means the ports look native, not transliterated. The biggest source of complexity in the existing `.ps1` tests (path-translation, flavor-dispatch) is unnecessary in a pure-bash world — the simplification IS the alignment value.

**Alternatives considered**:
- *Use a bash test framework like `bats-core`* — rejected per Constitution Principle I ("Lightweight & Repo-Local") and per "简单对齐"; the existing PS tests don't use Pester either, plain assertions are fine.
- *Auto-port the .ps1 with a tool* — rejected: PowerShell→bash auto-port produces brittle output; manual port preserves the assertion contracts (which is what FR-007 demands) and lets us drop the path-translation chain cleanly.

---

## R4 — Where to insert the "Supported host environments" section in `AGENTS.md`

**Decision**: Insert a new top-level section **`## Supported Host Environments`** immediately after the existing `## Primary Design Reference` section and BEFORE the `## User-Facing Language Routing` section. This placement gives it the second-highest discoverability slot (top of file is reserved for the SPECKIT plan-reference marker; design-reference is the project's "north star").

**Content shape**:

```markdown
## Supported Host Environments

This repo supports two equivalent dev environments. Pick whichever matches your host:

| Environment | Required tools | Default flavor | One-time bootstrap (after clone) |
|---|---|---|---|
| Windows PowerShell 5.1+ | git, pwsh, gh, jq, specify CLI 0.8.10+ | `ps` | `specify init --here --script ps --force` |
| WSL2 Ubuntu bash 5.2+ (incl. `/mnt/c/...`) | git, bash, gh, jq, specify CLI 0.8.10+ | `sh` | `specify init --here --script sh --force` |

The bootstrap regenerates `.specify/scripts/<flavor>/` and the vendor-managed
`.claude/skills/speckit-{non-bridge}/` and `.agents/skills/speckit-{non-bridge}/`
slash-command skill files — these are gitignored as install-time state
(see `.gitignore` and `specs/009-wsl-dev-env-alignment/spec.md` Clarifications).

The project's own `speckit-superpowers-bridge` skill files under both
`.claude/skills/` and `.agents/skills/` are committed and MUST NOT be regenerated
by `specify init` — they are the project's deliverable.

To run the smoke-test suite:
- PowerShell: `pwsh -Command "Get-ChildItem tests/test-*.ps1 | ForEach-Object { & $_ }"` (until those files are removed by 009; afterwards same loop targeting `*.sh`)
- bash: `for f in tests/test-*.sh; do bash "$f" || exit 1; done` (or `tests/run-all.sh` if present)
```

**Rationale**: The placement satisfies SC-004 (under 30 seconds to find) because a new contributor scanning AGENTS.md sees `## Primary Design Reference` → `## Supported Host Environments` in the first screen of content. The format (table + per-env bootstrap one-liner + skill-boundary note) is the minimum information density needed for FR-010 + FR-005a + FR-011 to all be satisfied in one section.

**Alternatives considered**:
- *Insert at the very top before `## Primary Design Reference`* — rejected: the design reference is the project's identity; environments are operational. Identity comes first.
- *Insert as a subsection under `## Spec Kit + Superpowers Bridge`* — rejected: environments concern dev setup, not bridge protocol; the two are orthogonal.
- *Put it in a new `docs/SETUP.md`* — rejected: `docs/` is gitignored in this repo, and per FR-010 the section MUST live in `AGENTS.md` (the master agent context file) so coding agents see it on every session start.

---

## R5 — References to `tests/*.ps1` BY NAME that need redirection after Phase B's port-and-delete

**Decision**: Phase B updates exactly the following two paths in the same commit set as the `.ps1` deletions. All other references are historical (CHANGELOG entries describing past releases) and remain unchanged — rewriting them would falsify history.

| Path | Reference type | Action |
|---|---|---|
| `marketplace/README.md:41` | Current docs claim ("Run all 3 bridge smoke tests (`tests/test-*.ps1`)") | **Update** to reference `tests/test-*.sh` after Phase B |
| `marketplace/extension-submission-body.md:113-116` | Lists each `.ps1` file as part of the release submission template | **Update** to list `.sh` ports (this template is consumed by the NEXT release; updating it now prevents a stale submission body when v0.5.x ships) |
| `CHANGELOG.md` (various lines under [0.4.2], [0.4.3], [0.5.0] entries) | **Historical** record of what shipped in each release | **Leave unchanged**; rewriting history breaks the audit chain |

**Scope note**: Updating `marketplace/*` is technically a small expansion of FR-014's edit surface. Recording it here as a controlled, justified additive scope: the alternative (leaving the docs lying about the existence of `.ps1` files) violates SC-001's "silent absence forbidden" spirit, just transposed to the docs layer. The expansion is two file edits totaling < 10 lines.

**Tasks-side note**: The internal cross-test reference in the (about-to-be-deleted) `tests/test-bridge-state-summary.ps1` comment ("Pattern follows tests/test-handoff-shape.ps1") is naturally removed when the file is deleted in Phase B — no separate action required.

**Rationale**: The two `marketplace/*` paths are active documentation that a future maintainer will read and act on; the `CHANGELOG.md` entries describe the past truth correctly. Rule: edit forward-looking docs, leave backward-looking records alone.

**Alternatives considered**:
- *Update CHANGELOG.md entries too* — rejected; falsifies history and adds churn.
- *Defer marketplace/* edits to "next release-shipping feature"* — rejected; leaves the docs in a knowingly-broken state and risks the next release shipping submission text that names nonexistent files.
- *Add an `### Unreleased` CHANGELOG section noting the port* — accepted as a natural part of Phase B (the deletion + port is a notable repo change worth a one-line entry); does NOT count as "rewriting history" because the entry describes the change as a current event.

---

## Summary table

| R# | Status | Phase that consumes the answer |
|---|---|---|
| R1 | Resolved (two-step bootstrap; observation gate at Phase A start) | Phase A |
| R2 | Resolved (expected matrix + Phase A observation gate) | Phase A |
| R3 | Resolved (bash idiom mapping) | Phase B |
| R4 | Resolved (AGENTS.md insertion point + section content) | Phase C |
| R5 | Resolved (two marketplace updates + leave CHANGELOG history) | Phase B (deletion commit), with Unreleased CHANGELOG one-liner |

All Open Research items are answered. Phase 1 (data-model, contracts, quickstart) may proceed.
