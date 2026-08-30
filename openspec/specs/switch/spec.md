# Switch

## Purpose

Switch to or create worktrees for branches, commits, or the default branch.

## Requirements

### Requirement: Switch to Default Branch
The system SHALL switch to the default branch worktree when no arguments provided. Creation messages SHALL include color styling.

#### Scenario: Default worktree exists
- **WHEN** user runs `wt switch` with no arguments
- **THEN** system finds existing worktree for default branch
- **THEN** system prints worktree path to stdout (no color)

#### Scenario: Default worktree missing
- **WHEN** user runs `wt switch` and default worktree doesn't exist
- **THEN** system creates worktree at `<root>/<default-branch>/`
- **THEN** system prints creation message to stderr with branch name in cyan and directory name in green
- **THEN** system prints worktree path to stdout

### Requirement: Switch to Ref
The system SHALL switch to a worktree for the given ref, creating one if needed. Creation messages SHALL include color styling.

#### Scenario: Existing worktree for branch
- **WHEN** user runs `wt switch <branch>` and worktree exists for that branch
- **THEN** system prints existing worktree path to stdout (no color)

#### Scenario: Create worktree for local branch
- **WHEN** user runs `wt switch <branch>` and no worktree exists
- **THEN** system creates worktree at `<root>/<branch>/` (slashes flattened to dashes)
- **THEN** system prints creation message to stderr with branch name in cyan and directory name in green

#### Scenario: Create worktree for remote branch
- **WHEN** user runs `wt switch <remote-branch>` and remote exists
- **THEN** system creates worktree tracking the remote branch
- **THEN** system prints creation message to stderr with branch name in cyan and directory name in green

#### Scenario: Create detached worktree for commit
- **WHEN** user runs `wt switch <commit>`
- **THEN** system creates detached worktree named by 8-char commit hash
- **THEN** system prints creation message to stderr with commit hash in yellow and directory name in green

#### Scenario: Named detached worktree
- **WHEN** user runs `wt switch <ref> <name>`
- **THEN** system creates detached worktree at `<root>/<name>/`
- **THEN** system prints creation message to stderr with directory name in green

### Requirement: Create New Branch
The system SHALL create a new branch and worktree with `-b` flag. The `-b` flag SHALL be recognized in any argument position. Creation messages SHALL include color styling.

#### Scenario: Create new branch from HEAD
- **WHEN** user runs `wt switch -b <branch>`
- **THEN** system creates new branch from HEAD
- **THEN** system creates worktree at `<root>/<branch>/`
- **THEN** system prints creation message to stderr with branch name in cyan and directory name in green

#### Scenario: Create new branch with flag after branch name
- **WHEN** user runs `wt switch <branch> -b`
- **THEN** system creates new branch from HEAD (same behavior as `wt switch -b <branch>`)
- **THEN** system creates worktree at `<root>/<branch>/`
- **THEN** system prints creation message to stderr with branch name in cyan and directory name in green

#### Scenario: Create new branch from specific ref
- **WHEN** user runs `wt switch -b <branch> <from>`
- **THEN** system creates new branch from `<from>`
- **THEN** system creates worktree at `<root>/<branch>/`
- **THEN** system prints creation message to stderr with branch name in cyan, directory name in green, and source ref in yellow

#### Scenario: Create new branch from specific ref with flag after branch name
- **WHEN** user runs `wt switch <branch> -b <from>`
- **THEN** system creates new branch from `<from>` (same behavior as `wt switch -b <branch> <from>`)
- **THEN** system creates worktree at `<root>/<branch>/`
- **THEN** system prints creation message to stderr with branch name in cyan, directory name in green, and source ref in yellow

#### Scenario: Branch already exists
- **WHEN** user runs `wt switch -b <branch>` and branch exists
- **THEN** system exits with error "branch already exists"

#### Scenario: Directory already exists
- **WHEN** user runs `wt switch -b <branch>` and target directory exists
- **THEN** system exits with error "directory already exists"

### Requirement: Directory Naming
The system SHALL name worktree directories according to ref type and optional name.

#### Scenario: Branch without name
- **WHEN** switching to branch without explicit name
- **THEN** directory name is branch name with slashes flattened to dashes

#### Scenario: Branch with name
- **WHEN** switching to branch with explicit name
- **THEN** directory name is `<branch>-<name>`

#### Scenario: Commit without name
- **WHEN** switching to commit without explicit name
- **THEN** directory name is 8-char commit hash

#### Scenario: Commit with name
- **WHEN** switching to commit with explicit name
- **THEN** directory name is the explicit name

### Requirement: Unknown Ref Handling
The system SHALL reject unknown refs with an error.

#### Scenario: Ref not found
- **WHEN** user runs `wt switch <ref>` and ref doesn't match any local branch, remote branch, or commit
- **THEN** system exits with error "unknown ref"
