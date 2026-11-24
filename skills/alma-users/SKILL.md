---
name: alma-users
description: Alma Users API — patron records (get, search, update email and expiry date, the full-record PUT and its validation), user notes, loans (create, renew), user requests (create, cancel), purchase requests, and processing users from a set; with their verified quirks and error codes. Use when building, debugging or explaining Alma patron/user operations or the user-maintenance projects. Patron resource sharing (borrowing) requests are in alma-resource-sharing; other Alma API areas in alma-api-expert.
---

# Alma Users

Help the agent read and change Alma patron records and the user-side operations hanging off
them (`/almaws/v1/users/...`): loans, requests, purchase requests, notes.

**Maturity: partially evaluated (2026-11-12), not validated as a whole.** 42 claims were checked
against the official swagger, read-only Sandbox GETs and the production project; endpoints,
`expand`/`view`, note and email shapes mostly hold, but several error-code tables, the request
`op` values, the email JSON key, the rate limit and the toolkit method list were wrong and are
corrected inline. Writes (PUT/POST/DELETE behaviour) were not re-tested. See
[evaluation.md](references/evaluation.md).

## Traps worth knowing up front

- `PUT /users/{id}` replaces the whole record ("swap all") and re-validates it, so a record
  read with GET can be rejected on PUT. Send back the full record, not a fragment — and not
  one read with `view=brief`, which lacks notes, blocks and addresses. (Swagger exceptions:
  roles are kept if the incoming list has none; for external users some fields are kept unless
  named in `override`.)
- `expand` accepts only `loans`, `requests`, `fees` (Sandbox-confirmed 2026-11-12).
- More in [quirks.md](references/quirks.md).

## Find the detail

- Endpoints, object fields, common operations (email, expiry, set processing), loans and
  requests: [users-api.md](references/users-api.md)
- Quirks summary (loans, requests, notes, PUT, purchase requests): [quirks.md](references/quirks.md)

Sets themselves (fetching members) are in `alma-api-expert` (admin API).

## Before a write

A PUT can silently drop data you didn't send back. Read the current record, change only what
you mean to, read it back afterwards. Sandbox first; a Sandbox success does not authorise
Production.
