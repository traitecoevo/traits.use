#' @title Extract all data for a particular dataset
#'
#' @description Function to subset all data associated with a particular dataset from a traits.build relational database.
#' 
#' @param database traits.build database (list object)
#' @param dataset_id character string that matches a `dataset_id` in the database
#' @param partial_matches_allowed logical. If `TRUE` (the default), each value is matched as a case-insensitive regular expression, so `"Acacia"` also matches `"Acacia celsa"`; characters with special meaning in regular expressions, such as brackets, then need escaping. If `FALSE`, only exact matches are kept.
#' @return List of tibbles containing all traits.build data and metadata for the specified dataset(s).
#' @details
#' `extract_dataset` has been developed to extract data for specific datasets from databases built using the traits.build workflow. 
#' Learn more at:
#'   [https://github.com/traitecoevo/traits.build](https://github.com/traitecoevo/traits.build) &
#'   [https://github.com/traitecoevo/traits.build-book](https://github.com/traitecoevo/traits.build-book)
#'
#' Note to AusTraits users:
#' -  This function works with AusTraits version >= 5.0.0 (from Nov 2023 release)
#' -  For AusTraits versions <= 4.2.0 (up to Sept 2023 release) see [https://github.com/traitecoevo/austraits](https://github.com/traitecoevo/austraits) for how to install old versions of the package or download a newer version of the database.
#'
#' @examples
#' extract_dataset(austraits_lite, "Falster_2003")
#' @author Daniel Falster - daniel.falster@unsw.edu.au
#' @export


extract_dataset <- function(database, dataset_id, partial_matches_allowed = TRUE) {
  
  # Check compatability
  status <- check_compatibility(database, single_table_allowed = TRUE)

  # If compatible
  if(!status){
    function_not_supported(database)
  }
  
  extract_data(database, "traits", "dataset_id", col_value = dataset_id, partial_matches_allowed = partial_matches_allowed)
}


