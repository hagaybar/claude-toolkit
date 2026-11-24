<!-- moved from alma-api-expert/SKILL.md -->
### Invoice Creation & Payment (Acquisitions)

**⚠️ MANDATORY sequence to avoid errors:**

1. Check for duplicates: `check_pol_invoiced(pol_id)`
2. Create invoice: `create_invoice_simple(...)`
3. Add lines: `create_invoice_line_simple(...)`
4. **MUST approve first**: `approve_invoice(invoice_id)`
5. Mark as paid: `mark_invoice_paid(invoice_id)`

**Common Error**: Error 402459 = Invoice not approved yet

→ See [Acquisitions API](acquisitions-api.md)

<!-- moved from alma-api-expert/SKILL.md -->
### Receiving POL Items

> **Stop before receiving through the API.** Receiving can change an item's process type and may conflict with an item that is on loan or on the shelf. Untested and deferred (user rule, 15 Nov 2026): see *Receiving through the API* in SKILL.md. Never receive as a side step of another flow; ask the user first.


**Standard workflow** (item goes to "in transit"):
```python
acq.receive_item(pol_id, item_id)
```

**Keep in department** (prevents transit):
```python
acq.receive_and_keep_in_department(
    pol_id, item_id, mms_id, holding_id,
    library, department, work_order_type, work_order_status
)
```

→ See [Acquisitions API](acquisitions-api.md)

<!-- moved from alma-api-expert/SKILL.md -->
### Searching Invoices by POL

```python
# ✅ CORRECT - Tilde format
query = f"pol_number~{pol_id}"

# ✅ Also works - Equals format
query = f"pol_number={pol_id}"

# ❌ FAILS - Colon format
query = f"pol_number:{pol_id}"  # Server error!
```

→ See [Pagination & Queries](../../../alma-api-expert/references/pagination_and_queries.md#query-syntax)

<!-- moved from alma-api-expert/SKILL.md -->
### Invoice Payment Status Location

**⚠️ Payment status is NESTED, not at root:**

```python
# ❌ WRONG
payment_status = invoice['payment_status']

# ✅ CORRECT
payment_status = invoice['payment']['payment_status']['value']
```

→ See [Data Structures](../../../alma-api-expert/references/data_structures.md#invoice-structure)

<!-- moved from alma-api-expert/SKILL.md -->
### POL Items Location

**⚠️ Items are NOT at POL root:**

```python
# Items path: POL → location (list) → copy (list)
items = pol_data.get('location', [{}])[0].get('copy', [])
```

→ See [Data Structures](../../../alma-api-expert/references/data_structures.md#pol-structure)
