---
name: primo-nde
description: Use when building, debugging or explaining customizations for Ex Libris Primo NDE (New Discovery Experience): the CustomModule template, custom components inside the Primo host, view customization packages, host-fetched assets (custom.css, custom.js, footer and homepage HTML), asset 404s, the local development proxy, or uploading a package to a view. For TAU's own build, views and package archive, the TAU_customModule repo's tau-nde-build skill holds the specifics.
---

# Primo NDE customization

**Maturity: seed (2026-11-24).** This skill is the home for Primo NDE knowledge as it is
researched. Each fact below carries a status; see [references/evaluation.md](references/evaluation.md).
Grow it from [references/research-backlog.md](references/research-backlog.md), adding a fact only
with its evidence.

## How it fits together

- An institution customizes NDE with a **custom module** built from Ex Libris' template,
  https://github.com/ExLibrisGroup/customModule (*repo-verified*: TAU's fork). Its README is the
  first place to look for setup, proxy and theme examples (*repo-verified*).
- The module's components load **into Primo's host application**: theme and typography changes
  reach the custom components, not necessarily the whole Primo UI (*repo-verified*, TAU notes).
- A **build produces a zip package**, uploaded by hand for a view in **Alma Back Office**. Pushing
  code deploys nothing (*repo-verified*). After an upload, check in the browser console that the
  page loaded the package you meant. TAU prints a boot banner for this (*repo-verified*).
- Assets are served under the view's custom path, `/nde/custom/<INST_ID>-<VIEW_ID>`. A package
  whose asset base disagrees with its view gets **404s for every image and icon**
  (*repo-verified*, TAU's `ASSET_BASE_URL`).
- Some assets (`custom.css`, `custom.js`, the footer and homepage HTML) are fetched by the host
  from a **fixed URL** that cannot vary per view (*repo-verified*).
- **Local development** runs the module through a proxy to a real Primo instance, so changes show
  without uploading (*repo-verified*: TAU's `npm run start:proxy`, `proxy/proxy.const.mjs`).

## Not yet verified (from general knowledge; check before relying on it)

- Loading mechanism: Angular with Webpack Module Federation into the NDE shell.
- Upload location in Alma: Discovery > View configuration > the view's customization package, then save and deploy.
- CSS scoping: Angular's emulated view encapsulation confines component CSS; global rules go in the package's global stylesheet (or `ViewEncapsulation.None` / `::ng-deep`).

## Where the specifics live

- TAU: `hagaybar/TAU_customModule`: `CLAUDE.md` (rules) and its `tau-nde-build` project skill.
- Bar-Ilan NDE work: `~/biu-nde/`.
