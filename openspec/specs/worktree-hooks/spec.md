# Worktree Hooks

## Purpose

TBD: Define post-creation actions for newly created worktrees.

## Requirements

### Requirement: Run Post-Create Actions in Order
The system SHALL execute `hooks.post_create` actions in their configured order after `wt switch` successfully creates a worktree. It SHALL NOT execute the hook when switching to an existing worktree or when `wt clone` creates its initial worktree.

#### Scenario: Newly created worktree
- **WHEN** any `wt switch` path successfully creates a worktree and `post_create` actions are configured
- **THEN** the system executes each action in listed order against the new worktree

#### Scenario: Existing worktree
- **WHEN** `wt switch` resolves an already registered worktree
- **THEN** the system does not execute `post_create`

#### Scenario: Clone creates initial worktree
- **WHEN** `wt clone` creates the default worktree
- **THEN** the system does not execute `post_create`

### Requirement: Copy from the Default Worktree
The `copy` action SHALL copy a file or directory from the registered default-branch worktree into the new worktree. `from` SHALL be relative to the default worktree, and `to` SHALL be relative to the new worktree and default to the value of `from` when omitted.

#### Scenario: Copy file with default destination
- **WHEN** a `copy` action specifies `from` as `.env` and omits `to`
- **THEN** the system copies `<default-worktree>/.env` to `<new-worktree>/.env`

#### Scenario: Copy directory to explicit destination
- **WHEN** a `copy` action specifies a source directory and a distinct `to` path
- **THEN** the system recursively copies the source to that destination in the new worktree

#### Scenario: Copy source missing
- **WHEN** the configured copy source does not exist
- **THEN** the action fails with a clear error

#### Scenario: Copy destination exists
- **WHEN** the configured copy destination already exists
- **THEN** the action fails without overwriting the destination

### Requirement: Create Relative Links to the Default Worktree
The `symlink` action SHALL create a symbolic link in the new worktree whose target is expressed relative to the link's parent and resolves to the configured source in the registered default-branch worktree. `from` SHALL be relative to the default worktree, and `to` SHALL default to `from` when omitted.

#### Scenario: Link at worktree root
- **WHEN** `.bin` is linked from a sibling default worktree to `.bin` in a new worktree
- **THEN** the created link uses an equivalent relative target such as `../main/.bin`

#### Scenario: Nested link destination
- **WHEN** a symlink action uses a nested destination
- **THEN** the target is calculated relative to the nested destination's parent

#### Scenario: Link destination exists
- **WHEN** the configured symlink destination already exists
- **THEN** the action fails without replacing the destination

### Requirement: Execute Commands in the New Worktree
The `command` action SHALL execute its command through `/bin/sh -c` with the new worktree as its default working directory. It SHALL augment the inherited environment with configured `env` string values and SHALL resolve an optional `work_dir` relative to the new worktree.

#### Scenario: Command with environment
- **WHEN** a command action declares environment variables
- **THEN** the command receives those values in addition to the inherited environment

#### Scenario: Command with working directory
- **WHEN** a command action declares `work_dir`
- **THEN** the command runs in that directory beneath the new worktree

#### Scenario: Command exits nonzero
- **WHEN** a command returns a nonzero status
- **THEN** the action and hook fail with that failure reported to the user

### Requirement: Confine Action Paths
The system SHALL reject absolute `from`, `to`, and `work_dir` values and relative values that escape their respective worktree through parent traversal.

#### Scenario: Absolute action path
- **WHEN** an action contains an absolute filesystem path
- **THEN** configuration validation fails before worktree creation

#### Scenario: Escaping action path
- **WHEN** an action path would resolve outside its source or destination worktree
- **THEN** configuration validation fails before worktree creation

### Requirement: Handle Default Worktree as Both Source and Destination
When `wt switch` creates the configured default branch worktree, the system SHALL skip `copy` and `symlink` actions because the source and destination worktrees are identical, while continuing to execute command actions.

#### Scenario: Default worktree recreated
- **WHEN** `wt switch` creates the configured default branch worktree
- **THEN** copy and symlink actions are skipped with an informational message
- **THEN** command actions execute normally in the created default worktree

### Requirement: Preserve a Worktree After Hook Failure
If a post-create action fails, the system SHALL stop executing later actions, return a nonzero status, and leave the newly created worktree and branch intact. A later switch to that existing worktree SHALL NOT automatically rerun the hook.

#### Scenario: Middle action fails
- **WHEN** a post-create action fails after the worktree has been created
- **THEN** no subsequent action executes
- **THEN** the new worktree and branch remain available
- **THEN** `wt switch` exits nonzero

#### Scenario: Switch after prior hook failure
- **WHEN** a later `wt switch` resolves the retained worktree
- **THEN** the system returns that worktree without rerunning `post_create`

### Requirement: Preserve Machine-Readable Switch Output
The system SHALL reserve successful `wt switch` stdout for the single absolute worktree path and route post-create action output and status messages to stderr.

#### Scenario: Command writes standard output
- **WHEN** a successful hook command writes to stdout
- **THEN** the command output is presented through `wt switch` stderr
- **THEN** successful `wt switch` stdout contains only the absolute worktree path
