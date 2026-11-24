<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
## Nested Data Structures

### Invoice Payment Status Location

**⚠️ COMMON MISTAKE**: Payment status is NOT at root level!

**Incorrect Assumption**:
```python
# ❌ WRONG - payment_status not at root
payment_status = invoice['payment_status']  # KeyError!
```

**Actual Structure**:
```python
# ✅ CORRECT - nested in payment object
payment_status = invoice['payment']['payment_status']['value']
```

**Full Path**:
```
invoice
  └── payment (object)
        ├── prepaid (boolean)
        ├── payment_status (object)
        │     ├── value (string): "PAID", "NOT_PAID", etc.
        │     └── desc (string)
        ├── voucher_number (string)
        └── voucher_amount (string)
```

**Why This Matters**:
- Checking wrong location gives KeyError
- Can't determine if invoice is paid
- Duplicate payment prevention depends on this
- Many developers expect flat structure

**Helper Methods**:
```python
# Use helper to extract safely
check = acq.check_invoice_payment_status(invoice_id)
if check['is_paid']:
    print(f"Already paid: {check['payment_status']}")
```

**See Also**: [Data Structures - Invoice Structure](../../../alma-api-expert/references/data_structures.md#invoice-structure)

### POL Items Location

**Common Misconception**: Items are at POL root level

**Incorrect Assumption**:
```python
# ❌ WRONG - items not at root
items = pol_data['items']  # Doesn't exist!
```

**Actual Structure**:
```python
# ✅ CORRECT - items in location → copy path
items = pol_data.get('location', [{}])[0].get('copy', [])
```

**Full Path**:
```
pol
  └── location (array)
        └── [0] (object)
              ├── holding (array of {id, link})  ← holding id is here (corrected 2026-11-12, see evaluation AQ-27)
              ├── library
              └── copy (array)  ← This is the items array!
                    └── [0..n] (item objects)
                          ├── pid (item ID)
                          ├── barcode
                          ├── receive_date
                          └── ...
```

**Why Structure is Weird**:
- POLs can have multiple locations (rare)
- Each location can have multiple copies (items)
- Most POLs have single location with multiple items
- Structure optimized for multi-location scenario

**Helper Method**:
```python
# Use helper to extract correctly
items = acq.extract_items_from_pol_data(pol_data)
```

**Finding Unreceived Items**:
```python
items = acq.extract_items_from_pol_data(pol_data)
unreceived = [item for item in items if not item.get('receive_date')]
```

**See Also**: [Data Structures - POL Structure](../../../alma-api-expert/references/data_structures.md#pol-structure)

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
#### Acquisitions Undocumented Fields

**Invoice Fields**:
```python
{
    "creation_date": "2025-10-22Z",  # When invoice created in Alma
    "owner": {                        # Invoice owner
        "value": "MAIN",
        "desc": "Main Library"
    }
}
```

**POL Fields**: `receiving_operator` and `process_type` are NOT in POL copy objects; they are `item_data` fields of the Items API, and `process_type` is an object such as `{"value": "TRANSIT"}` (corrected 2026-11-12, see evaluation AQ-28)

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
## Required Workflow Sequences

### Invoice Workflow Must Follow Order

**⚠️ CRITICAL**: Invoice operations must follow specific sequence.

**Incorrect Sequence**:
```python
# ❌ WRONG - Skip approval step
invoice = acq.create_invoice_simple(...)
line = acq.create_invoice_line_simple(...)
paid = acq.mark_invoice_paid(invoice_id)  # ERROR 402459!
```

**Correct Sequence**:
```python
# ✅ CORRECT - Approve before paying
invoice = acq.create_invoice_simple(...)
line = acq.create_invoice_line_simple(...)
approved = acq.approve_invoice(invoice_id)  # MANDATORY!
paid = acq.mark_invoice_paid(invoice_id)    # Now works
```

**State Transitions**:
1. **After Create**: `approval_status=PENDING`, `payment_status=NOT_PAID`
2. **After Approve**: `approval_status=APPROVED`; workflow code depends on configuration (observed `Ready to be Paid` = Waiting for Payment); no `Approved` workflow code exists (corrected 2026-11-12, see evaluation AQ-06)
3. **After Pay**: `payment_status=PAID` (corrected 2026-11-12, see evaluation AQ-07)

**Why This Exists**:
- Enforces approval workflow
- Prevents accidental payments
- Mirrors UI workflow requirements
- Error 402459 occurs if skipped

**See Also**: [Acquisitions API - Critical Workflows](acquisitions-api.md)

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
## Linking Behaviors

### Invoice-POL Linkage

**Common Misconception**: POL has `invoice_reference` field with invoice ID

**Reality**: Linkage is through invoice lines, not POL field.

**Where Linkage Actually Lives**:
```python
# ❌ POL's invoice_reference is the vendor invoice NUMBER when set, never the Alma invoice ID (corrected 2026-11-12, see evaluation AQ-32):
pol_data = acq.get_pol("POL-01001")
invoice_ref = pol_data.get('invoice_reference')  # Often None!

# ✅ Authoritative link is in INVOICE LINES:
invoice_lines = acq.get_invoice_lines(invoice_id)
for line in invoice_lines:
    pol_id = line.get('po_line')  # e.g., "POL-01001"
    # This is the authoritative link
```

**Data Flow**:
```
POL (POL-01001)
  ↓ invoice_reference field (often empty/unreliable)
  ?

Invoice Line
  ↓ po_line field (authoritative!)
  POL-01001

Invoice
  ↓ Contains lines
  Invoice Lines
```

**Why This Matters**:
- Can't rely on POL's `invoice_reference` to find invoice
- Must search invoices by POL using query: `pol_number~POL-01001`
- Invoice lines are the source of truth
- One invoice can have lines for multiple POLs
- One POL can have lines in multiple invoices (rare but possible)

**Finding Invoices for POL**:
```python
# ✅ CORRECT - Query invoices by POL number
check = acq.check_pol_invoiced("POL-01001")
if check['is_invoiced']:
    for inv in check['invoices']:
        print(f"Invoice: {inv['invoice_number']}")
```

**See Also**: [Acquisitions API - Invoice-POL Linkage](acquisitions-api.md)

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
### Invoice Search by POL

**Supported Formats**:
```python
# ✅ WORKS - Tilde format (recommended)
query = f"pol_number~{pol_id}"

# ✅ WORKS - Equals format
query = f"pol_number={pol_id}"

# ❌ FAILS - Colon format (server error!)
query = f"pol_number:{pol_id}"
```

**Why Tilde is Recommended**:
- More forgiving matching
- Consistent with other Alma queries
- Less likely to break with API changes

**Usage**:
```python
params = {"q": f"pol_number~{pol_id}", "limit": 100}
response = client.get("almaws/v1/acq/invoices", params=params)
```

**See Also**: [Pagination and Queries - Query Syntax](../../../alma-api-expert/references/pagination_and_queries.md#query-syntax)

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
### Fund Distribution Rules

**CRITICAL RULE**: Use EITHER amount OR percent, never both, never neither!

**Causes Error**:
```
Error 400: Invoice line fund percentage or amount must be declared,
not both and not neither.
```

**Incorrect Patterns**:
```python
# ❌ Both amount and percent
{"fund_code": {"value": "FUND"}, "amount": 50.0, "percent": 100}

# ❌ Neither amount nor percent
{"fund_code": {"value": "FUND"}}

# ❌ Mixed types across multiple funds
[
    {"fund_code": {"value": "FUND_A"}, "amount": 50.0},
    {"fund_code": {"value": "FUND_B"}, "percent": 50}
]
```

**Correct Patterns**:
```python
# ✅ Single fund, percent
{"fund_code": {"value": "FUND"}, "percent": 100}

# ✅ Split percentage (must total 100)
[
    {"fund_code": {"value": "FUND_A"}, "percent": 50},
    {"fund_code": {"value": "FUND_B"}, "percent": 50}
]

# ✅ Split by amount (should total line amount)
[
    {"fund_code": {"value": "FUND_A"}, "amount": 50.00},
    {"fund_code": {"value": "FUND_B"}, "amount": 30.00}
]
```

**When to Use Each**:
- **Percent**: Most common, simple allocation (especially 100% to one fund)
- **Amount**: Complex splits, when rounding matters, specific dollar allocations

**See Also**: [Error Codes - Fund Distribution Error](../../../alma-api-expert/references/error_codes_and_solutions.md#error-400---fund-distribution-error)

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
## Item Receiving Behaviors

### Item Process Type Changes

**After Receiving Item**:
```python
# process_type is an item_data object with PROCESSTYPE codes (corrected 2026-11-12, see evaluation AQ-24)
# Before receiving
item['item_data']['process_type'] == {"value": "ACQ", ...}

# After acq.receive_item(), possibly (untested here)
item['item_data']['process_type'] == {"value": "TRANSIT", ...}
```

**Why This Happens**:
- Alma workflow moves item to next stage
- "In transit" means going to cataloging/processing
- May trigger automatic transit request if configured

**To Keep Item in Department**:
```python
# Use combined workflow
acq.receive_and_keep_in_department(
    pol_id=pol_id,
    item_id=item_id,
    mms_id=mms_id,
    holding_id=holding_id,
    library="MAIN",
    department="ACQ",
    work_order_type="AcqWorkOrder",
    work_order_status="CopyCataloging"
)
# Result: item stays in ACQ department with work order
```

**See Also**: [Acquisitions API - Item Receiving](acquisitions-api.md)
