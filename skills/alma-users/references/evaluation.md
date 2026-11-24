# alma-users — evaluation

> **IDs in this file are placeholders** (this skills library is public). If `$ALMA_FIXTURES` is set, it points to the owner's private map from each placeholder to the real Alma Sandbox record; use it to re-run a check, and never write a real ID back here.

Date: 2026-11-12. Self-review by one agent (not independent validation).

## Scope and sources

- Skill revision: `alma-users` as migrated on 2026-11-12 (SKILL.md, users-api.md, quirks.md).
- Tracks: 1 (knowledge accuracy) fully for the selected claims; 2 (implementation alignment)
  where cheap. Track 3 (agent behaviour) not run.
- Official contract: Users OpenAPI
  `https://developers.exlibrisgroup.com/wp-content/uploads/alma/openapi/users.json` and schemas
  `.../openapi/schemas/rest_user.json`, `rest_purchase_request.json`, `rest_item_loan.json`,
  `rest_user_request.json` (all fetched 2026-11-12). Rate limits: `https://developers.exlibrisgroup.com/alma/apis/`.
- Sandbox: read-only GETs via `.skill-eval/alma_get.py` in the `tau` sandbox, TAU EU Sandbox,
  2026-11-12 (about 35 calls). Responses were reduced to structure (keys, types, masked value
  shapes) before inspection; error messages are reported as text because the helper does not
  surface `errorCode`, so codes below are mapped from the swagger message text. No writes.
- Implementation: AlmaAPITK `de2013d` (tag v0.5.1), `src/almaapitk/domains/users.py`, read-only.
- Production: `Alma-update-expired-users-emails` `origin/prod` `64d597c` (2026-07-08), pinned to
  almaapitk 0.4.6. Uses `Admin.validate_user_set`, `get_user_set_members`,
  `Users.process_users_batch`, `Users.bulk_update_emails` (which calls `update_user_email`).

## Claims

| ID | Claim | Where | Verdict | Evidence |
|---|---|---|---|---|
| US-01 | `GET /users/{user_id}` accepts any unique identifier type | users-api Get User | documented | swagger: `user_id_type` default `all_unique` |
| US-02 | `view` = `full` (default) or `brief` | users-api Get User | sandbox-confirmed (one user) | swagger; Sandbox: brief drops `user_note`, `user_block`, address/phone; unknown value → 200 full record |
| US-03 | `expand` valid values only `loans`, `requests`, `fees`, comma-separated | SKILL trap 2; users-api | sandbox-confirmed (one user) | swagger param text; `expand=loans,requests,fees` → 200 |
| US-04 | `expand=blocks` / `user_blocks` rejected (401666) | users-api | sandbox-confirmed (message only) | both → HTTP 400 "expand=blocks parameter is not valid."; code not visible to helper |
| US-05 | `user_block` is inline at top level, not an expansion | users-api | sandbox-confirmed | full GET has `user_block: []` |
| US-06 | Each expansion is `{link, value}`; fees value is float balance | users-api table | sandbox-confirmed (shape) | loans/requests `value` int, fees `value` float, links to sub-resources |
| US-07 | PUT user is "Swap All"; send the full record | SKILL trap 1; users-api | documented, with exceptions | swagger PUT description; roles kept if absent; external-user fields kept unless `override` |
| US-08 | PUT rejects legacy data GET still returns (address line1) | quirks | untested | write; prior note in AlmaAPITK `docs/session-handoff-2026-05-13.md` |
| US-09 | DELETE user → 204, no body | users-api Delete | documented | swagger responses `204` |
| US-10 | Second DELETE → 400 / 401861 | users-api Delete | unresolved | swagger DELETE lists 401890/401850 only; Sandbox GET of unknown id gave the 401861 message text; DELETE not run |
| US-11 | Cannot delete users with active loans or fees | users-api Delete | untested | not in swagger (only generic 401850) |
| US-12 | Search `limit` default 10, max 100 | users-api Search | sandbox-confirmed | swagger "0-100"; limit=101 and 150 → 200 with 100 records, no error |
| US-13 | `q=email~<full address>` finds the user | users-api Query Examples | sandbox-confirmed (one address) | count 1 |
| US-14 | `q=email~*@domain` finds users by domain | users-api endpoints + "Search by Email Domain" | contradicted (Sandbox, one gmail address) | same address: `email~*@<domain>`, `email~<domain>`, `email~<local>`, prefix wildcard → 0; `ALL~gmail` → 43. Swagger does not specify wildcard semantics |
| US-15 | Create mandatory: primary_id, first/last name, user_group, record_type, account_type, status | users-api Validation Rules | unresolved | schema marks `primary_id`, `record_type` mandatory; `status` "Default is Active"; first/last name not marked |
| US-16 | `expiry_date` must be a future date | users-api Field Constraints | unresolved | not in swagger; production project PUTs records of long-expired users (production-inferred counter-evidence) |
| US-17 | Email objects carry `email_types` array | users-api Data Structure, Email Structure | contradicted | schema: JSON property `email_type` (array of `{value,desc}`), `email_types` is the XML wrapper; Sandbox GET shows `email_type`. AlmaAPITK `_extract_email_type` reads `email_type` as a dict, which misreads the array (toolkit observation) |
| US-18 | Each email has a `preferred` boolean; one preferred | users-api | sandbox-confirmed | schema "Only one address can be defined as preferred"; Sandbox boolean |
| US-19 | `expiry_date` format `YYYY-MM-DDZ` | users-api Update Expiry | sandbox-confirmed (shape) | schema example `2030-01-16Z`; Sandbox shape `9999-99-99Z` |
| US-20 | GET returns `user_note` as a flat list | quirks | sandbox-confirmed | `user_note: [list]` of note objects |
| US-21 | PUT with wrapped `{"user_note": [...]}` → 400 Jackson error | quirks | untested (write) | toolkit writes flat list (`add_user_note`), regression test cited in skill |
| US-22 | Note fields `note_type{value}`, `note_text`, `user_viewable`, `popup_note` | quirks, toolkit | documented | schema: `note_type`, `note_text` mandatory; booleans default false |
| US-23 | Users error table: 401862 validation, 401868 exists, 401863 cannot delete, 401890 user group not found | users-api Error Codes | contradicted | swagger: 401851 exists, 401863 "type not supported for record type", 401890 "user … of type Y not found", 401852 user group not legal; 401862/401868 absent |
| US-24 | `/users/{id}/blocks` endpoint exists | users-api Related Endpoints | contradicted | not in swagger; Sandbox GET → 400 treating `<id>/blocks` as user id |
| US-25 | Loan create: `item_barcode`/`item_pid` query; `library`, `circ_desk` body `{value}` mandatory | users-api, quirks | documented | swagger query params; `rest_item_loan` marks both Mandatory; Sandbox loan GET shows `{value,desc}` wrappers; toolkit aligned |
| US-26 | No DELETE on loans | users-api | documented | swagger verbs GET/POST/PUT |
| US-27 | `op=renew` is the only loan op | users-api, quirks | documented | swagger "Currently only op=renew is supported" |
| US-28 | 401168 "Patron's card has expired" blocks loan create | users-api, quirks | untested | not in swagger; earlier Sandbox note only |
| US-29 | Loan error map 401822/401823/401824/401681/401890 ("verified against swagger") | users-api | contradicted | swagger meanings differ (renew/update codes; 401890 = user not found); Sandbox bogus loan id → "Loan ID … does not exist" (401823 text) |
| US-30 | User requests have six endpoints | users-api | documented | swagger |
| US-31 | Cancel = DELETE, `reason` required, `note` optional, 204 | users-api, quirks | documented | swagger; also `notify_user`; reason from `RequestCancellationReasons`; toolkit enforces reason |
| US-32 | After cancel, GET → 401129 "Request not found" | users-api, quirks | contradicted (code meaning) | swagger 401129 = "No items can fulfill the submitted request" (create); toolkit test never GETs after cancel. Post-cancel GET behaviour itself untested |
| US-33 | Create request: `mms_id`/`item_pid` query; `holding_id` undocumented | users-api, quirks | documented | swagger params (plus `allow_same_request`); toolkit still sends `holding_id` if given |
| US-34 | Request `op` values not enumerated (e.g. priority) | users-api | contradicted | swagger: "Currently only next_step is supported" |
| US-35 | Request error table 401129/401119/401130/401694/401907 | users-api | contradicted | swagger: 401694 Request Identifier not found (DELETE), 401907 request not found (op); 401119/401130 absent |
| US-36 | PR `citation_type` lives in `resource_metadata`; 60280 citation invalid | quirks | documented | schema; mandatory only when `mms_id` not supplied; values BOOK/JOURNAL not re-tested |
| US-37 | PR `format` codes P/E; 60270 | quirks | documented | swagger 60270 "Requested format is not valid"; values from PR_RequestedFormat, P/E from 2026-07-19 Sandbox note, not re-tested |
| US-38 | `material_type` is not a PR field | quirks | documented | absent from `rest_purchase_request`; "silently ignored" untested |
| US-39 | Rate limit "default 100/min" | users-api Performance | contradicted | official: 50/s, 1500/min per institution; Sandbox 10/s, 300/min; daily 1000 × named licences |
| US-40 | Toolkit: `src/domains/users.py`, `update_user_expiry`, `search_users(query,…)`, `src/tests/test_users_script.py` | users-api AlmaAPITK, Testing | contradicted (source) | de2013d: `src/almaapitk/domains/users.py`; no `update_user_expiry`; `search_users(q, …)`; test script absent |
| US-41 | Email update = GET, change preferred email, full PUT | users-api Update User Email | production-inferred | prod `64d597c` runs `bulk_update_emails` → `update_user_email` (GET-mutate-PUT) on schedule |
| US-42 | Set processing: `get_set_members` returns dicts with `link` | users-api Process Users from Set | contradicted (source) | `Admin.get_set_members`/`get_user_set_members` return `List[str]`; `get_user` returns AlmaResponse |

Totals: documented 13, sandbox-confirmed 10, production-inferred 1, contradicted 11,
unresolved 3, untested 4 (42 claims).

## Corrections made

US-14 (warning on domain search), US-17 (`email_type`), US-23 (users error table), US-24
(no blocks endpoint), US-29 (loan error map), US-32 (post-cancel 401129, both files), US-34
(request op), US-35 (request error table), US-39 (rate limits), US-40 (toolkit method list and
test path), US-42 (set loop). Additions: `view=brief` drops notes/blocks/addresses (US-02),
limit cap behaviour (US-12), PUT exceptions in SKILL.md trap 1 (US-07).

## Open / untested

- All write-path behaviour: PUT validation (US-08), wrapped-note 400 (US-21), DELETE codes
  (US-10, US-11), loan-create expired-card code (US-28), post-cancel GET (US-32), PR values
  (US-36–38). Needs an authorised Sandbox fixture.
- US-14 rests on one address; repeat with a non-gmail domain before treating domain search as
  impossible.
- US-15, US-16: create/PUT validation rules need a write test.
- Toolkit observation (not a skill claim): `Users._extract_email_type` reads `email_type` as a
  dict, but the API returns a list, so the type is reported as a stringified list. Swagger also
  marks `user_id_type` required on purchase-request GET/POST, yet the Sandbox GET without it
  returned 200.
