<!-- moved from alma-api-expert/assets/test_scenarios.md -->
### Workflow 1: Create and Pay Invoice

**Scenario**: Create invoice, add line, approve, and mark as paid

**Steps**:
1. Create invoice
   - Request: `example_requests/create_invoice.json`
   - Response: `example_responses/invoice_created.json`

2. Add invoice line
   - Request: `example_requests/create_invoice_line.json`
   - Response: `example_responses/invoice_line_created.json`

3. Approve invoice
   - Endpoint: `POST /almaws/v1/acq/invoices/{invoice_id}?op=process_invoice`
   - Body: `{}`
   - Response: `example_responses/invoice_approved.json`

4. Mark as paid
   - Endpoint: `POST /almaws/v1/acq/invoices/{invoice_id}?op=paid`
   - Body: `{}`
   - Response: `example_responses/invoice_paid.json`

**Code Example**:
```python
# Complete workflow
invoice = acq.create_invoice_simple(
    invoice_number="INV-2025-001",
    invoice_date="2025-10-22",
    vendor_code="RIALTO",
    total_amount=100.00
)

line = acq.create_invoice_line_simple(
    invoice_id=invoice['id'],
    pol_id="POL-01001",
    amount=100.00
)

acq.approve_invoice(invoice['id'])
acq.mark_invoice_paid(invoice['id'])
```

<!-- moved from alma-api-expert/assets/test_scenarios.md -->
### Workflow 2: Receive Item and Keep in Department

**Scenario**: Receive POL item and keep in acquisitions department

**Steps**:
1. Get POL data
   - Response: `example_responses/pol_with_items.json`

2. Receive item
   - Request: `example_requests/receive_item.xml`
   - Endpoint: `POST /almaws/v1/acq/po-lines/{pol_id}/items/{item_id}?op=receive`

3. Scan in item
   - Endpoint: `POST /almaws/v1/bibs/{mms_id}/holdings/{holding_id}/items/{item_pid}?op=scan&library=MAIN&department=ACQ&work_order_type=AcqWorkOrder&status=CopyCataloging&done=false` (`department`, not `circ_desk`: `done` applies only with department, and AlmaAPITK sends department) (corrected 2026-11-12, see evaluation AQ-38)
   - Body: (empty)

**Code Example**:
```python
# Receive and keep in department
result = acq.receive_and_keep_in_department(
    pol_id="POL-01001",
    item_id="20000000000000001",
    mms_id="990000000000000002",
    holding_id="20000000000000003",
    library="MAIN",
    department="ACQ",
    work_order_type="AcqWorkOrder",
    work_order_status="CopyCataloging"
)
```
