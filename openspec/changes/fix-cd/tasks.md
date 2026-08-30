## 1. Fix git stdout leak on worktree add

- [x] 1.1 Add `>&2` redirect to `git worktree add` in `cmd_clone` (line ~197)
- [x] 1.2 Add `>&2` redirect to `git worktree add -b` in `cmd_switch` (line ~233)
- [x] 1.3 Add `>&2` redirect to `git worktree add --detach` calls in `cmd_switch` (lines ~278, ~288)
- [x] 1.4 Add `>&2` redirect to `git worktree add` for branch checkout in `cmd_switch` (line ~292)

## 2. Fix path resolution for symlinked project roots

- [x] 2.1 Change `find_project_root` to use `pwd -P` instead of `pwd` for physical path resolution

## 3. Verify fixes

- [x] 3.1 Test `wt clone` with shell wrapper — verify cd succeeds and no "no such file or directory" error
- [x] 3.2 Test `wt switch` creating new worktree with shell wrapper — verify cd succeeds
- [x] 3.3 Test `wt switch` to existing worktree with shell wrapper — verify cd succeeds
- [x] 3.4 Test `wt list` shows relative paths when project root contains symlinks
