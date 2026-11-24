# traits.use — agent & contributor guide

`traits.use` is an R package for **loading, exploring and wrangling
data** from any `traits.build` relational trait database, such as
AusTraits. It began as the `austraits` package and was split out in 2026
(traitecoevo/austraits#188, history carried over). `austraits` (4.0.0)
is now a thin AusTraits-specific layer over it. 0.1.1 (2026-11-23) was a
GitHub-only release. The next release, the one for AusTraits 8.0.0 and
the first on CRAN, is **1.0.0** (maintainer Elizabeth Wenk); it is
tracked in \#17 and its CRAN preparation in \#13.

## Repo-local guidance

- **Code:** `R/` (functions), `tests/` (testthat), `man/` (generated
  docs), `NAMESPACE`, `data-raw/` and `inst/` hold raw assets (incl. the
  cheatsheet); `data/austraits_lite.rda` is the exported example
  database (24 datasets, used by the examples), regenerated with
  `data-raw/austraits_lite.R`; `R/sysdata.rda` holds the tests’
  fixtures: `austraits_5.0.0_lite` (23 datasets of 5.0.0, the main one)
  and tiny 3.0.2/4.2.0 ones for version checks, regenerated with
  `data-raw/create_data.R`.
- **`austraits_lite` follows the data model, not the AusTraits
  releases** (decided 2026-11-24, \#13). It is compiled from
  austraits.build source at a pinned commit, because traits.use must be
  released before the AusTraits release whose data model it reads.
  Rebuild it whenever traits.build changes the data model; `test-data.R`
  fails where traits.build is installed until you do. Release order:
  traits.build develop → rebuild `austraits_lite` → traits.use release →
  traits.build release → AusTraits release. Update
  [`?austraits_lite`](https://traitecoevo.github.io/traits.use/reference/austraits_lite.md)
  (`R/data.R`) and `inst/COPYRIGHTS` with the commit.
- **Access entry point:**
  [`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
  (`R/load_database.R`) loads any traits.build database from its doi
  (Zenodo, Figshare, or a doi resolving directly to an `.rds`).
  `flattened = TRUE` loads the flattened table and `means = TRUE` the
  observed means published with the release (`*-observed-means.csv.gz`);
  `means_file()` picks that file and `cached_records()`
  (`R/database_cache.R`) must know every kind of file
  [`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
  downloads.
  [`list_versions()`](https://traitecoevo.github.io/traits.use/reference/list_versions.md)
  (`R/list_versions.R`) lists a record’s releases; it resolves a doi
  with the same helpers as
  [`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md),
  at the end of `R/load_database.R`.
- **AusTraits-specific code lives in `austraits`, not here** (decided
  2026-11-14, \#13): `load_austraits()`, `get_versions()` /
  `get_version_latest()`, the AusTraits vignette and the map of
  Australia. The generic part of `get_versions()` is
  [`list_versions()`](https://traitecoevo.github.io/traits.use/reference/list_versions.md)
  here (#52), which lists the releases of any Zenodo or Figshare record.
  [`plot_locations()`](https://traitecoevo.github.io/traits.use/reference/plot_locations.md)
  draws over a world map cropped to the locations by default
  (`inst/extdata/world_land.rds`, from `data-raw/world_land.R`), and
  takes a `basemap` data frame so `austraits` can pass its map.
- **Wrangle/extract:** `extract_*()` (data/dataset/taxa/trait),
  `join_*()` (taxa, methods, contributors, locations, context/location
  properties), `lookup_*()`, `trait_pivot_longer/wider()`,
  [`summarise_database()`](https://traitecoevo.github.io/traits.use/reference/summarise_database.md),
  [`bind_databases()`](https://traitecoevo.github.io/traits.use/reference/bind_databases.md),
  [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md),
  [`as_wide_table()`](https://traitecoevo.github.io/traits.use/reference/as_wide_table.md).
- **Trait means:**
  [`summarise_trait_means()`](https://traitecoevo.github.io/traits.use/reference/summarise_trait_means.md)
  (`R/summarise_trait_means.R`, \#50) gives one row per taxon and trait:
  the observed mean of a numeric trait (a geometric mean) and the most
  frequent value of a categorical one, optionally split `by` further
  variables. It takes both input formats. AusTraits publishes its output
  with each release (austraits.build’s `post_export()`), and the API and
  portal are to read that file, so a change to the method changes
  published numbers: say so in NEWS. The method’s terms (“observed
  mean”, never “average”) follow `terminology.md` in
  traitecoevo/austraits-means. It is computed with group indices and
  [`rowsum()`](https://rdrr.io/r/base/rowsum.html), not a grouped
  `summarise()`, which is about a hundred times slower on a full
  database (3.5 s against 100 s on AusTraits); keep it that way.
- **Two input formats, told apart by class** (#41): the relational
  database (list, class `traits.build`) and a flat table (data frame;
  [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md)
  output has class `traits.build_flat` and a `traits.build_stamp`
  attribute). `database_format()` in `R/check_compatibility.R` is the
  one place that decides; don’t branch on
  [`dim()`](https://rdrr.io/r/base/dim.html) or `is_tibble()`.
  `extract_trait/taxa/dataset()`,
  [`summarise_database()`](https://traitecoevo.github.io/traits.use/reference/summarise_database.md)
  and the plots take both, so test them with both
  (`tests/testthat/test-flat.R`); everything else stops on a flat table
  via
  [`check_compatibility()`](https://traitecoevo.github.io/traits.use/reference/check_compatibility.md).
- **Build/test (standard R-package workflow):** `devtools::load_all()`,
  `devtools::test()`, `devtools::check()`. The package targets
  `R >= 4.1.0` (it uses `|>`); tidyverse-style Imports (dplyr, tidyr,
  purrr, etc.). Lifecycle badge is **experimental** until the first CRAN
  release.
- **Default branch:** `master`. Docs/pkgdown site at
  <https://traitecoevo.github.io/traits.use/>.
- **CRAN-bound:** `traits.use` must never `Import`/`Depend` on
  traits.build (not on CRAN, and +57 recursive dependencies). Keep
  network tests behind `skip_on_cran()` / `skip_if_offline()`.

> Heads-up: `traits.use` (like `austraits` before it) is the
> *downstream* access/wrangle layer in the data pipeline, but the
> R-package install graph runs the other way — `traits.build` **Depends
> on `traits.use` (\>= 0.1.1)** and imports a few conversion helpers
> from it (`convert_df_to_list`, `convert_list_to_df1`,
> `convert_list_to_df2`, `bind_databases`, `flatten_database`) and
> re-exports the trait plots
> ([`plot_trait_distribution()`](https://traitecoevo.github.io/traits.use/reference/plot_trait_distribution.md),
> [`plot_categorical_trait_distribution()`](https://traitecoevo.github.io/traits.use/reference/plot_categorical_trait_distribution.md),
> [`plot_trait_distribution_jitter()`](https://traitecoevo.github.io/traits.use/reference/plot_trait_distribution_jitter.md)).
> Changing any of these can break `traits.build`; run its tests after
> touching them. `austraits` and `austraits.portal` also `Import`
> traits.use.

> Heads-up: from Sept 2024 the code works against any `traits.build`
> database (not just `austraits.build`). `austraits.build` versions **\<
> 5.0 are unsupported** by the current package — older builds need an
> older tagged `austraits` (e.g. `traitecoevo/austraits@v2.2.2`).

------------------------------------------------------------------------

## AusTraits family — cross-package context

`traits.use` is part of the **AusTraits family** (a subset of the
[`traitecoevo`](https://github.com/traitecoevo) org) — here, the
user-facing access/wrangle API (R package) for traits.build-format
databases, including AusTraits; loads the released `.rds` via
[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md).
Family-wide concerns are documented centrally in
**[austraits-meta](https://github.com/traitecoevo/austraits-meta)** —
don’t restate them here, read them there:

- **Start with
  [`AGENTS.md`](https://github.com/traitecoevo/austraits-meta/blob/master/AGENTS.md)**
  — pipeline order, who owns what, dependency direction, source-of-truth
  rules, cross-boundary artifacts, gotchas.
- **[`dependencies.yml`](https://github.com/traitecoevo/austraits-meta/blob/master/dependencies.yml)**
  — machine-readable package graph + cross-boundary artifacts.
- **[`governance/`](https://github.com/traitecoevo/austraits-meta/tree/master/governance)**
  — label taxonomy, board \#9 conventions, release playbooks, triage.

**Filing issues:** the whole family is tracked on one board, [AusTraits
\#9](https://github.com/orgs/traitecoevo/projects/9) (new issues
auto-add to it). Follow the [issue & labelling
guide](https://github.com/traitecoevo/austraits-meta/blob/master/governance/issue-guide.md):
pick one work-type label (`bug` / `task` / `epic`); Status and Priority
are set on the board, not as labels.

**Commit messages:** every family repo squash-merges, so the **PR title
and body become the permanent commit message**. Keep the subject ≤50
characters as typed and the body ≤10 lines; put the working detail —
what you tried, benchmarks, test counts, rejected alternatives — in the
**first PR comment** instead. Full convention:
[`commit-messages.md`](https://github.com/traitecoevo/austraits-meta/blob/master/governance/commit-messages.md).

> austraits-meta is hand-maintained prose — a map, not ground truth.
> Verify specifics against the actual repos.
