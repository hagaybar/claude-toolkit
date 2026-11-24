# MARC 21 Holdings Format — Working Reference

Authoritative source: https://www.loc.gov/marc/holdings/ (2000 ed., through Update
No. 25, Dec 2017). Per-field pages: `hd<tag>.html`. Verify against LOC.

## Purpose

The Holdings format records **what a library actually holds** of a resource —
location, call number, and which volumes/issues/parts are present — separate from
the bibliographic description of the resource itself. It is essential for serials
(where a library owns some run of many issues) and for multi-copy/multi-location
holdings. Holdings records are marked by **Leader/06 = `u`, `v`, `x`, or `y`**
(the four holdings type-of-record codes: single-part `x`, multipart `v`,
serial `y`, and `u` unknown).

Leader/17 (Encoding level) here signals the **holdings level** per ANSI/NISO
Z39.71: `1`–`4` = holdings levels 1–4 (1 = item + location identifiers only;
2 = adds coded 008/007; 3 = adds *summary* enumeration/chronology; 4 = adds
*detailed* enumeration/chronology), `5` = level 4 with piece designation,
`m` = mixed level, `u` = unknown, `z` = other. Leader/18 = `i`/`n` flags whether
item information (876–878) is present. Leader/06 pairs with 008 to describe the
holdings.

## Tag blocks
Most blocks are undefined in holdings; the meaningful ones:
- **00X** Control fields (001, 004 = control number of the related bib record,
  005, 007 physical description, 008 holdings fixed field)
- **0XX** Numbers/codes
- **5XX / 84X** Notes
- **852** Location; **856** Electronic access
- **853–855** Captions and pattern
- **863–865** Enumeration and chronology
- **866–868** Textual holdings
- **876–878** Item information
- **9XX** Local

Field **004** links the holdings record to its bibliographic record's control
number — the join between the two.

## 008 — Holdings fixed field (32 positions)
Includes 06 Receipt/acquisition status, 07 Method of acquisition, 08–11 Expected
acquisition end date, 12 General retention policy, 16 Completeness, 17–19 Number
of copies reported, 20 Lending policy, 21 Reproduction policy, 26–31 Date of
report. Positional — align carefully.

## 852 — Location (NR-ish; the anchor field)
Ind1 = shelving scheme (`0` LC, `1` Dewey, `2` NLM, `3` SuDoc, `8` other...).
Ind2 = shelving order.
- `$a` location (institution/MARC org code)
- `$b` sublocation/collection (e.g., branch, unit)
- `$c` shelving location
- `$h` classification part of call number, `$i` item part
- `$k` call number prefix, `$m` suffix
- `$p` piece designation (barcode), `$t` copy number
- `$x` nonpublic note, `$z` public note
852 is where "where is it / what's the call number" lives.

## 853–855 + 863–865 — The captions/pattern ↔ enumeration/chronology pair
This is the compressed, machine-actionable way to state serial holdings.

- **853** Captions and pattern — Basic bibliographic unit. Defines the *labels*
  and publication *pattern*: `$a`–`$h` enumeration captions (v., no.),
  `$i`–`$m` chronology captions (year, month), `$8` link number, `$w` frequency,
  `$y` regularity. (854 = supplementary material; 855 = indexes.)
- **863** Enumeration and chronology — the actual holdings values that fill the
  853 pattern: `$8` = linknumber.sequence tying it to its 853, then `$a`–`$h`
  enumeration values, `$i`–`$m` chronology values. (864 = supplements, 865 =
  indexes.)

The `$8` subfield's *link number* joins an 863 to its governing 853 (e.g., 853
`$8 1`, 863 `$8 1.1`, `1.2`, …). Systems expand these into human-readable runs.

## 866–868 — Textual holdings
Free-text holdings statement when the coded 853/863 pair is not used or not
sufficient: **866** basic bibliographic unit (`$a` = e.g., "v.1-25 (1970-1995)"),
867 supplements, 868 indexes. Ind1/Ind2 describe field encoding level and type of
notation (often ANSI/NISO Z39.71). Easier to author by hand; less machine-actionable
than 853/863.

## Practical notes
- For most academic serials workflows, catalogers author **866** textual holdings
  or let the ILS generate 863 from a **853** predictive pattern plus check-in data.
- When migrating serials, decide early whether holdings travel as coded (853/863)
  or textual (866); the two express the same facts at different granularity.
- Item-level data (barcodes, status, price) sits in **876–878** when holdings are
  carried in MARC, though many ILSs keep item data in their own tables rather than
  in exported MARC holdings.
