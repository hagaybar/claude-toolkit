# Evaluation: alma-resource-sharing

- **Date:** 2026-11-12 (Sandbox reads run 2026-11-12, ~08:30–09:00 IST)
- **Reviewer:** agent self-review, following `alma-api-knowledge-evaluator` (not an independent validation)
- **Tracks:** 1 (knowledge accuracy) fully; 2 (implementation alignment with AlmaAPITK) where cheap; 3 (agent behaviour) not run
- **Skill revision reviewed:** content as migrated from `alma-api-expert` on 2026-11-12 (pre-correction)

## Sources

- Official OpenAPI (retrieved 2026-11-12):
  - https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/partners.json
  - https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/users.json
  - https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/tasklists.json
  - https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/schemas/rest_user_resource_sharing_request.json (GET shape)
  - https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/schemas/rest_user_resource_sharing_request-post.json (POST shape, used by both lending and borrowing create)
  - https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/schemas/rest_rs_request_details.json (`rs_notes`, `amount`)
  - XSD: https://developers.exlibrisgroup.com/wp-content/uploads/alma/xsd/rest_user_resource_sharing_request.xsd
- Sandbox: read-only GETs via the `.skill-eval/alma_get.py` helper in the tau sandbox (about 20 calls). Code tables, `GET /partners`, `GET /partners/{code}/lending-requests/{id}`, `GET /task-lists/rs/lending-requests?library=AM1` (66 lending requests, aggregated as field shapes and code counts only; no personal data recorded). No POST/PUT/DELETE.
- AlmaAPITK: `/home/hagaybar/projects/AlmaAPITK` at commit `de2013d` (v0.5.1), read-only.
- Production: `Alma-RS-lending-request-automation` branch `origin/prod` at commit `7fb817a` (2026-10-25), read-only (`git show`/`git grep`). Lending uses `ResourceSharing.create_lending_request_from_citation`; borrowing uses `build_user_rs_request` + `Users.create_user_rs_request`.

## Claims

Verdicts: **documented** (official reference states it; not live-tested here) · **sandbox-confirmed** (scope stated) · **production-inferred** (shape used by scheduled prod code) · **contradicted** · **unresolved** · **untested**. "Source" marks a code-reading observation.

| ID | Claim | Where | Verdict | Evidence |
|---|---|---|---|---|
| RS-01 | Lending create is `POST /almaws/v1/partners/{partner_code}/lending-requests` | SKILL.md; api §Create | documented; production-inferred | partners.json path; prod lending path calls it via `create_lending_request_from_citation` |
| RS-02 | Lending `owner` is a plain string **and the schema docs wrongly show it wrapped** (`<owner value=… desc=…/>`) | SKILL.md; api §Owner; quirks §Owner; data-structures; error asset | **contradicted** (second half) — plain string itself is correct | JSON schema `owner: string`; XSD `<xs:element name="owner" type="xs:string">`; Sandbox GET: owner is `str` in 66/66 lending requests; prod sends plain. Corrected in all files. |
| RS-03 | Wrapped `owner` returns HTTP 400 "Cannot deserialize value of type java.lang.String from Object value" | api; quirks; error asset | untested | Needs a POST; historical observation 2025-12-24 only. AlmaAPITK contract test pins plain owner. |
| RS-04 | `partner`, `format`, `citation_type` are wrapped `{value}` | SKILL.md; api; data-structures | sandbox-confirmed (GET, 66 lending requests); documented; production-inferred | Schema: objects with `value`(+`desc`); GET shapes `{value,desc[,link]}`; prod/toolkit send `{value}` |
| RS-05 | `external_id` mandatory for lending create | SKILL.md; api | documented | Schema: "Mandatory when creating a lending request" |
| RS-06 | `citation_type` and `title` required unless `mms_id` given | SKILL.md; api; quirks | documented | Schema descriptions of `citation_type` and `title` |
| RS-07 | Retrieve is `GET /partners/{partner_code}/lending-requests/{request_id}` | api | sandbox-confirmed | HTTP 200 for an existing request (partner MFL) |
| RS-08 | `mms_id` is a wrapped field (`{"value": ...}`) | data-structures; api tables; quirks rule 7 | **contradicted** | Schema & XSD `string`; GET `str` 66/66. Track 2: AlmaAPITK `create_lending_request` sends `{"value": mms_id}` (toolkit bug, live effect untested) |
| RS-09 | `requested_media` is wrapped (lists) / "schema shows wrapped, reality plain" (quirks) | data-structures; api rules; quirks | **contradicted** | Schema & XSD `string`; GET `str` (52 present). Plain is right; schema agrees. Track 2: `create_lending_request` wraps string `requested_media`; `build_user_rs_request` correctly leaves it plain (prod borrowing sends `"7"`) |
| RS-10 | Publication year field is `publication_date` | data-structures; api table; quirks; book example | **contradicted** | No `publication_date` in schema; field is `year`; GET: `year` in 65/66, `publication_date` 0/66 |
| RS-11 | Lending citation types: BOOK, JOURNAL, ARTICLE, CHAPTER, DISSERTATION, from `ResourceSharingCitationTypes` | api §Citation Types; quirks; Pattern 4 | **contradicted** | Schema: lending codes in `PR_CitationType`: BOOK / JOURNAL. SB `PR_CitationType` = {BOOK, JOURNAL}; `ResourceSharingCitationTypes` → 400 "Table does not exist."; observed lending: JOURNAL 57, BOOK 9 |
| RS-12 | `barcode`, `text_email`, `printed`, `reported`, `has_active_notes`, `supplied_format`, `shipping_cost`, `*_time` are undocumented | data-structures; api; quirks | **contradicted** | All present in GET schema `rest_user_resource_sharing_request.json` (printed/reported/has_active_notes marked "Output parameter"). Presence sandbox-confirmed |
| RS-13 | Notes are `rs_notes`, created with items `{"note", "type": {"value": "STAFF_NOTE"}}` | data-structures; api Pattern 5 | **contradicted** | JSON GET key is `rs_note` (66/66; XML wrapper `rs_notes`); item schema `{content, created_date, created_by}`; `rs_notes` absent from POST schema. Prod lending uses `note` |
| RS-14 | `level_of_service` value `"Rush"` | journal example; api examples | **contradicted** | SB `LevelOfService` codes: WHEN_CONVINIENT, NORMAL_LOCAL/FULL, PRIORITY_LOCAL/EXTENDED, RUSH_LOCAL/EXTENDED, EXPRESS_LOCAL |
| RS-15 | Initial lending status `REQUEST_CREATED_LEN`; `IN_PROCESS` a status | api §Status; examples; Pattern 3 | **contradicted** | SB `MandatoryLendingWorkflowSteps` has `REQUEST_CREATED_LEND`, `BEING_PROCESSED`; 6 SB requests in `REQUEST_CREATED_LEND`; no `_LEN`/`IN_PROCESS` |
| RS-16 | `format` codes from `RequestFormats`: PHYSICAL / DIGITAL (borrowing section adds PHYSICAL_NON_RETURNABLE) | api; quirks | sandbox-confirmed (code table); documented | SB table = {PHYSICAL, DIGITAL, PHYSICAL_NON_RETURNABLE} |
| RS-17 | Partners API has `PUT …/lending-requests/{id}` and list `GET …/partners/{code}/lending-requests` (with `q`) | api endpoint table | **contradicted** | partners.json defines only POST and GET-by-id. SB list path → 400 "Partner not found" even for an existing partner. List is `GET /task-lists/rs/lending-requests` (tasklists.json; SB 200 with `library=AM1`) |
| RS-18 | `POST/GET /partners/{code}/borrowing-requests` exist | api endpoint table | **contradicted** | Not in partners.json; SB GET → 400. Borrowing is `/users/{id}/resource-sharing-requests` |
| RS-19 | Use `partner.value` (code), not `partner.desc` | data-structures; quirks | sandbox-confirmed (shape) | GET partner = `{value, desc, link}`; `GET /partners` items carry `partner_details.code` |
| RS-20 | Unknown partner → HTTP 404 "Partner not found: {code}" | api errors; quirks | **contradicted** (GET scope) | Swagger `GET /partners/{code}`: 400 `402118 'Partner not found.'`; SB unknown code → HTTP 400 "Partner not found". Create path untested |
| RS-21 | Borrowing endpoints: POST create, GET, DELETE cancel, POST `op=update_shipping` with `shipping_cost`/`fund_code` both optional | api borrowing; quirks | documented | users.json: all four; `shipping_cost`, `fund_code` required=false; `op` "Currently only update_shipping" |
| RS-22 | Borrowing `citation_type` codes BK/E_BK/CR/E_CR in `ReadingListCitationTypes`; BOOK/JOURNAL are purchase-request codes | api borrowing table | sandbox-confirmed (code tables only) — with doc nuance | SB `ReadingListCitationTypes` = {BK, CR, E_BK, E_CR}; `PhysicalReadingListCitationTypes` = {BK, CR}. Docs name `PhysicalReadingListCitationTypes` BK/CR for borrowing and `PR_CitationType` BOOK/JOURNAL for **lending**. Create acceptance of E_ codes is historical (SB 2026-07). Note added |
| RS-23 | Borrowing `owner` is mandatory; missing → `401607` | api borrowing | unresolved | users.json lists `401607 'Resource sharing library (owner) is missing'`, but schema says owner is "Borrowing request: Optional. Used only when there are more than one resource sharing library defined for the user". Likely tenant-dependent (TAU has several RS libraries) |
| RS-24 | Borrowing errors `401604`, `401768`, `402362`, `401607` with the stated meanings | api error table | documented | users.json POST 400 list (also `402039`, `401608`, `401890`, `401652` not in skill) |
| RS-25 | `create_lending_request(..., mms_id=...)` works without `title` | quirks example; api best practice | **contradicted** (source) | AlmaAPITK `title: str` is a required positional argument (TypeError without it) |
| RS-26 | Lending validation failure is "Error 400: Validation failed: {field} is required and must be non-empty" | api errors; quirks | **contradicted** (source) | AlmaAPITK raises client-side `ValueError("Validation failed for lending request:\n  - … is mandatory …")` before any HTTP call |
| RS-27 | `get_request_summary` returns 7 keys incl. partner/status/format | data-structures; api | **contradicted** (source) | Returns 9 keys (adds `citation_type`, `owner`); `owner` read as a plain string on AlmaAPITK main (de2013d; fixed in #171) — the "always N/A" finding came from an older checkout |
| RS-28 | AlmaAPITK test script `src/tests/test_resource_sharing_lending.py` | api §Testing | **contradicted** (source) | No `src/tests/` in AlmaAPITK; the script is `tests/test_resource_sharing_lending.py` in the RS automation repo; toolkit has `tests/unit/contracts/test_resource_sharing_contract.py` |
| RS-29 | Borrowing shapes: `pickup_location_type` plain (LIBRARY/CIRCULATION_DESK), `pickup_location` wrapped, `agree_to_copyright_terms` mandatory boolean, `partner` not required at create | SKILL.md; api borrowing | documented; production-inferred | Schema: pickup_location_type string with those values; agree "Mandatory for borrowing requests"; partner "Mandatory when creating a lending request" only. Prod borrowing builder sends exactly these |
| RS-30 | `Users` RS method signatures as listed | api borrowing | documented (source) — signatures incomplete, updated | AlmaAPITK de2013d: create adds `*, validate=False`; get adds `request_id_type`; cancel adds `note`, `remove_request`; `build_user_rs_request` exported |
| RS-31 | Test workflow response file `example_responses/lending_request_complete.json` | test-scenarios | **contradicted** | File does not exist; the asset is `lending_request_created.json` |
| RS-32 | Lending article request: DIGITAL + `citation_type` JOURNAL + `year`, `journal_title`, `pmid`/`doi`, `note`, owner plain | api patterns (via corrections) | production-inferred | prod `rs_requests/lending.py` → toolkit `create_lending_request_from_citation` (citation_type `JOURNAL`) |
| RS-33 | Borrowing article recipe CR + DIGITAL, `requested_media` "7" plain, one retry with `override_blocks` on 401604 | api borrowing | production-inferred | prod `rs_requests/borrowing.py`; config example |
| RS-34 | Authoritative pickup check is `GET /users/{id}/requests?allow_pickup_locations=true` | quirks table row 1 | unresolved | No `allow_pickup_locations` parameter in users.json or bibs.json; not probed |
| RS-35 | Borrowing cancel is soft: GET after cancel returns `CANCEL_REQUESTED` "Cancelled by staff" | api borrowing | untested (code exists) | `CANCEL_REQUESTED` = "Cancelled by staff" in SB `OptionalBorrowingWorkflowSteps`; behaviour needs a DELETE; swagger `DELETE` has `remove_request` param that may change it |
| RS-36 | (new) GET lending request does not enforce the path `partner_code` | api §Retrieve (added) | sandbox-confirmed (one request, one other existing partner) | `GET /partners/ANC/lending-requests/<MFL request>` → 200 with `partner.value` MFL |
| RS-37 | `40166422` = request_id invalid for this user_id | api error table | documented (interpretation) | users.json GET: `40166422 'Value of parameter is invalid given other parameter.'` |
| RS-38 | Lending status codes come from lending workflow-step tables | api §Status | sandbox-confirmed; documented | Schema names `MandatoryLendingWorkflowSteps`/`OptionalLendingWorkflowSteps`; both read in SB |
| RS-39 | Borrowing `401929`, `401930`, `401897`, raw-500 on wrong-table citation_type, `402362` matching cancelled requests | api borrowing; quirks | untested | Not in swagger error list; historical SB writes (2026-07); would need POSTs |

**Counts:** contradicted 17 · documented 8 · sandbox-confirmed 7 · production-inferred 2 · unresolved 2 · untested 3 (39 claims; several "documented"/"sandbox-confirmed" rows are also production-inferred).

## Corrections made (2026-11-12)

In-place edits marked "(corrected 2026-11-12, RS-nn)":
- RS-02 owner: removed "schema docs are wrong / XSD shows wrapped" in SKILL.md, data-structures, api, quirks, error asset.
- RS-08/09 `mms_id`, `requested_media` moved to plain-string lists; toolkit wrapping flagged.
- RS-10 `publication_date` → `year` (data-structures, api, quirks, book example).
- RS-11 lending citation types → BOOK/JOURNAL (`PR_CitationType`); Pattern 4 ARTICLE → JOURNAL.
- RS-12 "undocumented" labels removed. RS-13 notes: `rs_note` key, item shape; Pattern 5 uses `note`.
- RS-14 `Rush` → `RUSH_LOCAL`. RS-15 `REQUEST_CREATED_LEN` → `REQUEST_CREATED_LEND`, `IN_PROCESS` → `BEING_PROCESSED`.
- RS-17/18 endpoint tables: removed PUT/list/borrowing under `/partners`; added task-list and user-side endpoints.
- RS-20 partner not found → HTTP 400. RS-25/26/27/28/30/31 toolkit/file-path fixes. RS-36 added. RS-22 doc-nuance note added.

## Open / untested

- **Toolkit bugs (track 2, not fixed — outside this skill):** AlmaAPITK `create_lending_request` wraps `mms_id` and string `requested_media` (schema: plain) (AlmaAPITK #242); `title` required even with `mms_id` (#243). The `get_request_summary` owner bug reported at first was already fixed on main (#171). Live effect of the wrapping is untested; prod lending does not pass either field.
- RS-03, RS-39: write-path error behaviour needs a bounded Sandbox POST fixture to re-confirm.
- RS-23: borrowing `owner` optional vs `401607` — check with a single-RS-library user if ever relevant.
- RS-34: `allow_pickup_locations` parameter is undocumented; confirm or remove.
- RS-35: soft vs hard cancel, and effect of `remove_request`.
- Partner codes being case-sensitive, and the `partner` 4xx on lending *create*, were not tested.
- Historical example IDs (request 10000000000000016, partner ANC/"ANCA-TEST") no longer resolve in Sandbox; examples still use them as illustrations.
- Track 3 (agent behavioural tests) not run.
