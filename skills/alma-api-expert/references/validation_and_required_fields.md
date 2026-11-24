# Validation and Required Fields Reference

This reference documents required fields and validation rules for all Alma API operations.

## Quick Validation Lookup

| Operation | Required Fields | Common Validation Errors |
|-----------|----------------|--------------------------|
| Create Invoice | `number`, `invoice_date`, `vendor`, `total_amount` | Invalid date format, negative amount |
| Create Invoice Line | `invoice_id`, `po_line`, `price`, `fund_distribution` | Fund percent/amount rule violation |
| Create Lending Request | `external_id`, `owner`, `partner`, `format`, `citation_type` OR `mms_id`, `title` OR `mms_id` | Owner field format, missing external_id |
| Receive Item | `pol_id`, `item_id` | Item already received, POL closed |
| Scan In Item | `mms_id`, `holding_id`, `item_pid`, `library`, `circ_desk` | Invalid department, item not found |

## Acquisitions Validation

→ Moved to the `alma-acquisitions-specialist` skill (errors-and-validation.md).

## Resource Sharing Validation

→ Moved to the `alma-resource-sharing` skill (references/quirks-errors-validation.md).

## General Validation Patterns

### Date Format Validation

**Required Format**: ISO 8601 with timezone

```python
import re
from datetime import datetime

def validate_alma_date(date_str):
    """Validate Alma API date format."""
    if not date_str:
        raise ValueError("Date is required")

    # Check format
    if not re.match(r'^\d{4}-\d{2}-\d{2}Z$', date_str):
        raise ValueError("Date must be in YYYY-MM-DDZ format")

    # Validate date is valid
    try:
        datetime.strptime(date_str.replace('Z', ''), '%Y-%m-%d')
    except ValueError:
        raise ValueError("Invalid date value")

    return True

# Examples
validate_alma_date("2025-10-22Z")      # ✅ Valid
validate_alma_date("2025-10-22")       # ❌ Missing Z
validate_alma_date("10/22/2025")       # ❌ Wrong format
validate_alma_date("2025-13-01Z")      # ❌ Invalid month
```

### Code Table Value Validation

**Pattern for Wrapped Values**:
```python
def validate_code_table_value(value, field_name, allowed_values=None):
    """Validate code table field format and value."""
    # Check structure
    if not isinstance(value, dict):
        raise ValueError(f"{field_name} must be object with 'value' key")

    if 'value' not in value:
        raise ValueError(f"{field_name} must have 'value' key")

    if not value['value']:
        raise ValueError(f"{field_name}.value must be non-empty")

    # Check allowed values if provided
    if allowed_values and value['value'] not in allowed_values:
        raise ValueError(
            f"{field_name} must be one of {allowed_values}, "
            f"got: {value['value']}"
        )

    return True

# Examples
validate_code_table_value(
    {"value": "PHYSICAL"},
    "format",
    allowed_values=["PHYSICAL", "DIGITAL"]
)  # ✅ Valid

validate_code_table_value(
    "PHYSICAL",
    "format"
)  # ❌ Not wrapped

validate_code_table_value(
    {"value": "INVALID"},
    "format",
    allowed_values=["PHYSICAL", "DIGITAL"]
)  # ❌ Invalid value
```

### Required Field Validation

**Generic Pattern**:
```python
def validate_required_fields(data, required_fields):
    """Validate all required fields are present and non-empty."""
    missing = []

    for field in required_fields:
        value = data.get(field)

        if value is None:
            missing.append(field)
        elif isinstance(value, str) and not value.strip():
            missing.append(f"{field} (empty)")
        elif isinstance(value, dict) and not value:
            missing.append(f"{field} (empty dict)")
        elif isinstance(value, list) and not value:
            missing.append(f"{field} (empty array)")

    if missing:
        raise ValueError(f"Missing required fields: {', '.join(missing)}")

    return True

# Example
validate_required_fields(
    {
        "number": "INV-001",
        "invoice_date": "2025-10-22Z",
        "vendor": {"value": "RIALTO"},
        "total_amount": 100.00
    },
    required_fields=["number", "invoice_date", "vendor", "total_amount"]
)  # ✅ Valid
```

### Numeric Value Validation

**Pattern for Amounts**:
```python
def validate_amount(value, field_name, min_value=0, allow_zero=False):
    """Validate numeric amount field."""
    if value is None:
        raise ValueError(f"{field_name} is required")

    if not isinstance(value, (int, float)):
        raise ValueError(f"{field_name} must be numeric")

    if not allow_zero and value == 0:
        raise ValueError(f"{field_name} must be non-zero")

    if value < min_value:
        raise ValueError(f"{field_name} must be >= {min_value}")

    return True

# Examples
validate_amount(100.00, "total_amount")           # ✅ Valid
validate_amount(0, "total_amount")                # ❌ Zero not allowed
validate_amount(-50, "total_amount")              # ❌ Negative
validate_amount("100", "total_amount")            # ❌ Not numeric
```

## Pre-Operation Validation Patterns

### Check Before Create

**Pattern**: Always check for existing resources before creating duplicates

```python
# Check for existing invoices before creating
def create_invoice_safe(pol_id, **invoice_params):
    """Create invoice with duplicate check."""
    # Pre-validation: Check for duplicates
    check = acq.check_pol_invoiced(pol_id)
    if check['is_invoiced']:
        raise ValueError(
            f"POL {pol_id} already has {check['invoice_count']} invoice(s). "
            f"Review existing invoices before creating new one."
        )

    # Proceed with creation
    return acq.create_invoice_simple(**invoice_params)
```

### Check State Before Operation

**Pattern**: Verify resource is in correct state for operation

```python
def mark_invoice_paid_safe(invoice_id):
    """Mark invoice as paid with state check."""
    # Pre-validation: Check current state
    check = acq.check_invoice_payment_status(invoice_id)

    if check['is_paid']:
        raise ValueError(f"Invoice already paid: {check['payment_status']}")

    if not check['can_pay']:
        warnings = '; '.join(check['warnings'])
        raise ValueError(f"Cannot pay invoice: {warnings}")

    # Proceed with operation
    return acq.mark_invoice_paid(invoice_id)
```

## Validation Helper Methods

### Built-in Validation (ResourceSharing)

→ Moved to the `alma-resource-sharing` skill (references/quirks-errors-validation.md).

### Built-in Validation (Acquisitions)

→ Moved to the `alma-acquisitions-specialist` skill (errors-and-validation.md).

## Validation Error Messages

**Clear Error Messages**:
```python
# ✅ GOOD - Specific and actionable
raise ValueError(
    "Validation failed: external_id is required and must be non-empty. "
    "Provide unique identifier from external ILL system."
)

# ✅ GOOD - Lists all issues
raise ValueError(
    "Validation failed: "
    "1) owner must be plain string, not wrapped object; "
    "2) external_id is required; "
    "3) title is required when mms_id not provided"
)

# ❌ BAD - Vague
raise ValueError("Invalid parameters")

# ❌ BAD - No context
raise ValueError("Validation failed")
```

## See Also

- [Error Codes - Validation Errors](error_codes_and_solutions.md)
- [API Quirks - Field Format Rules](api_quirks_and_gotchas.md)
- [Data Structures - Field Requirements](data_structures.md)
- Acquisitions API - Validation Rules (`alma-acquisitions-specialist` skill)
- Resource Sharing API - Validation Rules (`alma-resource-sharing` skill)
