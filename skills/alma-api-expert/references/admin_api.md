# Admin API Reference (Configuration)

## Overview

The Alma Configuration (Admin) API provides access to administrative operations, primarily focused on **Sets** management. Sets are collections of records (bibliographic or user) used for batch operations and reports.

**Base URL**: `https://api-eu.hosted.exlibrisgroup.com/almaws/v1/conf/`

**Official Documentation**: https://developers.exlibrisgroup.com/alma/apis/conf/

## Key Endpoints

### Sets

Sets are collections of records used for batch processing. The content type fixes what a
member is; choose the type at the granularity the job acts on, not the most familiar one
(e.g. `BIB_MMS`, `USER`, `PO_LINE`, `ITEM`; full list below).

**Pick the content type that matches the unit of work.** A title (`BIB_MMS`) can have several
order lines, and each order line its own invoice, so a title set over-selects for acquisitions
work: use a `PO_LINE` set for order-line/invoice jobs. There is no invoice content type, so an
invoice job is driven by order lines (or a file of invoice numbers).

**Get Set**
```
GET /almaws/v1/conf/sets/{set_id}
```
- Retrieves set metadata (name, description, type, count)
- Does NOT include members - use get_set_members for member list
- Query parameters:
  - `view` - "full" (default) or "brief"

**Get Set Members**
```
GET /almaws/v1/conf/sets/{set_id}/members
```
- Returns list of set members (record IDs)
- Pagination: `limit` and `offset` parameters
- Default limit: 10, max: 100
- **Critical**: Use pagination for large sets (>100 members)

**Create Set**
```
POST /almaws/v1/conf/sets
```
- Creates new itemized set
- Validated in Sandbox 12 Nov 2026 (AlmaAPITK 0.4.5): `create_set({name, description, type: {value: ITEMIZED}, content: {value: BIB_MMS}, private: {value: "false"}})`, then `add_members_to_set(id, mms_ids)`. Members given in the create body were ignored (`number_of_members` 0, Sandbox 15 Nov 2026): always add them with `op=add_members` and read back (`POST /conf/sets/{id}?op=add_members`, body `{"members": {"member": [{"id": ...}]}}`); read-back showed `number_of_members.value` = 10 and the exact IDs
- Query parameters:
  - `from_id` - Copy from existing set
- Request body: Set object with metadata

**Update Set**
```
PUT /almaws/v1/conf/sets/{set_id}
```
- Updates set metadata
- Requires complete set object

**Delete Set**
```
DELETE /almaws/v1/conf/sets/{set_id}
```
- Removes set from system
- Does not delete the actual records, only the set

**Add Members to Set**
```
POST /almaws/v1/conf/sets/{set_id}/members
```
- Adds records to existing set
- Query parameters:
  - `id_type` - Type of identifier (for USER sets)
  - `fail_on_invalid_id` - Stop on invalid ID (true/false)
- Request body: Member object with ID

**Remove Member from Set**
```
DELETE /almaws/v1/conf/sets/{set_id}/members/{member_id}
```
- Removes specific member from set
- `member_id` - The record ID (MMS ID or User ID)

**Search Sets**
```
GET /almaws/v1/conf/sets
```
- Query parameters:
  - `q` - Query string for search
  - `content_type` - Filter by type (BIB_MMS, USER, etc.)
  - `limit` - Results per page
  - `offset` - Pagination offset

## Data Structures

### Set Object Structure

**Key Fields**:
- `id`: string - Set identifier (output only)
- `link`: string - API link to set (output only)
- `name`: string - Set name (mandatory)
- `description`: string - Set description
- `type`: object - Set type (mandatory)
  - `value`: Type code ("ITEMIZED", "LOGICAL")
  - `desc`: Type description
- `content`: object - Content type (mandatory)
  - `value`: Content code ("BIB_MMS", "USER", "ITEM", etc.)
  - `desc`: Content description
- `private`: boolean - Private set (true) or public (false)
- `created_by`: string - Creator username (output only)
- `created_date`: date - Creation date (output only)
- `number_of_members`: object - Member count (output only)
  - `value`: Integer count

**Set Types**:
- `ITEMIZED` - Manually defined list of records
- `LOGICAL` - Dynamically defined by query

**Content Types** (code table `SetContentType`, read in Sandbox 15 Nov 2026):
`BIB_MMS` (All Titles), `BIB_MMS_DISCOVERY`, `ITEM` (Physical items), `IEPA` (Electronic
collections), `FILE`, `REMOTE_REPRESENTATION`, `REPRESENTATION`, `AUTHORITY_MMS`, `IE`
(Inventory titles), `IEP` (Physical titles), `IEE` (Electronic titles), `IED`, `IEC`,
`PORTFOLIO`, `PO_LINE` (Order lines), `USER`, `VENDOR`, `HOLDING` (Physical holdings), `COURSE`,
`READING_LIST`, `READING_LIST_CITATION`, `IER`, `RESEARCHERS`, `BIB_BF_WORK`.
No invoice type exists. Read `GET /conf/code-tables/SetContentType` for the institution's list.

**Member Structure for PO_LINE Sets** (Sandbox 15 Nov 2026): `id` is the order-line number
(`"POL-01004"`), `description` the title. `op=add_members` accepts the numbers directly.

### Set Member Object Structure

**Key Fields**:
- `id`: string - Record identifier (MMS ID, User ID, etc.)
- `link`: string - API link to record
- `description`: string - Brief description (optional)

**Member Structure for BIB_MMS Sets**:
```json
{
  "id": "991234567890123456",
  "link": "https://.../almaws/v1/bibs/991234567890123456",
  "description": "Book Title"
}
```

**Member Structure for USER Sets**:
```json
{
  "id": "user123",
  "link": "https://.../almaws/v1/users/user123",
  "description": "John Doe"
}
```

## Common Operations

### Get All Set Members (with Pagination)

**Pattern**:
```python
def get_all_set_members(set_id):
    """Get all members from large set using pagination"""
    all_members = []
    limit = 100
    offset = 0

    while True:
        response = admin.get_set_members(set_id, limit=limit, offset=offset)
        members = response.get('member', [])

        if not members:
            break

        all_members.extend(members)
        offset += limit

        # Check if we got all members
        if len(members) < limit:
            break

    return all_members
```

**Important**: Always use pagination for sets with >100 members.

### Process User Set

**Pattern**:
```python
# Get set metadata
set_data = admin.get_set(set_id)
print(f"Processing set: {set_data['name']}")
print(f"Members: {set_data['number_of_members']['value']}")

# Get all members with pagination
members = get_all_set_members(set_id)

# Process each user
results = []
for member in members:
    user_id = member['id']

    try:
        # Get user data
        user_data = users.get_user(user_id)

        # Perform operation
        # ... update user ...

        results.append({'user_id': user_id, 'status': 'SUCCESS'})

    except Exception as e:
        results.append({'user_id': user_id, 'status': 'FAILED', 'error': str(e)})

return results
```

### Create Itemized Set

**Pattern**:
```python
set_data = {
    "name": "My New Set",
    "description": "Set of users for processing",
    "type": {"value": "ITEMIZED"},
    "content": {"value": "USER"},
    "private": False
}

# Create set
new_set = admin.create_set(set_data)
set_id = new_set['id']

# Add members
for user_id in user_ids:
    admin.add_set_member(set_id, user_id)
```

### Query Set by Name

**Pattern**:
```python
# Search for sets by name
query = f"name~My Set Name"
sets = admin.search_sets(query=query, content_type="USER")

if sets:
    set_id = sets[0]['id']
```

## Validation Rules

**Mandatory Fields (Set Creation)**:
- `name` - Set name
- `type` - Set type (ITEMIZED or LOGICAL)
- `content` - Content type (BIB_MMS, USER, etc.)

**Field Constraints**:
- `name`: Max 255 characters
- `description`: Max 4000 characters
- `type`: Must be valid type code
- `content`: Must be valid content type code
- `id`: System-generated, read-only

## Error Codes

| Code | Message | Cause | Solution |
|------|---------|-------|----------|
| 401861 | Set not found | Invalid set ID | Verify set ID exists |
| 401862 | Input validation error | Invalid field values | Check required fields |
| 401869 | Member not found | Invalid member ID | Verify member exists |
| 401870 | Cannot add member | Member already in set | Skip duplicate |
| 401871 | Set type not supported | Invalid set type | Use ITEMIZED or LOGICAL |

## Query Syntax (Set Search)

**Basic Queries**:
```
# By name (contains)
name~User Set

# By type
type~ITEMIZED

# By content
content~USER

# By creator
created_by~username

# Combined
name~Export AND content~BIB_MMS
```

**Operators**:
- `~` - Contains
- `=` - Equals
- `AND` - Logical AND
- `OR` - Logical OR

## Pagination

**Standard Pattern**:
```python
# Get first 100 members
members = admin.get_set_members(set_id, limit=100, offset=0)

# Get next 100 members
members = admin.get_set_members(set_id, limit=100, offset=100)
```

**Response Structure**:
```json
{
  "member": [
    {"id": "123", "link": "..."},
    {"id": "456", "link": "..."}
  ],
  "total_record_count": 250
}
```

**Key Points**:
- Default limit: 10
- Maximum limit: 100
- Use `total_record_count` to know when done
- Always implement pagination for production code

## Important Notes

### Set Member Count
- `number_of_members` in set object shows total count
- This is **metadata only** - members must be retrieved separately
- Use `get_set_members()` to get actual member list

### Set Types Comparison

| Feature | ITEMIZED | LOGICAL |
|---------|----------|---------|
| Definition | Manual list | Query-based |
| Members | Static | Dynamic |
| Updates | Manual | Automatic |
| Use Case | Fixed lists | Ongoing criteria |
| Performance | Fast | Depends on query |

**Example ITEMIZED Use Cases**:
- Export list for vendor
- User cohort for email update
- Collection assessment project

**Example LOGICAL Use Cases**:
- All items added this month
- Users expiring in 30 days
- E-resources by package

### Set Privacy

- **Private sets** (`private=true`): Visible only to creator
- **Public sets** (`private=false`): Visible to all staff

### Member ID Types (USER Sets)

When adding members to USER sets, specify `id_type`:
- `PRIMARY_ID` - Primary user identifier (default)
- `BARCODE` - User barcode
- `EXTERNAL_ID` - External system ID

## Related Operations

### Using Sets with Other APIs

**Pattern: Process Bib Set Records**:
```python
# Get BIB_MMS set
set_data = admin.get_set(set_id)
members = get_all_set_members(set_id)

# Process each bib
for member in members:
    mms_id = member['id']
    bib_data = bibs.get_bib(mms_id)
    # ... process bib ...
```

**Pattern: Process User Set Records**:
```python
# Get USER set
set_data = admin.get_set(set_id)
members = get_all_set_members(set_id)

# Process each user
for member in members:
    user_id = member['id']
    user_data = users.get_user(user_id)
    # ... process user ...
```

## AlmaAPITK Implementation

The Admin domain class is located at: `src/domains/admin.py`

**Available Methods**:
- `get_set(set_id)` - Retrieve set metadata
- `get_set_members(set_id, limit, offset)` - Get set members with pagination
- `create_set(set_data)` - Create new set
- `update_set(set_id, set_data)` - Update set metadata
- `add_set_member(set_id, member_id)` - Add member to set
- `remove_set_member(set_id, member_id)` - Remove member from set
- `search_sets(query, content_type, limit, offset)` - Search sets

## Example Scripts

- **update_expired_user_emails_2.py** - Processes USER sets
  - Demonstrates set member iteration
  - Handles pagination for large sets
  - Includes progress tracking and error handling

## Testing

Test script: `src/tests/test_sets_ret.py`

```bash
# Test set operations
python src/tests/test_sets_ret.py --environment SANDBOX --set-id <SET_ID>
```

## Performance Considerations

### Large Sets
- Sets with >1000 members: Use pagination with 100-item batches
- Process in batches to manage memory
- Include progress tracking for user visibility
- Consider rate limiting to avoid API throttling

### Error Handling
- Invalid member IDs: Continue processing remaining members
- API errors: Retry with exponential backoff
- Track failures for later review

### Progress Tracking
```python
total = set_data['number_of_members']['value']
processed = 0

for member in members:
    # ... process member ...
    processed += 1
    if processed % 10 == 0:
        print(f"Progress: {processed}/{total} ({processed*100//total}%)")
```

---

**Related References**:
- Users API (`alma-users` skill) - For processing USER sets
- Bibs API (`alma-bibs-inventory` skill) - For processing BIB_MMS sets
- [Pagination & Queries](pagination_and_queries.md) - Query syntax details
- [Error Codes](error_codes_and_solutions.md) - Complete error reference
