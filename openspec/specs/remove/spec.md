# Remove

## Purpose

Remove worktrees and optionally their associated branches.

## Requirements

### Requirement: Remove Clean Worktree
The system SHALL remove a clean worktree after confirmation.

#### Scenario: Remove clean worktree
- **WHEN** user runs `wt rm <name>` on clean worktree
- **THEN** system displays summary (path, branch info)
- **THEN** system prompts `Confirm? [y/N]`
- **THEN** on `y` input, system removes worktree
- **THEN** system deletes associated local branch
- **THEN** system prints results to stderr

#### Scenario: Abort on non-confirmation
- **WHEN** user runs `wt rm <name>` and enters anything other than `y`/`Y`
- **THEN** system prints "Aborted"
- **THEN** system does not remove worktree

### Requirement: Dirty Worktree Protection
The system SHALL refuse to remove dirty worktrees without `--force`.

#### Scenario: Dirty worktree without force
- **WHEN** user runs `wt rm <name>` on worktree with uncommitted changes
- **THEN** system exits with error "worktree has uncommitted changes, use --force"

#### Scenario: Dirty worktree with force
- **WHEN** user runs `wt rm <name> --force` on dirty worktree
- **THEN** system displays warning about uncommitted changes
- **THEN** system proceeds with removal after confirmation

### Requirement: Remote Branch Deletion
The system SHALL optionally delete the remote branch with `--remote` flag.

#### Scenario: Remove with remote deletion
- **WHEN** user runs `wt rm <name> --remote`
- **THEN** system removes worktree and local branch
- **THEN** system pushes `origin --delete <branch>`
- **THEN** system prints remote deletion result to stderr

#### Scenario: Remote deletion fails
- **WHEN** remote branch deletion fails
- **THEN** system prints warning but does not fail overall

### Requirement: Worktree Not Found
The system SHALL error when specified worktree doesn't exist.

#### Scenario: Unknown worktree name
- **WHEN** user runs `wt rm <name>` and no worktree matches
- **THEN** system exits with error "worktree not found"

### Requirement: Directory Naming for Removal
The system SHALL resolve worktree by directory name relative to project root.

#### Scenario: Remove by directory name
- **WHEN** user runs `wt rm <dir-name>`
- **THEN** system looks for worktree at `<root>/<dir-name>`
- **THEN** system matches against registered worktrees
