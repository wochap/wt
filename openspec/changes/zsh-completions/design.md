## Context

`wt` is a bash script with subcommands (clone, switch, list, rm, help). The shell wrapper `wt.sh` provides cd integration for zsh/bash. No completion script exists. Zsh's completion system (`compdef` + `compadd`) supports dynamic completions via shell functions.

## Goals / Non-Goals

**Goals:**
- Tab-complete subcommands after `wt `
- Tab-complete flags per subcommand (`-b` for switch, `--remote`/`--force` for rm)
- Tab-complete branch names (local + remote) for `wt switch`
- Tab-complete worktree directory names for `wt rm`
- Tab-complete commit hashes for `wt switch`

**Non-Goals:**
- Bash completions (zsh only for now)
- Completing URLs for `wt clone`
- Completing refs for `wt switch -b <from>`

## Decisions

### Decision 1: Single completion file with `compdef`

Create `wt.zsh` containing a `_wt` completion function registered via `compdef _wt wt`. This is the standard zsh pattern — works with `fpath` autoloading or direct `source`.

**Alternatives considered:**
- Inline completions in `wt.sh`: mixes concerns, harder to maintain
- Separate file per subcommand: over-engineered for this scope

### Decision 2: Dynamic branch/worktree listing via git

Use `git branch` and `git worktree list --porcelain` inside the completion function to generate candidates at tab-press time. This stays in sync with actual state — no stale caches.

**Alternatives considered:**
- Static list in completion file: goes stale immediately
- Parse wt's own output: adds dependency on output format stability

### Decision 3: Context-aware argument positions

Use zsh's `words`/`CURRENT` to detect which subcommand is active and what argument position we're at. First arg = subcommand, subsequent args depend on subcommand.

## Risks / Trade-offs

- [Not inside wt project] Branch/worktree completions require being inside a wt project (bare repo) → Mitigation: gracefully return empty completions when not in a wt project
- [Performance] Dynamic git calls on every tab press → Mitigation: git branch/list is fast for typical repo sizes; no mitigation needed unless repos get very large
