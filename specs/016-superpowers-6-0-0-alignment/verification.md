# Verification: Superpowers 6.0.0 Compatibility Alignment (v1.1.0)

**Feature**: `specs/016-superpowers-6-0-0-alignment/` | **Verifier**: Claude Code (claude-opus-4-8) driven by Lihan | **Date**: 2026-06-17

## Environment

| Tool | Version |
|---|---|
| Superpowers | **6.0.0** (live; `~/.claude/plugins/.../superpowers/6.0.0`, git sha `f2cbfbef`) |
| Spec Kit CLI | 0.10.2 (unchanged this feature) |
| Codex CLI | 0.140.0 (live env) |
| Claude Code | 2.1.178 (live env) |
| Platform | WSL2 Ubuntu bash 5.2, repo on /mnt/c (autocrlf=input) |
| Bridge | 1.1.0 (this release) |

> Agent evidence rows in `verified-versions.json` retain the v1.0.0 Codex
> `0.137.0` / Claude Code `2.1.162` versions because the bridge bytes those rows
> certify are unchanged; the live agent versions above only *drove* the v1.1.0
> audit, they are not a new verified claim.

## Phase 0 — Upstream-impact analysis (T001, research.md)

- Source-diffed the cached Superpowers `5.1.0` and `6.0.0` plugin trees and read
  the 6.0.0 RELEASE-NOTES. Verdict: every breaking/headline change is internal
  to upstream skills and transparent to the thin bridge (research.md R3).
- **R2 — skill-name invariance**: `diff <(ls 5.1.0/skills) <(ls 6.0.0/skills)` →
  no output. No skill added/removed/renamed. The bridge invokes by name only, so
  its invocation contract is intact by construction. **PASS**
- **R4 — surface audit (grep)** on the release commit:
  - `grep -rn -i "spec-reviewer\|code-quality-reviewer\|task-reviewer\|review-package\|task-brief" --include=*.md --include=*.sh --include=*.ps1 --include=*.json --include=*.yml . | grep -v ^./.git/ | grep -v specs/0` → **zero hits** (bridge references none of the renamed reviewer prompts / new helper scripts).
  - `grep -rn "config/superpowers/worktrees" ...` → **zero hits** (bridge never used the removed global worktree dir).
  - **PASS**
- Consumer-contract check: `executing-plans` / `subagent-driven-development`
  6.0.0 still load a plan-as-task-list and only *note* global constraints if
  present; Spec Kit `tasks.md` satisfies the contract unchanged. **PASS**

## Phase 1+2 — Metadata, evidence, public claims (T002–T009)

- `extension.yml`: `extension.version` 1.0.3 → **1.1.0** (no other field changed).
- `marketplace/catalog-entry.json`: `version` → **1.1.0**, `updated_at` → `2026-06-17`; `download_url` UNCHANGED (stable latest-release alias).
- `verified-versions.json`: `superpowers_version` 5.1.0 → **6.0.0**, `bridge_version` → **1.1.0**, `verified_at` → 2026-06-17; Linux-bash note rewritten for the 6.0.0 re-verification; Windows PowerShell + agent rows retained with original dates + "bytes unchanged in v1.1.0" notes.
- `CHANGELOG.md`: `## [1.1.0] - 2026-06-17` added with Changed / Upstream-notes (per-change "bridge surface unaffected" verdicts) / Verified subsections.
- `README.md` + `README.zh-CN.md`: Superpowers badge `verified_5.1.0` → **`verified_6.0.0`**; v1.1.0 summary paragraph added; maintenance section → Superpowers 6.0.0; version-pinned install example → v1.1.0. (Bridge-version badge is a dynamic GitHub release badge — auto-updates, no manual pin.)
- `marketplace/extensions-readme-row.md` + `marketplace/extension-submission-body.md`: refreshed to v1.1.0 (version, baseline = Superpowers 6.0.0, support matrix, Proposed Catalog Entry `version` + `updated_at`).

## Phase 3 — Verify (T010–T013)

### Smoke suite (SC-005) — PASS

- `bash scripts/release/build-extension-zip.sh --version 1.1.0` → `dist/speckit-superpowers-bridge-v1.1.0.zip` (75.5 KB, SHA256 `442ff186faf35e6cba801ad795402bb3b10c32c904b7d1b1ee86ab4e3a394334` at local build; canonical release SHA is the CI-built asset's).
- `bash tests/run-all.sh` → **6/6 PASS** with Superpowers 6.0.0 installed (test-bridge-state-summary, test-bridge-status 26/26, claude-codex-skill-parity, guard-hardcoded-rules, handoff-shape, release-package against the v1.1.0 ZIP).

### End-to-end bridge cycle of the v1.1.0 artifact under Superpowers 6.0.0 — PASS

Ran `../test_specify_superpower/run-bridge-cycle.sh` against the unpacked
**v1.1.0** release ZIP, in a /tmp sandbox, with Superpowers 6.0.0 live:

| Step | Result |
|---|---|
| update-handoff `ready` | PASS — `[bridge state]` printed, Pending tasks: 1 |
| guard `speckit.plan` (no active executing) | PASS — allowed (rc=0) |
| update-handoff `executing` (`--actor codex`, no `--artifact-owner`) | PASS — artifact_owner preserved = `claude` (B1 fix); actor `claude → codex` |
| guard `speckit.implement` while executing | PASS — denied (rc=1) |
| guard `speckit.constitution` while executing | PASS — denied (rc=1) |
| update-handoff `complete` | PASS — drift WARNING emitted for 1 unchecked task (exit 0) |
| auto-archive-handoff | PASS — snapshot written, 8 events in bridge-events.jsonl |
| **Overall** | **`BRIDGE_CYCLE_OK`** |

This exercises the real v1.1.0 bridge runtime end-to-end (guard rules, handoff
schema, `[bridge state]` output, actor preservation, drift warning,
auto-archive) with the new Superpowers major live in the environment.

### Final sweep (SC-006) — PASS

`grep` for stale *current-version* claims (`verified_5.1.0`, current `1.0.3`,
current Superpowers `5.1.0`) across README.md / README.zh-CN.md / extension.yml /
verified-versions.json / marketplace/. Remaining matches are exclusively
(a) version-history lines ("New in v1.0.3 …", the v1.0.3 README summary) and
(b) text *describing* the 5.1.0 → 6.0.0 transition and the byte-identity to
v1.0.3 — no stale current-version claim remains. Positive checks: extension.yml
`1.1.0`, catalog `1.1.0` / `2026-06-17`, verified-versions `6.0.0` / `1.1.0`,
README badges `verified_6.0.0` (1 each).

### Release-gate readiness (SC-007)

All seven AGENTS.md release-checklist files carry v1.1.0; the validator's
version checks (extension.yml, verified-versions `bridge_version`, catalog
`version`, CHANGELOG `## [1.1.0]`, extensions-readme-row needles,
extension-submission-body `### Version` + Proposed Catalog Entry) are all
satisfiable on these bytes. `validate-release-readiness.ps1` runs in CI on tag
push (no `pwsh` in this WSL env) and is part of the deferred release step.

## Release & published-artifact verification (DONE — 2026-06-17)

The "stop before tag" scope was lifted by Lihan; the release flow was executed.

### Tag + release gate — PASS

- Tagged `v1.1.0` on main merge commit `216b711`; pushed.
- Release workflow run `27644362797` (`.github/workflows/release.yml`):
  Linux + Windows gates (`validate-release-readiness.ps1` → `tests/run-all.sh`
  → release self-tests) → **completed success**.
- Release `v1.1.0` published, not draft / not prerelease, with both assets:
  `speckit-superpowers-bridge-v1.1.0.zip` (77,294 B) and the stable alias
  `speckit-superpowers-bridge.zip` (77,294 B).
- Stable alias verified: `releases/latest/download/speckit-superpowers-bridge.zip`
  → 302 → `releases/download/v1.1.0/speckit-superpowers-bridge.zip`.

### End-User Verification Sandbox cycle — PASS (constitution gate)

Sandbox: `../test_specify_superpower/v1-1-0-linux-20260616T200149Z`, fresh
`specify init --here --integration claude --script sh --force` (CLI 0.10.2),
Superpowers 6.0.0 live.

| Step | Result |
|---|---|
| Install from published release URL (`specify extension add speckit-superpowers-bridge --from .../releases/latest/download/...`, trust prompt `echo y`) | PASS — **v1.1.0**, 3 commands / 5 hooks, Enabled |
| `specify extension info` | PASS — Category: process, Effect: read-write (read from installed manifest) |
| Handoff `ready` (feature_directory set) | PASS — Pending tasks: 1 |
| Guard `speckit.plan` @ready | PASS — ALLOW (rc=0) |
| Handoff `ready → executing` | PASS — Actor claude → codex |
| Guard `speckit.implement` @executing | PASS — DENY (rc=1) |
| Guard `speckit.constitution` @executing | PASS — DENY (rc=1) |
| Guard `speckit.specify` @executing | PASS — ALLOW (rc=0) — "allow any other speckit.*" rule |
| Handoff `complete` (+ drift warning for 1 unchecked task) | PASS — exit 0, WARNING emitted |
| Auto-archive | PASS — snapshot written; 14 events in bridge-events.jsonl |

All five hardcoded guard rules + the full handoff lifecycle + `[bridge state]`
output + drift warning + auto-archive were exercised against the **published
v1.1.0 artifact installed from the release URL**, with Superpowers 6.0.0 live.

> Test-harness note: the first cycle attempt resolved the bridge's `git`
> repo-root to the enclosing scratch repo (the sandbox dir was created as a
> subdirectory of an existing git repo); `git init` on the project dir fixed
> root detection and the cycle passed. Not a bridge defect — expected
> git-root behavior. The guard CLI flag is `--action` (an earlier `--command`
> typo returned the script's usage exit code 2).

### Remaining (maintainer-triggered)

- Upstream github/spec-kit Extension Submission issue: **filed as [github/spec-kit#3009](https://github.com/github/spec-kit/issues/3009)** using `marketplace/extension-submission-body.md` (v1.1.0) — same path as v1.0.2 (#2848 → PR #2852) and v1.0.3 (#2945). Upstream maintainers pin the version-specific download URL.

The bridge SKILL/command/script bytes are byte-identical to v1.0.3 (only
version-metadata + docs differ), and v1.0.3 also passed the published-artifact
sandbox cycle on Spec Kit 0.10.2 (`specs/014` verification.md T013).

## Post-release Spec Kit 0.11.1 spot check — PASS (2026-06-18)

This is a maintenance verification for the already-published v1.1.0 bridge
surface, not a bridge version bump.

| Check | Result |
|---|---|
| Upgrade local CLI | PASS — `uv tool install --force specify-cli --from git+https://github.com/github/spec-kit.git@v0.11.1`; `specify --version` → `specify 0.11.1` |
| Upstream release audit | PASS — official Spec Kit release notes v0.10.3, v0.10.4, v0.11.0, and v0.11.1 reviewed; `git diff v0.10.2..v0.11.1` checked against bridge-owned files and runtime assumptions |
| Bridge impact | PASS — workflow step catalog, shell-step `output_format: json`, workflow failed/aborted exit codes, non-ASCII skill frontmatter preservation, installer self-install safety, and Windows Rich Live fixes require no bridge command, hook, script, schema, or manifest change |
| Local bootstrap refresh | PASS — source repo `specify init --here --integration claude --script sh --force` refreshed ignored install-state to 0.11.1; project-specific `plan-template.md`, `tasks-template.md`, and `CLAUDE.md` guard/marker customizations were retained |
| Smoke suite | PASS — `bash tests/run-all.sh` → all 6 bash smoke tests passed under Spec Kit 0.11.1 |
| Scratch extension round-trip | PASS — scratch `specify init --here --integration claude --script sh --force` followed by `specify extension add --dev <tmp>/speckit-superpowers-bridge --force`; `specify extension info speckit-superpowers-bridge` showed v1.1.0, Category: process, Effect: read-write, 3 commands, and 5 hooks |

Conclusion: Spec Kit 0.11.1 is compatible with bridge v1.1.0. The plugin does
not need a version bump, a raised `requires.speckit_version` floor, a new
workflow step, or any guard/handoff protocol change.
