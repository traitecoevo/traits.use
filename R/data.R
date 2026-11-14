#' A small subset of AusTraits, for examples
#'
#' @description A traits.build database with 24 of the datasets in AusTraits
#'   7.0.0, the Australian plant trait database. It is in the same form as the
#'   databases [load_database()] downloads, so every function in the package
#'   works on it, and the examples use it. For analysis, load a full release
#'   with [load_database()] instead.
#'
#' @format A list of class `traits.build`, with the tables of a traits.build
#'   database: `traits` (90,568 values of 151 traits for 7,259 taxa),
#'   `locations`, `contexts`, `methods`, `excluded_data`, `taxonomic_updates`,
#'   `taxa`, `identifiers`, `contributors`, `sources`, `definitions`, `schema`,
#'   `metadata` and `build_info`. AusTraits 7.0.0 fills in `source_id` for
#'   only a few datasets, and predates the reference columns of the `methods`
#'   table that traits.build 2.3 introduced (it has `source_primary_key` and
#'   others; see [join_sources()]).
#'
#' @source AusTraits 7.0.0, \doi{10.5281/zenodo.15718081}, licensed under
#'   CC BY 4.0 (<https://creativecommons.org/licenses/by/4.0/>), cut down to
#'   24 datasets with [extract_dataset()] (the script is `data-raw/create_data.R`
#'   in the package's GitHub repository). Please cite AusTraits as described
#'   in Falster et al. (2021) \doi{10.1038/s41597-021-01006-6}, and the
#'   original studies, listed in `sources` (as in the full release, a few keys
#'   in `source_id` and the `methods` table, such as unpublished data, have no
#'   entry). The `taxa` table, compiled from curated taxon lists such as the
#'   Australian Plant Census, is released under CC BY 3.0, as its description
#'   in `schema` says. See the file `COPYRIGHTS` installed with the package.
#'
#' @examples
#' austraits_lite
#' summarise_database(austraits_lite, "trait_name")
"austraits_lite"
