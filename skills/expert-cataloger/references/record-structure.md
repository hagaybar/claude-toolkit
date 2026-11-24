# MARC 21 Record Structure

Source of truth: LOC *MARC 21 Specifications for Record Structure, Character Sets,
and Exchange Media* — https://www.loc.gov/marc/specifications/specrecstruc.html

MARC 21 implements **ANSI/NISO Z39.2** (*Information Interchange Format*) and its
international counterpart **ISO 2709** (*Format for Information Exchange*). Those
standards define a generalized record *structure* but do **not** assign meaning to
tags, indicators, or subfield codes — MARC 21 supplies that meaning.

## Anatomy of a record

A MARC record has three parts, in this physical order:

```
LEADER  DIRECTORY  FT  001-field  FT  other-control-fields ... FT  data-fields ... FT  RT
```

- **FT** = field terminator, ASCII `1E` hex (record separator). Ends the
  Directory and every variable field.
- **RT** = record terminator, ASCII `1D` hex (group separator). Final character
  of the whole record.
- **Delimiter** = ASCII `1F` hex (unit separator), shown as `$` (or `‡`),
  precedes each subfield code.

Everything — including all the length numbers — is character-encoded.

## Leader (24 octets, character positions 00–23)

Fixed-length, first field of every record, only ASCII graphic characters. Many
positions are system-generated. Positions common to all formats:

| Pos | Name | Notes |
|-----|------|-------|
| 00–04 | Logical record length | 5 digits, right-justified, zero-filled. Max record = **99999 octets**. System-generated. |
| 05 | Record status | e.g. `n` new, `c` corrected/revised, `d` deleted, `a`/`p` encoding-level increase. |
| 06 | Type of record | Defines the material; **drives 006/007/008**. (Bib values below.) |
| 07 | Bibliographic level (bib) / Kind of data (community) | Bib: `a` mono component part, `b` serial component part, `c` collection, `d` subunit, `i` integrating resource, `m` monograph/item, `s` serial. |
| 08 | Type of control (bib) | `#` none, `a` archival. |
| 09 | Character coding scheme | **`#` = MARC-8, `a` = UCS/Unicode (UTF-8)**. Critical for encoding. |
| 10 | Indicator count | Always `2` in MARC 21. |
| 11 | Subfield code count | Always `2` in MARC 21. |
| 12–16 | Base address of data | 5 digits = length of Leader + Directory (incl. its FT). System-generated. |
| 17 | Encoding level | `#` full, `1` full/not examined, `2` less-than-full, `3` abbreviated, `4` core, `5` partial/prelim, `7` minimal, `8` prepublication (CIP), `u` unknown, `z` n/a. |
| 18 | Descriptive cataloging form | `#` non-ISBD, `a` AACR2, `c` ISBD punct. omitted, `i` ISBD punct. included, `n` non-ISBD punct. omitted, `u` unknown. (RDA records typically `i`.) |
| 19 | Multipart resource record level | `#` n/a, `a` set, `b` part w/ independent title, `c` part w/ dependent title. |
| 20 | Length of length-of-field portion | Always `4`. |
| 21 | Length of starting-char-position portion | Always `5`. |
| 22 | Length of implementation-defined portion | Always `0`. |
| 23 | Undefined | Always `0`. |

Positions 20–23 are the **entry map**. In MARC 21 the Leader always ends `4500`.

**Leader/06 Type of record (bibliographic):** `a` language material, `c` notated
music, `d` manuscript notated music, `e` cartographic, `f` manuscript
cartographic, `g` projected medium, `i` nonmusical sound recording, `j` musical
sound recording, `k` two-dimensional nonprojectable graphic, `m` computer file,
`o` kit, `p` mixed materials, `r` three-dimensional artifact, `t` manuscript
language material.

## Directory

Starts at character position 24, ends with an FT. Series of fixed **entries**, one
per variable field, each **12 characters**:

```
TAG(00-02)  LENGTH-OF-FIELD(03-06)  STARTING-CHAR-POSITION(07-11)
```

- **Tag** — 3 characters (MARC 21 uses numeric only). Stored *only* in the
  directory, not in the field itself.
- **Length of field** — 4 digits including indicators, subfield codes, data, and
  the field's FT. So a **single field is capped at 9999 octets**; very large
  fields force the record out of binary MARC into MARCXML.
- **Starting character position** — 5 digits, relative to the base address of
  data.

Order: control-field entries first (by tag ascending), then data-field entries (by
first tag character; numerics before alphabetics). The stored order of the actual
data fields need not match the directory order.

## Variable fields

Two kinds:

- **Control fields (00X)** — tags begin with two zeroes (`001`–`00X`). Contain
  data + FT only: **no indicators, no subfield codes.** Either a single string
  (001, 003, 005) or positionally-defined fixed-length data (006, 007, 008).
- **Data fields (all other tags)** — structure:
  `IND1 IND2 $code data ... $code data FT`
  - **Two indicators**, one character each, always present even when undefined
    (`#` = blank/undefined). May be lowercase alpha, numeric, or blank.
    Interpreted independently — never as a two-character pair. Value `9` is
    reserved for local use.
  - **Subfield codes** — delimiter + a one-character data element identifier
    (lowercase alpha or digit). Numeric codes usually carry processing/control
    data; alphabetic codes carry the content elements. `$9` and the graphic-symbol
    identifiers are reserved for local use.

`001` (Control Number) is the first variable field, sits at the base address of
data, and is **non-repeatable** — as is `005` (Date and Time of Latest
Transaction). Theoretically every other field and subfield may repeat; the
format's R/NR labels say when the data precludes it.

## Character sets: MARC-8 vs. Unicode

Leader/09 declares the encoding. **`#` = MARC-8** (the legacy 8-bit MARC character
sets, with escape sequences for non-Latin scripts; non-default sets named in field
066). **`a` = UCS/Unicode**, in practice **UTF-8**. Mismatches between the declared
scheme and the actual bytes are the classic cause of *mojibake* (garbled
diacritics) on import/export. When migrating, confirm Leader/09 matches reality and
transcode deliberately (MarcEdit and pymarc both do this). Field **880** holds the
alternate-graphic (vernacular script) representation of another field, linked via
`$6`.

## Coded-data conventions (common fixed-field values)

- `#` (blank) — undefined / not applicable in some positions
- `n` — not applicable
- `u` — unknown (creator could not determine)
- `z` — other
- `|` (fill, ASCII 7C) — "no attempt to code." Not allowed in Leader, tags,
  indicators, or subfield codes.

## Transport / serialization formats

- **ISO 2709 binary** — the classic `.mrc` file. Subject to the 9999/99999 octet
  limits above.
- **MARCXML** — LOC's XML serialization (schema at
  https://www.loc.gov/standards/marcxml/). No octet-length limits; best for very
  large records and for pipelines. Lossless round-trip with binary MARC.
- **MARC line/mnemonic** (e.g., MarcEdit's `.mrk`) — human-readable, `=245 10$a...`
  style. For editing, not exchange.

When any of these mechanics matter to an answer (loading errors, encoding,
migration), re-read this file and, for exact byte-level questions, consult the LOC
specifications pages listed in `loc-lookup-map.md`.
