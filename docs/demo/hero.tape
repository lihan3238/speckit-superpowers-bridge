# speckit-superpowers-bridge — concise user-flow demo (~18 s)
#
# Renders ./hero.gif via Charmbracelet VHS (https://github.com/charmbracelet/vhs).
# Re-render with: `vhs hero.tape` (run from this directory).
#
# Storyboard:
#   1. install the bridge once in a Spec Kit project
#   2. create design artifacts with Spec Kit commands
#   3. execute tasks through the bridge
#   4. end on a complete handoff

Output hero.gif

Set FontFamily "DejaVu Sans Mono"
Set FontSize 22
Set LetterSpacing 0
Set LineHeight 1.15
Set Width 1200
Set Height 650
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
Type "      printf '# Constitution\n' > .specify/memory/constitution.md"
Enter
Type "      printf '[ok] bridge installed: commands, hooks, peer skills\n[ok] ready for /speckit-superpowers-bridge\n'"
Enter
Type "      ;;"
Enter
Type "    /speckit-specify*)"
Enter
Type "      mkdir -p specs/oauth2"
Enter
Type "      printf '# Feature: OAuth2 sign-in\n' > specs/oauth2/spec.md"
Enter
Type "      printf '[ok] spec.md: user goal, scope, acceptance scenarios\n'"
Enter
Type "      ;;"
Enter
Type "    /speckit-plan\ \&\&\ /speckit-tasks)"
Enter
Type "      printf '# Plan\n' > specs/oauth2/plan.md"
Enter
Type "      printf -- '- [ ] T001 OAuth contract test\n- [ ] T002 OAuth callback\n- [ ] T003 session cookie\n- [ ] T004 happy-path test\n- [ ] T005 error-path test\n' > specs/oauth2/tasks.md"
Enter
Type "      BR=.specify/extensions/speckit-superpowers-bridge/scripts/bash"
Enter
Type "      bash $BR/update-handoff.sh --status executing --feature-directory specs/oauth2 --artifact-owner claude --actor claude >/tmp/bridge-demo.log 2>&1"
Enter
Type "      printf '[ok] plan.md + contracts ready\n[ok] tasks.md: 5 ordered tasks\n[ok] bridge handoff: executing\n'"
Enter
Type "      ;;"
Enter
Type "    /speckit-superpowers-bridge)"
Enter
Type "      printf '%s\n' '-> reading specs/oauth2/tasks.md'"
Enter
Type "      sleep 0.35"
Enter
Type "      printf '[ok] T001 test first\n'"
Enter
Type "      sleep 0.35"
Enter
Type "      printf '[ok] T002-T004 implementation\n'"
Enter
Type "      sleep 0.35"
Enter
Type "      printf '[ok] verification + code review\n'"
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

Type "# install once"
Enter
Sleep 500ms
Type "specify init my-app --integration claude"
Enter
Sleep 1500ms
Type "cd my-app"
Enter
Sleep 500ms
Type "specify extension add speckit-superpowers-bridge --from releases/latest/download/speckit-superpowers-bridge.zip"
Enter
Sleep 2200ms

Type "# every feature"
Enter
Sleep 500ms
Type "/speckit-specify add OAuth2 sign-in"
Enter
Sleep 1400ms
Type "/speckit-plan && /speckit-tasks"
Enter
Sleep 1900ms
Type "/speckit-superpowers-bridge"
Enter
Sleep 3000ms

Type "exit"
Enter
Sleep 900ms
