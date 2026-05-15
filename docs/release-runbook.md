# Release Runbook

> Audience: maintainer cutting a release of **speckit-superpowers-bridge**.
> Each step has a `Verify:` line — do not skip them.

## Pre-flight

- Confirm branch is `main` or a release branch.
- `git status` reports a clean working tree.
- Required scripts present: `submission-checklist.ps1`, `cleanup-audit.ps1`, `parity-check.ps1`, `validation-pass.ps1`, `test-bridge-guard.ps1`, every `tests/test-*.ps1`.

## Step 1 — Bump version

Edit `.specify/extensions/speckit-superpowers-bridge/extension.yml`:

```yaml
extension:
  version: "<N.N.N>"
```

**Verify**: `grep -E '^  version:' .specify/extensions/speckit-superpowers-bridge/extension.yml` reports the new value.

## Step 2 — Update CHANGELOG

In `CHANGELOG.md`:

1. Move the `[Unreleased]` section's content into a new `[N.N.N] - YYYY-MM-DD` section.
2. Add an empty `[Unreleased]` skeleton at the top.
3. Update the `[Unreleased]` and `[N.N.N]` link references at the bottom.

**Verify**: `head -30 CHANGELOG.md` shows the new section with today's date.

## Step 3 — Refresh verified versions

Edit `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`:

- Update `verified_at` to current ISO 8601 UTC timestamp.
- Update `spec_kit_version` / `superpowers_version` if either upstream has shipped a new release since the previous bridge release.

**Verify**: `verified-versions.json` parses; `verified_at` is today.

## Step 4 — Run submission checklist

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\submission-checklist.ps1
```

**Verify**: exit code `0`; stdout reports `Submission-ready.`. Resolve any P0/P1 findings before proceeding.

## Step 5 — Run full test suite

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\test-bridge-guard.ps1
foreach ($t in (Get-ChildItem tests\test-*.ps1)) { & $t.FullName }
```

**Verify**: every test ends `*-tests-ok`; no exit-non-zero in the loop.

## Step 6 — Run parity check + validation pass + cleanup audit

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\parity-check.ps1 -Strict
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\validation-pass.ps1
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\cleanup-audit.ps1
```

**Verify**: all three exit `0`; reports show no P0/P1 findings.

## Step 7 — Commit and tag

```powershell
git add -A
git commit -m "release: v<N.N.N>"
git tag -a v<N.N.N> -m "Release v<N.N.N>"
```

**Verify**: `git log --oneline -1` shows the release commit; `git tag -l v<N.N.N>` returns the tag.

## Step 8 — Push tag

```powershell
git push origin main --tags
```

**Verify**: GitHub Releases page shows the new tag listed. Wait for GitHub to build the release ZIP (a few minutes if a GitHub Actions workflow exists; otherwise the maintainer attaches the ZIP manually).

## Step 9 — Confirm release ZIP is reachable

```powershell
Invoke-WebRequest -Method Head -Uri "https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v<N.N.N>/speckit-superpowers-bridge-v<N.N.N>.zip"
```

**Verify**: returns HTTP `200`.

## Step 10 — Update `marketplace/catalog-entry.json`

If `version` or `download_url` changed since the last release:

1. Edit `marketplace/catalog-entry.json` to point at the new release.
2. Re-run `submission-checklist.ps1` (now without `-OfflineOnly`).

**Verify**: `submission-checklist.ps1` exits `0` with the download_url accessibility check passing.

## Step 11 — Submit upstream PR

1. Fork `github/spec-kit` (or use an existing fork).
2. Branch from `main`:

   ```powershell
   git checkout -b add-speckit-superpowers-bridge-v<N.N.N>
   ```

3. Paste the contents of `marketplace/catalog-entry.json` into the appropriate alphabetical position in `extensions/catalog.community.json`.
4. Paste the row from `marketplace/extensions-readme-row.md` into the community-extensions table in `extensions/README.md`.
5. Open a PR; paste the contents of `marketplace/upstream-pr-body.md` into the PR description. Ensure the AI-assistance disclosure paragraph is visible.

**Verify**: PR shows both file changes diffed cleanly; AI-disclosure paragraph is visible in the PR description.

## Step 12 — Track and respond

- Monitor the PR for maintainer feedback (automated checks land in minutes; manual review may take days to weeks).
- If maintainers request changes:
  1. Apply fixes in this source repo first.
  2. If the change is substantive, cut a patch release (steps 1–10) and update the catalog entry.
  3. Push to the PR branch.

**Verify**: maintainer marks the catalog entry `verified: true` and merges the PR.
