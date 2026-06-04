# speckit-superpowers-bridge — full user-flow demo (~26 s)
#
# Truth label: illustrative transcript-derived demo. It calls real bridge
# update-handoff.sh for state transitions, but Spec Kit / Superpowers / agent
# output lines are synthesized for a concise README animation.
#
# Renders ./full-cycle.gif via Charmbracelet VHS.
# Re-render with: `vhs full-cycle.tape` (run from this directory).
#
# This is the longer happy-path version of hero.tape. It shows the
# commands a user runs and the high-level artifacts/results they see.

Output full-cycle.gif

Set FontFamily "DejaVu Sans Mono"
Set FontSize 20
Set LetterSpacing 0
Set LineHeight 1.15
Set Width 1240
Set Height 720
Set Theme "GitHub Dark"
Set Framerate 20
Set TypingSpeed 14ms
Set Padding 24

# --- hidden setup: a small fake shell that keeps the visible flow user-facing ---
Hide
Type "export REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
Enter
Type "SANDBOX=$(mktemp -d) && cd $SANDBOX"
Enter
Type "cat > demo-shell <<'EOF'"
Enter
Type "#!/usr/bin/env bash"
Enter
Type "set -euo pipefail"
Enter
Type "clear"
Enter
Type "prompt() { printf '\n$ '; }"
Enter
Type "prompt"
Enter
Type "while IFS= read -r cmd; do"
Enter
Type "  case $cmd in"
Enter
Type "    specify\ init\ my-app\ --integration\ claude)"
Enter
Type "      mkdir -p my-app"
Enter
Type "      printf '[ok] created Spec Kit project: my-app\n[ok] agent integration: Claude Code\n'"
Enter
Type "      ;;"
Enter
Type "    cd\ my-app)"
Enter
Type "      cd my-app"
Enter
Type "      ;;"
Enter
Type "    specify\ extension\ add\ speckit-superpowers-bridge\ --from\ releases/latest/download/speckit-superpowers-bridge.zip)"
Enter
Type "      mkdir -p .specify/extensions/speckit-superpowers-bridge/scripts/bash .specify/memory"
Enter
Type "      cp $REPO/.specify/extensions/speckit-superpowers-bridge/scripts/bash/*.sh .specify/extensions/speckit-superpowers-bridge/scripts/bash/"
Enter
Type "      printf '[ok] bridge installed from latest release\n[ok] commands + hooks registered\n'"
Enter
Type "      ;;"
Enter
Type "    /speckit-constitution)"
Enter
Type "      printf '# Constitution\n' > .specify/memory/constitution.md"
Enter
Type "      printf '[ok] .specify/memory/constitution.md\n'"
Enter
Type "      ;;"
Enter
Type "    /speckit-specify*)"
Enter
Type "      mkdir -p specs/oauth2"
Enter
Type "      printf '# Feature: OAuth2 sign-in\n' > specs/oauth2/spec.md"
Enter
Type "      printf '[ok] specs/oauth2/spec.md\n     goal: GitHub OAuth2 sign-in\n     scope: callback route + session cookie\n'"
Enter
Type "      ;;"
Enter
Type "    /speckit-clarify)"
Enter
Type "      printf '? provider: GitHub\n? session storage: signed cookie\n[ok] clarifications applied to spec.md\n'"
Enter
Type "      ;;"
Enter
Type "    /speckit-plan)"
Enter
Type "      mkdir -p specs/oauth2/contracts"
Enter
Type "      printf '# Plan\n' > specs/oauth2/plan.md"
Enter
Type "      printf 'openapi: 3.1.0\n' > specs/oauth2/contracts/oauth.openapi.yaml"
Enter
Type "      printf '[ok] specs/oauth2/plan.md\n[ok] contracts/oauth.openapi.yaml\n[ok] data model: User, Session\n'"
Enter
Type "      ;;"
Enter
Type "    /speckit-tasks)"
Enter
Type "      printf -- '- [ ] T001 OAuth contract test\n- [ ] T002 OAuth callback\n- [ ] T003 session cookie\n- [ ] T004 happy-path test\n- [ ] T005 error-path test\n' > specs/oauth2/tasks.md"
Enter
Type "      BR=.specify/extensions/speckit-superpowers-bridge/scripts/bash"
Enter
Type "      bash $BR/update-handoff.sh --status executing --feature-directory specs/oauth2 --artifact-owner claude --actor claude >/tmp/bridge-demo.log 2>&1"
Enter
Type "      printf '[ok] specs/oauth2/tasks.md: 5 ordered tasks\n[ok] bridge handoff: executing\n'"
Enter
Type "      ;;"
Enter
Type "    /speckit-superpowers-bridge)"
Enter
Type "      printf '%s\n' '-> Superpowers reads specs/oauth2/tasks.md'"
Enter
Type "      sleep 0.35"
Enter
Type "      printf '[ok] T001 failing contract test created\n'"
Enter
Type "      sleep 0.35"
Enter
Type "      printf '[ok] T002 OAuth callback implemented\n'"
Enter
Type "      sleep 0.35"
Enter
Type "      printf '[ok] T003 session cookie wired\n'"
Enter
Type "      sleep 0.35"
Enter
Type "      printf '[ok] T004-T005 integration tests pass\n'"
Enter
Type "      sleep 0.35"
Enter
Type "      printf '[ok] verification before completion\n[ok] code review requested\n[ok] development branch ready\n'"
Enter
Type "      sed -i 's/- \[ \]/- [x]/' specs/oauth2/tasks.md"
Enter
Type "      BR=.specify/extensions/speckit-superpowers-bridge/scripts/bash"
Enter
Type "      bash $BR/update-handoff.sh --status complete --actor claude >/tmp/bridge-demo.log 2>&1"
Enter
Type "      printf '[ok] bridge handoff: complete\n'"
Enter
Type "      ;;"
Enter
Type "    exit)"
Enter
Type "      break"
Enter
Type "      ;;"
Enter
Type "  esac"
Enter
Type "  prompt"
Enter
Type "done"
Enter
Type "EOF"
Enter
Type "chmod +x demo-shell"
Enter
Type "clear"
Enter
Type "./demo-shell"
Enter
Show

Type "# 1. install the bridge"
Enter
Sleep 500ms
Type "specify init my-app --integration claude"
Enter
Sleep 1400ms
Type "cd my-app"
Enter
Sleep 400ms
Type "specify extension add speckit-superpowers-bridge --from releases/latest/download/speckit-superpowers-bridge.zip"
Enter
Sleep 1900ms

Type "clear"
Enter
Sleep 300ms
Type "# 2. let Spec Kit define the work"
Enter
Sleep 500ms
Type "/speckit-constitution"
Enter
Sleep 1000ms
Type "/speckit-specify add OAuth2 sign-in"
Enter
Sleep 1400ms
Type "/speckit-clarify"
Enter
Sleep 1400ms
Type "/speckit-plan"
Enter
Sleep 1600ms
Type "/speckit-tasks"
Enter
Sleep 1800ms

Type "clear"
Enter
Sleep 300ms
Type "# 3. let the bridge hand tasks to Superpowers"
Enter
Sleep 500ms
Type "/speckit-superpowers-bridge"
Enter
Sleep 4200ms

Type "exit"
Enter
Sleep 900ms
