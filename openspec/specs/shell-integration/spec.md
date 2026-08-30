# Shell Integration

## Purpose

Provide shell function wrapper for automatic directory switching after wt commands.

## Requirements

### Requirement: Auto-cd on Switch/Clone
The system SHALL automatically cd into the worktree after successful switch or clone.

#### Scenario: Switch with shell wrapper
- **WHEN** user runs `wt switch <ref>` with shell function loaded
- **THEN** shell captures stdout (worktree path)
- **THEN** shell cd's into that directory

#### Scenario: Clone with shell wrapper
- **WHEN** user runs `wt clone <url>` with shell function loaded
- **THEN** shell captures stdout (default worktree path)
- **THEN** shell cd's into that directory

### Requirement: Auto-cd After Remove Current
The system SHALL cd to default worktree when current directory is removed. The fallback path SHALL be resolved before the worktree is removed.

#### Scenario: Remove current worktree
- **WHEN** user runs `wt rm <name>` on current worktree
- **THEN** shell resolves default worktree path via `wt switch` before removal
- **THEN** after removal, `$PWD` no longer exists
- **THEN** shell cd's to the pre-resolved default worktree path

#### Scenario: Remove other worktree
- **WHEN** user runs `wt rm <name>` on non-current worktree
- **THEN** shell does not change directory

### Requirement: Auto-cd After Rename
The system SHALL cd into the renamed worktree after a successful rename, because the previous working directory no longer exists.

#### Scenario: Rename with shell wrapper
- **WHEN** user runs `wt rename <new-name>` with the shell function loaded
- **THEN** shell captures stdout (new worktree path)
- **THEN** shell cd's into that directory

#### Scenario: Failed rename
- **WHEN** user runs `wt rename <new-name>` and the command fails
- **THEN** shell does not change directory

### Requirement: Passthrough for Other Commands
The system SHALL pass through all other commands to the wt binary.

#### Scenario: List command
- **WHEN** user runs `wt list` with shell function loaded
- **THEN** shell calls `command wt list` directly
- **THEN** no cd occurs

#### Scenario: Help command
- **WHEN** user runs `wt help` with shell function loaded
- **THEN** shell calls `command wt help` directly

### Requirement: Shell Setup
The system SHALL provide instructions for loading the shell function.

#### Scenario: Setup instructions
- **WHEN** user reads wt.plugin.sh
- **THEN** file contains comment: `# source this in .bashrc / .zshrc`
- **THEN** user can `source /path/to/wt.plugin.sh` to enable integration
