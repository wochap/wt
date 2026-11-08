#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
WT_BIN=${WT_BIN:-$ROOT/wt}
PLUGIN_SH="$ROOT/wt.plugin.sh"
COMPLETIONS_ZSH="$ROOT/wt.completions.zsh"
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

export NO_COLOR=1
export GIT_CONFIG_GLOBAL=/dev/null

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [[ -f "$1" ]] || fail "expected file: $1"; }
assert_dir() { [[ -d "$1" ]] || fail "expected dir: $1"; }
assert_not_exists() { [[ ! -e "$1" && ! -L "$1" ]] || fail "expected not to exist: $1"; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "expected '$2' in '$1'"; }

init_repo() {
  local dir="$1" branch="${2:-main}"
  mkdir -p "$dir"
  git -C "$dir" init -q -b "$branch"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name Test
  git -C "$dir" config commit.gpgsign false
}

echo "=== Test 1: Clean conversion on default branch ==="
repo1="$TEST_TMP/repo1"
init_repo "$repo1" main
printf 'hello world\n' >"$repo1/hello.txt"
git -C "$repo1" add hello.txt
git -C "$repo1" commit -qm "initial commit"

out1=$(cd "$repo1" && "$WT_BIN" convert 2>"$TEST_TMP/repo1.err")
[[ "$out1" == "$repo1/main" ]] || fail "expected stdout to be $repo1/main, got: $out1"
err1=$(<"$TEST_TMP/repo1.err")
assert_contains "$err1" "Converted repository into bare + worktrees layout"
assert_contains "$err1" "main/"

assert_dir "$repo1/.git"
assert_dir "$repo1/main"
assert_file "$repo1/main/hello.txt"
assert_not_exists "$repo1/hello.txt"
[[ "$(git -C "$repo1/.git" rev-parse --is-bare-repository)" == "true" ]] || fail "expected bare repository"

# Verify wt list works inside converted repo
list1=$(cd "$repo1/main" && "$WT_BIN" list)
assert_contains "$list1" "main"

echo "=== Test 2: Feature branch conversion (active != default) ==="
repo2="$TEST_TMP/repo2"
init_repo "$repo2" main
printf 'main file\n' >"$repo2/file.txt"
git -C "$repo2" add file.txt
git -C "$repo2" commit -qm "main commit"

git -C "$repo2" checkout -q -b "feature/login"
printf 'login feature\n' >"$repo2/login.txt"
git -C "$repo2" add login.txt
git -C "$repo2" commit -qm "feature commit"

out2=$(cd "$repo2" && "$WT_BIN" convert 2>"$TEST_TMP/repo2.err")
[[ "$out2" == "$repo2/feature-login" ]] || fail "expected stdout to be $repo2/feature-login, got: $out2"
err2=$(<"$TEST_TMP/repo2.err")
assert_contains "$err2" "main/"
assert_contains "$err2" "feature-login/"

assert_dir "$repo2/main"
assert_dir "$repo2/feature-login"
assert_file "$repo2/main/file.txt"
assert_not_exists "$repo2/main/login.txt"
assert_file "$repo2/feature-login/file.txt"
assert_file "$repo2/feature-login/login.txt"

# Verify wt list shows both
list2=$(cd "$repo2/feature-login" && "$WT_BIN" list)
assert_contains "$list2" "main"
assert_contains "$list2" "feature/login"

echo "=== Test 3: Auto-stash with uncommitted tracked changes ==="
repo3="$TEST_TMP/repo3"
init_repo "$repo3" main
printf 'base content\n' >"$repo3/tracked.txt"
git -C "$repo3" add tracked.txt
git -C "$repo3" commit -qm "initial commit"

git -C "$repo3" checkout -q -b "feature/work"
printf 'work content\n' >>"$repo3/tracked.txt"
git -C "$repo3" commit -aqm "work commit"

# Make uncommitted tracked modifications
printf 'uncommitted changes\n' >>"$repo3/tracked.txt"

out3=$(cd "$repo3" && "$WT_BIN" convert 2>"$TEST_TMP/repo3.err")
[[ "$out3" == "$repo3/feature-work" ]] || fail "expected stdout $repo3/feature-work"
assert_contains "$(<"$repo3/feature-work/tracked.txt")" "uncommitted changes"

# Verify stash was dropped (auto-stash popped)
stash_list3=$(git -C "$repo3/feature-work" stash list)
[[ -z "$stash_list3" ]] || fail "expected empty stash list, got: $stash_list3"

echo "=== Test 4: Pre-existing stashes preservation ==="
repo4="$TEST_TMP/repo4"
init_repo "$repo4" main
printf 'init\n' >"$repo4/tracked.txt"
git -C "$repo4" add tracked.txt
git -C "$repo4" commit -qm "initial commit"

# Create pre-existing stash
printf 'old stash work\n' >"$repo4/tracked.txt"
git -C "$repo4" stash push -m "user-stash"

# Create another uncommitted change
printf 'current uncommitted\n' >"$repo4/tracked.txt"

out4=$(cd "$repo4" && "$WT_BIN" convert 2>/dev/null)
[[ "$out4" == "$repo4/main" ]] || fail "expected stdout $repo4/main"
assert_contains "$(<"$repo4/main/tracked.txt")" "current uncommitted"

# Verify pre-existing stash still intact
stash_list4=$(git -C "$repo4/main" stash list)
assert_contains "$stash_list4" "user-stash"

echo "=== Test 5: Untracked and ignored files restoration & config isolation ==="
repo5="$TEST_TMP/repo5"
init_repo "$repo5" main
printf 'tracked\n' >"$repo5/tracked.txt"
printf 'node_modules/\n.venv/\n' >"$repo5/.gitignore"
git -C "$repo5" add tracked.txt .gitignore
git -C "$repo5" commit -qm "initial commit"

git -C "$repo5" checkout -q -b "feature/app"
# Bulky ignored directories
mkdir -p "$repo5/node_modules/my-pkg" "$repo5/.venv/bin" "$repo5/src" "$repo5/.config"
printf 'pkg code\n' >"$repo5/node_modules/my-pkg/index.js"
printf 'venv binary\n' >"$repo5/.venv/bin/python"

# Untracked files
printf 'untracked notes\n' >"$repo5/notes.txt"
printf 'untracked src\n' >"$repo5/src/temp.txt"

# Lightweight config files
printf 'SECRET=abc\n' >"$repo5/.env"
printf 'SECRET=local\n' >"$repo5/.env.local"
printf '{"key": "val"}\n' >"$repo5/.config/settings.json"
printf 'nodejs 20.0.0\n' >"$repo5/.tool-versions"

out5=$(cd "$repo5" && "$WT_BIN" convert 2>/dev/null)
[[ "$out5" == "$repo5/feature-app" ]] || fail "expected stdout $repo5/feature-app"

# Active worktree should have all untracked and ignored items
assert_file "$repo5/feature-app/node_modules/my-pkg/index.js"
assert_file "$repo5/feature-app/.venv/bin/python"
assert_file "$repo5/feature-app/notes.txt"
assert_file "$repo5/feature-app/src/temp.txt"
assert_file "$repo5/feature-app/.env"
assert_file "$repo5/feature-app/.env.local"
assert_file "$repo5/feature-app/.config/settings.json"
assert_file "$repo5/feature-app/.tool-versions"

# Default worktree should have copied lightweight configs
assert_file "$repo5/main/.env"
assert_file "$repo5/main/.env.local"
assert_file "$repo5/main/.config/settings.json"
assert_file "$repo5/main/.tool-versions"

# Default worktree should NOT have bulky directories or general untracked files
assert_not_exists "$repo5/main/node_modules"
assert_not_exists "$repo5/main/.venv"
assert_not_exists "$repo5/main/notes.txt"
assert_not_exists "$repo5/main/src/temp.txt"

# Staging directory must be cleaned up
assert_not_exists "$repo5/.git/.wt-convert-staging"

echo "=== Test 6: Override default branch with --default ==="
repo6="$TEST_TMP/repo6"
init_repo "$repo6" develop
printf 'code\n' >"$repo6/code.txt"
git -C "$repo6" add code.txt
git -C "$repo6" commit -qm "initial commit"
git -C "$repo6" checkout -q -b "feature/test"

out6=$(cd "$repo6" && "$WT_BIN" convert --default develop 2>/dev/null)
[[ "$out6" == "$repo6/feature-test" ]] || fail "expected stdout $repo6/feature-test"
assert_dir "$repo6/develop"
assert_dir "$repo6/feature-test"

echo "=== Test 7: Pre-flight failure modes ==="
# 7a. Not inside git repo
non_git="$TEST_TMP/non-git"
mkdir -p "$non_git"
if (cd "$non_git" && "$WT_BIN" convert >/dev/null 2>"$TEST_TMP/err_non_git"); then
  fail "convert should fail in non-git directory"
fi
assert_contains "$(<"$TEST_TMP/err_non_git")" "not inside a git repository"

# 7b. Empty repository (0 commits)
empty_repo="$TEST_TMP/empty-repo"
init_repo "$empty_repo" main
if (cd "$empty_repo" && "$WT_BIN" convert >/dev/null 2>"$TEST_TMP/err_empty"); then
  fail "convert should fail in empty repository"
fi
assert_contains "$(<"$TEST_TMP/err_empty")" "repository has no commits"

# 7c. Detached HEAD
detached_repo="$TEST_TMP/detached-repo"
init_repo "$detached_repo" main
printf 'commit\n' >"$detached_repo/f.txt"
git -C "$detached_repo" add f.txt
git -C "$detached_repo" commit -qm "c1"
sha=$(git -C "$detached_repo" rev-parse HEAD)
git -C "$detached_repo" checkout -q "$sha"
if (cd "$detached_repo" && "$WT_BIN" convert >/dev/null 2>"$TEST_TMP/err_detached"); then
  fail "convert should fail in detached HEAD"
fi
assert_contains "$(<"$TEST_TMP/err_detached")" "detached HEAD"

# 7d. In-progress merge
merge_repo="$TEST_TMP/merge-repo"
init_repo "$merge_repo" main
printf 'c1\n' >"$merge_repo/f.txt"
git -C "$merge_repo" add f.txt
git -C "$merge_repo" commit -qm "c1"
touch "$merge_repo/.git/MERGE_HEAD"
if (cd "$merge_repo" && "$WT_BIN" convert >/dev/null 2>"$TEST_TMP/err_merge"); then
  fail "convert should fail with merge in progress"
fi
assert_contains "$(<"$TEST_TMP/err_merge")" "merge in progress"

# 7e. In-progress rebase
rebase_repo="$TEST_TMP/rebase-repo"
init_repo "$rebase_repo" main
printf 'c1\n' >"$rebase_repo/f.txt"
git -C "$rebase_repo" add f.txt
git -C "$rebase_repo" commit -qm "c1"
mkdir -p "$rebase_repo/.git/rebase-merge"
if (cd "$rebase_repo" && "$WT_BIN" convert >/dev/null 2>"$TEST_TMP/err_rebase"); then
  fail "convert should fail with rebase in progress"
fi
assert_contains "$(<"$TEST_TMP/err_rebase")" "rebase in progress"

# 7f. Already bare repository
bare_repo="$TEST_TMP/already-bare"
init_repo "$bare_repo" main
printf 'c1\n' >"$bare_repo/f.txt"
git -C "$bare_repo" add f.txt
git -C "$bare_repo" commit -qm "c1"
(cd "$bare_repo" && "$WT_BIN" convert >/dev/null 2>&1)
if (cd "$bare_repo" && "$WT_BIN" convert >/dev/null 2>"$TEST_TMP/err_bare"); then
  fail "convert should fail when already bare"
fi
assert_contains "$(<"$TEST_TMP/err_bare")" "already a bare repository"

# 7g. Inside linked worktree
if (cd "$bare_repo/main" && "$WT_BIN" convert >/dev/null 2>"$TEST_TMP/err_linked"); then
  fail "convert should fail inside linked worktree"
fi
assert_contains "$(<"$TEST_TMP/err_linked")" "cannot convert a linked worktree"

echo "=== Test 8: Shell integration auto-cd ==="
shell_repo="$TEST_TMP/shell-repo"
init_repo "$shell_repo" main
printf 'shell integration\n' >"$shell_repo/sh.txt"
git -C "$shell_repo" add sh.txt
git -C "$shell_repo" commit -qm "init"
git -C "$shell_repo" checkout -q -b "feature/shell"

final_pwd=$(bash -c "
  export NO_COLOR=1
  export GIT_CONFIG_GLOBAL=/dev/null
  command() {
    if [[ \"\$1\" == \"wt\" ]]; then
      shift
      \"$WT_BIN\" \"\$@\"
    else
      \"\$@\"
    fi
  }
  source \"$PLUGIN_SH\"
  cd \"$shell_repo\"
  wt convert >/dev/null
  pwd -P
")
[[ "$final_pwd" == "$shell_repo/feature-shell" ]] || fail "expected shell auto-cd to $shell_repo/feature-shell, got: $final_pwd"

echo "=== Test 9: Zsh completions syntax and flags ==="
grep -q "convert:Convert repo" "$COMPLETIONS_ZSH" || fail "completions missing convert description"
grep -q -- "--default:override default branch" "$COMPLETIONS_ZSH" || fail "completions missing --default"
grep -q -- "--force:force conversion" "$COMPLETIONS_ZSH" || fail "completions missing --force"

echo "=== Test 10: Rollback on failure ==="
repo10="$TEST_TMP/repo10"
init_repo "$repo10" main
printf 'original file\n' >"$repo10/original.txt"
git -C "$repo10" add original.txt
git -C "$repo10" commit -qm "init commit"

real_git=$(command -v git)
fake_bin="$TEST_TMP/fake-bin"
mkdir -p "$fake_bin"
cat <<EOF >"$fake_bin/git"
#!/usr/bin/env bash
if [[ "\$*" == *"worktree add"* ]]; then
  echo "simulated worktree add failure" >&2
  exit 1
fi
exec "$real_git" "\$@"
EOF
chmod +x "$fake_bin/git"

if (cd "$repo10" && PATH="$fake_bin:$PATH" "$WT_BIN" convert >/dev/null 2>"$TEST_TMP/err_rollback"); then
  fail "convert should have failed when worktree add fails"
fi

assert_contains "$(<"$TEST_TMP/err_rollback")" "rolling back changes"
assert_file "$repo10/original.txt"
assert_not_exists "$repo10/.git/.wt-convert-staging"
[[ "$(git -C "$repo10" rev-parse --is-bare-repository)" == "false" ]] || fail "expected non-bare repo after rollback"

echo "All convert integration tests passed successfully!"
