# Submission Checklist Contract

**Feature**: 005-marketplace-alignment
**Script**: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1`

## Purpose

Mirror the Spec Kit maintainers' upstream verification locally, so the upstream PR is right on the first try (no schema/structural rejection round-trips).

## Synopsis

```
submission-checklist.ps1 [-Json] [-Strict] [-OfflineOnly]
```

| Param | Default | Meaning |
|---|---|---|
| `-Json` | off | Emit Submission Checklist Report on stdout. |
| `-Strict` | off | Treat P2 findings as failure. |
| `-OfflineOnly` | off | Skip the HTTP accessibility check (use in offline environments). The check is then logged as `skipped` not `passed`. |

## Checks performed (per research §R2)

| # | Check | Code | Severity |
|---|---|---|---|
| 1 | `LICENSE` present at repo root, non-empty | `license_missing` | P0 |
| 2 | `CHANGELOG.md` present at repo root with ≥1 released-version section | `changelog_missing` | P0 |
| 3 | `extension.yml` parses + every required field present | `manifest_invalid` | P0 |
| 4 | `extension.yml.tags` equals exactly the locked 6-tag set: `bridge, superpowers, cross-agent, governance, tdd, workflow` | `tags_mismatch` | P1 |
| 5 | `extension.yml.description` length ≤ 200 chars | `description_too_long` | P1 |
| 6 | `marketplace/catalog-entry.json` exists, parses, conforms to `contracts/catalog-entry.schema.json` | `catalog_entry_invalid` | P0 |
| 7 | `marketplace/catalog-entry.json.download_url` resolves with HTTP 200 (HEAD request, 10s timeout) | `download_url_unreachable` | P0 |
| 8 | `marketplace/upstream-pr-body.md` contains the AI-disclosure paragraph (regex: `(AI|artificial intelligence).*coding assistant`) | `ai_disclosure_missing` | P1 |

## Outputs

Same envelope as `parity-check.ps1` ParityCheckReport. JSON or human-readable.

### Example output (default)

```
Submission checklist for v0.2.0:
  ✅ LICENSE present (MIT, 1071 bytes)
  ✅ CHANGELOG.md present (3 released versions)
  ✅ extension.yml schema valid
  ✅ tags match locked set (6/6)
  ✅ description length 187/200 chars
  ✅ marketplace/catalog-entry.json valid
  ✅ download_url HTTP 200 (response in 312ms)
  ✅ AI disclosure present in PR body
Submission-ready. Exit 0.
```

### Example output (failure)

```
Submission checklist for v0.2.0:
  ❌ [P0] license_missing — LICENSE not found at repo root. Fix: create LICENSE with MIT text.
  ❌ [P0] download_url_unreachable — https://github.com/lihan3238/.../v0.2.0.zip returned 404. Fix: ensure release ZIP is published.
  ✅ (6 other checks)
2 P0 finding(s). Exit 1.
```

## Side effects

Optional `bridge_events.jsonl` append: `action: "submission_check"`, `decision: "allow"`/`"deny"`, `reason: <summary>`. Controlled by `-LogEvent` (default off — the script is read-only by default).

## Performance

Target: under 30 seconds. The dominant cost is the HTTP HEAD request (1 round-trip).

## Testing

`tests/test-submission-checklist.ps1` covers:
- Happy path on this repo at the next release tag: 0 findings, exit 0.
- Synthetic missing LICENSE: temporarily rename `LICENSE` → `LICENSE.bak`; run; expect P0; restore in `finally`.
- Synthetic broken catalog entry: temporarily set `version: "not-semver"` in catalog-entry.json; expect P0 `catalog_entry_invalid`; restore.
- Synthetic missing AI disclosure: temporarily delete the paragraph from upstream-pr-body.md; expect P1; restore.
- `-OfflineOnly` mode: assert check 7 reports `skipped`, others run normally.
