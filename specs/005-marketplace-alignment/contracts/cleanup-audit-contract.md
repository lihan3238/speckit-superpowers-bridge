# Cleanup Audit Contract

**Feature**: 005-marketplace-alignment
**Script**: `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/cleanup-audit.ps1`

## Purpose

Surface dead / stale / mis-placed files in the source repo before a release, so the published artifact stays slim and the source tree stays grep-able.

## Synopsis

```
cleanup-audit.ps1 [-Json] [-Strict] [-Fix]
```

| Param | Default | Meaning |
|---|---|---|
| `-Json` | off | Emit Cleanup Audit Report on stdout. |
| `-Strict` | off | Treat P2 findings as failure. |
| `-Fix` | off | For each finding, apply the documented `suggested_fix` (delete file / add to .gitignore). DESTRUCTIVE; opt-in only. |

## Checks performed (per research §R3)

| # | Check | Code | Severity |
|---|---|---|---|
| 1 | No `*.bak`, `*.bak-*`, `*.orig`, `*.tmp` anywhere except `.git/` | `backup_file_present` | P2 |
| 2 | Every file under `.specify/extensions/speckit-superpowers-bridge/docs/` linked from `README.md` or `extension.yml` | `unreferenced_doc` | P2 |
| 3 | No abandoned one-shot scripts at repo root (`bump-*.ps1`, `migrate-*.ps1`, etc.) | `abandoned_script` | P2 |
| 4 | `.gitignore` covers all 5 categories: per-developer state, OS junk, backup patterns, editor scratch, build artifacts | `gitignore_gap` | P1 |
| 5 | `plugin-distribution-manifest.yml.includes[]` all exist on disk; `excludes[]` not in `includes[]` | `manifest_path_inconsistency` | P0 |

## Outputs

Same envelope shape as `parity-check.ps1` ParityCheckReport and submission-checklist Report. JSON or human-readable; exit codes 0/1/2/3 per severity.

### Example output (default)

```
Cleanup audit:
  ✅ no backup files
  ⚠️ 2 unreferenced docs (P2): docs/old-architecture.md, docs/draft-faq.md
  ✅ no abandoned scripts
  ✅ .gitignore covers all 5 categories
  ✅ distribution manifest paths consistent
2 P2 finding(s). Exit 0 without -Strict.
```

## Side effects

Read-only when `-Fix` is off. With `-Fix`:
- Delete matching files.
- Append missing entries to `.gitignore` (with comments naming the cleanup-audit run).
- For `manifest_path_inconsistency`: REFUSE to fix automatically (manifest changes require human review). Print the proposed edit; require manual application.

## Performance

Target: under 5 seconds. File-system enumeration only; no network.

## Testing

`tests/test-cleanup-audit.ps1` covers:
- Happy path on this repo at HEAD: 0 P0/P1 findings.
- Synthetic backup file: create `foo.bak` in temp location within repo → expect P2 `backup_file_present`. Delete in `finally`.
- Synthetic unreferenced doc: add `docs/unreferenced-test.md` not linked anywhere → expect P2. Remove in `finally`.
- Synthetic manifest inconsistency: temporarily edit `plugin-distribution-manifest.yml` to include a nonexistent path → expect P0. Restore in `finally`.
- `-Fix` mode: synthesize a backup file, run with `-Fix`; assert it's deleted; assert log line written.
