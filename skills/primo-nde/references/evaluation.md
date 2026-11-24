# Evaluation: primo-nde

- **Date:** 2026-11-24 · **Reviewer:** agent, from TAU_customModule evidence · not independently evaluated
- **Baseline test (no skill, 2026-11-24):** a fresh agent answered 5 general NDE questions plausibly
  (custom module, upload, CSS scoping, local proxy, reference repo), from memory and unverified.
  Its 404 answer missed the view/asset-base mismatch. The skill exists as the home for growing,
  evidence-backed knowledge (owner's decision 2026-11-24), not to fix a large baseline gap.

| ID | Claim | Verdict | Evidence |
|---|---|---|---|
| N-01 | Customization = a module built from ExLibrisGroup/customModule | repo-verified | TAU_customModule is a fork of it |
| N-02 | Components load into the Primo host; theming reaches custom components only | repo-verified | TAU_customModule CLAUDE.md notes |
| N-03 | Packages are zips uploaded by hand in Alma Back Office; a push deploys nothing | repo-verified | TAU deploy practice, boot-banner check |
| N-04 | Assets under `/nde/custom/<INST>-<VIEW>`; mismatch → 404s for every asset | repo-verified | TAU `build-settings.env` / `ASSET_BASE_URL` incident notes |
| N-05 | custom.css, custom.js, footer and homepage HTML fetched from a fixed URL | repo-verified | TAU per-view isolation design (2026-09-09) |
| N-06 | Local development through a proxy to a real Primo instance | repo-verified | TAU `npm run start:proxy` |
| N-07 | Module Federation loading | unverified | general knowledge |
| N-08 | Upload path in Alma's Discovery view configuration | unverified | general knowledge |
| N-09 | Angular view encapsulation and global stylesheet | unverified | general knowledge |
