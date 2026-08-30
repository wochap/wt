## MODIFIED Requirements

### Requirement: Auto-cd on Switch/Clone
The system SHALL automatically cd into the worktree after successful switch or clone.

#### Scenario: Switch with shell wrapper
- **WHEN** user runs `wt switch <ref>` with shell function loaded
- **THEN** shell captures stdout (single-line worktree path)
- **THEN** shell cd's into that directory

#### Scenario: Clone with shell wrapper
- **WHEN** user runs `wt clone <url>` with shell function loaded
- **THEN** shell captures stdout (single-line default worktree path)
- **THEN** shell cd's into that directory

#### Scenario: Stdout is clean single line
- **WHEN** `wt clone` or `wt switch` creates a new worktree
- **THEN** stdout contains only the worktree path (no git progress messages)
- **THEN** shell wrapper cd succeeds without "no such file or directory" error
