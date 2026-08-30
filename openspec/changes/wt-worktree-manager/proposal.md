# Proposal: wt — Git Worktree Manager

## Problem

Managing multiple git worktrees involves repetitive, error-prone commands (`git worktree add`, `git worktree remove`, `git worktree list --porcelain`) with verbose output. Switching between worktrees requires remembering paths. Cloning a repo for worktree-based workflows requires manual bare-clone setup. No single tool provides a fast, opinionated workflow for worktree-centric development.

Existing tools like worktrunk (Rust) are feature-rich but heavy. For simple worktree management, a lightweight bash script with fast execution is preferable.

## Solution

A bash script (`wt`) providing an opinionated worktree workflow with a bare-clone directory layout:

```
project/
├── .git/           (bare repo)
├── main/           (default branch worktree)
├── feature-x/      (branch worktree)
└── 9a8b7c6d/       (detached commit worktree)
```

### Commands

| Command | Description |
|---------|-------------|
| `wt` | Show help |
| `wt clone <url> [dir]` | Bare clone + default branch worktree, cd into it |
| `wt switch` | Switch to default branch worktree (create if missing) |
| `wt switch <ref> [name]` | Switch to worktree for ref (create if missing) |
| `wt switch -b <branch> [from]` | Create new branch + worktree |
| `wt list` | Worktrunk-style table (fast columns only) |
| `wt rm <name> [--remote] [--force]` | Remove worktree + branch (with confirmation) |

### Key Behaviors

- **Discovery**: Works from project root, inside `.git/`, or inside any worktree (via `git rev-parse --git-common-dir`)
- **cd integration**: Shell function wrapper (`wt.sh`, sourced in `.bashrc`) intercepts `switch`/`clone` for directory changes
- **Dir naming**: Branch slashes flattened to dashes; commit+name uses just the name; branch+name uses `{branch}-{name}`
- **Fast list**: One `git worktree list --porcelain` call + parallel background jobs per worktree for log/status/diff
- **Safety**: `wt rm` always confirms; `--force` required for dirty worktrees; nested repo detection prevents accidents

## Non-goals

- Remote tracking status (slow, requires fetch)
- CI status integration
- Ahead/behind counts vs main branch
- Interactive TUI picker
- Windows support

## Files

- `wt` — Main bash script (executable)
- `wt.sh` — Shell function wrapper for cd integration (sourced)
