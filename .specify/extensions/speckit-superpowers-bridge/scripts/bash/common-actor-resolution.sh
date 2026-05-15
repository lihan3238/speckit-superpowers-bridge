#!/usr/bin/env bash
set -euo pipefail

get_repo_root() {
    local root=""
    if command -v git >/dev/null 2>&1; then
        root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
        if [ -n "$root" ]; then
            printf '%s\n' "$root"
            return 0
        fi
    fi
    pwd
}

resolve_bridge_actor() {
    local argument="${1:-}"
    local actor=""

    if [ -n "${argument//[[:space:]]/}" ]; then
        actor="$(printf '%s' "$argument" | tr '[:upper:]' '[:lower:]')"
    elif [ -n "${SPECKIT_BRIDGE_ACTOR:-}" ]; then
        actor="$(printf '%s' "$SPECKIT_BRIDGE_ACTOR" | tr '[:upper:]' '[:lower:]')"
    else
        actor="unknown"
    fi

    case "$actor" in
        codex|claude|unknown) printf '%s\n' "$actor" ;;
        *) printf '%s\n' "unknown" ;;
    esac
}
