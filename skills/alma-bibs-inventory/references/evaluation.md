# alma-bibs-inventory — evaluation

**Date:** 2026-11-12 · **Type:** self-review (not independent) · **Tracks:** 1 (knowledge accuracy) and,
where cheap, 2 (implementation alignment). Track 3 (agent behaviour) not run.

## Scope and sources

- Skill revision: content as migrated from `alma-api-expert` on 2026-11-12 (SKILL.md, references/bibs-api.md, assets/).
  The Representations subsection of bibs-api.md is out of scope (owned by `alma-digital`).
- Official contract: `https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/bibs.json`
  (OpenAPI 3.0.1, retrieved 2026-11-12) and item schemas
  `.../openapi/schemas/rest_item.json`, `.../openapi/schemas/rest_item-post.json`.
  There is no separate `items.json`; `GET /almaws/v1/items?item_barcode=` is documented inside the
  description of "Retrieve Item" in bibs.json.
- Sandbox: read-only GETs through the evaluation probe `alma_get.py` (GET only, SANDBOX key), run in the
  tau sandbox on 2026-11-12 (Asia/Jerusalem). About 16 calls. The probe prints HTTP status and Alma's
  error *message*, not the numeric error code, so error codes could not be observed.
  Fixture: public bibliographic record 990000000000000002 (one holding, one item, barcode 2239409-10);
  also bib 990000000000000007. No patron data used.
- AlmaAPITK: `/home/hagaybar/projects/AlmaAPITK` at commit `de2013d`, `src/almaapitk/domains/bibs.py`
  and `acquisition.py`.
- Production inference: `Alma-Acquisitions-Automation` `origin/prod` at `1515cc2`
  (`workflows/rialto/workflow.py` calls `acq.receive_and_keep_in_department`, which calls
  `bibs.scan_in_item`). No other repo with an `origin/prod` branch makes bib/holding/item calls.
- Not run: any POST/PUT/DELETE (create item, update item, scan-in, duplicate barcode).

## Claims

Verdicts: documented (official spec only) · sandbox-confirmed (within the tested case) ·
production-inferred · contradicted · unresolved · untested.

| ID | Claim | Where | Verdict | Evidence |
|---|---|---|---|---|
| BI-01 | `GET /bibs` takes identifier params only (mms_id, ie_id, holdings_id, representation_id, nz_mms_id, cz_mms_id, other_system_id, lod_uri, view, expand); no `q` | SKILL traps; bibs-api.md "List / Multi-Fetch", quirks | sandbox-confirmed | Spec param list matches exactly. Sandbox `mms_id=<2 ids>&view=brief` → 200 with 2 bibs |
| BI-02 | No identifier, or `q=`, → HTTP 400 "Parameter missing. Try one of the following: …" | same | sandbox-confirmed | Sandbox: no params → 400; `q=title~history` → 400; message text matches skill verbatim |
| BI-03 | That 400 carries errorCode 401873 | bibs-api.md L21, quirks | unresolved | Spec lists 401873 only for other operations ("Input parameter mms_id is not valid"); probe does not expose the code |
| BI-04 | `mms_id` list up to 100 | bibs-api.md | documented | Spec: "from 1 to the limit of 100" |
| BI-05 | Keyword search belongs to SRU, not REST | bibs-api.md | documented | Spec note on GET /bibs and GET /bibs/{mms_id} points to SRU |
| BI-06 | `GET /bibs/{mms_id}`: view full(default)/brief; expand p_avail, e_avail, d_avail | bibs-api.md | documented | Spec (also lists view=local_fields, ld_enrich and expand=requests) |
| BI-07 | PUT bib needs full MARC XML, application/xml | bibs-api.md | documented | Spec: "JSON is not supported" (error 60105) |
| BI-08 | POST /bibs takes from_nz_mms_id, normalization, validate | bibs-api.md | documented | Spec (also from_cz_mms_id, override_warning, check_match, import_profile) |
| BI-09 | DELETE /bibs/{mms_id} exists | endpoint table | documented | Spec "Delete Bib Record" |
| BI-10 | Holdings: GET list, GET one, POST, PUT under /bibs/{mms_id}/holdings | bibs-api.md | sandbox-confirmed (GETs) | GET list → 200 (1 holding); GET unknown holding → 400 "Search failed for Holdings ID: …". POST/PUT documented only; POST is XML-only per spec |
| BI-11 | Items list `GET …/holdings/{holding_id}/items`, `ALL` allowed | bibs-api.md | sandbox-confirmed | `holdings/ALL/items?limit=2` → 200, 1 item |
| BI-12 | Get item `GET …/items/{item_pid}` | bibs-api.md | sandbox-confirmed | 200 for the fixture item; unknown pid → 400 "No Item found for mmsId …" |
| BI-13 | Get item `view` = "full" (default) or "brief" | bibs-api.md Get Item | contradicted | Spec: default `brief`, only other value `label`; Sandbox view=label → 200 |
| BI-14 | Create item `POST …/holdings/{holding_id}/items` | bibs-api.md | documented | Spec "Create Item" |
| BI-15 | Update item `PUT …/items/{item_pid}` with complete object | bibs-api.md | documented | Path in spec; "complete object" not stated, not tested |
| BI-16 | Get item by barcode via `bibs.search_items("barcode~…")` | Common Operations | contradicted | No such method in AlmaAPITK; no item search endpoint in spec. Spec documents `GET /almaws/v1/items?item_barcode=` (302 redirect) |
| BI-17 | Barcode lookup returns item with embedded `bib_data.mms_id`, `holding_data.holding_id`, `item_data.pid` | Common Operations | sandbox-confirmed | `items?item_barcode=2239409-10` → 200, all three present (client followed the 302); unknown barcode → 400 "No items found for barcode …" |
| BI-18 | Scan-in is `POST …/items/{item_pid}?op=scan` | bibs-api.md, asset | production-inferred | Spec "Scan-in operation on item"; used by prod rialto workflow via `scan_in_item`. Not live-tested (POST) |
| BI-19 | Scan-in `library` mandatory | bibs-api.md | documented | Spec |
| BI-20 | `circ_desk` and `department` are both optional | bibs-api.md, asset | contradicted | Spec: "Send either this parameter or the department parameter"; AlmaAPITK raises if neither |
| BI-21 | Example scan-in with `circ_desk=ACQ` plus work order and `done` | endpoint table | contradicted | Spec: `done` "only relevant when department parameter is sent"; work order goes to a department |
| BI-22 | Scan-in body is empty `<item/>`, application/xml | bibs-api.md, asset | unresolved | Spec defines no request body; AlmaAPITK posts an empty JSON body. Not tested |
| BI-23 | Scan-in to a department keeps a received item out of Transit | bibs-api.md | production-inferred | Prod rialto workflow relies on it; AlmaAPITK docstring; not Sandbox-tested |
| BI-24 | Work order types configured at Configuration > Fulfillment > Physical Fulfillment > Work Order Types; common codes AcqWorkOrder, CatalogingWorkOrder, ConservationWorkOrder | Common Operations | untested | `conf/departments` in Sandbox exposes no work order types; codes are institution-specific |
| BI-25 | `item_pid`, `holding_id`, `barcode`, `library`, `location`, `process_type` are top-level item fields | Item Record Structure | contradicted | Schema and Sandbox: `item_data.pid`, `holding_data.holding_id`, `item_data.barcode/library/location/process_type` |
| BI-26 | `physical_material_type` and `policy` mandatory on create | Validation Rules | untested | Schema does not mark them required; needs a Sandbox POST |
| BI-27 | Process types `acquisition`, `in_transit`, `work_order`, `loan` | Item Process Types | contradicted | Sandbox `PROCESSTYPE` code table: ACQ, TRANSIT, WORK_ORDER_DEPARTMENT, LOAN, MISSING, LOST_LOAN, … ; schema example `ACQ` |
| BI-28 | Base status has "various codes for missing, lost, withdrawn" | Item Statuses | contradicted | Sandbox `BaseStatus` code table has only 0 and 1 |
| BI-29 | `barcode` mandatory for item creation | Item structure, Validation Rules | contradicted | Schema: "If not sent as part of the PUT or POST actions, Alma will generate a barcode" |
| BI-30 | Duplicate barcode → 401660 "Barcode already exists" (asset) | Error Codes, asset | unresolved | Code absent from spec; asset body shape is not Alma's; needs a Sandbox POST with a known barcode |
| BI-31 | MMS ID is 10 digits (9 + Luhn check digit) | Validation Rules, Important Notes | contradicted | Sandbox MMS IDs are 18 digits, `99…<institution suffix>`; Luhn claim unsupported |
| BI-32 | Error codes 401861, 401689, 401694, 401674, 401675 (not found / invalid library/location) | Error Codes | unresolved | None in spec; Sandbox not-found cases return 400 with messages but probe hides codes. 40166411 is documented |
| BI-33 | AlmaAPITK methods get_bib, get_holding, get_item, update_item; file `src/domains/bibs.py`; test `src/tests/test_bibs.py --environment SANDBOX` | AlmaAPITK Implementation, Testing, patterns | contradicted | de2013d: `get_record`, `get_holdings(mms_id, holding_id=None)`, `get_items(mms_id, holding_id="ALL", item_id=None)`, `create_holding`, `create_item`, `scan_in_item(..., circ_desk=None, ..., confirm=True)`; no update_item/get_item; file `src/almaapitk/domains/bibs.py`; tests are mocked unit tests in `tests/unit/domains/test_bibs.py` |
| BI-34 | `search_records()` exists and is a broken q-based method | quirks "Related project notes" | contradicted | No `search_records` in AlmaAPITK de2013d (removed) |
| BI-35 | Base status `0` = not in place, `1` = in place | Item Statuses | sandbox-confirmed | `BaseStatus` code table; fixture item shows `1` "Item in place" |
| BI-36 | `acq.receive_and_keep_in_department(pol_id, item_id, mms_id, holding_id, library, department, work_order_type, work_order_status)` | Related Workflows | production-inferred | Matches AlmaAPITK signature; called this way by prod rialto workflow |
| BI-37 | Update location by setting `item_data.location` and PUT | Common Operations | documented | Schema: PUT changing library/location may move the item to another holding or create one |
| BI-38 | Base URL `api-eu.hosted.exlibrisgroup.com` | bibs-api.md | sandbox-confirmed | `link` fields in Sandbox responses (for this institution) |

Counts: documented 10 · sandbox-confirmed 8 · production-inferred 3 · contradicted 11 · unresolved 4 · untested 2 (total 38).

## Corrections made (2026-11-12)

In `references/bibs-api.md`, each marked "(corrected 2026-11-12, see evaluation BI-xx)":
BI-13 Get Item view values; BI-16 barcode lookup replaced with `GET /almaws/v1/items?item_barcode=` (also added
as an endpoint); BI-20/BI-21 circ_desk-or-department rule and example; BI-25/BI-29 item field layout and
optional barcode (create example moved barcode into `item_data`); BI-27 process-type codes; BI-28 base status;
BI-31 MMS ID format; BI-33 AlmaAPITK methods, file path and tests; BI-34 search_records note marked historical.
BI-22 and BI-32 got an "unverified" note only.
`assets/example_requests/scan_in_item.xml`: circ_desk/department rule (BI-20). `assets/error_examples/...401660...json`:
added `_evaluation_note` marking it illustrative (BI-30).
`SKILL.md`: Maturity paragraph; barcode route and `item_data` layout added to the traps.

## Open / untested

- All writes: create item (required fields BI-26, duplicate barcode BI-30), update item (location move), scan-in
  (body BI-22, effect BI-23). Need an authorised Sandbox fixture item and a bounded write test.
- Error codes (BI-03, BI-32): need a probe that prints `errorList.error[].errorCode` (still no key output).
- Work order types and departments (BI-24): institution configuration; ask the Alma admin or read the UI.
- AlmaAPITK gap (track 2): no barcode lookup and no item update method; skill now points to raw client calls.
