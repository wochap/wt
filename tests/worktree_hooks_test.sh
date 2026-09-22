#!/usr/bin/env bash
set -euo pipefail

WT_BIN=$(cd "$(dirname "$0")/.." && pwd -P)/wt
BASH_BIN=$(command -v bash)
TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
export NO_COLOR=1

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [[ -f "$1" ]] || fail "expected file: $1"; }
assert_contains() { [[ "$1" == *"$2"* ]] || fail "expected '$2' in '$1'"; }

make_project() {
  local name="$1" seed root
  seed="$TEST_TMP/$name-seed"
  root="$TEST_TMP/$name"
  git init -q -b main "$seed"
  git -C "$seed" config user.email test@example.com
  git -C "$seed" config user.name Test
  mkdir -p "$seed/subdir"
  printf 'tracked\n' >"$seed/tracked"
  printf 'subdir\n' >"$seed/subdir/tracked"
  git -C "$seed" add .
  git -C "$seed" commit -qm initial
  mkdir -p "$root"
  git clone -q --bare "$seed" "$root/.git"
  git -C "$root/.git" worktree add -q "$root/main" main
  git -C "$root/.git" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  git -C "$root/.git" update-ref refs/remotes/origin/remote refs/heads/main
  printf '%s\n' "$root"
}

# No configuration preserves switching and has no jq dependency on its path.
root=$(make_project absent)
out=$(cd "$root/main" && "$WT_BIN" switch)
[[ "$out" == "$root/main" ]] || fail "argument-free fallback default"

# A present config reports the conditional jq dependency before creation.
mkdir "$TEST_TMP/no-jq-bin"
ln -s "$(command -v git)" "$TEST_TMP/no-jq-bin/git"
ln -s "$(command -v dirname)" "$TEST_TMP/no-jq-bin/dirname"
printf '{}\n' >"$root/main/wt.json"
if (cd "$root/main" && PATH="$TEST_TMP/no-jq-bin" "$BASH_BIN" "$WT_BIN" switch -b no-jq >/dev/null 2>"$root/error"); then
  fail "configuration without jq succeeded"
fi
assert_contains "$(<"$root/error")" "jq is required"
[[ ! -d "$root/no-jq" ]] || fail "missing jq created worktree"

# Malformed and semantically invalid configuration fail before mutation.
printf '{' >"$root/main/wt.json"
if (cd "$root/main" && "$WT_BIN" switch -b malformed >/dev/null 2>"$root/error"); then
  fail "malformed configuration succeeded"
fi
assert_contains "$(<"$root/error")" "invalid wt.json"
[[ ! -d "$root/malformed" ]] || fail "malformed config created worktree"
printf '{"hooks":{"post_create":[{"type":"copy","from":"../escape"}]}}\n' >"$root/main/wt.json"
if (cd "$root/main" && "$WT_BIN" switch -b escaping >/dev/null 2>"$root/error"); then
  fail "escaping configuration succeeded"
fi
[[ ! -d "$root/escaping" ]] || fail "escaping config created worktree"

# Configured default branch affects argument-free switching.
git -C "$root/.git" branch trunk main
git -C "$root/.git" worktree add -q "$root/unusual-default-path" trunk
printf '{"default_branch":"trunk"}\n' >"$root/main/wt.json"
out=$(cd "$root/main" && "$WT_BIN" switch)
[[ "$out" == "$root/unusual-default-path" ]] || fail "configured default lookup"
printf '{"default_branch":"missing"}\n' >"$root/main/wt.json"
if (cd "$root/main" && "$WT_BIN" switch >/dev/null 2>"$root/error"); then
  fail "missing configured branch succeeded"
fi
assert_contains "$(<"$root/error")" "unknown ref: missing"

# Copy files/directories, default destinations, nested relative links, command
# environment/work_dir, ordering, and stdout/stderr routing.
root=$(make_project actions)
printf 'secret\n' >"$root/main/.env"
printf 'shared\n' >"$root/main/.shared"
mkdir -p "$root/main/cache/child"
printf 'cached\n' >"$root/main/cache/child/value"
cat >"$root/main/wt.json" <<'JSON'
{
  "default_branch": "main",
  "hooks": {"post_create": [
    {"type":"copy", "from":".env"},
    {"type":"copy", "from":"cache", "to":"var/copied"},
    {"type":"symlink", "from":"cache", "to":"nested/cache-link"},
    {"type":"symlink", "from":".shared"},
    {"type":"command", "command":"printf '%s' \"$HOOK_VALUE\" > hook-value; echo hook-output", "work_dir":"subdir", "env":{"HOOK_VALUE":"works"}},
    {"type":"command", "command":"test -f subdir/hook-value && printf ordered > ordered"}
  ]}
}
JSON
out=$(cd "$root/main" && "$WT_BIN" switch -b hooked 2>"$root/error")
[[ "$out" == "$root/hooked" && "$(wc -l <<<"$out")" -eq 1 ]] || fail "stdout protocol"
assert_contains "$(<"$root/error")" "hook-output"
assert_file "$root/hooked/.env"
assert_file "$root/hooked/var/copied/child/value"
[[ -L "$root/hooked/nested/cache-link" ]] || fail "nested symlink missing"
[[ "$(realpath "$root/hooked/nested/cache-link")" == "$root/main/cache" ]] || fail "symlink target"
[[ -L "$root/hooked/.shared" ]] || fail "defaulted file symlink missing"
[[ "$(<"$root/hooked/subdir/hook-value")" == works ]] || fail "command env/work_dir"
assert_file "$root/hooked/ordered"

# Existing worktrees bypass hooks.
printf '{"hooks":{"post_create":[{"type":"command","command":"touch should-not-run"}]}}\n' >"$root/main/wt.json"
out=$(cd "$root/main" && "$WT_BIN" switch hooked)
[[ "$out" == "$root/hooked" && ! -e "$root/hooked/should-not-run" ]] || fail "existing bypass"

# Every remaining creation form invokes hooks: local, remote, commit, and named
# detached. (-b was exercised above.)
printf '{"hooks":{"post_create":[{"type":"command","command":"touch lifecycle-ran"}]}}\n' >"$root/main/wt.json"
git -C "$root/.git" branch local-mode main
(cd "$root/main" && "$WT_BIN" switch local-mode >/dev/null)
assert_file "$root/local-mode/lifecycle-ran"
(cd "$root/main" && "$WT_BIN" switch remote >/dev/null)
assert_file "$root/remote/lifecycle-ran"
tree=$(git -C "$root/.git" rev-parse 'main^{tree}')
sha=$(printf 'detached\n' | env GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com git -C "$root/.git" commit-tree "$tree" -p main)
(cd "$root/main" && "$WT_BIN" switch "$sha" >/dev/null)
short=$(git -C "$root/.git" rev-parse --short=8 "$sha")
assert_file "$root/$short/lifecycle-ran"
(cd "$root/main" && "$WT_BIN" switch main snapshot >/dev/null)
assert_file "$root/main-snapshot/lifecycle-ran"

# Failure stops later actions, emits no path, retains state, and is not retried.
cat >"$root/main/wt.json" <<'JSON'
{"hooks":{"post_create":[
  {"type":"command","command":"touch before-failure"},
  {"type":"command","command":"echo failing; exit 7"},
  {"type":"command","command":"touch after-failure"}
]}}
JSON
if out=$(cd "$root/main" && "$WT_BIN" switch -b retained 2>"$root/error"); then
  fail "failed hook returned success"
fi
[[ -z "$out" ]] || fail "failed hook printed path"
assert_file "$root/retained/before-failure"
[[ ! -e "$root/retained/after-failure" ]] || fail "actions continued after failure"
git -C "$root/.git" show-ref --verify --quiet refs/heads/retained || fail "branch not retained"
out=$(cd "$root/main" && "$WT_BIN" switch retained)
[[ "$out" == "$root/retained" ]] || fail "retained worktree not switchable"

# Creating the default worktree skips source actions but runs commands.
# From the project root without a default worktree, the first existing
# worktree supplies configuration.
root=$(make_project default-self)
git -C "$root/.git" worktree remove "$root/main"
git -C "$root/.git" worktree add -q "$root/other" -b other main
cat >"$root/other/wt.json" <<'JSON'
{"default_branch":"main","hooks":{"post_create":[
  {"type":"copy","from":"not-present"},
  {"type":"symlink","from":"not-present"},
  {"type":"command","command":"touch command-ran"}
]}}
JSON
out=$(cd "$root" && "$WT_BIN" switch 2>"$root/error")
[[ "$out" == "$root/main" ]] || fail "default worktree creation"
assert_file "$root/main/command-ran"
assert_contains "$(<"$root/error")" "Skipping copy"

# Missing sources and existing tracked destinations fail without overwrite.
root=$(make_project failures)
printf '{"hooks":{"post_create":[{"type":"copy","from":"missing"}]}}\n' >"$root/main/wt.json"
if (cd "$root/main" && "$WT_BIN" switch -b missing-source >/dev/null 2>"$root/error"); then
  fail "missing source succeeded"
fi
assert_contains "$(<"$root/error")" "source does not exist"
printf 'source\n' >"$root/main/local-tracked"
printf '{"hooks":{"post_create":[{"type":"copy","from":"local-tracked","to":"tracked"}]}}\n' >"$root/main/wt.json"
if (cd "$root/main" && "$WT_BIN" switch -b existing-target >/dev/null 2>"$root/error"); then
  fail "existing destination succeeded"
fi
[[ "$(<"$root/existing-target/tracked")" == tracked ]] || fail "destination overwritten"

# Configuration comes from the current worktree, even from a subdirectory.
root=$(make_project per-worktree)
git -C "$root/.git" worktree add -q "$root/feature" -b feature main
printf '{"hooks":{"post_create":[{"type":"command","command":"touch from-main"}]}}\n' >"$root/main/wt.json"
printf '{"hooks":{"post_create":[{"type":"command","command":"touch from-feature"}]}}\n' >"$root/feature/wt.json"
(cd "$root/feature/subdir" && "$WT_BIN" switch -b from-feature-wt >/dev/null)
assert_file "$root/from-feature-wt/from-feature"
[[ ! -e "$root/from-feature-wt/from-main" ]] || fail "main config used inside feature worktree"
(cd "$root/main" && "$WT_BIN" switch -b from-main-wt >/dev/null)
assert_file "$root/from-main-wt/from-main"

# A worktree without wt.json has no configuration, even if others do.
(cd "$root/from-main-wt" && "$WT_BIN" switch -b unconfigured >/dev/null)
[[ ! -e "$root/unconfigured/from-main" ]] || fail "config leaked into unconfigured worktree"

# From the project root, the default-branch worktree supplies configuration.
(cd "$root" && "$WT_BIN" switch -b from-root >/dev/null)
assert_file "$root/from-root/from-main"

# A legacy project-root wt.json is ignored.
root=$(make_project legacy)
printf '{"hooks":{"post_create":[{"type":"command","command":"touch legacy-ran"}]}}\n' >"$root/wt.json"
(cd "$root/main" && "$WT_BIN" switch -b legacy-cwd >/dev/null)
(cd "$root" && "$WT_BIN" switch -b legacy-root >/dev/null)
[[ ! -e "$root/legacy-cwd/legacy-ran" && ! -e "$root/legacy-root/legacy-ran" ]] || fail "legacy root config used"

# Clone creates its initial worktree without consulting a pre-existing root config.
clone_seed="$TEST_TMP/clone-seed"
git init -q -b main "$clone_seed"
git -C "$clone_seed" config user.email test@example.com
git -C "$clone_seed" config user.name Test
printf 'clone\n' >"$clone_seed/file"
git -C "$clone_seed" add .
git -C "$clone_seed" commit -qm initial
mkdir "$TEST_TMP/cloned"
printf '{"hooks":{"post_create":[{"type":"command","command":"touch clone-hook-ran"}]}}\n' >"$TEST_TMP/cloned/wt.json"
(cd "$TEST_TMP" && "$WT_BIN" clone "$clone_seed" cloned >/dev/null)
[[ ! -e "$TEST_TMP/cloned/main/clone-hook-ran" ]] || fail "clone ran post_create"

echo "worktree hook integration tests passed"
