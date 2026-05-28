# Contract: Next-Command Decision Table

**Owner**: this document is the canonical source. Logic is implemented inline in both flavors of `bridge-status.{sh,ps1}` per [research D3](../research.md#d3--decision-table-source-code-vs-data).

**Consumer**: `bridge-status` reads the table on every invocation; the table must be exhaustive (every reachable input tuple maps to exactly one output string).

## Decision rules

The table is evaluated **in row order** — the first matching row wins. This is equivalent to a switch-case chain in scripts. Row order is meaningful; do not reorder.

Inputs are five booleans + one enum derived from on-disk state:

- `H`  = `has_handoff` — `.specify/superpowers-handoff.json` exists and parses
- `C`  = `has_constitution` — `.specify/memory/constitution.md` exists
- `FD` = `has_feature_dir` — `feature_directory` (from handoff or `.specify/feature.json`) resolves to an existing directory
- `S`  = `has_spec` — `<feature_dir>/spec.md` exists
- `P`  = `has_plan` — `<feature_dir>/plan.md` exists
- `T`  = `has_tasks` — `<feature_dir>/tasks.md` exists
- `St` = `handoff_status` ∈ {`ready`, `executing`, `complete`, `blocked`, `null` (no handoff), `corrupted`}

Cell value `*` means "any value matches".

| # | H | C | FD | S | P | T | St | Recommendation |
|---|---|---|---|---|---|---|---|---|
| 1 | * | * | * | * | * | * | `corrupted` | `inspect .specify/superpowers-handoff.json` |
| 2 | * | false | * | * | * | * | * | `/speckit-constitution` |
| 3 | false | true | * | * | * | * | * | `/speckit-specify` |
| 4 | true | true | false | * | * | * | `ready` | `/speckit-specify` |
| 5 | true | true | false | * | * | * | * | `clear handoff or restore feature directory` |
| 6 | true | true | true | false | * | * | * | `/speckit-specify` |
| 7 | true | true | true | true | false | * | * | `/speckit-plan` |
| 8 | true | true | true | true | true | false | * | `/speckit-tasks` |
| 9 | true | true | true | true | true | true | `ready` | `start handoff (update-handoff --status executing)` |
| 10 | true | true | true | true | true | true | `executing` | `continue implementation via speckit-superpowers-bridge SKILL` |
| 11 | true | true | true | true | true | true | `blocked` | `resolve blocked_reason or rerun /speckit-clarify` |
| 12 | true | true | true | true | true | true | `complete` | `/speckit-specify` (start a new feature; prior is terminal-not-active) |

### Rule notes

- **#1** wins over everything else: a corrupted handoff is a terminal user-fixable error; do not try to be smart.
- **#2** (no constitution) takes precedence over handoff state because Constitution VI requires a constitution as the design-time foundation. If the user has somehow gotten to `executing` without a constitution, the recommendation still points back to constitution — but in practice this state is unreachable through the standard flow.
- **#3** vs **#4**: when there's no handoff, recommend a new specify. When there's a `ready` handoff but its feature_directory is empty/missing, ALSO recommend a new specify (#4) — the `ready` state with no feature is the "fresh-after-archive" state per AGENTS.md "Auto-archive transitions".
- **#5**: when there's a non-`ready` handoff (executing/complete/blocked) but `feature_directory` points to a missing path → the user has manually moved or deleted the feature directory. Don't suggest creating a new feature; suggest fixing the dangling reference.
- **#6**: feature directory exists but has no `spec.md` — the directory was created (perhaps by `mkdir`) but `/speckit-specify` was never run inside it. Recommend running it.
- **#7** through **#9**: standard progression — spec → plan → tasks → start handoff.
- **#10**: the common "I'm in the middle of executing" case. The recommendation deliberately names the bridge SKILL rather than `/speckit-superpowers-bridge` — the SKILL identifier is agent-neutral (matches Constitution III).
- **#11**: blocked → `resolve blocked_reason or rerun /speckit-clarify`. The `blocked_reason` field is required when status is `blocked` (per v1 schema), so users should be able to inspect it from the handoff directly.
- **#12**: prior feature is `complete` — start a new one. Per [spec Clarifications Q2](../spec.md#clarifications), do NOT recommend `auto-archive-handoff` (it's idempotent and the prior `complete` row is already terminal-not-active per AGENTS.md).

## Exhaustiveness proof

The input space has |H|×|C|×|FD|×|S|×|P|×|T|×|St| = 2×2×2×2×2×2×6 = 384 combinations. Many are unreachable in practice (e.g., `has_tasks=true` and `has_spec=false` should not occur because `/speckit-tasks` requires a spec). The table above covers the *reachable* subset by ordered rule matching:

- Rule 1 covers the 1×384/6 = 64 combinations where St=`corrupted`.
- Rule 2 covers the remaining 1×2×… = combinations where C=false: half of the 320 non-corrupted rows.
- Rules 3..12 partition the C=true, St≠corrupted subspace.

Verified by the test harness via the **Test Vectors** section below.

## Test vectors

The smoke test `tests/test-bridge-status.sh` (FR-012) MUST exercise the following 14 vectors and assert exact match against the recommendation column. Vectors marked § are the SC-001 / SC-007 critical paths.

| ID | H | C | FD | S | P | T | St | Expected | Note |
|---|---|---|---|---|---|---|---|---|---|
| V1 | false | false | false | false | false | false | null | `/speckit-constitution` | bare repo, no constitution yet |
| V2 § | false | true | false | false | false | false | null | `/speckit-specify` | fresh checkout with constitution |
| V3 | true | true | true | true | false | false | ready | `/speckit-plan` | spec exists, plan missing |
| V4 | true | true | true | true | true | false | ready | `/speckit-tasks` | plan exists, tasks missing |
| V5 § | true | true | true | true | true | true | ready | `start handoff (update-handoff --status executing)` | ready to hand off |
| V6 § | true | true | true | true | true | true | executing | `continue implementation via speckit-superpowers-bridge SKILL` | mid-execution resume |
| V7 § | true | true | true | true | true | true | complete | `/speckit-specify` | prior feature done, start new |
| V8 | true | true | true | true | true | true | blocked | `resolve blocked_reason or rerun /speckit-clarify` | blocked state |
| V9 | true | true | false | false | false | false | ready | `/speckit-specify` | ready but feature_dir missing (post-archive) |
| V10 | true | true | false | false | false | false | executing | `clear handoff or restore feature directory` | dangling reference |
| V11 § | true | true | true | true | true | true | corrupted | `inspect .specify/superpowers-handoff.json` | corrupted handoff edge case |
| V12 | true | true | true | false | false | false | ready | `/speckit-specify` | feature dir created but no spec yet |
| V13 | true | false | true | true | true | true | executing | `/speckit-constitution` | constitution missing trumps execution state |
| V14 | true | true | true | true | true | true | complete | `/speckit-specify` | matches V7 (sanity duplicate) |

Total: 14 vectors covering all 12 rules with at least one example each, including 6 SC-critical paths.
