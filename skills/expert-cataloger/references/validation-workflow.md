# Validating & Troubleshooting a MARC Record

A repeatable method for "is this record valid / fix this record." Work top-down:
structure first (these errors break loading), then content designation, then
content/best-practice. Report findings grouped by that severity so the user knows
what will actually stop a load versus what is merely suboptimal.

## Step 0 — Establish context
Identify the format (bib/authority/holdings) from **Leader/06**, and the material
(Leader/06+07) so you know which 008/006/007 layout applies. Ask for the content
standard if it matters (assume **RDA** for current academic cataloging unless the
record says otherwise via 040 `$e` / Leader/18).

## Step 1 — Structural validity (breaks the record)
- **Leader** present, 24 chars, positions 10/11 = `2`, 20-23 = `4500`,
  09 matches the actual encoding (`#` MARC-8 vs `a` Unicode).
- **Directory / lengths** consistent (if you have raw ISO 2709). Remember the hard
  limits: **field ≤ 9999 octets, record ≤ 99999 octets** — overflow means the
  record must go to MARCXML.
- Every field ends with a field terminator; record ends with a record terminator.
- **Encoding sanity**: garbled diacritics = MARC-8/UTF-8 mismatch with Leader/09.

## Step 2 — Content designation (valid but mis-tagged)
For each field:
- **Tag exists** for this format and is **not obsolete** (e.g., 440 is obsolete →
  use 490/830; verify uncertain ones on LOC).
- **Indicators** are defined values for that field (or blank where blank is
  allowed). Watch the high-value traps:
  - **245 Ind1**: `1` requires a 1XX to exist; `0` means title main entry (no 1XX).
  - **245 Ind2 / 240 Ind2 / 830 Ind2 / 130 Ind1**: nonfiling-character count must
    match the actual leading article + space (e.g., "The " = 4).
  - **6XX Ind2**: subject-system code; if `7`, a **`$2`** source is required.
  - **490 Ind1 = 1** requires a matching **8XX** traced series.
- **Subfield codes** are defined for that field and in a sensible order.
- **Repeatability (R/NR)** respected — e.g., only one **245**, one **1XX**, one
  **008**; 001/005 never repeat. Confirm R/NR on the LOC field page when unsure.

## Step 3 — Required elements & internal consistency
- **Leader, 008, and 245** present (245 is required in every bib record).
- 008 is **correctly aligned** and its material layout matches Leader/06-07.
- **Coherence across fields**: 008/35-37 language agrees with 041; 008/15-17
  place agrees with 260/264 `$a` and 043; date type/dates in 008/06-14 agree with
  260/264 `$c` and 362; ISBN/ISSN in 020/022 valid; 300 extent agrees with the
  material and with 33X.
- **RDA completeness** (if RDA): 336/337/338 present; 264 used instead of 260;
  040 `$e rda`; relationship designators in `$e`/`$i` where appropriate.
- **Access-point control**: 1XX/6XX/7XX/8XX headings should match authorized forms
  (authority control); `$0`/`$1` links are a plus. Flag headings that look
  unestablished.

## Step 4 — Content standard & best practice (won't break, but hurts quality)
- **ISBD punctuation** where the record claims ISBD (Leader/18 = `i`/`a`): e.g.,
  ` : ` before 245 `$b`, ` / ` before 245 `$c`, ` ; ` before subsequent SORs.
- **Right field for the data** — the single biggest quality issue. Data forced
  into a generic 500 that belongs in 504/505/520/546/588 won't index or display
  properly. Series in 490 only, with no 830, loses controlled series access.
- **Fixed fields actually coded** rather than left as fills/defaults when the info
  is known (literary form, index, audience, form of item for e-resources, etc.).

## Reporting template
Present results like this:

```
STRUCTURAL (must fix — record may not load)
  - <problem> → <fix>, because <why>

CONTENT DESIGNATION (invalid tag/indicator/subfield/repeatability)
  - <field>: <problem> → corrected field, because <why>

CONTENT / BEST PRACTICE (valid but suboptimal)
  - <field>: <observation> → suggestion, because <downstream cost>
```

Always **show the corrected field** in MARC line notation and explain the *why* —
a cataloger learns from the reasoning, and it lets them judge whether a
"best-practice" suggestion fits local policy.

## When to reach for LOC
Any time you are asserting an exact indicator value, a subfield's R/NR, or whether
a field/value is obsolete or newly added, verify on the specific LOC field page
(see `loc-lookup-map.md`) and cite it. A confident guess that's one update stale
is exactly how bad data enters a catalog.

## Automation-friendly checks
For batch validation, these map cleanly to code (pymarc/MarcEdit):
- Leader positions 10/11/20-23 fixed values; Leader/09 vs. byte encoding.
- Presence of Leader, 008 (correct length per material), 245.
- Only-one checks: 245, 1XX, 008, 001, 005.
- Indicator value whitelist per tag; subfield code whitelist per tag.
- `$2` required when 6XX Ind2 = 7; 8XX required when 490 Ind1 = 1.
- ISBN-10/13 and ISSN checksum validation for 020/022.
Keep the tag/indicator/subfield rule tables sourced from LOC so they stay current.
