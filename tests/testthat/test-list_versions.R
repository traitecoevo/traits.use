# A fake Zenodo record of n releases, published one a day, served in pages
# of `size` like Zenodo's search (by concept record id) and versions listing
# (by any release's id)
zenodo_fake <- function(n = 30, concept = 100, version = TRUE) {
  ids <- 200 + seq_len(n)
  requested <- character()
  read_json <- function(url, ...) {
    requested <<- c(requested, url)
    size <- as.integer(stringr::str_match(url, "size=([0-9]+)")[, 2])
    page <- as.integer(stringr::str_match(url, "page=([0-9]+)")[, 2])
    stopifnot(size <= 25, grepl("sort=version", url, fixed = TRUE))
    search <- stringr::str_match(url, "records\\?q=conceptrecid:([0-9]+)&all_versions=true")[, 2]
    listing <- stringr::str_match(url, "records/([0-9]+)/versions\\?")[, 2]
    # A search for anything but the concept record id finds nothing; the
    # versions listing 404s for the concept record id
    if (!is.na(search) && search != concept) return(list(hits = list(total = 0, hits = list())))
    if (!is.na(listing) && listing == concept) stop("HTTP status was '404 Not Found'")
    stopifnot(!is.na(search) || !is.na(listing))
    # Newest first, as Zenodo sorts them
    i <- rev(ids)[intersect(seq_len(n), (page - 1) * size + seq_len(size))]
    i <- i[!is.na(i)]
    hits <- if (length(i) == 0) list() else data.frame(doi = paste0("10.5281/zenodo.", i))
    if (length(i) > 0) {
      hits$metadata <- data.frame(publication_date = as.character(as.Date("2020-01-01") + i - 200))
      if (version) hits$metadata$version <- paste0("v", i - 200, ".0.0")
    }
    list(hits = list(total = n, hits = hits))
  }
  list(read_json = read_json, requested = function() requested)
}

test_that("list_versions() pages through every Zenodo release, newest first", {
  fake <- zenodo_fake()
  local_mocked_bindings(read_json = fake$read_json, .package = "jsonlite")

  versions <- list_versions("https://doi.org/10.5281/zenodo.100")

  expect_s3_class(versions, "tbl_df")
  expect_named(versions, c("version", "doi", "publication_date"))
  expect_equal(nrow(versions), 30)
  expect_equal(versions$version[c(1, 30)], c("v30.0.0", "v1.0.0"))
  expect_equal(versions$doi[1], "10.5281/zenodo.230")
  expect_s3_class(versions$publication_date, "Date")
  expect_false(is.unsorted(rev(versions$publication_date)))
  # A concept doi: two pages of the search, nothing else
  expect_equal(fake$requested(), paste0(
    "https://zenodo.org/api/records?q=conceptrecid:100&all_versions=true&sort=version&size=25&page=", 1:2))

  # The doi of an older release lists the same releases: the search finds
  # nothing, then two pages of its versions listing
  fake <- zenodo_fake()
  local_mocked_bindings(read_json = fake$read_json, .package = "jsonlite")
  expect_equal(list_versions("10.5281/zenodo.205"), versions)
  expect_length(fake$requested(), 3)
  expect_equal(fake$requested()[2:3], paste0(
    "https://zenodo.org/api/records/205/versions?sort=version&size=25&page=", 1:2))
})

test_that("list_versions() stops at a full last page, and lists one release", {
  # 25 releases fill one page exactly, so no second page is asked for
  fake <- zenodo_fake(n = 25)
  local_mocked_bindings(read_json = fake$read_json, .package = "jsonlite")
  expect_equal(nrow(list_versions("10.5281/zenodo.100")), 25)
  expect_length(fake$requested(), 1)

  # A record of one release that records no version
  fake <- zenodo_fake(n = 1, version = FALSE)
  local_mocked_bindings(read_json = fake$read_json, .package = "jsonlite")
  versions <- list_versions("10.5281/zenodo.201")
  expect_equal(nrow(versions), 1)
  expect_identical(versions$version, NA_character_)
  expect_equal(versions$doi, "10.5281/zenodo.201")

  # A record that lists no versions gives a clear error
  local_mocked_bindings(
    read_json = function(url, ...) if (grepl("/versions", url)) list(hits = list(total = 0, hits = list())) else list(id = 1),
    .package = "jsonlite"
  )
  expect_error(list_versions("10.5281/zenodo.1"), "lists no versions")

})

test_that("list_versions() accepts a doi in any of its usual forms", {
  for (doi in c("DOI:10.5281/zenodo.100", "HTTPS://DOI.ORG/10.5281/zenodo.100",
                "https://dx.doi.org/10.5281/zenodo.100", "10.5281/zenodo.100/")) {
    fake <- zenodo_fake(n = 2)
    local_mocked_bindings(read_json = fake$read_json, .package = "jsonlite")
    expect_equal(nrow(list_versions(doi)), 2)
    # Read as a Zenodo doi, without asking doi.org
    expect_true(startsWith(fake$requested()[1], "https://zenodo.org/api/records?q=conceptrecid:100&"))
  }
  expect_error(list_versions("doi:"), "single doi")
  expect_error(list_versions("https://doi.org/"), "single doi")
})

test_that("list_versions() sorts releases of one day by version", {
  # Listed in no particular order, as a repository might
  local_mocked_bindings(
    read_json = function(url, ...) {
      if (!grepl("/versions", url)) return(list(hits = list(total = 0, hits = list())))
      hits <- data.frame(doi = paste0("10.5281/zenodo.", 1:6))
      hits$metadata <- data.frame(version = c("v3.0.2", "v3.0.10", "v4.0.0", "draft", "v3.0.0", "v3.0.1"),
                                  publication_date = c(rep("2021-07-14", 5), "2021-07-14"))
      hits$metadata$publication_date[3] <- "2022-11-27"
      list(hits = list(total = 6, hits = hits))
    },
    .package = "jsonlite"
  )
  # Newest date first, then the highest version; a version that is not a
  # number last
  expect_equal(list_versions("10.5281/zenodo.1")$version,
               c("v4.0.0", "v3.0.10", "v3.0.2", "v3.0.1", "v3.0.0", "draft"))

  # Equal versions of one day keep the repository's order
  local_mocked_bindings(
    read_json = function(url, ...) {
      if (!grepl("/versions", url)) return(list(hits = list(total = 0, hits = list())))
      hits <- data.frame(doi = paste0("10.5281/zenodo.", 1:3))
      hits$metadata <- data.frame(version = c("v1.0.0", "v1.0", "v1.0.0"), publication_date = "2021-07-14")
      list(hits = list(total = 3, hits = hits))
    },
    .package = "jsonlite"
  )
  expect_equal(list_versions("10.5281/zenodo.1")$doi, paste0("10.5281/zenodo.", 1:3))
})

test_that("list_versions() lists Figshare versions", {
  requested <- character()
  local_mocked_bindings(
    resolve_doi = function(doi) "https://figshare.com/articles/dataset/2019/12345678/2"
  )
  local_mocked_bindings(
    read_json = function(url, ...) {
      requested <<- c(requested, url)
      if (grepl("/versions$", url)) {
        return(data.frame(version = 1:3, url = paste0(url, "/", 1:3)))
      }
      v <- as.integer(stringr::str_extract(url, "[0-9]+$"))
      # Versions 2 and 3 published on the same day
      list(version = v, doi = paste0("10.6084/m9.figshare.12345678.v", v),
           published_date = c("2019-01-01T10:00:00Z", "2019-02-01T10:00:00Z", "2019-02-01T15:00:00Z")[v])
    },
    .package = "jsonlite"
  )

  versions <- list_versions("10.6084/m9.figshare.12345678.v1")
  expect_equal(versions$version, c("3", "2", "1"))
  expect_equal(versions$doi, paste0("10.6084/m9.figshare.12345678.v", 3:1))
  expect_equal(versions$publication_date, as.Date(c("2019-02-01", "2019-02-01", "2019-01-01")))
  expect_equal(requested[1], "https://api.figshare.com/v2/articles/12345678/versions")

  # A doi without a version lists the same versions
  expect_equal(list_versions("10.6084/m9.figshare.12345678"), versions)
})

test_that("list_versions() gives clear errors", {
  expect_error(list_versions(NULL), "single doi")
  expect_error(list_versions(c("a", "b")), "single doi")
  expect_error(list_versions(""), "single doi")

  local_mocked_bindings(resolve_doi = function(doi) "https://example.org/db.rds")
  expect_error(list_versions("10.1234/abc"), "Only Zenodo and Figshare")

  local_mocked_bindings(resolve_doi = function(doi) "https://figshare.com/articles/dataset/x/12345678")
  local_mocked_bindings(read_json = function(...) list(), .package = "jsonlite")
  expect_error(list_versions("10.6084/m9.figshare.12345678"), "no published versions")
})

test_that("list_versions() lists the releases of AusTraits", {
  skip_on_cran()
  skip_if_offline()
  versions <- list_versions("10.5281/zenodo.3568417")

  expect_gte(nrow(versions), 14)
  expect_true("10.5281/zenodo.10156222" %in% versions$doi)
  expect_equal(versions$version[versions$doi == "10.5281/zenodo.10156222"], "v5.0.0")
  expect_equal(versions$version[nrow(versions)], "v0.1.0")
  # A release's doi lists the same releases as the concept doi
  expect_equal(list_versions("10.5281/zenodo.10156222"), versions)
})
