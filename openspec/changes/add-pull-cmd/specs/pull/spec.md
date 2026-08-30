## ADDED Requirements

### Requirement: Pull changes from a source worktree or repository
The system SHALL provide a `wt pull <source>` command that squash-applies changes from a source worktree or git repository into the current worktree.

#### Scenario: Pull from worktree folder name
- **WHEN** user runs `wt pull <name>` where `<name>` is a worktree folder in the current project
- **THEN** system resolves source to `$root/<name>` and applies changes to the current worktree

#### Scenario: Pull from path
- **WHEN** user runs `wt pull <path>` where `<path>` is a filesystem path to a git repository or worktree
- **THEN** system uses that path as the source and applies changes to the current worktree

#### Scenario: Source folder name not found
- **WHEN** user runs `wt pull <name>` and no worktree with that folder name exists in the current project
- **THEN** system SHALL fall back to treating the argument as a filesystem path

#### Scenario: Source path is not a git repository
- **WHEN** user runs `wt pull <path>` and the path is not a git repository or worktree
- **THEN** system SHALL print an error and exit non-zero

#### Scenario: No source provided
- **WHEN** user runs `wt pull` with no arguments
- **THEN** system SHALL print usage and exit non-zero

### Requirement: Same-repository verification
The system SHALL verify that source and target are the same git repository before applying changes.

#### Scenario: Same repository confirmed
- **WHEN** source and target share at least one root commit (`git rev-list --max-parents=0 HEAD`)
- **THEN** system proceeds with the pull operation

#### Scenario: Different repositories
- **WHEN** source and target share no root commits
- **THEN** system SHALL print an error indicating the repositories are unrelated and exit non-zero

### Requirement: Default squash mode
The system SHALL squash all changes since the common ancestor into the current worktree.

#### Scenario: Same-project worktrees (shared object store)
- **WHEN** source is a worktree in the same project as target
- **THEN** system SHALL use `git merge --squash` with the source branch or commit, staging the result without committing

#### Scenario: Cross-clone repositories (separate object stores)
- **WHEN** source is a git repository not sharing an object store with target
- **THEN** system SHALL find the most recent common ancestor by walking source history and checking commit existence in target, generate a diff from that ancestor to source HEAD, and apply it with `git apply`

#### Scenario: Merge conflicts in same-project mode
- **WHEN** `git merge --squash` produces conflicts
- **THEN** system SHALL display git's conflict output and exit non-zero, leaving conflict markers for manual resolution

#### Scenario: Patch failure in cross-clone mode
- **WHEN** `git apply` fails
- **THEN** system SHALL display git's error output and exit non-zero

### Requirement: Staged mode
The system SHALL support a `--staged` flag to apply only the staged changes from the source.

#### Scenario: Pull staged changes
- **WHEN** user runs `wt pull <source> --staged`
- **THEN** system SHALL generate a patch from `git diff --cached` in the source and apply it to the target with `git apply`, regardless of whether source is same-project or cross-clone

#### Scenario: Nothing staged in source
- **WHEN** user runs `wt pull <source> --staged` and source has no staged changes
- **THEN** system SHALL print an error indicating nothing is staged in source and exit non-zero

### Requirement: Dirty target confirmation
The system SHALL warn and prompt for confirmation when the target worktree has uncommitted changes.

#### Scenario: Target is dirty and user confirms
- **WHEN** target has uncommitted changes and user confirms the prompt
- **THEN** system proceeds with the pull operation

#### Scenario: Target is dirty and user declines
- **WHEN** target has uncommitted changes and user declines the prompt
- **THEN** system SHALL abort without making changes

#### Scenario: Target is clean
- **WHEN** target has no uncommitted changes
- **THEN** system proceeds without prompting
