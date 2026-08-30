# Design: wt — Git Worktree Manager

## Architecture

Two files:

- **`wt`** — Bash script, all logic. Executable. Prints target path to stdout on `switch`/`clone` (for wrapper to cd). Errors to stderr, exit 1.
- **`wt.sh`** — Shell function wrapper, sourced in `.bashrc`/`.zshrc`. Intercepts `switch`/`clone` for cd, handles `rm` PWD recovery.

```
┌─────────────────────────────────────────────────┐
│  wt.sh (sourced function)                       │
│                                                 │
│  wt() {                                         │
│    case "$1" in                                 │
│      switch|clone)                              │
│        dir="$(command wt "$@")" && cd "$dir"    │
│        ;;                                       │
│      rm)                                        │
│        command wt "$@"                          │
│        [[ ! -d "$PWD" ]] && cd "$(command wt switch)" │
│        ;;                                       │
│      *) command wt "$@" ;;                      │
│    esac                                         │
│  }                                              │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│  wt (bash script)                               │
│                                                 │
│  ┌───────────┐  ┌──────────┐  ┌──────────────┐ │
│  │ discovery │  │ commands │  │  helpers     │ │
│  │           │  │          │  │              │ │
│  │ find_root │  │ clone    │  │ get_default  │ │
│  │           │  │ switch   │  │ resolve_ref  │ │
│  │           │  │ list     │  │ dir_name     │ │
│  │           │  │ rm       │  │ wt_exists    │ │
│  │           │  │ help     │  │ confirm      │ │
│  └───────────┘  └──────────┘  └──────────────┘ │
└─────────────────────────────────────────────────┘
```

## Discovery

Find project root from any location using `git rev-parse --git-common-dir`:

```bash
find_project_root() {
  local git_common
  git_common=$(git rev-parse --git-common-dir 2>/dev/null) || {
    echo "error: not inside a git repository" >&2; return 1
  }
  # resolve to absolute path
  git_common=$(cd "$git_common" && pwd)

  local root
  root=$(dirname "$git_common")

  # edge case: nested repo detection
  # if root itself is inside another worktree, refuse
  local parent_git
  if parent_git=$(git -C "$root/.." rev-parse --git-common-dir 2>/dev/null); then
    parent_git=$(cd "$root/.." && cd "$parent_git" && pwd)
    if [[ "$parent_git" != "$git_common" ]]; then
      echo "error: refusing to operate inside nested git repo" >&2
      return 1
    fi
  fi

  echo "$root"
}
```

Works from:
- Project root (parent of `.git/`)
- Inside `.git/`
- Inside any worktree
- Nested directories within a worktree

## Command: clone

```
wt clone <url> [dir]
```

Flow:
1. `dir = $2 || basename(url) .git` (strip `.git` suffix)
2. `mkdir -p "$dir"`
3. `git clone --bare "$url" "$dir/.git"`
4. Detect default branch: `git -C "$dir/.git" symbolic-ref HEAD` → strip `refs/heads/`
5. `git -C "$dir/.git" worktree add "../$default_branch" "$default_branch"`
6. Print summary to stderr
7. Print `"$dir/$default_branch"` to stdout (wrapper cd's here)

Bare clone sets `HEAD` to default branch. Local branches exist as `refs/heads/*` after bare clone (fetch refspec maps remote heads to local heads).

## Command: switch

```
wt switch                       → default branch worktree
wt switch <ref> [name]          → ref worktree (create if missing)
wt switch -b <branch> [from]    → new branch + worktree
```

### Resolution order for `<ref>`

```bash
resolve_ref() {
  local ref="$1" git_dir="$2"
  if git -C "$git_dir" rev-parse --verify "refs/heads/$ref" &>/dev/null; then
    echo "local-branch"
  elif git -C "$git_dir" rev-parse --verify "refs/remotes/origin/$ref" &>/dev/null; then
    echo "remote-branch"
  elif git -C "$git_dir" rev-parse --verify "$ref^{commit}" &>/dev/null; then
    echo "commit"
  else
    return 1
  fi
}
```

### Dir naming

```bash
make_dir_name() {
  local ref_type="$1" ref="$2" name="$3"
  case "$ref_type" in
    local-branch|remote-branch)
      local flat="${ref//\//-}"
      if [[ -n "$name" ]]; then
        echo "${flat}-${name}"
      else
        echo "$flat"
      fi
      ;;
    commit)
      local hash
      hash=$(git rev-parse --short=8 "$ref")
      if [[ -n "$name" ]]; then
        echo "$name"
      else
        echo "$hash"
      fi
      ;;
  esac
}
```

| Command | Dir |
|---------|-----|
| `wt switch feature/wm` | `feature-wm` |
| `wt switch main scratch` | `main-scratch` |
| `wt switch 9a8b7c6d` | `9a8b7c6d` |
| `wt switch 9a8b7c6d bisect` | `bisect` |
| `wt switch -b feature/waybar` | `feature-waybar` |

### Switch flow (no -b)

```
1. Resolve ref type (local-branch / remote-branch / commit)
2. Check if worktree already exists for this ref:
   - Parse `git worktree list --porcelain`
   - Match by branch (refs/heads/<ref>) or HEAD sha (commit)
3. If exists → print path, done
4. If not → create:
   - branch: `git worktree add "$root/$dir_name" "$ref"`
     (git auto-creates local tracking branch for remote-only refs)
   - commit: `git worktree add --detach "$root/$dir_name" "$ref"`
   - named (detached): same but dir_name includes name
5. Print path to stdout
```

### Switch flow (-b)

```
1. Check branch doesn't already exist → error if it does
2. Check dir doesn't already exist → error if it does
3. from = ${from:-HEAD}
4. git worktree add -b "$branch" "$root/$dir_name" "$from"
5. Print path to stdout
```

### Default branch detection

```bash
get_default_branch() {
  local git_dir="$1"
  # 1. refs/heads/main
  if git -C "$git_dir" rev-parse --verify refs/heads/main &>/dev/null; then
    echo "main"; return
  fi
  # 2. refs/heads/master
  if git -C "$git_dir" rev-parse --verify refs/heads/master &>/dev/null; then
    echo "master"; return
  fi
  # 3. origin/HEAD symref
  local remote_head
  remote_head=$(git -C "$git_dir" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  if [[ -n "$remote_head" ]]; then
    echo "${remote_head#refs/remotes/origin/}"; return
  fi
  # 4. origin/main, origin/master
  if git -C "$git_dir" rev-parse --verify refs/remotes/origin/main &>/dev/null; then
    echo "main"; return
  fi
  if git -C "$git_dir" rev-parse --verify refs/remotes/origin/master &>/dev/null; then
    echo "master"; return
  fi
  echo "error: cannot detect default branch" >&2; return 1
}
```

## Command: list

```
wt list
```

Output format (worktrunk-inspired, fast columns only):

```
  Branch        Status  HEAD±    Path            Commit    Age   Message
@ main          M       +10-2   .               ee13b66   20h   fix(tmux) sandbox config
  feature-wm    ✓               feature-wm      abc1234   3d    add hyprland bindings
  (detached)    ✓               9a8b7c6d        9a8b7c6   5h    debug: trace network

○ 3 worktrees
```

### Data collection

**Phase 1** — one call for all worktrees:
```bash
git worktree list --porcelain
```
Parse: `worktree` (path), `HEAD` (sha), `branch` (refs/heads/X or absent for detached), `detached` flag.

**Phase 2** — parallel background jobs per worktree:
```bash
for each worktree; do
  (
    # commit info: hash, age, message
    git -C "$wt_path" log -1 --format='%h%x09%ar%x09%s'
    # status: dirty flag
    git -C "$wt_path" status --porcelain 2>/dev/null | head -1
    # diff stats: +lines -lines
    git -C "$wt_path" diff --numstat HEAD 2>/dev/null
  ) > "$tmpdir/$i" &
done
wait
```

### Columns

| Column | Source | Notes |
|--------|--------|-------|
| Gutter | `@` = current worktree | Compare PWD to worktree path |
| Branch | porcelain `branch` field | `(detached)` if no branch |
| Status | `git status --porcelain` | `M` if non-empty, `✓` if clean |
| HEAD± | `git diff --numstat HEAD` | `+N-M` sum, empty if clean |
| Path | porcelain `worktree` field | Relative to project root, `.` for current |
| Commit | porcelain `HEAD` field | First 8 chars |
| Age | `git log -1 --format=%ar` | Relative time |
| Message | `git log -1 --format=%s` | Subject line |

### Rendering

Collect all data, compute column widths, print with `printf` formatting. Truncate Message column to terminal width if needed.

## Command: rm

```
wt rm <dir-name> [--remote] [--force]
```

Flow:
1. Resolve worktree path: `$root/$dir_name`
2. Verify it's a registered worktree (parse porcelain)
3. Gather info:
   - Attached branch? (from porcelain `branch` field)
   - Dirty? (`git status --porcelain`)
4. If dirty and no `--force` → error, exit 1
5. Print summary to stderr:
   ```
   Remove worktree: /path/to/project/feature-wm
     Branch: feature/wm (will be deleted)
     Remote: origin/feature/wm (will be deleted)    ← if --remote
     ⚠ worktree has uncommitted changes             ← if dirty
   Confirm? [y/N]
   ```
6. Read confirmation (from `/dev/tty` for safety in subshells)
7. `git worktree remove "$path" [--force]`
8. `git worktree prune`
9. If attached branch: `git branch -D "$branch"`
10. If `--remote`: `git push origin --delete "$branch"`
11. Print removed info to stderr

Wrapper handles cd: if `$PWD` no longer exists after rm, cd to default worktree.

## Command: help

```
wt
wt help
wt --help
```

Prints usage to stderr, exit 0.

## Edge Cases

| Case | Behavior |
|------|----------|
| Not in a git repo | Error: "not inside a git repository" |
| Nested git repo | Error: "refusing to operate inside nested git repo" |
| Branch already exists (`-b`) | Error: "branch 'X' already exists" |
| Worktree dir already exists | Error: "worktree already exists at X" |
| Unknown ref | Error: "unknown ref: X" |
| Dirty rm without `--force` | Error: "worktree has uncommitted changes, use --force" |
| rm current worktree | Remove + wrapper cd's to default |
| `wt switch` when default wt missing | Create it, then cd |
| Branch with slashes | Flatten `/` to `-` in dir name |

## Dependencies

- `git` (>= 2.15 for bare repo worktree support)
- `bash` (>= 4.0 for associative arrays, `${var//}` substitution)
- Standard unix: `awk`, `sed`, `basename`, `dirname`, `mkdir`, `printf`
