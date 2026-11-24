# Error Codes and Solutions

This reference documents common Alma API errors, their causes, and solutions.

## Quick Error Lookup

| Error Code | Domain | Error Message | Quick Fix |
|------------|--------|---------------|-----------|
| 402459 | Acquisitions | Invoice retrieval error | Approve invoice before paying |
| 40166411 | Acquisitions | Invalid parameter | Check date format (YYYY-MM-DDZ) |
| 401875 | Acquisitions | Department not found | Verify department code exists |
| 401871 | Acquisitions | PO Line not found | Check POL ID, may be closed |
| 401877 | Acquisitions | Failed to receive PO Line | Verify item not already received |
| 400 | Resource Sharing | Bad request - owner field | Use plain string, not wrapped format |
| 404 | Resource Sharing | Partner not found | Verify partner code in configuration |
| 400 | Resource Sharing | Validation failed | Check all mandatory fields populated |
| 400 | Acquisitions | Fund percentage error | Use EITHER amount OR percent, not both |

## Acquisitions Errors

→ Moved to the `alma-acquisitions-specialist` skill (errors-and-validation.md).

## Resource Sharing Errors

→ Moved to the `alma-resource-sharing` skill (references/quirks-errors-validation.md).

## General API Errors

### HTTP 401 - Unauthorized

**Error**: `HTTP 401 Unauthorized`

**Causes**:
- Invalid API key
- API key for wrong environment (SANDBOX key used in PRODUCTION)
- API key expired or revoked
- Missing API key

**Solutions**:
```python
# Check environment variables
ALMA_SB_API_KEY="your_sandbox_key"
ALMA_PROD_API_KEY="your_production_key"

# Verify correct key for environment
client = AlmaAPIClient('SANDBOX')  # Uses ALMA_SB_API_KEY
client = AlmaAPIClient('PRODUCTION')  # Uses ALMA_PROD_API_KEY

# Test connection
client.test_connection()
```

**Prevention**:
- Store API keys in environment variables, never in code
- Use different keys for SANDBOX and PRODUCTION
- Rotate keys periodically
- Test connection before operations

### HTTP 429 - Rate Limit Exceeded

**Error**: `HTTP 429 Too Many Requests`

**Causes**:
- Exceeded API rate limit (typically 100 requests per minute)
- Burst of rapid requests
- Multiple processes using same API key

**Solutions**:
```python
# Use rate limiting protection
# AlmaAPIClient includes basic rate limiting

# Add delays between requests
import time
for item in items:
    process_item(item)
    time.sleep(0.1)  # 100ms delay

# Implement exponential backoff
from time import sleep
retry_count = 0
max_retries = 3

while retry_count < max_retries:
    try:
        result = api_call()
        break
    except AlmaRateLimitError:
        wait_time = (2 ** retry_count) * 60  # Exponential backoff
        sleep(wait_time)
        retry_count += 1
```

**Prevention**:
- Implement rate limiting in application code
- Use batch operations where available
- Space out requests during large operations
- Monitor API usage in Alma analytics

### HTTP 500 - Internal Server Error

**Error**: `HTTP 500 Internal Server Error`

**Causes**:
- Alma server issue
- Data corruption in Alma
- Complex request that times out
- Bug in Alma API

**Solutions**:
- Retry the request after short delay
- Check Alma status page for known issues
- Simplify the request if complex
- Contact Ex Libris support with tracking ID

**Tracking ID**:
Every error response includes a tracking ID for support:
```python
try:
    result = api_call()
except AlmaAPIError as e:
    tracking_id = getattr(e, 'tracking_id', None)
    logger.error(f"Server error, tracking ID: {tracking_id}")
    # Include tracking ID when contacting support
```

## Error Handling Patterns

### Basic Error Handling

```python
from almaapitk import AlmaAPIError, AlmaValidationError

try:
    result = acq.create_invoice_simple(...)
except AlmaValidationError as e:
    # Client-side validation error
    logger.error(f"Validation failed: {e}")
    # Fix parameters and retry
except AlmaAPIError as e:
    # API error
    logger.error(
        f"API error: {e.status_code}",
        error_message=str(e),
        tracking_id=getattr(e, 'tracking_id', None)
    )
    # Handle based on error code
```

### Specific Error Code Handling

```python
try:
    acq.mark_invoice_paid(invoice_id)
except AlmaAPIError as e:
    if e.status_code == 402459:
        # Invoice not processed yet
        logger.info("Invoice not approved, processing first")
        acq.approve_invoice(invoice_id)
        acq.mark_invoice_paid(invoice_id)
    elif e.status_code == 40166411:
        # Invalid parameter
        logger.error("Invalid parameter value")
        # Check date formats, enum values, etc.
    else:
        # Other error
        raise
```

### Retry Pattern for Transient Errors

```python
from time import sleep

def api_call_with_retry(func, max_retries=3):
    """Retry API call on transient errors."""
    retry_count = 0

    while retry_count < max_retries:
        try:
            return func()
        except AlmaAPIError as e:
            if e.status_code in [429, 500, 502, 503, 504]:
                # Transient error - retry
                retry_count += 1
                if retry_count >= max_retries:
                    raise

                wait_time = (2 ** retry_count) * 1  # Exponential backoff
                logger.warning(
                    f"Transient error, retrying in {wait_time}s",
                    attempt=retry_count,
                    max_retries=max_retries
                )
                sleep(wait_time)
            else:
                # Non-transient error - don't retry
                raise

# Usage
result = api_call_with_retry(lambda: acq.create_invoice_simple(...))
```

### Validation Before API Call

```python
# Validate parameters before making API call
def create_invoice_safely(invoice_number, invoice_date, vendor_code, total_amount):
    """Create invoice with validation."""

    # Validation checks
    if not invoice_number:
        raise ValueError("invoice_number is required")

    if not vendor_code:
        raise ValueError("vendor_code is required")

    if total_amount <= 0:
        raise ValueError("total_amount must be positive")

    # Date format validation
    if isinstance(invoice_date, str):
        if not invoice_date.endswith('Z'):
            invoice_date = invoice_date + 'Z'

    # Now safe to make API call
    return acq.create_invoice_simple(
        invoice_number=invoice_number,
        invoice_date=invoice_date,
        vendor_code=vendor_code,
        total_amount=total_amount
    )
```

## Logging Error Context

Always log sufficient context for debugging:

```python
try:
    result = acq.receive_item(pol_id, item_id, department=dept)
except AlmaAPIError as e:
    logger.error(
        "Failed to receive item",
        pol_id=pol_id,
        item_id=item_id,
        department=dept,
        error_code=e.status_code,
        error_message=str(e),
        tracking_id=getattr(e, 'tracking_id', None)
    )
    raise
```

## Getting Help

### Error Information to Collect

When encountering an error:
1. **Error code** and full error message
2. **Tracking ID** from error response
3. **Request details** (endpoint, parameters, body)
4. **Environment** (SANDBOX or PRODUCTION)
5. **Timestamp** of error
6. **Steps to reproduce**

### Support Resources

1. **Ex Libris Documentation**: https://developers.exlibrisgroup.com/alma/apis/
2. **Ex Libris Support**: Include tracking ID in support tickets
3. **API Logs**: Check `logs/api_requests/` for request/response details
4. **Error Logs**: Check `logs/errors/` for error context

### Debugging Checklist

- [ ] Check error code in this reference
- [ ] Verify all required parameters present
- [ ] Check date format (YYYY-MM-DDZ)
- [ ] Verify code table values exist in configuration
- [ ] Check field format (wrapped vs plain string)
- [ ] Review API logs for request/response details
- [ ] Test in SANDBOX before PRODUCTION
- [ ] Check Alma configuration for referenced entities
- [ ] Verify API key is correct for environment
- [ ] Check for recent Alma API changes or known issues
