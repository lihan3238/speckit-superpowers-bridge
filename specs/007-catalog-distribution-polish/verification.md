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
