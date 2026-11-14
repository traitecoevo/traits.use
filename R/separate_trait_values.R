#' @title Separate bounded trait values
#'
#' @description This function reverts the action of bind_trait_values. 
#' This function separates values that were concatenated so that studies that have multiple observations for a given trait will have separate row for each observation.
#' @usage separate_trait_values(trait_data, definitions = NULL)
#' @param trait_data The traits table in a traits.build database, after
#'   [bind_trait_values()] - see example
#' @param definitions Not used; kept so that existing code passing the
#'   database's definitions still works.
#' @return trait tibble, with one row per value
#' @examples 
#' # A dataset with several values per observation and trait
#' trait_data <- austraits_lite$traits %>%
#'   dplyr::filter(dataset_id == "Apgaua_2017")
#' nrow(trait_data)
#'
#' # One row per observation and trait, values joined with "--"
#' traits_bind <- bind_trait_values(trait_data)
#' nrow(traits_bind)
#' traits_bind %>%
#'   dplyr::filter(grepl("--", value)) %>%
#'   dplyr::select(observation_id, trait_name, value, value_type)
#'
#' # Back to one row per value
#' nrow(separate_trait_values(traits_bind))
#' @author Daniel Falster - daniel.falster@unsw.edu.au
#' @export

#' 
separate_trait_values <- function(trait_data, definitions = NULL) {
  
  separate_x <- function(x) strsplit(x, "--")[[1]]
  
  separate_values_worker <- function(df) {
    
    df[rep(1, df$n_vals[1]),] %>%
      dplyr::mutate(
        value = separate_x(value[1]),
        value_type = separate_x(value_type[1]),
        basis_of_value = separate_x(basis_of_value[1]),
        replicates = separate_x(replicates[1])
      )
  }
  
  # record the number of values in each row of data
  trait_data$n_vals <- 1 + stringr::str_count(trait_data$value_type, "--")
  
  # separate out those rows requiring no modification
  out_1 <- trait_data %>% 
    dplyr::filter(n_vals == 1)
  
  bound <- trait_data %>% 
    dplyr::filter(n_vals > 1)

  # bind_trait_values() writes a missing value as "NA", even in a row
  # holding one value
  clean <- function(data) {
    data %>%
      dplyr::select(-n_vals) %>%
      dplyr::mutate(replicates = clean_NA(replicates),
                    value_type = clean_NA(value_type),
                    basis_of_value = clean_NA(basis_of_value))
  }

  if (nrow(bound) == 0) {
    return(clean(trait_data))
  }

  # Each bound row is separated on its own. (Grouping by a key pasted from
  # the id columns merged unrelated rows whenever an id was NA, losing their
  # values.)
  out_2 <- seq_len(nrow(bound)) %>%
    lapply(function(i) separate_values_worker(bound[i, ])) %>% 
    dplyr::bind_rows() %>% 
    dplyr::select(dataset_id:n_vals)
  
  # join it all back together, clean up and sort as in original
  dplyr::bind_rows(out_1, out_2) %>% 
    clean() %>% 
    dplyr::arrange(observation_id, trait_name, value_type)
}
