# README demo GIFs

Truth label: illustrative, transcript-derived demo assets. These GIFs are not real Codex or Claude Code recordings.

Two synthetic-shell demos rendered by [Charmbracelet VHS](https://github.com/charmbracelet/vhs). For v1.0.0, real verification evidence lives in `specs/013-v1-0-release-hardening/verification.md` and the sibling sandbox evidence files under `../test_specify_superpower/`.

| File | Length | Size | Where it's used |
|------|--------|------|-----------------|
| `hero.gif`       | ~18 s  | ~1.0 MB | README demo block — concise user happy path |
| `full-cycle.gif` | ~26 s  | ~1.7 MB | README "Your first feature in 10 minutes" details (collapsed by default, so the file size is not on the critical render path) |

## What's real vs. synthesized in the GIFs

- **Real**: bridge handoff transitions. The tape copies the repo's actual `update-handoff.sh` into a `mktemp -d` project and uses it for `executing` and `complete`.
- **Synthesized via a tiny demo shell**: the user-facing Spec Kit and Superpowers progress lines. Slash-command output depends on the active AI agent, so the transcript is scripted to keep the README demo concise and reproducible.
- **Truth label**: illustrative. The GIFs are useful for orientation, but release claims must cite the sandbox/platform/agent evidence instead of these animations.

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

If `vhs`, `ttyd`, or `ffmpeg` is unavailable, do not regenerate GIFs from fake terminal output and do not label old GIFs as real recordings. Keep this truth label and publish transcript/sandbox evidence instead.

## Editing the storyboard

Each tape file is heavily commented. The demos use `DejaVu Sans Mono`, which is available in the WSL image used for maintainer rendering; switching to a missing font can make VHS fall back to a badly tracked font. Pacing knobs:

- `Set FontSize 20` / `Set FontSize 22` — larger = more readable on GitHub; smaller = more terminal context.
- `Set TypingSpeed 40ms` — slower = more readable; faster = shorter GIF.
- `Sleep 800ms` between beats — the budget that controls total length.
- `Set Framerate 20` — increase only if motion feels choppy.

The hero target is < 1 MB; the full-cycle target is < 2 MB so README load stays snappy.
