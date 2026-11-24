# Large sets and bulk reads

**Evidence: Alma Sandbox, 18 Nov 2026**, from the invoice-closer work in the
Alma-Acquisitions-Automation repo (a vendor job over a 3,356-line `PO_LINE` set). Timings are
from that run and that vendor; treat them as orders of magnitude, not guarantees.

## Size the job before writing code

Read the set (`GET /conf/sets/{id}`: type, content, `number_of_members`) and the first members
page (`total_record_count`). Then estimate API calls x seconds per call. Record-by-record, an
invoice job costs about 10 calls per order line: 3,356 lines meant ~30,000 calls and hours of
running. That job was started without the estimate and wasted time. Show the user the estimate
before a long run.

## Read in bulk; there is no batch GET by IDs

Alma has no batch GET for a list of POL or invoice numbers: a list means one call each. Use the
list endpoints, 100 per page, and match in memory.

- `GET /almaws/v1/acq/invoices?q=vendor_code~<CODE>&view=full&limit=100&offset=N` returns
  invoices **with their lines** (`invoice_lines.invoice_line[]`, each with `po_line`), with the
  same keys as a single invoice GET. 3,633 invoices = 37 calls, ~2 s per page. Compare
  `number_of_lines.value` (an object `{value, link}`) with the lines returned; fetch the lines
  separately if they fall short.
- `GET /almaws/v1/acq/po-lines?q=vendor_code~<CODE>&status=ALL_WITH_CLOSED&limit=100` returns
  brief order lines (number, status, type, vendor, owner, `resource_metadata.mms_id`,
  `created_date`), without `invoice_reference`. 4,229 lines = 43 calls, ~10-11 s per page: the
  slow step. (`status=ALL` excludes closed lines; see invoice-workflows.md.)
- `vendor_code~` is a contains-match. Filter to the exact vendor code afterwards.
- Map order line -> invoice through the invoice lines (index them by `po_line`), not through the
  POL's `invoice_reference`: that holds the vendor's invoice number and is missing from brief
  records anyway.
- The whole download was ~80 calls and ~5-6 minutes, against hours record-by-record.

## Keep downloads on disk

Save every bulk download to a file before processing it, and reuse it for a while (up to an
hour worked here). In-memory downloads were lost twice when runs were stopped and restarted.
For live writes, the saved download is fine for mapping the input to records; re-read each
open record fresh immediately before writing to it.

## Check a set's member count before paging

Observed: a LOGICAL `PO_LINE` set with `number_of_members=3356` returned
`total_record_count=5289264` from `GET /conf/sets/{id}/members`, with members such as
"PO line <id> was deleted". An itemized copy of the same set listed the 3,356 POL numbers
correctly. Logical sets do work in other jobs (Analytics-driven ones), so this is **under
investigation** (AlmaAPITK issue hagaybar/AlmaAPITK#250), not a rule against logical sets.

- Guard: before paging, compare the members page's `total_record_count` with the set's
  `number_of_members`. On a mismatch, refuse and report. Workaround: itemize the set.
- AlmaAPITK 0.7.0 `Admin.get_set_members` pages by `number_of_members`, so on such a set it
  would silently return the first 3,356 bogus entries.

## Spend per-record calls only where they decide something

Per-record checks (e.g. e-book portfolio availability, print item receipt) cost one call each.
Ask whether each one changes the decision. In a pre-analysis, skip the merely informational ones.

## Running it

- First live run: limit it to a few records that actually need action. A limit counted over all
  records can be used up by already-closed ones and test nothing.
- When a requirement changes mid-run, do not stop and discard the work if the change can apply
  to the next run.
