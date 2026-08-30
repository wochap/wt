# Zsh Completions

## Purpose

Provide zsh tab-completion for wt subcommands, flags, branches, commits, and worktree names.

## Requirements

### Requirement: Subcommand Completion
The system SHALL provide tab-completion for wt subcommands.

#### Scenario: Complete subcommands
- **WHEN** user types `wt <TAB>`
- **THEN** zsh suggests: `clone`, `switch`, `list`, `rm`, `pull`, `doctor`, `help`

### Requirement: Switch Flag Completion
The system SHALL complete flags for `wt switch`.

#### Scenario: Complete switch flags
- **WHEN** user types `wt switch -<TAB>`
- **THEN** zsh suggests: `-b`

### Requirement: Switch Branch Completion
The system SHALL complete branch names and commits for `wt switch`, logically separated into distinct visual groups.

#### Scenario: Complete local branches
- **WHEN** user types `wt switch <TAB>` inside a wt project
- **THEN** zsh suggests local branch names from `git branch` under the `-- local branch --` group

#### Scenario: Complete remote branches
- **WHEN** user types `wt switch <TAB>` inside a wt project
- **THEN** zsh suggests remote branch names from `git branch -r` under the `-- remote branch --` group

#### Scenario: Complete commit hashes
- **WHEN** user types `wt switch <TAB>` inside a wt project
- **THEN** zsh suggests commit hashes under the `-- commit --` group

### Requirement: Remove Flag Completion
The system SHALL complete flags for `wt rm`.

#### Scenario: Complete rm flags
- **WHEN** user types `wt rm --<TAB>`
- **THEN** zsh suggests: `--remote`, `--force`

### Requirement: Remove Worktree Completion
The system SHALL complete worktree directory names for `wt rm`.

#### Scenario: Complete worktree names
- **WHEN** user types `wt rm <TAB>` inside a wt project
- **THEN** zsh suggests worktree directory names (relative to project root)

### Requirement: Pull Flag Completion
The system SHALL complete flags for `wt pull`.

#### Scenario: Complete pull flags
- **WHEN** user types `wt pull --<TAB>`
- **THEN** zsh suggests: `--staged`

### Requirement: Pull Source Completion
The system SHALL complete worktree directory names and filesystem paths for `wt pull`.

#### Scenario: Complete worktree names for pull
- **WHEN** user types `wt pull <TAB>` inside a wt project
- **THEN** zsh suggests worktree directory names (relative to project root)

#### Scenario: Complete filesystem paths for pull
- **WHEN** user types `wt pull <TAB>`
- **THEN** zsh also suggests filesystem directory paths via standard path completion

#### Scenario: Complete paths outside wt project
- **WHEN** user types `wt pull <TAB>` outside a wt project
- **THEN** zsh suggests filesystem directory paths

### Requirement: Flags-Last Completion Ordering
The system SHALL only offer flag completions after at least one positional argument has been provided. Before any positional argument, only value completions (branches, paths, worktree names) SHALL appear.

#### Scenario: No flags before positional
- **WHEN** user types `wt switch <TAB>` with no prior positional
- **THEN** zsh suggests branches and commits only (no `-b`)

#### Scenario: Flags after positional
- **WHEN** user types `wt switch <branch> <TAB>`
- **THEN** zsh suggests `-b` flag only

#### Scenario: Pull flags after source
- **WHEN** user types `wt pull <source> <TAB>`
- **THEN** zsh suggests `--staged` only

#### Scenario: Rm flags after name
- **WHEN** user types `wt rm <name> <TAB>`
- **THEN** zsh suggests `--force` and `--remote`

### Requirement: Graceful Degradation Outside wt Project
The system SHALL not error when completions are triggered outside a wt project.

#### Scenario: Not inside wt project
- **WHEN** user types `wt switch <TAB>` outside a wt project
- **THEN** zsh returns empty completions without error

### Requirement: Completion File Setup
The system SHALL provide a completion file loadable by zsh.

#### Scenario: Source completion file
- **WHEN** user sources `wt.zsh` or places it in `$fpath`
- **THEN** `compdef _wt wt` is registered
- **THEN** tab-completion works for wt commands
