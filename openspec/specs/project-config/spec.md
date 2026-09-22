# Project Config

## Purpose

Define optional, repository-tracked configuration for wt behavior.

## Requirements

### Requirement: Discover Optional Project Configuration
The system SHALL read `wt.json` from the worktree containing the current directory. When the current directory is outside every worktree, the system SHALL read `wt.json` from the default-branch worktree, and otherwise from the first existing worktree. The system SHALL ignore a `wt.json` in the wt project root. When no applicable file exists, the system SHALL retain its current behavior without requiring `jq`.

#### Scenario: Configuration absent
- **WHEN** a user runs `wt switch` and the applicable worktree has no `wt.json`
- **THEN** the system operates using its existing default-branch detection and worktree creation behavior
- **THEN** the system does not require `jq`

#### Scenario: Configuration present in current worktree
- **WHEN** a user runs `wt switch` inside a worktree, or a subdirectory of it, that contains `wt.json`
- **THEN** the system parses that file as JSON using `jq`
- **THEN** the system ignores `wt.json` files in other worktrees

#### Scenario: Run from project root
- **WHEN** a user runs `wt switch` from the project root and the default-branch worktree contains `wt.json`
- **THEN** the system uses the default-branch worktree's `wt.json`

#### Scenario: Run from project root without default worktree configuration
- **WHEN** a user runs `wt switch` from the project root and the default-branch worktree is missing or has no `wt.json`
- **THEN** the system uses `wt.json` from the first existing worktree, if present

#### Scenario: Legacy root configuration
- **WHEN** a `wt.json` exists in the wt project root next to the bare `.git` directory
- **THEN** the system ignores that file

### Requirement: Validate Project Configuration Before Creation
The system SHALL validate a present `wt.json` and the configuration fields used by `wt switch` before creating a worktree. The system SHALL report a clear error for malformed JSON, unsupported hook actions, invalid field types, or an unavailable `jq` executable.

#### Scenario: Malformed configuration
- **WHEN** `wt.json` contains malformed JSON
- **THEN** `wt switch` exits with an error before creating a worktree

#### Scenario: jq unavailable
- **WHEN** `wt.json` exists and `jq` is not available
- **THEN** `wt switch` exits with an error that identifies `jq` as required
- **THEN** no worktree is created

#### Scenario: Invalid hook action
- **WHEN** a configured `post_create` action has an unsupported type or invalid required fields
- **THEN** `wt switch` exits with an error before creating a worktree

### Requirement: Configure the Default Branch
The system SHALL use the non-empty string `default_branch` from `wt.json` as the project's default branch when present. When it is absent, the system SHALL use existing automatic default-branch detection.

#### Scenario: Configured default branch
- **WHEN** `wt.json` contains a valid `default_branch`
- **THEN** argument-free `wt switch` resolves that branch as the default

#### Scenario: Default branch option absent
- **WHEN** `wt.json` does not contain `default_branch`
- **THEN** the system detects the default branch using its existing fallback order

#### Scenario: Configured branch does not exist
- **WHEN** `default_branch` names neither a local nor an origin branch
- **THEN** argument-free `wt switch` exits with a clear error
