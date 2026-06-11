# Verification: Spec Kit 0.10.x Compatibility Alignment (v1.0.3)

**Feature**: `specs/014-speckit-0-10-x-alignment/` | **Verifier**: Claude Code (claude-fable-5) driven by Lihan | **Dates**: 2026-06-12

## Environment

| Tool | Version |
|---|---|
| Spec Kit CLI | 0.10.2 (uv tool, git tag v0.10.2) |
| Superpowers | 5.1.0 |
| Platform | WSL2 Ubuntu bash 5.2, repo on /mnt/c (autocrlf=input) |
| Bridge | 1.0.3 (this release) |

## US1 — Docs alignment (T002–T004)

- AGENTS.md supported-environments table updated: CLI floor "0.10.1+ (verified 0.10.2)", bootstrap sequence extended with `specify extension add git`; migration-notes paragraph added covering git-extension opt-in, removed `--ai*`/`--no-git` flags, and `branch_numbering`→`feature_numbering`.
- quickstart.md §1 grep on the release commit:
  - `grep -n "0\.9\.1+\|verified_0\.9\.3\|--ai-skills\|--ai-commands-dir\|--no-git" AGENTS.md README.md README.zh-CN.md`
  - Remaining matches are only the intentional mentions *inside* the new AGENTS.md migration-notes paragraph (documenting that the flags were removed) — no stale floor or live flag usage remains. CHANGELOG/specs history exempt per SC-005. **PASS**

## US2 — Metadata + evidence (T005–T009)

- `extension.yml`: added `category: process`, `effect: read-write`; version → 1.0.3.
- `marketplace/catalog-entry.json`: added the same two fields; version → 1.0.3; `download_url` untouched (stable latest-release alias); `updated_at` → 2026-06-12.
- `verified-versions.json`: Linux bash row re-verified on Spec Kit 0.10.2 (2026-06-12); Windows PowerShell row retained from v1.0.0 with original date (`ps` flavor byte-identical this release); agent rows retained dated.
- README EN/zh badges → `verified_0.10.2`; maintenance sections name v1.0.3; version-pinned install examples → v1.0.3.
- **T009 manifest round-trip (PASS, 2026-06-12)**: scratch project via `specify init --here --integration claude --script sh --force` (CLI 0.10.2) in `/tmp`, then `specify extension add --dev <tmp-copy>/speckit-superpowers-bridge` (copy taken *outside* the repo target dir per AGENTS.md safety note). `specify extension info speckit-superpowers-bridge` printed:
  ```
  Category: process
  Effect: read-write
  ```
  Validator accepted the manifest with the new fields (pre-version-bump copy at v1.0.2; fields, not version, were under test).
- Backward-compat check: 0.8.10 `ExtensionManifest._validate()` source reviewed — required-field/shape checks only, unknown `extension:` keys ignored. **PASS**

## Release gates (T010–T011)

- `bash scripts/release/build-extension-zip.sh --version 1.0.3` → `dist/speckit-superpowers-bridge-v1.0.3.zip` (73.2 KB, SHA256 `a1ae35620aeb36aca36fa43860cd8dd4fbd167c5c44028c2b2d2e7c7a1927510` at local build; the canonical release SHA is the CI-built asset's).
- `bash tests/test-release-package.sh` against the v1.0.3 ZIP: **PASS**
- `bash tests/run-all.sh`: **6/6 PASS** (test-bridge-state-summary 17, test-bridge-status 26/26, claude-codex-skill-parity, guard-hardcoded-rules, handoff-shape, release-package)
- `validate-release-readiness.ps1` (+ `-PackageZip`) runs in CI on tag push (pwsh unavailable in this WSL env); gate enforced by `.github/workflows/release.yml` before asset upload.

## US3 — Publication + end-user sandbox (T012–T013)

### T012 — Publication (PASS, 2026-06-12)

- PR #6 (014 branch → main) merged; tag `v1.0.3` initially on merge `a41e01f`.
- **Release-gate failure caught by CI** (first tag run): `extensions-readme-row.md` and `extension-submission-body.md` still carried v1.0.2 content, and `validate-release-readiness.ps1` pinned the proposed-catalog `updated_at` to the literal v1.0.2 date. Fixed in PR #7 (marketplace material refreshed to v1.0.3 incl. `category`/`effect` in the proposed catalog entry; validator relaxed to accept any ISO-8601 `updated_at`, `created_at` stays pinned). Tag re-pointed to merge `6e320a2`, force-pushed; release workflow **completed success**.
- Release published with both assets: `speckit-superpowers-bridge-v1.0.3.zip` + stable alias `speckit-superpowers-bridge.zip` (74,910 bytes each).
- Stable alias verified: `releases/latest/download/speckit-superpowers-bridge.zip` → 302 → `v1.0.3` asset.
- Published asset SHA256: `a1ae35620aeb36aca36fa43860cd8dd4fbd167c5c44028c2b2d2e7c7a1927510` — **identical to the local pre-publication build** (deterministic packaging confirmed; marketplace/ files are not part of the ZIP).

### T013 — End-user sandbox cycle (PASS, 2026-06-12)

Sandbox: `../test_specify_superpower/v1-0-3-linux-20260611T194136Z`, Spec Kit CLI 0.10.2, fresh `specify init --here --integration claude --script sh --force`.

| Step | Result |
|---|---|
| Install from published release URL (`specify extension add speckit-superpowers-bridge --from .../releases/latest/download/...`) | PASS — v1.0.3, 3 commands / 5 hooks, Enabled. Note: 0.10.2 requires the `--from` flag form; a bare URL positional arg is treated as a catalog id. Trust prompt confirmed interactively. |
| `specify extension info` | Category: process, Effect: read-write displayed (read from installed manifest) |
| `bridge-status.sh --readiness` | ready on tools/namespace/package/agents; expected "no handoff file" warning pre-cycle; Next: /speckit-specify |
| Guard allow (`speckit.plan`, no active handoff) | PASS — allowed |
| Handoff `ready` → `executing` | PASS — incl. correct `blocked` auto-transition when spec.md/plan.md were missing, then `executing` once artifacts existed (artifact-presence validation works) |
| Guard deny (`speckit.implement` while `executing`) | PASS — "blocked while superpowers handoff is executing" |
| `bridge-status.sh` drift detection | PASS — flagged tasks.md sha256 drift after task checked off |
| Handoff `complete` (+ drift warning) → `auto-archive` | PASS — snapshot created, status back to `ready`, `feature_directory` cleared |
| Event log | 11 events appended to `.specify/bridge-events.jsonl` |

One non-blocking observation: `specify extension info` header shows "(v1.0.2)" from the community-catalog metadata (upstream catalog not yet bumped) while the installed extension itself is v1.0.3 — exactly what the upstream catalog-update submission resolves.

## T014 — Final sweep

- quickstart.md §1 grep clean on release commit (intentional migration-notes mentions only); §2 fields verified in both manifest and catalog entry; §3 evidence rows present; smoke suite 6/6 on the release commit (CI: release workflow success on `6e320a2`).
- Upstream catalog update: **submitted** as Extension Submission issue [github/spec-kit#2945](https://github.com/github/spec-kit/issues/2945) using `marketplace/extension-submission-body.md` (v1.0.3), per the official template flow (no direct catalog PR) — same path as the merged v1.0.2 update (#2848 → PR #2852).
- Handoff transitioned to `complete` after this evidence was recorded.
