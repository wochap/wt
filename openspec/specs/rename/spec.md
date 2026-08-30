# Rename

## Purpose

Rename the current worktree's directory from inside it, keeping the git worktree registration, branch, and HEAD intact.

## Requirements

### Requirement: Rename Current Worktree
The system SHALL rename the directory of the worktree containing the current working directory to a new name provided as `wt rename <new-name>`. The worktree SHALL remain registered in git with its branch and HEAD unchanged.

#### Scenario: Rename from inside worktree
- **WHEN** user runs `wt rename <new-name>` from inside a worktree directory of a wt project
- **THEN** system moves the worktree directory from `<root>/<old-name>` to `<root>/<new-name>` via `git worktree move`
- **THEN** the git worktree registration points to the new path
- **THEN** the checked-out branch and HEAD are unchanged

#### Scenario: Rename from worktree subdirectory
- **WHEN** user runs `wt rename <new-name>` from a subdirectory nested inside a worktree
- **THEN** system resolves the containing worktree and renames it

### Requirement: Worktree Context Required
The system SHALL refuse to rename when the current directory is not inside a worktree.

#### Scenario: Run outside any git repository
- **WHEN** user runs `wt rename <new-name>` outside a git repository
- **THEN** system exits with error "not inside a git repository"

#### Scenario: Run at project root
- **WHEN** user runs `wt rename <new-name>` at the project root (not inside any worktree)
- **THEN** system exits with an error indicating rename must be run from inside a worktree

### Requirement: New Name Validation
The system SHALL reject new names that would escape the project root or collide with existing paths.

#### Scenario: Name contains slash
- **WHEN** user runs `wt rename a/b`
- **THEN** system exits with an error and does not move anything

#### Scenario: Name is dot path
- **WHEN** user runs `wt rename .` or `wt rename ..`
- **THEN** system exits with an error and does not move anything

#### Scenario: Target directory exists
- **WHEN** user runs `wt rename <new-name>` and `<root>/<new-name>` already exists
- **THEN** system exits with error "directory '<new-name>' already exists"

#### Scenario: No name given
- **WHEN** user runs `wt rename` with no argument
- **THEN** system exits with error "usage: wt rename <new-name>"

### Requirement: Rename To Same Name Is No-op
The system SHALL treat renaming to the current directory name as a no-op.

#### Scenario: Same name
- **WHEN** user runs `wt rename <name>` and the current worktree directory is already named `<name>`
- **THEN** system prints the existing worktree path to stdout
- **THEN** system exits 0 without invoking `git worktree move`

### Requirement: Rename Output Contract
The system SHALL print the new worktree path to stdout and human-readable messages to stderr with color styling, consistent with other commands.

#### Scenario: Success output
- **WHEN** `wt rename <new-name>` succeeds
- **THEN** system prints the new worktree absolute path to stdout with no color codes
- **THEN** system prints a result message to stderr with the new directory name in green

#### Scenario: Git move failure
- **WHEN** `git worktree move` fails
- **THEN** system exits with an error message
- **THEN** git's error output remains visible on stderr

### Requirement: Help Lists Rename
The system SHALL list the rename command in help output.

#### Scenario: Help output
- **WHEN** user runs `wt help`
- **THEN** output includes `wt rename <new-name>` with a short description
