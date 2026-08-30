## 1. Completion function scaffold

- [x] 1.1 Create `wt.zsh` with `_wt()` function and `compdef _wt wt` registration
- [x] 1.2 Implement subcommand dispatch: detect current subcommand from `words`/`CURRENT`

## 2. Subcommand and flag completions

- [x] 2.1 Complete subcommands: `clone`, `switch`, `list`, `rm`, `help`
- [x] 2.2 Complete flags for `wt switch`: `-b`
- [x] 2.3 Complete flags for `wt rm`: `--remote`, `--force`

## 3. Dynamic completions

- [x] 3.1 Complete branch names for `wt switch` (local + remote via `git branch`/`git branch -r`)
- [x] 3.2 Complete commit hashes for `wt switch`
- [x] 3.3 Complete worktree directory names for `wt rm` (via `git worktree list --porcelain`)

## 4. Edge cases and verification

- [x] 4.1 Graceful degradation: no errors when outside a wt project
- [x] 4.2 Test completions in zsh: subcommands, flags, branches, worktree names
