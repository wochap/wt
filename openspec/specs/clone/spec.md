# Clone

## Purpose

Create a new wt project from a remote repository using bare clone layout.

## Requirements

### Requirement: Bare Clone Layout
The system SHALL create a bare git repository at `<dir>/.git` and a worktree for the default branch at `<dir>/<default-branch>/`.

#### Scenario: Clone with explicit directory
- **WHEN** user runs `wt clone <url> <dir>`
- **THEN** system creates `<dir>/.git` as bare repo
- **THEN** system creates worktree at `<dir>/<default-branch>/`
- **THEN** system prints layout summary to stderr
- **THEN** system prints default worktree path to stdout

#### Scenario: Clone with implicit directory
- **WHEN** user runs `wt clone <url>` without directory argument
- **THEN** system derives directory name from URL basename (stripping `.git` suffix)
- **THEN** system proceeds as explicit directory scenario

### Requirement: Default Branch Detection
The system SHALL detect the default branch in priority order: local `main`, local `master`, `origin/HEAD`, remote `main`, remote `master`.

#### Scenario: Default branch is main
- **WHEN** repository has `refs/heads/main`
- **THEN** system uses `main` as default branch

#### Scenario: Default branch is master
- **WHEN** repository has `refs/heads/master` but not `main`
- **THEN** system uses `master` as default branch

#### Scenario: Default branch from remote HEAD
- **WHEN** repository has `refs/remotes/origin/HEAD` set
- **THEN** system uses the branch pointed to by origin/HEAD

#### Scenario: No default branch detectable
- **WHEN** none of the above refs exist
- **THEN** system exits with error "cannot detect default branch"
