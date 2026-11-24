# MARC 21 Authority Format — Working Reference

Authoritative source: https://www.loc.gov/marc/authority/ (through Update No. 39,
Dec 2024). Per-field pages: `ad<tag>.html`. Verify details against LOC.

## Purpose

The Authority format carries the **authorized (established) forms** of names,
subjects, and subject subdivisions used to build access points in bibliographic
records, the **variant forms** that should refer to them, and the
**relationships** among them. Authority control is what keeps a catalog's access
points consistent — every 1XX/6XX/7XX/8XX heading in a bib record should trace
back to an authorized heading here.

Authority records are marked by **Leader/06 = `z`** (Type of record = Authority
data).

## Kinds of authority records — 008/09 (Kind of record)

- `a` **Established heading** — 1XX contains an established name or subject.
- `b`/`c` **Reference** (traced / untraced) — 1XX is an *unestablished* form;
  the record points to the established form via 260/664/666.
- `d` **Subdivision** — 18X holds a term usable only as a subject subdivision.
- `e` **Node label** — 150 holds a thesaurus systematic-section label.
- `f` **Established heading and subdivision** — usable as heading *and* as a
  subdivision.
- `g` **Reference and subdivision.**

Other key 008 positions: 008/10 = descriptive cataloging rules (name authority
structure, e.g. `z` = other/RDA via 040 `$e`), 008/11 = subject heading system/
thesaurus, 008/14–16 = heading use as main/added, subject, and series added entry.

## Tag blocks

- **0XX** Standard/classification numbers, codes
- **1XX** Heading (established or unestablished) — **only one 1XX per record**
- **2XX** Complex see references
- **3XX** Complex see also references
- **4XX** See from tracings (variant forms → "search under")
- **5XX** See also from tracings (related established headings)
- **6XX** Reference notes, treatment decisions, notes
- **7XX** Heading linking entries (links to other systems/languages)
- **8XX** Alternate graphics
- **9XX** Local

Final-two-digit parallels: `X00` personal, `X10` corporate, `X11` meeting,
`X30` uniform title, `X48` chronological term, `X50` topical term, `X51`
geographic, `X55` genre/form, `X80` general subdivision, `X81` geographic
subdivision, `X82` chronological subdivision, `X85` form subdivision.

## Core fields

### 0XX
- **010** LCCN of the authority record (`$a` = the LCCN referenced by bib `$0`).
- **035** System control number. **040** Source (`$a`/`$c`/`$d`; `$e` = rules,
  `$f` = subject/thesaurus conventions).
- **053** LC classification range. **065/060/080/082/083** classification.
- **1XX-linked coded fields:** 043 GAC, 034/family fields, **046** special coded
  dates (birth/death/start/end — RDA attributes), **336/368/370–388** RDA
  attribute fields (field of activity, associated place, occupation, gender,
  etc.).

### 1XX — Heading (the established/authorized form)
- **100** Personal, **110** Corporate, **111** Meeting, **130** Uniform title,
  **148** Chronological, **150** Topical, **151** Geographic, **155** Genre/form,
  **180/181/182/185** subdivisions.
Indicators and name subfields parallel the bibliographic 1XX fields (e.g., 100
Ind1 `0`/`1`/`3`; `$a $b $c $d $q $t`). Subject subdivision subfields `$v $x $y
$z` extend a heading.

### 4XX — See from tracings (variant forms)
Same tag structure as 1XX (400/410/411/430/448/450/451/455…). Each 4XX is a form
that should **refer the user to** the 1XX. `$w` (control subfield) and `$i`
(relationship information, RDA) refine the reference. Example: on the authority for
*Twain, Mark*, a **400 1# `$a Clemens, Samuel Langhorne...`** produces "Clemens,
Samuel — search under Twain, Mark."

### 5XX — See also from tracings (related established headings)
Same structure (500/510/511/530/550/551/555…). Points between two *established*
headings (e.g., earlier/later corporate name, broader/narrower/related subject).
`$w/0` codes the relationship (e.g., `a` earlier, `b` later, `g` broader,
`h` narrower). `$i` gives RDA relationship designators.

### 260 / 360 / 663–666 — Complex references and notes
Free-text "see"/"see also" guidance when a simple tracing is insufficient
(260 complex see – subject; 360 complex see also – subject; 664 complex see –
name; 665 history reference; 666 general explanatory – name).

### 7XX — Heading linking entries
Link this heading to the equivalent in another authority file, thesaurus, or
language (Ind2 = system; `$0`/`$1` control numbers/URIs, `$2` source, `$4`/`$e`
relationship). The linked-data / multilingual authority hook.

## How authorities connect to bib records
A bib access point (1XX/6XX/7XX/8XX) is "controlled" when its text matches an
authority 1XX; increasingly the link is explicit via bib **`$0`** = the authority
record control number/URI. When validating or cleaning bib data, checking headings
against the authority file (and LC/NACO/LCSH via https://id.loc.gov/) is the
authority-control step. Note MADS (https://www.loc.gov/standards/mads/) is the XML
counterpart of the authority format.
