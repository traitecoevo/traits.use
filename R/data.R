#' A small subset of AusTraits, for examples
#'
#' @description A traits.build database with 23 of the datasets in AusTraits
#'   5.0.0, the Australian plant trait database. It is in the same form as the
#'   databases [load_database()] downloads, so every function in the package
#'   works on it, and the examples use it. For analysis, load a full release
#'   with [load_database()] instead.
#'
#' @format A list of class `traits.build`, with the tables of a traits.build
#'   database: `traits` (115,733 values of 143 traits for 7,324 taxa),
#'   `locations`, `contexts`, `methods`, `excluded_data`, `taxonomic_updates`,
#'   `taxa`, `contributors`, `sources`, `definitions`, `schema`, `metadata`
#'   and `build_info`. AusTraits 5.0.0 predates the `identifiers` table and
#'   the `source_id` column, which newer releases add.
#'
#' @source AusTraits 5.0.0, \doi{10.5281/zenodo.10156222}, licensed under
#'   CC BY 4.0 (<https://creativecommons.org/licenses/by/4.0/>), cut down to
#'   23 datasets with [extract_dataset()] (the script is `data-raw/create_data.R`
#'   in the package's GitHub repository). Please cite AusTraits as described
#'   in Falster et al. (2021) \doi{10.1038/s41597-021-01006-6}, and the
#'   original studies, listed in `sources`.
#'
#' @examples
#' austraits_lite
#' summarise_database(austraits_lite, "trait_name")
"austraits_lite"
