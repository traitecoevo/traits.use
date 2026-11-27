#' Load any traits.build database into R console
#'
#' @description Loads a traits.build formatted database, given its doi. The doi is resolved to its repository, the
#' relational database `.rds` file (or with `flattened = TRUE`, the flattened
#' one, or with `means = TRUE`, the observed means published with it) is downloaded (if there is no copy already,
#' or if the copy does not match the record's md5 checksum) and then loaded.
#' Zenodo and Figshare records are supported, as are dois that resolve directly
#' to an `.rds` file.
#'
#' The download is always kept in a folder shared by all your projects
#' (see [database_cache_dir()]), so each release is downloaded once per
#' computer. Use [list_cached_databases()] and [clear_database_cache()] to see
#' and delete what is there. Give a `path` to also keep a copy with a project.
#'
#' The record's metadata (its list of files and, for a concept doi, which
#' release is the latest) is saved with the database and fetched afresh once
#' it is more than 60 days old, so a concept doi finds a new release within
#' that time; set `update = TRUE` to check now. Change the 60 days with
#' `options(traits.use.update_after_days = )`.
#'
#' @param doi character string - doi of the database, e.g. "10.5281/zenodo.11188867".
#' A Zenodo concept doi will load the latest version of that record.
#' @param path a folder, such as `"data/austraits"`, to keep a copy of the
#'   database in (with its record, so the folder loads offline on its own),
#'   besides the cache folder. If the folder already holds the release (e.g.
#'   saved there by traits.use 1.0 or austraits 4.0) and it matches the
#'   repository's checksum, it is copied into the cache rather than downloaded
#'   again; if the repository cannot be reached, the folder is used on its
#'   own. `NULL` (the default) keeps only the cache copy. To keep nothing beyond one session, set the cache folder to
#'   a temporary one with `options(traits.use.cache_dir = tempfile())`.
#' @param flattened if `TRUE`, load the flattened version of the database
#'   instead: one table with the other tables joined to the traits table,
#'   made with [flatten_database()] when the release was built. Releases of
#'   AusTraits from 7.0.0 include it. Its reference columns follow the
#'   `flatten_database()` of that time, so may differ from what
#'   `flatten_database()` makes now (e.g. AusTraits 7.0.0 has
#'   `source_primary_citation`, not `dataset_id_citation`).
#'   It is several times larger than the relational database (AusTraits 7.0.0:
#'   a 77 MB download, about 1 GB once loaded).
#' @param means if `TRUE`, load the record's observed means instead: one row
#'   per taxon and trait, made with [summarise_trait_means()] when the release
#'   was built and published beside it as `<name>-<version>-observed-means.rds`
#'   (read when present: values exactly as computed) or `.csv.gz`.
#'   Releases of AusTraits after 7.0.0 include them. The file is much smaller
#'   than the database (AusTraits: about 15 MB). To have both, load each; the
#'   second call reuses the record fetched by the first. [trait_means_dictionary()]
#'   defines the columns.
#' @param update whether to fetch the record's metadata afresh: `NULL` (the
#'   default) when the saved copy is more than 60 days old (see
#'   [database_cache_dir()] for the option that sets this), `TRUE` always, and
#'   `FALSE` never if there is a saved copy, e.g. to work offline. If fetching
#'   fails (e.g. offline), the saved copy is used. Until it is fetched afresh,
#'   a concept doi loads the release last fetched, perhaps by another project.
#'
#' @return a large list containing traits.build data tables, or with
#'   `flattened = TRUE`, a single table (tibble), or with `means = TRUE`, the
#'   table of observed means (tibble)
#' @export
#' @seealso [list_versions()] to find the dois of a database's releases;
#'   [database_cache_dir()]; `austraits::load_austraits()`, which loads
#'   a release of AusTraits by version number
#'
#' @examplesIf interactive()
#' # Downloads AusTraits (about 20 MB, several hundred MB once loaded) the
#' # first time, then loads it from the cache. To try the package without
#' # downloading anything, see ?austraits_lite.
#' austraits <- load_database(doi = "10.5281/zenodo.11188867")
#'
#' # The observed means of each taxon and trait, published with the release
#' means <- load_database(doi = "10.5281/zenodo.11188867", means = TRUE)
#'
#' # Also keeping a copy in a folder of your choice, here a temporary one
#' austraits <- load_database(doi = "10.5281/zenodo.11188867",
#'   path = file.path(tempdir(), "austraits"))

load_database <- function(doi = NULL, path = NULL, update = NULL, flattened = FALSE, means = FALSE){
  if(!is.logical(flattened) || length(flattened) != 1 || is.na(flattened)){
    rlang::abort("`flattened` must be TRUE or FALSE.")
  }
  if(!is.logical(means) || length(means) != 1 || is.na(means)){
    rlang::abort("`means` must be TRUE or FALSE.")
  }
  if(flattened && means){
    rlang::abort("Choose one of `flattened = TRUE` and `means = TRUE`: they load different files.")
  }

  # Is doi supplied?
  if(is.null(doi)){
    stop("Please supply a doi!")
  }

  if(!is.null(path) && (!is.character(path) || length(path) != 1 || is.na(path) || !nzchar(path))){
    rlang::abort("`path` must be a single folder path, or NULL for the cache folder only.")
  }
  check_update(update)

  doi <- clean_doi(doi)

  # The database is kept in the cache folder shared by all projects; `path`,
  # if given, gets a copy. A cache that cannot be written to (e.g. a read-only
  # home folder) leaves only `path`.
  cache <- database_cache_dir()
  use_cache <- writable_folder(cache)
  if(!use_cache){
    if(has_cached_copy(doi, cache, flattened = flattened, means = means)){
      # A cache that holds the release but cannot be written to (e.g. one
      # shared by a research group) is read as it is
      update <- FALSE
    } else if(is.null(path)){
      rlang::abort(c(paste0("Cannot write to the cache folder '", cache, "'."),
                     i = "Choose another with `options(traits.use.cache_dir = )`, or give a `path`."))
    } else {
      message("Cannot write to the cache folder '", cache, "'; keeping the database in '", path, "' only")
      cache <- path
      path <- NULL
      writable_folder(cache)
    }
  }
  if(!is.null(path)){
    writable_folder(path)
    if(same_folder(path, cache)) path <- NULL
  }

  # Load the record metadata. The cache only ever holds what was checked
  # against a record fetched from the repository, so that one project's folder
  # cannot change what another project loads. A record saved in `path` (e.g.
  # by traits.use 1.0) is used only when the repository cannot be reached or
  # is not to be asked (`update = FALSE`), and then `path` is used on its own.
  record <- load_record_json(doi = doi, path = cache, update = update,
                             fallback = if(!is.null(path)) record_json_path(doi, path))
  if(isTRUE(attr(record, "from_fallback"))){
    cache <- path
    path <- NULL
    use_cache <- FALSE
  }

  # Say which release the doi resolved to (a concept doi resolves to the latest)
  if(length(record$version) == 1 && !is.na(record$version) && nzchar(record$version)) {
    message("doi '", doi, "' is version ", record$version)
  }

  # The relational (or flattened) database .rds, or the observed means, among
  # the record's files
  files <- if(means) means_file(record$files, doi) else database_file(record$files, doi, flattened = flattened)

  # A copy of the release in `path` saves downloading it again, if it matches
  # the record's checksum (without a checksum it cannot be told from any other
  # file of that name)
  md5 <- if(is.null(files$md5)) NA_character_ else files$md5
  key <- basename(files$key)
  if(!is.null(path) && !is.na(md5) &&
     file.exists(file.path(path, key)) && file_matches_md5(file.path(path, key), md5) &&
     !(file.exists(file.path(cache, key)) && file_matches_md5(file.path(cache, key), md5))){
    if(file.exists(file.path(cache, key))) remove_file(file.path(cache, key))
    seed_file(file.path(path, key), file.path(cache, key))
  }

  file_nm <- fetch_record_file(files, doi, cache, use_cache)

  # The copy in `path`, with the record so the folder loads offline on its own
  if(!is.null(path)){
    copy_to_path(file_nm, md5, path, doi)
    copy_record_to_path(record_json_path(doi, cache), record_json_path(doi, path))
  }

  if(means){
    message("Loading observed means from '", file_nm, "'")
    return(if(grepl("\\.rds$", file_nm, ignore.case = TRUE)) read_trait_means_rds(file_nm) else read_trait_means(file_nm))
  }

  # Loading the .rds
  message("Loading data from '", file_nm,"'")
  data <- readRDS(file_nm)

  if(isTRUE(flattened)){
    if(! is.data.frame(data) || ! all(c("dataset_id", "taxon_name", "trait_name", "value") %in% names(data))){
      rlang::abort(paste0("'", file_nm, "' is not a flattened traits.build database!"))
    }
    # A file flattened since #41 holds a stamped `traits.build_flat` tibble;
    # as_tibble() would drop its class, so convert only an older plain table
    if(! tibble::is_tibble(data)){
      data <- tibble::as_tibble(data)
    }
    return(data)
  }

  # Check it looks like a traits.build database
  if(! is.list(data) | ! all(c("traits", "taxa", "methods") %in% names(data))){
    rlang::abort(paste0("'", file_nm, "' is not a traits.build database!"))
  }

  # Assign class, and let `$` look up sources by key
  attr(data, "class") <- "traits.build"
  data <- classify_sources(data)

  data
}

#' Download one of a record's files into `path`, unless a copy matching its
#' md5 is already there
#'
#' @param files the one row of the record's files to fetch (`key`, `url`, `md5`)
#' @param doi the doi, used in messages
#' @param path the folder to keep it in
#' @param use_cache whether `path` is the shared cache folder
#' @return the path of the local copy
#' @noRd
#' @keywords internal

fetch_record_file <- function(files, doi, path, use_cache){
  url <- files$url
  file_nm <- file.path(path, basename(files$key))
  md5 <- if(is.null(files$md5)) NA_character_ else files$md5

  # Filenames are not unique across releases (every MYtraits release is
  # MYtraits.rds), so only reuse a cached file that matches the record's md5
  if(file.exists(file_nm) && ! file_matches_md5(file_nm, md5)){
    message("'", file_nm, "' does not match doi '", doi, "', downloading again")
    # A file another R session has open cannot be removed on Windows; going on
    # would load the wrong release
    if(! remove_file(file_nm)){
      rlang::abort(paste0("Could not remove '", file_nm, "' to download doi '", doi,
                          "'. Is it open in another R session?"))
    }
  }

  #Check if doi is downloaded, if not download
  if(! file.exists(file_nm)){
    # Downloading file
    download_database(url, file_nm, path = path, name = "your traits.build database")

    if(! file_matches_md5(file_nm, md5)){
      rlang::abort(paste0("Downloaded '", file_nm, "' does not match the md5 checksum for doi '", doi, "'"))
    }

    # Old releases stay in the cache until deleted, so say what is there
    if(use_cache){
      record_cache_size(path, file_nm)
    }
  } else if(use_cache){
    # Mark it used, so clear_database_cache(older_than) keeps it. This can
    # fail quietly (e.g. a read-only cache), which only affects older_than
    Sys.setFileTime(file_nm, Sys.time())
  }

  file_nm
}

#' Pick the observed means from a record's files
#'
#' The table [summarise_trait_means()] made when the release was built, as
#' `<name>-<version>-observed-means.rds` if the release has it (AusTraits from
#' 8.0.0), else `.csv.gz`: the .rds holds the values exactly as computed (the
#' .csv.gz rounds the last digit or so of a double) and is the smaller download.
#' AusTraits also publishes a parquet copy, which is not needed. Its column
#' dictionary is not loaded.
#'
#' @param files data frame of the record's files (`key`, `url`, `md5`)
#' @param doi the doi, used in messages
#' @return the one row of `files` to download
#' @noRd
#' @keywords internal

means_file <- function(files, doi){
  is_rds <- grepl("[-_.]observed-means\\.rds$", files$key, ignore.case = TRUE)
  is_csv <- grepl("[-_.]observed-means\\.csv\\.gz$", files$key, ignore.case = TRUE)
  files <- files[if(any(is_rds)) is_rds else is_csv, , drop = FALSE]

  if(nrow(files) == 0) {
    rlang::abort(paste0("No observed means (a file ending in '-observed-means.rds' or '.csv.gz') found for doi '", doi,
                        "'. Releases published before the means were added do not have them; ",
                        "summarise_trait_means() computes them from the database."))
  }
  if(nrow(files) > 1) {
    rlang::abort(paste0("More than one observed-means file found for doi '", doi, "': ",
                        paste(files$key, collapse = ", ")))
  }
  files
}

#' Read a published table of observed means
#'
#' Column types are those [summarise_trait_means()] gives; any other column,
#' such as a `by` variable, is read as text.
#'
#' @param file the `.csv.gz`
#' @noRd
#' @keywords internal

read_trait_means <- function(file){
  rlang::check_installed("readr", reason = "to read the observed means.")
  template <- trait_means_template()
  types <- vapply(template, function(x) if(is.integer(x)) "i" else if(is.numeric(x)) "d" else "c", character(1))
  col_types <- do.call(readr::cols, c(as.list(types), list(.default = "c")))

  means <- readr::read_csv(file, col_types = col_types, na = "", progress = FALSE)

  if(! all(c("taxon_name", "trait_name", "value") %in% names(means))){
    rlang::abort(paste0("'", file, "' is not a table of observed means!"))
  }
  attr(means, "spec") <- NULL
  attr(means, "problems") <- NULL
  tibble::as_tibble(means)
}

#' Read a published table of observed means saved as .rds
#'
#' @param file the `.rds`
#' @noRd
#' @keywords internal

read_trait_means_rds <- function(file){
  means <- readRDS(file)
  if(! is.data.frame(means) || ! all(c("taxon_name", "trait_name", "value") %in% names(means))){
    rlang::abort(paste0("'", file, "' is not a table of observed means!"))
  }
  tibble::as_tibble(means)
}


#' Load the record metadata .json for a doi
#'
#' @description Resolves the doi to its repository and saves a .json listing
#' the record's files (key and download url) to `path`
#'
#' @noRd
#' @keywords internal

load_record_json <- function(doi, path, update, fallback = NULL){
  file_json <- record_json_path(doi, path)

  # The saved copy: the one in `path`, else `fallback` (a record file in
  # another folder, never copied into `path`)
  saved <- if(file.exists(file_json)) file_json else if(!is.null(fallback) && file.exists(fallback)) fallback

  # Fetch it if there is no saved copy in `path`, or (update = NULL) that copy
  # is old, or names another release than `fallback` does (two computers
  # sharing a project folder, with a concept doi fetched at different times:
  # the repository says which is the latest); with update = FALSE, never if
  # there is any saved copy
  fetch <- if(isFALSE(update)) is.null(saved) else
    ! file.exists(file_json) || needs_update(file_json, update) || records_differ(file_json, fallback)
  if(fetch){
    # Retrieve the record, falling back to the saved one when the repository
    # cannot be reached. Other errors (e.g. a record since restricted) stop.
    res <- tryCatch(resolve_doi_files(doi), error = function(e) {
      unreachable <- ! inherits(e, "rlang_error") || inherits(e, "traits_use_unreachable")
      if(! unreachable || is.null(saved)) stop(e)
      message("Could not update the record for doi '", doi, "' (", conditionMessage(e),
              "); using the copy saved in '", dirname(saved), "'")
      NULL
    })
    # Save it
    if(! is.null(res)){
      jsonlite::write_json(res, file_json)
      saved <- file_json
    }
  }

  # Load the json, saying if it is not the one in `path`
  record <- jsonlite::fromJSON(saved)
  if(! identical(saved, file_json)) attr(record, "from_fallback") <- TRUE
  record
}

#' Pick the relational database .rds from a record's files
#'
#' @param files data frame of the record's files (`key`, `url`, `md5`)
#' @param doi the doi, used in messages
#' @param flattened if `TRUE`, pick the flattened database .rds instead
#' @return the one row of `files` that load_database() downloads; an error if
#'   there is not exactly one. An observed-means .rds is never picked. clear_database_cache() uses this too, so it
#'   only ever claims the files load_database() wrote.
#' @noRd
#' @keywords internal

database_file <- function(files, doi, flattened = FALSE){
  # The observed means are not a database, though a release may publish them
  # as .rds beside the .csv.gz (AusTraits 8.0.0 does); means = TRUE loads them
  is_rds <- grepl("\\.rds$", files$key, ignore.case = TRUE) &
    !grepl("[-_.]observed-means\\.rds$", files$key, ignore.case = TRUE)

  if(! any(is_rds)){
    rlang::abort(paste0("No .rds file found for doi '", doi,
                        "'. Is this a traits.build database?"))
  }

  files <- files[is_rds, , drop = FALSE]

  # A flattened file's name ends in e.g. "-flattened.rds"
  is_flattened <- stringr::str_detect(files$key, stringr::regex("[-_.]flattened\\.rds$", ignore_case = TRUE))

  if(isTRUE(flattened)){
    files <- files[is_flattened, , drop = FALSE]

    if(nrow(files) == 0) {
      rlang::abort(paste0("No flattened .rds file found for doi '", doi,
                          "'; load the relational database with `flattened = FALSE`"))
    }

    if(nrow(files) > 1) {
      rlang::abort(paste0("More than one flattened .rds file found for doi '", doi, "': ",
                          paste(files$key, collapse = ", ")))
    }

    return(files)
  }

  # Ignore flattened database files, even when one is the only .rds
  files <- files[!is_flattened, , drop = FALSE]

  if(nrow(files) == 0) {
    rlang::abort(paste0("Only flattened .rds files found for doi '", doi,
                        "'; load it with `flattened = TRUE`"))
  }

  if(nrow(files) > 1) {
    rlang::abort(paste0("More than one .rds file found for doi '", doi, "': ",
                        paste(files$key, collapse = ", ")))
  }

  files
}

#' file.remove(), wrapped so tests can make it fail
#' @noRd
#' @keywords internal

remove_file <- function(file){
  file.remove(file)
}

#' Where load_database() saves a doi's record in a folder
#'
#' The name is part of the folder's format: [clear_database_cache()] finds
#' records by it, and austraits writes one for caches made by austraits 3.x.
#' @noRd
#' @keywords internal

record_json_path <- function(doi, path){
  file.path(path, paste0(stringr::str_replace_all(doi, "[^A-Za-z0-9.]+", "_"), ".json"))
}

#' Check the `update` argument: TRUE, FALSE or NULL
#' @noRd
#' @keywords internal

check_update <- function(update){
  if(!is.null(update) && (!is.logical(update) || length(update) != 1 || is.na(update))){
    rlang::abort("`update` must be TRUE, FALSE or NULL (fetch the record when the saved copy is old).")
  }
  invisible(update)
}

#' Days after which a saved record (or list of releases) is fetched afresh
#'
#' The `traits.use.update_after_days` option, 60 by default. austraits reads
#' the same option for its saved list of releases.
#' @noRd
#' @keywords internal

update_after_days <- function(){
  days <- getOption("traits.use.update_after_days", 60)
  if(!is.numeric(days) || length(days) != 1 || is.na(days) || days < 0){
    rlang::abort("The `traits.use.update_after_days` option must be a number of days.")
  }
  days
}

#' Should a saved file be fetched afresh, given `update`?
#'
#' @param file the saved file; its modification time is when it was fetched
#' @noRd
#' @keywords internal

needs_update <- function(file, update){
  if(!is.null(update)) return(isTRUE(update))
  age <- difftime(Sys.time(), file.mtime(file), units = "days")
  is.na(age) || as.numeric(age) > update_after_days()
}

#' Do two saved records name different releases?
#'
#' @param a,b record files; `b` may be NULL or missing
#' @return TRUE only if both can be read and differ in version or checksums
#' @noRd
#' @keywords internal

records_differ <- function(a, b){
  if(is.null(b) || !file.exists(a) || !file.exists(b)) return(FALSE)
  tryCatch({
    a <- jsonlite::fromJSON(a)
    b <- jsonlite::fromJSON(b)
    !identical(a$version, b$version) || !setequal(a$files$md5, b$files$md5)
  }, error = function(e) FALSE)
}

#' Does a folder hold a doi's record and the file it names, matching its md5?
#' @noRd
#' @keywords internal

has_cached_copy <- function(doi, path, flattened = FALSE, means = FALSE){
  json <- record_json_path(doi, path)
  if(!file.exists(json)) return(FALSE)
  tryCatch({
    record <- jsonlite::fromJSON(json)
    files <- if(means) means_file(record$files, doi) else database_file(record$files, doi, flattened = flattened)
    file <- file.path(path, basename(files$key))
    file.exists(file) && file_matches_md5(file, if(is.null(files$md5)) NA_character_ else files$md5)
  }, error = function(e) FALSE)
}

#' Create a folder if needed, and say whether it can be written to
#' @noRd
#' @keywords internal

writable_folder <- function(path){
  if(!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  dir.exists(path) && file.access(path, 2) == 0
}

#' Copy a file to where it is missing, keeping its modification time
#'
#' @return TRUE if copied
#' @noRd
#' @keywords internal

seed_file <- function(from, to){
  if(!file.exists(from) || file.exists(to)) return(FALSE)
  file.copy(from, to, copy.date = TRUE)
}

#' Put a copy of a downloaded file in `path`, unless one matching its md5 is
#' there already
#'
#' @param file_nm the file, in the cache folder
#' @param md5 its md5 checksum (NA if the record gives none)
#' @param path the folder to copy it to
#' @param doi the doi, used in messages
#' @noRd
#' @keywords internal

copy_to_path <- function(file_nm, md5, path, doi){
  copy <- file.path(path, basename(file_nm))
  # Without a checksum from the record, compare with the file itself
  if(is.na(md5)) md5 <- unname(tools::md5sum(file_nm))
  if(file.exists(copy) && file_matches_md5(copy, md5)){
    return(invisible(copy))
  }
  # e.g. an earlier release saved under the same name (every MYtraits release
  # is MYtraits.rds). A copy that cannot be made is not a reason to stop: the
  # database loads from the cache.
  if(file.exists(copy) && !remove_file(copy)){
    rlang::warn(paste0("Could not replace '", copy, "' with doi '", doi, "': it still holds another release. ",
                       "Is it open in another R session?"))
    return(invisible(NULL))
  }
  if(!suppressWarnings(file.copy(file_nm, copy, copy.date = TRUE))){
    rlang::warn(paste0("Could not save a copy of doi '", doi, "' in '", path, "'. Can the folder be written to?"))
    return(invisible(NULL))
  }
  message("Saved a copy in '", copy, "'")
  invisible(copy)
}

#' Put a copy of a record in `path`, unless the copy there is the same
#'
#' Not rewritten on every load: an unchanged file is left alone, so a synced
#' or read-only project folder sees no writes.
#' @noRd
#' @keywords internal

copy_record_to_path <- function(from, to){
  if(file.exists(to) && identical(unname(tools::md5sum(from)), unname(tools::md5sum(to)))){
    return(invisible(FALSE))
  }
  invisible(suppressWarnings(file.copy(from, to, overwrite = TRUE, copy.date = TRUE)))
}

#' Say what the cache holds after a download into it
#'
#' @param path the cache folder
#' @param file_nm the database just downloaded
#' @noRd
#' @keywords internal

record_cache_size <- function(path, file_nm){
  cached <- list_cached_databases(path)
  others <- cached[cached$file != basename(file_nm), ]

  msg <- paste0("The cache in '", path, "' now holds ", nrow(cached), " database(s), ",
                round(sum(cached$size_mb), 1), " MB.")
  if(nrow(others) > 0){
    days <- floor(as.numeric(difftime(Sys.time(), others$last_used, units = "days")))
    msg <- paste0(msg, " Also there: ",
                  paste0(others$file, " (", others$size_mb, " MB, last used ", days, " days ago)", collapse = ", "),
                  ". Delete releases you no longer use with clear_database_cache().")
  }
  message(msg)
}

#' Find the files associated with a doi
#'
#' @param doi character string - doi of the record
#' @return list with the doi, source repository and a dataframe of files (key and url)
#' @noRd
#' @keywords internal

resolve_doi_files <- function(doi){
  landing_url <- doi_landing_url(doi)

  # Zenodo
  if(is_zenodo(landing_url)){
    id <- zenodo_id(doi, landing_url)

    # Concept record ids redirect to the latest version
    res <- jsonlite::read_json(paste0("https://zenodo.org/api/records/", id),
                               simplifyVector = TRUE)

    # Restricted, embargoed and closed records list no files
    access <- res$metadata$access_right
    if(length(res$files) == 0 && !is.null(access) && access != "open") {
      rlang::abort(paste0("The files for doi '", doi, "' are ", access,
                          " on Zenodo, so cannot be downloaded. You may be able to request access at https://zenodo.org/records/",
                          res$id))
    }

    files <- data.frame(key = res$files$key, url = res$files$links$self,
                        md5 = stringr::str_match(res$files$checksum, "^md5:([0-9a-f]{32})$")[, 2])

    return(list(doi = doi, source = "zenodo", version = res$metadata$version, files = files))
  }

  # Figshare
  if(is_figshare(landing_url)){
    ids <- figshare_ids(doi, landing_url)

    api_url <- paste0("https://api.figshare.com/v2/articles/", ids[, 2])
    if(!is.na(ids[, 3])) {
      api_url <- paste0(api_url, "/versions/", ids[, 3])
    }

    res <- jsonlite::read_json(api_url, simplifyVector = TRUE)

    files <- data.frame(key = res$files$name, url = res$files$download_url,
                        md5 = dplyr::na_if(res$files$computed_md5, ""))

    return(list(doi = doi, source = "figshare", version = as.character(res$version), files = files))
  }

  # doi resolves directly to an .rds file
  if(grepl("\\.rds(\\?.*)?$", landing_url, ignore.case = TRUE)){
    # No checksum to check a cached file against, so the doi goes in the
    # filename to keep files from different dois apart
    key <- paste0(stringr::str_replace_all(doi, "[^A-Za-z0-9.]+", "_"), "-",
                  basename(stringr::str_remove(landing_url, "\\?.*$")))
    files <- data.frame(key = key, url = landing_url, md5 = NA_character_)

    return(list(doi = doi, source = "url", version = NA_character_, files = files))
  }

  rlang::abort(paste0("doi '", doi, "' resolves to '", landing_url,
                      "', which is not a supported repository (Zenodo, Figshare or a direct .rds link)"))
}

#' Remove a url or `doi:` prefix, in any case, and trailing slashes from a doi
#' @noRd
#' @keywords internal

clean_doi <- function(doi){
  stringr::str_remove(doi, stringr::regex("^(https?://)?(dx\\.)?doi\\.org/", ignore_case = TRUE)) %>%
    stringr::str_remove(stringr::regex("^doi:", ignore_case = TRUE)) %>%
    stringr::str_remove("/+$")
}

#' The landing page url of a doi
#'
#' Zenodo dois contain the record id, so are not sent to doi.org
#' @noRd
#' @keywords internal

doi_landing_url <- function(doi){
  if(stringr::str_detect(doi, stringr::regex("^10\\.5281/zenodo\\.[0-9]+$", ignore_case = TRUE))){
    return(paste0("https://zenodo.org/records/", stringr::str_extract(doi, "[0-9]+$")))
  }
  resolve_doi(doi)
}

#' Which repository a landing page url is in
#' @noRd
#' @keywords internal

is_zenodo <- function(landing_url){
  stringr::str_detect(landing_url, "zenodo\\.org/")
}

#' @rdname is_zenodo
#' @noRd
is_figshare <- function(landing_url){
  stringr::str_detect(landing_url, "figshare\\.com/")
}

#' The Zenodo record id in a landing page url
#' @noRd
#' @keywords internal

zenodo_id <- function(doi, landing_url){
  id <- stringr::str_match(landing_url, "zenodo\\.org/(?:api/)?records?/([0-9]+)")[, 2]

  if(is.na(id)){
    rlang::abort(paste0("Could not find Zenodo record id for doi '", doi, "'"))
  }

  id
}

#' The Figshare article id and version of a doi
#'
#' Taken from the doi itself (`10.6084/m9.figshare.<id>[.v<version>]`); the
#' landing url's slug can contain numbers too, so it is only a fallback.
#' @return a one-row character matrix: the match, the article id and the
#'   version (`NA` if the doi names no version)
#' @noRd
#' @keywords internal

figshare_ids <- function(doi, landing_url){
  ids <- stringr::str_match(doi, stringr::regex("figshare\\.([0-9]+)(?:\\.v([0-9]+))?/?$", ignore_case = TRUE))
  if(is.na(ids[, 2])) {
    ids <- stringr::str_match(landing_url, "/([0-9]+)(?:/([0-9]+))?/?$")
  }

  if(is.na(ids[, 2])){
    rlang::abort(paste0("Could not find Figshare article id for doi '", doi, "'"))
  }

  ids
}

#' Check a file against its md5 checksum
#'
#' @param file path to the file
#' @param md5 expected md5 checksum, or NA if the repository gives none
#' @return TRUE if the file matches, or if there is no checksum to check against
#' @noRd
#' @keywords internal

file_matches_md5 <- function(file, md5){
  is.na(md5) || unname(tools::md5sum(file)) == md5
}

#' Resolve a doi to its landing page url using the doi.org handle API
#'
#' @noRd
#' @keywords internal

resolve_doi <- function(doi){
  res <- tryCatch(
    suppressWarnings(jsonlite::read_json(paste0("https://doi.org/api/handles/", doi), simplifyVector = TRUE)),
    error = function(e) NULL
  )

  if(is.null(res) || res$responseCode != 1){
    rlang::abort(paste0("Could not resolve doi '", doi, "'"), class = "traits_use_unreachable")
  }

  res$values$data$value[res$values$type == "URL"][[1]]
}


#' Download a database file, saving it only once the download is complete
#'
#' @param url url of download via Zenodo API
#' @param filename path the file is saved to, e.g. data/traits.build/austraits-7.0.0.rds
#' @param path folder the file is saved in, used in messages
#' @param name name of the database, used in messages
#' @noRd
#' @keywords internal

download_database <- function(url, filename, path, name = "the database") {
  # Allow at least 300s for large downloads, restoring the user's timeout after
  o <- options(timeout = max(300, getOption("timeout")))
  on.exit(options(o), add = TRUE)

  # Download to a temporary file, so a failed download leaves nothing at `filename`
  fn <- paste0(tempfile(), ".download")
  on.exit(unlink(fn), add = TRUE)

  message("Downloading ", name, " to '", path,"'")

  res <- utils::download.file(url=url, destfile=fn, method="auto", quiet = FALSE, mode = "wb", cacheOK = TRUE)

  if (res != 0) {
    stop("Could not download ", name, "!")
  }

  # file.rename() fails when the temporary folder is on a different device to
  # `filename` (e.g. another drive on Windows), so fall back to copying
  if (! suppressWarnings(file.rename(fn, filename))) {
    if (! file.copy(fn, filename, overwrite = TRUE)) {
      stop("Could not save ", name, " to '", filename, "'")
    }
  }

  invisible(filename)
}
