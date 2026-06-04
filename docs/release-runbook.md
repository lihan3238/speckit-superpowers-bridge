# Release Runbook

> Audience: maintainer cutting a release of **speckit-superpowers-bridge**.
> Each step has a `Verify:` line — do not skip them.

## Pre-flight

- Confirm branch is `main` or a release branch.
- `git status` reports no unrelated dirty files that would be included in the release commit.
- Required scripts present: `tests/run-all.sh`, `tests/test-release-package.sh`, `tests/test-release-powershell.ps1`, `scripts/release/validate-release-readiness.ps1`, `scripts/release/test-validate-release-readiness.ps1`, and `scripts/release/build-extension-zip.ps1`.
- Native Windows PowerShell 5.1+ is available for the Windows gate. WSL bash is valid Linux evidence only; it does not satisfy the Windows row.

## Step 1 — Bump version

Edit `.specify/extensions/speckit-superpowers-bridge/extension.yml`:

```yaml
extension:
  version: "<N.N.N>"
```

Edit `marketplace/catalog-entry.json`:

```diff
-  "version": "<previous>",
+  "version": "<N.N.N>",
```

Leave `marketplace/catalog-entry.json.download_url` alone; it permanently points at the GitHub latest-release alias.

**Verify**: `grep -E '^  version:' .specify/extensions/speckit-superpowers-bridge/extension.yml` reports the new value, and `jq -r '.version' marketplace/catalog-entry.json` reports the same value.

## Step 2 — Update CHANGELOG

In `CHANGELOG.md`:

1. Move the `[Unreleased]` section's content into a new `[N.N.N] - YYYY-MM-DD` section.
2. Add an empty `[Unreleased]` skeleton at the top.
3. Update the `[Unreleased]` and `[N.N.N]` link references at the bottom.

**Verify**: `head -30 CHANGELOG.md` shows the new section with today's date.

## Step 3 — Refresh verified versions

Edit `.specify/extensions/speckit-superpowers-bridge/verified-versions.json`:

- Update `verified_at` to current ISO 8601 UTC timestamp.
- Update `spec_kit_version`, `superpowers_version`, `codex_cli_version`, and `claude_code_version` if any upstream tool has shipped a new release since the previous bridge release.
- Keep platform and agent rows honest: use `pending` or `blocked` until the exact gate has run and evidence is recorded.

**Verify**: `verified-versions.json` parses; `verified_at` is today.

## Step 4 — Run release readiness validator

```powershell
.\scripts\release\validate-release-readiness.ps1 -Version <N.N.N>
```

**Verify**: exit code `0`; stdout reports `Release readiness OK for version <N.N.N>.`.

## Step 5 — Run Linux bash release gate

```bash
bash tests/run-all.sh
```

**Verify**: stdout reports `All <N> bash smoke tests passed.`

## Step 6 — Run native Windows PowerShell release gate

Run this from a native Windows PowerShell 5.1+ console, not from WSL bash:

```powershell
.\tests\test-release-powershell.ps1
```

**Verify**: stdout ends `release-powershell-tests-ok`. A `[bridge] WARNING:` line during the synthetic `complete` transition is expected when the fixture still has one unchecked task.

## Step 7 — Run release-tooling self-test and build dry run

```powershell
.\scripts\release\test-validate-release-readiness.ps1
.\scripts\release\build-extension-zip.ps1 -Version <N.N.N>
```

**Verify**: validator self-test ends `validate-release-readiness-tests-ok`; build output reports both `dist/speckit-superpowers-bridge-v<N.N.N>.zip` and `dist/speckit-superpowers-bridge.zip`, plus SHA256.

## Step 8 — Validate the built package

```powershell
.\scripts\release\validate-release-readiness.ps1 -Version <N.N.N> -PackageZip .\dist\speckit-superpowers-bridge-v<N.N.N>.zip
```

```bash
bash tests/test-release-package.sh
```

**Verify**: readiness reports `Release readiness OK for version <N.N.N>.`; package smoke ends `release-package-tests-ok`.

## Step 9 — Verify end-user sandbox

Use the sibling sandbox `..\test_specify_superpower` (Windows) / `../test_specify_superpower` (bash). Install the packaged artifact, not a local development path, and exercise one full bridge cycle per supported platform:

- Linux bash: install from `dist/speckit-superpowers-bridge-v<N.N.N>.zip`, then run guard, handoff, status/readiness, archive, and bash smoke commands.
- Windows PowerShell: install the same ZIP from native Windows PowerShell 5.1+, then run the equivalent PowerShell flavor checks.

**Verify**: the feature verification file records one passing Linux row and one passing Windows row with install source, ZIP SHA256, smoke result, sandbox result, readiness result, and any deviation.

## Step 10 — Verify real agents

Run bounded Codex and Claude Code checks in the sandbox using the prompt templates under the current feature's `agent-prompts/` directory. The prompts must keep the agent inside the sandbox and forbid source-repo writes except for evidence copied back by the maintainer.

**Verify**: the feature verification file records one Codex row and one Claude Code row with exact version, platform, prompt boundary, operations exercised, result, and evidence path. A blocked run must be recorded as blocked; do not advertise it as verified.

## Step 11 — Confirm demo truth labels

If `vhs`, `ttyd`, and `ffmpeg` are available, regenerate demos from a real sandbox run or real transcript. If they are not available, keep transcript evidence and label any existing demo asset as illustrative.

**Verify**: `docs/demo/README.md` and feature verification evidence distinguish real recordings, transcript-derived evidence, and illustrative assets.

## Step 12 — Commit and tag

```powershell
git add -A
git commit -m "release: v<N.N.N>"
git tag -a v<N.N.N> -m "Release v<N.N.N>"
```

**Verify**: `git log --oneline -1` shows the release commit; `git tag -l v<N.N.N>` returns the tag.

## Step 13 — Push tag

```powershell
git push origin main --tags
```

**Verify**: GitHub Releases page shows the new tag listed. Wait for GitHub to build the release ZIP (a few minutes if a GitHub Actions workflow exists; otherwise the maintainer attaches the ZIP manually).

## Step 14 — Confirm release ZIP is reachable

```powershell
Invoke-WebRequest -Method Head -Uri "https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/v<N.N.N>/speckit-superpowers-bridge-v<N.N.N>.zip"
```

**Verify**: returns HTTP `200`.

## Step 15 — Confirm stable-alias ZIP is reachable

**As of v0.6.0, `marketplace/catalog-entry.json.download_url` is decoupled** — it permanently points at the GitHub `/releases/latest/download/speckit-superpowers-bridge.zip` stable-alias and **MUST NOT** be edited per release. Every release tag uploads BOTH the versioned ZIP and the stable-aliased ZIP (verify in Step 9), so the latest-alias URL always resolves to the just-published asset.

**Verify after publish**:

```bash
curl -fsLI https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip | head -3
```

Expect a `302` (GitHub redirect) followed by `200 OK` on the resolved download URL. If you see `404`, the release-tag upload of the stable-aliased asset failed — re-attach it before announcing the release.

> **History**: pre-v0.6.0 releases edited `download_url` to point at the new versioned ZIP every time. v0.6.0 decoupled this (see CHANGELOG `[0.6.0]` `### Changed`), eliminating a recurring per-release edit class and a drift surface. The `version` field stays per-release for audit trail.

## Step 16 — Submit upstream catalog update

Official Spec Kit catalog updates go through the GitHub **Extension Submission** issue template. Do not open a direct pull request that edits `extensions/catalog.community.json`; maintainers use the issue metadata to review and update the community catalog.

1. Open a new issue from `https://github.com/github/spec-kit/issues/new?template=extension_submission.yml`.
2. Use `marketplace/extension-submission-body.md` as the source text.
3. State that this is an update to the existing `speckit-superpowers-bridge` entry.
4. Include the proposed catalog JSON and the AI-assistance disclosure paragraph.

**Verify**: the issue exists, uses the `extension-submission` template/label, references version `v<N.N.N>`, and includes the proposed catalog entry plus testing evidence.

## Step 17 — Track and respond

- Monitor the upstream issue for maintainer feedback. Manual review may take 3-7 business days per the official publishing guide.
- If maintainers request changes:
  1. Apply fixes in this source repo first.
  2. If the change is substantive, cut a patch release (steps 1–10) and update the catalog entry.
  3. Comment on the upstream issue with the updated release URL/evidence.

**Verify**: maintainer updates `extensions/catalog.community.json` / the community extension listing and closes the submission issue.
