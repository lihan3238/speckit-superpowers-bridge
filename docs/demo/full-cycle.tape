# speckit-superpowers-bridge — full-cycle demo (~64 s)
#
# Renders ./full-cycle.gif via Charmbracelet VHS.
# Re-render with: `vhs full-cycle.tape` (run from this directory).
#
# Same state-machine arc as hero.tape, plus the design phase and a
# montage of the per-task TDD loop. /speckit-* outputs are synthesized
# via printf; bridge-status / update-handoff / guard-command are the
# repo's real scripts copied into a scratch sandbox.

Output full-cycle.gif

Set FontFamily "DejaVu Sans Mono"
Set FontSize 20
Set LetterSpacing 0
Set LineHeight 1.15
Set Width 1240
Set Height 720
Set Theme "GitHub Dark"
Set Framerate 20
Set TypingSpeed 16ms
Set Padding 24

# --- hidden setup ---
Hide
Type "REPO=$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
Enter
Type "SANDBOX=$(mktemp -d)"
Enter
Type "cd $SANDBOX"
Enter
Type "mkdir -p .specify/extensions/speckit-superpowers-bridge/scripts/bash .specify/memory"
Enter
Type "cp $REPO/.specify/extensions/speckit-superpowers-bridge/scripts/bash/*.sh .specify/extensions/speckit-superpowers-bridge/scripts/bash/"
Enter
Type "printf '# Constitution\n' > .specify/memory/constitution.md"
Enter
Type "BR=.specify/extensions/speckit-superpowers-bridge/scripts/bash"
Enter
Type "status() { bash $BR/bridge-status.sh --actor claude; }"
Enter
Type "write_spec() { mkdir -p specs/oauth2; printf '# Feature: OAuth2 sign-in\n\n## Why\nUsers want one-click GitHub login.\n\n## Scope\n- /auth/oauth/callback\n- session cookie\n' > specs/oauth2/spec.md; head -6 specs/oauth2/spec.md; }"
Enter
Type "write_plan() { printf '# Plan\n\n- contracts/oauth.openapi.yaml\n- data-model: User, Session\n- research: PKCE vs implicit\n' > specs/oauth2/plan.md; mkdir -p specs/oauth2/contracts; touch specs/oauth2/contracts/oauth.openapi.yaml; head -4 specs/oauth2/plan.md; }"
Enter
Type "write_tasks() { printf -- '- [ ] T001 contract test for /auth/oauth/callback\n- [ ] T002 PKCE handler\n- [ ] T003 session cookie middleware\n- [ ] T004 integration test happy path\n- [ ] T005 error path tests\n' > specs/oauth2/tasks.md; cat specs/oauth2/tasks.md; }"
Enter
Type "handoff_exec() { bash $BR/update-handoff.sh --status executing --feature-directory specs/oauth2 --artifact-owner claude --actor claude; }"
Enter
Type "guard_speckit_implement() { bash $BR/guard-command.sh --action speckit.implement --actor claude; }"
Enter
Type "guard_writing_plans() { bash $BR/guard-command.sh --action superpowers:writing-plans --actor claude; }"
Enter
Type "finish_cycle() { bash $BR/update-handoff.sh --status complete --actor claude; bash $BR/bridge-status.sh --actor claude; }"
Enter
Type "run_tdd_montage() { for t in T001 T002 T003 T004 T005; do printf '  superpowers:test-driven-development  %s  OK\n' $t; sleep 0.5; done; }"
Enter
Type "clear"
Enter
Show

# --- Phase 1: Spec Kit owns design ---
Type "# Phase 1 -- Spec Kit owns WHAT"
Enter
Sleep 800ms

Type "status"
Enter
Sleep 3000ms

Type "# /speckit-specify 'add OAuth2 sign-in'"
Enter
Sleep 700ms
Type "write_spec"
Enter
Sleep 2200ms

Type "# /speckit-clarify  (bridge would ask 2-5 Qs; skipped for brevity)"
Enter
Sleep 1500ms

Type "# /speckit-plan"
Enter
Sleep 600ms
Type "write_plan"
Enter
Sleep 2200ms

Type "# /speckit-tasks  (writes the implementation contract)"
Enter
Sleep 600ms
Type "write_tasks"
Enter
Sleep 2500ms

# --- Phase 2: bridge fires after_tasks hook ---
Type "# after_tasks hook -> bridge writes the handoff JSON"
Enter
Sleep 700ms
Type "handoff_exec"
Enter
Sleep 2500ms

Type "# bridge-status confirms the state machine moved"
Enter
Sleep 600ms
Type "status"
Enter
Sleep 3500ms

# --- Phase 3: guard rules in action ---
Type "clear"
Enter
Sleep 300ms
Type "# Phase 2 -- guard enforces the boundary"
Enter
Sleep 700ms

Type "# A1: try /speckit-implement during executing"
Enter
Sleep 500ms
Type "guard_speckit_implement"
Enter
Sleep 3200ms

Type "# A2: try superpowers:writing-plans while Spec Kit owns spec.md + plan.md"
Enter
Sleep 500ms
Type "guard_writing_plans"
Enter
Sleep 3200ms

# --- Phase 4: Superpowers execution montage ---
Type "clear"
Enter
Sleep 300ms
Type "# Phase 3 -- Superpowers owns HOW (executing-plans -> TDD -> review)"
Enter
Sleep 700ms

Type "run_tdd_montage"
Enter
Sleep 3500ms

Type "echo '  superpowers:verification-before-completion  OK'"
Enter
Sleep 800ms
Type "echo '  superpowers:requesting-code-review            OK'"
Enter
Sleep 800ms
Type "echo '  superpowers:finishing-a-development-branch    OK'"
Enter
Sleep 1500ms

# --- Phase 5: complete ---
Type "clear"
Enter
Sleep 300ms
Type "# All tasks done -> bridge transitions to complete"
Enter
Sleep 600ms
Type "finish_cycle"
Enter
Sleep 3500ms

Type "# Cycle complete.  Spec Kit owns WHAT · Superpowers owns HOW · bridge keeps them honest."
Enter
Sleep 3000ms
