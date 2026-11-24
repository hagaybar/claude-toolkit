<!-- moved from alma-api-expert/SKILL.md -->
### Uploading Digital Files

**Complete workflow**:
1. Create representation: `bibs.create_representation(mms_id, access_rights_value, access_rights_desc, lib_code, usage_type="PRESERVATION_MASTER")`
   — five parameters; pass them by keyword (corrected 2026-11-12, see evaluation DG-33). It returns an
   `AlmaResponse`: `rep_id = resp.json()["id"]`
2. Upload to S3: `bucket.upload_file(local_path, s3_key)`
3. Link file: `bibs.link_file_to_representation(mms_id, rep_id, s3_path)` — this moves the file out of the upload folder

**Critical**: Library code must match Alma configuration (NOT MARC fields!)

→ See [Digital Representations API](digital-representations-api.md)
