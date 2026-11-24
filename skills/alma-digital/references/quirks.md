<!-- moved from alma-api-expert/references/api_quirks_and_gotchas.md -->
## Digital Representations

### UI Notes Are API-Invisible

**⚠️ QUIRK**: Notes added through the Alma UI's "Notes" tab on a digital representation are not retrievable, editable, or removable through any variant of the digital representations REST API.

**What was tried** (all returned 200 with no note text in any field):
- `GET /bibs/{mms_id}/representations/{rep_id}` (basic)
- `GET ...?expand=notes`, `?expand=all`, `?expand=internal_notes`, `?view=full`, `?use_updated_terminology=true`
- `GET .../representations/{rep_id}/files` and `.../files/{file_id}`

**What returned 404**:
- `GET .../representations/{rep_id}/notes` (no such sibling sub-resource)

**Schema only documents `public_note`** — a single string on the representation object — which is *not* what the UI's Notes tab writes to.

**Edit/remove is also impossible via API**:
```python
# ❌ DOES NOT clear UI notes — returns 200, but notes survive in UI:
client.put(f"almaws/v1/bibs/{mms_id}/representations/{rep_id}", data=stripped_body)

# ✅ Only working "removal" is destructive: delete every file, delete the rep,
#    re-create, re-link. The new rep starts fresh (no notes).
```

**Secondary finding**: Alma silently accepts unknown query params (`expand=anything`, `view=anything`) — so a 200 response from a probe with an unrecognized param does **not** prove the param exists.

**Discovered**: 2026-04-29 in TAU SANDBOX (bib `9900000000000012`, rep `10000000000000013`).

**See Also**: [Digital Representations API - UI-only Notes](digital-representations-api.md)

### DELETE on a Representation File Removes the S3 Object

**⚠️ DOCUMENTATION CORRECTION**: Earlier versions of `digital_representations_api.md` claimed that `DELETE /representations/{rep_id}/files/{file_id}` "Does not delete from S3". **This is incorrect** — empirically the underlying S3 object is removed.

**Verification** (TAU SANDBOX, 2026-04-29):
1. Phase 1: PDF uploaded to `EXAMPLE_INST/upload/9900000000000012/pylint_advisory_guide.pdf`. Linked successfully.
2. After `DELETE /files/{file_id}`: `s3:HeadObject` with same bucket+key returned **404 Not Found**.
3. `s3:ListObjectsV2` with the parent prefix returned no objects.

> **Caveat (2026-11-12, see evaluation DG-25):** the checked key was the *upload* key. Official docs say
> the link call (POST .../files) *moves* the file from the upload folder to storage, and the logged link
> response gave a `.../storage/alma/...` path. So the 404 is explained by the link, not the DELETE.
> Whether DELETE removes the stored copy is **unresolved**. The re-upload-before-re-link rule below is
> still correct (Sandbox-logged: error 401873 without re-upload, success after).

**Implication for delete-and-rebuild workflows**: if you're deleting a representation to start over (e.g., to clear UI notes — see above), you **must** re-upload the file to S3 before re-linking. The re-link call will fail with `"Failed to create a Representation File. Please verify that the path is valid and the file exists."` if you skip the re-upload.

```python
# ❌ Will fail — S3 object is gone after the file DELETE:
client.delete(f".../representations/{old_rep_id}/files/{old_file_pid}")
client.delete(f".../representations/{old_rep_id}")
new_rep = bibs.create_representation(...)
bibs.link_file_to_representation(mms_id, new_rep_id, old_s3_key)  # raises

# ✅ Must re-upload first:
client.delete(f".../representations/{old_rep_id}/files/{old_file_pid}")
client.delete(f".../representations/{old_rep_id}")
new_rep = bibs.create_representation(...)
s3.Bucket(bucket).put_object(Key=old_s3_key, Body=open(local_path, "rb").read())
bibs.link_file_to_representation(mms_id, new_rep_id, old_s3_key)  # works
```

### DELETE on a Representation Refuses if Files Are Linked

**Behavior**: `DELETE /representations/{rep_id}` returns a 4xx with body `"Unable to delete Representation ID: {rep_id}. The Representation contains files."` if any files are still linked.

**Required sequence** for full removal:
```python
# 1. Delete every linked file (also removes them from S3 — see above)
for file_pid in file_pids:
    client.delete(f"almaws/v1/bibs/{mms_id}/representations/{rep_id}/files/{file_pid}")

# 2. Then delete the representation itself
client.delete(f"almaws/v1/bibs/{mms_id}/representations/{rep_id}")
```

**Discovered**: 2026-04-29 in TAU SANDBOX.
