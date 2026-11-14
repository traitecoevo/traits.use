#' Manage the folder where downloaded databases are kept
#'
#' @description By default, [load_database()] keeps the databases it downloads
#' in one folder per user, so each release is downloaded once per computer and
#' shared by every project and R session that loads it.
#'
#' - `database_cache_dir()` gives the folder.
#' - `list_cached_databases()` lists the databases in it, with their size and
#'   when each was last used.
#' - `clear_database_cache()` deletes some or all of them, e.g. those not used
#'   for six months with `older_than = 180`.
#'
#' A release of AusTraits is about 20 MB (its flattened table several times
#' that), and each new release is usually kept beside the old ones, so delete
#' the ones you no longer use.
#'
#' The folder is, in order of preference:
#'
#' 1. the `traits.use.cache_dir` option, if set, e.g. with
#'    `options(traits.use.cache_dir = "~/data/traits")` in your `.Rprofile`;
#' 2. otherwise `tools::R_user_dir("traits.use", which = "cache")`, which
#'    follows each operating system's convention for cache files (and the
#'    `R_USER_CACHE_DIR` environment variable, if set).
#'
#' To keep a copy of a database with a project instead, give
#' [load_database()] a `path`; the functions here take the same `path`. They
#' only ever touch the files [load_database()] wrote there: the database
#' `.rds` files named in its record files (`10.*.json`, one per doi).
#'
#' @param path folder to list or clear; the cache folder by default.
#' @param files names of the database `.rds` files to delete, as listed by
#'   `list_cached_databases()`.
#' @param older_than delete the databases not used (loaded from the cache) for
#'   this many days. In a folder given as `path`, or where the cache cannot be
#'   written to, this is days since the file was downloaded.
#' @param ask if `TRUE`, asks for confirmation before deleting anything.
#'
#' @details With neither `files` nor `older_than`, `clear_database_cache()`
#'   deletes every database in `path`, with its record file.
#'
#' @return `database_cache_dir()` returns the folder's path (which may not
#'   exist yet). `list_cached_databases()` returns a tibble with one row per
#'   database: `file`, `size_mb` and `last_used`. `clear_database_cache()`
#'   invisibly returns the paths of the files it deleted.
#'
#' @seealso [load_database()]
#' @export
#'
#' @examples
#' database_cache_dir()
#' list_cached_databases()
#'
#' # Delete the cached databases not used for six months, with
#' # clear_database_cache(older_than = 180)

database_cache_dir <- function() {
  path <- getOption("traits.use.cache_dir")

  if (is.null(path)) {
    return(tools::R_user_dir("traits.use", which = "cache"))
  }

  if (!is.character(path) || length(path) != 1 || is.na(path) || !nzchar(path)) {
    rlang::abort("The `traits.use.cache_dir` option must be a single folder path.")
  }

  path.expand(path)
}

#' @rdname database_cache_dir
#' @export

list_cached_databases <- function(path = database_cache_dir()) {
  files <- unique(cached_records(path)$file)
  files <- files[file.exists(file.path(path, files))]
  info <- file.info(file.path(path, files))

  dplyr::tibble(
    file = files,
    size_mb = round(info$size / 1e6, 1),
    last_used = info$mtime
  )
}

#' @rdname database_cache_dir
#' @export

clear_database_cache <- function(files = NULL, path = database_cache_dir(),
                                 older_than = NULL, ask = interactive()) {
  if (!is.null(files) && !is.null(older_than)) {
    rlang::abort("Give `files` or `older_than`, not both.")
  }

  if (!dir.exists(path)) {
    message("Nothing to delete: '", path, "' does not exist")
    return(invisible(character()))
  }

  cached <- list_cached_databases(path)
  clear_all <- is.null(files) && is.null(older_than)

  if (!is.null(files)) {
    files <- unique(files)
    unknown <- setdiff(files, cached$file)
    if (length(unknown) > 0) {
      rlang::abort(c(
        paste0("Not a database in '", path, "': ", paste0("'", unknown, "'", collapse = ", ")),
        "i" = "See `list_cached_databases()` for the databases there."
      ))
    }
  } else if (!is.null(older_than)) {
    if (!is.numeric(older_than) || length(older_than) != 1 || is.na(older_than) || older_than < 0) {
      rlang::abort("`older_than` must be a number of days.")
    }
    files <- cached$file[cached$last_used < Sys.time() - older_than * 86400]
  } else {
    files <- cached$file
  }

  # Record files left naming no database are deleted with the databases
  records <- cached_records(path)
  remaining <- setdiff(cached$file, files)
  orphans <- setdiff(records$json, records$json[records$file %in% remaining])
  to_delete <- c(file.path(path, files), file.path(path, orphans))

  if (length(files) == 0 && !(clear_all && length(orphans) > 0)) {
    message("No databases to delete in '", path, "'")
    return(invisible(character()))
  }

  size_mb <- round(sum(cached$size_mb[cached$file %in% files]), 1)
  summary <- paste0(length(files), " database(s) (", size_mb, " MB)",
                    if (length(orphans) > 0) paste0(" and ", length(orphans), " record file(s)"),
                    " from '", path, "'",
                    if (length(files) > 0) paste0(": ", paste(files, collapse = ", ")))

  if (isTRUE(ask) && !isTRUE(ask_yes_no(paste0("Delete ", summary, "?")))) {
    message("Nothing deleted")
    return(invisible(character()))
  }

  unlink(to_delete)
  message("Deleted ", summary)

  # Remove the default cache folder once empty, but never a folder the user
  # chose, as `path` or with the option (which could be tempdir())
  if (is.null(getOption("traits.use.cache_dir")) &&
      same_folder(path, tools::R_user_dir("traits.use", which = "cache")) &&
      length(list.files(path, all.files = TRUE, no.. = TRUE)) == 0) {
    unlink(path, recursive = TRUE)
  }

  invisible(to_delete)
}

#' The record files load_database() wrote in a folder, and the files they name
#'
#' @return data frame with columns `json` (record file name) and `file` (the
#'   database `.rds` load_database() downloads for that record, existing or
#'   not; `NA` for a record it refused)
#' @noRd
#' @keywords internal

cached_records <- function(path) {
  # Named by load_record_json() from the doi, which starts "10."
  jsons <- list.files(path, pattern = "^10\\.[^/\\\\]*\\.json$")

  rows <- lapply(jsons, function(json) {
    tryCatch({
      record <- jsonlite::fromJSON(file.path(path, json))
      # Anything else with this name was not written by load_database()
      if(!is.list(record) || !is.data.frame(record$files) || is.null(record$files$key)) {
        return(NULL)
      }
      # Only the file load_database() downloads; NA for a record it refused
      key <- tryCatch(basename(database_file(record$files, json)$key), error = function(e) NA_character_)
      data.frame(json = json, file = key)
    }, error = function(e) NULL)
  })

  do.call(rbind, c(list(data.frame(json = character(), file = character())), rows))
}

#' Do two paths name the same folder?
#' @noRd
#' @keywords internal

same_folder <- function(a, b) {
  identical(normalizePath(a, winslash = "/", mustWork = FALSE),
            normalizePath(b, winslash = "/", mustWork = FALSE))
}

#' utils::askYesNo(), wrapped so tests can stand in for the user
#' @noRd
#' @keywords internal

ask_yes_no <- function(msg) {
  utils::askYesNo(msg, default = FALSE)
}
