---
description: "Audit the source repo for stale or mis-placed files before cutting a release"
---

# Bridge Cleanup Audit

Pre-release source-repo cleanup audit. Surfaces stale, abandoned, or mis-placed
files so the published release ZIP stays slim and the source tree stays
grep-able.

## When to use

- Before cutting a release (step 6 of `docs/release-runbook.md`).
- After landing a large feature, to identify scratch files that should have been
  cleaned up.
- Optional on-demand audit at any time.

## Behavior

Runs `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/cleanup-audit.ps1`
which performs 5 checks:

1. **Backup files** — `*.bak`, `*.bak-*`, `*.orig`, `*.tmp` anywhere except `.git/`. P2.
2. **Unreferenced docs** — files under `.specify/extensions/speckit-superpowers-bridge/docs/`
   not referenced from `README.md` or `extension.yml`. P2.
3. **Abandoned scripts** — root-level one-shot scripts matching `bump-*.ps1`,
   `migrate-*.ps1`, `fix-*.ps1`, `patch-*.ps1`. P2.
4. **`.gitignore` gaps** — missing coverage of 5 categories: per-developer
   state, OS junk, backup patterns, editor scratch, build artifacts. P1.
5. **Distribution manifest consistency** — every `includes[].path` in
   `plugin-distribution-manifest.yml` resolves on disk; no path appears in both
   `includes` and `excludes`. P0.

## Execution

```powershell
.\.specify\extensions\speckit-superpowers-bridge\scripts\powershell\cleanup-audit.ps1 -Json -Actor <codex|claude>
```

Pass `-Fix` to delete matching backup files / abandoned scripts. Manifest
inconsistencies are NEVER auto-fixed; they require human review (the script
prints the proposed change and exits non-zero).

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | Clean (or only P2 findings without `-Strict`) |
| `1` | At least one P0 (manifest inconsistency) |
| `2` | At least one P1 (`.gitignore` gap) |
| `3` | At least one P2 finding AND `-Strict` is on |

See `specs/005-marketplace-alignment/contracts/cleanup-audit-contract.md` for
the full contract.
