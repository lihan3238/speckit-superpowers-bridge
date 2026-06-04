# Contract: Verification Evidence

## Purpose

Define the evidence record required before 1.0.0 can be treated as ready for tagging and publication.

## Location

Primary record:

```text
specs/013-v1-0-release-hardening/verification.md
```

Supporting logs or transcripts may live under a feature-local subdirectory if needed.

## Required Sections

### Artifact

```markdown
## Artifact

- Version: 1.0.0
- ZIP path or URL:
- SHA256:
- Built at:
- Built from commit:
```

### Platform Matrix

```markdown
## Platform Matrix

| Platform | Environment | Script flavor | Install source | Smoke | Sandbox cycle | Readiness | Result | Notes |
|---|---|---|---|---|---|---|---|---|
| Linux bash |  | sh |  |  |  |  |  |  |
| Windows PowerShell |  | ps |  |  |  |  |  |  |
```

Rules:

- Linux bash row must pass.
- Windows PowerShell row must pass.
- WSL bash may appear in the Linux row but not the Windows row.

### Agent Matrix

```markdown
## Agent Matrix

| Agent | Version | Platform | Prompt boundary | Operations exercised | Result | Evidence | Notes |
|---|---|---|---|---|---|---|---|
| Codex |  |  |  |  |  |  |  |
| Claude Code |  |  |  |  |  |  |  |
```

Rules:

- A `pass` result requires exact version and evidence path.
- A `blocked` result requires exact attempted command and failure reason.
- Release notes may claim only passed rows.

### Demo Evidence

```markdown
## Demo Evidence

| Asset | Type | Source run | Truth label | Result | Notes |
|---|---|---|---|---|---|
```

Rules:

- Real GIFs must reference a real source run or transcript.
- If capture tools are unavailable, transcript evidence is acceptable.
- Illustrative assets must be labelled as illustrative.

### Known Blockers and Deferrals

```markdown
## Known Blockers and Deferrals

- None.
```

Rules:

- Mandatory platform/package/workflow failures are blockers, not deferrals.
- Non-mandatory demo polish can be deferred only if transcript evidence exists.

## Completion Rule

The feature cannot transition to complete while any of these are missing:

- Artifact SHA256
- Passing Linux bash row
- Passing Windows PowerShell row
- Codex row
- Claude row
- Release workflow status
- Package install evidence
