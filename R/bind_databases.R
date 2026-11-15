#' Bind multiple traits.build data objects into a single data object
#'
#' `bind_databases` binds all the listed studies into a single traits.build
#' database object as a large list.
#'
#' The combined `sources` hold the references of every database, with
#' duplicate keys removed. They are a [RefManageR::BibEntry()] object with the
#' class [`traits_build_sources`][traits_build_sources], so a reference can be
#' looked up by key with `$` as well as `[[` and `[`, e.g.
#' `database$sources$Falster_2005`.
#'
#' Each table keeps one of each set of identical rows, so binding two extracts
#' of one database that overlap, e.g. by two contexts, holds each shared
#' observation once. A row of `traits` or `excluded_data` that exactly copies
#' another row of the *same* database is dropped too, but with a warning naming
#' the dataset: two genuine measurements differ in `observation_id` or
#' `repeat_measurements_id`, so an exact copy means the dataset's configuration
#' is wrong.
#'
#' @param ... Arguments passed to other functions
#' @param databases List of traits.build databases to be bond together
#'
#' @return Compiled database as a single large list
#' @seealso [traits_build_sources] for looking up `sources` by key
#' @importFrom rlang .data
#' @examples
#' a <- extract_dataset(austraits_lite, "Falster_2003")
#' b <- extract_dataset(austraits_lite, "Falster_2005_1")
#' both <- bind_databases(a, b)
#' unique(both$traits$dataset_id)
#' @export
bind_databases <- function(..., databases = list(...)) {
  
  combine <- function(name, databases) {
    
    # Check for null elements and remove them
    databases <- databases[!sapply(databases, is.null)]
    
    # No data in any parts
    if(length(databases) == 0) {
      return(NULL)
    }

    tables <- databases %>% lapply("[[", name)

    if (name %in% c("traits", "excluded_data")) {
      warn_exact_copies(tables, name)
    }

    tables %>%
    dplyr::bind_rows() %>%
    dplyr::distinct()
  }
  
  # Bind sources and remove duplicates
  sources <- databases %>% lapply("[[", "sources")
  check_conflicting_sources(sources, databases)
  # Sorted in the C locale (radix), as dplyr::arrange() does, so the order
  # doesn't depend on the machine that built the database (#6)
  keys <- sources %>% lapply(names) %>% unlist() %>% unique() %>% sort(method = "radix")
  sources <- sources %>% purrr::reduce(c)
  sources <- sources[keys]
  
  # Lets `$` look up by key; see ?traits_build_sources. Applied here, after
  # the c(), because RefManageR's c() returns a plain BibEntry when the first
  # database's sources lack the class
  sources <- as_traits_build_sources(sources)
  
  definitions <- databases %>% lapply("[[", "definitions") %>% purrr::reduce(c)
  definitions <- definitions[!duplicated(names(definitions))]
  definitions <- definitions[sort(names(definitions), method = "radix")]
  
  # Drop null datasets
  databases[sapply(databases, is.null)] <- NULL
  
  # Taxonomy
  
  taxonomic_updates <-
    combine("taxonomic_updates", databases) %>%
    dplyr::group_by(.data$original_name, .data$aligned_name, .data$taxon_name, .data$taxonomic_resolution) %>%
    #dplyr::mutate(dataset_id = paste(.data$dataset_id, collapse = " ")) %>%
    dplyr::ungroup() %>%
    dplyr::distinct() %>%
    dplyr::arrange(.data$original_name, .data$aligned_name, .data$taxon_name, .data$taxonomic_resolution)
  
  # Metadata
  contributors <- combine("contributors", databases)
  metadata <- databases[[1]][["metadata"]]
  
  metadata[["contributors"]] <-
    contributors %>%
    dplyr::select(-dplyr::any_of(c("dataset_id", "additional_role"))) %>%
    dplyr::distinct() %>%
    dplyr::arrange(.data$last_name, .data$given_name) %>%
    convert_df_to_list()

  ret <- list(traits = combine("traits", databases) %>% dplyr::arrange(.data$dataset_id, .data$observation_id, .data$trait_name),
              locations = combine("locations", databases) %>% dplyr::arrange(.data$dataset_id, .data$location_id),
              contexts = combine("contexts", databases) %>% dplyr::arrange(.data$dataset_id, .data$category),
              methods = combine("methods", databases) %>% dplyr::arrange(.data$dataset_id, .data$trait_name),
              excluded_data = combine("excluded_data", databases) %>% dplyr::arrange(.data$dataset_id, .data$observation_id, .data$trait_name),
              taxonomic_updates = taxonomic_updates,
              taxa = combine("taxa", databases) %>% dplyr::distinct() %>% dplyr::arrange(.data$taxon_name),
              identifiers = combine("identifiers", databases) %>% dplyr::distinct(),
              contributors = contributors,
              sources = sources,
              definitions = definitions,
              schema = databases[[1]][["schema"]],
              metadata = metadata,
              build_info = list(session_info = utils::sessionInfo())
  )
  
  class(ret) <- c("traits.build")

  ret
}

#' Warn if a database holds exact copies of its own observations
#'
#' Binding keeps one of each set of identical rows. Across databases that is
#' wanted: two extracts of one release, e.g. by two contexts, share rows, and
#' their union should hold each once. Within one database it is not: two
#' genuine measurements differ in `observation_id` or `repeat_measurements_id`,
#' so an exact copy means a dataset's configuration is wrong (e.g. a
#' species-level value repeated on every location row). Dropping it unseen left
#' the compiled database looking clean while `traits.build::dataset_test()`
#' failed on it (#36). Copies are still dropped, so the result can be pivoted
#' wider, but each dataset holding them is named.
#'
#' @param tables List of one table (`traits` or `excluded_data`) from each
#'   database
#' @param name Name of the table, for the message
#' @return Nothing; warns, naming each dataset and its count of dropped rows
#' @noRd
#' @keywords internal
warn_exact_copies <- function(tables, name) {

  tables <- tables[!vapply(tables, function(x) is.null(x) || nrow(x) == 0, logical(1))]
  if (length(tables) == 0) return(invisible())

  # `.id` keeps rows of different databases apart, so only copies within one
  # database are counted. Unnamed, so it numbers them: `.id` takes names when
  # there are any, and two databases passed under one name would merge
  bound <- dplyr::bind_rows(unname(tables), .id = ".database")
  kept <- dplyr::distinct(bound)
  if (nrow(kept) == nrow(bound)) return(invisible())

  dropped <-
    dplyr::count(bound, .data$dataset_id, name = "n_bound") %>%
    dplyr::left_join(dplyr::count(kept, .data$dataset_id, name = "n_kept"), by = "dataset_id") %>%
    dplyr::mutate(n = .data$n_bound - .data$n_kept) %>%
    dplyr::filter(.data$n > 0)

  warning(
    sprintf(
      "Dropped %d row%s of `%s` that exactly copy another row in the same database: %s. ",
      sum(dropped$n), if (sum(dropped$n) == 1) "" else "s", name,
      paste(sprintf("%s (%d)", dropped$dataset_id, dropped$n), collapse = ", ")
    ),
    "An exact copy means the dataset's configuration is wrong",
    # It reads only the traits table
    if (name == "traits") {
      "; `traits.build::dataset_find_pivot_duplicates()` finds the rows."
    } else {
      "."
    },
    call. = FALSE
  )

  invisible()
}

#' Warn if one citation key names different references in different databases
#'
#' `sources` is bound by key, keeping one entry per key, so two different
#' references sharing a key lose one of them unseen -- and with it the citation
#' of every observation whose `source_id` names it. Entries are the same reference
#' when their titles and years agree, ignoring case, spacing and punctuation, so
#' one paper formatted differently by two datasets is not reported.
#'
#' A warning rather than an error: such keys exist in published databases, and
#' binding has always kept the first entry, so stopping would break every build
#' until the data are fixed.
#'
#' @param sources List of the `sources` of each database
#' @param databases List of traits.build databases, to name the datasets
#' @return Nothing; warns, listing the keys and datasets, on a conflict
#' @noRd
#' @keywords internal
check_conflicting_sources <- function(sources, databases) {

  keep <- !vapply(sources, is.null, logical(1))
  sources <- sources[keep]
  databases <- databases[keep]
  keys <- lapply(sources, names)

  counts <- table(unlist(lapply(keys, unique)))
  shared <- names(counts)[counts > 1]
  if (length(shared) == 0) return(invisible())

  identity <- function(entry) {
    field <- function(x) if (is.null(x)) "" else paste(unlist(x), collapse = " ")
    tolower(gsub("[^[:alnum:]]", "", paste(field(entry$title), field(entry$year))))
  }

  conflicts <- purrr::map_chr(shared, function(key) {
    holders <- which(vapply(keys, function(k) key %in% k, logical(1)))
    entries <- vapply(holders, function(i) {
      identity(sources[[i]][[match(key, keys[[i]])]])
    }, character(1))
    if (length(unique(entries)) == 1) return(NA_character_)
    datasets <- vapply(holders, function(i) {
      paste(unique(databases[[i]]$methods$dataset_id), collapse = ", ")
    }, character(1))
    sprintf("`%s` (%s)", key, paste(datasets, collapse = "; "))
  })
  conflicts <- conflicts[!is.na(conflicts)]

  if (length(conflicts) > 0) {
    warning(
      "These citation keys name different references in different datasets, ",
      "so `sources` keeps only one of each: ",
      paste(conflicts, collapse = ", "),
      ". Give each reference its own key.",
      call. = FALSE
    )
  }

  invisible()
}
