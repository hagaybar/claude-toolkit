# API Quirks and Gotchas

This reference documents unexpected behaviors, undocumented features, and schema discrepancies discovered through real-world testing.

## Critical Quirks Summary

| Quirk | Impact | Solution |
|-------|--------|----------|
| Owner field format | ⚠️ CRITICAL | Use plain string, not wrapped (schema docs wrong!) |
| Payment status location | HIGH | Nested in `invoice.payment.payment_status.value` |
| Invoice approval requirement | HIGH | Invoice must be approved before paying (402459 diagnosis unresolved). In the validated e-book flow `op=process_invoice` itself produced APPROVED; no separate approve call (Sandbox, 12–13 Nov 2026) |
| POL items location | MEDIUM | In `location[0].copy[]` array, not root |
| Invoice-POL linkage | MEDIUM | Invoice lines' `po_line` is authoritative. POL `invoice_reference` holds the vendor invoice *number* (never the ID) and was populated on every Rialto line read 12–13 Nov 2026; search by number, then filter exact number and vendor |
| PO-line search hides closed lines | HIGH | `GET /acq/po-lines?status=ALL` excludes CLOSED lines; use `status=ALL_WITH_CLOSED`. Results are brief (no `invoice_reference`): GET each line in full (Sandbox, 13 Nov 2026) |
| Portfolio availability code | MEDIUM | `availability` comes as `{"value": "11", "desc": "Available"}`, not `ACTIVE`; compare the code or desc (Sandbox, 12 Nov 2026) |
| `process_invoice` never errors on review | HIGH | When Alma's review rules keep an invoice In Review, `op=process_invoice` still returns HTTP 200 with the unchanged invoice. Compare the reply/read-back state with the state before (Sandbox, 12 Nov 2026) |
| Undocumented fields | LOW | Many useful fields not in schema (barcode, timestamps) |
| Fund distribution format | MEDIUM | EITHER amount OR percent, never both |
| Rep UI notes API-invisible | HIGH | Notes added in Alma UI never appear in any GET/expand variant; can't edit or remove via API. Only "removal" is destructive (delete files → delete rep → recreate). |
| Rep file DELETE removes S3 | HIGH | `DELETE /representations/{id}/files/{id}` deletes the underlying S3 object (schema doc claims otherwise — wrong). Re-upload required before re-link. |
| Rep DELETE blocked by files | MEDIUM | Must DELETE every linked file before DELETEing the representation itself. |
| `/bibs` rejects `q=` | HIGH | The list endpoint `GET /almaws/v1/bibs` is identifier-only; it does NOT accept a free-form `q=` keyword query (returns HTTP 400 errorCode 401873). Use `mms_id`/`other_system_id` etc., or SRU for keyword search. |
| Letters PUT requires XML | HIGH | `PUT /almaws/v1/conf/letters/{code}` rejects JSON with HTTP 400 + alma_code 60105 ("JSON is not supported for this API."). Send `Content-Type: application/xml` and an XML body. **Documented in swagger description** — easily missed in initial implementation; verify the swagger description, not just `consumes`. Some letter fields (e.g., `description`) are derived from the labels code-table and silently ignored on PUT — assert mutations on `xsl` / `enabled` / `channel` instead. |
| User attachments: no DELETE | MEDIUM | Alma exposes no DELETE endpoint for `/users/{id}/attachments/{att_id}` (swagger lists only POST + GET; documented by absence). Uploads accumulate; manual UI cleanup is the only path. Trying DELETE returns 400 + alma_code 401861 ("User with identifier ... was not found") because Alma's router parses the path as a malformed user lookup. |
| User attachment upload format | MEDIUM | `POST /users/{id}/attachments` accepts JSON+base64 (NOT multipart). Body shape: `{"type": "GENERAL", "note": "...", "file_name": "...", "content": "<base64>"}`. **`type` must be a plain string** — sending `{"value": "GENERAL"}` returns 400 ("Cannot deserialize value of type java.lang.String from Object value"), unusual since Alma elsewhere uses the value-wrapper. Swagger references `rest_attachment.json#/rest_attachment` for the request body schema; the type-as-string requirement lives there but is easy to miss. |
| User DELETE returns 204 (empty body) | MEDIUM | `DELETE /almaws/v1/users/{id}` returns **HTTP 204 No Content** with no body (matches swagger: `204: "Deleted"`). NOT the deleted user payload — `.data` is empty. If you need an audit snapshot, GET the user before DELETE and persist that yourself. Latency is usually <2s but observed up to ~40s under load. Second DELETE on a freshly-deleted user returns 400 + alma_code 401861 — treat as "already deleted, OK" when retrying after a hung call. |
| User loans: no DELETE endpoint | MEDIUM | `/users/{id}/loans/{loan_id}` only exposes GET / POST (op=renew) / PUT — there is no DELETE. To clear a loan, complete it: call `POST /bibs/{mms_id}/holdings/{hid}/items/{item_pid}?op=scan&library=&circ_desk=` (the `BibliographicRecords.scan_in_item` wrapper). The same Alma endpoint serves both work-order placement (with `work_order_type`) and circulation returns (with just `circ_desk` and no work_order_type). |

## Input/Output Asymmetries

### Owner Field Format (Resource Sharing)

→ Moved to the `alma-resource-sharing` skill (references/quirks-errors-validation.md).

### Requested Media Field (Resource Sharing)

→ Moved to the `alma-resource-sharing` skill (references/quirks-errors-validation.md).

## Nested Data Structures

→ Moved to the `alma-acquisitions-specialist` skill (quirks.md).

## Undocumented Fields

### Fields Not in Schema but Present in Responses

Many useful fields appear in API responses but aren't documented in XSD schemas.

#### Resource Sharing Undocumented Fields

→ Moved to the `alma-resource-sharing` skill (references/quirks-errors-validation.md).

#### Acquisitions Undocumented Fields

→ Moved to the `alma-acquisitions-specialist` skill (quirks.md).

### Date Field Duplication

**Both Coarse and Precise Timestamps**:

```python
# Lending request example
{
    "created_date": "2025-08-20Z",                    # Day precision
    "created_time": "2025-08-20T05:42:24.143Z",      # Millisecond precision
    "last_modified_date": "2025-09-18Z",
    "last_modified_time": "2025-09-18T11:10:20.491Z"
}
```

**When to Use Each**:
- `*_date` (YYYY-MM-DDZ): For display and day-level filtering
- `*_time` (ISO 8601): For precise sequencing and audit trails

**Why Both Exist**:
- `*_date`: What you send in requests
- `*_time`: What Alma tracks internally
- Alma converts your date to precise timestamp
- Returns both for flexibility

## Required Workflow Sequences

→ Moved to the `alma-acquisitions-specialist` skill (quirks.md).

## Linking Behaviors

→ Moved to the `alma-acquisitions-specialist` skill (quirks.md).

## Query Syntax Quirks

### `/bibs` is identifier-only — no keyword search

→ Moved to the `alma-bibs-inventory` skill (references/bibs-api.md).

### Invoice Search by POL

→ Moved to the `alma-acquisitions-specialist` skill (quirks.md).

## Field Format Rules

### Fund Distribution Rules

→ Moved to the `alma-acquisitions-specialist` skill (quirks.md).

### Date Format Requirements

**Required Format**: ISO 8601 with timezone indicator

```python
# ✅ CORRECT - With 'Z' suffix
"2025-01-15Z"                    # Date only
"2025-01-15T14:30:00Z"          # Date and time

# ❌ WRONG - Missing timezone
"2025-01-15"                    # Causes error 40166411

# ❌ WRONG - Wrong format
"01/15/2025"                    # US format (rejected)
"15-01-2025"                    # European format (rejected)
```

**Helper for Date Formatting**:
```python
# Use built-in helper
from datetime import datetime

formatted = acq._format_invoice_date("2025-01-15")
# Returns: "2025-01-15Z"

formatted = acq._format_invoice_date(datetime(2025, 1, 15))
# Returns: "2025-01-15Z"
```

## Code Table Value Constraints

### Partner Codes (Resource Sharing)

→ Moved to the `alma-resource-sharing` skill (references/quirks-errors-validation.md).

### Format Values (Resource Sharing)

→ Moved to the `alma-resource-sharing` skill (references/quirks-errors-validation.md).

## Item Receiving Behaviors

→ Moved to the `alma-acquisitions-specialist` skill (quirks.md).

## Digital Representations

→ Moved to the `alma-digital` skill (references/quirks.md).

## Duplicate Prevention

### Check Before Creating

**Pattern for Invoices**:
```python
# Always check for duplicates BEFORE creating
check = acq.check_pol_invoiced(pol_id)
if check['is_invoiced']:
    print(f"⚠️ POL already has {check['invoice_count']} invoice(s)")
    for inv in check['invoices']:
        print(f"  {inv['invoice_number']}: {inv['payment_status']}")
    # Use existing invoice instead of creating new one
else:
    # Safe to create new invoice
    invoice = acq.create_invoice_simple(...)
```

**Why This Matters**:
- Prevents double-invoicing same POL
- Avoids financial errors (paying twice)
- No built-in API protection for this
- Must be implemented in application logic

**See Also**: Acquisitions API - Duplicate Prevention (`alma-acquisitions-specialist` skill)

## Testing Discoveries

### Real vs Documentation Discrepancies

**Owner Field** (Resource Sharing):
- **Schema Says**: Wrapped object with value/desc
- **Reality**: Plain string
- **Discovered**: Through 400 error and testing

**Invoice Reference** (Acquisitions):
- **Expected**: POL's `invoice_reference` field populated
- **Reality**: Often empty/null even when linked
- **Discovered**: Testing POL-01001 with two invoices

**Status Values** (Resource Sharing):
- **Documented**: `REQUEST_CREATED_LEN`
- **Observed**: `SHIPPED_PHYSICALLY` and others
- **Discovered**: SANDBOX request 10000000000000016

**Field Formats** (Resource Sharing):
- **Expected**: Consistent wrapping per schema
- **Reality**: `owner` plain, `requested_media` plain, others wrapped
- **Discovered**: Testing create operations

### Trust Testing Over Documentation

**General Principle**: When schema contradicts real API behavior, **trust the API**.

**Steps When Encountering Discrepancy**:
1. Test in SANDBOX with real data
2. Observe actual request/response formats
3. Document the quirk in this file
4. Update implementation to match reality
5. Add comment noting schema discrepancy

**Example**:
```python
# Note: Schema shows owner as wrapped object, but API requires plain string!
# See: api_quirks_and_gotchas.md#owner-field-format
request_data = {
    "owner": "MAIN"  # Plain string (schema is wrong)
}
```

## Best Practices for Handling Quirks

### 1. Never Trust Schema Alone

```python
# ❌ BAD - Blindly follow schema
request_data = build_from_schema(schema_definition)

# ✅ GOOD - Test and validate
request_data = build_from_tested_pattern()
# Add comment explaining any schema discrepancies
```

### 2. Validate in SANDBOX First

```python
# Always test new operations in SANDBOX
client = AlmaAPIClient('SANDBOX')
result = test_operation()

# Only move to PRODUCTION after verification
client = AlmaAPIClient('PRODUCTION')
result = production_operation()
```

### 3. Document Discovered Quirks

```python
# When you find unexpected behavior, document it
"""
QUIRK: Invoice payment status is nested in payment object, not at root.
See: api_quirks_and_gotchas.md#invoice-payment-status-location

Correct path: invoice['payment']['payment_status']['value']
"""
```

### 4. Use Helper Methods

```python
# ❌ BAD - Manual navigation of quirky structure
payment_status = invoice['payment']['payment_status']['value']
items = pol_data['location'][0]['copy']

# ✅ GOOD - Use helpers that encapsulate quirks
check = acq.check_invoice_payment_status(invoice_id)
items = acq.extract_items_from_pol_data(pol_data)
```

### 5. Add Protection Layers

```python
# Protect against quirks with validation
def create_lending_request_safe(**kwargs):
    # Ensure owner is plain string (common mistake)
    if isinstance(kwargs.get('owner'), dict):
        raise ValueError("owner must be plain string, not wrapped object!")

    # Now safe to call
    return rs.create_lending_request(**kwargs)
```

## Summary of Critical Quirks

**Must-Know Quirks**:
1. **Owner field**: Plain string (schema wrong!)
2. **Payment status**: Nested in `payment` object
3. **Invoice approval**: MUST approve before paying
4. **POL items**: In `location[0].copy[]` array
5. **Invoice-POL link**: Via invoice lines, not POL field
6. **Fund distribution**: EITHER amount OR percent

**Nice-to-Know Quirks**:
- Undocumented fields exist and are useful
- Date fields duplicated (coarse + precise)
- Partner codes have internal value vs display name
- Query syntax varies by field
- Item process_type changes after receiving

**When in Doubt**:
- Test in SANDBOX
- Check this documentation
- Trust API behavior over schema
- Use helper methods when available
