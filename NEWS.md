# traits.use 0.1.0

- First release as `traits.use`, a generic package for loading and wrangling any traits.build database. The code and history come from the `austraits` package (version 3.1.1 and earlier, listed below), which becomes a thin AusTraits-specific layer over `traits.use` (austraits#188).
- What is specific to AusTraits stays in the `austraits` package: `load_austraits()`, `get_versions()` and `get_version_latest()` (load AusTraits with `load_database()` and its doi instead), the AusTraits Getting Started vignette, and the map of Australia used by `plot_locations()`.
- Requires R 4.1.0 or later, as the code uses the native pipe `|>`.
- New dataset `austraits_lite`: 23 datasets from AusTraits 5.0.0 (CC BY 4.0), a small traits.build database to try the package on without downloading anything. The examples now use it and run; those of `load_database()`, which download, run only in interactive sessions.
- Fix bug in `as_wide_table()`, which failed on a database without contexts or without known location properties (8 of the 23 datasets in `austraits_lite`, each on its own). Such databases now give the same columns, empty where there is nothing to fill. The location columns now always come in the order `latitude (deg)`, `longitude (deg)`, `location`.
- Fix bug in `separate_trait_values()`, which lost values: rows whose `method_context_id` or `repeat_measurements_id` was `NA` were merged before being separated (AusTraits 5.0.0's ABRS_1981 went from 36,603 rows to 28,138 when bound and 19,675 when separated again; it now returns to 36,603). It also returned `NULL` when there was nothing to separate, and left missing values as the text `"NA"` in `basis_of_value`. Its `definitions` argument is no longer needed.
- `join_identifiers()` works on a database without an identifiers table (built before traits.build added it), adding an empty `identifier_types` column as for an empty table, rather than failing.
- New plotting functions from austraits.portal (#15, #7): `plot_trait_distribution_jitter()` plots a numeric trait by group, about 3 to 10 times faster than the beeswarm plot on AusTraits 5.0.0 traits; `plot_categorical_trait_distribution()` plots the proportion of each family's taxa with each value of a categorical trait; `plot_trait_distribution()` picks between them from the trait's type. They return a ggplot object, match the trait name exactly, leave out bins and ranges, and keep negative values within the x-axis limits.
- `plot_trait_distribution_beeswarm()` is deprecated: it draws the jitter plot, with a warning. ggbeeswarm and gridExtra are no longer needed.
- The plotting functions say which suggested packages they need (ggplot2 and others) when one is not installed, rather than failing partway.
- `plot_locations()` draws without a map by default. Its `basemap` argument takes a data frame of map cells (columns `x` and `y`) to draw the locations over; `basemap = "australia"` now gives an error pointing to the `austraits` package.
- `extract_data()` on the contexts table now honours `partial_matches_allowed`: matching is case-insensitive by default, exact with `FALSE` (so brackets are read literally), and several values are combined. `partial_matches_allowed` is now documented in all `extract_*()` functions.
- Support databases built with traits.build 2.3, where every observation names the reference it was taken from in `source_id` (the `dataset_id` unless it came from another study) and the methods table's reference columns are `dataset_id_type`, `dataset_id_citation`, `secondary_id` and `secondary_citation` (traitecoevo/traits.build#296). Older databases still work.
- New function `join_sources()` adds each observation's references to the traits table: `dataset_id_citation`, `source_id_citation` (formatted from `sources[[source_id]]`), `secondary_id` and `secondary_citation`.
- `flatten_database()` takes its references from `join_sources()`, so the flattened table has those columns in place of the methods table's `source_*` columns.
- `as_wide_table()` has `dataset_id_citation`, `source_id_citation` and `secondary_citation` in place of `source_primary_citation` and `source_secondary_citation`.
- `extract_data()` keeps every reference the extracted observations cite, including the studies observations were taken from, which it used to drop; it no longer fails on a database without `source_secondary_key`.
- `bind_databases()` warns when one citation key names different references in different datasets (titles or years differ), since `sources` keeps only one entry per key and the other is lost.
- `sources` can now be looked up by key with `$` (austraits#185): `database$sources$Falster_2005` returns the reference, as `database$sources[["Falster_2005"]]` does. Before, `$` on a `BibEntry` only did field access, so a key returned a list of `NULL`s. `bind_databases()`, `load_database()` and `extract_data()` give `sources` the class `traits_build_sources` (see `?traits_build_sources`), also for older releases; field access such as `sources$title`, printing and `RefManageR::WriteBib()` output are unchanged.
- Added new function `load_database` which loads any traits.build database from its doi (Zenodo, Figshare or a doi resolving directly to an .rds file). By default it keeps downloads in a per-user cache folder (`tools::R_user_dir()`, or the `traits.use.cache_dir` option), so each release is downloaded once per computer and shared by every project (#22); give `path` to keep a copy with a project instead. Nothing is written to the working directory unasked.
- New functions `database_cache_dir()`, `list_cached_databases()` and `clear_database_cache()` show where the cache is, what it holds, how big it is and when each database was last used, and delete releases you no longer need (`clear_database_cache(older_than = 180)` deletes those not used for six months). They only touch files `load_database()` wrote, also in a folder given as `path`.
- `load_database()` loads a saved database when the repository cannot be reached (e.g. offline), using its saved record, rather than failing.
- Fix bug in `load_database` downloads: when the temporary folder was on a different drive to `path`, the file was saved under its temporary name and could not be loaded. The user's `timeout` option is now also restored after a download.
- Fix bug in `plot_locations` that silently left out locations east of 153°E (Brisbane, the Gold Coast, Byron Bay) and north of 9.5°S (Torres Strait), about 2% of AusTraits 5.0.0 records with coordinates. Locations beyond the map are now reported in a message. `...` is now passed on to `geom_pointdensity()`, and `feature = NA` works.

# austraits 3.1.1
- Fix bug in function `load_austraits` that was preventing it from loading austraits.build v.7.0.0, as both relational and flattened database versions are now on Zenodo. For now, ignoring flattened data table.

# austraits 3.1.0
- Change functions to work with traits.build databases that include an identifiers table (or ones that don't)

# austraits 3.0.2
- Updated dependencies, placing graphics related packages in Suggests
- Added internal function to check the compatibility of databases
- Added internal function notify users that some database versions will not be supported
- The following functions will no longer support AusTraits version < 5.0.0:
    - `extract_*` 
    - `trait_pivot_wider`
    - `join_*`
    - `plot_site/locations`
    - `plot_trait_beeswarm`
    - `as_wide_table`
- `trait_pivot_longer` is deprecated
- `summarise_trait_means` will trigger warning due to uninformed calculations
- Added new function `extract_data`
- Added new function `bind_databases`
- Added new function `flatten_databases`
- Updated print function `print.traits.build` - thanks @Rekyt!