# Clone

## Purpose

Create a new wt project from a remote repository using bare clone layout.

## Requirements

### Requirement: Bare Clone Layout
The system SHALL create a bare git repository at `<dir>/.git`, configure `origin` to fetch remote branches into `refs/remotes/origin/*`, fetch the remote-tracking refs, configure the default local branch to track `origin/<default-branch>`, and create a worktree for that branch at `<dir>/<default-branch>/`. The tracking configuration and upstream assignment MUST be complete before the default worktree is created. Success messages SHALL include color styling.

#### Scenario: Clone with explicit directory
- **WHEN** user runs `wt clone <url> <dir>`
- **THEN** system creates `<dir>/.git` as bare repo
- **THEN** system configures the `origin` fetch refspec as `+refs/heads/*:refs/remotes/origin/*`
- **THEN** system fetches `origin` and creates `refs/remotes/origin/*`
- **THEN** system configures the default local branch to track `origin/<default-branch>`
- **THEN** system creates worktree at `<dir>/<default-branch>/`
- **THEN** system prints layout summary to stderr with directory paths in green and `.git` label in dim
- **THEN** system prints default worktree path to stdout (no color)

#### Scenario: Clone with implicit directory
- **WHEN** user runs `wt clone <url>` without directory argument
- **THEN** system derives directory name from URL basename (stripping `.git` suffix)
- **THEN** system proceeds as explicit directory scenario

#### Scenario: Remote-tracking fetch fails
- **WHEN** fetching `origin` fails during clone setup
- **THEN** system exits with error "failed to configure remote tracking"
- **THEN** system does not create the default branch worktree

#### Scenario: Default branch upstream configuration fails
- **WHEN** assigning `origin/<default-branch>` as the default local branch upstream fails
- **THEN** system exits with error "failed to configure upstream"
- **THEN** system does not create the default branch worktree

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
