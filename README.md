# wt

`wt` manages sibling Git worktrees around a bare `.git` repository. See `wt help`
for commands and shell setup.

## Worktree configuration

An optional `wt.json` in the project root can select the default branch and
initialize every worktree newly created by `wt switch`:

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
