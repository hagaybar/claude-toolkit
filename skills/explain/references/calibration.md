# Calibration profile

Role framing: architect / director of AI coding agents, not a hands-on daily coder.
Concepts, data flow, governance, and trade-offs land immediately; language- and
framework-internal idioms are where unpacking pays off.

## Never unpack (use these terms freely)

- **Ex Libris ecosystem:** Alma, Primo, NDE, CDI, Alma APIs, XSLT letters,
  sandbox/production refresh, SB/PSB, Analytics/reports.
- **Library & metadata domain:** MARC, holdings, items, fulfillment, discovery,
  OpenURL, link resolvers.
- **Git & GitHub:** branch, PR, merge, issues,
  labels, code review, self-merge rules.
- **Agent orchestration:** subagent, hooks, MCP, system prompt, context window,
  acceptance criteria, oracle/verification, deterministic tests.
- **General architecture vocabulary:** API, endpoint, cache, queue, schema,
  client/server, token, environment variable, deploy, staging/prod.
- **Infra basics:** WSL, SSH, SFTP, cron, S3-compatible storage, Lambda.

## Judge from context (unpack when the mechanics matter, not the mention)

- webhook, tmux, rebase, CI / GitHub Actions.
- Rule of thumb: passing mention or naming a familiar workflow → use freely.
  The explanation hinges on *how it works internally* or *why it behaves
  unexpectedly* → unpack that mechanism.

## Unpack by default (cash out jargon even in technical register)

- **Software-design & reliability idioms:** idempotency, exception/error-type
  hierarchies, retries & HTTP-verb semantics (POST vs PUT), builder/factory
  patterns, "pass-through/verbatim" — name the problem each solves, not the
  pattern. (Concepts, trade-offs, and governance still land immediately; it is
  the *named idiom* that needs cashing out.)
- Language internals: JS event loop, closures-as-idiom, Python async/await
  mechanics, typing system subtleties.
- Framework internals: Angular/NGRX store mechanics (actions, reducers,
  selectors, effects), React rendering/hooks internals, RxJS operators.
- Frontend minutiae: CSS layout mechanics, browser rendering pipeline.
- Security/crypto primitives: how CSP directives actually evaluate, JWT
  signature verification internals, OAuth flow variants.
- Statistics / ML math: anything past descriptive statistics.

## Standing preferences

- Plain register + full fidelity is the default and the preferred combination.
- **Length is a knob separate from fidelity — default to short and to the
  point.** Deliver the shortest version that still carries every load-bearing
  fact. Flags `short` / `terse` tighten further: cut examples, scaffolding,
  restated takeaways, and the closing offer — trim *words*, never facts. This
  is distinct from `gist`, which drops *facts*: `short` keeps all facts in
  fewer words; `gist` keeps the shape and sheds detail. The two compose
  (`short gist` = a tiny lossy overview).
- Data-flow traces with a concrete payload are the highest-value form for
  system behavior questions.
- Code snippets: short, shown with per-line annotation, never load-bearing alone.
- Bilingual Hebrew/English environment; explanations in English unless asked.

## Change log (keep only the 5 most recent entries)

- 2026-07-19: Added "software-design & reliability idioms" to unpack-by-default — SDK-recommendation jargon (idempotency, exceptions, retries, builders, verbatim) lost the user despite the concepts landing.
- 2026-07-08: Added `short`/`terse` length preference (trim words, not facts; distinct from gist) + concise-by-default delivery.
- 2026-07-08: Moved webhook, tmux, rebase, CI to new judge-from-context tier.
- 2026-07-08: Initial profile created with the skill.
