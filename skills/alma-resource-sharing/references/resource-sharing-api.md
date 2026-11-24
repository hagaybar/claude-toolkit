# Resource Sharing API Reference

This reference covers the Alma Partners API for resource sharing operations (lending and borrowing requests).

## Quick Links

- **Partners API**: https://developers.exlibrisgroup.com/alma/apis/partners/
- **Schema Reference**: https://developers.exlibrisgroup.com/alma/apis/xsd/rest_user_resource_sharing_request.xsd
- **Swagger**: https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/partners.json (body schema `schemas/rest_user_resource_sharing_request-post.json`)
- **Implementation**: AlmaAPITK `src/almaapitk/domains/resource_sharing.py`
- **Test Script**: `tests/test_resource_sharing_lending.py` in the Alma-RS-lending-request-automation repo (corrected 2026-11-12, RS-28: there is no `src/tests/` in AlmaAPITK; its contract test is `tests/unit/contracts/test_resource_sharing_contract.py`)

## Key Endpoints

### Lending Requests

Lending requests represent partner institution requests to borrow material from your library.

#### Create Lending Request
```
POST /almaws/v1/partners/{partner_code}/lending-requests
Content-Type: application/json
```

**Required Parameters**:
- `partner_code` (path): Partner institution code

**Request Body**: Lending request object (see Data Structure below)

**Response**: Created lending request with generated `request_id`

**Example**:
```python
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id="EXT-2025-001",
    owner="MAIN",
    format_type="PHYSICAL",
    title="Introduction to Library Science",
    citation_type="BOOK"
)
# Returns: {'request_id': '12345678', 'external_id': 'EXT-2025-001', ...}
```

#### Retrieve Lending Request
```
GET /almaws/v1/partners/{partner_code}/lending-requests/{request_id}
```

**Required Parameters**:
- `partner_code` (path): Partner institution code
- `request_id` (path): Request identifier

**Response**: Complete lending request object

Observed in Sandbox 2026-11-12: the GET returned the request (HTTP 200) even when the path's
`partner_code` was a different existing partner than the request's own partner — do not use
this GET to confirm which partner a request belongs to; read `partner.value` from the body.

**Example**:
```python
request = rs.get_lending_request(
    partner_code="RELAIS",
    request_id="12345678"
)
```

## Data Structure

### Lending Request Object

**Mandatory Fields** (for creation):

| Field | Type | Format | Description |
|-------|------|--------|-------------|
| `external_id` | string | plain | External identifier from ILL/Rapido system |
| `owner` | **string** | **plain** | Resource sharing library code (e.g., "MAIN") |
| `partner` | object | wrapped | Partner institution code |
| `format` | object | wrapped | Request format (PHYSICAL/DIGITAL) |
| `citation_type` | object | wrapped | Resource type (unless `mms_id` provided) |
| `title` | string | plain | Resource title (unless `mms_id` provided) |

**⚠️ CRITICAL**: The `owner` field uses **plain string format**, NOT wrapped. (Corrected 2026-11-12, RS-02: the official JSON schema and XSD also define it as a string.)

**Field Format Examples**:
```python
# ✅ CORRECT formats:
{
    "owner": "MAIN",                           # Plain string
    "partner": {"value": "RELAIS"},            # Wrapped
    "format": {"value": "PHYSICAL"},           # Wrapped
    "citation_type": {"value": "BOOK"},        # Wrapped
    "title": "Introduction to Library Science" # Plain string
}

# ❌ INCORRECT - causes 400 error:
{
    "owner": {"value": "MAIN"}  # wrapped - wrong (schema says string too)
}
```

**Optional Fields**:

| Field | Type | Format | Description |
|-------|------|--------|-------------|
| `mms_id` | string | plain | Alma catalog record ID (if item exists) — corrected 2026-11-12, RS-08 |
| `author` | string | plain | Resource author |
| `isbn` | string | plain | ISBN for books |
| `issn` | string | plain | ISSN for journals |
| `publisher` | string | plain | Publisher name |
| `year` | string | plain | Publication date (the field is `year`; `publication_date` does not exist — corrected 2026-11-12, RS-10) |
| `journal_title` | string | plain | Journal title (article requests) |
| `note` | string | plain | Free-text note |
| `edition` | string | plain | Edition information |
| `volume` | string | plain | Volume number (journals) |
| `issue` | string | plain | Issue number (journals) |
| `pages` | string | plain | Page range |
| `doi` | string | plain | Digital Object Identifier |
| `pmid` | string | plain | PubMed ID |
| `call_number` | string | plain | Library call number |
| `oclc_number` | string | plain | OCLC number |
| `requested_media` | string | plain | Media description code |
| `preferred_send_method` | object | wrapped | Preferred delivery method |
| `pickup_location` | object | wrapped | Delivery location |
| `last_interest_date` | string | ISO date | Need-by date (YYYY-MM-DDZ) |
| `level_of_service` | object | wrapped | Service level, `LevelOfService` code (e.g. `RUSH_LOCAL`) |
| `copyright_status` | object | wrapped | Copyright status (docs: GET only for lending) |
| `allow_other_formats` | boolean | boolean | Accept alternative formats (not in the POST schema) |

(Corrected 2026-11-12, RS-13/RS-14: `rs_notes` is not in the POST schema and its items are
`{content, created_by, created_date}`; `level_of_service` has no `Rush` code.)

**Output-Only Fields** (returned but not sent; `rs_note` list too):

| Field | Description |
|-------|-------------|
| `request_id` | System-generated identifier |
| `status` | Current workflow status |
| `barcode` | Physical item barcode (when shipped) |
| `created_date` | Creation date (YYYY-MM-DDZ) |
| `created_time` | Precise creation timestamp (ISO 8601) |
| `last_modified_date` | Last modification date |
| `last_modified_time` | Precise modification timestamp |
| `printed` | Whether request has been printed |
| `reported` | Whether request has been reported |
| `has_active_notes` | Quick check for notes |
| `text_email` | Contact email for request |
| `supplied_format` | What was actually supplied |
| `shipping_cost` | Actual shipping cost |

## Validation Rules

### Mandatory Validation

The ResourceSharing domain validates these requirements before creating requests:

```python
# Required for all lending requests:
- external_id must be non-empty string
- owner must be non-empty string (plain format!)
- partner must be non-empty string
- format_type must be non-empty string

# Title validation (conditional):
- If mms_id is NOT provided, title is REQUIRED
- If mms_id IS provided, title is optional

# Citation type validation (conditional):
- If mms_id is NOT provided, citation_type is REQUIRED
- If mms_id IS provided, citation_type is optional
```

**Validation Method**: `_validate_lending_request_data()`

### Field Format Rules

**Wrapped Fields** (must use `{"value": "..."}`):
- `partner`
- `format`
- `citation_type`
- `status`
- `preferred_send_method`
- `pickup_location`
- `level_of_service`
- `copyright_status`
- `supplied_format`

**Plain String Fields** (never wrap):
- `owner` ⚠️ (plain, as documented)
- `mms_id`, `requested_media` (corrected 2026-11-12, RS-08/RS-09: string in schema and on GET; AlmaAPITK `create_lending_request` still wraps both)
- `year`
- `external_id`
- `request_id`
- `title`
- `author`
- `isbn`, `issn`
- `publisher`
- `edition`, `volume`, `issue`, `pages`
- `doi`, `pmid`, `call_number`, `oclc_number`
- `barcode`
- `text_email`

**Boolean Fields**:
- `printed`
- `reported`
- `allow_other_formats`

## Critical API Quirks

### Owner Field Format

**Corrected 2026-11-12 (RS-02):** the official documentation is *not* wrong here. Both the
JSON schema (`rest_user_resource_sharing_request-post.json`: `owner` type `string`) and the XSD
(`<xs:element name="owner" type="xs:string">`) define `owner` as a plain string. The pitfall is
assuming it is wrapped like its neighbours `partner`/`format`/`citation_type`.

**Wrong (wrapped)**:
```python
{"owner": {"value": "MAIN"}}  # ❌ WRONG - causes 400 error!
```

**Actual Required Format**:
```python
{"owner": "MAIN"}  # ✅ CORRECT - plain string
```

**Error When Using Wrapped Format**:
```
HTTP 400 Bad Request
Cannot deserialize value of type `java.lang.String` from Object value
```

**Discovery**: Found through testing on 2025-12-24 with SANDBOX lending request ID 10000000000000016.

**Resolution**: Always use plain string for `owner` field in both CREATE and UPDATE operations.

### Input/Output Symmetry

Unlike some other APIs, Resource Sharing API maintains symmetry for most fields:

**Symmetric Fields** (same format in/out):
- `owner`: Plain string (both input and output)
- `partner`: Wrapped object (both input and output)
- `format`: Wrapped object (both input and output)
- `title`, `author`, etc.: Plain strings (both)

**No Asymmetry Issues** (`owner` is plain on both sides, as documented).

### Operational Fields in Responses

Real API responses include these output fields (corrected 2026-11-12, RS-12: all are
documented in the GET schema `rest_user_resource_sharing_request.json`):

**Operational Metadata**:
```python
{
    "printed": false,                    # Printing status
    "reported": false,                   # Reporting status
    "has_active_notes": true,           # Quick note check
    "created_time": "2025-08-20T05:42:24.143Z",    # Precise timestamp
    "last_modified_time": "2025-09-18T11:10:20.491Z"
}
```

**Item Integration**:
```python
{
    "barcode": "2239409-10",            # Physical item barcode
    "mms_id": "990000000000000002"      # Links to catalog
}
```

**Fulfillment Details**:
```python
{
    "supplied_format": {                 # What was actually sent
        "value": "PHYSICAL",
        "desc": "Physical"
    },
    "shipping_cost": {
        "sum": 0,
        "currency": {"value": "ILS", "desc": "New Israeli Sheqel"}
    },
    "text_email": "partner@example.edu"  # Contact email
}
```

**Partner Display Names**:
```python
{
    "partner": {
        "value": "ANC",           # Use this code in API calls
        "desc": "ANCA-TEST",      # Display name for UI
        "link": "https://api-eu.hosted.exlibrisgroup.com/almaws/v1/partners/ANC"
    }
}
```

⚠️ **Always use** `partner.value` (internal code) in API calls, not `partner.desc` (display name).

### Date Format Precision

Alma returns both coarse and precise timestamps:

```python
{
    "created_date": "2025-08-20Z",                    # Day precision (what you send)
    "created_time": "2025-08-20T05:42:24.143Z",      # Millisecond precision (Alma internal)
    "last_modified_date": "2025-09-18Z",
    "last_modified_time": "2025-09-18T11:10:20.491Z"
}
```

**When to use each**:
- `*_date`: For day-level comparisons and display
- `*_time`: For precise audit trails and sequencing

### Status Values

**Initial status**: `REQUEST_CREATED_LEND` ("Created lending request") — corrected
2026-11-12 (RS-15) from `REQUEST_CREATED_LEN`, which does not exist.

Codes come from the `MandatoryLendingWorkflowSteps` / `OptionalLendingWorkflowSteps` code
tables. Observed on 66 Sandbox lending requests 2026-11-12: `REQUEST_CREATED_LEND`,
`SHIPPED_DIGITALLY`, `REJECTED`, `RECEIVED_BY_PARTNER`. Others in the table include
`BEING_PROCESSED`, `WILL_SUPPLY`, `SHIPPED_PHYSICALLY`, `RETURNED_BY_PARTNER`,
`REQUEST_COMPLETED`, `CANCELLED`.

Status workflow is managed by Alma based on request lifecycle and institutional configuration.

## Implementation Guide

### Basic Usage

```python
from almaapitk import AlmaAPIClient
from almaapitk import ResourceSharing

# Initialize
client = AlmaAPIClient('SANDBOX')
rs = ResourceSharing(client)

# Create lending request
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id="EXT-2025-001",
    owner="MAIN",
    format_type="PHYSICAL",
    title="Introduction to Library Science",
    citation_type="BOOK",
    author="Smith, John A.",
    isbn="978-0-123456-78-9"
)

print(f"Created request: {request['request_id']}")

# Retrieve request
retrieved = rs.get_lending_request(
    partner_code="RELAIS",
    request_id=request['request_id']
)

# Get summary
summary = rs.get_request_summary(retrieved)
print(f"Title: {summary['title']}")
print(f"Status: {summary['status']}")
```

### Advanced Usage - Catalog Item

When creating a request for an item already in your catalog:

```python
# Create request for known catalog item
request = rs.create_lending_request(
    partner_code="PARTNER_01",
    external_id="EXT-2025-002",
    owner="MAIN",
    format_type="DIGITAL",
    title="Advanced Cataloging",
    mms_id="991234567890123456",  # Item exists in catalog
    level_of_service={"value": "RUSH_LOCAL"}  # LevelOfService code (RS-14)
)
# Caution (RS-08): AlmaAPITK de2013d sends mms_id as {"value": ...}, but the schema
# defines a plain string. Untested live; prefer verifying in Sandbox first.

# When mms_id is provided:
# - citation_type becomes optional
# - Alma can auto-populate some metadata from catalog
```

### Validation Error Handling

```python
try:
    request = rs.create_lending_request(
        partner_code="PARTNER_01",
        external_id="",  # ❌ Missing - will fail validation
        owner="MAIN",
        format_type="PHYSICAL",
        title="Test Book"
    )
except ValueError as e:
    print(f"Validation error: {e}")
    # Output (AlmaAPITK de2013d): Validation failed for lending request:
    #   - external_id is mandatory when creating a lending request
```

### Helper Method - Request Summary

```python
request = rs.get_lending_request(partner_code="RELAIS", request_id="12345678")

# Extract key information
summary = rs.get_request_summary(request)
# Returns:
# {
#     'request_id': '12345678',
#     'external_id': 'EXT-2025-001',
#     'title': 'Introduction to Library Science',
#     'author': 'Smith, John A.',
#     'citation_type': 'BOOK',
#     'format': 'PHYSICAL',
#     'status': 'REQUEST_CREATED_LEND',
#     'partner': 'RELAIS',
#     'owner': 'MAIN'  # plain string (fixed in AlmaAPITK #171)
# }
```

## Common Patterns

### Pattern 1: Create Request from ILL System

```python
# Receive ILL request from external system (Rapido, ILLiad, etc.)
ill_request = {
    "external_id": "ILL-12345",
    "patron_name": "John Doe",
    "title": "Example Book",
    "author": "Smith, Jane",
    "isbn": "978-0-123456-78-9"
}

# Create lending request in Alma
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id=ill_request['external_id'],
    owner="MAIN",
    format_type="PHYSICAL",
    title=ill_request['title'],
    citation_type="BOOK",
    author=ill_request['author'],
    isbn=ill_request['isbn']
)

# Store request_id for tracking
ill_request['alma_request_id'] = request['request_id']
```

### Pattern 2: Batch Request Creation

```python
# Process multiple ILL requests
external_requests = load_ill_requests()  # Your data source

created_requests = []
for ext_req in external_requests:
    try:
        request = rs.create_lending_request(
            partner_code=ext_req['partner'],
            external_id=ext_req['id'],
            owner="MAIN",
            format_type=ext_req['format'],
            title=ext_req['title'],
            citation_type=ext_req['type'],
            author=ext_req.get('author'),
            isbn=ext_req.get('isbn')
        )
        created_requests.append({
            'external_id': ext_req['id'],
            'alma_id': request['request_id'],
            'status': 'SUCCESS'
        })
    except (ValueError, AlmaAPIError) as e:
        created_requests.append({
            'external_id': ext_req['id'],
            'status': 'FAILED',
            'error': str(e)
        })

# Generate report
save_report(created_requests)
```

### Pattern 3: Monitor Request Status

```python
# Retrieve and check current status
request = rs.get_lending_request(
    partner_code="RELAIS",
    request_id="12345678"
)

status = request.get('status', {}).get('value')

# Handle different statuses
if status == "REQUEST_CREATED_LEND":   # corrected 2026-11-12, RS-15
    print("Request created, awaiting processing")
elif status == "BEING_PROCESSED":       # IN_PROCESS is not a lending status
    print("Request being processed")
elif status == "SHIPPED_DIGITALLY":
    print("Shipped digitally to partner")
elif status == "SHIPPED_PHYSICALLY":
    print("Item shipped to partner")
    barcode = request.get('barcode')
    if barcode:
        print(f"Item barcode: {barcode}")
# Handle other statuses based on workflow
```

### Pattern 4: Journal Article Request

```python
# Create request for journal article
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id="EXT-2025-003",
    owner="MAIN",
    format_type="DIGITAL",
    title="The Impact of Digital Libraries",
    citation_type="JOURNAL",   # lending codes are BOOK/JOURNAL only (corrected 2026-11-12, RS-11)
    journal_title="Journal of Digital Libraries",
    author="Johnson, Mary",
    issn="1234-5678",
    volume="42",
    issue="3",
    pages="245-267",
    doi="10.1000/example.doi"
)
```

### Pattern 5: Rush Request with Notes

```python
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id="EXT-2025-004",
    owner="MAIN",
    format_type="PHYSICAL",
    title="Urgent Medical Reference",
    citation_type="BOOK",
    level_of_service={"value": "RUSH_LOCAL"},
    last_interest_date="2025-02-01Z",  # Need by date
    note="Rush request for medical research"
)
# Corrected 2026-11-12 (RS-13/RS-14): no "Rush" LevelOfService code; rs_notes is not in the
# POST schema (items, where returned, are {content, created_by, created_date}) — use `note`,
# as the production lending code does.
```

## Testing

### Test Script

**Location**: `tests/test_resource_sharing_lending.py` in the Alma-RS-lending-request-automation repo (corrected 2026-11-12, RS-28)

**Test Coverage**:
- Basic physical lending request creation
- Journal article request creation
- Request retrieval by ID
- Validation error handling
- Summary helper functionality

### Running Tests

```bash
# Dry-run test (no actual API calls)
python src/tests/test_resource_sharing_lending.py --dry-run

# Live test in SANDBOX (creates real requests)
python src/tests/test_resource_sharing_lending.py --live

# Test with custom partner and owner
python src/tests/test_resource_sharing_lending.py --live \
    --partner CUSTOM_PARTNER \
    --owner BRANCH_LIB

# Test validation errors
python src/tests/test_resource_sharing_lending.py --live --test-validation
```

### Test Data

**Historical SANDBOX Example** (no longer exists — GET returned 400 "request_id is invalid" on 2026-11-12):
- Request ID: 10000000000000016
- External ID: "test primo 200825"
- Status: SHIPPED_PHYSICALLY
- Partner: ANC (ANCA-TEST)
- Barcode: 2239409-10
- MMS ID: 990000000000000002

This real request demonstrates:
- Complete field population
- Shipped status with barcode
- Link to catalog (mms_id)
- Contact email integration
- Multiple metadata fields

## Configuration Requirements

### Partner Codes

Partner codes must exist in Alma configuration:
- **Path**: Configuration > Resource Sharing > Partners
- **Examples**: RELAIS, ILL_PARTNER, RAPIDO
- Partner codes are case-sensitive
- Must match exactly when used in API calls

### Owner Codes

Owner codes must be valid resource sharing library codes:
- **Path**: Configuration > Resource Sharing > Resource Sharing Libraries
- **Examples**: MAIN, BRANCH, SCIENCE_LIB
- Represents the library fulfilling the request

### Format Codes

Format values controlled by RequestFormats code table:
- PHYSICAL - Physical item
- DIGITAL - Digital/electronic delivery
- PHYSICAL_NON_RETURNABLE (in the Sandbox table, 2026-11-12)

### Citation Types

Lending citation types (corrected 2026-11-12, RS-11): the docs list the `PR_CitationType`
code table — `BOOK` / `JOURNAL` — and the Sandbox table holds exactly those two. `ARTICLE`,
`CHAPTER`, `DISSERTATION` are not lending codes, and a `ResourceSharingCitationTypes` table
does not exist ("Table does not exist."). Article requests use `JOURNAL` (+ `journal_title`).
Borrowing uses a different table — see the borrowing section below.

## Error Handling

### Common Errors

**Error 400 - Bad Request**:
```
Cannot deserialize value of type `java.lang.String` from Object value
```
**Cause**: Used wrapped format for `owner` field
**Fix**: Use plain string: `"owner": "MAIN"`

**Client-side ValueError - Validation Failed** (raised by AlmaAPITK before any request; not an HTTP 400 — corrected 2026-11-12, RS-26):
```
Validation failed for lending request:
  - external_id is mandatory when creating a lending request
```
**Cause**: Missing or empty required field
**Fix**: Ensure all mandatory fields are populated

**Error 400 - Partner not found** (corrected 2026-11-12, RS-20: HTTP 400, not 404):
```
Partner not found
```
Swagger documents `402118 'Partner not found.'` as a 400 on `GET /partners/{code}`; Sandbox
returned HTTP 400 "Partner not found" for an unknown code. The response on a lending *create*
with an unknown partner was not tested.
**Cause**: Partner code doesn't exist in configuration
**Fix**: Verify partner code in Configuration > Partners

### Validation Exceptions

The ResourceSharing domain raises `ValueError` for validation failures:

```python
try:
    request = rs.create_lending_request(...)
except ValueError as e:
    # Validation error - check parameters
    logger.error(f"Validation failed: {e}")
except AlmaAPIError as e:
    # API error - check Alma configuration or network
    logger.error(f"API error: {e.status_code} - {e}")
```

## Best Practices

### 1. Always Provide External ID

```python
# ✅ GOOD - Unique external ID
external_id = f"ILL-{datetime.now().strftime('%Y%m%d-%H%M%S')}-{unique_id}"

# ❌ BAD - Generic or missing ID
external_id = "REQUEST"  # Not unique
external_id = ""         # Empty (fails validation)
```

### 2. Use Correct Field Formats

```python
# ✅ GOOD - Correct field formats
{
    "owner": "MAIN",                      # Plain string
    "partner": {"value": "RELAIS"},       # Wrapped
    "format": {"value": "PHYSICAL"}       # Wrapped
}

# ❌ BAD - Mixed up formats
{
    "owner": {"value": "MAIN"},           # Wrong - will fail
    "partner": "RELAIS",                  # Wrong - will fail
    "format": "PHYSICAL"                  # Wrong - will fail
}
```

### 3. Extract Partner Code from Responses

```python
# ✅ GOOD - Use internal code
partner_code = request['partner']['value']  # "ANC"

# ❌ BAD - Use display name
partner_code = request['partner']['desc']   # "ANCA-TEST" - wrong!
```

### 4. Handle Optional Citation Metadata

```python
# For catalog items (mms_id provided)
request = rs.create_lending_request(
    mms_id="991234567890123456",
    external_id="EXT-001",
    owner="MAIN",
    format_type="PHYSICAL",
    title="Example Book",  # Optional for Alma, but a required argument in AlmaAPITK (RS-25)
    # citation_type optional when mms_id present
)

# For non-catalog requests
request = rs.create_lending_request(
    external_id="EXT-002",
    owner="MAIN",
    format_type="PHYSICAL",
    title="Example Book",        # REQUIRED
    citation_type="BOOK",         # REQUIRED
    author="Smith, John",         # Recommended
    isbn="978-0-123456-78-9"      # Recommended
)
```

### 5. Log Request Creation

```python
# Log for audit trail
logger.info(
    "Creating lending request",
    external_id=external_id,
    partner=partner_code,
    title=title
)

request = rs.create_lending_request(...)

logger.info(
    "Lending request created",
    request_id=request['request_id'],
    external_id=external_id
)
```

## Future Enhancements

The following Partners API endpoints are available but not yet implemented in ResourceSharing domain:

**Not Yet Implemented** (corrected 2026-11-12, RS-17/RS-18: the Partners API documents only
POST and GET-by-id for lending requests; there is no update or partner-level borrowing endpoint):
- List / bulk actions on lending requests — `GET`/`POST /almaws/v1/task-lists/rs/lending-requests` (Task Lists API, `library` param)
- Borrowing requests are patron-side — see the next section
- Request cancellation / status change — lending: not in the Partners API

**When implementing**, follow the same patterns:
- Validate inputs before API calls
- Use correct field formats (wrapped vs plain)
- Include comprehensive error handling
- Add logging for all operations
- Write corresponding test methods

---

## User-Side Resource Sharing Requests (Borrowing)

The user-side endpoints (`POST /almaws/v1/users/{user_id}/resource-sharing-requests`) are distinct from the partner-side `ResourceSharing` domain documented above. They live on the `Users` class in AlmaAPITK and represent a patron requesting an item that the institution doesn't hold.

**Authoritative schema (POST):** [`rest_user_resource_sharing_request-post.json`](https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/schemas/rest_user_resource_sharing_request-post.json) — referenced from `users.yaml` line 2182.

**AlmaAPITK methods (since 0.4.5+1 / PR #147):**
- `Users.create_user_rs_request(user_id, request_data, user_id_type=None, override_blocks=None, *, validate=False) -> AlmaResponse`
- `Users.get_user_rs_request(user_id, request_id, request_id_type=None) -> Dict`
- `Users.cancel_user_rs_request(user_id, request_id, reason=None, note=None, remove_request=None, notify_user=None) -> AlmaResponse` (a `DELETE`)
- `build_user_rs_request(owner, format, citation_type, *, title=None, journal_title=None, author=None, year=None, pickup_location=None, pickup_location_type=None, agree_to_copyright_terms=True, external_id=None, extra=None)` — pure body builder, owns the plain-vs-wrapped rules
- (Signatures updated 2026-11-12 from AlmaAPITK de2013d / v0.5.1, RS-30.)
- `Users.perform_user_rs_request_action(user_id, request_id, op, shipping_cost=None, fund_code=None, request_id_type=None) -> AlmaResponse`

### Required field shapes (CREATE)

The body validates against a JAXB type (`UserResourceSharingRequest`). Wrong field names or wrapper-vs-string mismatches produce HTTP 400 `BAD_REQUEST` with errorMessage starting `Cannot construct instance of com.exlibris.urm.jaxb.resourceSharing.UserResourceSharingRequest` — not very diagnostic. Get the shape right:

| Field | Schema type | Wrapped? | Example |
|---|---|---|---|
| `owner` | string | **NO — plain string** | `"RS_LIB_CODE"` |
| `format` | object | YES `{value}` | Codes from the **`RequestFormats`** code table: **`PHYSICAL`** / **`DIGITAL`** / **`PHYSICAL_NON_RETURNABLE`**. `DIGITAL` confirmed (created). `P`/`E` are *purchase-request* codes (table `PR_RequestedFormat`) and are rejected here with a mangled `Invalid field value … {1}` error. Confirm the live list via the [Code Tables API](../../alma-api-expert/references/code_tables_api.md). Observed SB 2026-07-19. |
| `citation_type` | object | YES `{value}` | Article codes: **`CR`** = "Physical Article" (scan of a printed article) and **`E_CR`** = "Electronic Article" (born-digital) — **both confirmed created** via the RS create. Book codes `BK` / `E_BK` sit in the same code table (`ReadingListCitationTypes`) but were not create-tested. `BOOK`/`JOURNAL` are *purchase-request* codes (`PR_CitationType`), NOT these. Observed SB 2026-07-19. Note (2026-11-12, RS-22): the official schema names `PhysicalReadingListCitationTypes` (`BK`/`CR`) as the borrowing table and `PR_CitationType` (`BOOK`/`JOURNAL`) as the *lending* table; both tables, plus `ReadingListCitationTypes` with `BK`/`CR`/`E_BK`/`E_CR`, exist in Sandbox. |
| `title` | string | NO | `"Some Title"` |
| `pickup_location_type` | string | **NO — plain string** | `"LIBRARY"` (or `"CIRCULATION_DESK"`) |
| `pickup_location` | object | YES `{value}` | `{"value": "PICKUP_LIB_CODE"}` |
| `agree_to_copyright_terms` | boolean | NO | `True` (mandatory for borrowing) |
| `partner` | object | YES `{value}` | `{"value": "PARTNER_CODE"}` (NOT required at create — see "User-side BR create: partner NOT required" in `quirks-errors-validation.md`) |
| `fund` | object | YES `{value}` | `{"value": "FUND_CODE"}` |
| `requester` | object | YES `{value, full_name}` | auto-populated from path; usually omit |
| `mms_id` | string | NO | (alternative to title) |
| `last_interest_date` | string | NO | `"2026-12-31Z"` |

> **Don't guess the `format` / `citation_type` codes** — confirm your tenant's
> accepted values with the Code Tables API (`Configuration.get_code_table(...)`),
> see [Code Tables API](../../alma-api-expert/references/code_tables_api.md). `CR` was observed as the tenant
> label "Physical Article"; a different code may apply to electronic-source
> articles.

**Mandatory minimum for create:**
- `format` (long-form `PHYSICAL`/`DIGITAL` — NOT the purchase-request `P`/`E`)
- `citation_type` (for borrowing)
- `owner` (RS library code; missing → alma_code `401607`)
- `pickup_location_type` + `pickup_location` (when patron picks up; missing/invalid → alma_code `401929`)
- `title` OR `mms_id` (title mandatory unless mms_id supplied)
- `agree_to_copyright_terms: True` (mandatory for borrowing)

### Borrowing create — observed behavior (SB 2026-07-19)

Confirmed by live SANDBOX creates:

- **Working digital-article recipe (HTTP 200, ~3s):** `owner` (plain) · `format:{DIGITAL}` · `citation_type:{E_CR}` · `title` · `journal_title` · `author` · `year` · `pickup_location_type:"LIBRARY"` · `pickup_location:{RES_SHARE}` · `agree_to_copyright_terms:true`. **No `override_blocks`.**
- **`E_CR` (Electronic Article) and `CR` (Physical Article) are both accepted** — each produced a created request.
- **A DIGITAL article requires `journal_title` + `year` + `author`**, else `alma_code 401930` "Fill the mandatory fields: Journal Title, Publication Date, Author."
- **`401604` "The institutional inventory has services for the requested title"** fires when the request's `title` matches material the institution already holds. It blocks the create (HTTP 400) despite the "Warning" wording — it is *not* a payload bug. A distinctive / genuinely un-held title created cleanly with no override.
- **`override_blocks=true` is a workaround, not the recipe.** It force-creates past `401604` (and patron blocks) — use it knowingly. Observed side effect: **with** override the create ran **>60s (client ReadTimeout)** yet still saved the request (a non-idempotent POST that timed out — retry then hit `402362` "duplicate request"); **without** override the same-shaped create returned in **~3s** with a clean `200`+`request_id`.
- **`pickup_location` may equal `owner`** (the RS library) where that is the only configured BR pickup; a created request also gets a flow-generated placeholder bib (MMS ID) built from the request's own metadata — not a catalogue match.

### Borrowing create — observed behavior (SB 2026-07-22)

Confirmed by live SANDBOX creates (AlmaAPITK chunk `rs-borrowing-ergonomics` test run + follow-up diagnostics):

- **DECOMPOSED (same day, follow-up matrix — evidence in AlmaAPITK issue #207): the raw-500 culprit is the `citation_type` value, NOT the `PHYSICAL` format path.** Controlled matrix (same patron/owner/pickup/field shapes/`year` across all cells): `BOOK` → raw 500 under **both** PHYSICAL and DIGITAL; `JOURNAL` → raw 500; a deliberately bogus code → the **identical** raw 500; `BK` (PHYSICAL), `E_CR` (PHYSICAL and DIGITAL), `E_BK` (DIGITAL) → all create cleanly. **Rule: any `citation_type` outside the RS borrowing table `BK`/`E_BK`/`CR`/`E_CR` dies as an unhandled raw HTTP 500 *before* field validation** (tracking-ID only, no alma_code) — Alma has no validation message for wrong-table citation codes on this endpoint. `BOOK`/`JOURNAL` are lending/purchase-request-table values; SB *tolerated* `BOOK` until ~mid-2026 (a 2026-05-18 create with PHYSICAL+BOOK succeeded) and stopped between 2026-05-18 and 2026-07-19. Also: `BK` validates `year` (Publication Date) as create-mandatory — the old tolerated-`BOOK` path never reached that check.
- **Digital-article recipe re-confirmed with a second RS library:** `owner:"AM1"` (plain) + `pickup_location:{AM1}` + `format:{DIGITAL}` + `citation_type:{E_CR}` + `title`/`journal_title`/`author`/`year` + `pickup_location_type:"LIBRARY"` + `agree_to_copyright_terms:true` → HTTP 200, `REQUEST_CREATED_BOR`, ~1s. Optional enrichment fields `volume`/`issue`/`pages`/`doi`/`pmid` accepted.
- **Pickup validation runs before the 500-path:** `owner:"AM1"` + `pickup_location:{RES_SHARE}` → clean `401929` "The library selected is not a valid pickup location" (RES_SHARE is not a configured BR pickup *for AM1*; pickup validity is per-owner).
- **GET echo asymmetry on the created request:** `volume` and `pages` echo back, but `journal_title`, `issue`, `doi`, `pmid` return as `""` even though the create accepted them (and journal_title is create-mandatory for digital articles). Sent-and-accepted ≠ echoed-on-GET.
- **Toolkit note (almaapitk #194 guardrail):** the shipped (v0.5.0) allow-set is `{BK, CR, BOOK, JOURNAL, E_CR, E_BK}` — the `E_CR`/`E_BK` gap found by this run was fixed pre-merge, but `BOOK`/`JOURNAL` were deliberately kept, citing the historical SB acceptance. The decomposition matrix (above) invalidated that justification: both now raw-500 live. The set was tightened to exactly the RS table `{BK, CR, E_BK, E_CR}` in AlmaAPITK PR #213 (merged 2026-07-26, R10 pin `tests/unit/regressions/test_issue_207.py`), so `validate=True` now rejects wrong-table citation codes pre-send.
- **`E_CR` drops journal-level metadata at persist; `CR` keeps and ENRICHES it.** A/B pair with identical bodies (DIGITAL, journal_title/volume/issue/pages/doi/pmid all sent):
  - `citation_type:{E_CR}` → create validates the 401930-mandatory fields, then **discards `journal_title`, `issue`, `doi`, `pmid`** (empty in JSON GET, XML GET, and the placeholder bib — no `773$t`). Kept: title/author/volume/pages/year, but volume lands in the bib's **series slot `490$v` ("v:69")** instead of the host-item `773$g` — which is why the Alma UI form shows the Volume box EMPTY while the API echoes `volume:"69"`. UI "Publication date" ← api `year` (260$c); the UI "Year" box maps to nothing sent. Net effect: the UI Resource Information panel shows title/author/pages/publication-date only.
  - `citation_type:{CR}` (same body otherwise) → **all fields persist** (journal_title/volume/issue/pages/doi/pmid echo back) AND Alma runs citation enrichment: bib gets `022` ISSN it was never sent (resolved externally, presumably via DOI/PMID), normalized 245 title (submitted title text was even replaced), `260$c` year, full `773` host item (`$t` journal, `$g no:` volume, `$g iss:` issue, `$g p:`/`pages:` ranges), `856$u` doi:+pmid:.
  - **Practical rule:** for scanned/article borrowing requests where the journal metadata must survive into the request + bib, use `CR`, not `E_CR`. Reproducible A/B pair exists in SB (E_CR vs CR requests created 2026-07-22) if reporting to Ex Libris.

### Borrowing create — observed behavior (SB 2026-07-30, TAU repo test matrix)

Confirmed by live SANDBOX creates (Alma-RS-lending-request-automation matrix T-01/T-02/T-02b, user `SHEB`, owner `AM1`, `CR`+`DIGITAL`, bodies from `almaapitk.build_user_rs_request`):

- **`agree_to_copyright_terms` is enforced at create: `false` → `401897` "Invalid field value. Field: agree_to_copyright_terms, Value: false."** — the request is rejected outright. `true` succeeds and **stores as `true`** on immediate GET. The "mandatory TRUE for borrowing" line above is confirmed; the `false` values seen on manually-created requests are UI population, not an API persistence rewrite.
- **Settability (T-02, fake identifiers so augmentation stays silent): every field of the full article template stores verbatim** — title/journal_title/author/year, volume/issue/pages/start_page/end_page, issn/pmid/doi, publisher/place_of_publication, note/bib_note, requested_media/specific_edition/need_patron_info/maximum_fee/lcc_number, booleans. Wrapped fields (`format`/`citation_type`/`pickup_location`) gain only a `desc`. The **only dropped field is `external_id`** (stored empty — Alma discards client external_ids on this endpoint). Note this *contradicts the 2026-07-22 "GET echo asymmetry" bullet for `CR`*: with `CR` + this template, `journal_title`/`issue`/`doi`/`pmid` DO echo back.
- **Augmentation with a real `pmid` is SYNCHRONOUS and selective (T-02b):** overwrites already present on a GET issued immediately after the create response. Augmentation-owned (rewritten from the resolved PubMed record): `title`, `author`, `year`, `volume`, `issue`, `start_page`, `end_page`, `issn`. Sender-owned (deliberately-wrong sent values survived): `journal_title`, `pages` (can end up disagreeing with the augmented `start_page`/`end_page`), `publisher`, `place_of_publication`, `note`, `bib_note`, and all operational fields. No `401604` fired despite the real identifier.

### Borrowing cancel + duplicate detection — observed behavior (SB 2026-07-22)

- **Cancel is a soft state transition, not a delete.** After `cancel_user_rs_request`, GET on the request **succeeds** and returns `status: {value: "CANCEL_REQUESTED", desc: "Cancelled by staff"}`. Pre-2026-07 SB behavior hard-deleted the request (post-cancel GET raised); tests asserting "GET must fail after cancel" broke when this changed — assert *gone-or-CANCEL\** instead.
- **Duplicate detection (`402362`) matches cancelled requests too.** Re-creating a request with the same `title` minutes after cancelling its twin fails with "Patron has duplicate request". Automated tests must use a per-run unique `title` (timestamp suffix) to stay re-runnable.

### update_shipping action — both params optional

`POST /users/{user_id}/resource-sharing-requests/{request_id}?op=update_shipping`

Per the swagger, both `shipping_cost` and `fund_code` are `required=False`. Either can be passed independently, both, or neither (no-op-but-valid). Useful when only one needs updating. See the matching quirks-row "`update_shipping` action params both optional" for the documented error codes.

### Common error codes (user-side RS)

| Code | Meaning | Cause |
|---|---|---|
| `401607` | Resource sharing library (owner) is missing | `owner` field absent or empty |
| `401768` | Patron is not affiliated with a resource sharing library | Test user must be in an RS-enabled user group |
| `401929` | The library selected is not a valid pickup location | `pickup_location.value` not configured as a BR pickup for the `owner` library; pickup-library codes live in **Alma UI (path varies by tenant + Alma version; check your installation's Resource Sharing config area)** tab |
| `401930` | Missing mandatory fields (e.g. "Journal Title, Publication Date, Author") | A DIGITAL article (`citation_type` `CR`/`E_CR`) requires `journal_title` + `year` + `author` |
| `401604` | "Warning – The institutional inventory has services for the requested title" | The request `title` matches material the institution already holds; blocks create (HTTP 400 despite "Warning"). Fix: request genuinely un-held material — or, knowingly, pass `override_blocks=true` |
| `402362` | Failed to save the request: Patron has duplicate request | An identical request already exists for the patron (also surfaces when retrying after a *timed-out* create that actually saved). **Cancelled requests count as duplicates too** (SB 2026-07-22) — use per-run unique titles in automated tests |
| *(raw HTTP 500, no alma_code)* | Unhandled server error, pre-validation | On user-side BR create: `citation_type` outside the RS table `BK`/`E_BK`/`CR`/`E_CR` — e.g. `BOOK`/`JOURNAL` (purchase/lending-table values). Alma emits no validation message for wrong-table citation codes; verified via matrix incl. a bogus code, SB 2026-07-22 (AlmaAPITK #207) |
| `40166422` | request_id is invalid for this user_id | GET/action used the wrong owning patron — the endpoint is user-scoped |
| `40166411` | Parameter value is invalid | Generic; usually on `op` actions |
| `40166425` | Shipping cost cannot be lower than 0 | Negative `shipping_cost` on `update_shipping` |
| `40166426` | Parameter value is invalid (with error message) | Generic; check the embedded message |
| `Invalid field value. Field: [Ljava.lang.Object;@… Value: {1}` | A code-table value is from the wrong table (Alma fails to render *which* field) | Most common cause: `format` sent as `P`/`E` instead of `PHYSICAL`/`DIGITAL`; also check `citation_type`. Verified SB 2026-07-19. |
| `60270` | Purchase request format not valid: [E,P] | **Purchase-request endpoint only — does NOT apply to RS.** RS-borrowing `format` uses `PHYSICAL`/`DIGITAL`; a wrong RS `format` returns the mangled `Invalid field value … {1}` error above instead. |
| `BAD_REQUEST` + "Cannot construct instance ... UserResourceSharingRequest" | Body shape mismatch | Wrong field name, wrong wrapper-vs-plain-string, wrong nested structure |

### Live SANDBOX test pattern

See `chunks/users-requests-followup/sandbox-tests/test_t_42_3.py` (AlmaAPITK repo) for a complete create → get → update_shipping → cancel → post-cancel-get round-trip with an agent-safe dual-output design (issue #148). Pattern is reusable for any user-side RS test.

<!-- moved from alma-api-expert/references/endpoint_reference.md -->
## Resource Sharing API Endpoints

### Lending Requests

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| POST | `/partners/{partner_code}/lending-requests` | Create lending request | Yes |
| GET | `/partners/{partner_code}/lending-requests/{request_id}` | Retrieve lending request | Yes |
| GET | `/task-lists/rs/lending-requests?library=...` | List lending requests (filters: `status`, `partner`, `printed`, `reported`, `requested_format`, `supplied_format`) | Yes |
| POST | `/task-lists/rs/lending-requests?op=...` | Bulk action on lending requests | Yes |

(Corrected 2026-11-12, RS-17: `partners.json` defines only POST and GET-by-id under
`/partners/{partner_code}/lending-requests`; there is no PUT and no list there — a GET on the
list path returned HTTP 400 "Partner not found" in Sandbox even for an existing partner. The
list lives in the Task Lists API; Sandbox `GET /task-lists/rs/lending-requests?library=AM1`
returned 200.)

**Parameters**:
- `partner_code`: Partner institution code
- `request_id`: Request identifier
- `limit`, `offset`: Pagination (task list)

**Examples**:
```
POST /almaws/v1/partners/RELAIS/lending-requests
GET /almaws/v1/partners/RELAIS/lending-requests/10000000000000016
```

### Borrowing Requests

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| POST | `/users/{user_id}/resource-sharing-requests` | Create borrowing request | Yes |
| GET | `/users/{user_id}/resource-sharing-requests/{request_id}` | Retrieve borrowing request | Yes |
| DELETE | `/users/{user_id}/resource-sharing-requests/{request_id}` | Cancel borrowing request | Yes |
| POST | `/users/{user_id}/resource-sharing-requests/{request_id}?op=update_shipping` | Update shipping cost / fund | Yes |

(Corrected 2026-11-12, RS-18: `/partners/{partner_code}/borrowing-requests` does not exist in
`partners.json`; borrowing requests are patron-side, in `users.json`. AlmaAPITK implements them
on `Users`, see above.)

<!-- moved from alma-api-expert/references/endpoint_reference.md -->
### Creating Lending Requests
```
POST /partners/{partner_code}/lending-requests
```
