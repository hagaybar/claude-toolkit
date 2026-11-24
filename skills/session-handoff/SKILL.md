---
name: session-handoff
description: Preserve and restore session state across Claude Code sessions. Use this skill whenever the user wants to end, close, or wrap up a session ("prepare handoff", "wrap up", "let's close for today", "save state before we stop"), OR whenever the user wants to resume prior work ("pick up where we left off", "resume", "load the handoff", "what were we doing", "continue from last session"). Also use it if the user mentions handing off work to a future session or agent, or asks what state was saved from a previous session.
---

# Session Handoff

Two modes: **handoff** (write session state before closing) and **pickup** (restore state when resuming). Determine the mode from the user's request. If ambiguous, ask.

## Core principle: ephemeral vs. durable knowledge

A handoff file holds only *perishable* session state — the things that exist in your head right now and nowhere else. Anything that future agents should never re-litigate does NOT belong in the handoff; it belongs in durable storage:

| Knowledge type | Destination |
|---|---|
| Architectural decision, constraint, convention | CLAUDE.md or docstrings in the repo |
| Task definition, acceptance criteria, discussion | GitHub issue / PR |
| Working code, config, test | Committed to the project repo |
| Current position, next step, unverified state, open question | **Handoff file** |

During handoff mode, actively look for durable knowledge that hasn't been persisted yet and offer to promote it before writing the handoff. A handoff that says "we decided X" without X being recorded anywhere durable is a bug — a future agent could silently reverse X.

## Storage layout

Handoffs live at **user level**, outside project repos, in `~/.claude/handoffs/`, which is its own git repository (auto-committed on every write). This gives history and durability across all projects without polluting project repos.

```
~/.claude/handoffs/
├── .git
└── <project-slug>/
    ├── latest.md                  # copy of the newest handoff
    └── 2026-07-08-1432.md         # timestamped archive
```

Use the helper script for all path resolution, initialization, and committing — do not hand-roll these operations:

```bash
python <skill-dir>/scripts/handoff.py resolve   # prints project slug + paths for cwd
python <skill-dir>/scripts/handoff.py save <tmpfile>   # installs tmpfile as new handoff, updates latest.md, git-commits
python <skill-dir>/scripts/handoff.py latest    # prints path of latest handoff for cwd's project (or NONE)
python <skill-dir>/scripts/handoff.py list      # lists all archived handoffs for cwd's project
```

The script derives the project slug from the git remote URL (falling back to directory name), so the same project resolves to the same slug from any worktree or clone.

## Handoff mode (end of session)

1. **Take stock.** Review the session: what was the task, what state is it in, what was decided, what was learned, what's next. Run `git status` and `git log --oneline -5` to capture ground truth (branch, commit, dirty files).
2. **Promote durable knowledge first — sparingly.** List decisions/learnings from this session not yet recorded durably, then apply the promotion rules below. Offer specific promotions and wait for the user's answer before proceeding.
3. **Write the handoff** using the template in `references/handoff-template.md`. Read the template file — do not improvise the structure; a fixed structure is what makes pickup deterministic. Be concrete: exact file paths, exact commands, exact next step. Write for a reader with zero context beyond the file itself.
4. **Save and commit** via `handoff.py save`. Confirm to the user with the file path and a one-line summary of the state captured.

Quality bar for the "Next steps" section: the first step must be executable without any judgment call — a specific command to run or file to open, not "continue working on the feature".

If the repo has `docs/OPEN-TASKS.md` (the `open-tasks` skill), the handoff does not copy the task list: it links to that file and records only this session's state and next steps. Update OPEN-TASKS.md first if the session finished or added tasks.

### Promotion rules (anti-bloat)

CLAUDE.md degrades in two ways when promotion is careless: it bloats until agents skim it, and additive-only edits accumulate contradictions until agents pick between them arbitrarily. Every session-end promotion is a chance to cause both. Therefore:

- **Default is: do not promote.** Promote only if BOTH hold: (a) a future agent would plausibly do the wrong thing without this knowledge, and (b) it is not already enforced or expressed by code, tests, or an existing durable record. If a test enforces the decision, the test IS the record — do not write it down twice.
- **Choose the narrowest durable home.** Docstring beside the code it constrains > GitHub issue/PR > CLAUDE.md. CLAUDE.md is the home of last resort, only for repo-wide standing instructions that no single file can host. Most session decisions are local and belong beside the code.
- **CLAUDE.md edits are edits, never blind appends.** Before writing to CLAUDE.md, read the whole file. If the new item contradicts an existing line, DO NOT append — surface the conflict to the user ("line N says X; this session decided Y — which stands?") and let them resolve it. If it overlaps an existing line, amend that line rather than adding a sibling.
- **Leave it smaller when you can.** While reading CLAUDE.md, if you notice entries that are now obsolete (superseded by code, merged PRs, or later decisions), point them out and offer to remove them. Net-negative line count is a legitimate outcome of a promotion pass.

## Pickup mode (start of session)

Never auto-trigger pickup — only act when the user explicitly asks to resume.

1. **Locate** the latest handoff via `handoff.py latest`. If NONE, say so and ask how to proceed.
2. **Verify against reality before trusting.** The handoff describes the world as it was. Check for drift: current branch vs. recorded branch, current HEAD vs. recorded commit, dirty files. If the repo has moved since the handoff (new commits, different branch), flag every discrepancy explicitly — someone or some agent may have worked in between.
3. **Brief the user.** Surface a compact briefing: task + status in one line, what's verified vs. unverified, blockers/open questions, and the recorded next step. Keep it short — this is a briefing, not a re-reading of the file.
4. **Propose, don't act.** State the next step you intend to take and wait for a go/no-go. Do not start executing the plan before the user confirms.

## Multiple handoffs / stale handoffs

- If the latest handoff is old (compare its date to today), say so in the briefing: "This handoff is from N days ago; the repo has had M commits since."
- If the user asks about earlier sessions, use `handoff.py list` and read the archived files.
- Never delete archived handoffs; the archive is the history.
