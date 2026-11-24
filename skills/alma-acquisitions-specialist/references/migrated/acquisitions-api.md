<!-- moved from alma-api-expert/references/acquisitions_api.md -->
# Alma Acquisitions API Reference

Comprehensive guide to Alma Acquisitions API endpoints, workflows, and troubleshooting.

## Table of Contents
- [Official Documentation](#official-documentation)
- [Key Endpoints](#key-endpoints)
- [Critical Workflows](#critical-workflows)
- [Invoice Operations](#invoice-operations)
- [POL Operations](#pol-operations)
- [Item Receiving](#item-receiving)
- [Common Errors](#common-errors)
- [Duplicate Prevention](#duplicate-prevention)
- [Helper Methods](#helper-methods)

## Official Documentation

- **Base URL**: https://developers.exlibrisgroup.com/alma/apis/acq/
- **API Docs**: https://developers.exlibrisgroup.com/alma/apis/
- **OpenAPI/Swagger**: Available for download at developers.exlibrisgroup.com

## Key Endpoints

### Purchase Order Lines (POL)

**Get POL**
```
GET /almaws/v1/acq/po-lines/{po_line_id}
```
- Retrieves complete POL information including items, pricing, and status
- Returns POL object with embedded item details

**Get POL Items**
```
GET /almaws/v1/acq/po-lines/{po_line_id}/items
```
- Returns list of all items associated with a POL
- Each item includes only `item_data.pid`, `item_data.barcode` and a `link` to the Get-Item API; fetch the item for status/receiving data (corrected 2026-11-12, see evaluation AQ-29)

**Update POL**
```
PUT /almaws/v1/acq/po-lines/{po_line_id}
```
- Updates POL data including pricing, vendor information, notes
- Requires complete POL object in request body

### Invoices

**Get Invoice**
```
GET /almaws/v1/acq/invoices/{invoice_id}
```
- Retrieves complete invoice data including lines, amounts, status
- Optional parameter: `view=brief|full` (default: full)

**List Invoices**
```
GET /almaws/v1/acq/invoices
```
- Query parameters: `limit`, `offset`, `q` (query string)
- Supports filtering by status, vendor, date ranges
- Query format: documented `q` fields are invoice_number, vendor_code, pol_number, po_number, pol_title, vendor_name, additional_pol_reference, invoice_reference_number, all, e.g. `vendor_code~VENDOR_CODE`. Filter status with the separate `base_status` (ACTIVE/CLOSED) and `invoice_workflow_status` parameters; `invoice_status~` and `vendor~` are silently ignored and return all invoices (corrected 2026-11-12, see evaluation AQ-14)

**Create Invoice**
```
POST /almaws/v1/acq/invoices
```
- Creates new invoice with vendor and date information
- Returns invoice object with generated invoice_id

**Create Invoice Line**
```
POST /almaws/v1/acq/invoices/{invoice_id}/lines
```
- Adds line item to existing invoice
- Links to POL via reference in line data
- Must be done before processing invoice

**Get Invoice Lines**
```
GET /almaws/v1/acq/invoices/{invoice_id}/lines
```
- Returns all lines for an invoice
- Use this endpoint, NOT the embedded `invoice_line` in full invoice response
- Supports pagination: `limit` and `offset` parameters

**Invoice Service Operations**
```
POST /almaws/v1/acq/invoices/{invoice_id}?op={operation}
```
- **Operations**:
  - `paid`: Mark invoice as paid
  - `process_invoice`: Approve/process invoice (**MANDATORY** after creation)
  - `mark_in_erp`: Mark as sent to ERP system
  - `rejected`: Reject invoice
- **Request Body**: Empty object `{}`
- **Effect**: Updates invoice status and payment_status fields

### Items and Receiving

> **Stop before receiving through the API.** Receiving can change an item's process type and may conflict with an item that is on loan or on the shelf. Untested and deferred (user rule, 15 Nov 2026): see *Receiving through the API* in SKILL.md. Never receive as a side step of another flow; ask the user first.


**Receive Existing Item**
```
POST /almaws/v1/acq/po-lines/{po_line_id}/items/{item_id}?op=receive
```
- **Required Query Parameter**: `op=receive`
- **Optional Parameters**:
  - `receive_date`: Date of receipt (format: YYYY-MM-DDZ)
  - `department`: Department code for receiving
  - `department_library`: Library code of receiving department
- **Content-Type**: `application/xml`
- **Request Body**: Empty `<item/>` or item object with updates
- **Response**: Updated Item object
- **Effect**:
  - Changes item status to "received"
  - May move the item to transit; process type is an object with PROCESSTYPE codes such as `ACQ`, `TRANSIT`, `WORK_ORDER_DEPARTMENT`, not "acquisition"/"in transit" (corrected 2026-11-12, see evaluation AQ-24)
  - Automatically creates request if configured

**Error Codes**:
- `40166411`: Invalid parameter value
- `401875`: Department not found
- `401871`: PO Line not found
- `401877`: Failed to receive PO Line

**Add and Receive New Item**
```
POST /almaws/v1/acq/po-lines/{po_line_id}/items
```
- Adds a new item to POL and marks it as received
- Request body contains complete item object
- Returns created Item object

## Critical Workflows

### ⚠️ MANDATORY: Invoice Workflow Sequence

**Invoices MUST be processed/approved BEFORE they can be paid. This is enforced by Alma API.**

```python
# ✅ CORRECT WORKFLOW:
# Step 1: Create invoice
invoice = acq.create_invoice_simple(
    invoice_number="INV-2025-001",
    invoice_date="2025-01-08",
    vendor_code="RIALTO",
    total_amount=100.00
)

# Step 2: Add invoice lines
line = acq.create_invoice_line_simple(
    invoice_id=invoice['id'],
    pol_id="POL-01001",
    amount=100.00,
    quantity=1
)

# Step 3: MUST PROCESS FIRST (mandatory!)
processed = acq.approve_invoice(invoice_id)
# API: POST /almaws/v1/acq/invoices/{id}?op=process_invoice

# Step 4: Then can mark as paid (includes automatic duplicate protection)
paid = acq.mark_invoice_paid(invoice_id)
# API: POST /almaws/v1/acq/invoices/{id}?op=paid

# ❌ WRONG - Will fail with error 402459:
invoice = acq.create_invoice_simple(...)
line = acq.create_invoice_line_simple(...)
paid = acq.mark_invoice_paid(invoice_id)  # FAILS - not processed yet!
```

**Invoice State Transitions**:
1. **Created**: `invoice_status=ACTIVE`, `workflow_status=InReview`, `approval_status=PENDING`, `payment_status=NOT_PAID`
2. **After Processing**: `approval_status=APPROVED`; workflow code depends on configuration (observed: `Ready to be Paid` = Waiting for Payment). There is no `Approved` workflow code (corrected 2026-11-12, see evaluation AQ-06)
3. **After Payment**: `payment_status=PAID` (the Sandbox PaymentStatus table has only NOT_PAID and PAID) (corrected 2026-11-12, see evaluation AQ-07)

**Common Errors**:
- **Error 402459**: "Error while trying to retrieve invoice" - Usually means invoice not processed yet or deleted
- **Solution**: Always call `approve_invoice()` before `mark_invoice_paid()`

### ⚠️ CRITICAL: Duplicate Payment Prevention

**Automatic duplicate payment protection** is built into `mark_invoice_paid()` (added 2025-10-23):

```python
# ✅ SAFE - Automatic protection (default behavior):
try:
    result = acq.mark_invoice_paid(invoice_id)
    # Protection automatically checks:
    # - Is invoice already paid? (PAID, FULLY_PAID, PARTIALLY_PAID)
    # - Is invoice already closed?
    # - Is invoice approved?
except AlmaAPIError as e:
    # Will raise error if invoice already paid or not ready
    print(f"Payment prevented: {e}")

# ⚠️ BYPASS PROTECTION (dangerous, not recommended):
result = acq.mark_invoice_paid(invoice_id, force=True)

# ✅ MANUAL CHECK before payment:
check = acq.check_invoice_payment_status(invoice_id)
if check['is_paid']:
    print(f"⚠️ Invoice already paid: {check['payment_status']}")
elif check['can_pay']:
    acq.mark_invoice_paid(invoice_id)
else:
    print(f"Cannot pay: {check['warnings']}")
```

**Protection Features**:
- Automatically checks invoice payment status before paying
- Prevents duplicate payments (PAID, FULLY_PAID, PARTIALLY_PAID states)
- Prevents paying closed invoices
- Blocks invoices whose approval status is neither APPROVED nor PENDING (PENDING is allowed by `can_pay`) (corrected 2026-11-12, see evaluation AQ-35)
- Provides clear error messages with current state
- Includes `force=True` option to bypass (not recommended)

**When Protection Triggers**:
1. Invoice already paid (status: PAID, FULLY_PAID, PARTIALLY_PAID)
2. Invoice already closed (status: CLOSED)
3. Invoice approval status not APPROVED or PENDING (a PENDING invoice passes the check) (corrected 2026-11-12, see evaluation AQ-35)

**Error Message Example**:
```
AlmaAPIError: ⚠️ DUPLICATE PAYMENT PREVENTED!
Invoice 123456 is already paid.
Payment Status: PAID
Invoice Status: CLOSED
Use force=True to bypass this protection (not recommended).
```

### ⚠️ MANDATORY: Pre-Flight Checks

**Before ANY invoice creation or payment:**

```python
# ✅ RULE 1: ALWAYS check for existing invoices BEFORE creating new one
check = acq.check_pol_invoiced(pol_id)
if check['is_invoiced']:
    print(f"⚠️ STOP! POL {pol_id} already has {check['invoice_count']} invoice(s)")
    for inv in check['invoices']:
        print(f"  - Invoice {inv['invoice_number']}")
        print(f"    Status: {inv['invoice_status']} / Payment: {inv['payment_status']}")
    # REVIEW existing invoices - DO NOT create new one
    # USE existing invoice instead
else:
    # Only NOW is it safe to create new invoice
    invoice = acq.create_invoice_simple(...)

# ✅ RULE 2: NEVER skip approval step
invoice = acq.create_invoice_simple(...)
line = acq.create_invoice_line_simple(...)
processed = acq.approve_invoice(invoice_id)  # MANDATORY - do not skip!
paid = acq.mark_invoice_paid(invoice_id)     # Includes automatic protection

# ❌ RULE 3: When error occurs, FIX existing invoice - DON'T create new one
if payment_fails_with_error_402459:
    # CORRECT: Fix the existing invoice
    acq.approve_invoice(existing_invoice_id)  # Process it first
    acq.mark_invoice_paid(existing_invoice_id)  # Then pay

    # WRONG: Create new invoice (causes duplicate!)
    # new_invoice = acq.create_invoice_simple(...)  # ✗ DON'T DO THIS

# ✅ RULE 4: Trust the protection - do NOT bypass
try:
    result = acq.mark_invoice_paid(invoice_id)  # Has automatic protection
except AlmaAPIError as e:
    # Protection blocked payment for good reason
    print(f"Payment prevented: {e}")
    # Review the error - do NOT use force=True
```

## Invoice Operations

### Invoice Data Structure

Based on Alma API XSD Schema (`rest_invoice.xsd`):

**Top-Level Fields**:
- `id`: string - Invoice identifier (output only, unique)
- `number`: string - Vendor invoice number (mandatory)
- `invoice_date`: date - Date of invoice (mandatory)
- `vendor`: object - Vendor code with attributes (mandatory)
  - `value`: Vendor code
  - `desc`: Vendor description
- `total_amount`: **decimal** - Total invoice amount (mandatory, simple numeric type)
- `currency`: object - Currency information (optional, defaults to institution currency)
  - `value`: Currency code
  - `desc`: Currency description
- `invoice_status`: object - Invoice processing status
  - `value`: Base status code, ACTIVE or CLOSED only. Workflow stage is in `invoice_workflow_status`, approval in `invoice_approval_status` (corrected 2026-11-12, see evaluation AQ-08)
  - `desc`: Status description
- `payment`: object - Payment information (contains payment_status)
  - `prepaid`: boolean
  - `internal_copy`: boolean
  - `payment_status`: object - **Payment status is nested here**
    - `value`: Status code (NOT_PAID, PAID in the Sandbox PaymentStatus table) (corrected 2026-11-12, see evaluation AQ-07)
    - `desc`: Status description
  - `voucher_number`: string
  - `voucher_amount`: string
- `invoice_lines`: object - `{invoice_line: [...], total_record_count}`; omitted with `view=brief` (corrected 2026-11-12, see evaluation AQ-11)
- `creation_date`: date - When invoice was created in Alma
- `owner`: object - Owner of the invoice

**⚠️ IMPORTANT**: `total_amount` is a **simple decimal field**, not a complex object with nested 'sum' and 'currency'. Currency information is separate in the `currency` field.

**Invoice Payment Status Location**:
```python
# ❌ WRONG - Payment status is NOT at root level
payment_status = invoice['payment_status']

# ✅ CORRECT - Payment status is nested in 'payment' object
payment_status = invoice['payment']['payment_status']['value']
```

### Invoice Line Structure

**Fund Distribution - Critical Rule**:

**Must use EITHER `percent` OR `amount`, NOT both and not neither.**

```python
# ✅ CORRECT - Use percent only
"fund_distribution": [{
    "fund_code": {"value": "AAC_FUND"},
    "percent": 100  # 100% of line amount allocated to this fund
}]

# ✅ CORRECT - Use amount only (for split funding)
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "amount": 50.00},
    {"fund_code": {"value": "FUND_B"}, "amount": 30.00}
]

# ❌ WRONG - Both amount and percent
"fund_distribution": [{
    "fund_code": {"value": "AAC_FUND"},
    "amount": 50.0,        # Can't have both!
    "percent": 100
}]
```

**Common Error**: "Invoice line fund percentage or amount must be declared, not both and not neither."

**Solution**: Remove one field. For single-fund allocation, use `percent: 100`. For multi-fund allocation, use explicit `amount` values that sum to line total.

## POL Operations

### POL Data Structure

**⚠️ POL Items Are NOT at Root Level**:

Items are nested in location → copy structure:

```python
# Path: POL → location (list) → copy (list of item objects)

# Extract items correctly:
pol_data = acq.get_pol(pol_id)
items = []
for location in pol_data.get('location', []):
    for item in location.get('copy', []):
        items.append(item)

# Or use helper:
items = acq.extract_items_from_pol_data(pol_data)

# Item ID field is 'pid', not 'item_id'
item_id = item['pid']

# Check if item is received:
is_received = item.get('receive_date') is not None
```

### Invoice-POL Linkage

**How the Link Works**:

The relationship between invoices and POLs works through **invoice lines**:

1. Invoice has invoice lines (get via `/almaws/v1/acq/invoices/{invoice_id}/lines`)
2. Each invoice line has a `po_line` field containing the POL ID (e.g., "POL-01001")
3. Multiple invoice lines can reference the same POL
4. One invoice can have lines for multiple POLs

**Finding POL-Invoice Links**:
```python
# Get invoice lines
invoice_lines = acq.get_invoice_lines(invoice_id)

# Check which POL each line references
for line in invoice_lines:
    pol_id = line.get('po_line')  # e.g., "POL-01001"
    quantity = line.get('quantity')
    price = line.get('price')
    total = line.get('total_price')
```

**Important Notes**:
- POL's `invoice_reference` field is often NOT populated (even when linked correctly)
- The authoritative link is in the **invoice line's `po_line` field**
- To verify linkage: Get invoice lines and check `po_line` field
- POL closure depends on POL type and configuration; one Sandbox E_BOOK_OT POL closed after invoice processing, before payment. Do not assume closure waits for payment (corrected 2026-11-12, see evaluation AQ-33)

### Searching Invoices by POL

The Alma API supports **direct search of invoices by POL number**:

**Correct Query Format**:
```python
# ✅ CORRECT - Tilde format (recommended)
query = f"pol_number~{pol_id}"
params = {"q": query, "limit": 100}
response = client.get("almaws/v1/acq/invoices", params=params)

# ✅ Also works - Equals format
query = f"pol_number={pol_id}"

# ❌ FAILS - Colon format
query = f"pol_number:{pol_id}"  # Server error!
```

**Important Notes**:
- This query searches **across all invoice lines** automatically
- Much more efficient than iterating through invoices manually
- Returns complete invoice objects that contain the POL
- Use `check_pol_invoiced()` method which implements this correctly
- Prevents double-invoicing by detecting existing invoice lines

**Example**:
```python
# Search for all invoices containing POL-01001
response = client.get("almaws/v1/acq/invoices", params={"q": "pol_number~POL-01001"})
# Returns all invoices that have lines referencing POL-01001
```

## Item Receiving

> **Stop before receiving through the API.** Receiving can change an item's process type and may conflict with an item that is on loan or on the shelf. Untested and deferred (user rule, 15 Nov 2026): see *Receiving through the API* in SKILL.md. Never receive as a side step of another flow; ask the user first.


### Standard Receiving Workflow

```python
# 1. Get POL and extract items
pol_data = acq.get_pol(pol_id)
items = acq.extract_items_from_pol_data(pol_data)

# 2. Find unreceived item
unreceived = [item for item in items if not item.get('receive_date')]
if unreceived:
    item_id = unreceived[0]['pid']

    # 3. Receive item (will move to "in transit")
    acq.receive_item(pol_id, item_id)
```

### Receive and Keep in Department

**Problem**: When receiving items via `acq.receive_item()`, items automatically move to "in transit" instead of staying in the acquisitions department.

**Solution**: Use `receive_and_keep_in_department()` workflow that combines receiving with scan-in operation:

```python
# Get POL data first to extract MMS and holding IDs
pol_data = acq.get_pol(pol_id)
items = acq.extract_items_from_pol_data(pol_data)
unreceived = [item for item in items if not item.get('receive_date')]

if unreceived:
    item = unreceived[0]
    item_id = item['pid']

    # Extract MMS and holding IDs from POL data
    mms_id = pol_data.get('resource_metadata', {}).get('mms_id', {}).get('value')
    # holding id is at location[].holding[].id, not location[0].holding_id (corrected 2026-11-12, see evaluation AQ-27)
    holding_id = pol_data.get('location', [{}])[0].get('holding', [{}])[0].get('id')

    # Receive and keep in department (prevents Transit)
    result = acq.receive_and_keep_in_department(
        pol_id=pol_id,
        item_id=item_id,
        mms_id=mms_id,
        holding_id=holding_id,
        library="MAIN",
        department="ACQ",
        work_order_type="AcqWorkOrder",
        work_order_status="CopyCataloging"
    )

    # Item is now received and in work order, NOT in Transit
```

**Configuration Requirements**:
- Work order types and statuses must be configured in Alma:
  - Path: Configuration > Fulfillment > Physical Fulfillment > Work Order Types
- Common work order types: `AcqWorkOrder`, `CatalogingWorkOrder`, `ConservationWorkOrder`
- Common statuses for AcqWorkOrder: `CopyCataloging`, `Labeling`, `Processing`, `Review`

## Common Errors

### Error 402459: Invoice Retrieval Error

**Error Message**: "Error while trying to retrieve invoice"

**Common Causes**:
1. Invoice not processed/approved yet
2. Invoice was deleted
3. Incorrect invoice ID

**Solution**:
```python
# Always process invoice before payment
acq.approve_invoice(invoice_id)  # MUST call this first
acq.mark_invoice_paid(invoice_id)  # Then can pay
```

### Fund Distribution Error

**Error Message**: "Invoice line fund percentage or amount must be declared, not both and not neither"

**Cause**: Including both `amount` and `percent` in fund_distribution

**Solution**:
```python
# ✅ CORRECT - Use percent only
"fund_distribution": [{
    "fund_code": {"value": "AAC_FUND"},
    "percent": 100  # 100% of line amount
}]

# ❌ WRONG - Both amount and percent
"fund_distribution": [{
    "fund_code": {"value": "AAC_FUND"},
    "amount": 50.0,
    "percent": 100  # Can't have both!
}]
```

### Item Receiving Errors

**Error 40166411**: Invalid parameter value
- Check date format (YYYY-MM-DDZ)
- Verify department code exists

**Error 401875**: Department not found
- Department code doesn't exist in Alma
- Check spelling and case sensitivity

**Error 401871**: PO Line not found
- Invalid POL ID
- POL may be closed or deleted

**Error 401877**: Failed to receive PO Line
- Item may already be received
- Check item status first

## Duplicate Prevention

### Checking POL Invoice Status

```python
# Check if POL already has invoice(s)
check = acq.check_pol_invoiced("POL-01001")

if check['is_invoiced']:
    print(f"⚠️ POL already has {check['invoice_count']} invoice(s)")
    for inv in check['invoices']:
        print(f"  - {inv['invoice_number']}: {inv['amount']}")
        print(f"    Invoice Status: {inv['invoice_status']}")
        print(f"    Payment Status: {inv['payment_status']}")
else:
    # Safe to create new invoice
    invoice = acq.create_invoice_simple(...)
```

**Returns**:
```python
{
    'is_invoiced': bool,           # Has existing invoice(s)?
    'invoice_count': int,          # Number of invoices
    'invoices': [                  # List of existing invoices
        {
            'invoice_id': str,
            'invoice_number': str,
            'invoice_status': str,
            'payment_status': str,
            'amount': str            # display string, e.g. '100.0' or '100.0 ILS'
            # also: approval_status, line_id, line_status
        }
    ],
    # 'search_error': str        # present when the search failed; is_invoiced is then False (fails open)
}
# invoice_count counts matching invoice LINES, not distinct invoices (corrected 2026-11-12, see evaluation AQ-36)
```

### Checking Invoice Payment Status

```python
# Check if invoice is already paid
check = acq.check_invoice_payment_status(invoice_id)

if check['is_paid']:
    print(f"⚠️ Invoice already paid: {check['payment_status']}")
elif check['can_pay']:
    acq.mark_invoice_paid(invoice_id)
else:
    print(f"Cannot pay: {check['warnings']}")
```

**Returns**:
```python
{
    'is_paid': bool,           # Is invoice already paid?
    'payment_status': str,     # PAID, NOT_PAID, etc.
    'invoice_status': str,     # ACTIVE, CLOSED, etc.
    'approval_status': str,    # APPROVED, PENDING, etc.
    'can_pay': bool,           # Safe to pay?
    'warnings': List[str]      # Any warnings
}
```

## Helper Methods

**POL Utilities**:
- `get_vendor_from_pol(pol_id)` - Extract vendor code from POL
- `get_fund_from_pol(pol_id)` - Extract primary fund code from POL
- `get_price_from_pol(pol_id)` - Extract POL list price as float
- `check_pol_invoiced(pol_id)` - Check for existing invoices linked to POL
- `extract_items_from_pol_data(pol_data)` - Extract items from location→copy structure

**Invoice Utilities**:
- `check_invoice_payment_status(invoice_id)` - Check payment status with detailed info
- `get_invoice_lines(invoice_id)` - Get all invoice lines (use this, not embedded lines)
- `get_invoice_summary(invoice_id)` - Formatted summary with correct payment_status

**Invoice Creation Helpers**:
- `create_invoice_simple(...)` - Create invoice with minimal parameters
- `create_invoice_line_simple(...)` - Create line with auto-fund extraction from POL
- `create_invoice_with_lines(...)` - Create + lines, then process if `auto_process=True` (default) and pay only if `auto_pay=True` (default False) (corrected 2026-11-12, see evaluation AQ-37)
- `approve_invoice(invoice_id)` - Process/approve invoice (MANDATORY before payment)
- `mark_invoice_paid(invoice_id, force=False)` - Mark as paid with automatic duplicate protection

**Item Receiving**:
- `receive_item(pol_id, item_id, ...)` - Standard receive (item goes to transit)
- `receive_and_keep_in_department(...)` - Receive and keep in department with work order

## Complete Rialto Workflow

```python
# Complete workflow for Rialto EDI vendor
# (One-time POL with auto-invoice creation)

# 1. Get POL and extract data
pol_data = acq.get_pol(pol_id)
items = acq.extract_items_from_pol_data(pol_data)

# 2. Find invoice by POL. Do NOT use pol_data['invoice_reference'] as an ID: it holds the
#    vendor invoice number, and GET /acq/invoices/{that value} returns 'not found' (corrected 2026-11-12, see evaluation AQ-32)
invoice_id = None
check = acq.check_pol_invoiced(pol_id)
if check['is_invoiced']:
    invoice_id = check['invoices'][0]['invoice_id']

# 3. Find unreceived item
unreceived = [item for item in items if not item.get('receive_date')]
if unreceived:
    item_id = unreceived[0]['pid']

    # 4. Receive item
    acq.receive_item(pol_id, item_id)

# 5. Approve and pay invoice
if invoice_id:
    # Check if already paid
    check = acq.check_invoice_payment_status(invoice_id)

    if not check['is_paid']:
        # Must approve first
        acq.approve_invoice(invoice_id)

        # Then mark as paid (with automatic duplicate protection)
        acq.mark_invoice_paid(invoice_id)

# 6. Verify POL closure
updated_pol = acq.get_pol(pol_id)
status = updated_pol.get('status', {}).get('value')
print(f"POL Status: {status}")  # Should be 'CLOSED' if all items received and invoice paid
```

## Best Practices

1. **Always check for duplicates** before creating invoices
2. **Always approve invoices** before paying (`approve_invoice()` is MANDATORY)
3. **Trust the automatic protection** - don't bypass with `force=True`
4. **Use helper methods** - they include proper error handling and protection
5. **Extract POL price** instead of hardcoding amounts
6. **Search by POL** to find existing invoices: `pol_number~{pol_id}`
7. **Check payment status** before attempting payment
8. **Use invoice lines endpoint** for authoritative POL linkage
9. **Test in SANDBOX** before running in PRODUCTION

## See Also

- [Error Codes & Solutions](../../../alma-api-expert/references/error_codes_and_solutions.md) - Detailed error troubleshooting
- [Data Structures](../../../alma-api-expert/references/data_structures.md) - Complete object schemas
- [API Quirks](../../../alma-api-expert/references/api_quirks_and_gotchas.md) - Known issues and workarounds
- [Pagination & Queries](../../../alma-api-expert/references/pagination_and_queries.md) - Query syntax and search patterns

<!-- moved from alma-api-expert/references/endpoint_reference.md -->
## Acquisitions API Endpoints

### Purchase Order Lines (POL)

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| GET | `/acq/po-lines/{po_line_id}` | Retrieve POL data | Yes |
| PUT | `/acq/po-lines/{po_line_id}` | Update POL | Yes |
| GET | `/acq/po-lines/{po_line_id}/items` | Get POL items | Yes |
| POST | `/acq/po-lines/{po_line_id}/items?op=receive` | Receive item | Yes |
| POST | `/acq/po-lines/{po_line_id}/items` | Add and receive new item | Yes |

**Parameters**:
- `po_line_id`: POL identifier (e.g., "POL-01001")
- `op=receive`: Operation type for receiving
- `receive_date`: Date of receipt (YYYY-MM-DDZ)
- `department`: Department code
- `department_library`: Library code

**Example**:
```
GET /almaws/v1/acq/po-lines/POL-01001
POST /almaws/v1/acq/po-lines/POL-01001/items/20000000000000001?op=receive
```

### Invoices

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| GET | `/acq/invoices/{invoice_id}` | Retrieve invoice | Yes |
| POST | `/acq/invoices` | Create invoice | Yes |
| PUT | `/acq/invoices/{invoice_id}` | Update invoice | Yes |
| GET | `/acq/invoices` | List invoices (with query) | Yes |
| POST | `/acq/invoices/{invoice_id}?op={operation}` | Invoice operations | Yes |
| GET | `/acq/invoices/{invoice_id}/lines` | Get invoice lines | Yes |
| POST | `/acq/invoices/{invoice_id}/lines` | Create invoice line | Yes |

**Invoice Operations** (`op` parameter):
- `paid`: Mark invoice as paid
- `process_invoice`: Approve/process invoice (mandatory before paying!)
- `mark_in_erp`: Mark as sent to ERP
- `rejected`: Reject invoice

**Query Parameters** (GET /acq/invoices):
- `q`: Query string (e.g., `pol_number~POL-01001`)
- `limit`: Results per page (default: 10, max: 100)
- `offset`: Starting position
- `view`: brief or full

**Examples**:
```
POST /almaws/v1/acq/invoices
POST /almaws/v1/acq/invoices/10000000000000004?op=process_invoice
POST /almaws/v1/acq/invoices/10000000000000004?op=paid
GET /almaws/v1/acq/invoices?q=pol_number~POL-01001&limit=100
GET /almaws/v1/acq/invoices/10000000000000004/lines
```

<!-- moved from alma-api-expert/references/endpoint_reference.md -->
### Creating Invoices
```
1. POST /acq/invoices (create invoice)
2. POST /acq/invoices/{id}/lines (add lines)
3. POST /acq/invoices/{id}?op=process_invoice (approve)
4. POST /acq/invoices/{id}?op=paid (mark paid)
```

<!-- moved from alma-api-expert/references/endpoint_reference.md -->
### Receiving Items
```
1. GET /acq/po-lines/{pol_id} (get POL data)
2. POST /acq/po-lines/{pol_id}/items/{item_id}?op=receive (receive)
```

<!-- moved from alma-api-expert/references/endpoint_reference.md -->
### Keeping Item in Department
```
1. POST /acq/po-lines/{pol_id}/items/{item_id}?op=receive (receive)
2. POST /bibs/{mms_id}/holdings/{holding_id}/items/{item_pid}?op=scan (scan in)
```

<!-- moved from alma-api-expert/references/endpoint_reference.md -->
### Searching Invoices by POL
```
GET /acq/invoices?q=pol_number~{pol_id}&limit=100
```

<!-- moved from alma-api-expert/references/pagination_and_queries.md -->
### Search Invoices by POL

**Most Efficient Method**:
```python
# Direct POL search
query = f"pol_number~{pol_id}"
params = {"q": query, "limit": 100}

response = client.get("almaws/v1/acq/invoices", params=params)
invoices = response.json().get('invoice', [])
```

**Why This Works**:
- Alma automatically searches across all invoice lines
- Returns complete invoice objects
- Much faster than iterating through invoices manually

**Example**:
```python
# Find all invoices for POL-01001
check = acq.check_pol_invoiced("POL-01001")

if check['is_invoiced']:
    print(f"Found {check['invoice_count']} invoices:")
    for inv in check['invoices']:
        print(f"  {inv['invoice_number']}: {inv['payment_status']}")
```

<!-- moved from alma-api-expert/references/pagination_and_queries.md -->
### Invoice Lines Pagination

**Invoice lines endpoint supports pagination**:
```python
# Get all lines for large invoice
invoice_id = "10000000000000004"
endpoint = f"almaws/v1/acq/invoices/{invoice_id}/lines"

lines = fetch_all_pages(endpoint, item_key='invoice_line')
print(f"Total lines: {len(lines)}")
```
