---
name: alma-api-expert
description: Alma ILS API core reference and router — authentication and base URLs, general HTTP errors (401, 429, 500) and error handling, pagination and query syntax, sets (admin API), code tables for valid field values, cross-domain quirks and validation patterns, and which Alma domain skill to load. Use for general Alma API questions or when unsure which Alma skill applies. Domain work goes to alma-acquisitions-specialist (POs, POLs, invoices, receiving, funds), alma-resource-sharing (lending and borrowing requests, partners), alma-digital (representations, S3 file upload), alma-users (patrons, loans, user requests, purchase requests), alma-bibs-inventory (bibs, holdings, items), alma-letters (notification letters); MARC cataloguing rules go to expert-cataloger.
---

# Alma API Expert (core)

General Alma API knowledge plus a router to the domain skills. Domain content moved out
on 2026-11-12; pointers ("→ Moved to the … skill") mark where it went.

## Which skill?

| Working on | Load |
|---|---|
| Purchase orders, POLs, invoices, receiving, funds, vendors | `alma-acquisitions-specialist` |
| Lending requests (partners) or patron borrowing requests | `alma-resource-sharing` |
| Digital representations, S3 upload, file linking | `alma-digital` |
| Patrons, loans, user requests, purchase requests, user notes | `alma-users` |
| Bibs, holdings, items, barcodes, scan-in | `alma-bibs-inventory` |
| Notification letters (XSLT, letter configuration API) | `alma-letters` |
| MARC content and cataloguing rules (technology-agnostic; pair with `alma-bibs-inventory` for API writes) | `expert-cataloger` |
| Checking any Alma skill's claims | `alma-api-knowledge-evaluator` |

## Core references

| Need | Reference |
|---|---|
| Base URLs, auth, content types, response codes, rate limits | [Endpoint reference](references/endpoint_reference.md) |
| General errors (401, 429, 500) and handling patterns | [Errors](references/error_codes_and_solutions.md) |
| Pagination (`limit` + `offset`) and query syntax (`~`, `=`, wildcards) | [Pagination and queries](references/pagination_and_queries.md) |
| Sets: search, members, itemized sets | [Admin API](references/admin_api.md) |
| Valid field values instead of guessing | [Code tables](references/code_tables_api.md) |
| Cross-domain quirks, undocumented fields, dates | [Quirks](references/api_quirks_and_gotchas.md) |
| General validation patterns | [Validation](references/validation_and_required_fields.md) |
| Generic field extraction | [Data structures](references/data_structures.md) |

## Official documentation

- Alma APIs: https://developers.exlibrisgroup.com/alma/apis/
- Schemas (XSD): https://developers.exlibrisgroup.com/alma/apis/xsd/

Schema docs are sometimes wrong (the resource-sharing `owner` field is the known case).
When docs and observed Sandbox behaviour disagree, record both and say which you relied on.

## Rules

- Sandbox before Production; a Sandbox success does not authorise Production.
- Resolve codes from configuration or code tables, not display names.
- Read back the result of every write.
