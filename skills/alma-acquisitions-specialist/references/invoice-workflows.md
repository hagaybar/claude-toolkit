# Invoice workflows and API interpretation

## Existing versus new invoices

For an existing invoice, inspect its header, lines, linked orders and current states.
Do not create another invoice to work around processing/payment failures. For new
invoice creation, reuse project duplicate/linkage checks, validate header/line payloads
and test the relevant transitions. The current skill has no live creation coverage.

## Distinct state dimensions

| Dimension | Evidence to inspect | Interpretation boundary |
|---|---|---|
| Invoice base state | invoice_status | ACTIVE is not a payment-eligibility decision |
| Invoice workflow | invoice_workflow_status, including value and description | Preserve both if they differ; do not silently replace one with a familiar label |
| Approval | invoice_approval_status | Toolkit readiness logic is not proof of institutional approval policy |
| Payment | payment.payment_status | This nested path was observed in a bounded Sandbox read; revalidate other response shapes/versions |
| ERP/export | Relevant invoice fields, configured integration and service effects | Recording an ERP state is distinct from processing and payment |
| PO-line state | Linked PO-line status and relevant receiving/activation/invoicing data | Closed invoice does not by itself prove closed PO-line |

## Service operations

The current official catalog documents invoice-service `op` values mark_in_erp,
paid, process_invoice and rejected, plus create_rt_invoice. These are documented
contracts with action-specific coverage. The paid case below has bounded operator-run
evidence; other actions remain unvalidated. Read the exact official parameter/body schema
and current state requirements before a previously unused operation.

In the reviewed toolkit source, approve_invoice delegates to process_invoice.
That implementation fact does not prove that processing always ends in approval.
The reviewed payment guard permits PENDING in its can_pay calculation; this is
wrapper logic requiring separate business/API validation, not a domain synonym.

The toolkit posts an empty object for service operations. Whether that is sufficient
for a particular action/configuration must be verified against the official body
contract and a scoped Sandbox test. Do not turn earlier successful examples into
an assertion that all operations need the same payload.

The paid operation must be investigated as a payment-recording action, not used as
a generic administrative close. Confirm the intended financial/ERP semantics and
read back the result. One operator-run paid transition is now supported within the
specific scope recorded in [transition evidence](invoice-transition-evidence.json).

## Payment flow: documentation checked 8 November 2026

**Evidence: official documentation, not a live mutation test.** Invoice processing,
approval, ERP handoff, payment confirmation and closure are separate stages.
Institutional configuration can skip ERP or payment tracking. With
handle_invoice_payment=true, the ERP handoff can lead to Waiting for Payment;
false can close the invoice without waiting for payment confirmation. Do not change
that configuration merely to make a test work.

Preserve the API/UI naming distinction documented in the invoice schema:

| API workflow code | User-facing stage |
|---|---|
| Waiting to be Sent | Ready to be paid; ERP handoff stage |
| Ready to be Paid | Waiting for Payment; payment stage |

The invoice service POST with op=paid records a payment confirmation in Alma. It is
not an instruction to transfer money. The official ERP integration example supplies
a minimal invoice object containing payment.voucher_date, voucher_amount,
voucher_currency and voucher_number. The invoice schema also documents optional
explicit_ratios and notes; create_rt_invoice controls a reporting-tax invoice.
Do not replay all GET fields or infer final paid amount/currency from invoice totals
when exchange rates may apply. Inspect the relevant financial requirements.

The API schema describes a default current payment date; the UI payment guide
requires a payment identifier for Accounting Department. Do not assume UI field
requirements completely specify the service API's conditional validation. The
project's guided PAY desk requires all four voucher fields as a conservative local
prototype policy, not a universal Alma requirement. It uses ACTIVE, APPROVED or
NOT_REQUIRED, the waiting-for-payment workflow code and NOT_PAID as local entry
conditions. These checks are not proof that Alma will accept the action.

The schema warns that processing is asynchronous. Read back payment, base and
workflow state after an action; a POST body or HTTP 2xx alone is insufficient.
Inspect linked PO lines separately: closure depends on invoicing/payment and
receiving or activation. An older official ERP blog comment also reports a PO-line
closure defect; neither that historical report nor current workflow prose proves
this institution's current behavior. Do not automatically close PO lines to hide a
discrepancy.

Rialto's optional "Mark Invoices as Paid in Alma" feature updates payment status/date
without itself changing invoice status. This makes paid-but-open a meaningful
investigation case; it does not establish that this institution enabled the option
or that repeating op=paid is an appropriate remedy.

Official references checked on that date:

- [Invoice service](https://developers.exlibrisgroup.com/alma/apis/docs/acq/UE9TVCAvYWxtYXdzL3YxL2FjcS9pbnZvaWNlcy97aW52b2ljZV9pZH0=/)
- [Invoice schema and payment fields](https://developers.exlibrisgroup.com/alma/apis/docs/xsd/rest_invoice.xsd/?tags=POST)
- [ERP invoice API integration and minimal payment example](https://developers.exlibrisgroup.com/blog/alma-erp-invoices-integration-using-apis/)
- [Invoicing workflow and configuration](https://knowledge.exlibrisgroup.com/Alma/Product_Documentation/010Alma_Online_Help_%28English%29/020Acquisitions/020Invoicing/010Invoicing_Workflow)
- [Working with invoices waiting for payment](https://knowledge.exlibrisgroup.com/Alma/Product_Documentation/010Alma_Online_Help_%28English%29/020Acquisitions/020Invoicing/060Working_with_Invoices_Waiting_for_Payment)
- [Rialto invoicing option](https://knowledge.exlibrisgroup.com/Rialto/Product_Documentation/040Rialto_Administrator_Guide/API_Invoicing_Workflow_and_Options)

**Last live PAY test: 8 November 2026, 13:53 Israel time.** An operator-run Sandbox
simulation on one approved Waiting for Payment electronic-book invoice returned
HTTP 200. Subsequent GET confirmed CLOSED/PAID, supplied voucher fields, and unchanged
owner/vendor; all eight checks passed. The operator's UI screenshots corroborated
Closed and four retained alerts. This does not validate every record or fiscal rule.

Its preceding process_invoice request lost its response after approximately 15
seconds. Later reconciliation at 13:43 observed APPROVED and Waiting for Payment,
with payment unchanged. This supports the observed progression, not a captured
successful processing response or a general approval guarantee. The linked one-time
electronic-book PO line changed to CLOSED before PAY, while the invoice remained
NOT_PAID. Keep that observation separate from invoice closure and claims about
receiving/activation. See the [sanitized evidence](invoice-transition-evidence.json).

The actual JSON invoice returned a flat `alert` list (singular); the schema describes
an alerts container. Inspect the actual shape, and support both without changing raw
evidence. Four alerts persisted after CLOSED/PAID; they did not prevent these
transitions in this case. They are not proven harmless in other workflows.
The closed invoice returned invoice_workflow_status={} while its base status was
CLOSED: do not require a populated workflow code to recognize closure.

## Batch closure evidence: 12–13 November 2026

**Evidence: Sandbox live writes, almaapitk 0.4.5, same configuration as 8 Nov (operator
confirmed ERP skipped, payment handling on).** Agent-run with the user's approval through
the Acquisitions repo's `scripts/close_invoices.py` (PR #15 there); sanitized summary in
[closure batch evidence](invoice-closure-batch-evidence.json).

- 12 Rialto E_BOOK_OT one-line invoices (one by hand, ten from a title set, plus the 8 Nov
  case) went InReview/PENDING/NOT_PAID → `process_invoice` → Ready to be Paid/APPROVED →
  `paid` → CLOSED/PAID. Every linked order line was CLOSED right after processing.
- The process reply is the updated invoice. Do not assume the reply means progress: compare
  its state with the state before.
- A print invoice (PRINTED_BOOK_OT, item without `arrival_date`, invoice line 35.29 vs order
  39.95) returned HTTP 200 and stayed In Review. Alma raises no error; the alerts in the
  reply are the only hint. Which condition held it is unresolved; the 18 Nov evidence below
  points to an invoice line without a fund (not re-checked for this invoice).
- Retained alerts (DIFFERENT_VENDOR_ACCOUNT, EDI_INVOICE_OF_EXTERNAL_SYSTEM,
  NOT_READY_LINES, and once DIFF_PRICE_THAN_POLINE) did not stop e-book processing.
- The order (PO) itself has no API read; whether it closes needs the UI.
- PO-line search: `status=ALL` excludes CLOSED lines; `status=ALL_WITH_CLOSED` includes them.
  Search results are brief records without `invoice_reference`; GET each line in full.
- POL `invoice_reference` held the vendor invoice number on every Rialto line read (12–13 Nov);
  `GET /acq/invoices?q=invoice_number~<n>` then an exact-number and vendor filter resolved
  each to one invoice.

**Select by order line, not by title.** A title can hold several order lines, each with its
own invoice, so starting from a title reaches invoices nobody named. Drive invoice jobs from a
`PO_LINE` set (members are POL numbers) or an explicit file of order lines or invoice numbers.
Alma has no invoice set type. Before acting, check that every line of each invoice belongs to the
selected order lines; otherwise hold the invoice. (The 13 Nov title-set run was safe only
because each title had one order line.)

**Physical one-time orders, pay only (Sandbox, 15 Nov 2026, almaapitk 0.7.0, 5 Rialto
PRINTED_BOOK_OT one-line invoices, items with an arrival date, in place; order lines SENT):**
`process_invoice` → Ready to be Paid/APPROVED, then `paid` → CLOSED/PAID for all five. Every
order line **stayed SENT**: paying does not close a physical order line, and an item's
`arrival_date` is not order-line receiving. Closing the line needs receiving (done in the UI here).
Repeated the same day with **items never received** (5 AC1 lines; 3 items in ACQ, 2 in place
without receiving; no arrival or copy receive date): same result, CLOSED/PAID, order lines SENT,
items unchanged. Unreceived items did not block processing or payment, despite NOT_READY_LINES.
What does block print processing is an invoice line without a fund (18 Nov, below).

**The API cannot close an order line directly (Sandbox, 15 Nov 2026).** There is no close
operation on `/acq/po-lines`. `PUT /acq/po-lines/{id}?update_inventory=false` with the full
record and `status=CLOSED` returned **HTTP 200 and changed nothing**: the line stayed SENT. The
status is silently ignored, so HTTP 200 is no proof; read back. The PUT also trimmed a trailing
newline from a note: a full-record PUT can rewrite fields you did not mean to change. `DELETE`
cancels a line, which is not closing it. That leaves receiving (deferred: see SKILL.md) or the UI.

**Receiving a shelved item closes the line, and pulls the item off the shelf (Sandbox, 15 Nov
2026, user-approved single run).** POL-level: PRINTED_BOOK_OT line, SENT, invoice already
CLOSED/PAID, one item in place at AC1/CC, never received, no loan or request.
`POST /acq/po-lines/{pol}/items/{item}?op=receive&receive_date=…` with no department: HTTP 200
after **33.6 s**. The **order line went CLOSED at once**, and its copy got the receive date. The
item's library and location were unchanged (AC1/CC). But it went from *Item in place* to
*Item not in place*, with process type TRANSIT, `requested` set to true, and a work order
(AcqWorkOrder, *Acquisition technical services*) at the AC1 Acquisitions Department. Its
`arrival_date` was set and its receiving operator was `API`. For a book already on the shelf,
Alma now shows it unavailable and in transit. That is the conflict the receiving warning is
about; someone must finish the work order or scan the item in to return it to the shelf.
Earlier lines whose items and copies already had imported arrival or receive dates stayed SENT
after payment: only the receive action counted.

**An invoice line without a fund holds the invoice; paying it unprocessed is irreversible
(Sandbox, 18 Nov 2026, almaapitk 0.7.0, Rialto/AC1).** 6 of 6 PRINTED_BOOK_OT one-line invoices
whose line had an empty `fund_distribution` got HTTP 200 in under 1 s from
`POST /acq/invoices/{id}?op=process_invoice` (body `{}`), no error, and stayed InReview/PENDING;
before/after snapshots of invoice, lines and order line were identical. 2 E_BOOK_OT invoices
whose line had a fund (100% to one fund) went Ready to be Paid/APPROVED (1.7 s and 19 s), `paid`
closed them and their order lines closed; one carried DIFF_PRICE_THAN_POLINE (21.99 vs 22.99),
one did not. So the price alert is not the blocker. **Same-day contrast on print (~21:00):** a
PRINTED_BOOK_OT one-line invoice, InReview/PENDING with the same four alerts
(DIFFERENT_VENDOR_ACCOUNT, DIFF_PRICE_THAN_POLINE, EDI_INVOICE_OF_EXTERNAL_SYSTEM,
NOT_READY_LINES; line 31.99 vs order 32.00), item with an imported receive date only, and its
line **with** a fund (100%): `process_invoice` `{}` → HTTP 200 in 0.9 s, the reply already showed
Ready to be Paid/APPROVED (confirmed by a 30 s read-back). Lines re-read, every line funded;
`paid` with the four voucher fields → HTTP 200 in 0.5 s → CLOSED/PAID/APPROVED. Diff: approval
PENDING→APPROVED with `approval_date` (run day) and `approved_by` (the API user) set, status
ACTIVE→CLOSED, workflow InReview→null, payment NOT_PAID→PAID, voucher fields set, the line's fund
distribution unchanged; the order line stayed SENT (expected for physical lines, see above). Fund
transaction for this invoice not checked. So the missing fund is the blocker, confirmed by a
same-type contrast (6 fundless print held vs funded print and 2 funded e-books advanced), still
not an Ex Libris-documented rule; a funded print invoice processes despite NOT_READY_LINES and a
price difference. In that test set 73 print and 1 e-book closable invoices had a fundless line,
against 857 print and 575 e-book with funds; the 15 Nov print invoices that processed are
consistent with having funds (not re-checked).
`op=paid` on an **unprocessed** InReview invoice with a fundless line returned HTTP 200: the
invoice went CLOSED/PAID with the voucher fields set, but `invoice_approval_status` stayed PENDING,
the line stayed INREVIEW (e-book lines also do after a normal close, so that alone is normal),
and **no fund transaction exists for that line**. A later
`PUT /acq/invoices/{id}/lines/{line_id}` adding `fund_distribution` was refused: HTTP 400, Alma
error 403877 "The fields: Fund distribution can't be edited in an invoice line of a closed
invoice." Paying without processing is therefore effectively irreversible through the API and
leaves the expense unrecorded. **Rule:** never process or pay an invoice with a line lacking
`fund_distribution`; check at selection and again right before `paid`, and exclude fundless
lines from the operator's selection (Analytics report or set).

**A fund share that is not exactly 100% also holds the invoice (production, 22 Nov 2026,
Rialto/AC1, 1,271 invoices).** 12 invoices stayed ACTIVE/InReview/NOT_PAID after `process_invoice`
(no change within a 30 s read-back) while 1,242 others processed and paid. Every one of the 12, and
none checked otherwise, had invoice lines with a single fund whose `fund_distribution[].percent` was
not 100 (99.95 to 105.27; 77 lines in all). Alma pays a whole invoice, so one such line blocks all
its lines. Inference from this run, not an Ex Libris-documented rule. **Rule:** at selection, hold
an invoice whose any line's fund percents do not sum to 100, and report the lines to staff.
Related, same run: 6 paid e-book invoices left their order line SENT (not CLOSED). Those lines were
already SENT before the run (not WAITING_FOR_INVOICE); likely not activated. Not verified.
Fund transactions: `GET /acq/funds?q=fund_code~<CODE>&mode=ALL&status=ALL` (one fund record per
fiscal period), then `GET /acq/funds/{fund_id}/transactions?limit=100&offset=N`. Each transaction
has type (EXPENDITURE, ALLOCATION, ...), amount, transaction_time, `po_line.value` (internal POL
id) and `invoice_line.value` (internal invoice-line id). No filter by invoice was found, so
matching meant paging all of them (108 calls for one fund across periods). The processed e-book's
EXPENDITURE was dated at the invoice date, i.e. it existed before processing.

**Fiscal period of the expense: Alma chooses it; the API call does not (Sandbox, 22 Nov 2026,
Rialto/AC1).** The invoice line exposes only `fund_distribution[].fund_code` (e.g. AAC_FUND,
100%, amount), with no fund ID or fiscal period, while the fund code exists once per fiscal period
(AAC_FUND: six fund records, FY-2022 to 01/10/2026–30/09/2027). `process_invoice` (body `{}`) and
`paid` (voucher number, date, amount, currency) carry no fund or period either. Six print invoices
dated 25 Oct 2024, paid on 22 Nov 2026, each got one EXPENDITURE transaction for the line amount in
the **01/10/2024–30/09/2025** AAC_FUND, not the current period (matched by `invoice_line.value`).
So the expense lands in the period that belongs to the invoice: either the fund attached when
the invoice line was created, or the invoice date's period. These cases cannot tell the two apart
(the invoices were created in that same period). With the earlier observation that an e-book's
EXPENDITURE already existed before processing, the creation-time attachment is the likelier
reading, but it is unconfirmed; Analytics Funds Expenditure (Fiscal Period folder) can show the
period of unpaid lines. To charge another period, the invoice line's fund would have to be changed
before payment; editing it after closing is refused (403877, above).
**Project decision (owner, 22 Nov 2026):** the Rialto invoice closer leaves the attached fund as it
is and lets Alma charge its period, in Sandbox and production.

Still untested: physical order-line closure through receiving, multi-line and charge-line invoices, manual
approval, ERP stage, paid-but-open continuation, multi-currency payments, production.

## Implementation discrepancies and troubleshooting

The baseline bulk processor read payment_status at the root. The review branch
corrects its before/after reads to the observed nested field; three regressions
failed before correction and all 16 configured offline tests passed after it.
The underlying duplicate guard and already-paid skip behavior were retained.
This does not resolve the business treatment of an invoice that is paid but open,
or prove that the processor's success flag enforces every desired final state.

Legacy query examples use vendor/invoice_status in q. Use the current official
invoice search fields and separate owner/base_status/invoice_workflow_status filters
instead of treating those examples as authoritative. Validate the returned predicate.

For errors, collect the HTTP operation, relevant state, sanitized error code and
official error contract. A general retrieval/validation error does not uniquely
prove a missing approval step. Read back before retrying an uncertain mutation;
do not force payment, recreate an invoice or automatically process it as a diagnosis.

## Validation status of invoice claims

| Claim | Validity indication | Last live test |
|---|---|---|
| Owner/vendor/ACTIVE search predicate | Confirmed on the three returned records only | 8 Nov 2026 09:46 Israel time |
| Nested payment status field | Confirmed in one invoice detail; root field absent | 8 Nov 2026 09:46 Israel time |
| Invoice-line collection and linked PO read | Confirmed for one invoice and one linked PO line | 8 Nov 2026 09:46 Israel time |
| approve_invoice maps to process_invoice | Source-reviewed implementation fact. In 12 e-book cases process_invoice itself produced APPROVED (no separate approval call); manual-approval configurations untested | 13 Nov 2026 |
| PENDING makes an invoice eligible for payment | Unresolved business/API claim; wrapper logic is insufficient | Not tested |
| paid produces the desired closure | 12 approved, NOT_PAID e-book invoices (8, 12, 13 Nov): HTTP 200 in under 1 s, GET CLOSED/PAID with the four supplied voucher fields | 13 Nov 2026 |
| PO-line closure during processing | Confirmed for 12 one-line invoices on active E_BOOK_OT lines (WAITING_FOR_INVOICE): CLOSED on the first GET after a captured process_invoice reply, before PAY | 13 Nov 2026 |
| process_invoice reply carries the new state | 11 captured replies: HTTP 200 already showing Ready to be Paid/APPROVED (2.3–39.7 s) | 13 Nov 2026 |
| process_invoice that cannot advance returns an error | Contradicted: 1 print invoice (12 Nov) and 6 print invoices with a fundless line (18 Nov) got HTTP 200 in under 1 s and stayed InReview/PENDING, snapshots unchanged, no error. Read back and treat unchanged as held | 18 Nov 2026 |
| DIFF_PRICE_THAN_POLINE blocks processing | Contradicted: e-book invoices with this alert advanced and closed (13 Nov; 18 Nov with a funded line), and one funded print invoice (18 Nov) | 18 Nov 2026 |
| Unreceived print line keeps the invoice In Review | Contradicted: 5 print invoices with never-received items processed and paid (15 Nov). The held cases are better explained by a line without a fund | 18 Nov 2026 |
| Invoice line without a fund keeps the invoice In Review | Supported: 6 of 6 fundless print invoices stayed In Review; a funded print invoice (same day, same alerts incl. NOT_READY_LINES and a price difference) and 2 funded e-book invoices advanced. Not an Ex Libris-documented rule | 18 Nov 2026 |
| paid on an unprocessed invoice can be undone | Contradicted: one fundless InReview invoice went CLOSED/PAID (approval still PENDING, no fund transaction); adding a fund afterwards refused with 403877. Never pay unprocessed | 18 Nov 2026 |
| ERP and other PO-line closure effects | No active ERP in the tested environment; other configurations/record types unvalidated | Not tested |

See [validation-status.md](validation-status.md) and the dated evidence for exact
operation scope. A test date does not establish every parameter combination.
