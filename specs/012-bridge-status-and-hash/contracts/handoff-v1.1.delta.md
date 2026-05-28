# Contract: Handoff v1 Schema Delta — `artifacts_sha256`

**Owner**: declared in this delta document; merged into the canonical [specs/006-trim-to-thin-bridge/contracts/handoff.v1.schema.json](../../006-trim-to-thin-bridge/contracts/handoff.v1.schema.json) as a non-breaking additive property.

**Status**: schema_version stays at 1. No new schema_version is introduced. This is a "v1.1 delta" only in documentation — the wire-level schema_version field continues to write `1`.

## What changes

Add the following property to the `properties` object of the v1 schema:

```jsonc
{
  // ... existing v1 properties ...
  "artifacts_sha256": {
    "type": "object",
    "description": "Optional SHA256 snapshots of source-of-truth Markdown artifacts taken at the time of the most recent executing/complete write. Used for drift detection on subsequent executing/complete writes. Present from v0.7.0 onward; pre-0.7.0 handoffs omit this field and readers must tolerate its absence.",
    "additionalProperties": false,
    "properties": {
      "spec.md":  { "type": ["string", "null"], "pattern": "^[0-9a-f]{64}$" },
      "plan.md":  { "type": ["string", "null"], "pattern": "^[0-9a-f]{64}$" },
      "tasks.md": { "type": ["string", "null"], "pattern": "^[0-9a-f]{64}$" }
    }
  }
}
```

Also amend the existing `allOf` block to add a conditional rule for the `executing` and `complete` states:

```jsonc
{
  "if": {
    "properties": { "status": { "enum": ["executing", "complete"] } }
  },
  "then": {
    "required": ["artifacts_sha256"]
  }
}
```

This conditional rule says: when a handoff write produces a document with `status` in `{executing, complete}`, the writer MUST emit `artifacts_sha256`. Readers (including strict validators) MUST tolerate documents written before v0.7.0 that have `status: executing` or `status: complete` but no `artifacts_sha256` — the spec assumption is that the strict-validation rule applies only to *new writes by v0.7.0+ writers*, not to legacy documents at rest.

## What does NOT change

- `schema_version`: stays integer with `minimum: 1, maximum: 3`. No bump.
- `additionalProperties`: stays `true` at the top level.
- `required` (top-level): stays `["schema_version", "updated_at", "feature_directory", "source_of_truth", "executor", "status", "artifact_owner"]`. `artifacts_sha256` is NOT added to the top-level `required` list — it remains optional at the schema level, conditional via the `allOf` rule.
- Existing properties: byte-frozen.

## Compatibility matrix

| Reader version | Document written by v0.4.x | v0.5.x | v0.6.x | v0.7.x |
|---|---|---|---|---|
| v0.4.x (pre-trim) | OK (legacy compat path) | OK | OK | OK (`artifacts_sha256` silently ignored as extra) |
| v0.5.x | OK | OK | OK | OK (silently ignored) |
| v0.6.x | OK | OK | OK | OK (silently ignored) |
| v0.7.x | OK (no drift comparison possible — treated as "no snapshot") | OK | OK | OK (drift comparison enabled) |

Pre-0.7.0 documents that lack `artifacts_sha256` MUST NOT trigger validation errors when read by v0.7.0+ tooling. The conditional `required` rule applies only to *new writes* — strict validators that flag legacy at-rest documents would need a separate "writer-version-aware" mode, which we explicitly do not require.

## Race window note

Per [research D6](../research.md#d6--race-window-analysis-concurrent-writes), the v1 atomic temp-file + `mv` write pattern is sufficient to guarantee that a concurrent `bridge-status` read sees either the pre-write or post-write state, never a partial write. Adding `artifacts_sha256` does not change this guarantee; the field is written as part of the same atomic transaction.

## Migration

NO migration script. NO version pin. Existing v0.5.0/v0.6.0 handoffs at rest continue to work; the next `executing` or `complete` write under v0.7.0+ populates the field. Drift comparison silently skips any handoff that lacks the field on read.

## Smoke-test coverage

The `tests/test-bridge-status.sh` file (FR-012) MUST include at least:

1. **Forward-compat test**: write a handoff under v0.7.0+ → verify `artifacts_sha256` present and well-formed.
2. **Backward-compat fixture test**: load the fixture at `tests/fixtures/pre-070-handoff.json` (a v0.5.0-shaped handoff with `status: executing` and no `artifacts_sha256`) → verify `bridge-status` exits 0, prints no `Drift:` line, no parse error.
3. **Drift detection**: write `executing` → modify `tasks.md` → write `complete` → verify stderr warning, `artifact_drift_detected` event, exit code 0.
4. **No drift**: write `executing` → write `complete` immediately → verify no warning, no event, `Drift: (none)` if bridge-status is invoked between.
5. **Schema validation**: load v1 schema with the delta applied → validate a v0.7.0+ write that includes `artifacts_sha256: null` for tasks.md → confirm it passes (null is permitted per the `["string", "null"]` type).
