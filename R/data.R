#' A small subset of AusTraits, for examples
#'
#' @description A traits.build database with 24 of the datasets in AusTraits,
#'   the Australian plant trait database, compiled from AusTraits' source
#'   after the 7.0.0 release, in the form of the 8.0.0 release (traits.build
#'   data model 1.4.0). It is in the same form as the databases
#'   [load_database()] downloads, so every function in the package works on
#'   it, and the examples use it. For analysis, load a full release with
#'   [load_database()] instead.
#'
#' @format A list of class `traits.build`, with the tables of a traits.build
#'   database: `traits` (87,001 values of 151 traits for 7,259 taxa),
#'   `locations`, `contexts`, `methods`, `excluded_data`, `taxonomic_updates`,
#'   `taxa`, `identifiers`, `contributors`, `sources`, `definitions`, `schema`,
#'   `metadata` and `build_info`. Every observation names the reference it
#'   was taken from in `source_id` (3,294 name another study than their
#'   dataset), and the `methods` table has the reference columns
#'   `dataset_id_citation`, `secondary_id` and `secondary_citation` (see
#'   [join_sources()]).
#'
#' @details `austraits_lite` is compiled from AusTraits' source
#'   (<https://github.com/traitecoevo/austraits.build>) at a given commit, not
#'   taken from a release: traits.use is released before the AusTraits release
#'   whose data model it reads, so its example data follows the data model
#'   rather than the releases. This one was compiled from commit `a8ae3d94`
#'   with traits.build 3.0.0, so `metadata$version` is `"7.0.0.9000"` and
#'   `build_info$git_SHA` names the commit. Its values can differ a little
#'   from those of the same datasets in AusTraits 8.0.0.
#'
#' @source AusTraits, \doi{10.5281/zenodo.3568417}, whose compiled database is
#'   licensed under CC BY 4.0 (<https://creativecommons.org/licenses/by/4.0/>),
#'   compiled for 24 datasets by `data-raw/austraits_lite.R` in the package's
#'   GitHub repository. Please cite AusTraits as described in Falster et al.
#'   (2021) \doi{10.1038/s41597-021-01006-6}, and the original studies, listed
#'   in `sources`. The `taxa` table, compiled from curated taxon lists such as
#'   the Australian Plant Census, is released under CC BY 3.0, as its
#'   description in `schema` says. See the file `COPYRIGHTS` installed with
#'   the package.
#'
#' @examples
#' austraits_lite
#' summarise_database(austraits_lite, "trait_name")
"austraits_lite"
