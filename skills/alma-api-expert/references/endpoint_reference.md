# Endpoint Reference

**For detailed endpoint usage → see domain-specific references**

Quick lookup table of all key Alma API endpoints.

## Base URLs

| Environment | Base URL |
|-------------|----------|
| SANDBOX | `https://api-eu.hosted.exlibrisgroup.com/almaws/v1` |
| PRODUCTION | `https://api-eu.hosted.exlibrisgroup.com/almaws/v1` |

**Note**: Region may vary (api-eu, api-na, api-ap, api-ca). Check your institution's configuration.

## Acquisitions API Endpoints

→ Moved to the `alma-acquisitions-specialist` skill (acquisitions-api.md).

## Resource Sharing API Endpoints

→ Moved to the `alma-resource-sharing` skill (references/resource-sharing-api.md).

## Bibs API Endpoints

→ Moved to the `alma-bibs-inventory` skill (references/bibs-api.md).

## Users API Endpoints

→ Moved to the `alma-users` skill (references/users-api.md).

## Admin API Endpoints

### Sets

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| GET | `/conf/sets/{set_id}` | Retrieve set metadata | Yes |
| GET | `/conf/sets/{set_id}/members` | Get set members | Yes |
| POST | `/conf/sets` | Create set | Yes |

**Set Types**:
- `BIB_MMS`: Bibliographic record sets
- `USER`: User sets

**Parameters**:
- `set_id`: Set identifier
- `limit`, `offset`: Pagination for members

**Examples**:
```
GET /almaws/v1/conf/sets/10000000000000017
GET /almaws/v1/conf/sets/10000000000000017/members?limit=100
```

## Analytics API Endpoints

### Reports

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| GET | `/analytics/reports` | List available reports | Yes |
| GET | `/analytics/reports?path={report_path}` | Run report | Yes |

**Parameters**:
- `path`: Report path in Analytics
- `limit`, `offset`: Pagination (Analytics has max limits)
- `filter`: Report filters

**Note**: Analytics API is read-only and only available in PRODUCTION.

## General API Patterns

### Authentication

All endpoints require API key in header:
```
Authorization: apikey {your_api_key}
```

**Example**:
```python
headers = {
    "Authorization": f"apikey {api_key}",
    "Content-Type": "application/json"
}
```

### Content Types

| Content-Type | Used For |
|--------------|----------|
| `application/json` | Most endpoints |
| `application/xml` | Item operations (scan, receive) |

**Examples**:
```python
# JSON request
headers = {"Content-Type": "application/json"}
data = {"invoice_number": "INV-001", ...}

# XML request (item receiving)
headers = {"Content-Type": "application/xml"}
data = "<item></item>"
```

### Response Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Check parameters and format |
| 401 | Unauthorized | Check API key |
| 404 | Not Found | Resource doesn't exist |
| 429 | Rate Limit | Implement backoff |
| 500 | Server Error | Retry with backoff |

### Pagination

**Standard Parameters**:
- `limit`: Number of results per page (typically max: 100)
- `offset`: Starting position (0-indexed)

**Example**:
```python
# Get first page
params = {"limit": 100, "offset": 0}

# Get second page
params = {"limit": 100, "offset": 100}

# Get all pages
all_results = []
offset = 0
while True:
    params = {"limit": 100, "offset": offset}
    response = client.get(endpoint, params=params)
    results = response.json().get('items', [])
    if not results:
        break
    all_results.extend(results)
    offset += 100
```

### Query Syntax

**Common Query Formats**:
```
# Tilde (fuzzy match) - Recommended
q=pol_number~POL-01001
q=email~*@university.edu

# Equals (exact match)
q=pol_number=POL-01001
q=status=ACTIVE

# Combined with AND/OR
q=status~ACTIVE AND vendor~RIALTO
q=(status~ACTIVE OR status~APPROVED) AND pol_number~POL-01001

# Wildcards
q=email~*@university.edu    # Ends with
q=title~Library*            # Starts with
```

**Note**: Colon format (`field:value`) may cause errors in some endpoints.

### Date Formats

**Required Format**: ISO 8601 with timezone

```
# Date only
YYYY-MM-DDZ
Example: 2025-10-22Z

# Date and time
YYYY-MM-DDTHH:MM:SSZ
Example: 2025-10-22T14:30:00Z
```

## Rate Limiting

**Typical Limits**:
- 100 requests per minute per API key
- May vary by institution and API tier

**Handling Rate Limits**:
```python
import time

for item in items:
    try:
        process(item)
    except AlmaRateLimitError:
        time.sleep(60)  # Wait 1 minute
        process(item)
```

## Error Responses

**Standard Error Format**:
```json
{
    "errorList": {
        "error": [
            {
                "errorCode": "402459",
                "errorMessage": "Error while trying to retrieve invoice",
                "trackingId": "E01-1234567890"
            }
        ]
    }
}
```

**Error Extraction**:
```python
if response.status_code >= 400:
    error_data = response.json()
    errors = error_data.get('errorList', {}).get('error', [])
    if errors:
        error = errors[0]
        code = error.get('errorCode')
        message = error.get('errorMessage')
        tracking_id = error.get('trackingId')
```

## Official Documentation Links

### API Documentation
- **Main API Docs**: https://developers.exlibrisgroup.com/alma/apis/
- **Acquisitions API**: https://developers.exlibrisgroup.com/alma/apis/acq/
- **Partners API**: https://developers.exlibrisgroup.com/alma/apis/partners/
- **Bibs API**: https://developers.exlibrisgroup.com/alma/apis/bibs/
- **Users API**: https://developers.exlibrisgroup.com/alma/apis/users/
- **Configuration API**: https://developers.exlibrisgroup.com/alma/apis/conf/

### Schema Reference
- **XSD Schemas**: https://developers.exlibrisgroup.com/alma/apis/xsd/
- **OpenAPI/Swagger**: Available for download from developers site

## Quick Reference by Task

### Creating Invoices

→ Moved to the `alma-acquisitions-specialist` skill (acquisitions-api.md).

### Receiving Items

→ Moved to the `alma-acquisitions-specialist` skill (acquisitions-api.md).

### Keeping Item in Department

→ Moved to the `alma-acquisitions-specialist` skill (acquisitions-api.md).

### Creating Lending Requests

→ Moved to the `alma-resource-sharing` skill (references/resource-sharing-api.md).

### Searching Invoices by POL

→ Moved to the `alma-acquisitions-specialist` skill (acquisitions-api.md).

## Implementation Classes

**Domain Classes** (in `src/domains/`):
- `Acquisitions`: POL and invoice operations
- `ResourceSharing`: Lending and borrowing requests
- `Bibs`: Bibliographic records, holdings, items
- `Users`: User management
- `Admin`: Sets and configuration

**Usage**:
```python
from almaapitk import AlmaAPIClient
from almaapitk import Acquisitions

client = AlmaAPIClient('SANDBOX')
acq = Acquisitions(client)

# Methods map to endpoints
pol_data = acq.get_pol("POL-01001")        # GET /acq/po-lines/POL-01001
invoice = acq.create_invoice_simple(...)   # POST /acq/invoices
```

## See Also

- Acquisitions API - Detailed Usage (`alma-acquisitions-specialist` skill)
- Resource Sharing API - Detailed Usage (`alma-resource-sharing` skill)
- [Pagination and Queries - Query Syntax](pagination_and_queries.md)
- [Error Codes - Endpoint Errors](error_codes_and_solutions.md)
