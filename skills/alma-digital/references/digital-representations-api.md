<!-- moved from alma-api-expert/references/digital_representations_api.md -->
# Digital Representations API Reference

## Overview

The Alma Digital Representations API enables management of digital assets associated with bibliographic records. This includes creating digital representations, uploading files to AWS S3, and linking files to representations.

**Base URL**: `https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/{mms_id}/`

**Official Documentation**: https://developers.exlibrisgroup.com/alma/apis/bibs/

## Use Cases

- **Digitization Projects**: Upload scanned materials and link to catalog records
- **File Repository**: Manage digital files associated with physical collections
- **Access Management**: Control access rights and usage policies for digital content
- **Batch Processing**: Upload multiple files from sets or directories

## Key Concepts

### Digital Representation
A container for digital files associated with a bibliographic record. Each representation has:
- **Library code**: Owning library
- **Usage type**: Purpose of the representation (code, e.g. PRESERVATION_MASTER, DERIVATIVE_COPY; corrected 2026-11-12, see evaluation DG-06)
- **Access rights**: Policy controlling who can access the files
- **Remote storage**: Files stored externally (typically AWS S3)

### File Linking
After uploading files to AWS S3, they must be "linked" to Alma representations using the API. The link contains the S3 path where Alma can retrieve the file.

## API Endpoints

### Representations

**Get All Representations**
```
GET /almaws/v1/bibs/{mms_id}/representations
```
- Returns all digital representations for a bibliographic record
- Query parameters:
  - `limit` - Number of results (default: 10, max: 100)
  - `offset` - Pagination offset (default: 0)
  - `originating_record_id` - Filter by remote repository object ID
  - `use_updated_terminology` - When true, uses PRIMARY/DERIVATIVE terminology (default: false)

**Get Specific Representation**
```
GET /almaws/v1/bibs/{mms_id}/representations/{representation_id}
```
- Returns detailed information about a specific representation
- Includes metadata and a `files` object with `total_record_count` and a `link` to the files
  sub-resource, not the file list itself (corrected 2026-11-12, see evaluation DG-16)

**Create Representation**
```
POST /almaws/v1/bibs/{mms_id}/representations
```
- Creates a new digital representation
- **Required fields** (schema `rest_representation-post`): `library` and `usage_type` only
  - `library`: Library code (must exist in configuration)
  - `usage_type`: Usage type code (AlmaAPITK default: PRESERVATION_MASTER)
  - `access_rights_policy_id` is optional; send it empty or omit it for the system default
    (corrected 2026-11-12, see evaluation DG-03)
- **Request body**: JSON representation object

**Update Representation**
```
PUT /almaws/v1/bibs/{mms_id}/representations/{representation_id}
```
- Updates representation metadata
- Requires complete representation object
- Returns 200 even when the body has no effect on UI-only sub-resources (see "UI-only Notes Are API-Invisible" below — sending a PUT without any note fields will *not* clear notes added via the Alma UI)
- Strip system-managed fields (`id`, `link`, `created_*`, `last_modified_*`, `delivery_url`, `thumbnail_url`, `files`) from the body before PUTting; Alma will recompute or reject them otherwise

### Files

**Get Representation Files**
```
GET /almaws/v1/bibs/{mms_id}/representations/{representation_id}/files
```
- Returns list of files linked to a representation (`representation_file` array + `total_record_count`)
- No `limit`/`offset` is documented for this call, and Sandbox ignored `offset=5` on a one-file
  representation; the only documented parameter is `expand=url` (signed download URL)
  (corrected 2026-11-12, see evaluation DG-29)

**Get Specific File**
```
GET /almaws/v1/bibs/{mms_id}/representations/{representation_id}/files/{file_id}
```
- Returns details of a specific file

**Link File to Representation**
```
POST /almaws/v1/bibs/{mms_id}/representations/{representation_id}/files
```
- Links an uploaded file to a representation
- **Required**: File must already exist in S3
- **Request body**: `{"path": "s3_path_to_file"}`
- Per the official docs this call **moves** the file from the upload folder to Alma storage; the
  returned `path` is the storage location (`{inst}/storage/...`), not the upload key you sent
  (added 2026-11-12, see evaluation DG-24)

**Update File**
```
PUT /almaws/v1/bibs/{mms_id}/representations/{representation_id}/files/{file_id}
```
- Updates file metadata
- Requires complete file object

**Delete File**
```
DELETE /almaws/v1/bibs/{mms_id}/representations/{representation_id}/files/{file_id}
```
- Removes file from representation
- ⚠️ **ALSO deletes the underlying S3 object.** Earlier versions of this documentation said "Does not delete from S3" — that is **incorrect**. Empirically verified 2026-04-29 in TAU SANDBOX: after this DELETE, `s3:HeadObject` against the original key returned 404. If you need to retain the S3 file, copy it to another key/bucket *before* calling DELETE.
  - **Caveat (2026-11-12, see evaluation DG-25):** the key checked was the *upload* key, and the link
    call already moves the file out of the upload folder, so that 404 does not show what DELETE did.
    Whether DELETE removes the stored copy is unresolved. The practical rule stands: re-upload
    before any re-link.
- Optional documented query params: `representations=retain|delete` (what to do with a representation
  left without files) and `bibs=retain|suppress|delete`.

**Delete Representation**
```
DELETE /almaws/v1/bibs/{mms_id}/representations/{representation_id}
```
- Deletes the representation
- ⚠️ **Refuses (4xx with "The Representation contains files") if any files are still linked.** Must DELETE every linked file first, then DELETE the representation.
  (Sandbox-logged 400 on 2026-04-29. The documented `override=true` query param — "delete even if
  warnings exist" — was not tried; see evaluation DG-26.)
- Cascading behavior on the S3 objects matches the per-file DELETE above: each file's S3 object is removed when its file link is removed.

## Behavioral Notes & Known Limitations

### UI-only Notes Are API-Invisible

Notes added to a digital representation through the **Alma UI** (the "Notes" tab on the representation editor) are **not exposed by any documented or speculative variant of the digital representations REST API**. Empirically verified 2026-04-29 in TAU SANDBOX against bib `9900000000000012`, rep `10000000000000013`, with two notes ("note 1", "note 2") added through the UI and saved (modification was confirmed via `last_modified_by` flipping to the user's staff ID).

The following all return **200 OK** but never include the note text:

| Endpoint / param | Result |
|---|---|
| `GET /bibs/{mms_id}/representations/{rep_id}` (basic) | 200, no note text in any field |
| `GET ...?expand=notes` | 200, identical body |
| `GET ...?expand=all` | 200, identical body |
| `GET ...?expand=internal_notes` | 200, identical body |
| `GET ...?view=full` | 200, identical body |
| `GET ...&use_updated_terminology=true` | 200, identical body |
| `GET .../notes` (sibling sub-resource) | **404** — no such endpoint |
| `GET .../files` (file list) | 200, no note text |
| `GET .../files/{file_id}` (file detail) | 200, no note text |

**Important secondary finding**: Alma silently accepts unknown query params (`expand=anything`, `view=anything`) and returns the same body as a bare GET. So a 200 from these probes does **not** indicate the param was recognized — only that it wasn't malformed.

**The only note-related field documented in the schema is `public_note`** (a single string on the representation object). The "Notes" tab in the UI writes to a different, undocumented store that is not retrievable, editable, or removable through this API.

#### Implications for editing/removing UI notes

- `PUT /representations/{rep_id}` — verified to **not** clear UI notes. Returns 200, the rep's `last_modified_by` flips to the API user, but the notes survive (visible in the UI on refresh).
- The only way to discard UI notes via API is **destructive**: `DELETE` every linked file, `DELETE` the representation, then re-create the representation and re-link the files. The new representation starts with no notes. (Note: file DELETE removes the underlying S3 object — re-link requires a fresh upload.)
- There is no GET / PUT / DELETE / POST surface for the notes themselves.

→ Cross-reference: [API Quirks & Gotchas — Digital Representations](../../alma-api-expert/references/api_quirks_and_gotchas.md#digital-representations)

## Data Structures

### Representation Object

**Create Request Structure** (Minimal):
```json
{
  "access_rights_policy_id": {
    "value": "",           // Policy code (empty = system default)
    "desc": ""             // Policy description
  },
  "is_remote": false,      // Always false (files stored remotely in S3)
  "library": {
    "value": "MAIN_LIB"    // Library code (mandatory)
  },
  "usage_type": {
    "value": "PRESERVATION_MASTER"  // Usage type code (mandatory)
  }
}
```

**Response Structure** (Full):
```json
{
  "id": "20000000000000001",
  "label": "Digital representation",
  "library": {
    "value": "MAIN_LIB",
    "desc": "Main Library"
  },
  "usage_type": {
    "value": "PRESERVATION_MASTER",
    "desc": "Preservation Master"
  },
  "access_rights_policy_id": {
    "value": "200",
    "desc": "Open Access"
  },
  "copyrights_statement_id": {
    "value": "",
    "desc": ""
  },
  "active": {"value": "true", "desc": "Active"},
  "is_remote": false,
  "public_note": null,
  "delivery_url": null,
  "thumbnail_url": null,
  "originating_system": "ALMA",
  "originating_system_id": null,
  "repository": null,
  "originating_record_id": null,
  "request_id": null,
  "deposit_id": null,
  "po_line": null,
  "created_by": "exl_impl",
  "created_date": "2024-01-15Z",
  "last_modified_by": "exl_impl",
  "last_modified_date": "2024-01-15Z",
  "link": "https://api-eu.hosted.exlibrisgroup.com/almaws/v1/bibs/99000000000000009/representations/20000000000000001"
}
```

#### Complete Field Reference

**Core Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Output only | System-generated representation ID |
| `library` | object | **Yes** | Library code (must match Alma configuration) |
| `usage_type` | object | **Yes** | Representation purpose: code from `RepresentationUsageType` (PRESERVATION_MASTER, DERIVATIVE_COPY, ...) |
| `access_rights_policy_id` | object | No | Access policy (empty = system default) |
| `label` | string | No | Display label for the representation |
| `public_note` | string | No | Public-facing note |
| `is_remote` | boolean | No | Always false for local S3-based representations |

**Entity Type Fields** (for specific types):

| Field | Type | Applies To | Description |
|-------|------|------------|-------------|
| `entity_type` | object | Optional | Codes (table `representationEntityType`): CHAPTER, ARTICLE, AUDIOVISUAL, ISSUE, IssueDet. A plain representation has no `entity_type` (corrected 2026-11-12, see evaluation DG-10) |
| `author` | string | CHAPTER, ARTICLE, AUDIOVISUAL | Creator/author name |
| `title` | string | CHAPTER, ARTICLE, AUDIOVISUAL | Title of the entity |
| `volume` | string | ARTICLE, ISSUE | Volume number |
| `issue` | string | ARTICLE, ISSUE | Issue number |
| `date` | string | ARTICLE, ISSUE | Publication date |
| `start_page` | string | CHAPTER, ARTICLE | Starting page |
| `end_page` | string | CHAPTER, ARTICLE | Ending page |
| `number` | string | CHAPTER | Chapter number |
| `track` | string | AUDIOVISUAL | Track number |
| `start_time` | string | AUDIOVISUAL | Start time (HH:MM:SS) |
| `end_time` | string | AUDIOVISUAL | End time (HH:MM:SS) |
| `year` | string | IssueDet | Publication year |
| `season_month` | string | IssueDet | Season or month |
| `day_in_month` | string | IssueDet | Day of publication |

**URLs and References**:

| Field | Type | Description |
|-------|------|-------------|
| `delivery_url` | string | URL for accessing the digital file |
| `thumbnail_url` | string | URL for thumbnail image |
| `request_id` | string | Related digitization request ID |
| `deposit_id` | string | Related deposit reference |
| `po_line` | string | Associated purchase order line |

**Remote Repository Fields** (when `is_remote=true`):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `repository` | object | **Yes*** | Remote repository code |
| `originating_record_id` | string | **Yes*** | Record ID in remote system |
| `linking_parameter_1` to `_5` | string | No | Additional linking parameters |

*Required only when `is_remote=true`

**System Metadata** (Output only):

| Field | Type | Description |
|-------|------|-------------|
| `created_by` | string | Username who created the representation |
| `created_date` | date | Creation timestamp (YYYY-MM-DDZ) |
| `last_modified_by` | string | Username who last modified |
| `last_modified_date` | date | Last modification timestamp |
| `originating_system` | string | Source system (typically "ALMA") |
| `originating_system_id` | string | ID in originating system |
| `link` | string | API URL to this representation |

**Status Fields**:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `active` | boolean | true | Whether representation is active |
| `copyrights_statement_id` | object | null | Copyright statement reference |

#### Entity Types

Alma supports granular entity types beyond basic representations:

(corrected 2026-11-12, see evaluation DG-10/DG-11: the schema marks these fields "relevant only
for" the entity type, not required; there is no `REPRESENTATION` code — omit `entity_type`.)

| Entity Type | Use Case | Relevant Fields (schema) |
|-------------|----------|-----------------|
| *(none)* | Standard digital file (default) | None beyond core fields |
| **CHAPTER** | Book chapter | `author`, `title`, `start_page`, `end_page`, `number` |
| **ARTICLE** | Journal article | `author`, `title`, `volume`, `issue`, `date`, `start_page`, `end_page` |
| **AUDIOVISUAL** | Audio/video content | `author`, `title`, `track`, `start_time`, `end_time` |
| **ISSUE** | Journal issue | `volume`, `issue`, `date` |
| **IssueDet** | Issue-Detailed | `volume`, `issue`, `number`, `year`, `season_month`, `day_in_month` |

**Example - Chapter Representation**:
```json
{
  "library": {"value": "MAIN_LIB"},
  "usage_type": {"value": "PRESERVATION_MASTER"},
  "entity_type": {"value": "CHAPTER"},
  "author": "Smith, John",
  "title": "Introduction to Digital Preservation",
  "number": "1",
  "start_page": "1",
  "end_page": "25"
}
```

**Example - Article Representation**:
```json
{
  "library": {"value": "MAIN_LIB"},
  "usage_type": {"value": "DERIVATIVE_COPY"},
  "entity_type": {"value": "ARTICLE"},
  "author": "Doe, Jane",
  "title": "Digital Repositories in Modern Libraries",
  "volume": "45",
  "issue": "3",
  "date": "2024-03-15Z",
  "start_page": "123",
  "end_page": "145"
}
```

**Note**: Most common use case is a plain representation with no `entity_type` for simple file uploads.

### File Object

**Link Request Structure**:
```json
{
  "path": "EXAMPLE_INST/upload/99000000000000009/document.pdf"
}
```

**Response Structure** (corrected 2026-11-12, see evaluation DG-23 — shape observed in Sandbox;
no `mime_type`, `md5` or `link`; `label` has no extension; `path` is the storage location):
```json
{
  "pid": "10000000000000010",
  "label": "document",
  "size": 1024000,
  "path": "EXAMPLE_INST/storage/alma/AB/CD/.../document.pdf",
  "thumbnail_url": "..."
}
```
`url` (signed download URL) appears only with `expand=url`.

## Configuration

### Environment Variables

**Alma API Keys**:
```bash
export ALMA_SB_API_KEY="your_sandbox_key"
export ALMA_PROD_API_KEY="your_production_key"
```

**AWS Credentials**:
```bash
export AWS_ACCESS_KEY="your_aws_access_key"
export AWS_SECRET="your_aws_secret_key"
export ALMA_SB_BUCKET_NAME="your_sandbox_bucket"
export ALMA_PROD_BUCKET_NAME="your_production_bucket"
```

### Configuration File Template

```json
{
  "environment": "SANDBOX",
  "library_code": "MAIN_LIB",
  "usage_type": "PRESERVATION_MASTER",
  "access_rights_value": "",
  "access_rights_desc": "",
  "institution_code": "EXAMPLE_INST",
  "aws_region": "eu-central-1"
}
```

**Key Parameters**:
- **library_code**: Must match exact Alma library code (NOT from MARC fields)
- **usage_type**: Representation usage type (see [Usage Types](#usage-types) below)
- **access_rights_value**: Empty = system default, or specific policy code
- **institution_code**: Used in S3 path structure

### Usage Types

Alma supports four representation usage types that define the purpose and relationship of the digital asset.
**The API codes differ from the UI labels** (corrected 2026-11-12, see evaluation DG-05/DG-06; Sandbox
code table `RepresentationUsageType`): `PRESERVATION_MASTER` (Primary), `MODIFIED_MASTER` (Modified
Primary), `DERIVATIVE_COPY` (Derivative), `AUXILIARY`. `VIEW` and `THUMBNAIL` are not codes. With
`use_updated_terminology=true` a GET returns `PRIMARY` instead of `PRESERVATION_MASTER`; whether POST
accepts the updated-terminology names is untested — send the codes. The table below uses the labels.

| Usage Type | Purpose | Description | Example Use Case |
|------------|---------|-------------|------------------|
| **PRIMARY** | Original copy | The original, unmodified digital file | Master scan from digitization project |
| **MODIFIED_PRIMARY** | Lossless modification | Version changed from primary without data loss | Color-corrected scan, metadata-enhanced file |
| **DERIVATIVE** | Lower fidelity copy | Copy with reduced quality or resolution | Thumbnail, web-optimized version, PDF from TIFF |
| **AUXILIARY** | Supplementary material | Additional content related to primary | Table of contents, index, cover image |

**Codes in Alma** (Sandbox code table, 2026-11-12):
- `PRESERVATION_MASTER` - Primary
- `MODIFIED_MASTER` - Modified Primary
- `DERIVATIVE_COPY` - Derivative
- `AUXILIARY` - Auxiliary

**Usage Type Selection Guide**:

**Choose PRIMARY when**:
- Uploading original scans from digitization
- Storing the authoritative version of the file
- File is the best quality available
- This will be the preservation copy

**Choose MODIFIED_PRIMARY when**:
- Applying lossless enhancements (color correction, metadata)
- Converting between lossless formats (TIFF to PNG, FLAC to WAV)
- Editing without quality loss (cropping, rotation)
- Original file and modified version both needed

**Choose DERIVATIVE when**:
- Creating web-friendly versions (lower resolution)
- Generating thumbnails or preview images
- Converting to different format with quality loss (TIFF to JPEG)
- Creating access copies from preservation masters

**Choose AUXILIARY when**:
- Uploading table of contents separately
- Adding cover images
- Including index files
- Providing supplementary documentation

**Example Scenarios**:

```python
# Scenario 1: Digitization project - upload master scan
rep = bibs.create_representation(
    mms_id=mms_id,
    usage_type="PRESERVATION_MASTER",  # PRIMARY - original scan
    ...
)

# Scenario 2: Also create web-friendly version
web_rep = bibs.create_representation(
    mms_id=mms_id,
    usage_type="DERIVATIVE_COPY",  # Derivative - lower resolution
    ...
)

# Scenario 3: Add table of contents
toc_rep = bibs.create_representation(
    mms_id=mms_id,
    usage_type="AUXILIARY",  # AUXILIARY - supplementary
    ...
)
```

**Best Practices**:
1. **Start with PRIMARY**: Always upload preservation master first
2. **Generate DERIVATIVE later**: Create access copies after preservation master secured
3. **Use AUXILIARY sparingly**: Only when separate supplementary files needed
4. **Document usage**: Note why each usage type was chosen for auditing

### Library Code Validation

**⚠️ CRITICAL**: Library codes must be exact Alma configuration values

**Common Mistake**:
```json
// ❌ WRONG: Copied from MARC 914 field
"library_code": "LGBTQ-NLI-2"

// ✅ CORRECT: Actual Alma library code
"library_code": "LGBTQ"
```

**How to Verify**:
1. Via Alma UI: Configuration > General > Libraries
2. Via API: `GET /almaws/v1/conf/libraries`
3. Check `code` field (NOT description or MARC values)

**Error if Invalid**:
```
Mandatory field is missing or invalid. For field library, valid options are: Valid library code.
```

### Access Rights Policies

**System Default** (recommended for most cases):
```json
{
  "access_rights_value": "",
  "access_rights_desc": ""
}
```

**Explicit Policy**:
```json
{
  "access_rights_value": "200",
  "access_rights_desc": "Open Access"
}
```

**Policy IDs are institution-specific Alma IDs**, e.g. a 17-digit `...<institution suffix>` value with a local
description such as "Wiener Open access" in TAU Sandbox. The previously listed 200/300/400/500 codes
were illustrative and do not exist (corrected 2026-11-12, see evaluation DG-15). Read the value from an
existing representation or Configuration > Digital > Access Rights Policies.

## AWS S3 Integration

### S3 Path Structure

**Standard Pattern**:
```
{institution_code}/upload/{identifier}/{filename}
```

**Examples**:
```
EXAMPLE_INST/upload/99000000000000009/document.pdf
EXAMPLE_INST/upload/rare_books_001/scan_001.pdf
EXAMPLE_INST/upload/LGBTQ_collection/item_047.pdf
```

**Path Components**:
- **institution_code**: Your institution's Alma code
- **upload**: Standard directory for uploads
- **identifier**: Unique identifier (typically MMS ID or collection ID)
- **filename**: Original filename

### Upload with boto3

**Setup boto3**:
```python
import boto3
import os

# Initialize S3 resource
s3_resource = boto3.resource(
    service_name='s3',
    region_name='eu-central-1',
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY'),
    aws_secret_access_key=os.getenv('AWS_SECRET')
)

# Get bucket
bucket_name = os.getenv('ALMA_SB_BUCKET_NAME')
bucket = s3_resource.Bucket(bucket_name)
```

**Upload File**:
```python
# Construct S3 path
institution_code = "EXAMPLE_INST"
mms_id = "99000000000000009"
filename = "document.pdf"
s3_key = f"{institution_code}/upload/{mms_id}/{filename}"

# Upload
local_file_path = "/path/to/local/document.pdf"
bucket.upload_file(local_file_path, s3_key)

print(f"Uploaded to S3: {s3_key}")
```

**Upload with Progress**:
```python
import os

def upload_with_progress(local_path, bucket, s3_key):
    """Upload file with progress tracking"""
    file_size = os.path.getsize(local_path)

    def callback(bytes_transferred):
        percent = (bytes_transferred / file_size) * 100
        print(f"  Progress: {percent:.1f}% ({bytes_transferred}/{file_size} bytes)", end='\r')

    bucket.upload_file(local_path, s3_key, Callback=callback)
    print(f"\n  ✓ Upload complete: {s3_key}")

upload_with_progress(local_path, bucket, s3_key)
```

### Error Handling

**Common AWS Errors**:
```python
from botocore.exceptions import ClientError, NoCredentialsError

try:
    bucket.upload_file(local_path, s3_key)
except NoCredentialsError:
    print("❌ AWS credentials not found")
    print("   Set AWS_ACCESS_KEY and AWS_SECRET environment variables")
except ClientError as e:
    error_code = e.response['Error']['Code']
    if error_code == 'NoSuchBucket':
        print(f"❌ Bucket does not exist: {bucket_name}")
    elif error_code == 'AccessDenied':
        print("❌ Access denied - check AWS permissions")
    else:
        print(f"❌ AWS error: {error_code}")
except Exception as e:
    print(f"❌ Upload failed: {e}")
```

## Complete Workflows

### Workflow 1: Single File Upload

**Use Case**: Upload one file to one bibliographic record

**Steps**:
```python
from almaapitk import AlmaAPIClient
from almaapitk import BibliographicRecords
import boto3
import os

# 1. Initialize clients
client = AlmaAPIClient('SANDBOX')
bibs = BibliographicRecords(client)

# 2. Setup AWS
s3_resource = boto3.resource(
    service_name='s3',
    region_name='eu-central-1',
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY'),
    aws_secret_access_key=os.getenv('AWS_SECRET')
)
bucket = s3_resource.Bucket(os.getenv('ALMA_SB_BUCKET_NAME'))

# 3. Configuration
mms_id = "99000000000000009"
local_file = "/path/to/document.pdf"
library_code = "MAIN_LIB"
institution_code = "EXAMPLE_INST"

# 4. Create representation
rep_response = bibs.create_representation(
    mms_id=mms_id,
    access_rights_value="",    # System default
    access_rights_desc="",
    lib_code=library_code,
    usage_type="PRESERVATION_MASTER"
)
rep_id = rep_response.json()['id']
print(f"✓ Created representation: {rep_id}")

# 5. Upload to S3
filename = os.path.basename(local_file)
s3_key = f"{institution_code}/upload/{mms_id}/{filename}"
bucket.upload_file(local_file, s3_key)
print(f"✓ Uploaded to S3: {s3_key}")

# 6. Link file to representation
link_response = bibs.link_file_to_representation(
    mms_id=mms_id,
    representation_id=rep_id,
    file_path=s3_key
)
print(f"✓ Linked file to representation")
print(f"  File ID: {link_response.json()['pid']}")
```

### Workflow 2: Set-Based Batch Upload

**Use Case**: Upload files for multiple records from an Alma set

**Pattern**:
```python
from almaapitk import Admin

# 1. Initialize
admin = Admin(client)
bibs = BibliographicRecords(client)

# 2. Get records from set
set_id = "20000000000000008"
set_members = admin.get_set_members(set_id)  # list of MMS ID strings (corrected 2026-11-12, see evaluation DG-35)
print(f"Processing {len(set_members)} records from set")

# 3. Process each record
results = []
for member in set_members:
    mms_id = member

    try:
        # Check if representation exists
        reps = bibs.get_representations(mms_id)

        if reps.json().get('representation'):
            # Use existing representation
            rep_id = reps.json()['representation'][0]['id']
            print(f"  Using existing representation for {mms_id}")
        else:
            # Create new representation
            rep_response = bibs.create_representation(
                mms_id=mms_id,
                access_rights_value="",
                access_rights_desc="",
                lib_code=library_code,
                usage_type="PRESERVATION_MASTER"
            )
            rep_id = rep_response.json()['id']
            print(f"  Created representation for {mms_id}")

        # Find matching file (assumes files named {mms_id}.pdf)
        file_path = f"/input/folder/{mms_id}.pdf"

        if os.path.exists(file_path):
            # Upload to S3
            filename = os.path.basename(file_path)
            s3_key = f"{institution_code}/upload/{mms_id}/{filename}"
            bucket.upload_file(file_path, s3_key)

            # Link to representation
            bibs.link_file_to_representation(mms_id, rep_id, s3_key)

            results.append({
                'mms_id': mms_id,
                'status': 'SUCCESS',
                'rep_id': rep_id,
                's3_key': s3_key
            })
        else:
            results.append({
                'mms_id': mms_id,
                'status': 'NO_FILE',
                'message': f"File not found: {file_path}"
            })

    except Exception as e:
        results.append({
            'mms_id': mms_id,
            'status': 'ERROR',
            'message': str(e)
        })

# 4. Report results
success_count = sum(1 for r in results if r['status'] == 'SUCCESS')
print(f"\n✓ Successfully processed {success_count}/{len(results)} records")
```

### Workflow 3: Multiple Representations (Primary + Derivatives)

**Use Case**: Upload preservation master and create access copies with different usage types

**Pattern**:
```python
# Configuration
mms_id = "99000000000000009"
master_file = "/path/to/high_res_scan.tiff"  # 300 DPI TIFF
web_file = "/path/to/web_version.jpg"        # 72 DPI JPEG
thumbnail_file = "/path/to/thumbnail.jpg"    # 150x150 JPEG
toc_file = "/path/to/table_of_contents.pdf"  # TOC PDF

# 1. Create PRIMARY representation (preservation master)
primary_rep = bibs.create_representation(
    mms_id=mms_id,
    access_rights_value="",
    access_rights_desc="",
    lib_code="RARE_BOOKS",
    usage_type="PRESERVATION_MASTER"  # PRIMARY
)
primary_rep_id = primary_rep.json()['id']

# Upload master TIFF to S3
s3_key_master = f"{institution_code}/upload/{mms_id}/master.tiff"
bucket.upload_file(master_file, s3_key_master)
bibs.link_file_to_representation(mms_id, primary_rep_id, s3_key_master)
print(f"✓ Uploaded preservation master (PRIMARY)")

# 2. Create DERIVATIVE representation (web access)
web_rep = bibs.create_representation(
    mms_id=mms_id,
    access_rights_value="200",  # Open access for web version
    access_rights_desc="Open Access",
    lib_code="RARE_BOOKS",
    usage_type="DERIVATIVE_COPY"  # Derivative
)
web_rep_id = web_rep.json()['id']

# Upload web JPEG to S3
s3_key_web = f"{institution_code}/upload/{mms_id}/web.jpg"
bucket.upload_file(web_file, s3_key_web)
bibs.link_file_to_representation(mms_id, web_rep_id, s3_key_web)
print(f"✓ Uploaded web version (DERIVATIVE)")

# 3. Create DERIVATIVE representation (thumbnail)
thumb_rep = bibs.create_representation(
    mms_id=mms_id,
    access_rights_value="200",
    access_rights_desc="Open Access",
    lib_code="RARE_BOOKS",
    usage_type="DERIVATIVE_COPY"  # Derivative (no THUMBNAIL code exists)
)
thumb_rep_id = thumb_rep.json()['id']

# Upload thumbnail to S3
s3_key_thumb = f"{institution_code}/upload/{mms_id}/thumbnail.jpg"
bucket.upload_file(thumbnail_file, s3_key_thumb)
bibs.link_file_to_representation(mms_id, thumb_rep_id, s3_key_thumb)
print(f"✓ Uploaded thumbnail (DERIVATIVE)")

# 4. Create AUXILIARY representation (table of contents)
aux_rep = bibs.create_representation(
    mms_id=mms_id,
    access_rights_value="200",
    access_rights_desc="Open Access",
    lib_code="RARE_BOOKS",
    usage_type="AUXILIARY"  # AUXILIARY
)
aux_rep_id = aux_rep.json()['id']

# Upload TOC PDF to S3
s3_key_toc = f"{institution_code}/upload/{mms_id}/toc.pdf"
bucket.upload_file(toc_file, s3_key_toc)
bibs.link_file_to_representation(mms_id, aux_rep_id, s3_key_toc)
print(f"✓ Uploaded table of contents (AUXILIARY)")

# Summary
print(f"\nCreated 4 representations for {mms_id}:")
print(f"  PRIMARY: {primary_rep_id} (preservation master)")
print(f"  DERIVATIVE (web): {web_rep_id}")
print(f"  DERIVATIVE (thumbnail): {thumb_rep_id}")
print(f"  AUXILIARY: {aux_rep_id} (table of contents)")
```

**Best Practice**: Create representations in order of importance:
1. PRIMARY first (preservation master)
2. DERIVATIVE for access
3. AUXILIARY for supplementary materials

### Workflow 4: MARC Field-Based Upload

**Use Case**: Extract file paths from MARC fields (e.g., 907$e) and upload

**Pattern**:
```python
# 1. Get record and extract MARC field
mms_id = "99000000000000009"
marc_values = bibs.get_marc_subfield(mms_id, "907", "e")

if not marc_values:
    print(f"No MARC 907$e found for {mms_id}")
    return

# 2. Construct file path from MARC value
marc_907e = marc_values[0]  # e.g., "rare_books/collection_001"
root_directory = "/mnt/c/collections"
file_directory = os.path.join(root_directory, marc_907e)

# 3. Find files in directory
if not os.path.exists(file_directory):
    print(f"Directory not found: {file_directory}")
    return

files = [f for f in os.listdir(file_directory) if f.endswith('.pdf')]
print(f"Found {len(files)} PDF files in {file_directory}")

# 4. Create representation (once per record)
rep_response = bibs.create_representation(
    mms_id=mms_id,
    access_rights_value="",
    access_rights_desc="",
    lib_code="RARE_BOOKS",
    usage_type="PRESERVATION_MASTER"
)
rep_id = rep_response.json()['id']

# 5. Upload and link each file
for filename in files:
    local_path = os.path.join(file_directory, filename)

    # Upload to S3
    s3_key = f"{institution_code}/upload/{marc_907e}/{filename}"
    bucket.upload_file(local_path, s3_key)

    # Link to representation
    bibs.link_file_to_representation(mms_id, rep_id, s3_key)
    print(f"  ✓ Uploaded and linked: {filename}")
```

## Common Patterns

### Check if Representation Exists

```python
def get_or_create_representation(bibs, mms_id, library_code):
    """Get existing representation or create new one"""

    # Check for existing representations
    reps_response = bibs.get_representations(mms_id)

    if reps_response.json().get('representation'):
        # Use first existing representation
        rep = reps_response.json()['representation'][0]
        print(f"Using existing representation: {rep['id']}")
        return rep['id']

    # Create new representation
    rep_response = bibs.create_representation(
        mms_id=mms_id,
        access_rights_value="",
        access_rights_desc="",
        lib_code=library_code,
        usage_type="PRESERVATION_MASTER"
    )
    print(f"Created new representation: {rep_response.json()['id']}")
    return rep_response.json()['id']
```

### Batch Processing with Error Recovery

```python
def process_batch_with_resume(records, checkpoint_file="checkpoint.json"):
    """Process batch with ability to resume from checkpoint"""
    import json

    # Load checkpoint if exists
    processed = set()
    if os.path.exists(checkpoint_file):
        with open(checkpoint_file, 'r') as f:
            processed = set(json.load(f))
        print(f"Resuming from checkpoint: {len(processed)} already processed")

    results = []
    for record in records:
        mms_id = record['mms_id']

        # Skip if already processed
        if mms_id in processed:
            continue

        try:
            # Process record
            result = process_single_record(record)
            results.append(result)

            # Save checkpoint
            processed.add(mms_id)
            with open(checkpoint_file, 'w') as f:
                json.dump(list(processed), f)

        except Exception as e:
            print(f"Error processing {mms_id}: {e}")
            # Continue with next record

    return results
```

### Progress Tracking

```python
from datetime import datetime

def process_with_progress(records, batch_size=10):
    """Process records with progress reporting"""
    total = len(records)
    start_time = datetime.now()

    for i, record in enumerate(records, 1):
        # Process record
        process_single_record(record)

        # Report progress every batch_size records
        if i % batch_size == 0 or i == total:
            elapsed = (datetime.now() - start_time).total_seconds()
            rate = i / elapsed
            remaining = (total - i) / rate if rate > 0 else 0

            print(f"Progress: {i}/{total} ({i*100//total}%)")
            print(f"  Rate: {rate:.1f} records/sec")
            print(f"  Estimated remaining: {remaining/60:.1f} minutes")
```

## Troubleshooting

### Error: Invalid Library Code

**Symptom**:
```
Mandatory field is missing or invalid. For field library, valid options are: Valid library code.
```

**Cause**: Library code doesn't match Alma configuration

**Solution**:
1. Verify library codes via API:
   ```python
   # Get valid library codes
   response = client.get("almaws/v1/conf/libraries")
   libraries = response.get('library', [])

   for lib in libraries:
       print(f"{lib['code']} - {lib['name']}")
   ```

2. Use exact `code` value (NOT name, NOT MARC field values)

3. **Common mistake**: Using MARC 914 field value directly
   - MARC may have: "LGBTQ-NLI-2" (collection batch identifier)
   - Alma needs: "LGBTQ" (library code only)

### Error: AWS Upload Failed

**Symptom**: File upload to S3 fails

**Common Causes & Solutions**:

1. **Credentials not set**:
   ```bash
   # Check environment variables
   echo $AWS_ACCESS_KEY
   echo $AWS_SECRET

   # Set if missing
   export AWS_ACCESS_KEY="your_key"
   export AWS_SECRET="your_secret"
   ```

2. **Wrong bucket name**:
   ```python
   # Verify bucket exists
   s3_client = boto3.client('s3')
   buckets = s3_client.list_buckets()
   print([b['Name'] for b in buckets['Buckets']])
   ```

3. **Insufficient permissions**:
   - Verify IAM user has `s3:PutObject` permission
   - Check bucket policy allows uploads

4. **Wrong region**:
   ```python
   # Specify correct region
   s3_resource = boto3.resource(
       service_name='s3',
       region_name='eu-central-1'  # Use your bucket's region
   )
   ```

### Error: File Path Not Found (WSL)

**Symptom**: Script can't find files even though they exist in Windows

**Cause**: Wrong path format for Windows Subsystem for Linux (WSL)

**Solution**: Use `/mnt/c/` format instead of `C:/`

```python
# ❌ WRONG: Windows path format
files_root = "C:/Users/username/Documents/files"

# ✅ CORRECT: WSL path format
files_root = "/mnt/c/Users/username/Documents/files"
```

**How WSL mounting works**:
- All Windows drives auto-mount at WSL startup
- `C:\` becomes `/mnt/c/`
- `D:\` becomes `/mnt/d/`
- No manual mounting required

**Verification**:
```bash
# Check if path accessible
ls /mnt/c/Users/

# Test specific directory
ls "/mnt/c/Users/username/Documents/files"
```

### Error: Representation Already Exists

**Note (2026-11-12, see evaluation DG-17/DG-18):** Alma does *not* reject a second representation —
Sandbox bibs carry two `PRESERVATION_MASTER` representations, and no such error is documented. The
real risk is silently creating a duplicate, so check first if you mean to reuse one:

```python
# Check before creating
reps = bibs.get_representations(mms_id)

if reps.json().get('representation'):
    # Use existing
    rep_id = reps.json()['representation'][0]['id']
    print(f"Using existing representation: {rep_id}")
else:
    # Create new
    rep = bibs.create_representation(...)
    rep_id = rep.json()['id']
```

### Error: File Not Linked

**Symptom**: File uploaded to S3 but not visible in Alma

**Cause**: Missing or incorrect link operation

**Solution**: Verify S3 path matches what you passed to link API

```python
# 1. Upload to S3
s3_key = f"{institution_code}/upload/{mms_id}/document.pdf"
bucket.upload_file(local_file, s3_key)
print(f"Uploaded: {s3_key}")

# 2. Link using EXACT same path
link_response = bibs.link_file_to_representation(
    mms_id=mms_id,
    representation_id=rep_id,
    file_path=s3_key  # Must match S3 key exactly
)

# 3. Verify link was created
print(f"File ID: {link_response.json()['pid']}")
```

## Validation Rules

### Representation Creation

**Mandatory Fields**:
- `mms_id`: Valid MMS ID (must exist in Alma)
- `library.value`: Valid library code from configuration
- `access_rights_policy_id.value`: optional, not mandatory (empty = default; corrected 2026-11-12, see evaluation DG-03)
- `usage_type.value`: Valid usage type code (see below)

**Usage Type Values**:

Must be a code from the `RepresentationUsageType` code table (corrected 2026-11-12, see evaluation
DG-05/06/07/09):
- `PRESERVATION_MASTER` - Primary/original file
- `MODIFIED_MASTER` - Modified Primary (lossless modification)
- `DERIVATIVE_COPY` - Derivative/access copy
- `AUXILIARY` - Auxiliary/supplementary

`PRIMARY`/`DERIVATIVE` are output labels under `use_updated_terminology=true`; their acceptance on
POST is untested.

**Validation**: `GET /almaws/v1/conf/code-tables/RepresentationUsageType`

**Optional Fields**:
- `access_rights_policy_id.desc`: Policy description
- `label`: Representation label
- `public_note`: Note visible to users

**Multiple Representations**:
A single bibliographic record can have multiple representations with different usage types:
```python
# Upload preservation master
primary = bibs.create_representation(mms_id, usage_type="PRESERVATION_MASTER", ...)

# Create web version
web = bibs.create_representation(mms_id, usage_type="DERIVATIVE_COPY", ...)

# Add table of contents
toc = bibs.create_representation(mms_id, usage_type="AUXILIARY", ...)
```

### File Linking

**Mandatory Fields**:
- `mms_id`: Valid MMS ID
- `representation_id`: Valid representation ID (must exist)
- `path`: Valid S3 path (file must exist in S3)

**Path Format**: Must match S3 bucket structure
- Correct: `EXAMPLE_INST/upload/{identifier}/{filename}`
- File must already exist at this path in S3

## Performance Considerations

### Batch Processing

**Rate Limiting**:
- Alma thresholds (official docs, read 2026-11-12): 50 calls/second and 1500/minute per institution
  (Sandbox: 10/second, 300/minute), plus a daily limit; exceeding them returns HTTP 429
  (`PER_SECOND_THRESHOLD` / `DAILY_THRESHOLD`). (Corrected 2026-11-12, see evaluation DG-37.)
- A short delay between requests keeps large batches well inside these

```python
import time

for record in records:
    process_record(record)
    time.sleep(0.6)  # ~100 requests/minute
```

**Parallel Upload** (S3):
- S3 uploads can be parallelized
- Use threading for multiple simultaneous uploads

```python
from concurrent.futures import ThreadPoolExecutor

def upload_file(file_info):
    bucket.upload_file(file_info['local'], file_info['s3_key'])

with ThreadPoolExecutor(max_workers=5) as executor:
    executor.map(upload_file, file_list)
```

### Large Files

**S3 Multipart Upload**:
- For files > 5GB, use multipart upload
- boto3 handles this automatically with `upload_file()`

```python
# Automatically uses multipart for large files
bucket.upload_file(
    large_file_path,
    s3_key,
    Config=boto3.s3.transfer.TransferConfig(
        multipart_threshold=25 * 1024 * 1024,  # 25MB (was 1024*25 = 25KB; corrected 2026-11-12, DG-38)
        multipart_chunksize=25 * 1024 * 1024,
        max_concurrency=10
    )
)
```

## Related Endpoints

- **Bibliographic Records**: Base record operations
- **Holdings**: Physical/electronic holdings
- **Items**: Item-level records

## AlmaAPITK Implementation

**Domain Class**: `src/almaapitk/domains/bibs.py` (class `BibliographicRecords`). Methods return an
`AlmaResponse`; read the body with `.json()` — it is not subscriptable (corrected 2026-11-12, see
evaluation DG-34/DG-36). AlmaAPITK has no delete method for representations or files; use
`client.delete(...)`.

**Available Methods**:
- `get_representations(mms_id, representation_id)` - Get representations
- `create_representation(mms_id, access_rights_value, access_rights_desc, lib_code, usage_type)` - Create new representation
- `get_representation_files(mms_id, representation_id, file_id)` - Get files
- `link_file_to_representation(mms_id, representation_id, file_path)` - Link uploaded file
- `update_representation_file(mms_id, representation_id, file_id, file_data)` - Update file metadata

**Example code** (corrected 2026-11-12, see evaluation DG-36: the old `src/projects/Alma_D/...` paths
no longer exist in AlmaAPITK): the production project is the separate `Alma-Digital-Upload` repo —
`alma_digital_upload.py`, strategies `marc-907e` and `mms-id-filename`, docs
`docs/FOLDER_PATH_WORKFLOW.md` and `docs/FILENAME_WORKFLOW.md`.

---

**Related References**:
- Bibs API (`alma-bibs-inventory` skill) - Complete bibliographic records API
- [Error Codes](../../alma-api-expert/references/error_codes_and_solutions.md) - Error troubleshooting
- [Data Structures](../../alma-api-expert/references/data_structures.md) - Object structure details
