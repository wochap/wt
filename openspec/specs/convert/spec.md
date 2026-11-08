# Convert

## Purpose

Enables converting a standard Git repository into a wt bare repository with sibling worktree directories in-place without data loss.

## Requirements

### Requirement: Convert Repository In-Place
The system SHALL provide `wt convert` to transform a standard non-bare Git repository into a bare repository with sibling worktrees for the default branch and the currently active branch.

#### Scenario: Convert on default branch
- **WHEN** user runs `wt convert` in a standard Git repository checked out at the default branch (`main`)
- **THEN** the root repository configuration is set to `core.bare = true`
- **THEN** a worktree is created at `<repo-root>/main` checked out at `main`
- **THEN** stdout prints the absolute path to `<repo-root>/main`
- **THEN** stderr displays a summary of the converted structure

#### Scenario: Convert on feature branch
- **WHEN** user runs `wt convert` in a standard Git repository checked out at a feature branch (`feature/login`)
- **THEN** the root repository configuration is set to `core.bare = true`
- **THEN** a worktree is created at `<repo-root>/main` checked out at the default branch
- **THEN** a worktree is created at `<repo-root>/feature-login` checked out at `feature/login`
- **THEN** stdout prints the absolute path to `<repo-root>/feature-login`

### Requirement: In-Place Staging and Zero Data Loss
The system SHALL stage working copy contents inside `.git/.wt-convert-staging` via atomic rename before converting to bare, ensuring zero data loss and O(1) performance.

#### Scenario: Staging untracked and ignored files
- **WHEN** `wt convert` executes
- **THEN** all files and directories in repository root except `.git` are moved into `.git/.wt-convert-staging/`
- **THEN** after worktree creation, all untracked and ignored files are restored to the active worktree
- **THEN** config files (such as `.env*`) are copied to the default branch worktree if the active branch is different
- **THEN** `.git/.wt-convert-staging` is cleaned up upon completion

### Requirement: Auto-Stash Dirty Working Tree
The system SHALL automatically stash uncommitted changes to tracked files before conversion and re-apply them to the active worktree after conversion.

#### Scenario: Dirty working tree conversion
- **WHEN** user runs `wt convert` with uncommitted changes in tracked files
- **THEN** changes are stashed automatically via `git stash push -m "wt convert auto-stash"`
- **THEN** after worktree creation and file restoration, the stash is popped inside the active worktree

### Requirement: Pre-flight Verification and Guardrails
The system SHALL validate repository prerequisites and abort before modifying files if safety checks fail.

#### Scenario: Repository with no commits
- **WHEN** user runs `wt convert` in an empty repository with no commits (`HEAD` cannot be resolved)
- **THEN** the command aborts with a non-zero exit code and an error message indicating no commits exist

#### Scenario: Detached HEAD state
- **WHEN** user runs `wt convert` in detached HEAD state
- **THEN** the command aborts with a non-zero exit code and prompts the user to check out a branch first

#### Scenario: In-progress Git operation
- **WHEN** user runs `wt convert` while a merge, rebase, revert, or cherry-pick is in progress
- **THEN** the command aborts with a non-zero exit code advising the user to complete or abort the operation first

#### Scenario: Already a wt project or worktree
- **WHEN** user runs `wt convert` in an already bare repository or inside a linked worktree
- **THEN** the command aborts with a non-zero exit code and explains the repository cannot be converted
