#' @title Check compatibility of traits.build object
#' @description Function to check whether the data object has been compiled by the traits.build workflow and
#' therefore has a data structure that is appropriate for use with traits.use functions.
#'
#' A database built by traits.build 2.3 or later records the version of the
#' traits.build data model its tables follow, in `metadata$data_model_version`
#' (see [get_data_model_version()]). It is compatible if that version's major
#' number is one this version of traits.use reads
#' ([supported_data_model_majors()]). A database without that field is
#' compatible if `metadata$related_identifiers` says it was compiled by
#' traits.build, which is how releases built before the field existed, such as
#' AusTraits 7.0.0 and earlier, are recognised.
#'
#' @param database traits.build database (list object)
#' @param single_table_allowed logical for when the input might be a single table instead of a complete database; defaults to FALSE
#'
#' @return logical (T/F) output and messaging for incompatible versions
#' @keywords internal
#'
#' @author Elizabeth Wenk - e.wenk@unsw.edu.au

check_compatibility <- function(database, single_table_allowed = FALSE) {

  if (!is.null(dim(database)) & single_table_allowed == TRUE) {

    compatible <- TRUE

  } else {

    if (is.null(database$metadata)) {

      compatible <- FALSE

    } else if (!is.na(get_data_model_version(database))) {

      compatible <- data_model_supported(get_data_model_version(database))

    } else {

      # Built before traits.build recorded its data model version
      compiled_by_traits.build <-
        get_compiled_by_traits.build(database)

      if(is.null(compiled_by_traits.build) | nrow(compiled_by_traits.build) > 0) {
        compatible <- TRUE
      } else{
        compatible <- FALSE
      }

    }

  }

  invisible(compatible)

}


#' Major versions of the traits.build data model that traits.use reads
#'
#' The traits.build data model (<https://w3id.org/traits.build>) is versioned
#' `major.minor.patch`, and a change to the tables that an existing reader cannot
#' read is a new major version. traits.use reads every minor and patch version
#' of the major versions listed here. To read a new major version, add it here
#' and release traits.use **before** traits.build writes it: traits.build's
#' tests check that the version it writes is one traits.use reads.
#'
#' @return An integer vector.
#' @keywords internal
supported_data_model_majors <- function() {
  1L
}


#' The traits.build data model version a database's tables follow
#'
#' @param database traits.build database (list object)
#'
#' @return The version as a string, such as `"1.4.0"`, or `NA` for a database
#'   built before traits.build recorded it (traits.build 2.2 and earlier).
#' @keywords internal
get_data_model_version <- function(database) {
  version <- database$metadata$data_model_version
  if (is.null(version)) {
    return(NA_character_)
  }
  paste(as.character(unlist(version)), collapse = ", ")
}


#' Whether traits.use reads a data model version
#'
#' @param version A version string, from [get_data_model_version()].
#'
#' @return `TRUE` if `version` is `major.minor.patch` with a major version in
#'   [supported_data_model_majors()].
#' @keywords internal
data_model_supported <- function(version) {
  if (!data_model_version_valid(version)) {
    return(FALSE)
  }
  as.integer(sub("\\..*$", "", version)) %in% supported_data_model_majors()
}


#' Whether a data model version is a `major.minor.patch` version number
#' @noRd
data_model_version_valid <- function(version) {
  length(version) == 1 && !is.na(version) &&
    grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version)
}




#' Check compatibility of traits table
#'
#' @param trait_data the traits table in a traits.build database
#' @keywords internal
#' @return logical, TRUE indicating version traits table came from traits.build version > 1.0

check_traits_compatibility <- function(trait_data){
  # Check compatibility using column 
  if(any(names(trait_data) %in% c("treatment_context_id", "repeat_measurements_id"))){
    compatible <- TRUE
  } else
    compatible <- FALSE
  
  invisible(compatible)
}


#' Retrieve compiled by information from metadata table
#'
#' @param database traits.build database
#'
#' @return logical, TRUE indicating version traits table came from traits.build version > 1.0

get_compiled_by_traits.build <- function(database){
  database$metadata$related_identifiers %>% 
  convert_list_to_df2() %>%
  dplyr::filter(relation_type == "isCompiledBy") %>% 
  dplyr::filter(stringr::str_detect(identifier, "github.com/traitecoevo/traits.build"))
}