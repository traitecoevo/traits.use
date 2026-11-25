#' @title Pivot wide format traits table into long format
#'
#' @description `r lifecycle::badge('deprecated')`
#' `trait_pivot_longer()` is deprecated, and gives an error. To pivot the output
#' of [trait_pivot_wider()] back into long format, use [tidyr::pivot_longer()],
#' as in the example.
#'
#' @param wide_data output from trait_pivot_wider.
#' @return None: the function stops with an error.
#'
#' @examples 
#' # trait_pivot_longer() is deprecated, and gives an error. Pivot the output
#' # of trait_pivot_wider() back with tidyr::pivot_longer() instead:
#' data <- austraits_lite$traits %>%
#'   dplyr::filter(dataset_id == "Falster_2003")
#' traits_wide <- trait_pivot_wider(data)
#' tidyr::pivot_longer(traits_wide, cols = dplyr::all_of(unique(data$trait_name)),
#'   names_to = "trait_name", values_to = "value", values_drop_na = TRUE)
#' @author Daniel Falster - daniel.falster@unsw.edu.au
#' @author Fonti Kar - fonti.kar@unsw.edu.au
#' @export

#
trait_pivot_longer <- function(wide_data){
  function_not_supported(wide_data)
}
