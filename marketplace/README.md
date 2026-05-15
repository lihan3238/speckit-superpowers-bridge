# marketplace/

This directory holds the **submission-ready artifacts** for listing this extension in the [Spec Kit community catalog](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json).

Contents:

| File | Purpose |
|---|---|
| `catalog-entry.json` | The JSON object pasted into upstream `extensions/catalog.community.json` by the Spec Kit maintainer. |
| `extensions-readme-row.md` | The Markdown table row pasted into upstream `extensions/README.md` by the maintainer. |
| `upstream-pr-body.md` | The submission body (history note: filename predates the change to issue-based submission; content is still used for the issue body and any future communications). Contains the mandated AI-assistance disclosure paragraph per Spec Kit CONTRIBUTING.md. |

These files are **source-repo only** — they describe the extension to the upstream maintainer, and they are NOT installed into host projects when a user adds this extension.

## Workflow (Spec Kit-aligned)

Per the upstream [EXTENSION-PUBLISHING-GUIDE](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md), community-extension submissions go **through an issue template**, not a fork+PR:

1. Bump `extension.yml.extension.version`; write the `CHANGELOG.md` section.
2. Build the release ZIP locally (see `scripts/release/build-extension-zip.ps1`):
   ```powershell
   pwsh scripts/release/build-extension-zip.ps1 -Version 0.4.0
   ```
   This stages `extension.yml`, `commands/`, `scripts/powershell/`, plus repo-root `README*.md`, `LICENSE`, `CHANGELOG.md`, `.gitignore` into a `speckit-superpowers-bridge-X.Y.Z/` tree and zips it. Same internal layout as `agent-governance` in the canonical catalog.
3. Tag and push:
   ```powershell
   git tag -a v0.4.0 -m "v0.4.0 — …"
   git push origin v0.4.0
   ```
4. Create the GitHub release and attach the ZIP:
   ```powershell
   gh release create v0.4.0 --notes-file <changelog-section>
   gh release upload v0.4.0 dist/speckit-superpowers-bridge-v0.4.0.zip
   ```
   Record the SHA256 from the build script's output (or `Get-FileHash dist/...zip -Algorithm SHA256`) **before any rebuild** — `Compress-Archive` is not byte-deterministic, so each build produces a different SHA256. The hash you record must match the asset GitHub now serves.
5. Update `marketplace/catalog-entry.json` `version` + `download_url` to the new release asset URL.
6. Open or update the catalog submission issue via the **[Extension Submission template](https://github.com/github/spec-kit/issues/new?template=extension_submission.yml)**. Paste the contents of `catalog-entry.json` into the "Proposed Catalog Entry" section, and the contents of `upstream-pr-body.md` into the "Additional Context" section (preserving the AI-disclosure paragraph verbatim).
7. The Spec Kit maintainer reviews and updates `catalog.community.json` directly. **Do NOT open a PR against `catalog.community.json`** — the upstream guide explicitly forbids that.

For an in-flight submission, comment on the existing issue with version updates rather than opening a new one — this preserves the maintainer's queue position.

### Why hand-built ZIP (not auto-archive)?

Some canonical catalog entries (`agent-assign`, `agent-governance`) use the GitHub auto-generated archive at `archive/refs/tags/vX.Y.Z.zip`. Those repos place `extension.yml` at the repo root. **Our repo doesn't**: the bridge content lives under `.specify/extensions/speckit-superpowers-bridge/` because the repo is also a Spec Kit dev environment used to dogfood the bridge on itself. The hand-built ZIP from `scripts/release/build-extension-zip.ps1` produces an `agent-governance`-shaped tree (extension.yml at top, plus commands/, scripts/, LICENSE, README) so the catalog install path works without restructuring the source repo.

When future cross-platform support lands (feature 003 stub: Bash port for Linux/macOS), the build script will gain one line: `Copy-Item scripts/bash` alongside `scripts/powershell`. Same release flow.
