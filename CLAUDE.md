# CLAUDE.md — claude-toolkit

Public library of agent skills (`skills/`) and Claude Code plugins (`plugins/`; this repo is the
`hagay-mods` marketplace). Claude edits skills; Codex reviews (`AGENTS.md`).

## Rules

**This repo is public. Nothing real goes in** (enforced by `.gitleaks.toml` in CI, written here
too because a scanner only catches shapes):
- No API keys, tokens or passwords, not even partial ones.
- No real Alma identifiers: MMS IDs, library IDs, PO line numbers, user IDs, vendor codes. Use
  placeholders (`990000000000000001`, `POL-01001`, `<user_primary_id>`).
- No institution codes or anything that ends in the institution's ID suffix.
- No staff or patron names or emails (`name@example.edu` is fine).
- Evidence in `evaluation.md` files names the *kind* of check ("read-only Sandbox GET, 2026-11-12")
  and keeps real IDs out; detailed private evidence stays in the owner's private notes.

**Skills**
- One skill per folder, `skills/<name>/SKILL.md` with `name` and a `description` that starts with
  when to use it. Supporting files in `references/`, `assets/`, `scripts/`.
- Alma skills: `alma-api-expert` is the core and router; each domain skill covers one Alma API area
  and keeps `references/evaluation.md`. A change to a claim updates its evaluation row in the same PR.
- A new skill earns its place with a failing baseline: a fresh agent gets the task wrong without it.

**Process**
- Branch, PR, CI green (the scan). Docs-only changes are merged by Claude; anything else waits for the owner.
- After merging: `./install-skills.sh` on each machine (plugins: `claude plugin marketplace update hagay-mods`).

## Where to look
- `README.md`: the catalogue and install.
- `AGENTS.md`: the reviewer's brief.
