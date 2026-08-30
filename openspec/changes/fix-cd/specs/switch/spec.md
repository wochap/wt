## MODIFIED Requirements

### Requirement: Switch to Default Branch
The system SHALL switch to the default branch worktree when no arguments provided.

#### Scenario: Default worktree exists
- **WHEN** user runs `wt switch` with no arguments
- **THEN** system finds existing worktree for default branch
- **THEN** system prints worktree path as the only line on stdout

#### Scenario: Default worktree missing
- **WHEN** user runs `wt switch` and default worktree doesn't exist
- **THEN** system creates worktree at `<root>/<default-branch>/`
- **THEN** system prints creation message to stderr
- **THEN** system prints worktree path as the only line on stdout

### Requirement: Switch to Ref
The system SHALL switch to a worktree for the given ref, creating one if needed.

#### Scenario: Existing worktree for branch
- **WHEN** user runs `wt switch <branch>` and worktree exists for that branch
- **THEN** system prints existing worktree path as the only line on stdout

#### Scenario: Create worktree for local branch
- **WHEN** user runs `wt switch <branch>` and no worktree exists
- **THEN** system creates worktree at `<root>/<branch>/` (slashes flattened to dashes)
- **THEN** system prints creation message to stderr
- **THEN** system prints worktree path as the only line on stdout

#### Scenario: Create worktree for remote branch
- **WHEN** user runs `wt switch <remote-branch>` and remote exists
- **THEN** system creates worktree tracking the remote branch
- **THEN** system prints creation message to stderr
- **THEN** system prints worktree path as the only line on stdout

#### Scenario: Create detached worktree for commit
- **WHEN** user runs `wt switch <commit>`
- **THEN** system creates detached worktree named by 8-char commit hash
- **THEN** system prints creation message to stderr
- **THEN** system prints worktree path as the only line on stdout

#### Scenario: Named detached worktree
- **WHEN** user runs `wt switch <ref> <name>`
- **THEN** system creates detached worktree at `<root>/<name>/`
- **THEN** system prints creation message to stderr
- **THEN** system prints worktree path as the only line on stdout

#### Scenario: Stdout contains only path on create
- **WHEN** user runs `wt switch <ref>` and captures stdout
- **THEN** stdout contains exactly one line: the absolute worktree path
- **THEN** git progress messages appear on stderr, not stdout

### Requirement: Create New Branch
The system SHALL create a new branch and worktree with `-b` flag.

#### Scenario: Create new branch from HEAD
- **WHEN** user runs `wt switch -b <branch>`
- **THEN** system creates new branch from HEAD
- **THEN** system creates worktree at `<root>/<branch>/`
- **THEN** system prints creation message to stderr
- **THEN** system prints worktree path as the only line on stdout

#### Scenario: Create new branch from specific ref
- **WHEN** user runs `wt switch -b <branch> <from>`
- **THEN** system creates new branch from `<from>`
- **THEN** system creates worktree at `<root>/<branch>/`
- **THEN** system prints worktree path as the only line on stdout

#### Scenario: Branch already exists
- **WHEN** user runs `wt switch -b <branch>` and branch exists
- **THEN** system exits with error "branch already exists"

#### Scenario: Directory already exists
- **WHEN** user runs `wt switch -b <branch>` and target directory exists
- **THEN** system exits with error "directory already exists"
