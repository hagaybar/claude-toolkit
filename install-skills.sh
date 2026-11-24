#!/usr/bin/env bash
# Link every skill in skills/ into ~/.claude/skills (Claude Code) and ~/.agents/skills (Codex),
# link commands/*.md into ~/.claude/commands, prune links to skills since deleted here, and refresh the Docker Sandboxes (sbx) skill store
# when sbx is present. Idempotent. A real (non-link) folder in the way is moved to
# ~/.cache/claude-skills-backup/<date>/ first. Plugins install separately (see README).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
DESTS=("${CLAUDE_DIR:-$HOME/.claude}/skills" "${AGENTS_DIR:-$HOME/.agents}/skills")
BACKUP="$HOME/.cache/claude-skills-backup/$(date +%Y%m%d-%H%M%S)"
removed=()
for DEST in "${DESTS[@]}"; do
  mkdir -p "$DEST"
  for src in "$ROOT"/skills/*/; do
    src="${src%/}"; name="$(basename "$src")"; dest="$DEST/$name"
    [ -f "$src/SKILL.md" ] || continue
    if [ -L "$dest" ]; then rm "$dest"
    elif [ -e "$dest" ]; then mkdir -p "$BACKUP"; mv "$dest" "$BACKUP/"; echo "backed up $dest -> $BACKUP/$name"; fi
    ln -s "$src" "$dest"; echo "linked $dest"
  done
  for link in "$DEST"/*; do
    [ -L "$link" ] || continue
    target="$(readlink "$link")"
    case "$target" in "$ROOT"/skills/*) ;; *) continue ;; esac
    [ -e "$target" ] && continue
    rm "$link"; echo "removed stale link $link"; removed+=("$(basename "$link")")
  done
done
# Slash commands: link commands/*.md into ~/.claude/commands (Claude Code).
CMDS="${CLAUDE_DIR:-$HOME/.claude}/commands"; mkdir -p "$CMDS"
for src in "$ROOT"/commands/*.md; do
  [ -e "$src" ] || continue
  dest="$CMDS/$(basename "$src")"
  if [ -L "$dest" ]; then rm "$dest"; elif [ -e "$dest" ]; then mkdir -p "$BACKUP"; mv "$dest" "$BACKUP/"; fi
  ln -s "$src" "$dest"; echo "linked $dest"
done
if command -v sbx >/dev/null 2>&1 && [ "${SKIP_SBX:-0}" != 1 ]; then
  for name in $(printf '%s\n' "${removed[@]}" | sort -u); do
    sbx skills rm --force "$name" >/dev/null 2>&1 && echo "removed $name from the sbx store"
  done
  sbx skills import --force >/dev/null 2>&1 && echo "sbx skill store updated"
fi
