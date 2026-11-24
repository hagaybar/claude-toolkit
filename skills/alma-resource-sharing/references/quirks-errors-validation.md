<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md (summary table) -->
## User-side (borrowing) quirks

| Quirk | Severity | Detail |
|---|---|---|
| User-side BR create: partner NOT required | HIGH | `POST /almaws/v1/users/{user_id}/resource-sharing-requests` does NOT require a `partner` field at create time, despite folklore that says it does. Proven empirically across 11 SANDBOX experiments (2026-05-13): with `partner` absent, Alma's validation chain never raised a partner-related error. The *actual* gate is `pickup_location.value` — it must be a library code configured as a valid Borrowing-Request pickup location for the request's `owner` (RS library). An invalid pickup code returns `alma_code 401929 "The library selected is not a valid pickup location."` and a missing `owner` returns `alma_code 401607 "Resource sharing library (owner) is missing"`. Partner attachment happens later, during the Locate / Send Request workflow steps — not at Create. **Implication**: testing BR create against SANDBOX requires only a valid `owner` + valid `pickup_location.value` + bib metadata (`title` or `mms_id`) + `format` + `citation_type`. No partner-policy clearance needed. The valid pickup-library code lives in Alma UI (path varies by tenant + Alma version; the authoritative answer is the API endpoint `GET /almaws/v1/users/{user_id}/requests?allow_pickup_locations=true` — if it returns `total_record_count: 0`, no pickup mapping exists for that user) — not in the generic `Configuration.list_libraries()` enumeration. |
| `update_shipping` action params both optional | LOW | `POST /almaws/v1/users/{user_id}/resource-sharing-requests/{request_id}?op=update_shipping` accepts BOTH `shipping_cost` and `fund_code` as query params, but the Alma swagger marks **both as `required=False`**. Either can be passed independently, both, or neither (no-op-but-valid). The Python wrapper (`Users.perform_user_rs_request_action`) declares them `Optional[str] = None` and forwards only the non-None values. Documented error codes when one IS provided: `40166411` "Parameter value is invalid", `40166425` "Shipping cost cannot be lower than 0", `40166426` "Parameter value is invalid (with error message)". **Implication**: tests / scripts can update one field without supplying the other — useful when the operator knows a fund_code but not a shipping cost, or vice-versa. Confirmed 2026-05-18 against the official users.json swagger. |

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
### Owner Field Format (Resource Sharing)

**⚠️ CRITICAL**: `owner` is a plain string — unlike its wrapped neighbours.

(Corrected 2026-11-12, RS-02: the schema is *not* wrong. The JSON schema defines `owner` as
`string` and the XSD as `<xs:element name="owner" type="xs:string">`; the
`<owner value=... desc=...>` form previously quoted here is not in the official XSD.)

**What Developers Expect** (by analogy with `partner`/`format`):
```python
{"owner": {"value": "MAIN"}}  # Wrapped format
```

**Reality**:
```python
# ❌ Using wrapped format causes 400 error:
# "Cannot deserialize value of type `java.lang.String` from Object value"

# ✅ Must use plain string:
{"owner": "MAIN"}
```

**Consistency Check**:
- **CREATE**: Plain string required
- **RETRIEVE**: Plain string returned
- **UPDATE**: Plain string required (when implemented)

**Other Resource Sharing Fields** (correct wrapping):
```python
{
    "owner": "MAIN",                      # Plain (exception!)
    "partner": {"value": "RELAIS"},       # Wrapped (correct)
    "format": {"value": "PHYSICAL"},      # Wrapped (correct)
    "citation_type": {"value": "BOOK"}    # Wrapped (correct)
}
```

**Why This Matters**:
- Wrapped format seems correct by analogy with the neighbouring code-table fields
- Error message is cryptic about the real issue
- Wastes hours debugging before discovering schema error

**Discovered**: 2025-12-24 through SANDBOX testing with request ID 10000000000000016

**See Also**: [Resource Sharing API - Owner Field Quirk](resource-sharing-api.md#owner-field-format-error-in-schema)

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
### Requested Media Field (Resource Sharing)

**Plain string, as documented** (corrected 2026-11-12, RS-09): the schema and XSD define
`requested_media` as a string (codes 1-7 plus `AdditionalRequestedMedia`); Sandbox GETs return
it as a plain string (e.g. `"7"`). Note AlmaAPITK `create_lending_request` wraps a string
`requested_media` into `{"value": ...}` — avoid passing it through that method until fixed.

```python
# What you might expect from schema:
{"requested_media": {"value": "7", "desc": "Microform"}}

# What actually works:
{"requested_media": "7"}  # Plain string code
```

**Note**: This field is optional, so impact is lower than `owner` field issue.

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
#### Resource Sharing Operational Fields

(Corrected 2026-11-12, RS-12: these are all documented in the GET schema
`rest_user_resource_sharing_request.json`; they are output fields, not undocumented.)

**Operational Metadata**:
```python
{
    "printed": false,           # Request printed status
    "reported": false,          # Request reported status
    "has_active_notes": true,   # Quick check without parsing notes array
    "created_time": "2025-08-20T05:42:24.143Z",      # Precise timestamp
    "last_modified_time": "2025-09-18T11:10:20.491Z" # Precise modification time
}
```

**Item Integration**:
```python
{
    "barcode": "2239409-10",              # Physical item barcode (very useful!)
    "mms_id": "990000000000000002",       # Links request to catalog
    "text_email": "partner@example.edu"   # Contact email
}
```

**Fulfillment Details**:
```python
{
    "supplied_format": {           # What was actually supplied
        "value": "PHYSICAL",
        "desc": "Physical"
    },
    "shipping_cost": {
        "sum": 0,
        "currency": {"value": "ILS", "desc": "New Israeli Sheqel"}
    }
}
```

**Why These Matter**:
- `barcode`: Links request to physical item for tracking
- `text_email`: Enables automated partner communication
- `supplied_format`: Tracks format substitutions (requested DIGITAL, supplied PHYSICAL)
- `has_active_notes`: Avoids parsing notes array just to check if any exist
- `*_time`: Precise timestamps for audit trails

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
### Partner Codes (Resource Sharing)

**Display Name vs Internal Code**:
```python
{
    "partner": {
        "value": "ANC",           # ← Use THIS in API calls
        "desc": "ANCA-TEST",      # Display name only
        "link": "https://..."
    }
}
```

**Common Mistake**:
```python
# ❌ WRONG - Using display name
partner_code = request['partner']['desc']  # "ANCA-TEST"

# ✅ CORRECT - Using internal code
partner_code = request['partner']['value']  # "ANC"
```

**Why This Matters**:
- API requires internal code
- Display names can change
- Display names may contain spaces/special chars
- Internal codes are stable identifiers

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
### Format Values (Resource Sharing)

**Controlled by RequestFormats Code Table**:
- `PHYSICAL` - Physical item
- `DIGITAL` - Digital/electronic delivery
- `PHYSICAL_NON_RETURNABLE` (present in Sandbox table 2026-11-12)
- Other values based on configuration

**Must Exist in Configuration**:
- Path: Configuration > Resource Sharing > Code Tables > RequestFormats
- Custom values can be added by institution
- Values are case-sensitive

<!-- moved from alma-api-expert/references/error_codes_and_solutions.md -->
## Resource Sharing Errors

### Error 400 - Owner Field Format

**Full Error**:
```
Error 400: Cannot deserialize value of type `java.lang.String` from Object value
```

**When It Occurs**:
Using wrapped object format for `owner` field in lending request creation.

**Root Cause**:
`owner` sent wrapped. The API requires a plain string — which is what the official JSON schema
and XSD define (corrected 2026-11-12, RS-02; the documentation is not incorrect). This 400 body
is historical (2025-12-24) and was not re-run in this evaluation.

**Wrong** (Causes Error):
```python
# ❌ WRONG - Wrapped format causes 400 error
request_data = {
    "owner": {"value": "MAIN"}
}
```

**Actual Required Format**:
```python
# ✅ CORRECT - Plain string required
request_data = {
    "owner": "MAIN"
}
```

**Correct Field Formats**:
```python
{
    "owner": "MAIN",                      # Plain string (critical!)
    "partner": {"value": "RELAIS"},       # Wrapped (correct)
    "format": {"value": "PHYSICAL"},      # Wrapped (correct)
    "citation_type": {"value": "BOOK"}    # Wrapped (correct)
}
```

**Prevention**:
- Always use plain string for `owner` field
- Test in SANDBOX before production
- Use `create_lending_request()` method which handles this correctly

**See Also**: [Resource Sharing API - Owner Field Quirk](resource-sharing-api.md#owner-field-format-error-in-schema)

### Error 400 - Partner Not Found

**Full Error** (corrected 2026-11-12, RS-20 — HTTP 400, not 404):
```
HTTP 400: Partner not found
```
Swagger: `402118 'Partner not found.'` (400) on `GET /partners/{partner_code}`; Sandbox returned
HTTP 400 "Partner not found" for an unknown code. The status on a lending *create* with an
unknown partner was not tested.

**When It Occurs**:
- Partner code doesn't exist in Alma configuration
- Partner code is misspelled or has wrong case
- Partner has been deleted or deactivated

**Verification**:
1. Check Configuration > Resource Sharing > Partners
2. Verify partner code matches exactly (case-sensitive)
3. Confirm partner is active and not deleted
4. Check partner code in both SANDBOX and PRODUCTION (may differ)

**Example**:
```python
# ❌ WRONG - Partner doesn't exist
request = rs.create_lending_request(
    partner_code="INVALID_PARTNER",  # Not configured
    ...
)

# ✅ CORRECT - Verify partner exists first
# In Alma: Configuration > Resource Sharing > Partners
# Partner code: RELAIS (active)
request = rs.create_lending_request(
    partner_code="RELAIS",
    ...
)
```

**Prevention**:
- Maintain list of valid partner codes
- Validate partner code before API call
- Use consistent partner codes across environments

### Client-side ValueError - Validation Failed (Lending Request)

**Full Error** (corrected 2026-11-12, RS-26: raised by AlmaAPITK before any request is sent, not
an HTTP 400; text per AlmaAPITK de2013d):
```
ValueError: Validation failed for lending request:
  - {field} is mandatory ...
```

**When It Occurs**:
Creating lending request with missing mandatory fields.

**Mandatory Fields**:
- `external_id` - Always required
- `owner` - Always required
- `partner` - Always required (via partner_code parameter)
- `format` - Always required
- `citation_type` - Required UNLESS mms_id provided
- `title` - Required UNLESS mms_id provided

**Common Mistakes**:
```python
# ❌ WRONG - Missing external_id
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id="",  # Empty string
    owner="MAIN",
    format_type="PHYSICAL",
    title="Example Book"
)

# ❌ WRONG - Missing title when no mms_id
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id="EXT-001",
    owner="MAIN",
    format_type="PHYSICAL"
    # No title, no mms_id - will fail!
)

# ✅ CORRECT - All mandatory fields
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id="EXT-001",
    owner="MAIN",
    format_type="PHYSICAL",
    title="Example Book",
    citation_type="BOOK"
)

# With mms_id: Alma makes title and citation_type optional, BUT AlmaAPITK's
# create_lending_request has `title` as a required argument (TypeError without it), and it
# sends mms_id wrapped although the schema defines a string (corrected 2026-11-12, RS-08/RS-25).
# Untested live; build the body by hand with "mms_id": "<plain string>" if needed.
request = rs.create_lending_request(
    partner_code="RELAIS",
    external_id="EXT-001",
    owner="MAIN",
    format_type="PHYSICAL",
    title="Example Book",
    mms_id="991234567890123456"
)
```

**Prevention**:
- Use `_validate_lending_request_data()` validation before API call
- ResourceSharing domain includes built-in validation
- Check for empty strings, not just None values

**See Also**: [Resource Sharing API - Validation Rules](resource-sharing-api.md#validation-rules)

<!-- moved from alma-api-expert/references/validation_and_required_fields.md -->
## Resource Sharing Validation

### Create Lending Request

**Mandatory Fields**:
```python
{
    "external_id": str,         # External system ID (mandatory)
    "owner": str,               # Library code (mandatory, PLAIN STRING!)
    "partner": {                # Partner institution (mandatory)
        "value": str            # Partner code
    },
    "format": {                 # Request format (mandatory)
        "value": str            # PHYSICAL or DIGITAL
    },
    # CONDITIONAL: If mms_id NOT provided:
    "citation_type": {          # Resource type (mandatory if no mms_id)
        "value": str            # BOOK or JOURNAL only (corrected 2026-11-12, RS-11)
    },
    "title": str                # Title (mandatory if no mms_id)
}
```

**Validation Rules**:

1. **external_id**:
   - Must be non-empty string
   - Should be unique identifier from external system
   - Example: "ILL-12345", "RAPIDO-001"

2. **owner** (⚠️ CRITICAL):
   - Must be PLAIN STRING (not wrapped object!)
   - Schema documentation agrees: string (corrected 2026-11-12, RS-02)
   - Must be valid resource sharing library code
   - Example: "MAIN" (not `{"value": "MAIN"}`)
   - **Error if wrapped**: Error 400 "Cannot deserialize value..."

3. **partner**:
   - Must be wrapped object with `value` key
   - Partner code must exist in configuration
   - Example: `{"value": "RELAIS"}`

4. **format**:
   - Must be wrapped object with `value` key
   - Valid values: "PHYSICAL", "DIGITAL" (controlled by RequestFormats code table)
   - Example: `{"value": "PHYSICAL"}`

5. **citation_type** (conditional):
   - Required UNLESS `mms_id` is provided
   - Must be wrapped object with `value` key
   - Valid values: "BOOK", "JOURNAL" (`PR_CitationType`; no ARTICLE etc. — corrected 2026-11-12, RS-11)
   - Example: `{"value": "BOOK"}`

6. **title** (conditional):
   - Required UNLESS `mms_id` is provided
   - Must be non-empty string
   - Example: "Introduction to Library Science"

7. **mms_id** (optional):
   - If provided, `citation_type` and `title` become optional
   - Plain string (corrected 2026-11-12, RS-08: schema/XSD `string`; Sandbox GETs return a string)
   - Example: `"991234567890123456"`

**Validation Logic**:
```python
def validate_lending_request(data):
    """Validate lending request data."""
    errors = []

    # Always required
    if not data.get('external_id'):
        errors.append("external_id is required and must be non-empty")

    if not data.get('owner'):
        errors.append("owner is required and must be non-empty")

    # Check owner format (critical!)
    if isinstance(data.get('owner'), dict):
        errors.append("owner must be plain string, not wrapped object")

    if not data.get('partner'):
        errors.append("partner is required")

    if not data.get('format'):
        errors.append("format is required")

    # Conditional requirements
    has_mms_id = bool(data.get('mms_id'))

    if not has_mms_id:
        if not data.get('citation_type'):
            errors.append("citation_type is required when mms_id not provided")

        if not data.get('title'):
            errors.append("title is required when mms_id not provided")

    if errors:
        raise ValueError(f"Validation failed: {'; '.join(errors)}")

    return True
```

**Optional But Commonly Used**:
```python
{
    "author": str,              # Author name
    "isbn": str,                # ISBN (for books)
    "issn": str,                # ISSN (for journals)
    "publisher": str,           # Publisher name
    "year": str,                # Publication date (no `publication_date` field — RS-10)
    "journal_title": str,       # Journal (article requests)
    "volume": str,              # Volume (journals)
    "issue": str,               # Issue (journals)
    "pages": str,               # Page range
    "doi": str,                 # Digital Object Identifier
    "level_of_service": {       # Service level
        "value": str            # LevelOfService code, e.g. RUSH_LOCAL (no "Rush" — RS-14)
    },
    "last_interest_date": str   # Need-by date (YYYY-MM-DDZ)
}
```

<!-- moved from alma-api-expert/references/validation_and_required_fields.md -->
### Built-in Validation (ResourceSharing)

```python
# ResourceSharing domain includes built-in validation
rs.create_lending_request(...)  # Validates before API call

# Validation happens in _validate_lending_request_data()
# Checks:
# - external_id non-empty
# - owner non-empty and plain string
# - partner non-empty
# - format non-empty
# - title or mms_id present
# - citation_type or mms_id present
```
