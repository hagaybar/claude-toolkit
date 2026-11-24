# LOC Lookup Map — where to verify, fast

The Library of Congress is the authoritative source. Fetch the **specific** page
rather than searching, so you can quote current text. URL patterns below let you
jump straight to a field.

## Format home pages (table of contents)
- Bibliographic: https://www.loc.gov/marc/bibliographic/
- Authority: https://www.loc.gov/marc/authority/
- Holdings: https://www.loc.gov/marc/holdings/
- Classification: https://www.loc.gov/marc/classification/
- Community Information: https://www.loc.gov/marc/community/
- Concise (all five, abridged): https://www.loc.gov/marc/concise/

## Per-field page URL patterns
Replace `<tag>` with the three-digit tag.
- **Bibliographic field**: `https://www.loc.gov/marc/bibliographic/bd<tag>.html`
  - Leader: `.../bibliographic/bdleader.html`
  - 006: `.../bd006.html` · 007: `.../bd007.html` · 008: `.../bd008.html`
  - Example: field 245 → `https://www.loc.gov/marc/bibliographic/bd245.html`
  - Concise version: `.../bibliographic/concise/bd<tag>.html`
- **Authority field**: `https://www.loc.gov/marc/authority/ad<tag>.html`
  (Leader `adleader.html`, 008 `ad008.html`).
- **Holdings field**: `https://www.loc.gov/marc/holdings/hd<tag>.html`
  (some are grouped, e.g. `hd852856.html`, `hd853855.html`, `hd863865.html`,
  `hd866868.html`; the TOC at the holdings home page lists exact filenames).

Tip: if a `bd008.html`-type fetch returns empty (the 008 pages are large), try the
concise version, or the material-specific 008 in context via the Leader page's
dependency table, or fetch again.

## Record structure & character sets (the physical spec)
- Specifications home: https://www.loc.gov/marc/specifications/spechome.html
- Record structure: https://www.loc.gov/marc/specifications/specrecstruc.html
- Character sets: https://www.loc.gov/marc/specifications/speccharintro.html
- Background and principles: https://www.loc.gov/marc/96principl.html

## Code lists (controlled values used inside fields)
- Countries (008/15-17, 044): https://www.loc.gov/marc/countries/
- Geographic Areas / GAC (043): https://www.loc.gov/marc/geoareas/
- Languages (008/35-37, 041): https://www.loc.gov/marc/languages/
- Organizations / MARC org codes (003, 040, 852 $a): https://www.loc.gov/marc/organizations/
- Relators (`$e`/`$4`): https://www.loc.gov/marc/relators/
- Other value lists: https://www.loc.gov/standards/valuelist/
- Sources (the `$2` codes: rdacontent, lcgft, fast, aat...): https://www.loc.gov/standards/sourcelist/

## Linked-data / authority data
- id.loc.gov (LCSH, LC Name Authority, LCGFT, MARC lists as linked data): https://id.loc.gov/
- Authorities & Vocabularies: browse names and subjects to confirm authorized forms.

## XML and related schemas / crosswalks
- MARCXML (schema + tools): https://www.loc.gov/standards/marcxml/
- MODS (bibliographic XML) + MARC↔MODS mapping: https://www.loc.gov/standards/mods/
- MADS (authority XML): https://www.loc.gov/standards/mads/
- BIBFRAME (the linked-data successor initiative): https://www.loc.gov/bibframe/
- Crosswalks index (Dublin Core, ONIX, etc.): https://www.loc.gov/marc/marcdocz.html

## Change tracking / currency
- MARC updates & announcements: https://www.loc.gov/marc/status.html and
  https://www.loc.gov/marc/marcginf.html
- Each format home page states the latest Update number and date; changes from the
  latest update are shown in **red** on the field pages. When a user asks whether
  something is current/obsolete/new, this is where to confirm.

## How to use in an answer
1. Answer from the bundled reference for speed.
2. If precision matters (exact indicator value, R/NR, obsolete/new status),
   fetch the specific page above and quote it.
3. Cite the URL so the user can re-verify. Example citation style:
   "per LOC MARC 21 Bibliographic, field 264 — https://www.loc.gov/marc/bibliographic/bd264.html".
