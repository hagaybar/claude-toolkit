# Evaluation: alma-letters

> **IDs in this file are placeholders** (this skills library is public). If `$ALMA_FIXTURES` is set, it points to the owner's private map from each placeholder to the real Alma Sandbox record; use it to re-run a check, and never write a real ID back here.

- **Date:** 2026-11-24
- **Reviewer:** agent, from repo evidence (not an independent validation; no new Sandbox calls)
- **Source:** TAU-Alma-letters, branch `dev`: `docs/alma-xslt-findings.md` (each finding there
  carries its own evidence), `CLAUDE.md`, `docs/verification-protocol.md`
- **Baseline test (skill absent, 2026-11-24):** a fresh agent answered 5 letter questions.
  Wrong or missing: the language fields (named `preferred_language` only; missed the multi-valued
  `languages/string` and the RS case), reading components through the API ("no endpoint for
  components"), and the upload-time template check. Right: Sandbox refresh reverts uploads.

Verdicts: **repo-verified** (proven in the TAU work; evidence named) · **unverified**.

| ID | Claim | Verdict | Evidence (in alma-xslt-findings.md unless noted) |
|---|---|---|---|
| L-01 | `GET conf/letters/{code}` returns XSL + `update_date`, `updated_by`, `customized` | repo-verified | `tools/letter_prod_snapshot.py`; 2026-06-25 prod snapshot |
| L-02 | Components are readable by full code, e.g. `footer.xsl` | repo-verified | CLAUDE.md layout section; prod reconcile of footer/header |
| L-03 | Alma validates all call-template targets at upload; libxslt is lazy | repo-verified | New Gen upload error 2026-06-30 |
| L-04 | A Sandbox refresh reverts every uploaded XSL | repo-verified | New Gen 2026-08-12 (`signature` not defined) |
| L-05 | footer.xsl needs style.xsl | repo-verified | same upload error; `check_templates.py` |
| L-06 | New-Gen letters resolve `xsl:include` | repo-verified | New Gen upload error referencing a footer-internal template |
| L-07 | Editor round-trip adds a trailing space per line | repo-verified | New Gen prod deploy 2026-08-13 (+1,025 bytes) |
| L-08 | Upload takes effect after 20 to ~50 min | repo-verified | trial RTL experiments 2026-11-09 |
| L-09 | `languages/string` is multi-valued config, not the letter language | repo-verified | fingerprints (Borrowing Activity, User Notifications, DD) |
| L-10 | RS letters often have no user-language field | repo-verified | General Message fingerprint |
| L-11 | Language precedence user_preferred_language → preferred_language → languages/string | repo-verified | fingerprints (circulation, RS, acquisitions) |
| L-12 | Hebrew recipient: rtl placeholder + left/right mirroring | repo-verified | trial RTL bisect 2026-11-09 (SB, Outlook) |
| L-13 | `user/library_code` can be a `##` list; signature = sender | repo-verified | all-libs DD fingerprint; local render (5 blocks) |
| L-14 | DD responsible library = `organization_unit/org_scope/library_id` | repo-verified | 2 DD fingerprints |
| L-15 | `user/default_language`, `request/language` as language sources | unverified | mapping CSV only |
| L-16 | Purpose of `user_preferred_language_original_value` | unverified | — |
