<!-- moved from alma-api-expert/references/data_structures.md -->
## Invoice Structure

### Overview

Invoices represent vendor bills for purchased materials. They contain header information and line items.

### Top-Level Structure

```python
{
    "id": "10000000000000004",            # Invoice ID (output only)
    "number": "INV-2025-001",              # Vendor invoice number
    "invoice_date": "2025-10-22Z",         # Invoice date
    "vendor": {                             # Vendor information
        "value": "RIALTO",
        "desc": "Rialto Vendor"
    },
    "total_amount": 100.00,                # Total invoice amount (decimal)
    "currency": {                           # Currency information
        "value": "ILS",
        "desc": "New Israeli Sheqel"
    },
    "invoice_status": {                     # Invoice processing status
        "value": "ACTIVE",                  # ACTIVE, CLOSED, etc.
        "desc": "Active"
    },
    "payment": {                            # ⚠️ Payment info is NESTED here!
        "prepaid": false,
        "internal_copy": false,
        "payment_status": {                 # ← Payment status location
            "value": "NOT_PAID",            # NOT_PAID or PAID (corrected 2026-11-12, see evaluation AQ-07)
            "desc": "Not Paid"
        },
        "voucher_number": "",
        "voucher_amount": ""
    },
    "invoice_vat": {                        # VAT/Tax information
        "report_tax": false,
        "vat_code": {"value": "", "desc": ""},
        "percentage": 0,
        "type": {"value": "", "desc": ""}
    },
    "additional_charges": {                 # Additional costs
        "shipment": 0,
        "overhead": 0,
        "insurance": 0,
        "discount": 0
    },
    "invoice_lines": {"invoice_line": [], "total_record_count": 0},  # (corrected 2026-11-12, see evaluation AQ-11)
    "creation_date": "2025-10-22Z",        # When created in Alma
    "owner": {                              # Invoice owner
        "value": "MAIN",
        "desc": "Main Library"
    }
}
```

### Critical Field Details

#### payment_status (Nested!)

**⚠️ CRITICAL**: Payment status is NOT at root level!

**Location**: `invoice.payment.payment_status.value`

**Values** (corrected 2026-11-12, see evaluation AQ-07): the Sandbox PaymentStatus code table has only
- `NOT_PAID` - not yet paid
- `PAID` - paid

FULLY_PAID / PARTIALLY_PAID were not found; check for them defensively, do not expect them.

**Access Pattern**:
```python
# ❌ WRONG
payment_status = invoice['payment_status']  # KeyError!

# ✅ CORRECT
payment_status = invoice['payment']['payment_status']['value']

# ✅ BETTER - Use helper
check = acq.check_invoice_payment_status(invoice_id)
is_paid = check['is_paid']
status = check['payment_status']
```

#### invoice_status

**Location**: `invoice.invoice_status.value`

**Values** (corrected 2026-11-12, see evaluation AQ-08): base status is only
- `ACTIVE` - open
- `CLOSED` - finalized

Workflow stage is `invoice_workflow_status` (InReview, InApproval, `Waiting to be Sent`, `Ready to be Paid`; may be `{}` once closed). Approval is `invoice_approval_status` (PENDING, APPROVED, NOT_REQUIRED, REJECTED).

**Note**: This is different from `payment_status`. An invoice can be `ACTIVE` and `PAID`.

#### total_amount

**Type**: Decimal/float (NOT a nested object)

**Format**:
```python
# ✅ CORRECT - Simple numeric value
"total_amount": 100.00

# ❌ WRONG - Not a nested object
"total_amount": {"sum": 100.00, "currency": {...}}  # Wrong!
```

**Note**: Currency is separate field at `invoice.currency.value`

#### invoice_lines (corrected 2026-11-12, see evaluation AQ-11)

**Type**: Object `{invoice_line: [...], total_record_count}`; omitted with `view=brief`

**Access**:
```python
# Get lines from dedicated endpoint (recommended, paginated)
lines = acq.get_invoice_lines(invoice_id)

# Or from the embedded container
lines = invoice.get('invoice_lines', {}).get('invoice_line', [])
```

**See**: [Invoice Line Structure](#invoice-line-structure) below

### State Transitions

```
CREATE
  ↓ invoice_status=ACTIVE, approval_status=PENDING, payment_status=NOT_PAID
APPROVE (op=process_invoice)
  ↓ approval_status=APPROVED, workflow code per configuration (no 'Approved' code) (corrected 2026-11-12, see evaluation AQ-06)
PAY (op=paid)
  ↓ payment_status=PAID (corrected 2026-11-12, see evaluation AQ-07)
CLOSE
  ↓ invoice_status=CLOSED
```

### Common Patterns

#### Checking Payment Status
```python
# Pattern 1: Direct access
invoice = acq.get_invoice(invoice_id)
payment_status = invoice['payment']['payment_status']['value']

if payment_status in ['PAID', 'FULLY_PAID']:
    print("Invoice is paid")

# Pattern 2: Using helper (recommended)
check = acq.check_invoice_payment_status(invoice_id)
if check['is_paid']:
    print(f"Already paid: {check['payment_status']}")
```

#### Getting Invoice Summary
```python
summary = acq.get_invoice_summary(invoice_id)
# Returns (corrected 2026-11-12, see evaluation AQ-37):
# {
#     'invoice_id': '...', 'invoice_number': '...',
#     'vendor_code': '...', 'vendor_name': '...', 'invoice_date': '...',
#     'total_amount': '100.0',   # string
#     'currency': 'Unknown',     # when total_amount is a plain number
#     'status': 'ACTIVE',        # base status
#     'payment_status': 'NOT_PAID'
# }
```

<!-- moved from alma-api-expert/references/data_structures.md -->
## Invoice Line Structure

### Overview

Invoice lines link invoices to POLs and specify fund distribution.

### Structure

```python
{
    "id": "12345678",                      # Line ID (output only)
    "number": "1",                          # Line number within invoice
    "po_line": "POL-01001",                 # ⚠️ Link to POL (authoritative!)
    "quantity": 1,                          # Quantity
    "price": 100.00,                        # Unit price
    "total_price": 100.00,                  # Total line price
    "currency": {
        "value": "ILS",
        "desc": "New Israeli Sheqel"
    },
    "fund_distribution": [                  # ⚠️ Fund allocation
        {
            "fund_code": {"value": "AAC_FUND", "desc": "Acquisitions Fund"},
            "percent": 100                  # ⚠️ Use EITHER percent OR amount!
        }
    ],
    "note": "",                             # Line notes
    "subscription_from_date": "",           # For subscriptions
    "subscription_to_date": "",
    "vat": {                                # VAT information
        "vat_code": {"value": "", "desc": ""},
        "percentage": 0
    }
}
```

### Critical Field Details

#### po_line

**Type**: String (POL ID)

**Purpose**: Links invoice line to Purchase Order Line

**⚠️ Critical**: This is the AUTHORITATIVE link between invoices and POLs!

**Usage**:
```python
# Finding which POL a line references
lines = acq.get_invoice_lines(invoice_id)
for line in lines:
    pol_id = line.get('po_line')  # e.g., "POL-01001"
    print(f"Line references {pol_id}")

# Finding invoices for a POL
query = f"pol_number~{pol_id}"
invoices = client.get("almaws/v1/acq/invoices", params={"q": query})
```

#### fund_distribution

**Type**: Array of fund allocation objects

**⚠️ CRITICAL RULE**: Each fund must have EITHER `amount` OR `percent`, never both!

**Correct Patterns**:
```python
# ✅ Single fund, 100% allocation
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "percent": 100}
]

# ✅ Split percentage (must total 100)
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "percent": 60},
    {"fund_code": {"value": "FUND_B"}, "percent": 40}
]

# ✅ Split by amount (should total line total_price)
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "amount": 60.00},
    {"fund_code": {"value": "FUND_B"}, "amount": 40.00}
]
```

**Incorrect Patterns**:
```python
# ❌ Both amount and percent
{"fund_code": {"value": "FUND"}, "amount": 100.0, "percent": 100}

# ❌ Neither amount nor percent
{"fund_code": {"value": "FUND"}}

# ❌ Mixed types
[
    {"fund_code": {"value": "FUND_A"}, "amount": 50.0},
    {"fund_code": {"value": "FUND_B"}, "percent": 50}
]
```

**Error When Wrong**:
```
Error 400: Invoice line fund percentage or amount must be declared,
not both and not neither.
```

<!-- moved from alma-api-expert/references/data_structures.md -->
## POL (Purchase Order Line) Structure

### Overview

POLs represent individual items or subscriptions being acquired. They contain pricing, vendor information, and nested item details.

### Top-Level Structure

```python
{
    "number": "POL-01001",                  # POL identifier
    "type": {                               # POL type: PurchaseType code (corrected 2026-11-12, see evaluation AQ-31)
        "value": "PRINTED_BOOK_OT",         # e.g. PRINTED_BOOK_OT, E_BOOK_OT, PRINT_SO
        "desc": "One Time"
    },
    "status": {                             # POL status: POLineStatus code (corrected 2026-11-12, see evaluation AQ-31)
        "value": "SENT",                    # e.g. SENT, WAITING_FOR_INVOICE, CLOSED, CANCELLED
        "desc": "Active"
    },
    "vendor": {                             # Vendor information
        "value": "RIALTO",
        "desc": "Rialto Vendor"
    },
    "price": {                              # Pricing information
        "sum": "180.0",                     # List price
        "currency": {"value": "ILS", "desc": "New Israeli Sheqel"}
    },
    "resource_metadata": {                  # Bibliographic information
        "mms_id": {"value": "990000000000000002"},
        "title": "Example Book Title",
        "author": "Smith, John"
    },
    "fund_distribution": [                  # Fund allocation
        {
            "fund_code": {"value": "AAC_FUND", "desc": "Acquisitions Fund"},
            "amount": {"sum": "180.0", "currency": {"value": "ILS"}}  # observed; no percent (corrected 2026-11-12, see evaluation AQ-30)
        }
    ],
    "location": [                           # ⚠️ Location/item information (NESTED!)
        {
            "library": {"value": "MAIN", "desc": "Main Library"},
            "shelving_location": {"value": "STACKS", "desc": "Stacks"},
            "holding": [{"id": "20000000000000003", "link": "..."}],  # not holding_id (corrected 2026-11-12, see evaluation AQ-27)
            "copy": [                       # ⚠️ Items are HERE!
                {
                    "pid": "20000000000000001",    # Item ID
                    "barcode": "2239409-10",
                    "receive_date": "2025-10-22Z",  # null if unreceived
                    # receiving_operator / process_type are NOT in POL copies; see Items API item_data (corrected 2026-11-12, see evaluation AQ-28)
                }
            ]
        }
    ],
    "invoice_reference": ""                 # vendor invoice NUMBER when set, never the Alma invoice ID (corrected 2026-11-12, see evaluation AQ-32)
}
```

### Critical Field Details

#### location → copy (Items Array)

**⚠️ CRITICAL**: Items are NOT at root level!

**Path**: `pol.location[0].copy[]`

**Structure**:
```
POL
  └── location (array, usually 1 element)
        └── [0] (location object)
              ├── library
              ├── holding (array of {id, link}) (corrected 2026-11-12, see evaluation AQ-27)
              └── copy (array)  ← This is the items array!
                    └── [0..n] (item objects)
```

**Access Pattern**:
```python
# ❌ WRONG
items = pol_data['items']  # Doesn't exist!

# ❌ WRONG
items = pol_data['copy']  # Not at root level!

# ✅ CORRECT - Direct navigation
items = pol_data.get('location', [{}])[0].get('copy', [])

# ✅ BETTER - Use helper
items = acq.extract_items_from_pol_data(pol_data)
```

**Why This Structure**:
- POLs can have multiple locations (rare)
- Each location can have multiple copies/items
- Most POLs: 1 location with N items
- Structure supports multi-location scenario

#### Item Object Fields

**Key Fields**:
- `pid`: Item ID (use this, not "item_id")
- `barcode`: Physical item barcode
- `receive_date`: When received (null/missing if unreceived)
- `holding_id`, `item_policy`, `expected_arrival_date`, `link`
- `receiving_operator` / `process_type` are not in POL copies; GET the item (`link`) for `item_data` (corrected 2026-11-12, see evaluation AQ-28)

**Finding Unreceived Items**:
```python
items = acq.extract_items_from_pol_data(pol_data)
unreceived = [item for item in items if not item.get('receive_date')]

if unreceived:
    item = unreceived[0]
    item_id = item['pid']
    acq.receive_item(pol_id, item_id)
```

#### invoice_reference

**⚠️ WARNING**: This field is often EMPTY even when invoice exists!

**Do NOT rely on this** to find invoices for a POL.

**Authoritative Link**: Invoice lines' `po_line` field (see [Invoice-POL Linkage](#invoice-pol-linkage))

#### price

**Structure**:
```python
"price": {
    "sum": "180.0",      # String or float
    "currency": {"value": "ILS", "desc": "..."}
}
```

**Extraction**:
```python
# Get POL price
price = acq.get_price_from_pol(pol_id)
# Returns: 180.0 (float)

# Manual extraction
price = float(pol_data['price']['sum'])
```

#### fund_distribution

**Structure**: Array of fund allocations (similar to invoice lines)

```python
"fund_distribution": [
    {
        "fund_code": {"value": "AAC_FUND", "desc": "Acquisitions Fund"},
        "amount": {"sum": "180.0", "currency": {"value": "ILS"}}  # observed shape (corrected 2026-11-12, see evaluation AQ-30)
    }
]
```

**Extraction**:
```python
# Get primary fund code
fund_code = acq.get_fund_from_pol(pol_id)
# Returns: "AAC_FUND"

# Manual extraction
funds = pol_data.get('fund_distribution', [])
if funds:
    fund_code = funds[0]['fund_code']['value']
```

### POL Status Values

**Status values** (corrected 2026-11-12, see evaluation AQ-31): POLineStatus codes, e.g. `INREVIEW`, `READY`, `SENT`, `WAITING_FOR_INVOICE`, `DEFERRED`, `CLOSED`, `CANCELLED`. There is no `ACTIVE` code.

**Checking Status**:
```python
pol_data = acq.get_pol(pol_id)
status = pol_data.get('status', {}).get('value')

if status == 'CLOSED':
    print("POL is closed, cannot receive items")
elif status == 'ACTIVE':
    print("POL is active")
```

### POL Type Values

**Types** (corrected 2026-11-12, see evaluation AQ-31): PurchaseType codes, e.g. `PRINTED_BOOK_OT` (one-time print book), `E_BOOK_OT`, `PRINT_SO` (standing order), `PRINTED_JOURNAL_CO` (continuous). Acquisition method (PURCHASE, APPROVAL, ...) is the separate `acquisition_method` field.

<!-- moved from alma-api-expert/references/data_structures.md -->
## Invoice-POL Linkage

### Relationship Overview

**Hierarchical Structure**:
```
Purchase Order (PO)
  └── Purchase Order Lines (POLs)
        ├── POL-01001
        ├── POL-01002
        └── ...

Invoice
  └── Invoice Lines
        ├── Line 1 (po_line: "POL-01001")
        ├── Line 2 (po_line: "POL-01002")
        └── ...
```

### The Authoritative Link

**⚠️ CRITICAL**: The link is in INVOICE LINES, not POL!

**Invoice Line → POL**:
```python
invoice_lines = acq.get_invoice_lines(invoice_id)
for line in invoice_lines:
    pol_id = line.get('po_line')  # e.g., "POL-01001"
    # This is the authoritative link!
```

**POL → Invoice** (unreliable):
```python
pol_data = acq.get_pol("POL-01001")
invoice_ref = pol_data.get('invoice_reference')  # Often None or empty!
```

### Finding Invoices for POL

**Correct Method** - Query invoices:
```python
# Use direct POL search
check = acq.check_pol_invoiced(pol_id)
if check['is_invoiced']:
    for inv in check['invoices']:
        print(f"Invoice: {inv['invoice_number']}")
        print(f"Status: {inv['payment_status']}")
```

**Behind the Scenes**:
```python
# Query uses pol_number parameter
query = f"pol_number~{pol_id}"
response = client.get("almaws/v1/acq/invoices", params={"q": query})
```

### Multiple Relationships

**One Invoice → Multiple POLs**:
```python
invoice_lines = acq.get_invoice_lines(invoice_id)
pol_ids = [line.get('po_line') for line in invoice_lines]
# Returns: ["POL-01001", "POL-01002", "POL-01003"]
```

**One POL → Multiple Invoices** (rare but possible):
```python
check = acq.check_pol_invoiced("POL-01001")
print(f"Found {check['invoice_count']} invoices")
# Can be >1 if POL partially invoiced, then invoiced again
```

<!-- moved from alma-api-expert/references/data_structures.md -->
### Acquisitions Helpers

```python
# Extract items from POL
items = acq.extract_items_from_pol_data(pol_data)

# Get vendor from POL
vendor_code = acq.get_vendor_from_pol(pol_id)

# Get fund from POL
fund_code = acq.get_fund_from_pol(pol_id)

# Get price from POL
price = acq.get_price_from_pol(pol_id)

# Check invoice payment status
check = acq.check_invoice_payment_status(invoice_id)

# Get invoice summary
summary = acq.get_invoice_summary(invoice_id)
```
