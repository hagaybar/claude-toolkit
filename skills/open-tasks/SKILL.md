---
name: open-tasks
description: Keep a living, one-line-per-item list of everything open in the current git repo (open PRs, work-in-progress branches, open issues, items waiting on people, roadmap items) in docs/OPEN-TASKS.md on the repo's trunk, and report status from it. Use when the user asks to "create a short list of open tasks", says "/open-tasks", "Update", "Status?", "what's open?", "what's next?", or when a task finishes or a new follow-up appears mid-session in a repo that already has docs/OPEN-TASKS.md. Works in any repo; detects the trunk (dev or the default branch, never prod).
---

# Open tasks

One short list per repo of everything open. It guides the work; the goal is that it shrinks over time.

## Collect

Run `bash <this skill's base directory>/scripts/collect.sh [trunk]` from the repo root (the base directory is shown when the skill loads; it differs between WSL and sandboxes). It runs `git fetch -p`, then prints: the trunk, open PRs, open issues, branches with commits not in the trunk (with `unique-patches` — 0 means squash-merged — and whether an open PR holds them), unchecked items in `ROADMAP.md`, and whether the file already exists.

Trunk = `dev` if `origin/dev` exists, else the default branch. Pass a trunk explicitly if the repo uses something else. Never use `prod`.

## The file: `docs/OPEN-TASKS.md`

```markdown
# Open tasks

Last updated: YYYY-MM-DD

## PRs
- #53 (one Zellij key file per session) — review and merge

## Work in progress
- `fix/foo` branch (retry on 429) — unpushed, no PR yet

## Issues
- #50 (pop-up image viewer for screenshot paths) — needs design

## Other
- Waiting on the cataloguing team: is "London" a donated collection?
- Carry the .gitignore fix to main at epic end
```

Rules: one line per item; every `#N` and branch gets a short gloss in parentheses; each line ends with the next action or who it waits on. A branch that has an open PR is listed once, under PRs. No other sections.

## First run

1. Collect.
2. Read anything ambiguous before classifying it (an issue body, a branch's diff). Verify a fact before writing it down.
3. Write the file, then commit and push it to the trunk (see Committing).

## Update / Status?

1. Collect again (it fetches first).
2. Diff against the existing file: drop closed and merged items, add new ones, add follow-ups this session created (e.g. "carry this to main at epic end"). Bump "Last updated".
3. Commit and push.
4. Report, in this order and within the user's chat-length rules:
   - Decision needed from the user (or "none").
   - Done since last time.
   - Added.
   - Waiting on others.
   - The next task we can do alone.

## After finishing a task

Update the file in the same commit stream as the work. Close the issue with a comment saying what was done. Offer the next task.

## Picking the next task

Prefer items that need no outside input; among those, smallest first.

## Committing

- Commit only `docs/OPEN-TASKS.md`, message `docs: update open tasks`.
- If the checkout is not on the trunk, do not switch branches under the user: use a worktree of the trunk (`git worktree add`) or ask.
- If a push to the trunk is rejected (branch protection), open a PR for the file instead.
- A push to the trunk may auto-deploy somewhere (e.g. a test host). A docs-only change is fine; say so if the repo deploys from the trunk. Never touch `prod`.

## Safety rules

- Never delete a branch that holds an open PR.
- Before calling a branch stale, check it really is merged (`unique-patches=0` or `git cherry`). Copy any content that never landed (e.g. a `.gitignore` rule) to the trunk before deleting, and ask before deleting.
- Before running tests that compare against main, update the local main first.
- Keep chat short; long write-ups go in the issue or the file.
- A session handoff (`session-handoff`) links to this file instead of copying it; keep the list here current so the handoff can rely on it.
