# claude-toolkit

Agent skills and one Claude Code plugin, used daily for library-systems work at a university
library: Ex Libris Alma (API workflows), MARC cataloguing, Primo NDE customization, plus general
workflow skills (session handoffs, open-task lists, HTML dashboards, explanations).

Skills follow the open [Agent Skills](https://agentskills.io) format, so Claude Code and Codex
both read them.

## Skills

| Skill | What it is for |
|---|---|
| [`alma-acquisitions-specialist`](skills/alma-acquisitions-specialist) | Help Claude Code and Codex understand, implement, and troubleshoot Alma Acquisitions workflows and APIs using official documentation, AlmaAPITK, and project knowledge. |
| [`alma-api-expert`](skills/alma-api-expert) | Alma ILS API core reference and router — authentication and base URLs, general HTTP errors (401, 429, 500) and error handling, pagination and query syntax, sets (admin AP |
| [`alma-api-knowledge-evaluator`](skills/alma-api-knowledge-evaluator) | Evaluate Alma API skills for factual accuracy, implementation alignment, and usefulness on realistic tasks using official documentation and controlled Sandbox evidence. |
| [`alma-bibs-inventory`](skills/alma-bibs-inventory) | Alma Bibs API for catalogue and physical inventory — bibliographic records (fetch by identifier; /bibs has no keyword search), holdings, items (get by barcode, scan-in to |
| [`alma-digital`](skills/alma-digital) | Alma digital representations through the API — creating representations on a bib (usage-type codes PRESERVATION_MASTER/MODIFIED_MASTER/DERIVATIVE_COPY/AUXILIARY, entity t |
| [`alma-letters`](skills/alma-letters) | Use when writing, debugging, testing or uploading Ex Libris Alma notification letters (XSLT over notification XML) or their shared components (footer.xsl, header.xsl, sty |
| [`alma-resource-sharing`](skills/alma-resource-sharing) | Alma resource sharing through the API, both sides — partner-side lending requests (POST /almaws/v1/partners/{partner_code}/lending-requests) and patron-side borrowing req |
| [`alma-users`](skills/alma-users) | Alma Users API — patron records (get, search, update email and expiry date, the full-record PUT and its validation), user notes, loans (create, renew), user requests (cre |
| [`bidi-engineering`](skills/bidi-engineering) | Bidirectional (BiDi) UI engineering and RTL support for Hebrew–English interfaces. |
| [`expert-cataloger`](skills/expert-cataloger) | Expert head-of-cataloging for anything involving the MARC 21 standard (bibliographic, authority, holdings). |
| [`explain`](skills/explain) | Adaptive explanation of technical concepts, systems, code, and architecture at the level the user actually needs. |
| [`html-dashboard`](skills/html-dashboard) | Generate visually compelling HTML — interactive dashboards with a live browser↔Claude link, or static reports/diagrams — from a pattern library, and decide between a loca |
| [`open-tasks`](skills/open-tasks) | Keep a living, one-line-per-item list of everything open in the current git repo (open PRs, work-in-progress branches, open issues, items waiting on people, roadmap items |
| [`primo-nde`](skills/primo-nde) | Use when building, debugging or explaining customizations for Ex Libris Primo NDE (New Discovery Experience): the CustomModule template, custom components inside the Prim |
| [`session-handoff`](skills/session-handoff) | Preserve and restore session state across Claude Code sessions. |

The Alma skills are a family: `alma-api-expert` is the shared core and router; each domain
skill covers one area of the Alma API and keeps an `evaluation.md` recording which claims were
checked, against what, and which were corrected.

## Plugin

This repo is also a Claude Code plugin marketplace, `hagay-mods`:

- **secret-guard**: keeps API keys, tokens and passwords out of the transcript, tool output,
  files, commits, PRs and issues.

```
claude plugin marketplace add hagaybar/claude-toolkit
claude plugin install secret-guard@hagay-mods
```

## Install the skills

```
git clone https://github.com/hagaybar/claude-toolkit
cd claude-toolkit && ./install-skills.sh
```

It links every skill into `~/.claude/skills` (Claude Code) and `~/.agents/skills` (Codex), and the
slash commands in `commands/` (e.g. `/dashboard`) into `~/.claude/commands`.

## No real identifiers

This repo is public. Examples use placeholders: no API keys, no real Alma IDs (records,
libraries, PO lines), no institution codes, no staff or patron data. Every push and PR is
scanned (`.gitleaks.toml`, `.github/workflows/scan.yml`). See `CLAUDE.md`.

## License

MIT.
