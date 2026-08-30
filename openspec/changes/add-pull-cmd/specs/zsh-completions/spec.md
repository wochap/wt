## MODIFIED Requirements

### Requirement: Subcommand Completion
The system SHALL provide tab-completion for wt subcommands.

#### Scenario: Complete subcommands
- **WHEN** user types `wt <TAB>`
- **THEN** zsh suggests: `clone`, `switch`, `list`, `rm`, `doctor`, `pull`, `help`

## ADDED Requirements

### Requirement: Pull Flag Completion
The system SHALL complete flags for `wt pull`.

#### Scenario: Complete pull flags
- **WHEN** user types `wt pull --<TAB>`
- **THEN** zsh suggests: `--staged`

### Requirement: Pull Source Completion
The system SHALL complete worktree directory names for `wt pull`.

#### Scenario: Complete worktree names for pull
- **WHEN** user types `wt pull <TAB>` inside a wt project
- **THEN** zsh suggests worktree directory names (relative to project root)
