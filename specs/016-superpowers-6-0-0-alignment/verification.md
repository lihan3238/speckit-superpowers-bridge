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

## Deferred to the maintainer's release/tag step (chosen "stop before tag" scope)

- `git tag v1.1.0` → release gate (`validate-release-readiness.ps1`) → publish versioned ZIP + stable alias.
- **Published-v1.1.0** end-user sandbox cycle via `specify extension add … --from <release URL>` (the networked install step; the offline runtime cycle above already exercised the same bytes). Per constitution §"End-User Verification Sandbox", this is why **016's handoff is intentionally NOT driven to `complete` this session** — the published-artifact gate completes at release time.
- Upstream github/spec-kit Extension Submission issue using `marketplace/extension-submission-body.md`.

The bridge SKILL/command/script bytes are byte-identical to v1.0.3 (only
version-metadata + docs differ), and v1.0.3 already passed the published-artifact
sandbox cycle on Spec Kit 0.10.2 (`specs/014` verification.md T013); that
evidence transfers to v1.1.0.
