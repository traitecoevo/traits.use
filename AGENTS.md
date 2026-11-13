# traits.use — agent & contributor guide

`traits.use` is an R package for **loading, exploring and wrangling data** from any `traits.build` relational trait database, such as AusTraits. It began as the `austraits` package and was split out in 2026 (traitecoevo/austraits#188, history carried over). `austraits` is becoming a thin AusTraits-specific layer over it. The first CRAN release (0.1.0, maintainer Elizabeth Wenk) is tracked in #13.

## Repo-local guidance

- **Code:** `R/` (functions), `tests/` (testthat), `man/` (generated docs), `NAMESPACE`,
  `vignettes/`. `data/`, `data-raw/`, and `inst/` hold packaged/raw assets (incl. the cheatsheet).
- **Access entry point:** `load_austraits()` (`R/load_austraits.R`) downloads/loads a released
  AusTraits build (`.rds`); `get_versions()` / `get_version_latest()` resolve versions.
  `load_database()` (`R/load_database.R`) loads any traits.build database from its doi
  (Zenodo, Figshare, or a doi resolving directly to an `.rds`).
- **Wrangle/extract:** `extract_*()` (data/dataset/taxa/trait), `join_*()` (taxa, methods,
  contributors, locations, context/location properties), `lookup_*()`, `trait_pivot_longer/wider()`,
  `summarise_database()`, `bind_databases()`, `flatten_database()`, `as_wide_table()`.
- **Build/test (standard R-package workflow):** `devtools::load_all()`, `devtools::test()`,
  `devtools::check()`. The package targets `R >= 4.0.0`; tidyverse-style Imports (dplyr, tidyr,
  purrr, etc.). Lifecycle badge is **experimental** until the first CRAN release.
- **Default branch:** `master`. Docs/pkgdown site at <https://traitecoevo.github.io/traits.use/>.
- **CRAN-bound:** `traits.use` must never `Import`/`Depend` on traits.build (not on CRAN, and +57 recursive dependencies). Keep network tests behind `skip_on_cran()` / `skip_if_offline()`.

> Heads-up: `traits.use` (like `austraits` before it) is the *downstream* access/wrangle layer in the data pipeline, but the
> R-package install graph runs the other way — `traits.build` currently **Imports `austraits`** (moving to `traits.use`, see austraits#188) and
> re-exports a few conversion helpers from it (`convert_df_to_list`, `convert_list_to_df1`,
> `convert_list_to_df2`, `bind_databases`, `flatten_database` — all in `NAMESPACE`). Changing those
> helpers can break `traits.build`; run its tests after touching them.

> Heads-up: from Sept 2024 the code works against any `traits.build` database (not just
> `austraits.build`). `austraits.build` versions **< 5.0 are unsupported** by the current package —
> older builds need an older tagged `austraits` (e.g. `traitecoevo/austraits@v2.2.2`).

---

## AusTraits family — cross-package context

`traits.use` is part of the **AusTraits family** (a subset of the
[`traitecoevo`](https://github.com/traitecoevo) org) — here, the user-facing access/wrangle API (R
package) for traits.build-format databases, including AusTraits; loads the released `.rds` via
`load_austraits()`. Family-wide concerns are documented centrally in
**[austraits-meta](https://github.com/traitecoevo/austraits-meta)** — don't restate them here, read
them there:

- **Start with [`AGENTS.md`](https://github.com/traitecoevo/austraits-meta/blob/master/AGENTS.md)** —
  pipeline order, who owns what, dependency direction, source-of-truth rules, cross-boundary
  artifacts, gotchas.
- **[`dependencies.yml`](https://github.com/traitecoevo/austraits-meta/blob/master/dependencies.yml)** —
  machine-readable package graph + cross-boundary artifacts.
- **[`governance/`](https://github.com/traitecoevo/austraits-meta/tree/master/governance)** —
  label taxonomy, board #9 conventions, release playbooks, triage.

**Filing issues:** the whole family is tracked on one board,
[AusTraits #9](https://github.com/orgs/traitecoevo/projects/9) (new issues auto-add to it). Follow
the [issue & labelling guide](https://github.com/traitecoevo/austraits-meta/blob/master/governance/issue-guide.md):
pick one work-type label (`bug` / `task` / `epic`); Status and Priority are set on the board, not as
labels.

**Commit messages:** every family repo squash-merges, so the **PR title and body become the permanent
commit message**. Keep the subject ≤50 characters as typed and the body ≤10 lines; put the working
detail — what you tried, benchmarks, test counts, rejected alternatives — in the **first PR comment**
instead. Full convention:
[`commit-messages.md`](https://github.com/traitecoevo/austraits-meta/blob/master/governance/commit-messages.md).

> austraits-meta is hand-maintained prose — a map, not ground truth. Verify specifics against the
> actual repos.
