# Tasks: Fire speckit.implement before/after hooks from the bridge

**Branch**: `017-fire-implement-hooks`

**Tests**: Required per spec FR-009 — the full bash smoke suite (now 7 tests)
must stay green at every commit; the new `test-implement-hooks-dispatch.sh`
asserts the dispatch contract. The published-artifact sandbox cycle is deferred
to the maintainer's release/tag step.

- [x] T001 [US1] Add the `before_implement` and `after_implement` extension-hook dispatch sections to `commands/speckit.speckit-superpowers-bridge.execute.md`, mirroring Spec Kit's own `implement` command: read `.specify/extensions.yml`, filter `enabled: false` and non-empty `condition`, fire each remaining hook via its command rendered per agent (`speckit.git.commit` → `$speckit-git-commit` / `/speckit-git-commit`), mandatory hooks execute-and-wait, optional hooks prompt first.
- [x] T002 [US2] Encode the skip-own-guard rule in `execute.md`: skip any hook whose `extension` is `speckit-superpowers-bridge` so the bridge never fires its own `before_implement` guard.
- [x] T003 [US1][US2] Add the same hook-dispatch contract and the two new lifecycle steps to `.agents/skills/speckit-superpowers-bridge/SKILL.md` (fire `before_implement` before the `executing` transition, `after_implement` after `complete`), renumbering the orchestration list.
- [x] T004 [US1][US2] Mirror the identical body change in `.claude/skills/speckit-superpowers-bridge/SKILL.md`.
- [x] T005 [US3] Add `tests/test-implement-hooks-dispatch.sh` asserting the dispatch contract (before/after references, skip-own-guard rule, ordering) exists in `execute.md` and both SKILL peers.
- [x] T006 [US1] Bump `.specify/extensions/speckit-superpowers-bridge/extension.yml` `extension.version` → `1.2.0`.
- [x] T007 [US1] Bump `marketplace/catalog-entry.json` `version` → `1.2.0` and refresh `updated_at`.
- [x] T008 [US1] Add a `## [1.2.0]` section to `CHANGELOG.md` describing the hook-dispatch behavior, the skip-own-guard rule, and the MINOR bump.
- [x] T009 [US1] Refresh `verified-versions.json` (`bridge_version` 1.2.0, `verified_at` 2026-08-17, Linux-bash evidence row + top-level notes for the dispatch feature and 7-test suite).
- [x] T010 [US1] Update `README.md` and `README.zh-CN.md` (v1.2.0 description, version-pinned install example, maintenance version, smoke-test coverage note).
- [x] T011 [US1] Update `marketplace/extensions-readme-row.md` and `marketplace/extension-submission-body.md` (version, baseline, Key Features, Support Matrix, Release Validation Summary, Proposed Catalog Entry with `updated_at`).
- [x] T012 [US1] Run `bash tests/run-all.sh` → MUST be 7/7 green; record evidence in `verification.md`.
