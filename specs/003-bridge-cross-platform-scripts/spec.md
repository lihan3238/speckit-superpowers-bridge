# Feature Specification: Bridge Cross-Platform Scripts (Bash port)

**Feature Branch**: `003-bridge-cross-platform-scripts` (not yet created)
**Created**: 2026-05-15
**Status**: STUB — receiving deferred CG-005 from feature 002-complete-bridge-protocol
**Input**: Carried forward from `specs/002-complete-bridge-protocol/compat-gaps.md` CG-005.

## Why this stub exists

Feature 002 closed CG-001 through CG-004 and CG-006. CG-005 (Bash port of the PowerShell bridge scripts) was explicitly DEFERRED so feature 002 could ship lightweight. This stub is the named follow-up feature the SC-007 ship gate requires.

## Scope (proposed; finalize via `/speckit-specify` when this feature starts)

- Bash equivalents of the PowerShell bridge scripts (`guard-command.sh`, `update-handoff.sh`, `restore-snapshot.sh`, `auto-archive-handoff.sh`, `parity-check.sh`).
- Equivalent bash variants of the git extension scripts (`create-new-feature.sh`, `auto-commit.sh`, `initialize-repo.sh`).
- A small dispatcher that picks the right script flavour based on platform (or just leans on Spec Kit's existing `script: ps|sh` config).
- Cross-platform smoke tests under `tests/` that run on Linux/macOS shells.

## Out of scope (initially)

- Re-architecting the bridge protocol — the data model is unchanged.
- Module-level distribution. This stays a repo-local protocol.

## Acceptance signal

Running every step in `specs/002-complete-bridge-protocol/quickstart.md` end-to-end on a Linux/macOS shell, with zero PowerShell invocations.

## Pointer to the gap that drove this stub

`specs/002-complete-bridge-protocol/compat-gaps.md` — row `CG-005`.
