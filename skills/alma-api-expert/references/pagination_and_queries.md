# Pagination and Queries Reference

This reference documents pagination and query syntax for Alma API operations.

## Quick Reference

| Pattern | Example | Use Case |
|---------|---------|----------|
| Basic pagination | `limit=100&offset=0` | Get first 100 results |
| Search by POL | `q=pol_number~POL-01001` | Find invoices for POL |
| Fuzzy match | `q=email~*@university.edu` | Match email domain |
| Exact match | `q=status=ACTIVE` | Exact status match |
| Combined query | `q=status~ACTIVE AND vendor~RIALTO` | Multiple criteria |
| Wildcard start | `q=title~Library*` | Starts with "Library" |
| Wildcard end | `q=email~*@university.edu` | Ends with "@university.edu" |

## Pagination

### Standard Pagination Parameters

**Parameters**:
- `limit`: Number of results per page (default varies, max typically 100)
- `offset`: Starting position (0-indexed)

**Example**:
```python
# Get first page (results 0-99)
params = {"limit": 100, "offset": 0}

# Get second page (results 100-199)
params = {"limit": 100, "offset": 100}

# Get third page (results 200-299)
params = {"limit": 100, "offset": 200}
```

### Fetching All Pages

**Pattern**:
```python
def fetch_all_pages(endpoint, params=None, page_size=100, item_key='items'):
    """Fetch all pages from paginated endpoint."""
    all_items = []
    offset = 0
    params = params or {}

    while True:
        # Add pagination parameters
        page_params = {**params, "limit": page_size, "offset": offset}

        # Make request
        response = client.get(endpoint, params=page_params)
        data = response.json()

        # Extract items
        items = data.get(item_key, [])
        if not items:
            break  # No more results

        all_items.extend(items)
        offset += page_size

        # Log progress for long operations
        if offset % 1000 == 0:
            logger.info(f"Fetched {offset} items so far...")

    logger.info(f"Fetched total of {len(all_items)} items")
    return all_items
```

**Usage**:
```python
# Fetch all invoices for a POL
invoices = fetch_all_pages(
    "almaws/v1/acq/invoices",
    params={"q": f"pol_number~{pol_id}"},
    item_key='invoice'
)

# Fetch all set members
members = fetch_all_pages(
    f"almaws/v1/conf/sets/{set_id}/members",
    item_key='member'
)
```

### Pagination Limits

**Typical Limits**:
- Most endpoints: max 100 results per page
- Analytics: max 1000 results total (not per page!)
- Some endpoints: max 10 or 25 results per page

**Check Response for Total**:
```python
response = client.get(endpoint, params={"limit": 100, "offset": 0})
data = response.json()

# Some endpoints include total count
total = data.get('total_record_count')
if total:
    print(f"Total results: {total}")
    pages_needed = (total + 99) // 100  # Ceiling division
    print(f"Pages needed: {pages_needed}")
```

### Progress Tracking

**Pattern for Long Operations**:
```python
def fetch_with_progress(endpoint, params, total_expected=None):
    """Fetch all pages with progress logging."""
    all_items = []
    offset = 0
    page_size = 100

    while True:
        page_params = {**params, "limit": page_size, "offset": offset}
        response = client.get(endpoint, params=page_params)
        items = response.json().get('items', [])

        if not items:
            break

        all_items.extend(items)
        offset += page_size

        # Calculate and log progress
        current = len(all_items)
        if total_expected:
            percent = (current / total_expected) * 100
            logger.info(f"Progress: {current}/{total_expected} ({percent:.1f}%)")
        else:
            logger.info(f"Fetched {current} items...")

    return all_items
```

## Query Syntax

### Basic Query Format

**General Pattern**: `q={field}{operator}{value}`

**Operators**:
- `~` : Fuzzy match (recommended for most searches)
- `=` : Exact match
- `:` : Colon format (⚠️ may cause errors in some endpoints!)

### Fuzzy Match (Tilde ~)

**Recommended for most queries**.

**Examples**:
```python
# Search invoices by POL
q = "pol_number~POL-01001"

# Search users by email domain
q = "email~*@university.edu"

# Search by vendor
q = "vendor~RIALTO"

# Search by status
q = "status~ACTIVE"

# Search by title (partial match)
q = "title~Library Science"
```

**Why Tilde is Recommended**:
- More forgiving matching
- Handles partial matches
- Consistent across Alma APIs
- Less likely to cause errors

### Exact Match (Equals =)

**Use for precise matches**.

**Examples**:
```python
# Exact POL number
q = "pol_number=POL-01001"

# Exact status
q = "status=ACTIVE"

# Exact vendor code
q = "vendor=RIALTO"
```

**When to Use**:
- Need exact match only
- Filtering by specific code table value
- Known exact value

### Colon Format (Risky!)

**⚠️ WARNING**: Colon format causes server errors in some endpoints!

**Examples**:
```python
# ❌ May cause error in invoice search
q = "pol_number:POL-01001"  # Server error!

# ✅ Use tilde or equals instead
q = "pol_number~POL-01001"  # Works
q = "pol_number=POL-01001"  # Works
```

**Discovered Issue**: Testing on 2025-10-22 showed colon format causes errors when searching invoices by POL number.

### Wildcards

**Supported Wildcards**:
- `*` : Match any characters (zero or more)

**Examples**:
```python
# Ends with (email domain)
q = "email~*@university.edu"

# Starts with (title)
q = "title~Library*"

# Contains (anywhere in field)
q = "title~*Library*"

# Specific pattern
q = "barcode~2239*"
```

**Common Use Cases**:
```python
# All users from a domain
q = "email~*@university.edu"

# All items in a call number range
q = "call_number~QA*"

# All invoices from a vendor
q = "vendor~RIALTO*"
```

### Combined Queries (AND/OR)

**AND Operator**:
```python
# Active invoices from RIALTO vendor
q = "status~ACTIVE AND vendor~RIALTO"

# Specific email from specific user group
q = "email~*@university.edu AND user_group~STUDENTS"

# Multiple conditions
q = "status~ACTIVE AND vendor~RIALTO AND invoice_date~2025-10*"
```

**OR Operator**:
```python
# Multiple statuses
q = "status~ACTIVE OR status~APPROVED"

# Multiple vendors
q = "vendor~RIALTO OR vendor~AMAZON"

# Multiple email domains
q = "email~*@university.edu OR email~*@college.edu"
```

**Combined AND/OR**:
```python
# Grouping with parentheses
q = "(status~ACTIVE OR status~APPROVED) AND vendor~RIALTO"

# Multiple criteria
q = "vendor~RIALTO AND (status~ACTIVE OR status~WAITING_TO_BE_SENT)"
```

### Date Range Queries

**Pattern for date fields**:
```python
# Invoices from specific month
q = "invoice_date~2025-10*"

# Invoices from specific year
q = "invoice_date~2025*"

# Created in date range (if supported)
q = "created_date~2025-10-01 TO 2025-10-31"
```

**Note**: Date range syntax varies by endpoint. Test in SANDBOX first.

## Common Query Patterns

### Search Invoices by POL

→ Moved to the `alma-acquisitions-specialist` skill (acquisitions-api.md).

### Search Users by Email Domain

→ Moved to the `alma-users` skill (references/users-api.md).

### Search by Multiple Criteria

**Pattern**:
```python
# Active invoices from specific vendor in date range
query = (
    "status~ACTIVE AND "
    "vendor~RIALTO AND "
    "invoice_date~2025-10*"
)
params = {"q": query, "limit": 100}
```

### Search Set Members

**Pattern**:
```python
# Get all members of a set (with pagination)
set_id = "10000000000000017"
endpoint = f"almaws/v1/conf/sets/{set_id}/members"

members = fetch_all_pages(endpoint, item_key='member')
print(f"Total members: {len(members)}")
```

## Query Best Practices

### 1. Use Tilde for Safety

```python
# ✅ GOOD - Tilde format (recommended)
q = f"pol_number~{pol_id}"

# ⚠️ RISKY - Colon may cause errors
q = f"pol_number:{pol_id}"

# ✅ OK - Equals works but less forgiving
q = f"pol_number={pol_id}"
```

### 2. Escape Special Characters

**If query value contains special characters**:
```python
# If POL ID contains special chars (rare)
pol_id = "POL-01001"  # Hyphen is OK

# If title contains quotes or special chars
title = "Introduction to \"Library\" Science"
# May need URL encoding or escaping
```

**URL Encoding**:
```python
import urllib.parse

# URL encode query string
query = "title~Introduction to Library Science"
encoded = urllib.parse.quote(query)

params = {"q": encoded}
```

### 3. Start Broad, Then Filter

```python
# Start with broader query
query = "vendor~RIALTO"
invoices = search_invoices(query)

# Filter in code for complex logic
active_unpaid = [
    inv for inv in invoices
    if inv.get('invoice_status', {}).get('value') == 'ACTIVE'
    and inv.get('payment', {}).get('payment_status', {}).get('value') == 'NOT_PAID'
]
```

### 4. Validate Query Before Sending

```python
def validate_query(query):
    """Validate query syntax before API call."""
    if not query or not query.strip():
        raise ValueError("Query cannot be empty")

    # Check for balanced parentheses
    if query.count('(') != query.count(')'):
        raise ValueError("Unbalanced parentheses in query")

    # Warn about colon format
    if ':' in query and '~' not in query and '=' not in query:
        logger.warning("Query uses colon format, may cause errors. "
                      "Consider using tilde (~) instead.")

    return True
```

### 5. Log Queries for Debugging

```python
# Always log query for debugging
logger.info(
    "Searching invoices",
    query=query,
    limit=limit,
    offset=offset
)

response = client.get(endpoint, params={"q": query, "limit": limit, "offset": offset})

logger.info(
    "Search results",
    count=len(response.json().get('invoice', [])),
    total=response.json().get('total_record_count')
)
```

## Pagination + Query Combined

### Full Pattern

```python
def search_with_pagination(endpoint, query, page_size=100, item_key='items'):
    """Search with query and fetch all pages."""
    all_items = []
    offset = 0

    logger.info(f"Starting search: {query}")

    while True:
        params = {
            "q": query,
            "limit": page_size,
            "offset": offset
        }

        response = client.get(endpoint, params=params)
        data = response.json()

        items = data.get(item_key, [])
        if not items:
            break

        all_items.extend(items)
        offset += page_size

        logger.info(f"Fetched {len(all_items)} items so far...")

    logger.info(f"Search complete: {len(all_items)} total items")
    return all_items
```

**Usage**:
```python
# Search all active invoices from RIALTO
invoices = search_with_pagination(
    endpoint="almaws/v1/acq/invoices",
    query="status~ACTIVE AND vendor~RIALTO",
    item_key='invoice'
)
```

## Special Cases

### Analytics Pagination

**⚠️ Analytics has strict limits**:
- Maximum 1000 results TOTAL (not per page)
- May have row limits based on report
- Production only (not available in SANDBOX)

**Pattern**:
```python
# Analytics limited pagination
params = {
    "path": report_path,
    "limit": 1000,  # Maximum
    "offset": 0
}

# Usually get all results in one request
response = client.get("almaws/v1/analytics/reports", params=params)
results = response.json().get('ResultXml', {}).get('rowset', {}).get('Row', [])

if len(results) == 1000:
    logger.warning("Results may be truncated (1000 limit)")
```

### Set Members Pagination

**Set members support standard pagination**:
```python
# Get set members with pagination
set_id = "10000000000000017"
endpoint = f"almaws/v1/conf/sets/{set_id}/members"

params = {"limit": 100, "offset": 0}
response = client.get(endpoint, params=params)

members = response.json().get('member', [])
```

### Invoice Lines Pagination

→ Moved to the `alma-acquisitions-specialist` skill (acquisitions-api.md).

## Error Handling

### Query Errors

**Common Query Errors**:
```python
try:
    response = client.get(endpoint, params={"q": query})
    response.raise_for_status()
except AlmaAPIError as e:
    if "Invalid query" in str(e):
        logger.error(f"Query syntax error: {query}")
        # Fix query and retry
    elif e.status_code == 400:
        logger.error(f"Bad request, check query format: {query}")
    else:
        raise
```

### Empty Results vs Errors

**Distinguish between no results and errors**:
```python
response = client.get(endpoint, params={"q": query})

if response.status_code == 200:
    items = response.json().get('items', [])

    if not items:
        logger.info("Query succeeded but returned no results")
    else:
        logger.info(f"Found {len(items)} results")
else:
    logger.error(f"Query failed: {response.status_code}")
```

## Performance Optimization

### Batch Size Optimization

```python
# Test different page sizes to find optimal
page_sizes = [10, 25, 50, 100]

for size in page_sizes:
    start = time.time()
    items = fetch_all_pages(endpoint, params=params, page_size=size)
    duration = time.time() - start

    logger.info(f"Page size {size}: {duration:.2f}s for {len(items)} items")

# Use fastest page size for production
```

### Caching Query Results

```python
from functools import lru_cache

@lru_cache(maxsize=100)
def search_cached(endpoint, query, ttl=300):
    """Search with caching (for read-only queries)."""
    # Cache results for TTL seconds
    return search_with_pagination(endpoint, query)

# Clear cache when needed
search_cached.cache_clear()
```

### Limit Scope When Possible

```python
# ✅ GOOD - Narrow query
q = "vendor~RIALTO AND status~ACTIVE AND invoice_date~2025-10*"

# ❌ BAD - Too broad, filter in code
q = "vendor~RIALTO"
# Then filter thousands of results in Python
```

## See Also

- [Endpoint Reference - Query Parameters](endpoint_reference.md)
- Acquisitions API - Invoice Search (`alma-acquisitions-specialist` skill)
- [Error Codes - Query Errors](error_codes_and_solutions.md)
