---
name: alma-resource-sharing
description: Alma resource sharing through the API, both sides — partner-side lending requests (POST /almaws/v1/partners/{partner_code}/lending-requests) and patron-side borrowing requests (/almaws/v1/users/{user_id}/resource-sharing-requests) — with their field shapes, owner/partner/format/citation_type quirks, partner codes, validation rules, errors and AlmaAPITK methods. Use when building, debugging or explaining Alma lending or borrowing requests, resource sharing partners, or the RS automation projects. For other Alma API areas use alma-api-expert or alma-acquisitions-specialist.
---

# Alma Resource Sharing

Help the agent create, read and troubleshoot Alma resource sharing requests through the API.
Two different sides share field names but not endpoints or rules:

- **Lending (partner side):** a partner institution asks to borrow from us.
  `POST /almaws/v1/partners/{partner_code}/lending-requests`; AlmaAPITK `ResourceSharing` domain.
- **Borrowing (patron side):** a patron asks for something we don't hold.
  `POST /almaws/v1/users/{user_id}/resource-sharing-requests`; AlmaAPITK `Users` class.

**Maturity: partly validated (evaluation 2026-11-12; knowledge accuracy and toolkit alignment,
read-only).** Of 39 claims checked against the official swagger/XSD, read-only Sandbox GETs and
production code, 17 were contradicted and corrected in place (e.g. lending status
`REQUEST_CREATED_LEND`, `year` not `publication_date`, `mms_id`/`requested_media` plain strings,
lending citation codes only `BOOK`/`JOURNAL`, no partner-level list/PUT endpoints). Write-path
claims (the wrapped-owner 400, borrowing error codes) were not re-run; see
[evaluation.md](references/evaluation.md) before relying on a claim for a write.

## Lending request: the fields that bite

- `external_id` — mandatory.
- `owner` — **plain string**, not wrapped. The official JSON schema and XSD both define it
  as a string (corrected 2026-11-12, see evaluation RS-02).
- `partner`, `format` (e.g. `PHYSICAL`), `citation_type` — wrapped: `{"value": "CODE"}`.
- `mms_id`, `requested_media` — plain strings (corrected 2026-11-12, RS-08, RS-09).
- `citation_type` and `title` — required unless `mms_id` is given. Lending citation codes are
  `BOOK` / `JOURNAL` (`PR_CitationType`) (corrected 2026-11-12, RS-11).

Borrowing requests have their own shapes (`owner` plain, `pickup_location_type` plain,
`agree_to_copyright_terms` mandatory, `partner` *not* required at create); see the
borrowing section of the API reference.

## Find the detail

- Endpoints, request/response shapes, implementation guide, partner codes, borrowing side:
  [resource-sharing-api.md](references/resource-sharing-api.md)
- Quirks, errors (owner field 400, partner not found, validation failed) and validation rules:
  [quirks-errors-validation.md](references/quirks-errors-validation.md)
- Lending request object, field by field: [data-structures.md](references/data-structures.md)
- Test workflow: [test-scenarios.md](references/test-scenarios.md)
- Evaluation record (claims, verdicts, evidence): [evaluation.md](references/evaluation.md)
- Example bodies and an owner-field error: `assets/`

General API matters (authentication, 401/429/500, pagination, code tables such as
`RequestFormats` and `ReadingListCitationTypes`) live in `alma-api-expert`.

## Before a write

Resolve partner, owner and format codes from configuration or code tables, not from
display names. Check the current request state before acting, keep Sandbox and
Production separate, and read the result back. A Sandbox success does not authorise
Production.
