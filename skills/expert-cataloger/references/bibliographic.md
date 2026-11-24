# MARC 21 Bibliographic Format — Working Reference

Authoritative source: https://www.loc.gov/marc/bibliographic/ (1999 ed., through
Update No. 42, May 2026). Per-field pages: `bd<tag>.html`
(e.g., `bd245.html`). This file is condensed; **verify indicators, subfield
lists, and repeatability against the specific LOC field page whenever precision
matters.**

Notation: `R` = repeatable, `NR` = non-repeatable. `#` = blank indicator.

## Contents
- Tag blocks overview
- Fixed fields: Leader, 006, 007, 008
- 0XX control/number/code fields
- 1XX main entry
- 20X–24X title fields
- 25X–28X edition/imprint
- 3XX physical description & RDA fields
- 4XX / 8XX series
- 5XX notes
- 6XX subject access
- 70X–75X added entries
- 76X–78X linking
- 9XX local

## Tag blocks (first digit)

- **0XX** — Control information, numbers, codes
- **1XX** — Main entry
- **2XX** — Titles, edition, imprint
- **3XX** — Physical description, etc.
- **4XX** — Series statements
- **5XX** — Notes
- **6XX** — Subject access
- **7XX** — Added entries (non-subject/non-series), linking
- **8XX** — Series added entries; holdings/location; alternate graphics
- **9XX** — Reserved for local implementation

Final two tag digits recur across blocks: `X00` personal name, `X10` corporate
name, `X11` meeting name, `X30` uniform title, `X40` bibliographic title, `X50`
topical term, `X51` geographic name, `X55` genre/form term.

## Fixed fields

### Leader
See `record-structure.md`. Key for bib: 06 Type of record + 07 Bibliographic
level jointly determine the **008 configuration** and any **006/007** needed.

### 008 — Fixed-Length Data Elements (NR, 40 char positions 00–39)
Positions 00–17 and 35–39 are the same for all materials; **18–34 vary by material**
(selected by Leader/06–07). Do not misalign — 008 is positional, every slot counts.

Common positions (all materials):
- 00–05 Date entered on file (yymmdd)
- 06 Type of date / publication status: `s` single date, `m` multiple, `r`
  reprint/reissue, `t` publication+copyright, `c` continuing/currently published,
  `d` continuing/ceased, `e` detailed date, `n` unknown, `b`, `q`, `u`, `|`
- 07–10 Date 1
- 11–14 Date 2
- 15–17 Place of publication (MARC country code)
- 35–37 Language (MARC language code; matches 041 when present)
- 38 Modified record
- 39 Cataloging source (`#` national bib agency, `c` cooperative, `d` other, `u`)

Material-specific 18–34 configurations (chosen from Leader/06–07):
- **Books** — Leader/06 `a` or `t` with book-type level. 18–21 Illustrations,
  22 Target audience, 23 Form of item, 24–27 Nature of contents, 28 Govt pub,
  29 Conference pub, 30 Festschrift, 31 Index, 33 Literary form, 34 Biography.
- **Continuing Resources (serials)** — Leader/06 `a` + level `b`/`i`/`s`.
  18 Frequency, 19 Regularity, 21 Type of continuing resource, 22 Form of
  original, 23 Form of item, 24 Nature of entire work, 25–27 Nature of contents,
  28 Govt pub, 29 Conference pub, 33 Original alphabet/script of title,
  34 Entry convention.
- **Music** — Leader/06 `c d i j`. **Maps** — `e f`. **Visual Materials** —
  `g k o r`. **Computer Files** — `m`. **Mixed Materials** — `p`.
  Read the LOC 008 page for the exact byte layout of each.

Position 23 (Form of item) note: value `o` = online, `q` = direct electronic — the
usual flags that a resource is electronic.

### 006 — Additional material characteristics (R, 18 char)
Used when a resource has **multiple characteristics** (e.g., an electronic serial
needs a serials 008 *and* a computer-file 006). 006/00 = form of material and
selects the layout, which parallels the 008/18–34 for that material.

### 007 — Physical Description Fixed Field (R, variable length)
Category of material in 007/00 (`a` map, `c` electronic resource, `h` microform,
`s` sound recording, `v` videorecording, etc.); remaining positions coded per
category. Repeat for each physical aspect.

## 0XX — Numbers and codes

- **010** LCCN (NR). `$a` LCCN, `$z` canceled/invalid. Ind. undefined.
- **020** ISBN (R). `$a` ISBN (valid), `$z` canceled/invalid, `$q` qualifier,
  `$c` terms of availability. Ind. undefined.
- **022** ISSN (R). `$a` ISSN, `$l` linking ISSN, `$y` incorrect, `$z` canceled.
  Ind1 = level of international interest.
- **024** Other standard identifier (R). Ind1 = type (`0` ISRC, `1` UPC, `2`
  ISMN, `3` EAN, `7` source in `$2`...). `$a` number, `$2` source.
- **035** System control number (R). `$a` (e.g., OCLC `(OCoLC)...`). Key dedup field.
- **040** Cataloging source (NR). `$a` original agency, `$b` language of
  cataloging, `$c` transcribing agency, `$d` modifying agency, `$e` description
  conventions (e.g., `rda`). Central for provenance.
- **041** Language code (R). `$a` language of text, `$b` summary, `$h` original.
  Ind1 = translation indication.
- **042** Authentication code. **043** Geographic area code (`$a` GAC).
- **050** LC call number (R). Ind2 `0` = assigned by LC, `4` = assigned by others.
  `$a` classification, `$b` item number. **060** NLM, **082** Dewey (`$a` number,
  `$2` edition), **090** local call number.

## 1XX — Main entry (NR — only one 1XX per record)

- **100** Personal name (NR). Ind1: `0` forename, `1` surname, `3` family name.
  `$a` name, `$b` numeration, `$c` titles/words, `$d` dates, `$q` fuller form,
  `$e` relator term, `$4` relator code, `$t` title of a work (name/title).
- **110** Corporate name. Ind1: `0` inverted, `1` jurisdiction, `2` direct.
  `$a` `$b` subordinate unit, `$e` relator.
- **111** Meeting name. Ind1 as 110. `$a` `$n` number, `$d` date, `$c` location.
- **130** Uniform title (main entry). Ind1 = nonfiling chars. `$a` `$l` language,
  `$s` version, `$n` `$p` part.

A record has a 1XX **only if** there is an authorized main-entry access point;
title main entry lives in 245 with 245 Ind1 = 0 (no 1XX). This linkage is a
frequent source of error — check it.

## 20X–24X — Title and title-related

- **210** Abbreviated title, **222** Key title (serials).
- **240** Uniform title (used *with* a 1XX). Ind1 = printed/displayed,
  Ind2 = nonfiling characters.
- **245** Title statement (**NR, required in every record**). Ind1: `1` = a 1XX
  is present (make an added title entry), `0` = no 1XX (title main entry).
  Ind2 = number of nonfiling characters (0–9) for leading articles.
  `$a` title proper, `$b` remainder of title (other title info / parallel),
  `$c` statement of responsibility, `$h` medium (GMD — largely dropped under RDA
  in favor of 33X), `$n` number of part, `$p` name of part, `$f` `$g` `$k` `$s`.
- **246** Varying form of title (R). Ind1 controls note/added-entry & print;
  Ind2 = type of title (cover, spine, etc.). **247** Former title.

## 25X–28X — Edition, imprint

- **250** Edition statement (R). `$a` edition, `$b` remainder.
- **255** Cartographic mathematical data. **256** Computer file characteristics.
- **260** Publication/Distribution (**Imprint, AACR2 style**) (R). `$a` place,
  `$b` publisher, `$c` date.
- **264** Production/Publication/Distribution/Manufacture/Copyright (**RDA**) (R).
  Ind2 = function: `0` production, `1` publication, `2` distribution,
  `3` manufacture, `4` copyright notice date. `$a` place, `$b` name, `$c` date.
  Under RDA, **264** replaces 260; a copyright date uses a separate 264 _4 with
  `©`/`℗`.

## 3XX — Physical description and RDA content/media/carrier

- **300** Physical description (R). `$a` extent, `$b` other physical details,
  `$c` dimensions, `$e` accompanying material.
- **310/321** Current/former publication frequency (serials).
- **336** Content type (R) — RDA. `$a` term, `$b` code, `$2 rdacontent`.
- **337** Media type (R) — RDA. `$2 rdamedia`.
- **338** Carrier type (R) — RDA. `$2 rdacarrier`.
  (336/337/338 are the RDA replacement for the old GMD in 245 `$h`.)
- **340** Physical medium, **344–347** sound/video/digital characteristics.
- **362** Dates of publication/sequential designation (serials).
- **380–388** Form of work, other distinguishing characteristics, etc.

## 4XX / 8XX — Series

- **490** Series statement (R). Ind1: `0` series **not** traced, `1` series traced
  differently (in an 8XX). `$a` series statement, `$v` volume/number, `$x` ISSN.
  Note: 490 is the transcribed form; the *traced/controlled* form goes in 800/810/
  811/830. If 490 Ind1 = 1, there must be a corresponding 8XX.
- **800** Series added entry–personal name, **810** corporate, **811** meeting,
  **830** uniform title (R). These carry the authorized series access point.
  (Field 440, the old traced series title, is **OBSOLETE** — do not use; use
  490/830.)

## 5XX — Notes (all R)

- **500** General note. **502** Dissertation note (`$b` degree, `$c` institution,
  `$d` year). **504** Bibliography note. **505** Formatted contents (Ind1 controls
  display; `$t` title, `$r` responsibility with enhanced Ind2 `0`).
- **506** Restrictions on access, **508** Creation/production credits,
  **511** Participant/performer, **520** Summary/abstract (Ind1 controls label),
  **521** Target audience, **526** Study program.
- **530** Additional physical form, **533** Reproduction note, **534** Original
  version, **538** System details (e.g., "System requirements"), **540** Terms
  governing use, **546** Language note.
- **588** Source of description note (RDA; e.g., "Description based on...").
Guidance: a **specific** field is preferred over 500 whenever categorical
indexing, special manipulation, or a data standard requires it. Do not dump into
500 what belongs in 504/505/520/546/588.

## 6XX — Subject access (all R)

- Ind2 = **thesaurus/subject system**: `0` LCSH, `1` LC children's (AC),
  `2` MeSH, `3` NAL, `4` source not specified, `5` Canadian, `6` RVM,
  `7` source specified in `$2` (then add `$2 fast`, `$2 lcgft`, etc.).
- **600** Personal name subject (Ind1 as 100). **610** Corporate, **611** Meeting.
- **630** Uniform title subject. **648** Chronological term.
- **650** Topical term (Ind1 = level of subject). **651** Geographic name.
- **653** Uncontrolled index term. **655** Genre/form term (with `$2 lcgft`,
  `$2 gsafd`, etc.). **656/657/658/662** specialized.
Subject subdivisions: `$v` form, `$x` general, `$y` chronological, `$z` geographic.

## 70X–75X — Added entries

- **700** Personal name added entry (R). Ind1 as 100; Ind2: `#` no info, `2`
  analytical entry. `$a … $t` for name/title (analytic) added entries;
  `$e`/`$4` relator; `$i` relationship information (RDA).
- **710** Corporate, **711** Meeting, **730** Uniform title added entry.
- **740** Uncontrolled related/analytical title. **751** Geographic name added
  entry. **752** Hierarchical place name.

## 76X–78X — Linking entries (all R)

Ind1 = note controller; Ind2 = display constant/type. `$t` title, `$x` ISSN,
`$z` ISBN, `$w` record control number, `$g` relationship info.
- **760** Main series, **762** Subseries, **765** Original language,
  **767** Translation, **770** Supplement, **772** Parent of supplement,
  **773** Host item (used in component-part records), **774** Constituent unit,
  **775** Other edition, **776** Additional physical form, **777** Issued with,
  **780** Preceding entry (serials; Ind2 continues/replaces...),
  **785** Succeeding entry, **787** Other relationship.

## 841–88X — Holdings, alternate graphics, local

- **856** Electronic location and access (R). Ind1 = access method (`4` = HTTP),
  Ind2 = relationship (`0` resource itself, `1` version, `2` related). `$u` URI,
  `$y` link text, `$z` public note, `$3` materials specified.
- **880** Alternate graphic representation (R) — vernacular/non-Latin script,
  linked to its Roman-script partner via `$6`.
- **9XX** (and 490 historically, indicator `9`, subfield `$9`) — **local**. MARC
  assigns no meaning; behavior is by local/ILS agreement (e.g., 999 in many ILSs).

## Common control subfields (across data fields)
- `$0` Authority record control number / URI (links to an authority; RDA-era
  linked-data hook).
- `$1` Real World Object URI.
- `$2` Source of term/scheme (paired with Ind2 `7` in 6XX; also 336–338, 655).
- `$3` Materials specified. `$5` Institution to which field applies.
- `$6` Linkage (to 880). `$8` Field link and sequence number.
