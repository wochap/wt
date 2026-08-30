# Tasks: wt — Git Worktree Manager

## Task 1: Scaffold `wt` script with helpers and discovery

- [x] Create `wt` bash script with:
- Shebang, `set -euo pipefail`
- `find_project_root()` — discovery via `git rev-parse --git-common-dir`, nested repo detection
- `get_default_branch()` — refs/heads/main → master → origin/HEAD → origin/main → origin/master
- `resolve_ref()` — local-branch / remote-branch / commit detection
- `make_dir_name()` — dir naming rules (flatten slashes, commit+name → just name, branch+name → branch-name)
- `find_worktree_for_ref()` — parse `git worktree list --porcelain`, match by branch or HEAD sha
- `help()` — usage text
- Main dispatch: parse `$1` as subcommand, route to handler

**Files**: `wt`

## Task 2: Implement `wt clone`

- [x] Parse `<url>` and optional `[dir]`
- Derive dir from URL basename if not provided (strip `.git` suffix)
- `git clone --bare "$url" "$dir/.git"`
- Detect default branch via `get_default_branch`
- `git -C "$dir/.git" worktree add "../$default_branch" "$default_branch"`
- Print summary to stderr
- Print default worktree path to stdout (for wrapper cd)

**Files**: `wt`

## Task 3: Implement `wt switch`

- [x] Three modes:
- **No args**: resolve default branch, find or create its worktree, print path
- **`<ref> [name]`**: resolve ref type, check existing worktree, create if missing (branch: `git worktree add`, commit: `git worktree add --detach`), print path
- **`-b <branch> [from]`**: validate branch/dir don't exist, `git worktree add -b`, print path

Error cases: unknown ref, existing branch with `-b`, existing worktree dir.

**Files**: `wt`

## Task 4: Implement `wt list`

- [x] Phase 1: `git worktree list --porcelain` → parse into arrays (path, HEAD, branch, detached)
- Phase 2: background jobs per worktree → `git log -1`, `git status --porcelain`, `git diff --numstat HEAD` → write to temp files
- `wait` for all jobs
- Compute column widths from data
- Render table with `printf`: Gutter, Branch, Status, HEAD±, Path, Commit, Age, Message
- Footer: `○ N worktrees`
- Path column: relative to project root, `.` for current worktree
- Truncate Message to terminal width (`tput cols`)

**Files**: `wt`

## Task 5: Implement `wt rm`

- [x] Parse `<dir-name>`, `--remote`, `--force` flags
- Resolve worktree path, verify registered (porcelain parse)
- Gather: attached branch, dirty status
- Dirty + no `--force` → error exit
- Print summary to stderr, `Confirm? [y/N]` read from `/dev/tty`
- `git worktree remove [--force]`
- `git worktree prune`
- `git branch -D` if attached
- `git push origin --delete` if `--remote`
- Print results to stderr

**Files**: `wt`

## Task 6: Create `wt.sh` shell function wrapper

- [x] `wt()` function:
  - `switch|clone`: capture stdout, cd on success
  - `rm`: run interactively, if `$PWD` gone after → cd to `$(command wt switch)`
  - `*`: passthrough to `command wt`
- Comment at top: `# source this in .bashrc / .zshrc`

**Files**: `wt.sh`

## Task 7: Test all commands end-to-end

- [x] `wt clone` a small public repo, verify layout (`.git/` bare + `main/` worktree)
- Verify cd into default worktree after clone
- `wt list` from project root, `.git/`, worktree, nested dir
- `wt switch` to default, existing branch, new branch (`-b`), commit, named detached
- `wt rm` clean worktree, dirty worktree (refuse without `--force`), with `--remote`
- `wt rm` current worktree → verify cd to default
- Edge cases: unknown ref, duplicate branch, nested repo error
- Verify dir naming: slashes flattened, commit+name, branch+name

**Files**: manual testing
