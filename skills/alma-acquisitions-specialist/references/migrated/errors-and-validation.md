<!-- moved from alma-api-expert/references/error_codes_and_solutions.md -->
## Acquisitions Errors

### Error 402459 - Invoice Retrieval Error

**Full Error**:
```
Error 402459: Error while trying to retrieve invoice
```

**When It Occurs**:
- Attempting to mark an invoice as paid before it has been processed/approved
- Attempting to access an invoice that has been deleted

**Root Cause**:
Alma requires invoices to be processed/approved before they can be marked as paid. The API enforces this workflow sequence.

**Mandatory Workflow**:
```python
# ❌ WRONG - Will cause error 402459
invoice = acq.create_invoice_simple(...)
line = acq.create_invoice_line_simple(...)
paid = acq.mark_invoice_paid(invoice_id)  # FAILS HERE!

# ✅ CORRECT - Approve first, then pay
invoice = acq.create_invoice_simple(...)
line = acq.create_invoice_line_simple(...)
processed = acq.approve_invoice(invoice_id)  # MUST DO THIS FIRST
paid = acq.mark_invoice_paid(invoice_id)     # NOW it works
```

**API Operations**:
```
1. Create invoice: POST /almaws/v1/acq/invoices
2. Add lines: POST /almaws/v1/acq/invoices/{id}/lines
3. Process/Approve: POST /almaws/v1/acq/invoices/{id}?op=process_invoice  ← MANDATORY
4. Mark paid: POST /almaws/v1/acq/invoices/{id}?op=paid
```

**Invoice State Transitions**:
1. **Created**: `invoice_status=ACTIVE`, `approval_status=PENDING`, `payment_status=NOT_PAID`
2. **After Processing**: `approval_status=APPROVED`; workflow code depends on configuration (no `Approved` code exists) (corrected 2026-11-12, see evaluation AQ-06)
3. **After Payment**: `payment_status=PAID` (corrected 2026-11-12, see evaluation AQ-07)

**Prevention**:
- Always call `approve_invoice()` before `mark_invoice_paid()`
- Use automatic protection: `mark_invoice_paid()` includes duplicate payment checks by default
- Check invoice status before attempting payment:
  ```python
  check = acq.check_invoice_payment_status(invoice_id)
  if check['can_pay']:
      acq.mark_invoice_paid(invoice_id)
  ```

**See Also**: [Acquisitions API - Critical Workflows](acquisitions-api.md)

### Error 40166411 - Invalid Parameter

**Full Error**:
```
Error 40166411: Invalid parameter value
```

**When It Occurs**:
- Incorrect date format in receive_date, invoice_date, or other date fields
- Invalid enum value for status, type, or other code table fields
- Out-of-range numeric values

**Common Causes**:

**1. Date Format Issues**:
```python
# ❌ WRONG - Missing timezone indicator
receive_date = "2025-01-15"

# ❌ WRONG - Wrong format
receive_date = "01/15/2025"

# ✅ CORRECT - ISO 8601 with timezone
receive_date = "2025-01-15Z"
```

**2. Invalid Department Code**:
```python
# ❌ WRONG - Department doesn't exist
department = "NONEXISTENT_DEPT"

# ✅ CORRECT - Verify department exists
# Check in Configuration > Fulfillment > Physical Fulfillment > Departments
department = "ACQ"
```

**Solutions**:
- Always use ISO 8601 format with 'Z' suffix for dates: `YYYY-MM-DDZ`
- Verify code table values in Alma configuration before using
- Use `_format_invoice_date()` helper for date formatting
- Check API documentation for parameter constraints

### Error 401875 - Department Not Found

**Full Error**:
```
Error 401875: Department not found
```

**When It Occurs**:
- Receiving an item to a non-existent department
- Scanning in an item to an invalid department
- Creating work order with invalid department code

**Root Cause**:
Department code must exist in Alma configuration and be valid for the specified library.

**Verification Steps**:
1. Check Configuration > Fulfillment > Physical Fulfillment > Departments
2. Verify department is enabled and not deleted
3. Confirm department belongs to the correct library
4. Ensure department code matches exactly (case-sensitive)

**Example**:
```python
# ❌ WRONG - Department doesn't exist or wrong library
acq.receive_item(
    pol_id="POL-01001",
    item_id="20000000000000001",
    department="CATALOGING",        # Doesn't exist
    department_library="WRONG_LIB"  # Wrong library
)

# ✅ CORRECT - Valid department for library
acq.receive_item(
    pol_id="POL-01001",
    item_id="20000000000000001",
    department="ACQ",
    department_library="MAIN"
)
```

**Prevention**:
- Maintain list of valid department codes in configuration
- Validate department parameter before API call
- Use department validation helper if available

### Error 401871 - PO Line Not Found

**Full Error**:
```
Error 401871: PO Line not found
```

**When It Occurs**:
- Attempting to access a POL that doesn't exist
- POL has been closed or deleted
- POL ID is incorrect or contains typo

**Common Scenarios**:
```python
# Scenario 1: POL doesn't exist
pol_data = acq.get_pol("POL-9999999")  # Invalid ID

# Scenario 2: POL is closed
# POLs can be closed when all items received and invoices paid
pol_data = acq.get_pol("POL-01001")
status = pol_data.get('status', {}).get('value')
if status == 'CLOSED':
    # POL exists but is closed
    pass

# Scenario 3: Typo in POL ID
pol_data = acq.get_pol("PO-5989")  # Missing 'L'
```

**Solutions**:
- Verify POL ID format (usually POL-XXXXXXX)
- Check POL status before operations
- Use try/except to handle gracefully:
  ```python
  try:
      pol_data = acq.get_pol(pol_id)
  except AlmaAPIError as e:
      if e.status_code == 401871:
          logger.error(f"POL {pol_id} not found")
  ```

### Error 401877 - Failed to Receive PO Line

**Full Error**:
```
Error 401877: Failed to receive PO Line
```

**When It Occurs**:
- Item already received
- POL is in wrong state for receiving
- Item doesn't exist in POL
- POL is closed or cancelled

**Debugging Steps**:
```python
# Step 1: Get POL data and check status
pol_data = acq.get_pol(pol_id)
status = pol_data.get('status', {}).get('value')

if status in ['CLOSED', 'CANCELLED']:
    logger.error(f"POL {pol_id} is {status}, cannot receive")

# Step 2: Check if item already received
items = acq.extract_items_from_pol_data(pol_data)
for item in items:
    if item['pid'] == item_id:
        if item.get('receive_date'):
            logger.error(f"Item {item_id} already received on {item['receive_date']}")
        break

# Step 3: Verify item exists in POL
item_ids = [item['pid'] for item in items]
if item_id not in item_ids:
    logger.error(f"Item {item_id} not found in POL {pol_id}")
```

**Prevention**:
- Always check item status before attempting to receive
- Filter for unreceived items:
  ```python
  unreceived = [item for item in items if not item.get('receive_date')]
  ```
- Use idempotent workflows that check state first

### Error 400 - Fund Distribution Error

**Full Error**:
```
Error 400: Invoice line fund percentage or amount must be declared, not both and not neither.
```

**When It Occurs**:
Creating invoice lines with incorrect fund_distribution structure.

**Root Cause**:
Alma requires EITHER `amount` OR `percent` in fund distribution, never both, never neither.

**Incorrect Structures**:
```python
# ❌ WRONG - Both amount and percent
"fund_distribution": [{
    "fund_code": {"value": "AAC_FUND"},
    "amount": 50.0,
    "percent": 100  # Can't have both!
}]

# ❌ WRONG - Neither amount nor percent
"fund_distribution": [{
    "fund_code": {"value": "AAC_FUND"}
}]

# ❌ WRONG - Multiple funds with inconsistent fields
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "amount": 50.0},
    {"fund_code": {"value": "FUND_B"}, "percent": 50}  # Mixed types!
]
```

**Correct Structures**:
```python
# ✅ CORRECT - Single fund with percent
"fund_distribution": [{
    "fund_code": {"value": "AAC_FUND"},
    "percent": 100
}]

# ✅ CORRECT - Split percentage
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "percent": 50},
    {"fund_code": {"value": "FUND_B"}, "percent": 50}
]

# ✅ CORRECT - Split by amount
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "amount": 50.00},
    {"fund_code": {"value": "FUND_B"}, "amount": 30.00}
]
```

**When to Use Each**:
- **Use percent**: For percentage-based allocation (most common)
  - Single fund: 100%
  - Split funds: Percentages must total 100%
- **Use amount**: For explicit dollar amounts
  - Amounts should total line item amount
  - Useful for complex splits with rounding

**Fixed in**: `_build_invoice_line_structure()` helper method

<!-- moved from alma-api-expert/references/validation_and_required_fields.md -->
## Acquisitions Validation

### Create Invoice

**Required Fields**:
```python
{
    "number": str,              # Vendor invoice number (mandatory)
    "invoice_date": str,        # Date in YYYY-MM-DDZ format (mandatory)
    "vendor": {                 # Vendor information (mandatory)
        "value": str            # Vendor code
    },
    "total_amount": float       # Total invoice amount (mandatory)
}
```

**Validation Rules**:

1. **invoice_number**:
   - Must be non-empty string
   - Should be unique per vendor (not enforced by API but recommended)
   - Example: "INV-2025-001"

2. **invoice_date**:
   - Must be in ISO 8601 format with timezone: `YYYY-MM-DDZ`
   - Cannot be future date (typically)
   - Example: "2025-10-22Z"
   - **Error if wrong**: Error 40166411 "Invalid parameter value"

3. **vendor**:
   - Must be wrapped object with `value` key
   - Vendor code must exist in Alma configuration
   - Case-sensitive
   - Example: `{"value": "RIALTO"}`

4. **total_amount**:
   - Must be positive number
   - Can be decimal (e.g., 100.50)
   - Must match sum of line item amounts (enforced after lines added)
   - Example: 100.00

**Optional But Recommended**:
```python
{
    "currency": {               # Defaults to institution currency
        "value": "ILS"
    },
    "payment": {                # Payment information
        "prepaid": false,
        "payment_status": {"value": "NOT_PAID"}
    }
}
```

**Validation Example**:
```python
def validate_invoice_create(number, invoice_date, vendor_code, total_amount):
    """Validate invoice creation parameters."""
    errors = []

    if not number or not number.strip():
        errors.append("Invoice number is required")

    if not invoice_date:
        errors.append("Invoice date is required")
    elif not invoice_date.endswith('Z'):
        errors.append("Invoice date must end with 'Z'")

    if not vendor_code:
        errors.append("Vendor code is required")

    if total_amount is None or total_amount <= 0:
        errors.append("Total amount must be positive")

    if errors:
        raise ValueError(f"Validation failed: {'; '.join(errors)}")

    return True
```

### Create Invoice Line

**Fields** (corrected 2026-11-12, see evaluation AQ-19): the POST schema marks `po_line` optional, `price`/`quantity` default to the PO line's values, `total_price` is output-only (not in the POST schema), and `fund_distribution` is mandatory for processing the line.
```python
{
    "po_line": str,             # POL number (optional in schema; needed to link a POL)
    "quantity": int,            # Optional, defaults to the PO line quantity
    "price": float,             # Optional, defaults to the PO line price
    "fund_distribution": [      # Fund allocation (mandatory for processing)
        {
            "fund_code": {"value": str},
            "percent": int OR "amount": float  # EITHER percent OR amount!
        }
    ]
}
```

**Validation Rules**:

1. **po_line**:
   - Must be valid POL ID
   - POL must exist and be accessible
   - Example: "POL-01001"

2. **quantity**:
   - Must be positive integer
   - Typically 1 for books
   - Example: 1

3. **price** and **total_price**:
   - Must be positive numbers
   - `total_price` should equal `price * quantity`
   - Example: price=100.00, quantity=1, total_price=100.00

4. **fund_distribution** (CRITICAL):
   - Must be non-empty array
   - Each fund must have `fund_code.value`
   - Each fund must have EITHER `percent` OR `amount`, NEVER both, NEVER neither
   - If using percent: should total 100 for all funds
   - If using amount: should total `total_price` for all funds

**Fund Distribution Validation**:
```python
# ✅ VALID - Single fund, percent
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "percent": 100}
]

# ✅ VALID - Split percentage
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "percent": 60},
    {"fund_code": {"value": "FUND_B"}, "percent": 40}
]

# ✅ VALID - Split by amount
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "amount": 60.00},
    {"fund_code": {"value": "FUND_B"}, "amount": 40.00}
]

# ❌ INVALID - Both percent and amount
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "percent": 100, "amount": 100.00}
]

# ❌ INVALID - Neither percent nor amount
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}}
]

# ❌ INVALID - Mixed types
"fund_distribution": [
    {"fund_code": {"value": "FUND_A"}, "percent": 50},
    {"fund_code": {"value": "FUND_B"}, "amount": 50.00}
]
```

**Error When Invalid**:
```
Error 400: Invoice line fund percentage or amount must be declared,
not both and not neither.
```

**Validation Example**:
```python
def validate_fund_distribution(fund_distribution):
    """Validate fund distribution rules."""
    if not fund_distribution:
        raise ValueError("fund_distribution is required")

    has_percent = None
    has_amount = None

    for fund in fund_distribution:
        if 'percent' in fund and 'amount' in fund:
            raise ValueError("Fund cannot have both percent and amount")

        if 'percent' not in fund and 'amount' not in fund:
            raise ValueError("Fund must have either percent or amount")

        if has_percent is None:
            has_percent = 'percent' in fund
            has_amount = 'amount' in fund
        else:
            # Check consistency across funds
            if has_percent and 'amount' in fund:
                raise ValueError("Cannot mix percent and amount across funds")
            if has_amount and 'percent' in fund:
                raise ValueError("Cannot mix amount and percent across funds")

    return True
```

### Receive Item

**Required Fields**:
```python
{
    "pol_id": str,              # POL identifier (mandatory)
    "item_id": str              # Item PID (mandatory)
}
```

**Optional Parameters**:
```python
{
    "receive_date": str,        # Date in YYYY-MM-DDZ format
    "department": str,          # Department code
    "department_library": str   # Library code
}
```

**Validation Rules**:

1. **pol_id**:
   - Must be valid POL ID
   - POL must exist and not be CLOSED or CANCELLED
   - Example: "POL-01001"

2. **item_id**:
   - Must be valid item PID
   - Item must belong to the POL
   - Item must not already be received
   - Example: "20000000000000001"

3. **receive_date**:
   - Must be in YYYY-MM-DDZ format
   - Typically current date or past date
   - Example: "2025-10-22Z"

4. **department** and **department_library**:
   - Department must exist in configuration
   - Department must belong to specified library
   - Both required if either is specified

**Pre-Receive Validation**:
```python
def validate_item_receive(pol_id, item_id):
    """Validate item can be received."""
    # Get POL data
    pol_data = acq.get_pol(pol_id)

    # Check POL status
    status = pol_data.get('status', {}).get('value')
    if status in ['CLOSED', 'CANCELLED']:
        raise ValueError(f"Cannot receive item: POL is {status}")

    # Extract items
    items = acq.extract_items_from_pol_data(pol_data)

    # Find item
    item = next((i for i in items if i['pid'] == item_id), None)
    if not item:
        raise ValueError(f"Item {item_id} not found in POL {pol_id}")

    # Check if already received
    if item.get('receive_date'):
        raise ValueError(f"Item {item_id} already received on {item['receive_date']}")

    return True
```

**Common Errors**:
- Error 401871: POL not found
- Error 401877: Failed to receive (item already received or doesn't exist)
- Error 401875: Department not found

<!-- moved from alma-api-expert/references/validation_and_required_fields.md -->
### Built-in Validation (Acquisitions)

```python
# Invoice line creation validates fund distribution
acq.create_invoice_line_simple(...)

# Uses _build_invoice_line_structure() which ensures:
# - fund_distribution has either percent or amount
# - Never both, never neither
# - Defaults to percent: 100 for single fund
```
