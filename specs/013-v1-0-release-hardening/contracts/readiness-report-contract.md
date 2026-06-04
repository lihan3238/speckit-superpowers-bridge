# Contract: Readiness Report

## Purpose

Define the user-facing readiness/status surface for 1.0.0. The report helps a user or maintainer understand whether the bridge installation is healthy and what action is recommended next.

## Invocation

The report may be implemented by extending existing bridge status scripts or release readiness scripts. It should not require a new `speckit.*` extension command unless implementation planning later proves the existing surfaces cannot express the result.

Supported script flavors:

- Linux/bash flavor under `.specify/extensions/speckit-superpowers-bridge/scripts/bash/`
- Windows PowerShell flavor under `.specify/extensions/speckit-superpowers-bridge/scripts/powershell/`

## Human Output Requirements

Human-readable output must include at least these categories:

```text
[bridge readiness]
  Script flavor: <sh|ps|unknown>
  Required tools: <ready|warning|failed> (<detail>)
  Namespace: <ready|failed> (<detail>)
  Package files: <ready|failed> (<detail>)
  Bridge state: <ready|warning|failed> (<detail>)
  Agents: <ready|warning|not checked|failed> (<detail>)
  Next: <recommended action>
```

The exact heading may differ if the report is folded into `[bridge state]`, but the categories must remain visible.

## Machine Output Requirements

When a JSON mode exists, it must return a single JSON object:

```json
{
  "script_flavor": "sh",
  "required_tools": {
    "status": "ready",
    "items": [
      { "name": "jq", "status": "ready", "version": "1.6" }
    ]
  },
  "namespace": {
    "status": "ready",
    "extension_id": "speckit-superpowers-bridge",
    "command_prefix": "speckit.speckit-superpowers-bridge."
  },
  "package_files": {
    "status": "ready",
    "missing": []
  },
  "bridge_state": {
    "status": "ready",
    "feature_directory": "specs/013-v1-0-release-hardening",
    "next": "/speckit-tasks"
  },
  "agents": {
    "status": "not checked",
    "items": []
  },
  "overall_status": "ready",
  "next": "/speckit-tasks"
}
```

## Status Values

- `ready`: All required checks passed.
- `warning`: Non-blocking issue or optional tool missing.
- `failed`: A release or install requirement failed.
- `not checked`: Category intentionally skipped.

## Read-Only Requirement

Readiness checks must not:

- write `superpowers-handoff.json`
- append `bridge-events.jsonl`
- mutate user source files
- generate or delete release artifacts
- run implementation tasks
- create a new lifecycle state file

## Failure Behavior

For command-line script usage:

- Exit `0` when overall status is `ready` or `warning`.
- Exit `1` when a required readiness category is `failed`.
- Exit `2` for usage errors or missing repository context.

Failures must name the failing category and item.
