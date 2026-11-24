<!-- moved from alma-api-expert/references/users_api.md -->
# Users API Reference

## Overview

The Alma Users API provides operations for managing patron records, including user details, email addresses, expiry dates, and user sets.

**Base URL**: `https://api-eu.hosted.exlibrisgroup.com/almaws/v1/users/`

**Official Documentation**: https://developers.exlibrisgroup.com/alma/apis/users/

## Key Endpoints

### User Record Operations

**Get User**
```
GET /almaws/v1/users/{user_id}
```
- Retrieves complete user record
- `user_id` can be primary ID or other identifier types
- Query parameters:
  - `view` - "full" (default) or "brief". Sandbox 2026-11-12: `brief` omits `user_note`,
    `user_block`, and contact addresses/phones (only `contact_info.email` remains), so never
    PUT a record read with `view=brief`; an unknown `view` value is ignored (full record, 200).
  - `expand` - Optional expansions: **only `loans`, `requests`, `fees` are valid** per the official Swagger. Multiple values are comma-separated (e.g. `expand=loans,fees`). NOT valid: `blocks`, `user_blocks` — Alma rejects both with `alma_code 401666` ("expand=<value> parameter is not valid"). User blocks are NOT an expansion — `user_block[]` is always inline at the top level of the user record.

**`expand` response shapes (verified live 2026-05-15 against EU SANDBOX, almaapitk 0.4.3):**

Each expansion adds an aggregate summary, NEVER a list of individual records. The shape is consistent across all three:

| Expansion         | Field added             | Sub-fields                                                     |
|-------------------|-------------------------|----------------------------------------------------------------|
| `expand=loans`    | `loans` (dict)          | `link: str` (URL to `/users/{id}/loans`), `value: int` (count) |
| `expand=requests` | `requests` (dict)       | `link: str` (URL to `/users/{id}/requests`), `value: int` (count) |
| `expand=fees`     | `fees` (dict)           | `link: str` (URL to `/users/{id}/fees`), `value: float` (current outstanding balance — same number Alma UI shows as "Active balance") |

**Important:** `fees.value` IS the active balance. It's NOT a sum of individual fee records — those live at the `link` endpoint. Code that reads `data["fees"]["fee"]` expecting a list of fine objects will silently get nothing back. To get individual fee records (with `original_amount`, `balance`, `type`, `status` per fee), call `GET /users/{user_id}/fees` directly.

**Update User**
```
PUT /almaws/v1/users/{user_id}
```
- Updates user record
- Requires complete user object in request body
- Content-Type: application/json or application/xml

**Create User**
```
POST /almaws/v1/users
```
- Creates new user record
- Requires complete user object with mandatory fields

**Delete User**
```
DELETE /almaws/v1/users/{user_id}
```
- Removes user from system
- Cannot delete users with active loans or fees
- **Response shape (verified live 2026-05-10 against EU SANDBOX):**
  returns **HTTP 204 No Content** with no body — matches the swagger
  spec which documents `204: "Deleted"`. Callers expecting a JSON
  payload echo (for audit logging, etc.) will be surprised: there is
  no body to parse. `AlmaResponse.success` is True for 204;
  `.data` is empty. If you need an audit snapshot of the user, do
  `GET /users/{id}` immediately BEFORE the DELETE and persist that
  yourself. (Some inferred-from-docs AC text in upstream issues
  suggests the deleted payload is echoed back — it is not.)
- **Latency:** typically <2 seconds, but observed up to ~40 seconds in
  SANDBOX once during a regression run. Likely Alma cascading through
  linked resources (notes, audit log entries, blocks). Callers SHOULD
  set a generous client timeout — the existing toolkit default of 300
  seconds is sufficient.
- **Idempotency:** a second DELETE on a freshly-deleted user_id
  returns HTTP 400 with `alma_code 401861` ("User with identifier ...
  was not found.") — NOT 404. Callers retrying after a hung first
  call should treat 401861 as "already deleted, OK".

### User Search

**Search Users**
```
GET /almaws/v1/users
```
- Query parameters:
  - `q` - Query string for search
  - `limit` - Results per page (default: 10, max: 100; Sandbox: limit=101/150 silently return 100, no error)
  - `offset` - Pagination offset

**Query Examples**:
```
# By primary ID
q=primary_id~123456

# By email
q=email~user@example.com

# By user group
q=user_group~FACULTY

# By status
q=status~ACTIVE

# Combined query
q=user_group~STUDENT AND status~ACTIVE
```

## Data Structure

### User Object Key Fields

**Identification**:
- `primary_id`: string - Primary identifier (mandatory)
- `user_group`: object - User group code (mandatory)
  - `value`: Group code (e.g., "FACULTY", "STUDENT")
  - `desc`: Group description
- `record_type`: object - Record type (mandatory)
  - `value`: Type code (e.g., "PUBLIC", "STAFF")

**Personal Information**:
- `first_name`: string - First name (mandatory)
- `last_name`: string - Last name (mandatory)
- `middle_name`: string - Middle name (optional)
- `pin_number`: string - User PIN/password
- `birth_date`: date - Date of birth

**Contact Information**:
- `contact_info`: object - Contains contact details
  - `email`: array - Email addresses
    - `email_address`: string
    - `preferred`: boolean
    - `email_type`: array of `{value, desc}` (JSON key is `email_type`; `email_types` is only the XML wrapper) (corrected 2026-11-12, see evaluation US-17)
  - `phone`: array - Phone numbers
  - `address`: array - Physical addresses

**Account Status**:
- `status`: object - Account status
  - `value`: Status code (e.g., "ACTIVE", "INACTIVE")
- `expiry_date`: date - Account expiry date (YYYY-MM-DD format)
- `purge_date`: date - Purge date

**Identifiers**:
- `user_identifier`: array - Additional identifiers
  - `id_type`: object - Identifier type
  - `value`: string - Identifier value
  - `note`: string - Note about identifier

**Statistics & Notes**:
- `user_statistic`: array - Statistical categories
- `user_note`: array - Notes about user
- `user_block`: array - Blocks on user account
- `user_role`: array - Staff roles (for staff users)

## Common Operations

### Update User Email

**Pattern**:
```python
# Get user
user_data = users.get_user(user_id)

# Update email
if 'contact_info' in user_data and 'email' in user_data['contact_info']:
    emails = user_data['contact_info']['email']
    if emails:
        emails[0]['email_address'] = new_email

# Save changes
users.update_user(user_id, user_data)
```

**Important Notes**:
- Email array can be empty
- Each email has `preferred` flag
- Multiple email types supported (personal, school, work)

### Update Expiry Date

**Pattern**:
```python
# Get user
user_data = users.get_user(user_id)

# Update expiry date
user_data['expiry_date'] = "2026-12-31Z"  # ISO format with Z

# Save changes
users.update_user(user_id, user_data)
```

**Date Format**: `YYYY-MM-DDZ` (ISO 8601 with timezone marker)

### Process Users from Set

**Pattern**:
```python
# Get user set
set_data = admin.get_set(set_id)
user_ids = admin.get_user_set_members(set_id)  # list of user ID strings

# Process each user
# (corrected 2026-11-12, see evaluation US-43: get_set_members/get_user_set_members
#  return ID strings, not member dicts with a 'link'; get_user returns an AlmaResponse)
for user_id in user_ids:
    user_data = users.get_user(user_id).json()

    # Perform operation
    # ... update user ...

    users.update_user(user_id, user_data)
```

## Validation Rules

**Mandatory Fields (User Creation)**:
- `primary_id` - Unique identifier
- `first_name` - First name
- `last_name` - Last name
- `user_group` - User group code
- `record_type` - Record type code
- `account_type` - Account type code
- `status` - Account status

**Field Constraints**:
- `primary_id`: Max 255 characters, must be unique
- `expiry_date`: Must be valid date in future
- `email_address`: Must be valid email format
- `user_group`: Must exist in configuration
- `campus_code`: Must exist in configuration

## Error Codes

(Table corrected 2026-11-12 against the official users swagger, see evaluation US-23. The
previous version listed 401862/401868 and gave wrong meanings for 401863 and 401890.)

| Code | Message (swagger) | Where |
|------|---------|-------|
| 401861 | User with identifier X was not found | GET/DELETE/PUT user |
| 401890 | User with identifier X of type Y was not found | GET/PUT/DELETE user, loans, requests, purchase requests |
| 401851 | User with identifier of type Y already exists | POST user (duplicate) |
| 401664 | Mandatory field is missing: X | POST user |
| 401852 | Given user group is not legal | POST user |
| 401863 | Given X type (Y) is not supported for given user record type (Z) | POST/PUT user |
| 401864 | Given X type (Y) is invalid | POST/PUT user |
| 401860 | Failed to update user | PUT user |
| 401850 | Failed to delete user with identifier X of type Y | DELETE user |

## Important Notes

### Email Structure
- Emails are in an array even for single email
- Empty email arrays are valid
- Email object structure:
  ```json
  {
    "email_address": "user@example.com",
    "preferred": true,
    "email_type": [
      {"value": "personal", "desc": "Personal"}
    ]
  }
  ```
  (corrected 2026-11-12: JSON key is `email_type`, see evaluation US-17)

### Expiry Date Processing
- Expired users may have active status
- Check both `status` and `expiry_date` fields
- Expiry date is date-only (no time component)
- Use "Z" suffix for timezone (e.g., "2026-12-31Z")

### User Groups
- User groups control loan rules, fines, permissions
- Must be configured in Alma before use
- Common groups: FACULTY, STUDENT, STAFF, PUBLIC
- Group codes are institution-specific

### Performance Considerations
- Large user sets: Process in batches
- Rate limiting: per institution 50 calls/second and 1500/minute (Sandbox: 10/s, 300/min),
  plus a daily cap of 1000 × named user licences; over-limit returns HTTP 429
  (corrected 2026-11-12 from "100/min", see evaluation US-40)
- Pagination: Use limit/offset for large result sets
- Caching: Cache frequently accessed users

## Related Endpoints

- **User Loans**: `/almaws/v1/users/{user_id}/loans`
- **User Requests**: `/almaws/v1/users/{user_id}/requests`
- **User Fees**: `/almaws/v1/users/{user_id}/fees`
- **User Deposits**: `/almaws/v1/users/{user_id}/deposits`
- There is no `/users/{user_id}/blocks` endpoint; blocks are the inline `user_block` list of
  the user record (corrected 2026-11-12, see evaluation US-24)

## User Loans — quirks (verified live 2026-05-10 EU SANDBOX)

### Create loan: query vs body separation

`POST /almaws/v1/users/{user_id}/loans` is split between query and
body params — easy to get wrong:

- **Query params**: `item_barcode` OR `item_pid` (mutually exclusive,
  exactly one required), and optional `user_id_type`.
- **Body fields**: `library` and `circ_desk`, both wrapped in the
  canonical `{"value": "<code>"}` dict.

Example body that works:

```json
{"library": {"value": "GEO"}, "circ_desk": {"value": "MAIN"}}
```

Skipping `library`/`circ_desk` in the body (sending `null` or `{}`)
is rejected with a validation error — Alma can't derive defaults
from API-key context alone.

### No DELETE endpoint for loans

Swagger documents only `GET`, `POST` (create + `op=renew`), and `PUT`
on the loans endpoints. There is no DELETE — a loan can only be
"cleared" by completing it (return) or letting it expire.

To return a loaned item programmatically, use the items / scan-in
endpoint:

```
POST /almaws/v1/bibs/{mms_id}/holdings/{holdings_id}/items/{item_pid}
     ?op=scan&library=<lib>&circ_desk=<desk>
```

When called with `circ_desk` and **no `work_order_type`**, this
endpoint performs a circulation return and completes the loan. (The
same endpoint with a `work_order_type` instead places the item in a
work order — same Alma URL, two different semantics keyed off the
presence of `circ_desk` vs `work_order_type`.) The toolkit wraps this
as `BibliographicRecords.scan_in_item(...)`.

### `op=renew` is the only documented op

`POST /loans/{loan_id}` accepts only `op=renew`. Other ops (e.g.,
`return`, `lost`) are NOT exposed at this endpoint — they live on
the items resource or on dedicated request flows.

### Patron must be eligible

Loan creation enforces patron-side rules server-side. A common block
is **`alma_code 401168` "Patron's card has expired"**, which prevents
loan creation even if the patron exists and the item is on shelf.
Test fixtures need their expiration extended periodically (via the
Alma staff UI or via `update_user`); this is normal operator
maintenance, not a wrapper bug.

### Loan error-code map (corrected 2026-11-12 against the official swagger, see evaluation US-29)

The previous map here (401822 item not found, 401823 active loan exists, 401824 user not
found, 401681 patron not eligible, 401890 too many loans) did not match the swagger. Per
`users.json`:

| Code | Swagger message | Endpoint |
|------|---------|-------|
| 401890 | User with identifier X of type Y was not found | create loan |
| 401153 | Item cannot be loaned from this circulation desk | create loan |
| 401651 | Item is not loanable | create loan |
| 401672 | PID field is empty | create loan |
| 401652 | General error | create loan |
| 60340 / 60258 | Loan is API Restricted by library / API Restricted profile not valid | create, renew |
| 401822 | Cannot renew loan: Loan ID X | renew (`op=renew`) |
| 401823 | Loan ID X does not exist | renew, update (Sandbox GET of a bogus loan id returned this message) |
| 401824 | Due date is not in loan object | update (PUT) |
| 401681 | Due date cannot be in the past | update (PUT) |

401168 (expired card, above) is not in the swagger; it comes from an earlier Sandbox run.

### Test fixture maintenance

When designing live SANDBOX tests against a fixture user (e.g., the
toolkit's regression smoke), expect the test to fail eventually with
`401168` (expired patron) until you refresh the user's expiration.
Same applies to test items going off-shelf or being marked lost. A
healthy fixture inventory is part of regular SANDBOX hygiene, not a
one-time setup.

## User Requests — quirks (verified live + swagger 2026-05-10)

The user-requests resource (hold / booking / digitization requests
placed BY a user) lives under `/almaws/v1/users/{user_id}/requests`.
Six endpoints in total: GET (list), POST (create), GET single, POST
op (perform action), PUT (update), DELETE (cancel).

### Cancel is `DELETE` (NOT a separate cancel verb), and `reason` is required

`DELETE /almaws/v1/users/{user_id}/requests/{request_id}` is the
documented "cancel" path — there is no `op=cancel` on the POST
endpoint. The DELETE accepts:

- `reason` — **REQUIRED** as a query param (`required: true` in the
  swagger). Wrapper-level validation should enforce non-empty string.
- `note` — optional query param.

Returns HTTP 204 No Content on success (`.data` empty). NOT the
canceled request payload.

```
DELETE /almaws/v1/users/{user_id}/requests/{request_id}?reason=...&note=...
→ 204 No Content
```

The original toolkit ticket described `reason` as optional. That was
wrong; the swagger confirms it is required.

### Cancel does NOT delete the request record

A canceled request still exists in Alma's history with `status=CANCELED`
or similar (depends on tenant config). Whether a subsequent `GET /requests/{id}`
on a freshly-canceled request fails, and with which code, is **untested**.
(Corrected 2026-11-12, see evaluation US-32: this said the GET returns
alma_code 401129 "Request not found", but per the swagger 401129 means
"No items can fulfill the submitted request" on request create, and the
toolkit's regression test never GETs after cancel.)

### Create accepts query-param resource identifiers + body request data

`POST /almaws/v1/users/{user_id}/requests` is a query/body split:

- **Query params** (at least one resource identifier required):
  - `mms_id` — a bib-level request (e.g., "hold any copy of this title")
  - `item_pid` — an item-level request (specific item)
  - `user_id_type` — optional, identifier-type override
- **Body** (the request object):
  - `request_type` — `HOLD` / `BOOKING` / `DIGITIZATION` / etc.
  - `pickup_location_type` — `LIBRARY` / `CIRCULATION_DESK`
  - `pickup_location_library` — library code
  - Optional fields: `last_interest_date`, `comment`, `partial_digitization`, ...

Note: the toolkit's `create_user_request` ALSO accepts `holding_id`
as a query param (per the original issue body); but the public Alma
swagger does NOT document `holding_id` as a query parameter on this
endpoint — only `mms_id` and `item_pid`. Calling with `holding_id`
may or may not work depending on Alma version; treat as undocumented.
Prefer `mms_id` or `item_pid` for documented behavior.

### Op endpoint values

`POST /almaws/v1/users/{user_id}/requests/{request_id}?op=...` — per the
swagger, **only `op=next_step` is supported** (moves a digitization
request to its next workflow step), with an optional `release_item`
flag (corrected 2026-11-12, see evaluation US-34; this previously said
the swagger does not enumerate the ops). The toolkit's
`perform_user_request_action` accepts an arbitrary `op` string and
lets Alma reject invalid values — not opinionated about which ops
are valid because Alma's set evolves with version.

### Common error codes

(Corrected 2026-11-12 against the swagger, see evaluation US-35. The previous table gave
wrong meanings for 401129, 401694 and 401907; 401119 and 401130 are not in the swagger.)

| Code | Swagger message | Endpoint |
|------|---------|-------|
| 401890 | User with identifier X of type Y was not found | create, get, cancel |
| 401129 | No items can fulfill the submitted request | create (also seen briefly right after a loan, until the index catches up) |
| 401136 | Patron has active request for selected item | create |
| 401895 | Pickup circulation desk X / library Y not found | create |
| 60328 | Item for request was not found | create |
| 401694 | Request Identifier not found | cancel (DELETE) |
| 401907 | Failed to find a request for the given request ID | op (POST) |
| 401932 / 401933 | Not a digitization request / cannot move forward in workflow | op (POST) |

## AlmaAPITK Implementation

The Users domain class is located at: `src/almaapitk/domains/users.py`
(corrected 2026-11-12 against AlmaAPITK de2013d, see evaluation US-41)

**Available Methods** (selection):
- `get_user(user_id, expand="none")` - Retrieve user record; rejects expand values other than loans/requests/fees locally
- `update_user(user_id, user_data)` - Full-record PUT
- `update_user_email(user_id, new_email, email_type='personal')` - GET, change preferred (or sole) email, PUT; adds a new preferred email if none
- `list_users(limit, offset, q, order_by, expand, ...)` / `search_users(q, limit, offset, **kwargs)` - Search users (returns a list of dicts)
- `list_user_notes`, `add_user_note`, `remove_user_notes` - notes via GET-mutate-PUT
- `process_users_batch`, `bulk_update_emails`, `is_user_expired_years` - used by the expired-users project
- There is **no** `update_user_expiry`; set `expiry_date` and call `update_user`.

## Example Scripts

- **update_expired_user_emails_2.py** - Bulk update emails for expired users
  - Demonstrates user set processing
  - Handles email validation and updates
  - Includes dry-run and safety features
  - Configuration file support

## Testing

(Corrected 2026-11-12: the script `src/tests/test_users_script.py` named here does not exist
in AlmaAPITK de2013d. Users Sandbox tests live under `chunks/users-*/sandbox-tests/`.)

---

**Related References**:
- [Admin API](../../alma-api-expert/references/admin_api.md) - For user set operations
- [Error Codes](../../alma-api-expert/references/error_codes_and_solutions.md) - Complete error reference
- [Validation Rules](../../alma-api-expert/references/validation_and_required_fields.md) - Field validation details

<!-- moved from alma-api-expert/references/endpoint_reference.md -->
## Users API Endpoints

### User Records

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| GET | `/users/{user_id}` | Retrieve user | Yes |
| POST | `/users` | Create user | Yes |
| PUT | `/users/{user_id}` | Update user | Yes |
| DELETE | `/users/{user_id}` | Delete user | Yes |
| GET | `/users` | List users (with query) | Yes |

**Query Parameters** (GET /users):
- `q`: Query string
- `limit`, `offset`: Pagination
- `order_by`: Sort field

**Examples**:
```
GET /almaws/v1/users?q=email~*@university.edu&limit=100   # domain wildcard returned 0 in Sandbox, see evaluation US-14
PUT /almaws/v1/users/user123
```

<!-- moved from alma-api-expert/references/pagination_and_queries.md -->
### Search Users by Email Domain

**Warning (added 2026-11-12, see evaluation US-14):** in the TAU Sandbox, `email~` matched
only a complete address. For an address that `email~<full address>` found, `email~*@<domain>`,
`email~<domain>`, `email~<local part>` and a prefix wildcard all returned 0. Domain search by
`email~` does not appear to work; do not rely on the pattern below without testing it.

**Pattern (unverified)**:
```python
# All users from a domain
query = "email~*@university.edu"
params = {"q": query, "limit": 100}

response = client.get("almaws/v1/users", params=params)
users = response.json().get('user', [])
```
