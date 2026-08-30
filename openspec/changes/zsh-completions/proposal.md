## Why

`wt` has no shell completions. Users must remember subcommand names, flag syntax, and branch/worktree names manually. Adding zsh completions makes the tool discoverable and faster to use — tab-complete subcommands, flags, branch names, and worktree directory names.

## What Changes

- New `wt.zsh` completion file providing zsh completions for all wt subcommands
- Subcommand completion: `clone`, `switch`, `list`, `rm`, `help`
- Dynamic branch completion for `wt switch` (local + remote branches)
- Dynamic worktree name completion for `wt rm` (existing worktree directories)
- Flag completion: `-b` for switch, `--remote`/`--force` for rm

## Capabilities

### New Capabilities

- `zsh-completions`: Zsh completion definitions for wt subcommands, flags, branches, and worktree names

### Modified Capabilities

None.

## Impact

- New file: `wt.zsh` (completion script)
- No changes to `wt` or `wt.sh`
- Users source `wt.zsh` or place it in `$fpath` for autoloading
