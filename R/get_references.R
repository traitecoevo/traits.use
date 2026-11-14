#' List the references a database cites
#'
#' @description
#' Lists the references cited by the data in a traits.build database, or in
#' the part of one returned by an `extract_*()` function, each formatted as a
#' citation. With `file`, it also writes them to a BibTeX file. Use it to cite
#' the studies behind the data you use.
#'
#' @param database traits.build database (list object), or the result of an
#'   `extract_*()` function.
#' @param file Path of a BibTeX file to write the references to, or `NULL`
#'   (the default) to write none. An existing file is overwritten. As with
#'   [RefManageR::WriteBib()], `.bib` is added to a name that does not end in
#'   it.
#'
#' @return A tibble with one row per reference, sorted by key in the C locale,
#'   and columns:
#'   - `key`: the reference's citation key, as in `sources`.
#'   - `citation`: the reference, formatted as in the citation columns of
#'     [join_sources()] and the methods table, or `NA` when `sources` has no
#'     entry for the key.
#'   - `type`: how the data cite it. `"dataset"`: the reference describing a
#'     dataset. `"source"`: a study that observations were taken from, in a
#'     dataset compiled from several studies. `"secondary"`: a further
#'     reference for a dataset, such as a later paper using the same data.
#'
#' @details
#' The references are the ones the data cite, read from the traits, excluded
#' data and methods tables: each dataset's own reference, each observation's
#' `source_id` and each dataset's secondary references. These are also the
#' references [extract_data()] keeps in `sources`, so for a database or any
#' `extract_*()` result the references listed are those in its `sources`. A key
#' cited in more than one way gets the first type of `"dataset"`, `"source"`
#' and `"secondary"`.
#'
#' In databases built with traits.build 2.3 or later, a dataset's own
#' reference is keyed by its `dataset_id`. In older ones it is the methods
#' table's `source_primary_key`, and the studies are also listed in its
#' `source_original_dataset_key`.
#'
#' A cited key with no entry in `sources` is listed with an `NA` citation and a
#' warning, rather than silently dropped. A database can have such keys when a
#' dataset names a study it took observations from without giving its
#' reference. Only the references in `sources` are written to `file`.
#'
#' A flattened database (one table, see [flatten_database()]) has no `sources`,
#' so its references cannot be listed.
#'
#' @seealso [join_sources()] to add each observation's references to the
#'   traits table, [traits_build_sources] to look up `sources` by key.
#' @export
#'
#' @examples
#' refs <- austraits_lite %>%
#'   extract_dataset("Falster_2003") %>%
#'   get_references()
#' refs
#'
#' # Write the references to a BibTeX file too
#' bib_file <- tempfile(fileext = ".bib")
#' refs <- austraits_lite %>%
#'   extract_taxa(genus = "Eucalyptus") %>%
#'   get_references(file = bib_file)
#' head(readLines(bib_file))
#' unlink(bib_file)
get_references <- function(database, file = NULL) {

  if (is.data.frame(database) || !is.list(database) ||
      !inherits(database[["sources"]], "BibEntry")) {
    rlang::abort(paste0(
      "`database` must be a traits.build database, or the result of an ",
      "`extract_*()` function, with its references in `sources`; a flattened ",
      "database has none."
    ))
  }

  # Check compatibility
  if (!check_compatibility(database)) {
    function_not_supported(database)
  }

  sources <- database[["sources"]]
  refs <- cited_references(database)

  # By position: given a character vector, `[` on a BibEntry searches rather
  # than indexes
  index <- match(refs$key, names(sources))
  refs$citation <- vapply(
    index,
    function(i) if (is.na(i)) NA_character_ else format_citation(sources[[i]]),
    character(1)
  )
  refs <- refs[, c("key", "citation", "type")]

  missing <- refs$key[is.na(index)]
  if (length(missing) > 0) {
    cli::cli_warn(c(
      "{length(missing)} cited key{?s} {?has/have} no reference in `sources`, so {?its/their} citation is `NA`:",
      "i" = "{.val {missing}}"
    ))
  }

  if (!is.null(file)) {
    # An empty `[` on a BibEntry prints "No results."
    present <- index[!is.na(index)]
    write_references(if (length(present) > 0) sources[present], file)
  }

  refs
}

#' References cited by a database's data
#'
#' The keys of the references the traits, excluded data and methods tables of
#' a database cite, with how each is cited. Shared by [get_references()] and
#' [extract_data()], so the references listed are the ones extracted.
#'
#' @param database traits.build database (list object)
#' @param source_keys The keys in the database's `sources`, given separately
#'   for [extract_data()], which calls this before it adds `sources`
#' @return Tibble with columns `key` and `type` (`"dataset"`, `"source"` or
#'   `"secondary"`), one row per key, sorted by key in the C locale. A key
#'   cited in more than one way gets the first of those types.
#' @noRd
#' @keywords internal
cited_references <- function(database, source_keys = names(database[["sources"]])) {
  # A column missing or all `NA` (so logical) gives no keys
  split_keys <- function(x) {
    x <- as.character(x)
    x <- unlist(strsplit(x[!is.na(x)], "; ", fixed = TRUE))
    x[x != ""]
  }
  methods <- database[["methods"]]

  # Built before traits.build 2.3?
  old_schema <- "source_primary_key" %in% names(methods)

  # A dataset's own reference: keyed by its `dataset_id` from traits.build
  # 2.3, and named in `source_primary_key` before
  dataset_keys <- methods[["dataset_id"]]
  if (old_schema) {
    dataset_keys <- dplyr::coalesce(as.character(methods[["source_primary_key"]]), dataset_keys)
  }

  # The study each observation was taken from. From traits.build 2.3 it must
  # be a key in `sources` (an observation from the dataset's own study names
  # the dataset, and so is typed as a dataset below). Before, it was free
  # text, e.g. "44" (most of AusTraits 7.0.0's), so only the values that are
  # keys count, and the studies are listed in `source_original_dataset_key`
  observation_keys <- as.character(c(
    database[["traits"]][["source_id"]],
    database[["excluded_data"]][["source_id"]]
  ))
  if (old_schema) {
    observation_keys <- observation_keys[observation_keys %in% source_keys]
  }
  study_keys <- c(
    observation_keys,
    split_keys(methods[["source_original_dataset_key"]])
  )

  secondary_keys <- c(
    split_keys(methods[["secondary_id"]]),
    split_keys(methods[["source_secondary_key"]])
  )

  keys <- c(dataset_keys, study_keys, secondary_keys)
  types <- rep(c("dataset", "source", "secondary"),
               c(length(dataset_keys), length(study_keys), length(secondary_keys)))
  keep <- !is.na(keys) & keys != "" & !duplicated(keys)
  refs <- tibble::tibble(key = keys[keep], type = types[keep])
  refs[order(refs$key, method = "radix"), ]
}

#' Write references to a BibTeX file
#'
#' @param bib A BibEntry object, or `NULL` for none
#' @param file Path of the file; `.bib` is added to a name without it, as
#'   [RefManageR::WriteBib()] does
#' @return `file`, invisibly
#' @noRd
#' @keywords internal
write_references <- function(bib, file) {
  if (!grepl("\\.bib$", file)) {
    file <- paste0(file, ".bib")
  }
  if (length(bib) == 0) {
    # WriteBib() writes no file at all for no references
    writeLines(character(), file)
  } else {
    RefManageR::WriteBib(bib, file = file, verbose = FALSE)
  }
  invisible(file)
}
