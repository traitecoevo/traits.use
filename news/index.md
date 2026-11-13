# Changelog

## traits.use 0.1.0

- First release as `traits.use`, a generic package for loading and
  wrangling any traits.build database. The code and history come from
  the `austraits` package (version 3.1.1 and earlier, listed below),
  which becomes a thin AusTraits-specific layer over `traits.use`
  (austraits#188).
- Support databases built with traits.build 2.3, where every observation
  names the reference it was taken from in `source_id` (the `dataset_id`
  unless it came from another study) and the methods table’s reference
  columns are `dataset_id_type`, `dataset_id_citation`, `secondary_id`
  and `secondary_citation` (traitecoevo/traits.build#296). Older
  databases still work.
- New function
  [`join_sources()`](https://traitecoevo.github.io/traits.use/reference/join_sources.md)
  adds each observation’s references to the traits table:
  `dataset_id_citation`, `source_id_citation` (formatted from
  `sources[[source_id]]`), `secondary_id` and `secondary_citation`.
- [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md)
  takes its references from
  [`join_sources()`](https://traitecoevo.github.io/traits.use/reference/join_sources.md),
  so the flattened table has those columns in place of the methods
  table’s `source_*` columns.
- [`as_wide_table()`](https://traitecoevo.github.io/traits.use/reference/as_wide_table.md)
  has `dataset_id_citation`, `source_id_citation` and
  `secondary_citation` in place of `source_primary_citation` and
  `source_secondary_citation`.
- [`extract_data()`](https://traitecoevo.github.io/traits.use/reference/extract_data.md)
  keeps every reference the extracted observations cite, including the
  studies observations were taken from, which it used to drop; it no
  longer fails on a database without `source_secondary_key`.
- [`bind_databases()`](https://traitecoevo.github.io/traits.use/reference/bind_databases.md)
  warns when one citation key names different references in different
  datasets (titles or years differ), since `sources` keeps only one
  entry per key and the other is lost.
- `sources` can now be looked up by key with `$` (austraits#185):
  `database$sources$Falster_2005` returns the reference, as
  `database$sources[["Falster_2005"]]` does. Before, `$` on a `BibEntry`
  only did field access, so a key returned a list of `NULL`s.
  [`bind_databases()`](https://traitecoevo.github.io/traits.use/reference/bind_databases.md),
  [`load_austraits()`](https://traitecoevo.github.io/traits.use/reference/load_austraits.md)
  and
  [`extract_data()`](https://traitecoevo.github.io/traits.use/reference/extract_data.md)
  give `sources` the class `traits_build_sources` (see
  [`?traits_build_sources`](https://traitecoevo.github.io/traits.use/reference/traits_build_sources.md)),
  also for older releases; field access such as `sources$title`,
  printing and
  [`RefManageR::WriteBib()`](https://docs.ropensci.org/RefManageR/reference/WriteBib.html)
  output are unchanged.
- Added new function `load_database` which loads any traits.build
  database from its doi (Zenodo, Figshare or a doi resolving directly to
  an .rds file)
- Fix bug in `load_austraits` and `load_database` downloads: when the
  temporary folder was on a different drive to `path`, the file was
  saved under its temporary name and could not be loaded. The user’s
  `timeout` option is now also restored after a download.
- Fix bug in `plot_locations` that silently left out locations east of
  153°E (Brisbane, the Gold Coast, Byron Bay) and north of 9.5°S (Torres
  Strait), about 2% of AusTraits 5.0.0 records with coordinates.
  Locations beyond the map of Australia are now reported in a message.
  The new argument `basemap = NULL` draws every location without the
  map, for databases from outside Australia. `...` is now passed on to
  `geom_pointdensity()`, and `feature = NA` works.
