## Why

Shell wrapper cd integration is broken. `git worktree add` outputs progress messages to stdout, which get captured by the shell function's `$(command wt ...)` substitution. The resulting multi-line string causes `cd` to fail with "no such file or directory". Additionally, `wt list` shows absolute paths instead of relative paths in some scenarios, suggesting a path resolution mismatch.

## What Changes

- Redirect git stdout to stderr on all `git worktree add` calls in `wt` so only the worktree path reaches stdout
- Investigate and fix path resolution mismatch between `find_project_root` (logical path) and `git worktree list --porcelain` (potentially physical path) causing `wt list` to display absolute paths

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `clone`: git worktree add stdout must not leak to stdout (only path)
- `switch`: git worktree add stdout must not leak to stdout (only path)
- `shell-integration`: shell wrapper must receive clean single-line path on stdout
- `list`: path column must show relative paths consistently regardless of symlink resolution

## Impact

- `wt` script: 5 `git worktree add` calls need stdout→stderr redirect
- `wt` script: `find_project_root` or path stripping logic may need symlink normalization
- `wt.sh` shell wrapper: no changes needed (fix is in `wt` itself)
