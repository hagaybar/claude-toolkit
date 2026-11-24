#!/usr/bin/env bash
# install.sh — symlink the html-dashboard skill + /dashboard command into
# ~/.claude. Idempotent: re-running re-points the symlinks; any pre-existing
# real file is backed up to <name>.bak.<epoch> first.
set -euo pipefail

# repo root = two levels up from this script (.../skills/html-dashboard/install.sh)
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SKILL_DIR/../.." && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/commands"

link() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%s)"
    echo "backed up existing $dest"
  fi
  ln -s "$src" "$dest"
  echo "linked $dest -> $src"
}

link "$SKILL_DIR" "$CLAUDE_DIR/skills/html-dashboard"
link "$REPO_ROOT/commands/dashboard.md" "$CLAUDE_DIR/commands/dashboard.md"
echo "done."
