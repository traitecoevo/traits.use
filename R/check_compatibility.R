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
#' A flat table (see `database_format()`) is accepted only when
#' `single_table_allowed` is `TRUE`, and, if [flatten_database()] stamped it
#' with a data model version, only if that version is supported; otherwise it
#' stops with an error saying the function needs the relational database. Anything that is neither a
#' relational database nor a traits table stops with an error.
#'
#' @param database traits.build database (list object), or a flat table from one
#' @param single_table_allowed logical: can the calling function take a flat
#'   table (a flattened database, or a traits table)? Defaults to `FALSE`
#' @param call the calling function's environment, named in errors
#'
#' @return logical (T/F) output and messaging for incompatible versions
#' @keywords internal
#'
#' @author Elizabeth Wenk - e.wenk@unsw.edu.au

check_compatibility <- function(database, single_table_allowed = FALSE, call = rlang::caller_env()) {

  if (database_format(database, call = call) == "flat") {

    if (!isTRUE(single_table_allowed)) {
      abort_flat_input(call = call)
    }

    # A stamped flat table records its data model version too; an unstamped
    # one (a traits table, or a release flattened before the stamp) is let in
    version <- get_data_model_version(database)
    compatible <- is.na(version) || data_model_supported(version)

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
#' The traits.build data model (<https://w3id.org/traits.build/>) is versioned
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
#' The one place the version is read, for both the compatibility check and the
#' stamp [flatten_database()] puts on a flat table.
#'
#' @param database traits.build database (list object), or a flat table
#'
#' @return The version as a string, such as `"1.4.0"`, or `NA` for a database
#'   built before traits.build recorded it (traits.build 2.2 and earlier), and
#'   for a flat table without a stamp. A field that is there but is not one
#'   string is returned as text, e.g. `"NA"` or `""`, which
#'   [data_model_supported()] rejects.
#' @keywords internal
get_data_model_version <- function(database) {
  if (is.data.frame(database)) {
    # stamp_flat() writes NA when the database recorded no version
    version <- attr(database, "traits.build_stamp")[["data_model_version"]]
    if (is.null(version) || (length(version) == 1 && is.na(version))) {
      return(NA_character_)
    }
  } else {
    version <- database$metadata$data_model_version
    if (is.null(version)) {
      return(NA_character_)
    }
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
  # as.numeric, not as.integer: a major past the integer range is just unsupported
  as.numeric(sub("\\..*$", "", version)) %in% supported_data_model_majors()
}


#' Whether a data model version is a `major.minor.patch` version number
#' @noRd
data_model_version_valid <- function(version) {
  length(version) == 1 && !is.na(version) &&
    grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", version)
}


#' Is a database relational or flat?
#'
#' traits.use takes a database in one of two formats, told apart by class:
#'
#' - **relational**: a list of tables, of class `traits.build`, as a release's
#'   `.rds` holds and [extract_data()] returns. A list with a `traits` table
#'   but no class is taken as relational too.
#' - **flat**: one table, a data frame. A table [flatten_database()] makes has
#'   the class `traits.build_flat` and is stamped with the database it came
#'   from (see `stamp_flat()`); a database's `traits` table, or a flattened
#'   table made before the stamp, is a flat table without the stamp.
#'
#' Anything else, including a data frame with neither a `trait_name` nor a
#' `dataset_id` column, stops with an error.
#'
#' @param database the object passed as a function's `database`
#' @param call the calling function's environment, named in errors
#' @return `"relational"` or `"flat"`
#' @noRd
#' @keywords internal
database_format <- function(database, call = rlang::caller_env()) {
  if (inherits(database, "traits.build_flat") || is.data.frame(database)) {
    # Every table made from a database has one of these: the traits table, a
    # flattened one, a wide one from trait_pivot_wider(), a table of locations
    if (!any(c("trait_name", "dataset_id") %in% names(database))) {
      cli::cli_abort(c(
        "x" = "{.arg database} is a data frame without a {.field trait_name} or {.field dataset_id} column, so not a table from a traits.build database.",
        "i" = "Pass a traits.build database, its {.field traits} table, or a table made by {.fn flatten_database}."
      ), call = call)
    }
    return("flat")
  }
  if (inherits(database, "traits.build") ||
      (is.list(database) && "traits" %in% names(database))) {
    return("relational")
  }
  cli::cli_abort(c(
    "x" = "{.arg database} must be a traits.build database or a table from one, not {.obj_type_friendly {database}}.",
    "i" = "Load a database with {.fn load_database}."
  ), call = call)
}

#' Is `database` a flat table?
#' @noRd
#' @keywords internal
is_flat <- function(database, call = rlang::caller_env()) {
  database_format(database, call = call) == "flat"
}

#' Stop because a function that needs the relational database was given a flat table
#' @noRd
#' @keywords internal
abort_flat_input <- function(call = rlang::caller_env()) {
  cli::cli_abort(c(
    "x" = "{.arg database} is a single table, but this needs the relational database (a list of tables).",
    "i" = "A flattened table or {.field traits} table has its other tables joined in, or left out.",
    "i" = "Use the database the table came from, e.g. {.code load_database(doi)} without {.code flattened = TRUE}."
  ), call = call)
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


#' Version of traits.build that built a relational database
#'
#' From the `isCompiledBy` entries of `metadata$related_identifiers` naming
#' traits.build's repository: the `version` traits.build records, if any entry
#' has one, otherwise the release tag in an identifier
#' (".../traits.build/releases/tag/v2.1.0"), which is typed by hand and may
#' be stale.
#'
#' @param database traits.build database (list object)
#' @return the version as a string, or `NA_character_`
#' @noRd
#' @keywords internal
traits_build_version <- function(database) {
  ids <- database[["metadata"]][["related_identifiers"]]
  if (!is.list(ids) || length(ids) == 0) {
    return(NA_character_)
  }
  # traits.build's own repository, not e.g. austraits.build's
  is_traits_build <- function(id) {
    identical(id[["relation_type"]], "isCompiledBy") &&
      grepl("github\\.com/traitecoevo/traits\\.build(/|$)", scalar_or_na(id[["identifier"]]))
  }
  compiled_by <- Filter(is_traits_build, ids)
  first_found <- function(x) {
    x <- x[!is.na(x)]
    if (length(x) == 0) NA_character_ else x[[1]]
  }
  # The `version` traits.build records takes precedence over a release tag
  # typed into a database's metadata, which may be stale
  recorded <- first_found(vapply(compiled_by, function(id) scalar_or_na(id[["version"]]), character(1)))
  if (!is.na(recorded)) {
    return(recorded)
  }
  first_found(vapply(compiled_by, function(id) {
    stringr::str_match(scalar_or_na(id[["identifier"]]), "traits\\.build/releases/tag/v?([0-9][0-9.]*[0-9])")[, 2]
  }, character(1)))
}

#' A single value as a string, or NA if there isn't one
#' @noRd
#' @keywords internal
scalar_or_na <- function(x) {
  if (length(x) != 1 || is.list(x) || is.na(x)) {
    return(NA_character_)
  }
  as.character(x)
}
