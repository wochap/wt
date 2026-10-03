---
name: wt
description: Manage git worktrees with the wt CLI (bare .git + sibling worktree dirs); create, enter, list, remove, rename worktrees and move changes between them.
disable-model-invocation: true
---

# wt

Use in projects laid out as a bare `.git` with worktrees as sibling dirs:

```text
project/
├── .git/       # bare repository
├── main/       # default-branch worktree
└── feature-x/  # branch worktree (slashes in branch names become '-')
```

```sh
wt clone <url> [dir]              # new wt project: bare .git + default worktree
wt switch                         # stdout: default-branch worktree path
wt switch <ref> [name]            # stdout: worktree path (created if missing)
wt switch -b <branch> [from]      # new branch + worktree; stdout: its path
wt list                           # all worktrees with status
wt rename <new-name>              # rename current worktree dir; stdout: new path
wt pull <source>                  # squash source worktree's HEAD into current, staged
wt pull <source> --staged         # apply only source's staged diff
echo y | wt rm <name>             # remove worktree + local branch
wt doctor                         # repair broken worktree links
```

- `wt` changes no directory by itself. The `cd` wrapper in `wt.plugin.sh` is
  for interactive shells only. Use the printed path: `cd "$(wt switch <ref>)"`
  or `git -C "$(wt switch <ref>)" ...`.
- Stdout of `switch`, `clone`, `rename` is only the absolute path; status,
  hook output and errors go to stderr. Nonzero exit means no path.
- `<name>` for `rm`/`pull` is the worktree dir name (e.g. `feature-login`),
  not the branch name. `pull` also accepts a path to another clone.
- `rm` and `pull` (into a dirty target) prompt `[y/N]` on stdin; pipe `echo y`
  only when removal or the merge is intended. `rm` deletes the local branch;
  `--force` drops uncommitted changes, `--remote` also deletes
  `origin/<branch>`. Never pass either without the user asking.
- `wt switch` runs `post_create` hooks from the worktree's `wt.json` (copy,
  symlink, command) only for newly created worktrees. A hook failure exits
  nonzero but leaves the worktree and branch in place; fix and rerun the step
  by hand.
- `pull` stages changes in the current worktree; it does not commit. On
  conflicts, resolve them manually.
