# Catalog-entry.json field contract — post-v0.6.0 (decoupled)

Documents the post-v0.6.0 shape of `marketplace/catalog-entry.json`, after the one-shot `download_url` decoupling (per spec FR-007 + research D9).

---

## Full field set (no field added or removed by v0.6.0)

| Field | Type | v0.5.0 value | v0.6.0 value | Per-release maintenance |
|-------|------|--------------|--------------|--------------------------|
| `id` | string | `"speckit-superpowers-bridge"` | unchanged | never |
| `name` | string | `"Superpowers Implementation Bridge"` | unchanged | never |
| `description` | string | `"Thin orchestrator between Spec Kit (design) and Superpowers (implementation). Cross-agent."` | unchanged | rare |
| `author` | string | `"lihan3238"` | unchanged | never |
| `version` | semver string | `"0.5.0"` | `"0.6.0"` | **per release** (audit trail) |
| `license` | SPDX string | `"MIT"` | unchanged | never |
| `repository` | URL | GitHub repo URL | unchanged | never |
| `homepage` | URL | GitHub repo URL | unchanged | never |
| `documentation` | URL | `"<repo>#readme"` | unchanged | never |
| `changelog` | URL | `"<repo>/blob/main/CHANGELOG.md"` | unchanged | never |
| `download_url` | URL | `"<repo>/releases/download/v0.5.0/speckit-superpowers-bridge-v0.5.0.zip"` | **`"<repo>/releases/latest/download/speckit-superpowers-bridge.zip"`** (decoupled) | **never (one-shot freeze)** |
| `requires` | object | `{speckit_version: ">=0.8.10", tools: [...]}` | unchanged | rare |
| `provides` | object | `{commands: 3, hooks: 5}` | unchanged | only when bridge command/hook count actually changes |
| `tags` | string[] | `["bridge", "superpowers", "cross-agent", "tdd", "workflow"]` | unchanged | rare |

---

## Two write-paths per release (post-v0.6.0)

After v0.6.0 ships, every subsequent release touches **exactly one field** in this file:

```diff
- "version": "0.6.0",
+ "version": "0.7.0",
```

That's it. No `download_url` edit. No `requires.speckit_version` edit unless v0.7+ adds a behavioral requirement. The release runbook's "edit catalog download_url" step retires as of v0.6.0 (per research D9).

---

## URL contract for `download_url`

Stable form (post-v0.6.0):

```
https://github.com/lihan3238/speckit-superpowers-bridge/releases/latest/download/speckit-superpowers-bridge.zip
```

This URL resolves via GitHub's `/releases/latest/` redirect to whichever release has the `latest` flag (the tag the GitHub UI shows as "Latest"). For the URL to keep working, every release MUST upload an asset named exactly `speckit-superpowers-bridge.zip` (no version suffix). The release runbook already does this for v0.5.0 (verified empirically — both `speckit-superpowers-bridge-v0.5.0.zip` and `speckit-superpowers-bridge.zip` are attached at 44708 bytes each).

**Runbook invariant** (codified in `docs/release-runbook.md` as part of this feature): every release MUST attach BOTH:

1. `speckit-superpowers-bridge-v<X.Y.Z>.zip` (version-pinned, for users who want determinism)
2. `speckit-superpowers-bridge.zip` (stable-alias, identical byte content)

---

## Failure mode if invariant broken

If a future release forgets to attach the stable-alias asset, the catalog's `download_url` will 404. The mitigation is **runbook discipline + a release-time smoke check**: after publishing the GitHub release, run `curl -fsLI <stable-alias-url>` and expect `200 OK` (302→200 chain is fine). This check belongs in the release runbook's "verify after publish" section; tasks-phase adds it.

---

## Versioning of THIS contract

This contract document itself is versioned by Git history. Future bridge releases that need to change the catalog-entry shape (add a field, deprecate one) MUST update this contract in the same PR. Backwards-compatible additions only; field removals require a major bridge version bump (e.g., v1.0.0) plus an explicit deprecation note in CHANGELOG.
