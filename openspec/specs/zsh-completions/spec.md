# Zsh Completions

## Purpose

Provide zsh tab-completion for wt subcommands, flags, branches, commits, and worktree names.

## Requirements

### Requirement: Subcommand Completion
The system SHALL provide tab-completion for wt subcommands.

#### Scenario: Complete subcommands
- **WHEN** user types `wt <TAB>`
- **THEN** zsh suggests: `clone`, `switch`, `list`, `rm`, `help`

### Requirement: Switch Flag Completion
The system SHALL complete flags for `wt switch`.

#### Scenario: Complete switch flags
- **WHEN** user types `wt switch -<TAB>`
- **THEN** zsh suggests: `-b`

### Requirement: Switch Branch Completion
The system SHALL complete branch names for `wt switch`.

#### Scenario: Complete local branches
- **WHEN** user types `wt switch <TAB>` inside a wt project
- **THEN** zsh suggests local branch names from `git branch`

#### Scenario: Complete remote branches
- **WHEN** user types `wt switch <TAB>` inside a wt project
- **THEN** zsh suggests remote branch names from `git branch -r`

#### Scenario: Complete commit hashes
- **WHEN** user types `wt switch <TAB>` inside a wt project
- **THEN** zsh suggests commit hashes

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
