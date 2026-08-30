## Why

Worktrees often diverge — a user works in one worktree and needs to bring those changes into another. Today this requires manual git commands (diff, format-patch, apply) with careful setup. `wt pull` provides a single command to squash-apply changes from any worktree or repository clone into the current one, handling both same-project worktrees (shared object store) and cross-clone scenarios (separate object stores, possibly different remotes).

## What Changes

- Add `wt pull <source> [--staged]` command to the `wt` binary
- Source can be a worktree folder name within the current project or a path to any worktree/git repository
- Default mode: squash all changes since the common ancestor into the current worktree
  - Same-project worktrees: uses `git merge --squash` (native 3-way merge, conflict markers)
  - Cross-clone repos: generates a patch via merge-base walk + `git diff`, applies with `git apply`
- `--staged` mode: applies only the staged changes (`git diff --cached`) from source, always via patch
- Same-repository verification via root commit comparison before any operation
- Target dirty check with interactive confirmation before proceeding

## Capabilities

### New Capabilities
- `pull`: Pull and squash-apply changes from a source worktree or repository into the current worktree

### Modified Capabilities
- `zsh-completions`: Add `pull` subcommand, `--staged` flag, and worktree name completion

## Impact

- `wt` binary: new `cmd_pull` function, new helper for same-repo verification and cross-clone merge-base discovery
- `wt.zsh`: completion entries for `pull` subcommand
- No changes to `wt.sh` (pull does not cd, falls through existing `*` case)
- No new dependencies — pure git + bash
