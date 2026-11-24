<!-- moved from alma-api-expert/assets/test_scenarios.md -->
### Workflow 3: Create Lending Request

**Scenario**: Create resource sharing lending request from partner

**Steps**:
1. Create lending request
   - Request: `example_requests/create_lending_request_book.json`
   - Response: `example_responses/lending_request_created.json` (corrected 2026-11-12: `lending_request_complete.json` does not exist)

2. Retrieve request
   - Endpoint: `GET /almaws/v1/partners/{partner_code}/lending-requests/{request_id}`
   - Response: `example_responses/lending_request_created.json`

**Code Example**:
```python
# Create lending request
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id="ILL-12345",
    owner="MAIN",
    format_type="PHYSICAL",
    title="Introduction to Library Science",
    citation_type="BOOK",
    author="Smith, John A.",
    isbn="978-0-123456-78-9"
)
```
