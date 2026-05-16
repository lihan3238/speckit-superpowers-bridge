# marketplace/

This directory holds the **submission-ready artifacts** for listing and updating this extension in the [Spec Kit community catalog](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json).

Contents:

| File | Purpose |
|---|---|
| `catalog-entry.json` | The JSON object proposed for upstream `extensions/catalog.community.json`. |
| `extensions-readme-row.md` | The Markdown table row proposed for upstream `docs/community/extensions.md`. |
| `extension-submission-body.md` | Extension Submission issue body for a new listing or existing-entry update. It leads with the bridge philosophy and contains the mandated AI-assistance disclosure paragraph per Spec Kit CONTRIBUTING.md. |

These files are **source-repo only** - they describe the extension to the upstream maintainer, and they are NOT installed into host projects when a user adds this extension.

## Release workflow (automated via `.github/workflows/release.yml`)

Per the upstream [EXTENSION-PUBLISHING-GUIDE](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md), community-extension submissions and updates go **through an issue template**, not a fork+PR. The release-asset build + publish flow is automated; the cross-repo issue stays manual.

**Manual pre-tag steps (do these all in one commit on `main`):**

1. Bump `.specify/extensions/speckit-superpowers-bridge/extension.yml` -> `extension.version: "X.Y.Z"`.
2. Bump `marketplace/catalog-entry.json` -> `"version": "X.Y.Z"` and `"download_url": "https://github.com/lihan3238/speckit-superpowers-bridge/releases/download/vX.Y.Z/speckit-superpowers-bridge-vX.Y.Z.zip"`.
3. Add a `## [X.Y.Z] - <date>` section to `CHANGELOG.md` (this becomes the GitHub release notes).
4. Commit + push to `main`.
5. Verify locally before tagging:
   ```powershell
   pwsh scripts/release/validate-release-readiness.ps1 -Version X.Y.Z
   ```
   The validator checks version/download/changelog alignment plus script-flavor parity and shell-script LF rules. Exit 0 = ready.

**Tag the release:**

```powershell
git tag -a vX.Y.Z -m "vX.Y.Z - <one-line description>"
git push origin vX.Y.Z
```

**Automated on tag push** (`.github/workflows/release.yml`):

1. Validate release readiness (same 4 checks as the local validator).
2. Run all 4 bridge smoke tests (`tests/test-*.sh`).
3. Run release-tooling self-tests (`scripts/release/test-*.ps1`).
4. Build the ZIP via `scripts/release/build-extension-zip.ps1`.
5. Extract `[X.Y.Z]` section from `CHANGELOG.md` as release notes.
6. `gh release create` with notes, the versioned ZIP, and the stable `speckit-superpowers-bridge.zip` alias attached.
7. Print SHA256, versioned asset URL, and latest-alias URL in the workflow's GitHub Step Summary.

The workflow is sequential - any failure stops the release before the asset is published. Local dry-run is supported: each script can be invoked manually with the same arguments the workflow uses.

**Manual post-release step (cross-repo, intentionally not automated):**

8. Open a catalog-submission issue at github/spec-kit via the **[Extension Submission template](https://github.com/github/spec-kit/issues/new?template=extension_submission.yml)**. If the extension is already listed, state that this is an **existing-entry update** and include the current accepted issue/PR links for traceability.
9. Use `marketplace/extension-submission-body.md` as the issue body, paste `catalog-entry.json` into the "Proposed Catalog Entry" section, and copy the vX.Y.Z ZIP SHA256 from the GitHub release asset into the testing details.
10. The Spec Kit maintainer reviews and updates `catalog.community.json` directly. **Do NOT open a PR against `catalog.community.json`** - the upstream guide explicitly requires issue-based submissions.

## Catalog update policy

**As of 2026-05-16**, the upstream-documented process for already-accepted catalog entries is: file a new "Extension Submission" issue per version update, mentioning that the issue is an update to an existing entry. Upstream automation (`catalog-assign.yml`) auto-assigns the issue to the maintainer `mnriem`; the maintainer reviews and updates `catalog.community.json` directly. No automated PR generation exists upstream as of this date (issue [#2400](https://github.com/github/spec-kit/issues/2400) closed without delivering `catalog-validate.yml` / `catalog-pr.yml`).

**Source**: [`extensions/EXTENSION-PUBLISHING-GUIDE.md` § "Updating an Existing Extension"](https://github.com/github/spec-kit/blob/81e9ecd4d955af21adf97c17646b8d3c9b9b67bb/extensions/EXTENSION-PUBLISHING-GUIDE.md) (commit `81e9ecd` as of 2026-05-16).

**Our policy** (per 008 Clarifications Q5 = Option C; v0.5.0+):

| Bump magnitude | Action |
|---|---|
| Patch (e.g., 0.5.0 → 0.5.1) | **Skip** — rely on the stable-alias URL `releases/latest/download/speckit-superpowers-bridge.zip` (added in v0.4.3). Users get the latest patch transparently; the catalog row stays at the most-recent MINOR/MAJOR. |
| Minor (e.g., 0.5.x → 0.6.0) | **File upstream issue** using the [Extension Submission template](https://github.com/github/spec-kit/issues/new?template=extension_submission.yml). |
| Major (e.g., 0.x → 1.0.0) | **File upstream issue** — major bumps almost always change the catalog-visible surface (new commands, new hooks, deprecations). |

**Rationale**: Balances "strictly follow upstream method" (still issue-based when filed) with "minimize per-release issue overhead". Patches in this project have historically been documentation/marketplace polish or surgical bridge fixes that don't change the catalog-visible metadata; users find them through the stable-alias URL. Minor/major bumps actually warrant the upstream signal because they may add commands or hooks. See [spec.md § Clarifications Q5](../specs/008-bridge-hardening-0-5-0/spec.md) for the decision record.

**How to file an update issue (when applicable)**:

1. Open the [Extension Submission](https://github.com/github/spec-kit/issues/new?template=extension_submission.yml) template.
2. Title format: `[Extension]: Update Superpowers Implementation Bridge to vX.Y.Z`.
3. Body: paste `marketplace/extension-submission-body.md` (already refreshed for the current version, with the workflow-emitted SHA256 from the GH release Step Summary).
4. Reference any open prior catalog issues with `Supersedes #<N>` in the body (e.g., #2581 = initial v0.4.1 acceptance; #2600 = v0.4.3 update pending at time of v0.5.0).
5. **Do NOT open a PR against `extensions/catalog.community.json`** — upstream applies the change on their side after issue review.

**Compatibility baseline** (per 008 Clarifications Q1 / FR-014):

As of v0.5.0, **v0.4.2** is the minimum supported direct-upgrade source. Users on v0.4.0 or v0.4.1 should upgrade through v0.4.2 first OR re-install fresh via the stable-alias URL. The handoff schema is byte-stable since v0.4.2, so v0.4.2 / v0.4.3 users upgrade to v0.5.0 with no migration. The previous "branch = release line" pattern (v0.4.0 → v0.4.3 all tagged on `003-cross-platform-cleanup`) is discontinued — v0.5.0+ releases tag on `main`.

## Why hand-built ZIP (not auto-archive)?

Some canonical catalog entries use the GitHub auto-generated archive at `archive/refs/tags/vX.Y.Z.zip`. Those repos place `extension.yml` at the repo root. **Our repo doesn't**: the bridge content lives under `.specify/extensions/speckit-superpowers-bridge/` because the repo is also a Spec Kit dev environment used to dogfood the bridge on itself. The hand-built ZIP from `scripts/release/build-extension-zip.ps1` produces a standard extension ZIP tree (extension.yml at top, plus commands/, scripts/, LICENSE, README) so the catalog install path works without restructuring the source repo.

## Cross-platform ZIP

The release ZIP carries both runtime flavors: `scripts/powershell/` for Windows and `scripts/bash/` for Linux/macOS. The validator enforces file-count/name parity and `.gitattributes` keeps shell scripts LF-clean on Windows clones.
