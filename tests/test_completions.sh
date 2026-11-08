#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
WT_BIN=${WT_BIN:-$ROOT/wt}
COMPLETIONS_ZSH="$ROOT/wt.completions.zsh"
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

export NO_COLOR=1
export GIT_CONFIG_GLOBAL=/dev/null

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "expected '$2' in '$1'"; }
assert_not_contains() { [[ "$1" != *"$2"* ]] || fail "expected '$2' NOT to be in '$1'"; }

echo "=== Setting up synthetic bare repo with multiple worktrees ==="
repo="$TEST_TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q -b main
git -C "$repo" config user.email test@example.com
git -C "$repo" config user.name Test
git -C "$repo" config commit.gpgsign false
echo "hello world" > "$repo/file.txt"
git -C "$repo" add file.txt
git -C "$repo" commit -qm "initial commit"

# Convert to wt bare + worktrees layout
cd "$repo"
"$WT_BIN" convert >/dev/null

# Add multiple worktrees
git -C "$repo/main" worktree add -q -b feat1 "$repo/feat1"
git -C "$repo/main" worktree add -q -b feat2 "$repo/feat2"
git -C "$repo/main" worktree add -q -b feat3 "$repo/feat3"

echo "=== Test 1: wt rm completion captures all worktrees without collision or .git ==="
output_rm=$(zsh -c '
autoload -U compinit
compinit -D
typeset -A compstate
source "'"$COMPLETIONS_ZSH"'"

typeset -a captured_worktrees captured_groups
compadd() {
  local prev="" grp=""
  for arg in "$@"; do
    if [[ "$prev" == "-V" || "$prev" == "-J" ]]; then
      grp="$arg"
    elif [[ "$prev" == "-a" ]]; then
      local -a copy
      copy=("${(@P)arg}")
      captured_worktrees+=("${copy[@]}")
      [[ -n "$grp" ]] && captured_groups+=("$grp")
    fi
    prev="$arg"
  done
  builtin compadd "$@" 2>/dev/null || true
}

cd "'"$repo/main"'"
CURRENT=3
words=(wt rm "")
set +e
_wt
err=$?
set -e

[[ $err -eq 0 ]] || { echo "ERROR_EXIT: $err"; exit 1; }
echo "WORKTREES: ${(j:,:)captured_worktrees}"
echo "GROUPS: ${(j:,:)captured_groups}"
')

echo "$output_rm"
assert_contains "$output_rm" "WORKTREES: feat1,feat2,feat3,main"
assert_contains "$output_rm" "GROUPS: wt-worktree"
assert_not_contains "$output_rm" ".git"
assert_not_contains "$output_rm" "$repo"

echo "=== Test 2: wt rm flag completion when positional arg given ==="
output_rm_flags=$(zsh -c '
autoload -U compinit
compinit -D
typeset -A compstate
source "'"$COMPLETIONS_ZSH"'"

typeset -a captured_flags
_describe() {
  local tag="$1" varname="$2"
  local -a copy
  copy=("${(@P)varname}")
  captured_flags+=("${copy[@]}")
}

cd "'"$repo/main"'"
CURRENT=4
words=(wt rm feat1 "")
set +e
_wt
set -e

echo "FLAGS: ${(j:,:)captured_flags}"
')
echo "$output_rm_flags"
assert_contains "$output_rm_flags" "--remote:also delete remote branch"
assert_contains "$output_rm_flags" "--force:allow removing dirty worktree"

echo "=== Test 3: wt pull completion captures worktrees and calls _files ==="
output_pull=$(zsh -c '
autoload -U compinit
compinit -D
typeset -A compstate
source "'"$COMPLETIONS_ZSH"'"

files_called=0
_files() { files_called=1; }

typeset -a captured_worktrees captured_groups
compadd() {
  local prev="" grp=""
  for arg in "$@"; do
    if [[ "$prev" == "-V" || "$prev" == "-J" ]]; then
      grp="$arg"
    elif [[ "$prev" == "-a" ]]; then
      local -a copy
      copy=("${(@P)arg}")
      captured_worktrees+=("${copy[@]}")
      [[ -n "$grp" ]] && captured_groups+=("$grp")
    fi
    prev="$arg"
  done
  builtin compadd "$@" 2>/dev/null || true
}

cd "'"$repo/main"'"
CURRENT=3
words=(wt pull "")
set +e
_wt
err=$?
set -e

[[ $err -eq 0 ]] || { echo "ERROR_EXIT: $err"; exit 1; }
echo "FILES_CALLED: $files_called"
echo "WORKTREES: ${(j:,:)captured_worktrees}"
echo "GROUPS: ${(j:,:)captured_groups}"
')

echo "$output_pull"
assert_contains "$output_pull" "FILES_CALLED: 1"
assert_contains "$output_pull" "WORKTREES: feat1,feat2,feat3,main"
assert_contains "$output_pull" "GROUPS: wt-worktree"
assert_not_contains "$output_pull" ".git"

echo "=== Test 4: wt pull flag completion when source arg given ==="
output_pull_flags=$(zsh -c '
autoload -U compinit
compinit -D
typeset -A compstate
source "'"$COMPLETIONS_ZSH"'"

typeset -a captured_flags
_describe() {
  local tag="$1" varname="$2"
  local -a copy
  copy=("${(@P)varname}")
  captured_flags+=("${copy[@]}")
}

cd "'"$repo/main"'"
CURRENT=4
words=(wt pull feat1 "")
set +e
_wt
set -e

echo "FLAGS: ${(j:,:)captured_flags}"
')
echo "$output_pull_flags"
assert_contains "$output_pull_flags" "--staged:pull only staged changes from source"

echo "=== Test 5: Outside bare wt project ==="
output_outside=$(zsh -c '
autoload -U compinit
compinit -D
typeset -A compstate
source "'"$COMPLETIONS_ZSH"'"

files_called=0
_files() { files_called=1; }

mkdir -p "'"$TEST_TMP/non_wt"'"
cd "'"$TEST_TMP/non_wt"'"

# wt rm outside wt repo (returns without output/crash)
CURRENT=3
words=(wt rm "")
set +e
_wt
rm_err=$?

# wt pull outside wt repo (calls _files for filesystem paths)
CURRENT=3
words=(wt pull "")
_wt
pull_err=$?
set -e

echo "RM_ERR: $rm_err, PULL_ERR: $pull_err, FILES_CALLED: $files_called"
')
echo "$output_outside"
assert_contains "$output_outside" "FILES_CALLED: 1"

echo "=== Test 6: Verify PATH / scalar path is not corrupted in Zsh ==="
output_path=$(zsh -c '
autoload -U compinit
compinit -D
typeset -A compstate
source "'"$COMPLETIONS_ZSH"'"

compadd() { :; }

ORIG_PATH="$PATH"
cd "'"$repo/main"'"
CURRENT=3
words=(wt rm "")
set +e
_wt
_wt
set -e

[[ "$PATH" == "$ORIG_PATH" ]] || { echo "PATH_CORRUPTED"; exit 1; }
echo "PATH_INTACT"
')
echo "$output_path"
assert_contains "$output_path" "PATH_INTACT"

echo "All completion integration tests passed successfully!"
