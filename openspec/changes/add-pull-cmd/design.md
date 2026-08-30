## Context

`wt` manages git worktrees under a bare-repo layout. Worktrees within a project share one object store. Users also work across separate clones of the same repository (different remotes, different object stores). Today, moving changes between worktrees or clones requires manual git commands.

The `wt` binary is a single bash script. All commands follow the pattern: resolve project root via `find_project_root`, operate via `git -C`, print colored output to stderr, print machine-readable paths to stdout.

## Goals / Non-Goals

**Goals:**
- Single command to squash-apply changes from a source worktree/repo into the current worktree
- Handle same-project (shared objects) and cross-clone (separate objects) transparently
- Support `--staged` to pull only staged changes from source
- Verify same-repository before operating
- Preserve git's native conflict resolution where possible

**Non-Goals:**
- Preserving individual commit history (squash only)
- Bidirectional sync
- Pulling from remote URLs (local paths/names only)
- Auto-committing the result

## Decisions

### 1. Two application strategies based on object store topology

Same-project worktrees share objects → use `git merge --squash <ref>`. This gives native 3-way merge with conflict markers, no patch files.

Cross-clone repos have separate object stores → generate patch in source (`git diff base..HEAD`), apply in target (`git apply`). No `git fetch` — avoids writing to either repo's object store or refs.

`--staged` always uses patch path (`git diff --cached` from source → `git apply` in target) regardless of topology, since staged changes are index-only and not reachable via merge.

**Alternative considered:** Unify on patch for all cases. Rejected — loses 3-way merge quality for the common same-project case.

**Alternative considered:** `git fetch` for cross-clone to enable merge-base natively. Rejected — user preference to avoid any cross-repo git operations that modify object stores.

### 2. Same-repo verification via root commit comparison

Compare `git rev-list --max-parents=0 HEAD` from both repos. Any shared root commit → same repository. Content-addressed hashes make collisions practically impossible. O(1) per repo, no traversal.

For repos with multiple root commits (merged unrelated histories), compare as sets — any intersection passes.

**Alternative considered:** Compare remote URLs. Rejected — remotes can differ for the same repo.

### 3. Cross-clone merge-base via commit walk

Walk source history newest-first (`git rev-list HEAD`), check each SHA with `git cat-file -e` in target. First hit = most recent common ancestor. No fetch, no refs touched.

Then generate patch in source: `git -C <source> diff <base>..HEAD`. Apply in target: `git apply`.

Performance: proportional to divergence depth. Recent divergence → few iterations. `cat-file -e` is O(1).

### 4. Source resolution order

1. Worktree folder name in current project (`$root/<name>`, must be registered worktree)
2. Filesystem path (must be a git repository — worktree or standalone)
3. Neither → die

Folder name first since that's the common case within a wt project.

### 5. Dirty target handling

If target worktree has uncommitted changes: warn and prompt for confirmation. If user proceeds, let `git apply` / `git merge --squash` fail naturally on overlap. No preemptive blocking.

### 6. Error and conflict handling

- `git merge --squash` conflicts: git leaves conflict markers in files. Show message, exit non-zero. User resolves manually.
- `git apply` failures: show git's error output. Atomic — no partial application.
- In all cases, underlying git output goes to stderr (visible to user per project convention).

## Risks / Trade-offs

- **Cross-clone merge-base walk on deeply divergent repos** → Could iterate many commits. Mitigated: `cat-file -e` is O(1), and practical divergence is usually shallow. Could add progress output for very long walks if needed.
- **Patch apply without 3-way for cross-clone** → Less graceful conflicts than merge. Mitigated: user accepted this tradeoff; `git apply` errors are clear.
- **Root commit false negative** → Repos created with `git init` separately then connected won't share roots. Acceptable: these aren't "the same repo" in any meaningful sense.
