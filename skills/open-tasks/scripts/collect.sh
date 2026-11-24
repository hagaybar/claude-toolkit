#!/usr/bin/env bash
# Collect everything open in the current repo, for docs/OPEN-TASKS.md.
# Read-only except `git fetch -p`. Usage: collect.sh [trunk]
set -uo pipefail

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repo" >&2; exit 1; }
git fetch -p --quiet origin 2>/dev/null || echo "WARN: git fetch failed; data may be stale" >&2

trunk="${1:-}"
if [ -z "$trunk" ]; then
  if git show-ref --verify --quiet refs/remotes/origin/dev; then
    trunk=dev
  else
    trunk=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
    [ -n "$trunk" ] || trunk=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)
    [ -n "$trunk" ] || trunk=main
  fi
fi
[ "$trunk" = prod ] && { echo "refusing: trunk resolved to prod" >&2; exit 2; }

echo "## TRUNK"
echo "$trunk"
echo "current branch: $(git branch --show-current)"
echo "default branch: $(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo '?')"

echo; echo "## OPEN PRS (number | head -> base | draft | review | title)"
gh pr list --state open --limit 100 \
  --json number,title,headRefName,baseRefName,isDraft,reviewDecision \
  -q '.[] | "#\(.number) | \(.headRefName) -> \(.baseRefName) | draft=\(.isDraft) | \(if (.reviewDecision // "") == "" then "-" else .reviewDecision end) | \(.title)"' 2>/dev/null \
  || echo "(gh pr list failed)"
pr_heads=$(gh pr list --state open --limit 100 --json headRefName -q '.[].headRefName' 2>/dev/null)

echo; echo "## OPEN ISSUES (number | labels | assignees | title)"
gh issue list --state open --limit 200 \
  --json number,title,labels,assignees \
  -q '.[] | "#\(.number) | \([.labels[].name] | join(",")) | \([.assignees[].login] | join(",")) | \(.title)"' 2>/dev/null \
  || echo "(gh issue list failed)"

echo; echo "## BRANCHES NOT MERGED INTO origin/$trunk (branch | ahead | last commit | has open PR)"
for ref in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin refs/heads); do
  name=${ref#origin/}
  case "$name" in HEAD|origin|"$trunk"|prod) continue ;; esac
  ahead=$(git rev-list --count "origin/$trunk..$ref" 2>/dev/null || echo "?")
  [ "$ahead" = 0 ] && continue
  # cherry: commits whose patch is not already in trunk (catches squash-merged branches)
  unique=$(git cherry "origin/$trunk" "$ref" 2>/dev/null | grep -c '^+')
  when=$(git log -1 --format='%cs' "$ref")
  pr=no; printf '%s\n' "$pr_heads" | grep -qxF "$name" && pr=yes
  where=remote; [ "$ref" = "$name" ] && where=local
  echo "$name ($where) | ahead=$ahead unique-patches=$unique | $when | PR=$pr"
done | sort -u

for f in ROADMAP.md docs/ROADMAP.md; do
  [ -f "$f" ] || continue
  echo; echo "## OPEN ITEMS IN $f"
  grep -nE '^\s*[-*] \[ \]' "$f" || echo "(no unchecked boxes; read the file for open items)"
done

echo; echo "## EXISTING FILE"
[ -f docs/OPEN-TASKS.md ] && echo "docs/OPEN-TASKS.md exists (last updated: $(grep -m1 -i 'last updated' docs/OPEN-TASKS.md))" || echo "none"
