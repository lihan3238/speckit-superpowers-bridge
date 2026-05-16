# Sample tasks.md fixture: 3 pending (outside deferred) + 2 done + 2 deferred

This fixture exercises FR-001 / FR-005 counting rules. The bridge state helper
MUST report `Pending tasks: 3` (the three lines under the active phase that are
not yet checked). The two lines under `## Deferred (later cycle)` are excluded
per FR-005 + Clarifications Q6.

## Phase 1: Active

- [x] T001 Done already
- [ ] T002 Pending
- [ ] T003 Pending
- [ ] T004 Pending
- [x] T005 Done already

## Deferred (later cycle)

- [ ] T100 Deferred per FR-005 (excluded from pending count)
- [ ] T101 Deferred per FR-005 (excluded from pending count)
