# README demo GIFs

Two synthetic-shell demos rendered by [Charmbracelet VHS](https://github.com/charmbracelet/vhs).

| File | Length | Size | Where it's used |
|------|--------|------|-----------------|
| `hero.gif`       | ~36 s  | ~464 KB | README demo block — bridge state machine in 5 beats |
| `full-cycle.gif` | ~64 s  | ~1.5 MB | README "Your first feature in 10 minutes" details (collapsed by default, so the file size is not on the critical render path) |

## What's real vs. synthesized in the GIFs

- **Real**: every call to `bridge-status.sh`, `update-handoff.sh`, and `guard-command.sh` — the tape copies the repo's actual scripts into a `mktemp -d` sandbox and runs them. The output text, including the literal `[bridge state]` block, the `Next:` recommendation, and the guard's deny reasons, is byte-identical to what a real user sees.
- **Synthesized via `printf`**: the `/speckit-specify`, `/speckit-plan`, `/speckit-tasks` LLM-side outputs and the `superpowers:*` progress lines. These are scripted so the demo is deterministic and reproducible.

## Re-rendering

```bash
bash scripts/render-demos.sh
```

Or directly:

```bash
cd docs/demo
vhs hero.tape
vhs full-cycle.tape
```

The wrapper checks for `vhs` and prints the install pointer if missing. VHS's runtime deps are `ttyd` and `ffmpeg`.

## Editing the storyboard

Each tape file is heavily commented. The demos use `DejaVu Sans Mono`, which is available in the WSL image used for maintainer rendering; switching to a missing font can make VHS fall back to a badly tracked font. Pacing knobs:

- `Set FontSize 20` / `Set FontSize 22` — larger = more readable on GitHub; smaller = more terminal context.
- `Set TypingSpeed 40ms` — slower = more readable; faster = shorter GIF.
- `Sleep 800ms` between beats — the budget that controls total length.
- `Set Framerate 20` — increase only if motion feels choppy.

The hero target is < 1 MB; the full-cycle target is < 2 MB so README load stays snappy.
