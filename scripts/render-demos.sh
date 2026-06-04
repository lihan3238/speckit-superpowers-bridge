#!/usr/bin/env bash
# Re-render the README demo GIFs from their .tape sources.
#
# Requirements: vhs (https://github.com/charmbracelet/vhs) + ttyd + ffmpeg.
# Install on Ubuntu/WSL: `sudo apt install ffmpeg && curl -sL https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd && go install github.com/charmbracelet/vhs@latest`
# Install on macOS:    `brew install vhs`

set -euo pipefail

find_tool() {
    local name="$1"
    local fallback="${2:-}"
    local found
    found="$(command -v "$name" || true)"
    if [[ -z "$found" && -n "$fallback" && -x "$fallback" ]]; then
        found="$fallback"
    fi
    printf '%s\n' "$found"
}

VHS_BIN="$(find_tool vhs "$HOME/go/bin/vhs")"
TTYD_BIN="$(find_tool ttyd "$HOME/.local/bin/ttyd")"
FFMPEG_BIN="$(find_tool ffmpeg "")"

missing=()
[[ -n "$VHS_BIN" ]] || missing+=("vhs")
[[ -n "$TTYD_BIN" ]] || missing+=("ttyd")
[[ -n "$FFMPEG_BIN" ]] || missing+=("ffmpeg")

if [[ "${#missing[@]}" -gt 0 ]]; then
    printf 'Cannot render demos; missing required tool(s): %s\n' "${missing[*]}" >&2
    printf 'Install VHS and its runtime dependencies before regenerating GIFs.\n' >&2
    printf 'Do not present old or scripted GIF output as a real sandbox/agent recording; keep docs/demo/README.md truth labels current.\n' >&2
    exit 2
fi

DEMO_DIR="$(cd "$(dirname "$0")/../docs/demo" && pwd)"
cd "$DEMO_DIR"

printf 'Rendering hero.gif ...\n'
"$VHS_BIN" hero.tape

printf 'Rendering full-cycle.gif ...\n'
"$VHS_BIN" full-cycle.tape

printf '\nDone. Outputs:\n'
ls -lh hero.gif full-cycle.gif
