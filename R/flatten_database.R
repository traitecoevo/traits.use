#' Create combined traits.build table
#'
#' Create a single database output that merges together the information
#' in all relational tables within a traits.build database.
#' Trait measurements are still output in long format (1 row per trait value),
#' but all measurement-related metadata (methods, location properties, context properties, contributors, references)
#' are now included as additional columns in a single table. References are joined by [join_sources()], so
#' `vars$sources` selects among its columns, and the reference columns of the methods table are not repeated.
#'
#' @param database traits.build database (list object)
#' @param format A parameter for the locations, contexts and data contributors tables specifying how data are packed. 
#' All three can be formatted as a single compacted column(s) will have a human readable column ("single_column_pretty")
#' or using json ("single_column_json") syntax. For location properties or context properties  there is also 
#' the option to add each `location_property` or `context_property` to the traits table as its own column ("many_columns");
#' the contributors column defaults to "single_column_pretty" when this option is selected.
#' @param vars List specifying which columns or properties to include from each table. The detail is for all columns/properties to be included.
#' @param include_description A logical indicating whether to include (TRUE) or omit (FALSE) the context_property descriptions; defaults to TRUE.
#'
#' @return A table combining information in 8 traits.build relational tables: traits, locations, contexts, methods, taxa, taxonomic_updates, contributors, and identifiers.
#' It is a tibble of class `traits.build_flat`, stamped with the database it came from: the attribute
#' `traits.build_stamp` is a list of its `title`, `version`, `doi`, `data_model_version` and
#' `traits_build_version` (each `NA` if the database does not record it). The stamp is kept by
#' `saveRDS()` and, with the class, by `arrow::write_parquet()`, which stores it in the file's metadata,
#' and is shown when the table is printed. [extract_trait()], [extract_taxa()], [extract_dataset()],
#' [summarise_database()] and the plots take this table as well as the relational database, and keep the
#' stamp on what they return.
#' @examples
#' flat <- austraits_lite %>%
#'   extract_dataset("Falster_2003") %>%
#'   flatten_database()
#' flat
#' attr(flat, "traits.build_stamp")$version
#' @export
#'
#' @usage flatten_database(database, format, vars, include_description)
#' 
flatten_database <- function(database,
    format = "single_column_pretty",
    vars = list(
      location = "all",
      context = "all",
      contributors = "all",
      identifiers = "all",
      taxonomy = "all",
      taxonomic_updates = "all",
      methods = setdiff(names(database$methods), c("data_collectors", methods_source_columns)),
      sources = "all"
    ),
    include_description = TRUE
  ) {
  # Since `data_collectors` is also merged into the combined_table via the contributors tibble, we don't want the information twice.
  # Likewise the references come from `join_sources()`, not from the methods table.

  # Before `vars` is evaluated, since its default reads `database$methods`
  if (!check_compatibility(database)) {
    function_not_supported(database)
  }

  if (format == "many_columns") {
    format_contributors = "single_column_pretty"
  } else {
    format_contributors = format
  }

  combined_table_relational <- database %>%
    join_location_coordinates() %>%
    join_location_properties(format = format, vars =  vars$location) %>%
    join_context_properties(format = format, vars =  vars$context, include_description = TRUE) %>%
    join_methods(vars = vars$methods) %>%
    join_sources(vars = if (is.null(vars$sources)) "all" else vars$sources) %>%
    join_contributors(format = format_contributors, vars = vars$contributors) %>%
    join_taxa(vars = vars$taxonomy) %>%
    join_taxonomic_updates(vars = vars$taxonomic_updates)

  if(!is.null(database$identifiers)) {
    combined_table_relational <- combined_table_relational %>%
      join_identifiers(format = format, vars = vars$identifiers)
  }
  
  combined_table <- combined_table_relational$traits

  stamp_flat(combined_table, database)
}

#' Stamp a flat table with the database it came from
#'
#' Gives `table` the class `traits.build_flat` and the attribute
#' `traits.build_stamp`: a list of the database's `title`, `version`, `doi`,
#' `data_model_version` (see [get_data_model_version()]) and
#' `traits_build_version`, each a string or `NA`. Plain attributes, so
#' `saveRDS()` keeps them, and arrow keeps them in a Parquet file's metadata.
#'
#' @param table a table made from `database`, such as its flattened form
#' @param database the traits.build database (list object) it was made from
#' @return `table`, with the class and stamp
#' @noRd
#' @keywords internal
stamp_flat <- function(table, database) {
  stamp <- list(
    title = scalar_or_na(database[["metadata"]][["title"]]),
    version = scalar_or_na(database[["build_info"]][["version"]]),
    doi = scalar_or_na(database[["metadata"]][["doi"]]),
    data_model_version = get_data_model_version(database),
    traits_build_version = traits_build_version(database)
  )
  table <- tibble::as_tibble(table)
  attr(table, "traits.build_stamp") <- stamp
  class(table) <- c("traits.build_flat", setdiff(class(table), "traits.build_flat"))
  table
}

#' Header of a printed flat table: the database it came from
#' @param x a `traits.build_flat` table
#' @param ... passed on
#' @noRd
#' @exportS3Method pillar::tbl_sum
tbl_sum.traits.build_flat <- function(x, ...) {
  out <- NextMethod()
  names(out)[1] <- "A traits.build_flat table"
  stamp <- attr(x, "traits.build_stamp")
  if (is.list(stamp)) {
    title <- scalar_or_na(stamp$title)
    version <- scalar_or_na(stamp$version)
    doi <- scalar_or_na(stamp$doi)
    described <- c(
      title,
      if (!is.na(version)) paste("version", version),
      if (!is.na(doi)) paste0("doi:", doi)
    )
    described <- described[!is.na(described)]
    if (length(described) > 0) {
      out <- c(out, "From" = paste(described, collapse = ", "))
    }
  }
  out
}
