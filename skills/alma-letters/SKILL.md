---
name: alma-letters
description: Use when writing, debugging, testing or uploading Ex Libris Alma notification letters (XSLT over notification XML) or their shared components (footer.xsl, header.xsl, style.xsl), reading letters through the configuration API (/almaws/v1/conf/letters), or when a letter renders locally but fails in Alma ("Template 'X' not defined in this stylesheet"), shows in the wrong language or direction, signs as the wrong library, or reverts after a Sandbox refresh. For general Alma API questions use alma-api-expert.
---

# Alma notification letters

Alma renders every notification (email, slip, SMS) by running a letter's **XSLT 1.0**
stylesheet over that event's **notification XML**. Stylesheets live in Alma's letter
configuration (cloud); Alma never fetches XSL from anywhere else. Letters share
**components** (`footer.xsl`, `header.xsl`, `style.xsl`, `senderReceiver.xsl`,
`recordTitle.xsl`, `mailReason.xsl`, …) through `xsl:include href="<registered name>"`.

**Maturity: repo-verified, not independently evaluated.** Every claim below was proven in the
TAU-Alma-letters work (fingerprints, local renders, Sandbox uploads); sources and status per
claim in [references/evaluation.md](references/evaluation.md). Check it before relying on a
claim for a production change.

## Reading letters through the API

- `GET /almaws/v1/conf/letters/{code}` returns the letter's XSL (escaped) plus provenance:
  `update_date`, `updated_by`, `customized`.
- **Components are letters too:** read one by its full code, e.g. `footer.xsl`.
- **`400` with `40166411` ("The parameter letterCode is invalid") means a wrong code**, not a letter
  the API can't reach. Local file names are not always Alma's codes (a New Gen letter was kept
  for months as `UserNotificationsLetterNG.xsl`; Alma's code was `NotificationsNgLetter`, and the
  400 was misread as "a different subsystem"). Before concluding a letter is unreachable, look
  the code up in `GET conf/letters`, matching by XSL if the name differs. A code missing from the
  list may also be a letter Alma no longer has.
- Use **almaapitk** (PyPI, 0.7.0+) rather than raw HTTP: `Configuration(client).list_letters()`,
  `get_letter(code)` and `update_letter(code, letter)`. JSON reads wrap some fields as
  `{"value": ...}` (`enabled`, `customized`, `updated_by`); the XSL is the `xsl` key.
- `GET /almaws/v1/conf/letters` is **unpaged**: one call returns every letter (all channels);
  `limit`/`offset` are ignored.
- The letter **PUT accepts XML only**; a JSON body fails with `60105` ("JSON is not supported for
  this API"). It replaces the whole letter, so read it, change it, send it all back.
  `update_letter` converts to XML for you.
- Treat production letters as **read-only**; change production only by an upload in Alma's UI,
  after a Sandbox test. (TAU rule; see the repo's CLAUDE.md.)
- Letters get edited directly in Alma, so a repo copy can drift from production. When
  reconciling, fetch the live XSL as ground truth.
- Alma's editor **round-trips XSL with cosmetic changes** (it added a trailing space to 1,025 of
  1,026 lines of `footer.xsl`). Compare copies **ignoring whitespace**, never byte for byte.

## Upload rules (where local tests lie)

| Fact | Consequence |
|---|---|
| Alma validates **every** `call-template` target at upload; libxslt resolves them lazily, only when called | A letter can render fine locally and still fail: `Template 'X' not defined in this stylesheet`. Check all call-template targets transitively through includes before uploading |
| Alma resolves includes against **its own** stored components, not your files | A letter and the shared includes it needs are **one upload unit**: upload the changed component with the letter |
| A **Sandbox refresh from production reverts every uploaded XSL**, components included | After any refresh, re-upload the components before the letter (a refresh is the usual cause of "it worked last week, now `signature` is not defined") |
| `footer.xsl` calls templates defined in `style.xsl` (`footerTableStyleCss`, `listStyleCss`, `mainTableStyleCss`) | A letter that includes `footer.xsl` must also include `style.xsl` |
| New-Gen letters resolve `xsl:include` too | Shared components work for them, not only for classic letters |
| An upload takes effect after a delay (seen 20 to ~50 min, irregular) | Put a visible version marker in test copies and wait before judging |

Local rendering with `lxml`/libxslt (XSLT 1.0) approximates Alma well enough to prove a change
preserves output; **the Alma Sandbox is always the final gate.**

## Notification XML: language

There is no single "letter language" field, and the right one differs by letter type:

- `languages/string` is **multi-valued** (`he` and `en`): it is the institution's configured
  languages, **not** the letter's language. `value-of` returns the first in document order, so
  code that reads it renders by config order, not by the patron.
- **Resource Sharing letters often have no user-language field**; `languages/string` is then the
  only signal.
- Precedence proven across circulation, RS and acquisitions letters:
  `user/user_preferred_language` → `receiver/preferred_language` → `languages/string`.
- Different footer templates read different fields today (`user_preferred_language`,
  `languages/string`, `receiver/preferred_language`), so one letter can resolve language several
  ways at once. Resolve it once and pass it down.
- For a **Hebrew recipient**, Alma fills the `@@language_related_body_css@@` placeholder
  (in `style.xsl`'s `generalStyle` and in Alma's own `bodyStyleCss`) with `direction:rtl`, and
  **mirrors** left/right in styles and `align` (`float:left`→`right`, `align="right"`→`"left"`).
  `dir` attributes are left alone. An English-only letter must not call `generalStyle` or
  `bodyStyleCss`, and should position by layout (e.g. `width="100%"`), not left/right words.

## Notification XML: library and signature

- A signature names the **sender** (the responsible library), never the **recipient**.
- `user/library_code` is a **recipient** field and can be a `##`-joined list of every library the
  patron is authorized at (`AS1##RES_SHARE##AM1##AH1##AL1`). A `contains()` per library then
  matches them all (the "all departments" signature bug). Never pick a signature from it.
- Document Delivery: the responsible library is the handling unit,
  `organization_unit/org_scope/library_id` (or `request/library_id`).
- When no XML field names the responsible library, the answer may live only in human-entered
  text (e.g. a title alert's name, in `notification_data/description`): a policy question, not
  an XPath one. Verify each letter separately.

## Patron data

Real notification XML contains patron PII (names, emails, addresses, barcodes). Keep raw exports
out of git and inspect them through an allowlist tool that prints field names and language or
library fields only, never patron values.

## Common mistakes

- Trusting a green local render: Alma checks every template at upload.
- Uploading a letter without the component it now depends on, or after a Sandbox refresh.
- Reading `languages/string` as the patron's language.
- Signing from `user/library_code`.
- Byte-comparing an XSL fetched from Alma with the repo copy.
- Reading a `400` on a letter code as "not available through the API" instead of "wrong code".

## TAU specifics

Library codes and IDs, per-letter analysis, the verification protocol and the tools
(`check_templates.py`, `render_diff.py`, `xml_fingerprint.py`, `letter_prod_snapshot.py`) are in
the TAU-Alma-letters repo (`dev` branch): `docs/alma-xslt-findings.md`,
`docs/verification-protocol.md`, `docs/signature-per-letter-analysis.md`.
