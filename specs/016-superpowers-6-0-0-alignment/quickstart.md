# Quickstart: Validate the Superpowers 6.0.0 alignment (v1.1.0)

**Feature**: `specs/016-superpowers-6-0-0-alignment/`

This guide reproduces the verification for the v1.1.0 compatibility-alignment
release. All commands run from the repo root. No bridge runtime file changes in
this release — these checks confirm the *claims* are accurate and the runtime is
still green under Superpowers 6.0.0.

## 1. Confirm the live upstream is 6.0.0

```bash
jq -r '.plugins["superpowers@claude-plugins-official"][0].version' \
  ~/.claude/plugins/installed_plugins.json     # -> 6.0.0
specify --version                               # -> specify 0.10.2 (unchanged)
```

## 2. Reproduce the transparency audit (research.md R2 + R4)

```bash
SP=~/.claude/plugins/cache/claude-plugins-official/superpowers
diff <(ls -1 $SP/5.1.0/skills) <(ls -1 $SP/6.0.0/skills)        # -> no output (no skill renamed)

grep -rn -i "spec-reviewer\|code-quality-reviewer\|task-reviewer\|review-package\|task-brief" \
  --include="*.md" --include="*.sh" --include="*.ps1" --include="*.json" --include="*.yml" . \
  | grep -v "^./.git/" | grep -v "specs/0"                       # -> no hits (bridge surface clean)
grep -rn "config/superpowers/worktrees" --include="*.md" --include="*.sh" --include="*.ps1" .   # -> no hits
```

## 3. Confirm version + verified-baseline claims (SC-001..SC-003, SC-006, SC-007)

```bash
grep -m1 'version' .specify/extensions/speckit-superpowers-bridge/extension.yml          # 1.1.0
jq -r '.version, .updated_at, .download_url' marketplace/catalog-entry.json              # 1.1.0 / 2026-06-17 / stable alias
jq -r '.superpowers_version, .bridge_version' \
  .specify/extensions/speckit-superpowers-bridge/verified-versions.json                  # 6.0.0 / 1.1.0
grep -c 'verified_6.0.0' README.md README.zh-CN.md                                        # 1 each

# no stale current-version claims (history exempt)
grep -rn "verified_5.1.0\|1\.0\.3" README.md README.zh-CN.md \
  .specify/extensions/speckit-superpowers-bridge/extension.yml \
  .specify/extensions/speckit-superpowers-bridge/verified-versions.json marketplace/      # -> no hits
```

## 4. Green smoke suite under Superpowers 6.0.0 (SC-005)

```bash
bash scripts/release/build-extension-zip.sh --version 1.1.0   # rebuild ZIP the release-package test consumes
bash tests/run-all.sh                                         # -> All 6 bash smoke tests passed.
```

## 5. Release-gate files (the 7-file checklist in AGENTS.md)

Confirm each carries v1.1.0: `extension.yml`, `marketplace/catalog-entry.json`
(+`updated_at`), `CHANGELOG.md` (`## [1.1.0]`), `verified-versions.json`,
`README.md` + `README.zh-CN.md`, `marketplace/extensions-readme-row.md`,
`marketplace/extension-submission-body.md`.

## Deferred to the maintainer's release/tag step (out of this session's scope)

- `git tag v1.1.0` → release gate (`validate-release-readiness.ps1`) → publish ZIP + stable alias.
- Published-artifact end-user sandbox cycle in `../test_specify_superpower` from the v1.1.0 release URL.
- Upstream github/spec-kit Extension Submission issue using `marketplace/extension-submission-body.md`.

The bridge runtime bytes (SKILLs, commands, scripts) are byte-identical to
v1.0.3, which already passed the published-artifact sandbox cycle on Spec Kit
0.10.2 (specs/014 verification.md T013), so that evidence transfers to v1.1.0;
only version-metadata and docs differ.
