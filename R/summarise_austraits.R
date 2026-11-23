#' @title Summarise counts for a particular variable of interest
#'
#' @name summarise_database
#' @param database traits.build database (list object), or a flat table from
#'   one: a table made by [flatten_database()], or a traits table (for `"family"`
#'   or `"genus"`, it must then have that column, e.g. from [join_taxa()])
#' @param var variable you use wish to see summary of (trait_name, genus, family)
#'
#' @return dataframe of unique levels of variable with counts and percentage
#' @export
#' @examples
#' summarise_database(database = austraits_lite, "trait_name")
#' summarise_database(database = austraits_lite, "family")


summarise_database <- function(database, var){
  
  if(!var %in% c("trait_name", "family", "genus")){
    stop(paste0("Print summary for ", var, " has not been implemented! see examples)"))
  }
  
  if (!check_compatibility(database, single_table_allowed = TRUE)) {
    function_not_supported(database)
  }

  # The traits table, with family and genus for a summary by taxon
  if (is_flat(database)) {
    traits <- database
    if (!var %in% names(traits)) {
      cli::cli_abort(c(
        "x" = "{.arg database} has no {.field {var}} column to summarise.",
        "i" = "Pass the relational database, or a table made by {.fn flatten_database}, which has the taxonomy joined in."
      ))
    }
  } else if (var == "trait_name") {
    traits <- database[["traits"]]
  } else {
    traits <- join_taxa(database)[["traits"]]
  }

  switch(var,
         trait_name = summarise_database_traits(traits, var),
         genus =  summarise_database_taxa(traits, var),
         family = summarise_database_taxa(traits, var)
  )
}

#' @noRd
#' @keywords internal
         
summarise_database_traits <-function(traits, var) {

  ret <- 
    traits %>% 
    dplyr::pull({{var}}) %>% 
    sort(method = "radix") %>% 
    janitor::tabyl() 
  
  # Fix first column name
  names(ret)[1] <- var
  
  # Renaming
  ret <- ret %>% dplyr::mutate(n_records = n,
                               n = NULL,
                               percent_total = signif(percent, 3),
                               percent = NULL)
  # Summary statistics
  sum_stats <- traits %>% 
    dplyr::group_by(trait_name) %>% 
    dplyr::summarise(n_dataset = length(unique(dataset_id)),
                     n_taxa = length(unique(taxon_name))) 
  
  ret <- dplyr::left_join(ret, sum_stats, by = "trait_name")
  
  # Organise
  ret %>% dplyr::select(1, dplyr::starts_with("n_"), percent_total) %>% tibble::tibble()
}

#' @noRd
#' @keywords internal

summarise_database_taxa <-function(traits, var) {
  
  # Create table
  ret <- traits %>% 
    dplyr::pull(var) %>% 
    sort(method = "radix") %>% 
    janitor::tabyl() 
  
  # Fix first column name
  suppressWarnings(names(ret)[1] <- var
  )
  
  # Renaming
  ret <- ret %>% dplyr::mutate(n_records = n,
                               n = NULL,
                               percent_total = signif(percent, 3),
                               percent = NULL)


  
  # Summary statistics (https://stackoverflow.com/questions/55425976/use-quoted-variable-in-group-by-mutate-function-call)
  sum_stats <- traits %>% 
    dplyr::group_by(!!rlang::sym(var)) %>% 
    dplyr::summarise(n_dataset = length(unique(dataset_id)),
                     n_taxa = length(unique(taxon_name)))
  
  ret <- dplyr::left_join(ret, sum_stats, by = var)
  
  # Organise
  ret %>% dplyr::select(1, dplyr::starts_with("n_"), percent_total) %>% tibble::tibble()
  
}
