#!/usr/bin/env bash
# Re-render the README demo GIFs from their .tape sources.
#
# Requirements: vhs (https://github.com/charmbracelet/vhs) + ttyd + ffmpeg.
# Install on Ubuntu/WSL: `sudo apt install ffmpeg && curl -sL https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd && go install github.com/charmbracelet/vhs@latest`
# Install on macOS:    `brew install vhs`

set -euo pipefail

VHS_BIN="$(command -v vhs || true)"
if [[ -z "$VHS_BIN" && -x "$HOME/go/bin/vhs" ]]; then
    VHS_BIN="$HOME/go/bin/vhs"
fi

if [[ -z "$VHS_BIN" ]]; then
    printf 'vhs is not installed. See https://github.com/charmbracelet/vhs for install instructions.\n' >&2
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
