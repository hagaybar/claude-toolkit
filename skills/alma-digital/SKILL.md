---
name: alma-digital
description: Alma digital representations through the API — creating representations on a bib (usage-type codes PRESERVATION_MASTER/MODIFIED_MASTER/DERIVATIVE_COPY/AUXILIARY, entity types CHAPTER/ARTICLE/AUDIOVISUAL/ISSUE, library codes, access rights), uploading files to the institution's AWS S3 bucket and linking them, deleting files or representations, and the related errors and quirks (UI-only notes, linking moves the file out of the S3 upload folder). Use when building, debugging or explaining Alma digital uploads, representations or the digital-collection projects. For other Alma API areas use alma-api-expert.
---

# Alma Digital Representations

Help the agent create, inspect and troubleshoot digital representations and their files
(`/almaws/v1/bibs/{mms_id}/representations/...`), including the S3 upload that precedes linking.

**Maturity: partially evaluated (2026-11-12).** 40 claims were checked against the official
swagger, read-only Sandbox GETs, logged Sandbox runs and the production code. Eighteen were wrong and seventeen
have been corrected in place, among them the usage-type codes (`DERIVATIVE_COPY`, not `VIEW`),
the shape of the file response, and AlmaAPITK returning `AlmaResponse` (use `.json()`). Several
write behaviours are still unresolved, including what DELETE does to the stored S3 copy. See
[evaluation.md](references/evaluation.md) and check the official documentation before any write.

## Find the detail

- Endpoints, objects, configuration, S3 upload, complete workflows, troubleshooting:
  [digital-representations-api.md](references/digital-representations-api.md)
- Short upload recipe: [quick-workflow.md](references/quick-workflow.md)
- Behaviours the docs don't state (UI notes invisible to the API; linking moves the file out of
  the upload folder, so re-upload before re-linking; a representation with linked files refuses
  DELETE): [quirks.md](references/quirks.md)
- Example bodies, responses, errors and an upload config: `assets/`

Bib, holding and item records themselves are in `alma-bibs-inventory`; general API matters
(auth, 401/429/500, pagination, code tables) in `alma-api-expert`.

## Before a write

DELETE calls here destroy files in S3, not just Alma records. Confirm the target
representation and file IDs, work in Sandbox first, and read the result back. A Sandbox
success does not authorise Production.
