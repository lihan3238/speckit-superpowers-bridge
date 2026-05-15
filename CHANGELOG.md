# Changelog

## v0.1.1 - 2026-05-15

- Prepared the extension for Spec Kit Marketplace submission.
- Raised the verified baseline to Spec Kit `0.8.10` and Superpowers `5.1.0`.
- Switched bridge extension commands to the official namespace `speckit.speckit-superpowers-bridge.*`.
- Added the `execute` command as the marketplace-facing entry point for running Spec Kit `tasks.md` through Superpowers.
- Updated README documentation to emphasize the lightweight non-overlap protocol: Spec Kit remains the source of truth while Superpowers handles implementation discipline.
- Added install compatibility coverage for Spec Kit extension manifest validation.

## v0.1.0 - 2026-05-15

- Initial bridge protocol with handoff state, guard rules, audit logging, rollback snapshots, Codex and Claude Code bridge skills, and local validation scripts.
