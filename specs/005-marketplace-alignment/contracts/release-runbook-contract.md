# Release Runbook Contract

**Feature**: 005-marketplace-alignment
**Document**: `docs/release-runbook.md` (top-level repo docs)

## Purpose

The ordered procedure a maintainer follows to cut a new release and submit (or update) the upstream catalog entry. This is a markdown document, not a script — but it has an enforceable contract:

- Steps are numbered and idempotent.
- Each step has an explicit verification (`assert` line).
- Failure of any verification stops the release.
- The submission-checklist script (above) is invoked at step 4 and must exit 0.

## Required structure of `docs/release-runbook.md`

```markdown
# Release Runbook

> Audience: maintainer cutting a release.

## Pre-flight
- Confirm branch is `main` or release branch.
- `git status` is clean.

## Step 1 — Bump version
- Edit `extension.yml.extension.version` (semver bump).
- Verify: `grep "^  version:" .specify/extensions/speckit-superpowers-bridge/extension.yml` shows the new value.

## Step 2 — Update CHANGELOG
- Move `[Unreleased]` content into `[N.N.N] — YYYY-MM-DD`.
- Add an empty `[Unreleased]` skeleton.
- Verify: `head -50 CHANGELOG.md` shows the new section.

## Step 3 — Refresh verified versions
- Update `verified-versions.json.verified_at` to current ISO timestamp.
- Update `spec_kit_version` if a Spec Kit upgrade occurred since the last release.

## Step 4 — Run submission checklist
- `powershell.exe -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1`
- Verify: exit 0; output `Submission-ready`.

## Step 5 — Run full test suite
- `powershell.exe -File .specify/extensions/speckit-superpowers-bridge/scripts/powershell/test-bridge-guard.ps1`
- For each file in `tests/test-*.ps1`: run; assert `*-tests-ok` on stdout.

## Step 6 — Run parity + validation
- `parity-check.ps1` — exit 0.
- `validation-pass.ps1` — exit 0.

## Step 7 — Commit + tag
- `git commit -m "release: v<N.N.N>"`
- `git tag -a v<N.N.N> -m "Release v<N.N.N>"`

## Step 8 — Push tag
- `git push origin main --tags`
- Verify: GitHub Releases page shows the new tag.

## Step 9 — Build release ZIP
- GitHub Actions (or manual `git archive`) builds the ZIP at `releases/download/v<N.N.N>/speckit-superpowers-bridge-v<N.N.N>.zip`.
- Verify: HTTP HEAD the URL returns 200.

## Step 10 — Update marketplace/catalog-entry.json
- Bump `version` and `download_url` to match the new release.
- Re-run `submission-checklist.ps1` — exit 0.

## Step 11 — Submit upstream PR
- Fork `github/spec-kit` (or use existing fork).
- Branch from `main`: `git checkout -b add-speckit-superpowers-bridge-v<N.N.N>`
- Paste `marketplace/catalog-entry.json` into `extensions/catalog.community.json` (alphabetical by id).
- Paste `marketplace/extensions-readme-row.md` into `extensions/README.md`.
- Open PR; paste `marketplace/upstream-pr-body.md` into description; ensure AI-disclosure paragraph is present.
- Submit.

## Step 12 — Track + respond
- Monitor the PR for maintainer feedback.
- If asked for changes, apply in the source repo first, re-cut a release if needed.
```

## Validation

The runbook is informational, but `tests/test-release-runbook-shape.ps1` (optional polish) asserts:
- File exists at `docs/release-runbook.md`.
- Has at least 11 numbered steps.
- Each step contains a `Verify:` line.
- The "Step 4" line invokes `submission-checklist.ps1`.

## Versioning of the runbook

The runbook itself is versioned via git. If upstream Spec Kit changes the submission process, the runbook is amended; the change appears in CHANGELOG under "Changed".
