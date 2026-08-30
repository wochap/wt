## MODIFIED Requirements

### Requirement: Table Output
The system SHALL display worktrees in a formatted table with columns: Branch, Status, HEAD±, Path, Commit, Age, Message.

#### Scenario: List multiple worktrees
- **WHEN** user runs `wt list`
- **THEN** system displays header row with column names
- **THEN** system displays one row per worktree
- **THEN** system displays footer with worktree count

#### Scenario: Current worktree indicator
- **WHEN** a worktree is the current working directory
- **THEN** that row shows `@` in gutter column
- **THEN** Path column shows `.` instead of full path

#### Scenario: Other worktrees
- **WHEN** a worktree is not the current directory
- **THEN** that row shows space in gutter column
- **THEN** Path column shows path relative to project root

#### Scenario: Paths with symlinks in project root
- **WHEN** project root contains symlinks in its path
- **THEN** system resolves project root to physical path (symlinks resolved)
- **THEN** Path column correctly strips root prefix and shows relative paths
- **THEN** Path column does NOT show absolute paths
