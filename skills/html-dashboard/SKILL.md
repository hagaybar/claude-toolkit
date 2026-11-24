---
name: html-dashboard
description: Generate visually compelling HTML — interactive dashboards with a live browser↔Claude link, or static reports/diagrams — from a pattern library, and decide between a local HTML file and a claude.ai Artifact, always keeping a durable local copy. Use when the user wants to track a multi-step or long-running workflow, monitor live progress, understand a flow or architecture ("how does X work?"), compare options or review a decision, or present complex/tabular data clearly; and before publishing any Artifact page (report, explainer, diagram, chart). Also use when the user asks for a dashboard of THIS session ("/dashboard of this session", "/dash", "lay out where we are"). Triggers: dashboard, diagram, flowchart, visualize, "show me", "lay this out", track progress, compare options, artifact, HTML page.
---

# HTML Dashboard

Turn an idea into a styled HTML artifact from a library of patterns. Two modes:

- **Static** — pick a pattern, fill it, write the file into the current repo,
  open it. No server. For reports, diagrams, comparisons, one-shot data views.
- **Interactive** — same, plus a localhost server giving a live two-way
  browser↔Claude link (the operator pings; you reply inline).

## Local file or Artifact?

Decide first. The user wants pages they can come back to; claude.ai Artifact links have
gone dead before, because their source sat in a session scratchpad that was later wiped.

| Need | Output |
|---|---|
| Live tracking, two-way pings, long-running work | Local, interactive mode (below) |
| A page the user will reopen, or that belongs with a repo | Local, static mode (below) |
| A polished one-off visual: explainer, rich chart, design-heavy page, something to share | Artifact, following the artifact-design skill |
| Unsure | Local static; offer the Artifact in one line |

**Every Artifact keeps a durable local source.** Write its HTML to the durable folder (in a
repo: `docs/dashboards/`; elsewhere: `~/dashboards/`), never to the scratchpad, and publish
from that path. Then add one line to `ARTIFACTS.md` in the same folder:
`- YYYY-MM-DD · <file>.html · <artifact URL> · <one-line purpose>`. On a republish, edit
that same file. If the URL stops working, the page is still on disk and can be opened or
republished.

## When to suggest it

Offer a dashboard/diagram (don't wait to be asked) when the user wants to:
track a multi-step or long workflow, monitor live progress, understand a flow
or architecture, compare options, or present complex/tabular data. **Suggest,
then let the user accept.** Never start a server unprompted.

## Dashboard of this session

When the user asks for a dashboard of the current conversation (its work, decisions, progress,
open items), the conversation itself is the source. (This replaces the retired session-dash
plugin's `/dash`, 2026-11-24.)

1. **Plan first, silently:** pick the pattern from `patterns/INDEX.md` that fits, a title, and a
   kebab-case file name.
2. **Interview only when needed:** ask **at most 2** short multiple-choice questions (2–4
   options each, with AskUserQuestion), and only where the dashboard's purpose, audience or
   scope is genuinely unclear from the conversation. **Zero questions is the best answer when it
   is clear.**
3. **Build it static:** fill every slot with real content from the conversation; remove the comms
   `<script>` and the `/assets/*` links, inline the styles it needs (Mermaid may load from
   cdn.jsdelivr.net).
4. **Scrub before saving:** no secret values, API keys, tokens, passwords, personal emails or
   patron data; replace any token-shaped string (Alma `l7xx…` keys, JWTs `eyJ….eyJ….…`, GitHub
   `ghp_…`/`github_pat_…`, `sk-ant-…`, AWS `AKIA…`/`ASIA…`, private-key blocks) with `[redacted]`.
5. **Save durably** (see "Local file or Artifact?") and tell the user the path.

## Choosing a pattern

Read `patterns/INDEX.md` and match intent → pattern. The catalog covers
diagrams (flowchart/sequence/architecture/state, via Mermaid), dashboards
(status-cards/progress), data (table/metrics/chart), comparison
(side-by-side/decision-matrix), and narrative (stepper).

## Workflow — static

1. Copy the chosen pattern to the repo as `<topic>.html` (default location:
   `docs/dashboards/`, or the dir that fits — see `references/building-html.md`).
2. Fill every `<!-- SLOT: ... -->`. Remove the comms `<script>` if present.
3. Open it (`python3 -m http.server` in that dir, or a `file://` path).
4. Offer to commit it (it's a per-repo, committable artifact).

## Workflow — interactive

1. Copy the chosen interactive pattern to the repo as `<topic>-dash.html`
   (the `-dash.html` suffix is what the server auto-discovers).
2. Fill slots; keep the `/assets/comms.js` + `/assets/base.css` links.
3. Start the server (it auto-picks a free port if 8765 is taken):
   ```bash
   DASH_DIR=docs/dashboards DASH_PORT=8765 python3 ~/.claude/skills/html-dashboard/engine/server.py
   ```
   Tell the user the URL printed on stderr.
4. Run the watcher to receive the operator's pings:
   ```bash
   DASH_SERVER=http://localhost:<port> bash ~/.claude/skills/html-dashboard/engine/watch.sh
   ```
5. On a ping, act, then reply inline:
   ```bash
   DASH_SERVER=http://localhost:<port> bash ~/.claude/skills/html-dashboard/engine/reply.sh <elementId|-> <info|success|warn|error|question> "text"
   ```
   Relaunch the watcher for the next ping.

## Safety

- The server redacts JWTs and Alma API keys from every POST before persisting.
- Never write real operator-supplied identifiers into committed HTML (R9-style
  discipline). The redactor is a safety net, not a license.
- Localhost-bind only.

## Adding a pattern

Drop a new `<name>.html` in `patterns/` (follow an existing exemplar) and add a
row to `patterns/INDEX.md`. No code changes needed.
