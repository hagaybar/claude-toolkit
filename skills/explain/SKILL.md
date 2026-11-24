---
name: explain
description: Adaptive explanation of technical concepts, systems, code, and architecture at the level the user actually needs. Use this skill whenever the user asks to explain, clarify, walk through, or help them understand something ("explain this", "what does this actually do", "walk me through", "I don't get why", "in plain language", "ELI5", "how does X work"), or when they use explanation dial flags like "plain", "technical", "full", "gist", "trace", "analogy", "zoom in", "zoom out". Also use when the user pushes back on a previous explanation as too jargon-heavy, too shallow, too detailed, or too broad.
---

# Explain

Explanations have four independent dials. Most explanation failures come from collapsing them — e.g., treating "explain simply" as one knob and simultaneously dropping vocabulary, detail, and precision. Keep the dials separate.

## The four dials

| Dial | Settings | Controls |
|---|---|---|
| **Register** | `plain` \| `technical` | Vocabulary only. Plain register still names exact components, numbers, and invariants — it just doesn't assume jargon. |
| **Fidelity** | `full` \| `gist` | How much detail survives. `full` = every mechanism and edge case that matters, `gist` = deliberately lossy overview. |
| **Scope** | `layer` \| `system` | Zoom. `layer` = only the component asked about, `system` = the whole picture and how parts connect. |
| **Form** | `prose` \| `trace` \| `analogy` \| `example` \| `diagram` | The vehicle. `trace` = follow one concrete piece of data step by step through the system. |

The user's key requirement, stated in their own words: plain language must NOT mean over-simplification. `plain + full` is a common and legitimate combination — kitchen-table vocabulary carrying every load-bearing detail.

## Reading the dials

1. **Flags win.** The user may steer with short flags in natural text: "explain the auth flow — plain, full, trace". Any subset, any order. Honor them exactly.
2. **Otherwise infer** from phrasing: "what's the idea behind" → gist; "walk me through" → trace; "I don't get why X happens" → layer scope centered on X; "how does it all fit" → system scope; pasted code + "what does this do" → trace or example on that code only.
3. **Check the calibration profile** in `references/calibration.md` before choosing register. It has three tiers: *never unpack* (use freely), *unpack by default* (cash out jargon even in technical register), and *judge from context* (use freely on passing mention; unpack the mechanism when the explanation hinges on how it works internally).
4. **If genuinely ambiguous, ask ONE compact question** — a single either/or ("the whole pipeline, or just the vetting step?"), never a questionnaire. If the ambiguity is mild, pick the most likely setting, state it in half a sentence ("Zooming into just the selector layer —"), and proceed; the user will correct.

Defaults when no signal: register `plain`, fidelity `full`, scope = exactly what was asked, form = prose (switching to `trace` when the question is about behavior or data flow).

## Discipline rules

- **Simple ≠ vague.** Changing register never deletes facts. Exact names, numbers, file paths, invariants, and failure modes survive translation into plain language. If a sentence in plain register is less checkable than its technical equivalent, it's wrong.
- **Analogies must be cashed out.** After the analogy, give the explicit mapping ("the postal sorting office = the reducer; the tracking number = the action type") AND name where the analogy breaks. An analogy without a mapping and a breaking point is decoration — omit it.
- **Respect scope like a boundary.** When scope is `layer`, do not dump surrounding architecture "for context". One orienting sentence locating the layer is allowed; more is scope creep. Offer zoom instead: end with at most one line like "happy to go one layer down (X) or up (Y)."
- **Trace with a real payload.** In `trace` form, follow one specific, named piece of data ("a request for barcode 31404...") end to end, stating what each stage reads, changes, and passes on. No abstract "data flows to the service layer".
- **Code is shown, not assumed.** The user directs code rather than writing it daily: when a snippet is essential, show it short and annotate what each line *does*; never let syntax carry the explanation alone.
- **No hedging filler.** "It depends", "generally speaking", "in most cases" appear only when followed immediately by what it depends ON. Uncertainty is stated once, precisely, not sprinkled.
- **Invariant first or last.** Every explanation should contain one sentence the user could repeat as the takeaway — the core invariant or principle. Make sure it exists and is findable.

## Reading comprehension signals

The profile is a prior, not the truth. Actively watch the conversation for evidence of what actually landed:

- **"What do you mean by X" / a follow-up re-asking the same thing** → the explanation missed. Unpack X immediately (don't just define it — re-explain the point through it), and note X as a calibration candidate.
- **The user restates your explanation with an error in it** → correct the specific delta only ("almost — the selector re-emits on store change, not on a timer"), never re-deliver the whole explanation.
- **"Yes, I know this part" / skimming signals / the user answers their own question mid-message** → you're under-estimating; raise register or skip ahead, and note the term/area as a candidate for a higher tier.
- **A term from the never-unpack list needed unpacking, or a term marked unpack-by-default got waved off** → direct evidence the profile is wrong for that entry.

Adapt within the session first — the profile update is secondary and only worth proposing when a signal repeats or is unambiguous. One noisy data point is not a calibration event.

## Calibration profile updates: revise, never accrete

The profile degrades exactly like a bloated CLAUDE.md if edits are additive-only. Rules:

- **Read the whole file before proposing any change.** Most correct updates are *moves between tiers* or *amendments to an existing line*, not new lines. Prefer, in order: move an entry → reword an entry → delete an entry → add an entry.
- **Contradictions are surfaced, not layered.** If a proposed change conflicts with an existing entry, ask which stands; never leave both.
- **Propose, don't execute.** At most two specific one-line proposals, at a natural pause or session end ("Profile: move rebase from judge-from-context to never-unpack?"). Edit only after approval; never silently rewrite.
- **Keep it small.** Target: the profile stays readable in one screen (~60 lines). If it exceeds that, the next proposal should be a consolidation, not an addition. The change log keeps only the 5 most recent entries — prune older ones as part of any edit.
- **Net-negative edits are wins.** An entry that context-judgment now handles ("judge from context" covers it) can simply be deleted.
