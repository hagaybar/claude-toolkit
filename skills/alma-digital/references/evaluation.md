# alma-digital — evaluation record

> **IDs in this file are placeholders** (this skills library is public). If `$ALMA_FIXTURES` is set, it points to the owner's private map from each placeholder to the real Alma Sandbox record; use it to re-run a check, and never write a real ID back here.

Date: 2026-11-12 (times: Sandbox GETs run 2026-11-12, morning, Asia/Jerusalem). Self-review by an
agent, not independent validation. Method: `alma-api-knowledge-evaluator` (track 1 knowledge
accuracy; track 2 implementation alignment where cheap). Track 3 (agent behaviour) not run.

## Scope and sources

- Skill revision: content as migrated from `alma-api-expert` on 2026-11-12 (SKILL.md, references/,
  assets/).
- Official contract: `https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/bibs.json`
  (representation paths) and schemas under `.../openapi/schemas/`: `rest_representation-post.json`,
  `rest_representation.json`, `rest_representation_file-post.json`, `rest_representation_file.json`,
  `rest_representations.json`. Thresholds: `https://developers.exlibrisgroup.com/alma/apis/`. All
  retrieved 2026-11-12.
- Sandbox (TAU, read-only GET via the skill-eval helper): code tables `RepresentationUsageType`,
  `representationEntityType`, `DigitalRepresentationBaseStatus`; `conf/code-tables` list;
  `conf/libraries`; `bibs/collections`; representations of bib `9900000000000014` (two reps) and
  `9900000000000015`; one representation's detail, files, `use_updated_terminology=true`,
  `expand=bogus_xyz`, `/notes`, and files with `limit=1&offset=5`.
- Logged Sandbox run (prior evidence, not re-run): AlmaAPITK request log of the 2026-04-29
  notes/delete-rebuild experiment on bib `9900000000000012` (statuses, response shapes, error codes).
- Implementation: AlmaAPITK `de2013d` (`src/almaapitk/domains/bibs.py`,
  `client/AlmaAPIClient.py`, `domains/admin.py`).
- Production code: `Alma-Digital-Upload` `origin/prod` `f7e6b42` (`alma_digital_upload.py`,
  `config/config.example.json`); `Update_Alma_Digital_Collections` `origin/prod` `c6a9985`
  (collection membership only; no representation calls).
- Not done: any POST/PUT/DELETE, any S3 access, any Production call.

## Claims

Verdicts: documented · sandbox-confirmed (scope stated) · production-inferred · contradicted ·
unresolved · untested.

| ID | Claim | Where | Verdict | Evidence |
|---|---|---|---|---|
| DG-01 | Endpoints: GET/POST `/bibs/{mms_id}/representations`; GET/PUT/DELETE `.../{rep_id}`; GET/POST `.../files`; GET/PUT/DELETE `.../files/{file_id}` | api.md "API Endpoints" | documented | bibs.json paths |
| DG-02 | GET representations takes `limit` (0–100, default 10), `offset`, `originating_record_id`, `use_updated_terminology` | api.md | documented | bibs.json params |
| DG-03 | POST required fields include `access_rights_policy_id` | api.md "Create Representation", "Validation Rules" | contradicted → fixed | schema `required: [library, usage_type]`; field is optional |
| DG-04 | `library` and `usage_type` are mandatory | api.md | documented | schema required list |
| DG-05 | Usage-type values are PRIMARY / MODIFIED_PRIMARY / DERIVATIVE / AUXILIARY | api.md "Usage Types"; SKILL.md description | contradicted → fixed | Sandbox code table: codes `PRESERVATION_MASTER`, `MODIFIED_MASTER`, `DERIVATIVE_COPY`, `AUXILIARY`; PRIMARY etc. are descriptions |
| DG-06 | `VIEW` and `THUMBNAIL` are usage-type codes | api.md workflows, validation | contradicted → fixed | not in Sandbox code table |
| DG-07 | POST accepts `PRIMARY`/`DERIVATIVE` directly | api.md "Validation Rules" | unresolved | only seen as GET output; POST not tested |
| DG-08 | `use_updated_terminology=true` changes output usage type to PRIMARY | api.md | sandbox-confirmed (one PRESERVATION_MASTER rep) | GET returned `PRIMARY`; default GET returned `PRESERVATION_MASTER` |
| DG-09 | Validate usage types via `GET /conf/general` | api.md "Validation Rules" | contradicted → fixed | schema points to code table `RepresentationUsageType` |
| DG-10 | `entity_type` values include `REPRESENTATION` (default) | api.md field table, entity table, response example | contradicted → fixed | Sandbox table `representationEntityType`: ARTICLE, AUDIOVISUAL, CHAPTER, ISSUE, IssueDet; plain reps return no `entity_type` |
| DG-11 | Entity types have *required* fields; `year`/`season_month`/`day_in_month` apply to ISSUE | api.md "Entity Types" | contradicted → fixed | schema: "Relevant only for…", not required; those three are Issue-Detailed |
| DG-12 | Library must be an Alma library code from `GET /conf/libraries` (`library[].code`) | api.md, assets error example | sandbox-confirmed (list shape) + documented | 30 libraries, keys include `code`, `name`; `LGBTQ` exists (also a second code `LGBTQ ` with trailing space) |
| DG-13 | Invalid library → "Mandatory field is missing or invalid. For field library…" | api.md, error asset | untested | no write run |
| DG-14 | Empty `access_rights_policy_id` gives system default, call succeeds | api.md, AlmaAPITK | sandbox-confirmed (2026-04-29 log) + production-inferred | logged POST 200 with `access_rights_policy_id: {}`; prod sends `""` |
| DG-15 | Common policy codes 200/300/400/500 | api.md "Access Rights Policies" | contradicted → fixed | Sandbox policies are 17-digit Alma IDs with local descriptions |
| DG-16 | Representation response: `access_rights_policy`, `entity_type` string/object, GET includes file list | asset `representation_created.json`, api.md | contradicted → fixed | Sandbox: `access_rights_policy_id`, no `entity_type`, `active` is `{value,desc}`, `files` = `{total_record_count, link}` |
| DG-17 | A bib can have several representations | api.md | sandbox-confirmed | bib with two PRESERVATION_MASTER reps |
| DG-18 | Creating a rep fails when one exists ("Representation Already Exists") | api.md Troubleshooting | contradicted → fixed | DG-17; no such error documented |
| DG-19 | Link body is `{"path": "<s3 key>"}` | api.md, assets, AlmaAPITK | documented + production-inferred | file-post schema; prod `link_file_to_representation` |
| DG-20 | S3 key is `{institution_code}/upload/{identifier}/{filename}` | api.md "S3 Path Structure" | documented + production-inferred | swagger: path "starting with the institution code, i.e. 01UNI_INST/upload/scratch/1234/file.png"; prod builds the same |
| DG-21 | boto3 resource, region `eu-central-1`, the bucket/credential variable names in the skill | api.md Configuration | production-inferred | prod `_upload_file_to_s3` (prod uses `put_object`, skill shows `upload_file`; both valid) |
| DG-22 | Linking a missing file fails: 401873 "Failed to create a Representation File. Please verify that the path is valid and the file exists." | quirks.md | sandbox-confirmed (2026-04-29 log, HTTP 400) | logged error body |
| DG-23 | File response has `mime_type`, `md5`, `link`; `path` = sent upload key; `label` = filename | api.md, asset `file_linked.json` | contradicted → fixed | logged + live: `pid`, `label` (no extension), `size` (int), `path` (storage), `thumbnail_url`; `url` only with `expand=url` |
| DG-24 | (omitted by skill) Link moves the file from the upload folder into storage | — | documented → added | swagger note on POST files; logged path `…/storage/alma/…` |
| DG-25 | DELETE on a file removes the underlying S3 object | quirks.md, api.md | unresolved | evidence was a 404 on the *upload* key, which DG-24 explains; storage copy not checked. Re-upload-before-re-link remains correct (DG-22) |
| DG-26 | DELETE representation with linked files → 4xx "contains files" | quirks.md, api.md | sandbox-confirmed (2026-04-29 log: HTTP 400; message text from the earlier record) | `override` param untested |
| DG-27 | DELETE file and DELETE rep return 204 | api.md (implied) | documented + sandbox log | swagger 204; log 204/204 |
| DG-28 | Only way to remove a rep with files is file-by-file DELETE first | quirks.md | unresolved | documented alternatives not tried: file DELETE `representations=delete`, rep DELETE `override=true` |
| DG-29 | GET files supports `limit`/`offset` | api.md | contradicted → fixed | not in swagger; Sandbox `offset=5` on 1 file still returned it |
| DG-30 | UI notes not exposed; `.../notes` is 404 | quirks.md, api.md | sandbox-confirmed (`/notes` 404 today; other variants per 2026-04-29 record) | live GET |
| DG-31 | Unknown query params silently accepted | quirks.md | sandbox-confirmed (GET rep) | `expand=bogus_xyz` → 200, same body |
| DG-32 | PUT rep returns 200 but does not clear UI notes | quirks.md | sandbox-confirmed (2026-04-29 record only; not re-run) | log PUT 200; UI check was manual |
| DG-33 | `create_representation(mms_id, access_rights, library_code, usage_type)` | quick-workflow.md | contradicted → fixed | AlmaAPITK signature has 5 params: `access_rights_value, access_rights_desc, lib_code, usage_type="PRESERVATION_MASTER"` |
| DG-34 | Toolkit results subscriptable (`resp['id']`, `resp.get(...)`) | api.md workflows | contradicted → fixed | `AlmaResponse` has no `__getitem__`/`get`; use `.json()` (prod does) |
| DG-35 | `Admin.get_all_set_members` returning dicts with `id` | api.md Workflow 2 | contradicted → fixed | method is `get_set_members`, returns `List[str]` |
| DG-36 | Toolkit at `src/domains/bibs.py`; example scripts under `src/projects/Alma_D/…` | api.md "AlmaAPITK Implementation" | contradicted → fixed | path `src/almaapitk/domains/bibs.py`; `src/projects` absent; code lives in Alma-Digital-Upload |
| DG-37 | Rate limit "typically 100 requests/minute" | api.md Performance | contradicted → fixed | official: 50/s, 1500/min per institution; Sandbox 10/s, 300/min; 429 codes |
| DG-38 | `TransferConfig(multipart_threshold=1024*25)` is 25 MB | api.md Large Files | contradicted → fixed | 1024×25 bytes = 25 KB |
| DG-39 | PUT rep needs the full object; strip system fields | api.md | untested | no write run |
| DG-40 | Troubleshooting advises echoing the AWS credential variables | api.md "AWS Upload Failed"; asset `error_aws_upload_failed.json` | contradicted (by secret-handling policy, not the API) — **not fixed** | the evaluator's edit was blocked by the secret-guard hook; the user should replace those lines with a presence-only check |

Counts: documented 7 · sandbox-confirmed 9 · production-inferred 1 · contradicted 18 (17 fixed) ·
unresolved 3 · untested 2. (DG-19/20 also production-inferred; DG-14 also production-inferred.)

## Corrections made (2026-11-12)

All marked inline "(corrected 2026-11-12, see evaluation DG-xx)".

- `digital-representations-api.md`: DG-03, 05, 06, 09, 10, 11, 15, 16, 18, 23, 29, 34, 35, 36, 37, 38;
  added DG-24 note and DG-25/26/28 caveats.
- `quirks.md`: DG-25 caveat on the "DELETE removes S3 object" verification.
- `quick-workflow.md`: DG-33 signature, `.json()`, and the move-on-link note.
- `SKILL.md`: description's usage-type codes (DG-05); Maturity paragraph; quirks pointer (DG-25).
- `assets/example_responses/file_linked.json` and `representation_created.json`: replaced with the
  observed shapes (DG-16, DG-23).

## Open / untested

- DG-40: remove the credential-echo advice (api.md "Credentials not set" and the asset's `solution`
  text). Needs a manual edit.
- DG-25: does file DELETE remove the stored S3 copy? Test: link a Sandbox file, record the returned
  storage `path`, HeadObject it, DELETE the file, HeadObject again. Needs authorised Sandbox write + S3 read.
- DG-28: whether `DELETE .../files/{id}?representations=delete` or `DELETE rep?override=true`
  removes a representation in one call.
- DG-07: whether POST accepts `PRIMARY`/`DERIVATIVE` as usage-type input.
- DG-13, DG-39: invalid-library error text; PUT body requirements.
- Not in the skill but documented: POST rep error `402260` "Bib record is not assigned to a
  collection"; POST rep `generate_label`; GET files `expand=url`.
- Sections not reviewed claim by claim: the usage-type "selection guide" and best practices
  (advice, not contract), the WSL path section, and the generic batch/progress helpers.
