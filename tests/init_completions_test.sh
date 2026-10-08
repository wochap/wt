#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
WT_BIN=${WT_BIN:-$ROOT/wt}
DATA_DIR=${WT_DATA_DIR:-$ROOT}
export NO_COLOR=1

fail() { echo "FAIL: $*" >&2; exit 1; }

diff <("$WT_BIN" init zsh) "$DATA_DIR/wt.plugin.sh" >/dev/null || fail "wt init zsh != wt.plugin.sh"
diff <("$WT_BIN" completions zsh) "$DATA_DIR/wt.completions.zsh" >/dev/null || fail "wt completions zsh != wt.completions.zsh"
for args in "init bash" "init" "completions fish" "completions"; do
  # shellcheck disable=SC2086
  if "$WT_BIN" $args >/dev/null 2>&1; then fail "wt $args should fail"; fi
done

# Symlinked script still resolves its data files.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
ln -s "$WT_BIN" "$tmp/wt"
diff <("$tmp/wt" init zsh) "$DATA_DIR/wt.plugin.sh" >/dev/null || fail "symlinked wt init zsh"

echo "ok"
