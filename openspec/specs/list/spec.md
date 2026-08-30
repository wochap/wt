# List

## Purpose

Display all worktrees with status information in a formatted table.

## Requirements

### Requirement: Table Output
The system SHALL display worktrees in a formatted table with columns: Branch, Status, HEAD±, Path, Commit, Age, Message. Column headers SHALL be rendered in bold. Each column value SHALL use its designated color.

#### Scenario: List multiple worktrees
- **WHEN** user runs `wt list`
- **THEN** system displays header row with column names in bold
- **THEN** system displays one row per worktree with colored values
- **THEN** system displays footer with worktree count

#### Scenario: Current worktree indicator
- **WHEN** a worktree is the current working directory
- **THEN** that row shows `@` in gutter column in bold green
- **THEN** Path column shows `.` instead of full path

#### Scenario: Other worktrees
- **WHEN** a worktree is not the current directory
- **THEN** that row shows space in gutter column
- **THEN** Path column shows path relative to project root

### Requirement: Status Column
The system SHALL show clean/dirty status for each worktree with color.

#### Scenario: Clean worktree
- **WHEN** worktree has no uncommitted changes
- **THEN** Status column shows `✓` in green

#### Scenario: Dirty worktree
- **WHEN** worktree has uncommitted changes
- **THEN** Status column shows `M` in yellow

### Requirement: HEAD± Column
The system SHALL show uncommitted diff stats relative to HEAD.

#### Scenario: Worktree with changes
- **WHEN** worktree has staged or unstaged changes
- **THEN** HEAD± column shows `+N-M` format (additions/deletions)

#### Scenario: Clean worktree
- **WHEN** worktree matches HEAD
- **THEN** HEAD± column is empty

### Requirement: Branch Column
The system SHALL show branch name or detached indicator in cyan.

#### Scenario: Attached worktree
- **WHEN** worktree is on a branch
- **THEN** Branch column shows branch name in cyan

#### Scenario: Detached worktree
- **WHEN** worktree is in detached HEAD state
- **THEN** Branch column shows `(detached)` in cyan

### Requirement: Parallel Data Collection
The system SHALL collect git log, status, and diff data in parallel for performance.

#### Scenario: Multiple worktrees
- **WHEN** listing multiple worktrees
- **THEN** system spawns background jobs per worktree
- **THEN** system waits for all jobs to complete
- **THEN** system aggregates results into table

### Requirement: Message Truncation
The system SHALL truncate commit messages to fit terminal width.

#### Scenario: Long commit message
- **WHEN** commit message would exceed terminal width
- **THEN** system truncates message to fit within `tput cols`

### Requirement: Footer Count
The system SHALL display total worktree count with dim styling.

#### Scenario: Multiple worktrees
- **WHEN** listing N worktrees where N > 1
- **THEN** footer shows `○ N worktrees` with `○` in dim

#### Scenario: Single worktree
- **WHEN** listing 1 worktree
- **THEN** footer shows `○ 1 worktree` with `○` in dim
