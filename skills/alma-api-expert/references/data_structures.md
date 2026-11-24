# Data Structures Reference

This reference documents the structure of key Alma API objects with field-by-field descriptions.

## Quick Structure Navigation

| Object | Critical Fields | Nested Complexity | Quirks |
|--------|----------------|-------------------|---------|
| Invoice | `payment.payment_status.value` | HIGH | Payment status is nested |
| POL | `location[0].copy[]` | HIGH | Items in nested array |
| Item | `pid`, `receive_date` | LOW | Simple structure |
| Lending Request | `owner`, `partner.value` | MEDIUM | Owner field format quirk |
| Invoice Line | `po_line`, `fund_distribution` | MEDIUM | Fund rules (amount OR percent) |

## Invoice Structure

→ Moved to the `alma-acquisitions-specialist` skill (data-structures.md).

## Invoice Line Structure

→ Moved to the `alma-acquisitions-specialist` skill (data-structures.md).

## POL (Purchase Order Line) Structure

→ Moved to the `alma-acquisitions-specialist` skill (data-structures.md).

## Lending Request Structure

→ Moved to the `alma-resource-sharing` skill (references/data-structures.md).

## Invoice-POL Linkage

→ Moved to the `alma-acquisitions-specialist` skill (data-structures.md).

## Common Data Extraction Patterns

### Safe Field Extraction

```python
# Use get() with defaults
title = request.get('title', 'Unknown Title')

# Nested field extraction
payment_status = invoice.get('payment', {}).get('payment_status', {}).get('value', 'UNKNOWN')

# Array with default
items = pol_data.get('location', [{}])[0].get('copy', [])
```

### Field Type Conversion

```python
# String to float (POL price)
price_str = pol_data['price']['sum']  # "180.0"
price_float = float(price_str)         # 180.0

# String to date
from datetime import datetime
date_str = "2025-10-22Z"
date_obj = datetime.fromisoformat(date_str.replace('Z', ''))
```

### Checking Field Presence

```python
# Check if item received
if item.get('receive_date'):
    print(f"Received on {item['receive_date']}")
else:
    print("Not yet received")

# Check if field exists vs empty
if 'barcode' in request and request['barcode']:
    print(f"Barcode: {request['barcode']}")
```

## Helper Methods for Structure Navigation

### Acquisitions Helpers

→ Moved to the `alma-acquisitions-specialist` skill (data-structures.md).

### Resource Sharing Helpers

→ Moved to the `alma-resource-sharing` skill (references/data-structures.md).

## See Also

- [API Quirks - Field Format Issues](api_quirks_and_gotchas.md)
- Acquisitions API - Data Structures (`alma-acquisitions-specialist` skill)
- Resource Sharing API - Data Structures (`alma-resource-sharing` skill)
- [Error Codes - Structure-Related Errors](error_codes_and_solutions.md)
