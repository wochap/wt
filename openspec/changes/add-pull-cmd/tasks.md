## 1. Helpers

- [x] 1.1 Add `verify_same_repo` helper: compare root commit sets (`git rev-list --max-parents=0 HEAD`) between two git dirs, return 0 if any intersection, 1 otherwise
- [x] 1.2 Add `find_common_ancestor` helper: walk source `git rev-list HEAD` newest-first, check each SHA with `git cat-file -e` in target, echo first hit
- [x] 1.3 Add `resolve_pull_source` helper: try `$root/<name>` as registered worktree first, fall back to filesystem path, verify it's a git repo, echo resolved path or die

## 2. Core command

- [x] 2.1 Add `cmd_pull` function skeleton: parse args (`<source>`, `--staged`), resolve project root, resolve source, call `verify_same_repo`
- [x] 2.2 Add dirty target check: if `git status --porcelain` non-empty, warn and prompt y/N confirmation, abort on decline
- [x] 2.3 Implement `--staged` path: run `git -C <source> diff --cached`, die if empty, apply with `git apply` in target cwd
- [x] 2.4 Implement default same-project path: detect shared object store, run `git merge --squash <branch-or-sha>`, let conflicts surface naturally
- [x] 2.5 Implement default cross-clone path: call `find_common_ancestor`, generate patch with `git -C <source> diff <base>..HEAD`, apply with `git apply` in target cwd
- [x] 2.6 Wire `cmd_pull` into `main` case statement and add to `cmd_help` usage text

## 3. Completions

- [x] 3.1 Add `pull` to subcommand list in `wt.zsh`
- [x] 3.2 Add `--staged` flag completion and worktree name completion for `wt pull` in `wt.zsh`
