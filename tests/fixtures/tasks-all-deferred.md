# Sample tasks.md fixture: 5 pending tasks all under Deferred sections

This fixture tests the false-positive prevention for SC-002. When all unchecked
task-ID lines live under a deferred-exemption section header, the helper MUST
report `Pending tasks: 0` and the FR-003 WARNING line MUST NOT fire on a
complete transition.

## Done

- [x] T001 Done
- [x] T002 Done

## Deferred (no host available yet)

- [ ] T100 Pending but deferred
- [ ] T101 Pending but deferred

## Optional

- [ ] T200 Pending but optional
- [ ] T201 Pending but optional

## Out of Scope

- [ ] T300 Pending but out of scope
