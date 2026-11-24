#' List the releases of a traits.build database
#'
#' @description Finds every release of a database on its repository, given
#' the doi of any one of them or the doi of the whole record (a Zenodo concept
#' doi, or a Figshare doi without a version). Pass a release's doi to
#' [load_database()] to load it. Zenodo and Figshare records are supported.
#'
#' @param doi character string - a doi of the database, e.g. AusTraits'
#'   concept doi "10.5281/zenodo.3568417", or the doi of one of its releases
#'
#' @return a tibble with one row per release, newest first: `version` (as
#'   recorded on the repository, e.g. "v7.0.0" on Zenodo or "3" on Figshare),
#'   `doi` (the release's own doi) and `publication_date`. A release whose
#'   files are restricted is listed too, though [load_database()] cannot
#'   download it.
#' @export
#' @seealso [load_database()]; `austraits::get_versions()`, which lists the
#'   releases of AusTraits
#'
#' @examplesIf interactive()
#' # The releases of AusTraits
#' versions <- list_versions("10.5281/zenodo.3568417")
#' versions
#'
#' # Load the newest
#' austraits <- load_database(doi = versions$doi[1])

list_versions <- function(doi){
  if(!is.character(doi) || length(doi) != 1 || is.na(doi) || !nzchar(clean_doi(doi))){
    rlang::abort("`doi` must be a single doi.")
  }

  doi <- clean_doi(doi)
  landing_url <- doi_landing_url(doi)

  if(is_zenodo(landing_url)){
    versions <- zenodo_versions(zenodo_id(doi, landing_url))
  } else if(is_figshare(landing_url)){
    versions <- figshare_versions(figshare_ids(doi, landing_url)[, 2])
  } else {
    rlang::abort(paste0("doi '", doi, "' resolves to '", landing_url,
                        "'. Only Zenodo and Figshare records have versions to list."))
  }

  # Newest first: by publication date, then by version for releases published
  # on the same day (AusTraits 3.0.0 to 3.0.2). A version that is not a
  # number (after any "v") goes after those that are; order() then keeps
  # the repository's order.
  versions <- dplyr::mutate(versions, publication_date = as.Date(.data$publication_date))
  version_number <- numeric_version(sub("^[vV]", "", versions$version), strict = FALSE)
  versions[order(-as.numeric(versions$publication_date), -rank_versions(version_number), na.last = TRUE), , drop = FALSE]
}

#' Rank versions, NA for those that are not version numbers
#'
#' @param v a `numeric_version` vector, with NA elements
#' @noRd
#' @keywords internal

rank_versions <- function(v){
  out <- rep(NA_real_, length(v))
  ok <- !is.na(v)
  # Equal versions share a rank, so order() keeps their repository order
  out[ok] <- rank(v[ok], ties.method = "min")
  out
}

#' The releases of a Zenodo record
#'
#' @param id a Zenodo record id: of any release, or the concept record id
#' @return a tibble of `version`, `doi` and `publication_date` (character)
#' @noRd
#' @keywords internal

zenodo_versions <- function(id){
  # The listing comes in pages; Zenodo refuses a page size above 25.
  # list_versions() sorts the result itself; sort=version only keeps the
  # order stable from page to page.
  size <- 25

  # A concept record id: one search lists all its releases. Searching for a
  # release's id finds nothing, so then ask for that release's versions
  # listing (any release's id gives it; a concept record id 404s there)
  page_url <- function(page) {
    paste0("https://zenodo.org/api/records?q=conceptrecid:", id,
           "&all_versions=true&sort=version&size=", size, "&page=", page)
  }
  res <- jsonlite::read_json(page_url(1), simplifyVector = TRUE)
  if(! isTRUE(res$hits$total > 0)){
    page_url <- function(page) {
      paste0("https://zenodo.org/api/records/", id, "/versions?sort=version&size=", size, "&page=", page)
    }
    res <- jsonlite::read_json(page_url(1), simplifyVector = TRUE)
  }

  versions <- list()
  page <- 1
  repeat {
    hits <- res$hits$hits
    if(length(hits) == 0 || NROW(hits) == 0) break

    # version is optional on Zenodo: a page where no release has one has no
    # version column at all
    versions[[page]] <- tibble::tibble(
      version = if(is.null(hits$metadata$version)) NA_character_ else as.character(hits$metadata$version),
      doi = hits$doi,
      publication_date = hits$metadata$publication_date
    )

    total <- res$hits$total
    if(!is.numeric(total) || sum(vapply(versions, nrow, integer(1))) >= total) break
    page <- page + 1
    res <- jsonlite::read_json(page_url(page), simplifyVector = TRUE)
  }

  if(length(versions) == 0){
    rlang::abort(paste0("Zenodo lists no versions of record ", id))
  }

  dplyr::bind_rows(versions)
}

#' The versions of a Figshare article
#'
#' @param id a Figshare article id
#' @return a tibble of `version`, `doi` and `publication_date` (character)
#' @noRd
#' @keywords internal

figshare_versions <- function(id){
  # Lists each version's number and api url, but not its doi or date
  index <- jsonlite::read_json(paste0("https://api.figshare.com/v2/articles/", id, "/versions"),
                               simplifyVector = TRUE)

  if(length(index) == 0 || NROW(index) == 0){
    rlang::abort(paste0("Figshare lists no published versions of article ", id))
  }

  records <- lapply(index$url, jsonlite::read_json, simplifyVector = TRUE)

  tibble::tibble(
    version = vapply(records, function(r) as.character(r$version), character(1)),
    doi = vapply(records, function(r) r$doi, character(1)),
    publication_date = vapply(records, function(r) substr(r$published_date, 1, 10), character(1))
  )
}
