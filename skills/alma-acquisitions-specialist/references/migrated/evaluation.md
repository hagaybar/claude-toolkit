# Evaluation of the migrated acquisitions material

Date: **2026-11-12**. Method: `alma-api-knowledge-evaluator` (track 1 knowledge accuracy,
track 2 implementation alignment where cheap; track 3 agent usefulness not run).
This is a self-review by one agent, not an independent validation.

## Scope

Files under `references/migrated/` (acquisitions-api.md, quirks.md, errors-and-validation.md,
data-structures.md, quick-reference.md, test-scenarios.md, assets/). 38 material claims were
selected; the remaining prose (best-practice lists, code-sample comments, "see also" links)
was not individually evaluated and stays historical. The specialist's validated core
(SKILL.md, api-contracts.json, validation-*.md, invoice-workflows.md) was used as evidence,
not reviewed.

Permitted: official docs, read-only Sandbox GETs through the evaluation helper, read-only
source inspection. Not permitted and not done: any POST/PUT/DELETE (invoice process/pay,
receive, scan-in), production keys, project scripts. Every write-transition claim is
therefore at best documented or production-inferred, never Sandbox-confirmed here.

## Sources

- Official Acquisitions OpenAPI: https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/acq.json (fetched 2026-11-12)
- Official schemas: .../openapi/schemas/rest_invoice.json, rest_invoice-post.json,
  rest_invoice_line-post.json, rest_po_line.json, rest_item.json (fetched 2026-11-12)
- Official Bibs OpenAPI (scan-in parameters): .../openapi/bibs.json (fetched 2026-11-12)
- Blog "Creating an invoice using APIs": https://developers.exlibrisgroup.com/blog/creating-an-invoice-using-apis/
- Specialist evidence: `../api-contracts.json` (retrieved 2026-11-08), `../invoice-workflows.md`,
  `../invoice-transition-evidence.json` (one operator-run Sandbox process/pay case, 2026-11-08)
- AlmaAPITK source: `src/almaapitk/domains/acquisition.py`, `domains/bibs.py` at commit
  `de2013d` (release 0.5.1). The specialist's live evidence used installed SDK 0.4.5.
- Production project Alma-Acquisitions-Automation, `origin/prod` at `1515cc2`
  (scheduled entry point: `batch/rialto_pipeline_production.bat` -> `workflows/rialto/`).
- Sandbox GETs 2026-11-12, 08:58-09:09 Asia/Jerusalem, about 30 calls: invoice list
  (limit 50), invoice `q` variants, code tables (PaymentStatus, InvoiceStatus,
  InvoiceApprovalStatus, POLineStatus, PurchaseType, PROCESSTYPE), 9 PO lines, one
  PO-line items list, one item, two invoice GETs by non-ID values. No identifiers retained here.

## Claims

Verdicts: documented, sandbox-confirmed (scope), production-inferred, contradicted,
unresolved, untested. "Source" = AlmaAPITK/project code observation, not API behaviour.

| ID | Claim (migrated) | Where | Verdict | Evidence |
|---|---|---|---|---|
| AQ-01 | API invoice flow: create -> add lines -> `op=process_invoice` -> `op=paid` | acquisitions-api.md, quick-reference.md, test-scenarios.md | documented | Blog: process "after creating the invoice and its lines ... this step is mandatory", empty invoice object as payload. Specialist case: process then paid on one existing EDI invoice (2026-11-08). |
| AQ-02 | Alma API *enforces* process/approve before paid; always call `approve_invoice()` before `mark_invoice_paid()` | acquisitions-api.md "MANDATORY", quirks.md, errors-and-validation.md | unresolved | No official statement that `paid` rejects an unprocessed invoice; paying an unprocessed invoice is untested (POST not permitted). Production Rialto workflow calls `approve_invoice` only when base `invoice_status == 'WAITING_TO_BE_SENT'`, a value the schema says base status never takes (ACTIVE/CLOSED), so production effectively pays without a process call. 20/50 Sandbox invoices had approval NOT_REQUIRED. |
| AQ-03 | Error 402459 means "invoice not approved/processed yet" | errors-and-validation.md, acquisitions-api.md, assets/error_examples | unresolved | Official: 402459 "Error while trying to retrieve invoice X", listed only for GET invoice and GET invoice lines, not for the invoice service POST. GET with a non-ID value returned HTTP 400 "not found", not 402459. Agrees with specialist caution that a retrieval error does not prove a missing approval. |
| AQ-04 | Service ops: paid, process_invoice, mark_in_erp, rejected | acquisitions-api.md | documented | acq.json `op` description; also `create_rt_invoice` query param (not an op). |
| AQ-05 | Service request body is always an empty object `{}` | acquisitions-api.md, test-scenarios.md | unresolved | Documented for process_invoice (blog). For `paid`, schema says voucher_date/number/amount/currency are "relevant in op=paid"; the specialist's passing case sent four voucher fields. AlmaAPITK always sends `{}`. |
| AQ-06 | After processing: approval APPROVED, `workflow_status=Approved` | acquisitions-api.md, quirks.md, errors-and-validation.md, data-structures.md | contradicted | InvoiceStatus code table (Sandbox) has no Approved code: ACTIVE, CLOSED, InApproval, InReview, "Ready to be Paid", "Waiting to be Sent". Specialist case observed Waiting for Payment after processing. |
| AQ-07 | Payment status values include FULLY_PAID and PARTIALLY_PAID | data-structures.md, acquisitions-api.md | contradicted (this Sandbox tenant) | PaymentStatus code table: NOT_PAID, PAID only; 50 invoices: 47 PAID, 3 NOT_PAID. Treat extra values defensively, not as expected states. |
| AQ-08 | `invoice_status` values include WAITING_TO_BE_SENT, APPROVED | acquisitions-api.md, data-structures.md | contradicted | Schema: "Possible codes are: ACTIVE, CLOSED". Sandbox 50/50 ACTIVE or CLOSED. Workflow and approval are separate fields. |
| AQ-09 | Payment status is at `payment.payment_status.value`, not root | all files | sandbox-confirmed (50 invoices, list view) | Root key absent in 50/50; schema agrees. Production Rialto workflow reads nested path. |
| AQ-10 | `total_amount` is a plain number, currency separate | acquisitions-api.md, data-structures.md | sandbox-confirmed (50 invoices) | int/float in 50/50; schema type number. |
| AQ-11 | Full invoice embeds lines as top-level `invoice_line` array | acquisitions-api.md, data-structures.md | contradicted | Schema and Sandbox: container `invoice_lines` with `invoice_line[]` and `total_record_count`; omitted when view=brief. |
| AQ-12 | Invoice line `po_line` is a plain-string POL number (authoritative link) | acquisitions-api.md, quirks.md, data-structures.md | sandbox-confirmed (52 lines) | Schema: "number of the PO line connected to the invoice line". |
| AQ-13 | Invoice search `pol_number~X` and `pol_number=X` work; `pol_number:X` fails with server error | quick-reference.md, quirks.md, acquisitions-api.md | sandbox-confirmed (one POL) | `~` and `=` each returned 1 invoice; `:` returned HTTP 500; a 7-character prefix returned 0 (no prefix matching in that case). `pol_number` is a documented search field. |
| AQ-14 | Query format `invoice_status~... AND vendor~...` filters invoices | acquisitions-api.md | contradicted | Not documented search fields (documented: invoice_number, vendor_code, pol_number, po_number, ...; status via `base_status` / `invoice_workflow_status` params). Sandbox: `invoice_status~ACTIVE` and `vendor~X` each returned the full unfiltered population. |
| AQ-15 | GET invoices: limit default 10, max 100; `view=brief` | acquisitions-api.md | documented | acq.json. |
| AQ-16 | Fund distribution on invoice-line POST: percent or amount, not both; neither is an error | quirks.md, errors-and-validation.md, acquisitions-api.md | documented | Invoice-line schema: "percentage or [amount] should be supplied, but not both"; error 60257 "Fund percent or amount is required". Sandbox GET lines return *both* keys (52/52): never replay GET line JSON into POST. |
| AQ-17 | Error text "Invoice line fund percentage or amount must be declared, not both and not neither" with errorCode 400 | errors-and-validation.md, assets/error_examples/error_fund_distribution.json | unresolved | Not in the official error list (60257, 60252). The asset's errorCode "400" and trackingId look synthetic. |
| AQ-18 | Percent and amount cannot be mixed across funds; percents must total 100 | quirks.md, errors-and-validation.md | untested | Not documented; no write test. |
| AQ-19 | Invoice-line create requires po_line, quantity, price, total_price | errors-and-validation.md | contradicted | POST schema has no `total_price` (output only); `po_line` "Optional"; price and quantity default to the PO line. `fund_distribution` mandatory for processing. AlmaAPITK sends no total_price. |
| AQ-20 | Invoice create requires number, invoice_date, vendor, total_amount | errors-and-validation.md | documented | Schema "Mandatory"; errors 60233/60234/60235. |
| AQ-21 | invoice_date must be `YYYY-MM-DDZ`; otherwise error 40166411 | errors-and-validation.md | unresolved | Format: 50/50 Sandbox dates use it and blog example uses it. Error mapping: 40166411 is documented only for the receive endpoints; invoice POST lists other codes. |
| AQ-22 | Receive: `POST po-lines/{pol}/items/{item}?op=receive`, optional receive_date (YYYY-MM-DDZ), department, department_library; empty `<item/>` body | acquisitions-api.md, assets/example_requests/receive_item.xml | documented | acq.json; AlmaAPITK sends XML `<item/>` (aligned). Without department Alma picks a random acquisitions department of the owning library. |
| AQ-23 | Receive errors: 40166411 invalid param, 401875 department, 401871 PO line not found, 401877 failed to receive | errors-and-validation.md, acquisitions-api.md | documented | Official messages: "Param value is invalid", "Failed to find the department", "Failed to find the PO Line", "Failed to receive PO Line (with error message)". The listed causes (closed POL -> 401871, already received -> 401877) are untested. |
| AQ-24 | Receiving changes `process_type` from "acquisition" to "in_transit" | acquisitions-api.md, quirks.md, data-structures.md | contradicted (values) | process_type is an object with PROCESSTYPE codes: ACQ, TRANSIT, WORK_ORDER_DEPARTMENT, ... (Sandbox code table; item GET shows `{"value": ...}`). Whether a receive sends the item to transit is untested here; production adds a scan-in to avoid it (production-inferred). |
| AQ-25 | Keep in department = receive, then scan-in with department, library, work_order_type, status, done=false | acquisitions-api.md, quick-reference.md, quirks.md | production-inferred | Scheduled production Rialto pipeline calls `receive_and_keep_in_department`; AlmaAPITK sends `op=scan&library&department&work_order_type&status&done=false`. Bibs scan-in docs list these params. |
| AQ-26 | POL items live at `location[].copy[]`, item ID is `pid`, `receive_date` marks received | all files | sandbox-confirmed (1 physical POL; 8 e-book POLs had empty `location`) | Schema agrees. |
| AQ-27 | Holding ID is `location[0].holding_id` | acquisitions-api.md, quirks.md, data-structures.md | contradicted | Sandbox location keys: copy, holding, library, quantity, shelving_location. Holding id is at `location[].holding[].id` (schema also has `copy.holding_id`). Production code falls back to `holding[0].id`. |
| AQ-28 | POL copy objects carry `process_type` and `receiving_operator` | quirks.md, data-structures.md, assets/example_responses/pol_with_items.json | contradicted | Not in po_line copy schema or Sandbox copy keys; they are `item_data` fields of the Items API. |
| AQ-29 | `GET po-lines/{id}/items` returns item_id, status, receiving info, barcode, location | acquisitions-api.md | contradicted | Official: "only barcodes and a link for the Get-Item API". Sandbox: `item_data.pid`, `item_data.barcode`, `link`. AlmaAPITK `get_pol_items` docstring repeats the error. |
| AQ-30 | POL `fund_distribution` uses `percent: {"value": "100"}` | data-structures.md | contradicted | Sandbox 9/9 POLs: keys `fund_code`, `amount: {sum, currency}`; no percent. |
| AQ-31 | POL status ACTIVE/CLOSED/CANCELLED; POL type ONE_TIME/STANDING_ORDER/APPROVAL/SUBSCRIPTION | data-structures.md, assets | contradicted | POLineStatus codes have no ACTIVE (e.g. SENT, WAITING_FOR_INVOICE, CLOSED, CANCELLED). `type` uses PurchaseType codes; Sandbox POLs were PRINTED_BOOK_OT and E_BOOK_OT. |
| AQ-32 | POL `invoice_reference` is often empty; Rialto example uses it as the invoice ID | acquisitions-api.md, quirks.md, data-structures.md | contradicted (ID use) | Schema: "Invoice reference number". In one Sandbox POL it held the vendor invoice *number*; GET `/acq/invoices/{that value}` returned 400 "not found". Linkage through invoice lines (AQ-12) is the reliable path. |
| AQ-33 | POL auto-closes only when all items received and all linked invoice lines paid | acquisitions-api.md | contradicted (one case) | Specialist evidence: an E_BOOK_OT POL changed to CLOSED after processing, before payment. Closure rules vary by POL type/configuration. |
| AQ-34 | AlmaAPITK names/signatures: create_invoice_simple, create_invoice_line_simple, approve_invoice (= op=process_invoice), mark_invoice_paid(invoice_id, force=False), receive_item(pol_id, item_id, receive_date, department, department_library), receive_and_keep_in_department(...), extract_items_from_pol_data, get_invoice_lines, check_pol_invoiced (uses `pol_number~`) | all files | production-inferred (source-confirmed at de2013d) | Production uses approve_invoice, mark_invoice_paid, receive_and_keep_in_department, extract_items_from_pol_data. |
| AQ-35 | `mark_invoice_paid` protection blocks unapproved invoices | acquisitions-api.md | contradicted (source) | `check_invoice_payment_status.can_pay` accepts approval PENDING as well as APPROVED. |
| AQ-36 | `check_pol_invoiced` returns `amount` float and `invoice_count` = number of invoices | acquisitions-api.md | contradicted (source) | `amount` is a display string; count increments per matching line; on search failure it returns `is_invoiced: False` with `search_error` (fails open). |
| AQ-37 | `get_invoice_summary` keys; `create_invoice_with_lines` = create + lines + approve + pay | data-structures.md, acquisitions-api.md | contradicted (source) | Summary keys: invoice_id, invoice_number, vendor_code, vendor_name, invoice_date, total_amount, currency, status, payment_status. `auto_process=True`, `auto_pay=False` by default. |
| AQ-38 | Scan-in step uses `circ_desk=ACQ` with work_order_type and done=false | test-scenarios.md | contradicted | Bibs docs: `done` is "only relevant when department parameter is sent"; AlmaAPITK sends `department`, not `circ_desk`. |

Counts: documented 7, sandbox-confirmed 5, production-inferred 2, contradicted 18,
unresolved 5, untested 1.

## Corrections made

Inline notes "(corrected 2026-11-12, see evaluation AQ-nn)" were added in place for
AQ-06, 07, 08, 11, 14, 19, 24, 27, 28, 29, 30, 31, 32, 33, 35, 36, 37 and 38. Uncontested
text, the example assets' JSON bodies and the unresolved claims were left unchanged.
AQ-02 and AQ-03 (the "must approve" rule and 402459) were *not* rewritten: they are
unresolved, not contradicted. Read them with the specialist's caution in
`../invoice-workflows.md`.

## Consumer findings (not skill corrections)

- Production `workflows/rialto/workflow.py` (`origin/prod`): `_find_invoice_for_pol`
  searches with `invoice_status~...` (ignored by Alma: AQ-14), so it scans an arbitrary
  first 100 invoices; it first takes `pol_data['invoice_reference']` as an invoice ID
  (AQ-32); and its approve branch can never fire (AQ-02). The project owner should review this.
  These are observations from reading the code; no production behaviour was tested.
- AlmaAPITK `check_pol_invoiced` fails open on search errors (AQ-36), so a duplicate
  check can report "not invoiced" when it could not check.

## Open / untested

- Paying an unprocessed or PENDING invoice (AQ-02), and the real trigger of 402459 (AQ-03):
  need a bounded Sandbox write fixture authorised by the user.
- `paid` with empty body vs voucher fields (AQ-05).
- Fund-distribution mixed/total rules and the exact error text (AQ-17, AQ-18).
- Receive effects on process type / transit, with and without `department` (AQ-24).
- Error causes beyond the official messages (AQ-23), invoice_date error mapping (AQ-21).
- Other tenants: code-table findings (AQ-06, 07, 31) are from this Sandbox institution.
