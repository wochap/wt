## Context

The `wt` script uses `git worktree add` to create worktrees. Git writes progress messages ("Preparing worktree...", "HEAD is now at...") to stdout. The shell wrapper (`wt.sh`) captures stdout via `$(command wt ...)` to get the worktree path for auto-cd. When git's stdout leaks through, the captured string contains multiple lines and cd fails.

Additionally, `wt list` intermittently shows absolute paths instead of relative paths. The path stripping logic `${path#"$root"/}` depends on `$root` prefix-matching the worktree paths. If `find_project_root` returns a logical path (with symlinks) while `git worktree list --porcelain` returns physical paths (symlinks resolved), the prefix won't match.

## Goals / Non-Goals

**Goals:**
- Shell wrapper receives clean single-line path on stdout from `wt clone` and `wt switch`
- `wt list` shows relative paths consistently regardless of symlink configuration
- Fix must not break direct `wt` usage (without shell wrapper)

**Non-Goals:**
- Changing the shell wrapper itself (fix is in `wt` script)
- Adding new commands or features
- Changing the bare clone layout

## Decisions

### Decision 1: Redirect git stdout to stderr with `>&2`

Add `>&2` to all `git worktree add` invocations. This sends git's stdout (progress messages) to stderr while the script's own `echo "$path"` stays on stdout.

**Alternatives considered:**
- Modify shell wrapper to extract last line: fragile, couples wrapper to output format
- Use `git worktree add --quiet`: suppresses some output but behavior varies by git version
- Pipe git stdout to `/dev/null`: loses potentially useful error context on stderr

**Chosen:** `>&2` redirect — simple, explicit, preserves all git output on stderr where users can see it.

### Decision 2: Normalize paths with `pwd -P` for physical path resolution

Use `pwd -P` in `find_project_root` to resolve symlinks, ensuring the root path matches what `git worktree list --porcelain` returns (physical paths).

**Alternatives considered:**
- Normalize worktree paths instead of root: more complex, need to resolve each path
- Use `realpath`: not available on all systems by default
- Strip with pattern matching workaround: fragile

**Chosen:** `pwd -P` in `find_project_root` — single change point, aligns with git's physical path behavior.

## Risks / Trade-offs

- [Symlink surprise] If user intentionally uses logical paths in their workflow, `pwd -P` will show physical paths in `wt list` → Mitigation: physical paths are more correct for git operations; user rarely notices
- [Git version differences] `git worktree add` output format may vary → Mitigation: redirecting all stdout to stderr handles any output format
