# Doctor

## Purpose

Diagnose and repair broken worktree gitdir links in a wt project, typically caused by moving the project folder.

## Requirements

### Requirement: Doctor repairs all worktrees
The system SHALL run `git worktree repair` from the bare `.git` directory for every registered worktree path.

#### Scenario: Moved project folder
- **WHEN** user runs `wt doctor` after moving the project folder
- **THEN** all worktree gitdir links are repaired and worktrees function normally

#### Scenario: All worktrees healthy
- **WHEN** user runs `wt doctor` and no worktrees are broken
- **THEN** system reports all worktrees healthy

### Requirement: Doctor reports per-worktree status
The system SHALL print a status line for each worktree indicating whether it was repaired or already healthy.

#### Scenario: Mixed healthy and broken
- **WHEN** some worktrees are broken and others are healthy
- **THEN** broken worktrees show a repaired indicator and healthy worktrees show a healthy indicator

### Requirement: Doctor requires wt project
The system SHALL error when run outside a wt project, consistent with other commands.

#### Scenario: Not inside wt project
- **WHEN** user runs `wt doctor` outside a bare-repo wt project
- **THEN** system prints an error and exits non-zero

### Requirement: Doctor output on stderr
The system SHALL print all status output to stderr, keeping stdout clean for shell integration.

#### Scenario: Status output destination
- **WHEN** `wt doctor` runs
- **THEN** all human-readable output goes to stderr and stdout is empty
