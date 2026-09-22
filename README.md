# wt

`wt` is a small command-line tool for managing Git worktrees as sibling
directories around a bare `.git` repository. It makes it quick to clone a
repository into this layout, create or enter worktrees, inspect their status,
remove them, and move changes between them.

## Requirements

- Bash 4 or newer
- Git
- A Unix-like environment (Linux or macOS)
- `jq` only when a project uses the optional `wt.json` configuration
- Zsh only if you want the included Zsh completions

## Installation

Clone this repository, install the executable somewhere on your `PATH`, and
install the shell integration file:

```bash
git clone <repository-url> wt-cli
cd wt-cli
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/wt"
install -m 755 wt "$HOME/.local/bin/wt"
install -m 644 wt.plugin.sh "$HOME/.local/share/wt/wt.plugin.sh"
```

Make sure `$HOME/.local/bin` is on your `PATH`. Then enable shell integration,
which lets commands such as `wt switch` change your current directory.

For Bash, add this to `~/.bashrc`:

```bash
source "$HOME/.local/share/wt/wt.plugin.sh"
```

For Zsh, add the same line to `~/.zshrc`. To enable Zsh completions, also copy
and load the completion file after `compinit`:

```bash
install -m 644 wt.completions.zsh "$HOME/.local/share/wt/wt.completions.zsh"
```

```zsh
autoload -Uz compinit && compinit
source "$HOME/.local/share/wt/wt.plugin.sh"
source "$HOME/.local/share/wt/wt.completions.zsh"
```

Restart your shell or source its configuration file, then verify the install:

```bash
wt help
```

## Usage

Start by cloning a repository with `wt`:

```bash
wt clone https://github.com/example/project.git
```

This creates a bare repository and a worktree for the default branch:

```text
project/
├── .git/       # bare repository
└── main/       # default-branch worktree
```

From any worktree in that project, common commands include:

```bash
wt switch feature/login       # create or enter a branch worktree
wt switch -b feature/new-ui    # create a new branch and worktree
wt switch                      # return to the default branch worktree
wt list                        # show all worktrees and their status
wt rename login-redesign       # rename the current worktree directory
wt pull feature/login          # squash changes into the current worktree
wt rm feature-login            # remove a worktree and its local branch
wt doctor                      # repair broken worktree links
```

Run `wt help` for the full command summary and available flags. Worktree folder
names are derived from branch names, with `/` replaced by `-`.

## Worktree configuration

An optional `wt.json` committed in the repository can select the default branch
and initialize every worktree newly created by `wt switch`. Each worktree carries
its own copy, so configuration is versioned with the branch. `wt` reads it from:

1. The worktree containing the current directory (a missing file means no
   configuration).
2. From outside any worktree, such as the project root: the default-branch
   (`main`/`master`) worktree's `wt.json`, otherwise the first existing
   worktree's.

A `wt.json` next to the bare `.git` directory is ignored. To migrate, move it
into the default branch and commit it.

```json
{
  "default_branch": "main",
  "hooks": {
    "post_create": [
      { "type": "copy", "from": ".env" },
      { "type": "copy", "from": ".config", "to": "config/local" },
      { "type": "symlink", "from": ".cache", "to": "var/cache" },
      {
        "type": "command",
        "command": "npm install",
        "work_dir": "frontend",
        "env": { "NODE_ENV": "development" }
      }
    ]
  }
}
```

`default_branch` overrides automatic `main`, `master`, and remote default-branch
detection. Copy and symlink sources are relative to the registered default-branch
worktree. Their destinations are relative to the new worktree and default to
`from`; parent directories are created, but existing destinations are never
overwritten. Symlinks use relative targets. Commands run through `/bin/sh -c`,
inherit the environment, default to the new worktree root, and may add string
environment values or select a relative `work_dir`.

All paths must be relative and cannot contain a `..` component. `jq` is required
only when `wt.json` exists, and configuration is validated before worktree
creation. Configuration and commands are trusted project-local input.

Hooks run in order only for worktrees created by `wt switch`; they do not run for
existing worktrees or `wt clone`. Copy and symlink actions are skipped when the
new worktree is itself the default worktree, while commands still run. Hook
status and command output go to stderr so successful stdout contains only the
absolute worktree path. A failed action stops the hook and makes `wt switch`
fail without printing that path, but the new worktree and branch remain and a
later switch does not retry the hook automatically.

## Software stack

- **Bash:** CLI implementation and shell integration
- **Git:** repository, branch, and worktree operations
- **Zsh:** optional command completion
- **jq:** optional `wt.json` parsing and validation
- **Shell scripts:** integration tests

The project has no build step or package manager and does not require a runtime
beyond the shell and Git.
