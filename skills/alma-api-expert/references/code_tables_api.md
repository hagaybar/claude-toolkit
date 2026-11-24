# Code Tables API Reference

The Code Tables API exposes Alma's configurable code tables — the controlled
vocabularies behind wrapped `{"value": "..."}` fields (formats, citation types,
levels of service, note types, etc.). Use it to **discover the valid values for a
field instead of guessing** (guessing is how you get cryptic errors like the RS
`format`/`citation_type` saga).

- **Ex Libris blog:** https://developers.exlibrisgroup.com/blog/Working-with-the-code-tables-API/
- **AlmaAPITK:** `almaapitk.domains.configuration.Configuration`

## Endpoints

| Purpose | Method + path |
|---|---|
| List all code tables (names) | `GET /almaws/v1/conf/code-tables` |
| Get one table + all its rows | `GET /almaws/v1/conf/code-tables/{codeTableName}` |
| Update a table (Feb-2021+ release) | `PUT /almaws/v1/conf/code-tables/{codeTableName}` |
| Mapping tables (separate concept) | `GET /almaws/v1/conf/mapping-tables/{tableName}` |

Optional query param: `scope` (e.g. `?scope=<InstitutionCode>`) — sparsely
documented; usually omit for institution-level tables.

## AlmaAPITK methods (Configuration domain, issue #26)

```python
from almaapitk import AlmaAPIClient
from almaapitk.domains.configuration import Configuration   # not exported at top level

cfg = Configuration(AlmaAPIClient("SANDBOX"))

cfg.list_code_tables()                 # -> List[Dict]  (GET all; unwraps {"code_table": [...]})
cfg.get_code_table("<CodeTableName>")  # -> Dict        (full table, rows at top-level "row")
cfg.update_code_table(table_dict)      # PUT (mutate rows in place, pass the dict back)
cfg.list_mapping_tables(); cfg.get_mapping_table("<name>"); cfg.update_mapping_table(...)
```

## Response shape (`get_code_table`)

- Top-level metadata: `name`, `description`, `sub_system`, … **plus `row`**.
- **`row` is a top-level array (singular key), NOT `rows.row`.** Access via
  `table["row"]`. This differs from some other Alma list endpoints that wrap as
  `{"rows": {"row": [...]}}`. *(Verified live against SANDBOX 2026-05-07 — from
  the AlmaAPITK `get_code_table` docstring.)*
- Each row has at least **`code`** and **`description`**. Alma code-table rows
  commonly also carry **`enabled`** and **`default`** booleans *(typical, not
  verified here — inspect the actual rows)*.
- Unknown table name → **HTTP 400, alma_code `90101` "Table does not exist."**

## Finding a table's NAME (the tricky part)

Code-table names are not always obvious and are **not** the UI label. Three ways:

1. **Enumerate:** `list_code_tables()` and search the returned `name`s.
2. **XSD annotation:** in the endpoint's XSD, a code-table-backed field carries an
   `xs:appinfo` → `xs:codeTable` annotation naming the table.
3. **Alma UI:** Configuration → (sub-system) → the code-table editor shows names.

## Killer use case — discover valid field values instead of guessing

```python
# Which citation_type / format codes does THIS tenant accept?
names = [t.get("name") for t in cfg.list_code_tables()]
hits  = [n for n in names if n and any(k in n.lower() for k in ("citation", "format", "resourcesharing"))]
print(hits)                                  # find the right table name

tbl = cfg.get_code_table("<TableNameFromHits>")
for r in tbl.get("row", []):
    print(r.get("code"), "-", r.get("description"), "| enabled:", r.get("enabled"))
```

This is exactly how to answer questions like *"is there a distinct `citation_type`
for electronic vs. physical articles?"* (recall `CR` = "Physical Article") — read
the code table rather than inferring from one working request.

## Gotchas

- **Row key is `row` (singular)** at the top level — not `rows.row`.
- **`90101` "Table does not exist"** → wrong/misspelled table name; enumerate first.
- Table **name ≠ UI label**; confirm via `list_code_tables()` or the XSD `codeTable` annotation.
- **Mapping tables** are a different endpoint (`/conf/mapping-tables/...`) with their own methods.
- `Configuration` is imported from `almaapitk.domains.configuration` (not the top-level package).

## See also

- Resource Sharing API (`alma-resource-sharing` skill) — the `format`/`citation_type`
  code values this API lets you confirm instead of guessing.
- [Admin API](admin_api.md) — other `conf` endpoints (libraries, circ desks, locations).
