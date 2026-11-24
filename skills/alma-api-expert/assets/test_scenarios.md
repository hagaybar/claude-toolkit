# Test Scenarios and Examples

This directory contains example request/response JSON files from real Alma SANDBOX testing.

## Directory Structure

```
assets/
├── test_scenarios.md (this file)
├── example_requests/     # Request bodies for copy-paste
│   ├── create_invoice.json
│   ├── create_invoice_line.json
│   ├── create_lending_request_book.json
│   ├── create_lending_request_article.json
│   └── receive_item.xml
├── example_responses/    # Real SANDBOX responses
│   ├── invoice_full.json
│   ├── pol_with_items.json
│   ├── lending_request_complete.json
│   └── invoice_lines.json
└── error_examples/       # Common error responses
    ├── error_402459_invoice_not_approved.json
    ├── error_40166411_invalid_date.json
    ├── error_400_owner_field_format.json
    └── error_400_fund_distribution.json
```

## Complete Workflows

### Workflow 1: Create and Pay Invoice

→ Moved to the `alma-acquisitions-specialist` skill (test-scenarios.md).

### Workflow 2: Receive Item and Keep in Department

→ Moved to the `alma-acquisitions-specialist` skill (test-scenarios.md).

### Workflow 3: Create Lending Request

→ Moved to the `alma-resource-sharing` skill (references/test-scenarios.md).

## Example Files Documentation

### Request Examples

#### create_invoice.json
- Creates new invoice for RIALTO vendor
- Total amount: 100.00 ILS
- Invoice date: 2025-10-22
- Uses for: Basic invoice creation testing

#### create_invoice_line.json
- Links to POL-01001
- Amount: 100.00 ILS
- Fund allocation: 100% to AAC_FUND
- Demonstrates: Correct fund_distribution format

#### create_lending_request_book.json
- Book request from RELAIS partner
- Demonstrates: All mandatory fields, correct field formats
- Shows: Owner as plain string (not wrapped)

#### create_lending_request_article.json
- Journal article request
- Includes: Volume, issue, pages, DOI
- Demonstrates: Journal-specific metadata

#### receive_item.xml
- XML format for item receiving
- Empty body (Alma fills in defaults)
- Required for: Item receiving operations

### Response Examples

#### invoice_full.json
- Complete invoice object after creation
- Shows: Nested payment_status location
- Demonstrates: All invoice fields

#### pol_with_items.json
- POL with unreceived items
- Shows: location→copy structure for items
- Demonstrates: How to find unreceived items

#### lending_request_complete.json
- Real SANDBOX lending request (ID: 10000000000000016)
- Status: SHIPPED_PHYSICALLY
- Shows: All undocumented fields (barcode, timestamps, etc.)
- Demonstrates: Complete real-world object

#### invoice_lines.json
- Array of invoice lines
- Shows: po_line field linking to POL
- Demonstrates: Fund distribution in lines

### Error Examples

#### error_402459_invoice_not_approved.json
- Error: Invoice retrieval failed
- Cause: Attempted to pay before approving
- Solution: Call approve_invoice() first

#### error_40166411_invalid_date.json
- Error: Invalid parameter value
- Cause: Date format missing 'Z' suffix
- Solution: Use YYYY-MM-DDZ format

#### error_400_owner_field_format.json
- Error: Cannot deserialize string from Object
- Cause: Used wrapped format for owner field
- Solution: Use plain string "MAIN" not {"value": "MAIN"}

#### error_400_fund_distribution.json
- Error: Fund percentage or amount must be declared
- Cause: Used both percent and amount in fund_distribution
- Solution: Use EITHER percent OR amount, not both

## Testing Tips

### Using Examples in Tests

```python
import json

# Load example request
with open('example_requests/create_invoice.json') as f:
    invoice_data = json.load(f)

# Modify for your test
invoice_data['number'] = f"TEST-{datetime.now().strftime('%Y%m%d-%H%M%S')}"

# Create invoice
response = client.post("almaws/v1/acq/invoices", json=invoice_data)
```

### Validating Against Examples

```python
# Load expected response structure
with open('example_responses/invoice_full.json') as f:
    expected_structure = json.load(f)

# Verify your response has same structure
def validate_structure(actual, expected):
    """Check actual response has same keys as expected."""
    for key in expected.keys():
        if key not in actual:
            print(f"Missing key: {key}")

validate_structure(actual_invoice, expected_structure)
```

### Error Reproduction

```python
# Test error handling
with open('error_examples/error_402459_invoice_not_approved.json') as f:
    expected_error = json.load(f)

try:
    # This should fail
    acq.mark_invoice_paid(invoice_id)  # Without approving first
except AlmaAPIError as e:
    # Verify error matches expected
    assert e.status_code == 402459
```

## Real SANDBOX Data

All examples are based on real SANDBOX testing:

**Invoices**:
- Invoice ID: 10000000000000004
- Invoice Number: TEST-INV-20251022_153408-8
- POL: POL-01001
- Status: Successfully created, approved, and paid

**Lending Requests**:
- Request ID: 10000000000000016
- External ID: "test primo 200825"
- Partner: ANC (ANCA-TEST)
- Status: SHIPPED_PHYSICALLY
- Barcode: 2239409-10

**POLs**:
- POL-01001: One-time POL with RIALTO vendor
- Price: 180.00 ILS
- Status: ACTIVE → CLOSED after receiving and invoicing

## Creating Your Own Examples

### Capture Request
```python
import json

# Before making request
request_data = {
    "number": "INV-001",
    "invoice_date": "2025-10-22Z",
    # ...
}

# Save for reference
with open('my_request.json', 'w') as f:
    json.dump(request_data, f, indent=2)
```

### Capture Response
```python
# After successful request
response = client.post(endpoint, json=request_data)
response_data = response.json()

# Save for reference
with open('my_response.json', 'w') as f:
    json.dump(response_data, f, indent=2)
```

### Capture Error
```python
try:
    response = client.post(endpoint, json=bad_data)
except AlmaAPIError as e:
    error_data = {
        "status_code": e.status_code,
        "error_message": str(e),
        "response_body": e.response_data if hasattr(e, 'response_data') else None
    }

    with open('error_example.json', 'w') as f:
        json.dump(error_data, f, indent=2)
```

## See Also

- Acquisitions API (`alma-acquisitions-specialist` skill) - Complete workflows
- Resource Sharing API (`alma-resource-sharing` skill) - Request patterns
- [Error Codes](../references/error_codes_and_solutions.md) - Error reference
- [Data Structures](../references/data_structures.md) - Object field details
