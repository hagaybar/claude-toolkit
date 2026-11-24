<!-- moved from alma-api-expert/references/data_structures.md -->
## Lending Request Structure

### Overview

Lending requests represent partner institution requests to borrow material from your library.

### Structure

```python
{
    "request_id": "10000000000000016",     # System-generated ID (output only)
    "external_id": "test primo 200825",    # External system ID (mandatory)
    "owner": "AS1",                         # ⚠️ Plain string (not wrapped!)
    "partner": {                            # Partner institution (wrapped)
        "value": "ANC",                     # Internal code (use this!)
        "desc": "ANCA-TEST",                # Display name
        "link": "https://api-eu..."
    },
    "format": {                             # Request format (wrapped)
        "value": "PHYSICAL",
        "desc": "Physical"
    },
    "citation_type": {                      # Resource type (wrapped)
        "value": "BOOK",
        "desc": "Book"
    },
    "title": "Introduction to Library Science",
    "author": "Smith, John A.",
    "isbn": "978-0-123456-78-9",
    "publisher": "Academic Press",
    "year": "2024",                         # field is `year`; there is no `publication_date` (corrected 2026-11-12, RS-10)
    "status": {                             # Current status (wrapped)
        "value": "SHIPPED_PHYSICALLY",
        "desc": "Shipped Physically"
    },
    "mms_id": "990000000000000002",        # Catalog record - plain string
    "barcode": "2239409-10",               # Item barcode
    "created_date": "2025-08-20Z",         # Creation date
    "created_time": "2025-08-20T05:42:24.143Z",  # Precise timestamp
    "last_modified_date": "2025-09-18Z",
    "last_modified_time": "2025-09-18T11:10:20.491Z",
    "text_email": "partner@example.edu",   # Lending: requester's email
    "printed": false,                       # Operational flags (output only)
    "reported": false,
    "has_active_notes": true,              # Quick note check (output only)
    "supplied_format": {                    # What was supplied
        "value": "PHYSICAL",
        "desc": "Physical"
    },
    "shipping_cost": {
        "sum": 0,
        "currency": {"value": "ILS", "desc": "..."}
    },
    "rs_note": [                            # JSON key on GET is `rs_note` (XML wrapper is rs_notes)
        {"content": "...", "created_by": "...", "created_date": "2025-08-20Z"}
    ]
}
```

(Corrected 2026-11-12, see evaluation RS-12/RS-13: all fields above are in the official GET
schema, none are undocumented; the notes list is `rs_note` in JSON responses, with items
`content`/`created_by`/`created_date`. The example request 10000000000000016 no longer exists
in Sandbox.)

### Critical Field Details

#### owner (Plain String!)

**⚠️ CRITICAL**: owner is a plain string — as the official JSON schema and XSD define it
(corrected 2026-11-12, see evaluation RS-02; it is not a schema discrepancy).

**Format**:
```python
# ✅ CORRECT
"owner": "MAIN"

# ❌ WRONG - Causes 400 error
"owner": {"value": "MAIN"}
```

**Error if wrapped**:
```
Error 400: Cannot deserialize value of type `java.lang.String` from Object value
```

**See Also**: [API Quirks - Owner Field](quirks-errors-validation.md)

#### partner (Wrapped Object)

**Structure**:
```python
"partner": {
    "value": "ANC",           # ← Use THIS in API calls
    "desc": "ANCA-TEST",      # Display name only
    "link": "https://..."
}
```

**⚠️ Important**: Always use `partner.value` (internal code), not `partner.desc` (display name)

```python
# ✅ CORRECT
partner_code = request['partner']['value']  # "ANC"

# ❌ WRONG
partner_code = request['partner']['desc']  # "ANCA-TEST" - won't work!
```

#### Operational and fulfilment fields

**Useful output fields** (all documented in the GET schema — corrected 2026-11-12, RS-12):
- `barcode`: Physical item barcode - links to inventory
- `text_email`: Contact email for automated communication
- `created_time`, `last_modified_time`: Precise timestamps
- `printed`, `reported`: Operational status flags
- `has_active_notes`: Quick check without parsing notes array
- `supplied_format`: What was actually sent (may differ from requested)
- `shipping_cost`: Actual shipping cost tracking

**Usage**:
```python
# Link request to item
barcode = request.get('barcode')
if barcode:
    print(f"Request for item: {barcode}")

# Check if notes exist
if request.get('has_active_notes'):
    notes = request.get('rs_note', [])  # JSON key is rs_note (RS-13)
    # Process notes
```

### Mandatory vs Optional Fields

**Mandatory for CREATE**:
- `external_id`
- `owner`
- `partner` (via partner_code parameter)
- `format`
- `citation_type` (unless `mms_id` provided)
- `title` (unless `mms_id` provided)

**Commonly Used Optional**:
- `author`, `isbn`, `issn`: Bibliographic metadata
- `mms_id`: If item exists in catalog
- `level_of_service`: Service level, code from `LevelOfService` (e.g. `RUSH_LOCAL`, `NORMAL_LOCAL`; there is no `Rush` code — corrected 2026-11-12, RS-14)
- `last_interest_date`: Need-by date
- `note`: free-text note (notes list `rs_notes` is not in the POST schema — RS-13)

### Field Format Summary

**Wrapped Fields** (use `{"value": "..."}`):
- `partner`, `format`, `citation_type`, `status`
- `preferred_send_method`
- `pickup_location`, `level_of_service`, `copyright_status`
- `supplied_format`

**Plain String Fields**:
- `owner`
- `mms_id`, `requested_media` (corrected 2026-11-12, RS-08/RS-09: string in schema/XSD and on GET)
- `external_id`, `request_id`, `title`, `author`, `year`
- All bibliographic metadata (isbn, issn, publisher, etc.)
- `barcode`, `text_email`

**Boolean Fields**:
- `printed`, `reported`, `allow_other_formats`, `has_active_notes`

<!-- moved from alma-api-expert/references/data_structures.md -->
### Resource Sharing Helpers

```python
# Get request summary
summary = rs.get_request_summary(request)

# Returns:
# {
#     'request_id': '...',
#     'external_id': '...',
#     'title': '...',
#     'author': '...',
#     'citation_type': '...',
#     'format': '...',
#     'status': '...',
#     'partner': '...',
#     'owner': '...'   # plain-string owner (AlmaAPITK main reads it correctly since #171)
# }
```
(Corrected 2026-11-12, RS-27: nine keys, from AlmaAPITK source.)
