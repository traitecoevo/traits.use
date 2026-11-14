path = "ignore/data/austraits"

# A fake release served from a local file, to keep tests offline. Its record
# is what resolve_doi_files() would return; every release is MYtraits.rds, as
# for MYtraits, so releases can only be told apart by md5.
file_url <- function(file) {
  file <- normalizePath(file, winslash = "/")
  paste0(if (startsWith(file, "/")) "file://" else "file:///", file)
}

make_release <- function(src, version, n, md5 = NULL) {
  dir.create(file.path(src, version), recursive = TRUE)
  file <- file.path(src, version, "MYtraits.rds")
  saveRDS(list(traits = data.frame(value = seq_len(n)), taxa = data.frame(), methods = data.frame(),
               sources = RefManageR::BibEntry(bibtype = "Misc", key = "Src_2001", title = "T", author = "A B", year = 2001)), file)
  list(doi = paste0("10.5281/zenodo.", version), source = "zenodo", version = version,
       files = data.frame(key = "MYtraits.rds", url = file_url(file),
                          md5 = if (is.null(md5)) unname(tools::md5sum(file)) else md5))
}

test_that("load_database is working", {
  skip_on_cran()
  skip_if_offline()
  database <- load_database(doi = "10.5281/zenodo.10156222", path = path, update = TRUE)
  
  expect_visible(database)
  expect_named(database)
  expect_type(database, "list")
  expect_equal(class(database), "traits.build")
  
  # doi url prefix is removed and cached record json is reused
  database2 <- load_database(doi = "https://doi.org/10.5281/zenodo.10156222", path = path, update = FALSE)
  expect_equal(database, database2)
})

test_that("A cached file from a different release is not reused", {
  # Some databases reuse one filename for every release (every MYtraits
  # release is MYtraits.rds), so cached files can only be told apart by md5.
  # Two fake releases, served from local files, keep this test offline.
  src <- tempfile("releases")
  path_cache <- tempfile("cache")
  dir.create(src)
  on.exit(unlink(c(src, path_cache), recursive = TRUE), add = TRUE)

  releases <- list(
    "10.5281/zenodo.1" = make_release(src, "1", 3),
    "10.5281/zenodo.2" = make_release(src, "2", 5),
    "10.5281/zenodo.3" = make_release(src, "3", 7, md5 = strrep("0", 32))
  )
  local_mocked_bindings(resolve_doi_files = function(doi) releases[[doi]])

  expect_message(v1 <- load_database(doi = "10.5281/zenodo.1", path = path_cache), "is version 1")
  v2 <- load_database(doi = "10.5281/zenodo.2", path = path_cache)
  # sources get the class that lets `$` look references up by key
  expect_s3_class(v1$sources, "traits_build_sources")
  expect_identical(unname(unlist(v1$sources$Src_2001$title)), "T")
  expect_equal(nrow(v1$traits), 3)
  expect_equal(nrow(v2$traits), 5)

  # Going back to release 1 offline replaces release 2's file of the same name
  expect_message(
    v1_again <- load_database(doi = "10.5281/zenodo.1", path = path_cache, update = FALSE),
    "does not match"
  )
  expect_equal(v1_again, v1)

  # A corrupted cached file is downloaded again, even with update = FALSE
  writeLines("not an rds", file.path(path_cache, "MYtraits.rds"))
  expect_message(
    v1_again <- load_database(doi = "10.5281/zenodo.1", path = path_cache, update = FALSE),
    "does not match"
  )
  expect_equal(v1_again, v1)

  # A download that does not match its checksum stops instead of loading
  expect_error(
    suppressMessages(load_database(doi = "10.5281/zenodo.3", path = path_cache)),
    "does not match the md5 checksum"
  )
})

test_that("download_database saves to the full path and restores the timeout", {
  src <- tempfile(fileext = ".rds")
  dest <- tempfile("dest")
  dir.create(dest)
  on.exit(unlink(c(src, dest), recursive = TRUE), add = TRUE)
  saveRDS(1:3, src)
  src <- normalizePath(src, winslash = "/")
  url <- paste0(if (startsWith(src, "/")) "file://" else "file:///", src)

  old <- options(timeout = 60)
  on.exit(options(old), add = TRUE)

  filename <- file.path(dest, "db.rds")
  suppressMessages(download_database(url, filename, path = dest, name = "test"))

  expect_equal(list.files(dest), "db.rds")
  expect_equal(readRDS(filename), 1:3)
  expect_equal(getOption("timeout"), 60)
})

test_that("Restricted Zenodo records give a clear error", {
  local_mocked_bindings(
    read_json = function(...) list(id = 22961387, metadata = list(access_right = "restricted", version = "0.0.2"), files = list()),
    .package = "jsonlite"
  )
  expect_error(resolve_doi_files("10.5281/zenodo.22961387"), "are restricted on Zenodo")
})

test_that("Figshare ids come from the doi, not the landing url's slug", {
  requested <- NULL
  local_mocked_bindings(
    resolve_doi = function(doi) "https://figshare.com/articles/dataset/2019/12345678/2"
  )
  local_mocked_bindings(
    read_json = function(url, ...) {
      requested <<- c(requested, url)
      list(version = 4, files = data.frame(name = "db.rds", download_url = "u", computed_md5 = ""))
    },
    .package = "jsonlite"
  )
  expect_identical(resolve_doi_files("10.6084/m9.figshare.12345678.v4")$version, "4")
  resolve_doi_files("10.6084/M9.FIGSHARE.12345678.V4/")
  resolve_doi_files("10.6084/m9.figshare.12345678")
  expect_identical(requested, c(
    "https://api.figshare.com/v2/articles/12345678/versions/4",
    "https://api.figshare.com/v2/articles/12345678/versions/4",
    "https://api.figshare.com/v2/articles/12345678"
  ))
})

test_that("Right errors are tripped", {
  expect_error(load_database(path = path), "Please supply a doi")
  expect_error(load_database(doi = "10.5281/zenodo.10156222", path = c("a", "b")), "single folder path")
  expect_error(load_database(doi = "10.5281/zenodo.10156222", path = ""), "single folder path")
})

test_that("A doi that doesn't resolve gives a clear error", {
  # Asks doi.org
  skip_on_cran()
  skip_if_offline()
  expect_error(load_database(doi = "10.1000/notarealdoi123", path = path), "Could not resolve doi")
})

test_that("A record without a relational .rds gives a clear error", {
  skip_on_cran()
  skip_if_offline()
  # AusTraits v0.1.0 has no .rds file
  expect_error(load_database(doi = "10.5281/zenodo.3568418", path = path), "No .rds file found")
})

test_that("A record whose only .rds is flattened is not downloaded", {
  path_flat <- tempfile("flat")
  on.exit(unlink(path_flat, recursive = TRUE), add = TRUE)
  local_mocked_bindings(
    resolve_doi_files = function(doi) list(doi = doi, source = "zenodo", version = "1",
      files = data.frame(key = "db-flattened.rds", url = "file:///nonexistent/db-flattened.rds", md5 = NA))
  )
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.9", path = path_flat)),
               "Only flattened .rds files found")
})

test_that("Without a path, databases are kept in the per-user cache and reused", {
  src <- tempfile("releases")
  cache <- tempfile("cache")
  on.exit(unlink(c(src, cache), recursive = TRUE), add = TRUE)
  withr::local_options(traits.use.cache_dir = cache)

  releases <- list(
    "10.5281/zenodo.1" = make_release(src, "1", 3),
    "10.5281/zenodo.4" = make_release(src, "4", 4)
  )
  # Releases 1 and 4 share a filename; give release 4 its own, as most databases do
  file.rename(file.path(src, "4", "MYtraits.rds"), file.path(src, "4", "OTHERtraits.rds"))
  releases[["10.5281/zenodo.4"]]$files$key <- "OTHERtraits.rds"
  releases[["10.5281/zenodo.4"]]$files$url <- file_url(file.path(src, "4", "OTHERtraits.rds"))
  real_download <- download_database
  n_downloads <- 0
  local_mocked_bindings(
    resolve_doi_files = function(doi) releases[[doi]],
    download_database = function(...) {
      n_downloads <<- n_downloads + 1
      real_download(...)
    }
  )

  expect_identical(database_cache_dir(), cache)
  expect_message(v1 <- load_database(doi = "10.5281/zenodo.1"), "now holds 1 database")
  expect_true(file.exists(file.path(cache, "MYtraits.rds")))
  expect_equal(nrow(v1$traits), 3)

  # A second load, from any project, reuses the download
  v1_again <- suppressMessages(load_database(doi = "10.5281/zenodo.1", update = FALSE))
  expect_equal(v1_again, v1)
  expect_identical(n_downloads, 1)

  expect_message(load_database(doi = "10.5281/zenodo.4"), "now holds 2 database")
  cached <- list_cached_databases()
  expect_named(cached, c("file", "size_mb", "modified"))
  expect_setequal(cached$file, c("MYtraits.rds", "OTHERtraits.rds"))

  # Deleting one release, then the rest
  expect_error(clear_database_cache("nothere.rds", ask = FALSE), "Not a database")
  expect_message(deleted <- clear_database_cache("MYtraits.rds", ask = FALSE), "Deleted 1 file")
  expect_identical(basename(deleted), "MYtraits.rds")
  expect_identical(list_cached_databases()$file, "OTHERtraits.rds")

  expect_message(clear_database_cache(ask = FALSE), "Deleted")
  expect_false(dir.exists(cache))
  expect_identical(nrow(list_cached_databases()), 0L)
  expect_message(clear_database_cache(ask = FALSE), "does not exist")
})

test_that("A path keeps the database with a project, and clearing it leaves other files", {
  src <- tempfile("releases")
  project <- tempfile("project")
  cache <- tempfile("cache")
  on.exit(unlink(c(src, project, cache), recursive = TRUE), add = TRUE)
  withr::local_options(traits.use.cache_dir = cache)

  release <- make_release(src, "1", 3)
  local_mocked_bindings(resolve_doi_files = function(doi) release)

  msgs <- testthat::capture_messages(load_database(doi = "10.5281/zenodo.1", path = project))
  expect_false(any(grepl("now holds", msgs)))
  expect_true(file.exists(file.path(project, "MYtraits.rds")))
  expect_false(dir.exists(cache))

  writeLines("x", file.path(project, "notes.csv"))
  suppressMessages(clear_database_cache(path = project, ask = FALSE))
  expect_identical(list.files(project), "notes.csv")
})

test_that("The cache folder follows R_user_dir() unless the option is set", {
  withr::local_options(traits.use.cache_dir = NULL)
  expect_identical(database_cache_dir(), tools::R_user_dir("traits.use", which = "cache"))

  withr::local_options(traits.use.cache_dir = c("a", "b"))
  expect_error(database_cache_dir(), "single folder path")
})
