#' Manage the folder where downloaded databases are kept
#'
#' @description By default, [load_database()] keeps the databases it downloads
#' in one folder per user, so each release is downloaded once per computer and
#' shared by every project and R session that loads it.
#'
#' - `database_cache_dir()` gives the folder.
#' - `list_cached_databases()` lists the databases in it, with their size.
#' - `clear_database_cache()` deletes some or all of them.
#'
#' A release of AusTraits is around 100 MB or more, and new releases are added
#' beside old ones rather than replacing them, so delete the ones you no longer
#' use.
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
#' [load_database()] a `path`; the functions here take the same `path`.
#'
#' @param path folder to list or clear; the cache folder by default.
#' @param files names of the `.rds` files to delete, as listed by
#'   `list_cached_databases()`. If `NULL`, every `.rds` and record `.json` file
#'   in `path` is deleted.
#' @param ask if `TRUE`, asks for confirmation before deleting anything.
#'
#' @return `database_cache_dir()` returns the folder's path (which may not
#'   exist yet). `list_cached_databases()` returns a tibble with one row per
#'   `.rds` file: `file`, `size_mb` and `modified`. `clear_database_cache()`
#'   invisibly returns the paths of the files it deleted.
#'
#' @seealso [load_database()]
#' @export
#'
#' @examples
#' database_cache_dir()
#' list_cached_databases()
#'
#' # Clearing a folder of downloads, here a temporary one
#' path <- file.path(tempdir(), "traits_use_example")
#' dir.create(path)
#' saveRDS(list(), file.path(path, "database-1.0.0.rds"))
#' list_cached_databases(path)
#' clear_database_cache(path = path, ask = FALSE)

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
  files <- list.files(path, pattern = "\\.rds$", full.names = TRUE, ignore.case = TRUE)
  info <- file.info(files)

  dplyr::tibble(
    file = basename(files),
    size_mb = round(info$size / 1e6, 1),
    modified = info$mtime
  )
}

#' @rdname database_cache_dir
#' @export

clear_database_cache <- function(files = NULL, path = database_cache_dir(), ask = interactive()) {
  if (!dir.exists(path)) {
    message("Nothing to delete: '", path, "' does not exist")
    return(invisible(character()))
  }

  if (is.null(files)) {
    # Only the files load_database() writes, so nothing else in a project
    # folder given as `path` is touched
    to_delete <- list.files(path, pattern = "\\.(rds|json)$", full.names = TRUE, ignore.case = TRUE)
  } else {
    unknown <- setdiff(files, list_cached_databases(path)$file)
    if (length(unknown) > 0) {
      rlang::abort(c(
        paste0("Not a database in '", path, "': ", paste0("'", unknown, "'", collapse = ", ")),
        "i" = "See `list_cached_databases()` for the files there."
      ))
    }
    to_delete <- file.path(path, files)
  }

  if (length(to_delete) == 0) {
    message("Nothing to delete in '", path, "'")
    return(invisible(character()))
  }

  size_mb <- round(sum(file.info(to_delete)$size) / 1e6, 1)

  if (isTRUE(ask)) {
    ok <- utils::askYesNo(paste0("Delete ", length(to_delete), " file(s) (", size_mb,
                                 " MB) from '", path, "'?"), default = FALSE)
    if (!isTRUE(ok)) {
      message("Nothing deleted")
      return(invisible(character()))
    }
  }

  unlink(to_delete)
  message("Deleted ", length(to_delete), " file(s) (", size_mb, " MB) from '", path, "'")

  # Leave no empty folder behind
  if (length(list.files(path, all.files = TRUE, no.. = TRUE)) == 0) {
    unlink(path, recursive = TRUE)
  }

  invisible(to_delete)
}
