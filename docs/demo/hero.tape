# speckit-superpowers-bridge — 30-second hero demo
#
# Renders ./hero.gif via Charmbracelet VHS (https://github.com/charmbracelet/vhs).
# Re-render with: `vhs hero.tape` (run from this directory).
#
# Storyboard (5 beats, ~30 s):
#   1. empty sandbox → bridge-status shows "(no handoff)"
#   2. synthesize spec.md/plan.md/tasks.md + flip handoff to executing
#   3. bridge-status now shows "executing" + pending=3 + Next: continue
#   4. guard denies speckit.implement with the real bridge rule
#   5. update-handoff → complete; bridge calls out unchecked tasks honestly

Output hero.gif

Set FontFamily "JetBrains Mono"
Set FontSize 16
Set Width 1400
Set Height 700
Set Theme "Dracula"
Set Framerate 24
Set TypingSpeed 25ms
Set Padding 30

# --- hidden setup: real bridge scripts + helper functions ---
Hide
Type "REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
Enter
Type "SANDBOX=$(mktemp -d) && cd $SANDBOX"
Enter
Type "mkdir -p .specify/extensions/speckit-superpowers-bridge/scripts/bash .specify/memory specs/oauth2"
Enter
Type "cp $REPO/.specify/extensions/speckit-superpowers-bridge/scripts/bash/*.sh .specify/extensions/speckit-superpowers-bridge/scripts/bash/"
Enter
Type "printf '# Constitution\n' > .specify/memory/constitution.md"
Enter
Type "BR=.specify/extensions/speckit-superpowers-bridge/scripts/bash"
Enter
Type "status() { bash $BR/bridge-status.sh --actor claude; }"
Enter
Type "begin_spec_kit() { printf '# OAuth2 sign-in\n' > specs/oauth2/spec.md; printf '# Plan\n' > specs/oauth2/plan.md; printf -- '- [ ] T001 contract test\n- [ ] T002 PKCE handler\n- [ ] T003 cli wiring\n' > specs/oauth2/tasks.md; bash $BR/update-handoff.sh --status executing --feature-directory specs/oauth2 --artifact-owner claude --actor claude; }"
Enter
Type "deny_implement() { bash $BR/guard-command.sh --action speckit.implement --actor claude; }"
Enter
Type "complete_handoff() { bash $BR/update-handoff.sh --status complete --actor claude; }"
Enter
Type "clear"
Enter
Show

# Beat 1 — empty state
Type "# 1. Fresh Spec Kit project -- no handoff yet"
Enter
Sleep 800ms
Type "status"
Enter
Sleep 3500ms

# Beat 2 — design artifacts → handoff fires
Type "# 2. /speckit-specify -> /speckit-plan -> /speckit-tasks (synthesized)"
Enter
Sleep 600ms
Type "begin_spec_kit"
Enter
Sleep 2500ms

# Beat 3 — bridge sees executing
Type "# 3. bridge-status now sees the executing handoff"
Enter
Sleep 500ms
Type "status"
Enter
Sleep 4000ms

# Beat 4 — guard denial
Type "# 4. Try /speckit-implement while bridge is executing -- guard refuses"
Enter
Sleep 500ms
Type "deny_implement"
Enter
Sleep 4000ms

# Beat 5 — complete; bridge calls out unchecked tasks (honesty)
Type "# 5. Mark complete -> bridge flags unchecked tasks (it keeps you honest)"
Enter
Sleep 500ms
Type "complete_handoff && status"
Enter
Sleep 4500ms

# Beat 6 — tagline
Type "# Spec Kit owns WHAT · Superpowers owns HOW · bridge keeps them honest"
Enter
Sleep 3000ms
