---
description: "Run the local submission-checklist mirror of the Spec Kit maintainers' upstream catalog verification"
---

# Bridge Submission Checklist

Mirror the upstream Spec Kit maintainers' automated verification locally, so the
upstream catalog PR passes review on the first try.

## When to use

- Before opening or amending the upstream PR that adds this extension to
  `extensions/catalog.community.json`.
- Before cutting a new release (step 4 of `docs/release-runbook.md`).
- As part of CI on the release branch (optional).

## Behavior

Runs `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/submission-checklist.ps1`
which performs 8 checks:

1. `LICENSE` present at repo root and non-empty.
2. `CHANGELOG.md` present at repo root with at least one released-version section.
3. `extension.yml` parses and every required field is present
   (`id`, `name`, `version`, `description`, `author`, `repository`, `license`,
   `requires.speckit_version`).
4. `extension.yml.tags` equals exactly the locked 6-tag set
   (`bridge, superpowers, cross-agent, governance, tdd, workflow`).
5. `extension.yml.description` length is ≤ 200 characters.
6. `marketplace/catalog-entry.json` exists, parses, and contains every required
   field per the catalog entry schema.
7. `marketplace/catalog-entry.json.download_url` resolves with HTTP 200
   (HEAD request, 10-second timeout). Skipped with `-OfflineOnly`.
8. `marketplace/upstream-pr-body.md` contains the AI-assistance disclosure
   paragraph (regex match for "AI" + "coding assistant"/"disclosure" within
   200 characters).

The check is read-only by default. Pass `-LogEvent` to additionally append a
`submission_check` event to `.specify/bridge-events.jsonl`.

## Execution

Run this from the repository root:

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\submission-checklist.ps1 -Json -Actor <codex|claude>
```

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | All checks pass (or only P2/P3 findings without `-Strict`) |
| `1` | At least one P0 finding |
| `2` | At least one P1 finding (no P0) |
| `3` | At least one P2 finding AND `-Strict` is on |

## Output

With `-Json`, emits a single Submission Checklist Report document on stdout.
Without `-Json`, prints a short summary on stdout and per-finding lines on
stderr.

See `specs/005-marketplace-alignment/contracts/submission-checklist-contract.md`
for the full contract.
