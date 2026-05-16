# Contract: `specify init` Bootstrap Behavior

**Feature**: `009-wsl-dev-env-alignment` | **Plan**: [../plan.md](../plan.md) | **Research**: [../research.md R2](../research.md#r2--what-does-specify-init---here---script-flavor-regenerate-on-an-existing-repo-and-what-is-its-blast-radius)

This contract pins what `specify init --here --script <flavor> --force` MUST do and MUST NOT do on this repo. Phase A's first action validates against this contract; any deviation halts Phase A and triggers plan amendment.

---

## Inputs

```bash
specify init --here --script <flavor> --force
```

Where `<flavor>` ∈ {`sh`, `ps`}. The maintainer running the bootstrap for this feature uses `sh`.

## Expected effects (MUST be observed in Phase A)

### Files written or overwritten

| Path | Why |
|---|---|
| `.specify/scripts/<flavor>/check-prerequisites.{sh,ps1}` | Core script needed by every `/speckit-*` slash command |
| `.specify/scripts/<flavor>/common.{sh,ps1}` | Shared helpers |
| `.specify/scripts/<flavor>/create-new-feature.{sh,ps1}` | Used by `speckit-git-feature` hook |
| `.specify/scripts/<flavor>/setup-plan.{sh,ps1}` | Used by `/speckit-plan` |
| `.specify/scripts/<flavor>/setup-tasks.{sh,ps1}` | Used by `/speckit-tasks` |
| `.claude/skills/speckit-analyze/SKILL.md` | Skill file with `.specify/scripts/<flavor>/...` paths embedded |
| `.claude/skills/speckit-checklist/SKILL.md` | Same |
| `.claude/skills/speckit-clarify/SKILL.md` | Same |
| `.claude/skills/speckit-implement/SKILL.md` | Same |
| `.claude/skills/speckit-plan/SKILL.md` | Same |
| `.claude/skills/speckit-tasks/SKILL.md` | Same |
| `.claude/skills/speckit-taskstoissues/SKILL.md` | Same |
| `.agents/skills/speckit-{same 7 names}/SKILL.md` | Codex-side equivalents |

All of the above are under paths that this feature gitignores per `contracts/gitignore-contract.md`. So even though they're written to disk, they are NOT staged for commit.

### Files MAY be touched (acceptable with monitoring)

| Path | Acceptable mutation |
|---|---|
| `.specify/init-options.json` | The `speckit_version` field MAY bump (we have 0.8.11 installed; previous value was 0.8.10). The `script` field MAY be confirmed/written. NO other field MAY change. |
| `.specify/templates/*.md` | If `specify init` overwrites templates, the diff MUST be empty (templates are byte-stable between 0.8.10 and 0.8.11 in our experience). If non-empty, Phase A halts and the diff is recorded in `verification.md` for triage. |
| `.specify/memory/constitution.md` | MUST NOT change. Project owns this. If `init` rewrites it, Phase A halts immediately and reverts via `git checkout`. |

## Forbidden effects (MUST NOT be observed)

`specify init` MUST NOT touch any of the following:

- `.specify/extensions/**` — third-party / project extensions; bridge runtime lives here.
- `.specify/extensions.yml` — project hook registry.
- `.specify/superpowers-handoff.json`, `.specify/bridge-events.jsonl`, `.specify/bridge-snapshots/**` — bridge state.
- `.claude/skills/speckit-superpowers-bridge/**` — project deliverable.
- `.agents/skills/speckit-superpowers-bridge/**` — project deliverable.
- `AGENTS.md`, `CLAUDE.md` — project context files.
- `.gitignore`, `.gitattributes` — project config.
- Anything outside `.specify/`, `.claude/skills/`, `.agents/skills/` (specifically: `tests/`, `marketplace/`, `specs/`, `scripts/`, `CHANGELOG.md`).

If any forbidden effect is observed, Phase A:
1. Halts.
2. Runs `git status` and records output in `verification.md`.
3. Reverts via `git checkout HEAD -- <forbidden-path>` (since the forbidden paths are all tracked).
4. Either (a) extends this contract's "MAY be touched" list if the new mutation is benign and the spec amends accordingly, or (b) treats the deviation as a Spec Kit defect and pins `specify` to the pre-deviation version (currently 0.8.10).

## Pre-call invariants (MUST be true before running `specify init`)

1. `.specify/init-options.json.script == "sh"` (set by hand in the prior commit, per R1's two-step bootstrap).
2. `.gitignore` includes the new install-state entries from `contracts/gitignore-contract.md`, committed.
3. The seven non-bridge `.claude/skills/speckit-*/` and `.agents/skills/speckit-*/` directories AND `.specify/scripts/` have been `git rm -r --cached`'d in a commit immediately preceding the `specify init` run, so the upcoming regenerated content has nowhere to land in the index.

## Post-call invariants (MUST be true after Phase A)

1. `git status` reports a clean working tree (no tracked file modifications).
2. `git status --ignored` lists every path under "Ignored files" that this contract says was written.
3. `ls .specify/scripts/bash/` returns ≥ 5 `.sh` files (the core Spec Kit script set).
4. `cat .claude/skills/speckit-plan/SKILL.md` contains the literal substring `.specify/scripts/bash/setup-plan.sh` (NOT `powershell/setup-plan.ps1`).
5. `bash .specify/scripts/bash/setup-plan.sh --json` succeeds and emits valid JSON when invoked from the repo root with a feature active — proves the bootstrap delivered a usable bash flavor end-to-end.

## Failure handling

A failure of any "MUST be observed" or any post-call invariant is a blocking defect:

- If the failure is in `specify init` itself, Phase A halts. The plan is amended with a documented workaround (e.g., a one-shot script that hand-creates the missing files) and re-attempted.
- If the failure is in our pre-call invariants (e.g., we forgot to gitignore something), the commit set is reverted and the prerequisite is fixed before re-running.

## Contract version

Bound to `specify` CLI version 0.8.11. If `specify` upgrades or downgrades during the feature, this contract is re-validated.
