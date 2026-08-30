## MODIFIED Requirements

### Requirement: Bare Clone Layout
The system SHALL create a bare git repository at `<dir>/.git` and a worktree for the default branch at `<dir>/<default-branch>/`.

#### Scenario: Clone with explicit directory
- **WHEN** user runs `wt clone <url> <dir>`
- **THEN** system creates `<dir>/.git` as bare repo
- **THEN** system creates worktree at `<dir>/<default-branch>/`
- **THEN** system prints layout summary to stderr
- **THEN** system prints default worktree path as the only line on stdout

#### Scenario: Clone with implicit directory
- **WHEN** user runs `wt clone <url>` without directory argument
- **THEN** system derives directory name from URL basename (stripping `.git` suffix)
- **THEN** system proceeds as explicit directory scenario

#### Scenario: Stdout contains only path
- **WHEN** user runs `wt clone <url>` and captures stdout
- **THEN** stdout contains exactly one line: the absolute worktree path
- **THEN** git progress messages ("Preparing worktree", "HEAD is now at") appear on stderr, not stdout
