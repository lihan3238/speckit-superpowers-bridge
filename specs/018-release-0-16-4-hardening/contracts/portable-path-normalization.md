# Contract: Portable Missing-Path Normalization

## Purpose

Define the behavior that replaces GNU `realpath -m` in `scripts/bash/update-handoff.sh` without changing the handoff schema or adding a runtime dependency.

## Input and output

- Input is one non-empty path, absolute or relative to the caller's current directory.
- Output is one normalized absolute path followed by a newline.
- Empty input is not a valid canonicalization request; existing callers already filter empty feature paths.

## Normalization rules

1. Relative input is anchored to the current working directory.
2. Empty path segments and `.` are removed.
3. `..` removes the preceding resolved component and never climbs above `/`.
4. Each existing symbolic-link component is resolved with portable `readlink`.
5. A relative symbolic-link target is resolved relative to the link's parent; an absolute target resets resolution at `/`.
6. Missing components are retained and normalized lexically, matching GNU canonicalize-missing behavior.
7. Symbolic-link traversal is bounded; a loop or excessive chain returns non-zero with a clear error.

## Repository-relative rendering

- If the normalized path equals the normalized repository root, render `.`.
- If it is beneath the repository root, strip the root plus one separator.
- Otherwise preserve the absolute path.
- A symlink located inside the repository but targeting outside must be treated as outside.

## Non-regression obligations

- Required `spec.md`, `plan.md`, and `tasks.md` checks use the normalized feature path.
- Snapshot reads use the normalized source directory.
- Artifact hashing receives the same normalized feature directory.
- No `realpath -m` invocation remains in shipped bash scripts.
