---
name: alma-bibs-inventory
description: Alma Bibs API for catalogue and physical inventory — bibliographic records (fetch by identifier; /bibs has no keyword search), holdings, items (get by barcode, scan-in to a department, update location, create with barcode), item process types and statuses, and their errors (e.g. duplicate barcode). Use when building, debugging or explaining Alma bib/holding/item API work. Digital representations are in alma-digital, POL receiving in alma-acquisitions-specialist, other Alma API areas in alma-api-expert.
---

# Alma Bibs and Inventory

Help the agent read and change bibliographic records, holdings and items through
`/almaws/v1/bibs/...`.

**Maturity: partly validated (2026-11-12).** Moved from `alma-api-expert`, then checked
claim by claim against the official OpenAPI spec, read-only Sandbox GETs and AlmaAPITK: 21 of
38 claims hold; 11 were wrong and corrected in place (item field layout, process-type codes, scan-in
circ_desk/department rule, AlmaAPITK method names, barcode lookup). Error codes and all writes
(create, update, scan-in) are not live-tested; see [evaluation.md](references/evaluation.md).

## Traps worth knowing up front

- `GET /almaws/v1/bibs` fetches by identifier only (`mms_id`, up to 100, and other ID
  parameters). It has no keyword search; a call without an identifier returns 400.
- Item hierarchy is bib → holding → item; most item calls need all three IDs.
- Get an item by barcode with `GET /almaws/v1/items?item_barcode={barcode}` (302 to the full
  item URL; returns `bib_data`, `holding_data`, `item_data.pid`). Sandbox-confirmed.
- Item identifier, barcode, library, location and `process_type` sit under `item_data`;
  process types are codes like `ACQ`, `TRANSIT`, `WORK_ORDER_DEPARTMENT`.

## Find the detail

- Endpoints, structures, common operations, process types, statuses, scan-in:
  [bibs-api.md](references/bibs-api.md)
- Example scan-in request and a duplicate-barcode error: `assets/`

For MARC content itself (fields, indicators, cataloguing rules) use `expert-cataloger`.

## Before a write

Confirm the item by barcode and current status first, work in Sandbox, read the result back.
A Sandbox success does not authorise Production.
