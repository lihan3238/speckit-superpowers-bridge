# Verification Records

> Constitution v1.2.0 §"End-User Verification Sandbox" gate. Each release that
> publishes an artifact appends one `## <version>` section here recording the
> sandbox-install verification across required platforms. Schema is pinned by
> [`../003-bridge-cross-platform-scripts/contracts/verification-record.md`](../003-bridge-cross-platform-scripts/contracts/verification-record.md).

## v0.4.3

| Platform | bridge_sha256 | Date (UTC) | Operator | Result | Notes |
|---|---|---|---|---|---|
| windows-powershell | `d3da5b971b39590c66a21b2a76ab5e9c683528b812dd1ab3a71c8b31d959af01` | 2026-05-16 07:14 | codex | PASS | Installed from the stable latest-release alias `releases/latest/download/speckit-superpowers-bridge.zip`; verified installed extension version `0.4.3`, short alias skill, canonical fallback skills, PowerShell handoff, and guard allow/deny decisions. |
| wsl-linux-bash | `d3da5b971b39590c66a21b2a76ab5e9c683528b812dd1ab3a71c8b31d959af01` | 2026-05-16 07:14 | codex | PASS | Installed from the stable latest-release alias in WSL using official Spec Kit `v0.8.10`; verified installed extension version `0.4.3`, Claude skill aliases, bash handoff, and guard allow/deny decisions. |
| macos-bash | -- | -- | -- | PENDING | no host available; deferred per Clarifications Q3. |

## Gate evidence

Computed values for the v0.4.3 cycle's constitution / spec gates, recorded retrospectively per 008 FR-008 (Q3 cycle hardening — the bridge state output added in v0.5.0 will eliminate the need for this kind of retrospective backfill on future cycles).

| Gate | Computed value | Command | Date (UTC) | Operator |
|---|---|---|---|---|
| SC-005 (byte-freeze) | `0 lines diff` | `git diff v0.4.2..v0.4.3 -- .specify/extensions/speckit-superpowers-bridge/scripts/` | 2026-05-16 | claude |
| SC-006 (spec-history) | `96e3dffe323546d0f0121c2a8e8f24718e0765de` | `git ls-tree -r v0.4.3 specs/001-* specs/002-* specs/004-* specs/005-* specs/006- \| sort \| git hash-object --stdin` (equals value at v0.4.1 tag, confirming specs 001/002/004/005/006 are byte-identical across v0.4.1 → v0.4.3 — only specs/003 and specs/007 were touched in this cycle) | 2026-05-16 | claude |

Schema for this subsection is defined in [`../008-bridge-hardening-0-5-0/research.md`](../008-bridge-hardening-0-5-0/research.md) § R8 and [`../008-bridge-hardening-0-5-0/data-model.md`](../008-bridge-hardening-0-5-0/data-model.md) § Gate Evidence Record.
