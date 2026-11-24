<!-- moved from alma-api-expert/references/bibs_api.md -->
# Bibs API Reference

## Overview

The Alma Bibs (Bibliographic Records) API provides operations for managing bibliographic records, holdings, and items. This includes catalog records (MARC), physical and electronic holdings, and item-level data.

**Base URL**: `https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/`

**Official Documentation**: https://developers.exlibrisgroup.com/alma/apis/bibs/

## Key Endpoints

### Bibliographic Records

**List / Multi-Fetch Bibs (identifier-only — no keyword search)**
```
GET /almaws/v1/bibs
```
- Retrieves one or more bib records by **identifier**. This is **not** a keyword-search endpoint.
- **Required**: at least one identifier parameter from the list below. Calling with no identifier (or with a `q=` parameter) returns `HTTP 400 / errorCode 401873`.
- Query parameters:
  - `mms_id` — comma-separated list of MMS IDs (up to 100)
  - `ie_id` — IE identifier (IEP, IED, …)
  - `holdings_id` — Holdings ID
  - `representation_id` — Representation ID
  - `nz_mms_id` — Network Zone MMS ID
  - `cz_mms_id` — Community Zone MMS ID
  - `other_system_id` — additional ID stored as part of the record's network numbers (e.g., OCLC)
  - `lod_uri` — URI of the BIBFRAME record
  - `view` — `brief` to skip the full MARC body
  - `expand` — comma-separated: `p_avail,e_avail,d_avail,requests`
- **For keyword/free-text search**: use the **SRU endpoint** (`/view/sru/{institution_code}`) with CQL queries against indexes like `alma.title`, `alma.author`, `alma.mms_id`. There is no REST equivalent.
- **See also**: `api_quirks_and_gotchas.md` → "`/bibs` is identifier-only — no keyword search".

**Get Bib Record**
```
GET /almaws/v1/bibs/{mms_id}
```
- Retrieves bibliographic record in MARC XML format
- `mms_id` - MMS ID (bibliographic record identifier)
- Query parameters:
  - `view` - "full" (default) or "brief"
  - `expand` - Optional expansions (p_avail, e_avail, d_avail)

**Update Bib Record**
```
PUT /almaws/v1/bibs/{mms_id}
```
- Updates bibliographic record
- Requires complete MARC XML in request body
- Content-Type: application/xml

**Create Bib Record**
```
POST /almaws/v1/bibs
```
- Creates new bibliographic record
- Requires MARC XML with mandatory fields
- Query parameters:
  - `from_nz_mms_id` - Copy from Network Zone record
  - `normalization` - Apply normalization rules
  - `validate` - Validate MARC record

### Holdings

**Get Holdings List**
```
GET /almaws/v1/bibs/{mms_id}/holdings
```
- Returns all holdings for a bibliographic record
- Holdings represent physical or electronic collections

**Get Holding Record**
```
GET /almaws/v1/bibs/{mms_id}/holdings/{holding_id}
```
- Retrieves specific holding record
- Returns holding data including location and call number

**Create Holding**
```
POST /almaws/v1/bibs/{mms_id}/holdings
```
- Creates new holding record
- Requires holding data with location and library

**Update Holding**
```
PUT /almaws/v1/bibs/{mms_id}/holdings/{holding_id}
```
- Updates holding record
- Requires complete holding object

### Items

**Get Items List**
```
GET /almaws/v1/bibs/{mms_id}/holdings/{holding_id}/items
```
- Returns all items for a holding
- Items represent physical pieces

**Get Item**
```
GET /almaws/v1/bibs/{mms_id}/holdings/{holding_id}/items/{item_pid}
```
- Retrieves specific item record
- `item_pid` - Item persistent identifier
- Query parameters:
  - `view` - default `brief`; the only other documented value is `label` (adds label-printing fields) (corrected 2026-11-12, see evaluation BI-13)
  - `expand` - `due_date_policy`, `due_date`

**Get Item by Barcode**
```
GET /almaws/v1/items?item_barcode={barcode}
```
- Documented shorthand: Alma answers with HTTP 302 to the full `/bibs/{mms_id}/holdings/{holding_id}/items/{item_pid}` URL (the redirect counts as a separate request against the daily threshold). Unknown barcode: HTTP 400 "No items found for barcode …". (corrected 2026-11-12, see evaluation BI-16)

**Create Item**
```
POST /almaws/v1/bibs/{mms_id}/holdings/{holding_id}/items
```
- Creates new item record
- Requires item data with barcode and policy

**Update Item**
```
PUT /almaws/v1/bibs/{mms_id}/holdings/{holding_id}/items/{item_pid}
```
- Updates item record
- Requires complete item object

**Scan In Item**
```
POST /almaws/v1/bibs/{mms_id}/holdings/{holding_id}/items/{item_pid}?op=scan
```
- Simulates UI "Scan In Items" operation
- **Required Query Parameter**: `op=scan`
- **Query Parameters**:
  - `library` - Library code (mandatory)
  - `circ_desk` **or** `department` - send exactly one of them (where the scan happens) (corrected 2026-11-12, see evaluation BI-20)
  - `work_order_type` - Work order type code (optional)
  - `status` - Work order status (optional)
  - `done` - Mark work order complete (true/false); only relevant when `department` is sent
  - Also documented: `confirm`, `external_id`, `request_id`, `auto_print_slip`, `place_on_hold_shelf`, `register_in_house_use`. Send only parameters that appear on the matching UI scan-in page.
- **Content-Type**: `application/xml`
- **Request Body**: Empty `<item/>` or item object (the OpenAPI spec defines no request body; AlmaAPITK posts an empty body — see evaluation BI-22)
- **Effect**:
  - Places item in department with work order
  - Prevents automatic "in transit" status
  - Useful after receiving to keep item in acquisitions

### Representations

Digital representations manage files associated with bibliographic records (scanned materials, digital assets, etc.).

**Get Representations**
```
GET /almaws/v1/bibs/{mms_id}/representations
GET /almaws/v1/bibs/{mms_id}/representations/{representation_id}
```
- Returns all or specific digital representations
- Includes metadata and file information

**Create Representation**
```
POST /almaws/v1/bibs/{mms_id}/representations
```
- Creates new digital representation
- Required: library code, usage type, access rights policy

**Get Representation Files**
```
GET /almaws/v1/bibs/{mms_id}/representations/{representation_id}/files
GET /almaws/v1/bibs/{mms_id}/representations/{representation_id}/files/{file_id}
```
- Returns files linked to representation
- Supports pagination

**Link File to Representation**
```
POST /almaws/v1/bibs/{mms_id}/representations/{representation_id}/files
```
- Links uploaded file (from S3) to representation
- Requires S3 path where file is stored

**→ See Digital Representations API (`alma-digital` skill) for:**
- Complete endpoint reference
- AWS S3 integration guide
- Configuration patterns
- Batch upload workflows
- Troubleshooting guide

## Data Structures

### Bibliographic Record Structure

**Key Fields**:
- `mms_id`: string - Bibliographic record identifier (9 + check digit)
- `record`: object - MARC XML record data
  - `leader`: MARC leader
  - `controlfield`: Control fields (001-009)
  - `datafield`: Data fields with indicators and subfields
- `title`: string - Brief title (extracted from MARC)
- `author`: string - Brief author (extracted from MARC)
- `issn`: string - ISSN for serials
- `isbn`: string - ISBN for monographs
- `network_number`: array - Network identifiers (OCLC, etc.)
- `place_of_publication`: string
- `publisher_const`: string - Publisher
- `date_of_publication`: string - Publication date

### Holding Record Structure

**Key Fields**:
- `holding_id`: string - Holding identifier
- `library`: object - Library code
  - `value`: Library code
  - `desc`: Library description
- `location`: object - Location code
  - `value`: Location code
  - `desc`: Location description
- `call_number`: string - Call number
- `call_number_type`: object - Call number type
- `copy_id`: string - Copy identifier
- `in_temp_location`: boolean - Temporary location flag
- `temp_library`: object - Temporary library (if applicable)
- `temp_location`: object - Temporary location (if applicable)

### Item Record Structure

The item object has three blocks: `bib_data` (output), `holding_data` and `item_data`. The identifier,
barcode, library, location and process type live **inside `item_data`**, not at the top level
(corrected 2026-11-12, see evaluation BI-25):
- `item_data.pid`: string - Item persistent identifier (output only)
- `holding_data.holding_id`: string - Parent holding ID
- `item_data.barcode`: string - Item barcode (optional on POST/PUT: Alma generates one from its barcode rules if omitted)
- `item_data.library` / `item_data.location`: objects with `value` (code) and `desc`. On PUT, changing them can move the item to another holding or create one.
- `item_data`: object - Item details
  - `physical_material_type`: object - Material type
  - `policy`: object - Item policy
  - `enumeration_a`: string - Enumeration (e.g., "v.1")
  - `enumeration_b`: string - Additional enumeration
  - `chronology_i`: string - Chronology (e.g., "2024")
  - `chronology_j`: string - Additional chronology
  - `description`: string - Item description
  - `base_status`: object - Base status
  - `internal_note_1`: string - Internal note
  - `internal_note_2`: string - Internal note
  - `internal_note_3`: string - Internal note
  - `public_note`: string - Public note
  - `statistics_note_1`: string - Statistics note
  - `statistics_note_2`: string - Statistics note
  - `statistics_note_3`: string - Statistics note
- `item_data.process_type`: object `{value, desc}` - code from the `PROCESSTYPE` code table (e.g. `ACQ`, `TRANSIT`, `WORK_ORDER_DEPARTMENT`, `LOAN`; empty when none) (corrected 2026-11-12, see evaluation BI-27)
- `receiving_operator`: string - User who received item
- `arrival_date`: date - Date the item was received (empty = not received). `receiving_date` was absent on Sandbox items read 12 Nov 2026; use `arrival_date` (corrected 2026-11-13)
- `expected_arrival_date`: date - Expected receipt date from the order
- `inventory_date`: date - Last inventory date
- `alternative_call_number`: string - Alternative call number
- `alt_number_source`: string - Source of alt number
- `storage_location_id`: string - Remote storage location
- `pages`: string - Number of pages
- `pieces`: string - Number of pieces
- `public_note`: string - Public note (item level)
- `fulfillment_note`: string - Fulfillment note
- `internal_note_1`: string - Internal note
- `internal_note_2`: string - Internal note
- `internal_note_3`: string - Internal note

## Common Operations

### Get Item by Barcode

**Pattern** (corrected 2026-11-12, see evaluation BI-16) — there is no `search_items` method or `barcode~` item search;
use the documented barcode route:
```python
item = client.get("almaws/v1/items", params={"item_barcode": barcode}).json()
mms_id = item['bib_data']['mms_id']
holding_id = item['holding_data']['holding_id']
item_pid = item['item_data']['pid']
```

**Note**: The response is a single item object with embedded bib and holding data (Sandbox-confirmed 2026-11-12).

### Scan In Item to Department

**Pattern**:
```python
# After receiving item from acquisitions
result = bibs.scan_in_item(
    mms_id=mms_id,
    holding_id=holding_id,
    item_pid=item_pid,
    library="MAIN",
    department="ACQ",
    work_order_type="AcqWorkOrder",
    status="CopyCataloging",
    done=False
)
```

**Use Case**: Prevents item from going "in transit" after receiving, keeps in department for processing.

**Configuration Requirements**:
- Work order types must be configured in Alma
- Path: Configuration > Fulfillment > Physical Fulfillment > Work Order Types
- Common types: `AcqWorkOrder`, `CatalogingWorkOrder`, `ConservationWorkOrder`

### Update Item Location

AlmaAPITK has no `get_item`/`update_item`; use `bibs.get_items(mms_id, holding_id, item_id=item_pid)` and a
raw `client.put(...)` on the item URL (corrected 2026-11-12, see evaluation BI-33).

**Pattern**:
```python
# Get item
item_data = bibs.get_item(mms_id, holding_id, item_pid)

# Update location
item_data['item_data']['location'] = {"value": "NEW_LOC"}

# Save changes
bibs.update_item(mms_id, holding_id, item_pid, item_data)
```

### Create Item with Barcode

**Pattern**:
```python
# barcode belongs inside item_data (corrected 2026-11-12, see evaluation BI-25)
item_data = {
    "item_data": {
        "barcode": "2239409-11",
        "physical_material_type": {"value": "BOOK"},
        "policy": {"value": "STANDARD"},
        "description": "Copy 1"
    }
}

result = bibs.create_item(mms_id, holding_id, item_data)
```

## Validation Rules

**Mandatory Fields (Item Creation)**:
- `holding_data` and `item_data` blocks are required by the schema; `item_data.barcode` is optional (Alma generates one) (corrected 2026-11-12, see evaluation BI-29)
- `item_data.physical_material_type` - Material type code
- `item_data.policy` - Item policy code

**Field Constraints**:
- `barcode`: Must be unique across institution
- `mms_id`: numeric; this institution's IDs are 18 digits starting `99` and ending with the institution's suffix (corrected 2026-11-12, see evaluation BI-31)
- `item_pid`: System-generated, read-only
- `library`: Must exist in configuration
- `location`: Must exist in library configuration
- `physical_material_type`: Must exist in configuration
- `policy`: Must exist in configuration

## Error Codes

Unverified: of these codes only `40166411` ("Param value is invalid") appears in the official spec;
the others are unresolved (evaluation BI-32).

| Code | Message | Cause | Solution |
|------|---------|-------|----------|
| 401861 | Bib not found | Invalid MMS ID | Verify MMS ID exists |
| 401689 | Holding not found | Invalid holding ID | Verify holding exists |
| 401694 | Item not found | Invalid item PID | Verify item exists |
| 401660 | Barcode already exists | Duplicate barcode | Use unique barcode |
| 401674 | Invalid library code | Library not configured | Verify library code |
| 401675 | Invalid location code | Location not configured | Verify location exists |
| 40166411 | Invalid parameter value | Invalid query param | Check parameter format |

## Important Notes

### MMS ID Structure
- Format: numeric, starts `99`, ends with the institution suffix (4 digits, fixed per institution); observed IDs are 18 digits, e.g. "990000000000000002" (corrected 2026-11-12, see evaluation BI-31)

### Item Hierarchy
```
Bibliographic Record (MMS ID)
  └── Holdings (Holding ID)
        └── Items (Item PID)
```

**All item operations require MMS ID + Holding ID + Item PID.**

### Item Process Types

| Process Type | Meaning | Typical State |
|--------------|---------|---------------|
| `ACQ` | In acquisitions workflow | Before receiving |
| `TRANSIT` | Moving between locations | After receiving (default) |
| `WORK_ORDER_DEPARTMENT` | In department work queue ("In Process") | After scan-in |
| `LOAN` | On loan to patron | Checked out |

Codes from the `PROCESSTYPE` code table (also `MISSING`, `LOST_LOAN`, `HOLDSHELF`, `REQUESTED`, `ILL`, …) (corrected 2026-11-12, see evaluation BI-27).

### Item Statuses

**Base Status** values:
- `0` - Item not in place (default for acquisition)
- `1` - Item in place
- No other values: the `BaseStatus` code table has only 0 and 1. Missing/lost are process types (corrected 2026-11-12, see evaluation BI-28)

### Scan-In Operation

The scan-in operation (`op=scan`) simulates the UI "Scan In Items" function:

**When to Use**:
- After receiving items from acquisitions
- To place items in department work queues
- To prevent automatic "in transit" status
- To add items to cataloging or processing workflows

**Query Parameters**:
- `library` (mandatory) - Library code where item is scanned
- `department` or `circ_desk` - exactly one is required (corrected 2026-11-12, see evaluation BI-20)
- `work_order_type` (optional) - Work order type code
- `status` (optional) - Initial work order status
- `done` (optional) - Mark work order complete immediately

**Example Use Cases**:
1. **Receive and catalog**: Scan into cataloging department with CatalogingWorkOrder
2. **Receive and process**: Scan into acquisitions with AcqWorkOrder/Processing
3. **Complete work order**: Scan with `done=true` to complete and return to shelf

## Related Endpoints

- **Holdings**: Holdings records and locations
- **Portfolios**: Electronic holdings
- **Representations**: Digital representations
- **Linked Records**: Related bibliographic records
- **Requests**: Item-level requests

## AlmaAPITK Implementation

The Bibs domain class is located at: `src/domains/bibs.py`

Class `BibliographicRecords` in `src/almaapitk/domains/bibs.py` (corrected 2026-11-12, see evaluation BI-33).

**Available Methods** (AlmaAPITK de2013d):
- `get_record(mms_id, view="full", expand=None)` - Retrieve bibliographic record
- `get_holdings(mms_id, holding_id=None)` - Holdings list, or one holding
- `create_holding(mms_id, holding_data)`
- `get_items(mms_id, holding_id="ALL", item_id=None)` - Items list, or one item
- `create_item(mms_id, holding_id, item_data)`
- `scan_in_item(mms_id, holding_id, item_pid, library, department=None, circ_desk=None, work_order_type=None, status=None, done=False, confirm=True)` - Scan in item; raises if neither department nor circ_desk
- No `update_item`, `get_item`, `search_items` or barcode lookup method.

## Testing

Unit tests (mocked): `tests/unit/domains/test_bibs.py` — run with `poetry run pytest tests/unit/domains/test_bibs.py`. There is no `src/tests/test_bibs.py` (corrected 2026-11-12, see evaluation BI-33).

## Related AlmaAPITK Workflows

**Receive and Keep in Department**:
```python
# Combined workflow (acquisitions + bibs)
result = acq.receive_and_keep_in_department(
    pol_id=pol_id,
    item_id=item_id,
    mms_id=mms_id,
    holding_id=holding_id,
    library="MAIN",
    department="ACQ",
    work_order_type="AcqWorkOrder",
    work_order_status="Processing"
)
```

This method combines:
1. `acq.receive_item()` - Receive item via acquisitions API
2. `bibs.scan_in_item()` - Scan item into department

**Result**: Item is received AND stays in department (prevents "in transit").

---

**Related References**:
- Acquisitions API (`alma-acquisitions-specialist` skill) - For POL and receiving operations
- [Error Codes](../../alma-api-expert/references/error_codes_and_solutions.md) - Complete error reference
- [Data Structures](../../alma-api-expert/references/data_structures.md) - Detailed structure documentation

<!-- moved from alma-api-expert/references/endpoint_reference.md -->
## Bibs API Endpoints

### Bibliographic Records

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| GET | `/bibs/{mms_id}` | Retrieve bib record | Yes |
| POST | `/bibs` | Create bib record | Yes |
| PUT | `/bibs/{mms_id}` | Update bib record | Yes |
| DELETE | `/bibs/{mms_id}` | Delete bib record | Yes |

### Holdings

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| GET | `/bibs/{mms_id}/holdings` | List holdings | Yes |
| GET | `/bibs/{mms_id}/holdings/{holding_id}` | Get holding | Yes |
| POST | `/bibs/{mms_id}/holdings` | Create holding | Yes |

### Items

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| GET | `/bibs/{mms_id}/holdings/{holding_id}/items` | List items | Yes |
| GET | `/bibs/{mms_id}/holdings/{holding_id}/items/{item_pid}` | Get item | Yes |
| POST | `/bibs/{mms_id}/holdings/{holding_id}/items` | Create item | Yes |
| POST | `/bibs/{mms_id}/holdings/{holding_id}/items/{item_pid}?op=scan` | Scan in item | Yes |

**Scan Operation Parameters**:
- `op=scan`: Required for scan operation
- `library`: Library code
- `circ_desk` or `department`: exactly one (work-order parameters and `done` go with `department`) (corrected 2026-11-12, see evaluation BI-21)
- `work_order_type`: Work order type
- `status`: Work order status
- `done`: Boolean - mark work order done

**Example**:
```
POST /almaws/v1/bibs/990000000000000002/holdings/20000000000000003/items/20000000000000001?op=scan&library=MAIN&department=ACQ&work_order_type=AcqWorkOrder&status=CopyCataloging&done=false
```

<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
### `/bibs` is identifier-only — no keyword search

**Endpoint**: `GET /almaws/v1/bibs` (the list/multi-fetch variant, not `/bibs/{mms_id}`).

**Quirk**: This endpoint does **not** accept a free-form `q=` parameter. It only takes identifier params (and a couple of view/expand controls):

| Parameter | Type | Notes |
|-----------|------|-------|
| `mms_id` | string | Comma-separated list of MMS IDs, up to 100 |
| `ie_id` | string | IE identifier (IEP, IED, …) |
| `holdings_id` | string | Holdings ID |
| `representation_id` | string | Representation ID |
| `nz_mms_id` | string | Network Zone MMS ID |
| `cz_mms_id` | string | Community Zone MMS ID |
| `other_system_id` | string | An additional ID stored as part of the record's network numbers |
| `lod_uri` | string | URI of the BIBFRAME record |
| `view` | string | `brief` to skip the full MARC body |
| `expand` | string | Comma-separated: `p_avail,e_avail,d_avail,requests` |

**What you get if you pass `q=`**:
```
HTTP 400
errorCode: 401873
errorMessage: "Request failed: Parameter missing.
Try one of the following: mms_id, holdings_id, ie_id,
representation_id, nz_mms_id, cz_mms_id, other_system_id."
```

**Why this matters**: Other Alma list endpoints (`/users`, `/acq/invoices`, `/acq/po-lines`, `/conf/sets`, …) DO accept `q=`, so it's tempting to assume `/bibs` does too. It doesn't — historically, several callers have written `bibs?q=alma_mms_id=*` style queries against this endpoint and they all fail. The `q=` pattern was inherited from a misreading of the docs; there is no REST keyword endpoint for bibs.

**Use this instead**:

```python
# ✅ Multi-fetch by known MMS IDs
client.get("almaws/v1/bibs", params={"mms_id": "991234,991235"})

# ✅ Lookup by other_system_id (e.g., OCLC)
client.get("almaws/v1/bibs", params={"other_system_id": "(OCoLC)1234567"})

# ❌ Won't work — there is no q= for /bibs
client.get("almaws/v1/bibs", params={"q": "title~Harry Potter"})
```

**For real keyword search**: use the SRU endpoint (`/view/sru/{institution_code}`) — that's what the Ex Libris docs explicitly steer you to. SRU supports indexes like `alma.title`, `alma.author`, `alma.mms_id`, etc., via CQL queries.

**Related project notes** (historical — `search_records()` no longer exists in AlmaAPITK de2013d; corrected 2026-11-12, see evaluation BI-34): `BibliographicRecords.search_records()` in `src/almaapitk/domains/bibs.py` was historically built around a `q` parameter — it's been broken at the live API since inception (the unit-test suite mocked the response shape but never exercised the real 400). Discovered via SANDBOX smoke t-11-3 in chunk `pagination-helper`. Treat as an R10 bug-driven fix candidate: drop the `q` signature, replace with identifier-based lookup or route through SRU.
