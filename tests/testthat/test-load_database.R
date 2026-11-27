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
  local_test_cache()
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
  local_test_cache()
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

  # A corrupted cached file is replaced, even with update = FALSE: from the
  # copy in `path` if that is sound...
  writeLines("not an rds", file.path(database_cache_dir(), "MYtraits.rds"))
  expect_equal(suppressMessages(load_database(doi = "10.5281/zenodo.1", path = path_cache, update = FALSE)), v1)
  expect_identical(tools::md5sum(file.path(database_cache_dir(), "MYtraits.rds"))[[1]], releases[[1]]$files$md5)
  # ...otherwise by downloading it again
  writeLines("not an rds", file.path(database_cache_dir(), "MYtraits.rds"))
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
  local_test_cache()
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
  local_test_cache()
  expect_error(load_database(path = path), "Please supply a doi")
  expect_error(load_database(doi = "10.5281/zenodo.10156222", path = c("a", "b")), "single folder path")
  expect_error(load_database(doi = "10.5281/zenodo.10156222", path = ""), "single folder path")
})

test_that("A doi that doesn't resolve gives a clear error", {
  local_test_cache()
  # Asks doi.org
  skip_on_cran()
  skip_if_offline()
  expect_error(load_database(doi = "10.1000/notarealdoi123", path = path), "Could not resolve doi")
})

test_that("A record without a relational .rds gives a clear error", {
  local_test_cache()
  skip_on_cran()
  skip_if_offline()
  # AusTraits v0.1.0 has no .rds file
  expect_error(load_database(doi = "10.5281/zenodo.3568418", path = path), "No .rds file found")
})

test_that("A stamped flattened file keeps its class and stamp (#47)", {
  local_test_cache()
  src <- tempfile("flatsrc"); path_flat <- tempfile("flat")
  on.exit(unlink(c(src, path_flat), recursive = TRUE), add = TRUE)
  dir.create(src)
  flat <- austraits_lite %>% extract_dataset("Falster_2003") %>% flatten_database()
  file <- file.path(src, "db-flattened.rds")
  saveRDS(flat, file)
  local_mocked_bindings(
    resolve_doi_files = function(doi) list(doi = doi, source = "zenodo", version = "1",
      files = data.frame(key = "db-flattened.rds", url = file_url(file), md5 = unname(tools::md5sum(file))))
  )
  loaded <- suppressMessages(load_database(doi = "10.5281/zenodo.9", path = path_flat, flattened = TRUE))
  expect_s3_class(loaded, "traits.build_flat")
  expect_identical(attr(loaded, "traits.build_stamp"), attr(flat, "traits.build_stamp"))
})

test_that("A record whose only .rds is flattened is not downloaded", {
  local_test_cache()
  path_flat <- tempfile("flat")
  on.exit(unlink(path_flat, recursive = TRUE), add = TRUE)
  local_mocked_bindings(
    resolve_doi_files = function(doi) list(doi = doi, source = "zenodo", version = "1",
      files = data.frame(key = "db-flattened.rds", url = "file:///nonexistent/db-flattened.rds", md5 = NA))
  )
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.9", path = path_flat)),
               "Only flattened .rds files found")
})

test_that("An observed-means .rds beside the database is not taken for it (AusTraits 8.0.0)", {
  local_test_cache()
  src <- tempfile("releases"); path_means <- tempfile("means")
  on.exit(unlink(c(src, path_means), recursive = TRUE), add = TRUE)
  release <- make_release(src, "8", 3)
  # AusTraits 8.0.0's files, in the order Zenodo lists them
  keys <- c("austraits-8.0.0-observed-means.rds", "MYtraits.rds", "austraits-8.0.0-flattened.rds",
            "austraits-8.0.0-observed-means.csv.gz", "austraits-8.0.0-observed-means.parquet")
  release$files <- data.frame(key = keys, url = c("file:///nowhere", release$files$url, rep("file:///nowhere", 3)),
                              md5 = c(NA, release$files$md5, rep(NA, 3)))
  local_mocked_bindings(resolve_doi_files = function(doi) release)
  database <- suppressMessages(load_database(doi = "10.5281/zenodo.8", path = path_means))
  expect_equal(nrow(database$traits), 3)
  expect_identical(database_file(release$files, "x")$key, "MYtraits.rds")
  expect_identical(database_file(release$files, "x", flattened = TRUE)$key, "austraits-8.0.0-flattened.rds")
  expect_identical(list_cached_databases(path_means)$file, "MYtraits.rds")

  # With only the means as .rds, the record has no database to load
  release$files <- release$files[release$files$key != "MYtraits.rds", ]
  expect_error(database_file(release$files, "x"), "Only flattened .rds files found")
  release$files <- release$files[!grepl("flattened", release$files$key), ]
  expect_error(database_file(release$files, "x"), "No .rds file found")
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

  expect_message(load_database(doi = "10.5281/zenodo.4"), "now holds 2 database.*Also there: MYtraits.rds")
  cached <- list_cached_databases()
  expect_named(cached, c("file", "size_mb", "last_used"))
  expect_setequal(cached$file, c("MYtraits.rds", "OTHERtraits.rds"))

  # Deleting one release, then the rest
  expect_error(clear_database_cache("nothere.rds", ask = FALSE), "Not a database")
  expect_error(clear_database_cache("MYtraits.rds", older_than = 1), "not both")
  local_mocked_bindings(ask_yes_no = function(msg) FALSE)
  expect_message(clear_database_cache("MYtraits.rds", ask = TRUE), "Nothing deleted")
  expect_length(list_cached_databases()$file, 2)
  expect_message(deleted <- clear_database_cache(c("MYtraits.rds", "MYtraits.rds"), ask = FALSE),
                 "Deleted 1 database")
  # The record naming only that database goes with it
  expect_setequal(basename(deleted), c("MYtraits.rds", "10.5281_zenodo.1.json"))
  expect_identical(list_cached_databases()$file, "OTHERtraits.rds")

  expect_message(clear_database_cache(ask = FALSE), "Deleted")
  # A folder chosen with the option (it could be tempdir()) is never removed
  expect_true(dir.exists(cache))
  expect_length(list.files(cache), 0)
  expect_identical(nrow(list_cached_databases()), 0L)
  expect_message(clear_database_cache(ask = FALSE), "No databases to delete")
})

test_that("The default cache folder is removed once cleared", {
  src <- tempfile("releases")
  user_cache <- tempfile("user_cache")
  on.exit(unlink(c(src, user_cache), recursive = TRUE), add = TRUE)
  withr::local_options(traits.use.cache_dir = NULL)
  withr::local_envvar(R_USER_CACHE_DIR = user_cache)
  expect_identical(database_cache_dir(), tools::R_user_dir("traits.use", which = "cache"))
  expect_true(startsWith(database_cache_dir(), user_cache))

  release <- make_release(src, "1", 3)
  local_mocked_bindings(resolve_doi_files = function(doi) release)
  suppressMessages(load_database(doi = "10.5281/zenodo.1"))
  expect_true(dir.exists(database_cache_dir()))
  suppressMessages(clear_database_cache(ask = FALSE))
  expect_false(dir.exists(database_cache_dir()))
  expect_message(clear_database_cache(ask = FALSE), "does not exist")
})

test_that("Only the databases load_database() can download count, not other files a record lists", {
  local_test_cache()
  path <- tempfile("project")
  dir.create(path)
  on.exit(unlink(path, recursive = TRUE), add = TRUE)

  # A record listing the relational and flattened .rds (both downloadable
  # with load_database()), an extra .rds it never downloads, and a .zip
  record <- list(doi = "10.5281/zenodo.7", source = "zenodo", version = "7",
                 files = data.frame(key = c("db-7.rds", "db-7-flattened.rds", "db-7-v2-flattened.rds", "db-7.zip"),
                                    url = "file:///nowhere", md5 = NA))
  jsonlite::write_json(record, file.path(path, "10.5281_zenodo.7.json"))
  # All present; with two flattened files, neither is the one
  # load_database() would pick
  for (f in c("db-7.rds", "db-7-flattened.rds", "db-7-v2-flattened.rds", "db-7.zip")) saveRDS(1, file.path(path, f))
  # Files named like a record that load_database() did not write
  writeLines("[1, 2]", file.path(path, "10.1000_array.json"))
  writeLines("not json", file.path(path, "10.1000_broken.json"))
  # A record load_database() refused (no .rds), left from an earlier attempt
  jsonlite::write_json(list(doi = "10.5281/zenodo.8", source = "zenodo", version = "8",
                            files = data.frame(key = "data.zip", url = "file:///nowhere", md5 = NA)),
                       file.path(path, "10.5281_zenodo.8.json"))

  expect_identical(list_cached_databases(path)$file, "db-7.rds")
  suppressMessages(clear_database_cache(path = path, ask = FALSE))
  expect_setequal(list.files(path), c("db-7-flattened.rds", "db-7-v2-flattened.rds", "db-7.zip",
                                      "10.1000_array.json", "10.1000_broken.json"))

  # With one flattened .rds, it is claimed too
  record$files <- record$files[record$files$key != "db-7-v2-flattened.rds", ]
  jsonlite::write_json(record, file.path(path, "10.5281_zenodo.7.json"))
  saveRDS(1, file.path(path, "db-7.rds"))
  expect_setequal(list_cached_databases(path)$file, c("db-7.rds", "db-7-flattened.rds"))
  suppressMessages(clear_database_cache(path = path, ask = FALSE))
  expect_setequal(list.files(path), c("db-7-v2-flattened.rds", "db-7.zip", "10.1000_array.json", "10.1000_broken.json"))
})

test_that("flattened = TRUE loads the flattened table from the same record", {
  src <- tempfile("releases")
  cache <- tempfile("cache")
  on.exit(unlink(c(src, cache), recursive = TRUE), add = TRUE)
  withr::local_options(traits.use.cache_dir = cache)

  release <- make_release(src, "7", 3)
  flat_file <- file.path(src, "7", "MYtraits-flattened.rds")
  flat <- data.frame(dataset_id = "A_2001", taxon_name = c("Acacia a", "Acacia b"),
                     trait_name = "leaf_area", value = c("1", "2"))
  saveRDS(flat, flat_file)
  release$files <- rbind(release$files,
    data.frame(key = c("MYtraits-flattened.rds", "MYtraits-flattened.parquet"),
               url = c(file_url(flat_file), "file:///nowhere.parquet"),
               md5 = c(unname(tools::md5sum(flat_file)), NA)))
  local_mocked_bindings(resolve_doi_files = function(doi) release)

  out <- suppressMessages(load_database(doi = "10.5281/zenodo.7", flattened = TRUE))
  expect_s3_class(out, "tbl_df")
  expect_equal(as.data.frame(out), flat)
  # The relational database still loads from the same record
  db <- suppressMessages(load_database(doi = "10.5281/zenodo.7", update = FALSE))
  expect_s3_class(db, "traits.build")
  expect_setequal(list_cached_databases()$file, c("MYtraits.rds", "MYtraits-flattened.rds"))

  # A release without a flattened file
  release$files <- release$files[1, ]
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.7", flattened = TRUE, update = TRUE)),
               "No flattened .rds file found")

  # Two flattened files; case doesn't matter, and "flattened" must end the name
  release$files <- rbind(release$files,
    data.frame(key = c("A-Flattened.RDS", "B-FLATTENED.rds", "notflattened.rds"), url = "file:///nowhere", md5 = NA))
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.7", flattened = TRUE, update = TRUE)),
               "More than one flattened .rds file found.*A-Flattened.RDS, B-FLATTENED.rds")
  release$files <- release$files[1, ]

  # A table without the columns of a traits table
  odd <- file.path(src, "7", "ODD-flattened.rds")
  saveRDS(data.frame(dataset_id = "A_2001", value = "1"), odd)
  release$files <- rbind(release$files,
    data.frame(key = "ODD-flattened.rds", url = file_url(odd), md5 = unname(tools::md5sum(odd))))
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.7", flattened = TRUE, update = TRUE)),
               "not a flattened traits.build database")
  release$files <- release$files[1, ]

  expect_error(load_database(doi = "10.5281/zenodo.7", flattened = "TRUE"), "TRUE or FALSE")
  expect_error(load_database(doi = "10.5281/zenodo.7", flattened = NA), "TRUE or FALSE")

  # A flattened file that is not a table
  bad <- file.path(src, "7", "BAD-flattened.rds")
  saveRDS(list(a = 1), bad)
  release$files <- rbind(release$files,
    data.frame(key = "BAD-flattened.rds", url = file_url(bad), md5 = unname(tools::md5sum(bad))))
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.7", flattened = TRUE, update = TRUE)),
               "not a flattened traits.build database")
})

test_that("A path keeps a copy with a project, and clearing it leaves other files", {
  src <- tempfile("releases")
  project <- tempfile("project")
  cache <- tempfile("cache")
  on.exit(unlink(c(src, project, cache), recursive = TRUE), add = TRUE)
  withr::local_options(traits.use.cache_dir = cache)

  release <- make_release(src, "1", 3)
  local_mocked_bindings(resolve_doi_files = function(doi) release)

  # Downloaded to the cache, with a copy (and its record) in the project
  expect_message(load_database(doi = "10.5281/zenodo.1", path = project), "now holds 1 database")
  expect_true(file.exists(file.path(cache, "MYtraits.rds")))
  expect_true(file.exists(file.path(project, "MYtraits.rds")))
  expect_true(file.exists(file.path(project, "10.5281_zenodo.1.json")))
  expect_identical(tools::md5sum(file.path(project, "MYtraits.rds"))[[1]], release$files$md5)

  # Files load_database() did not write are never deleted, nor the folder
  writeLines("x", file.path(project, "notes.csv"))
  writeLines("{}", file.path(project, "config.json"))
  saveRDS(1, file.path(project, "fitted_model.rds"))
  expect_identical(list_cached_databases(project)$file, "MYtraits.rds")
  suppressMessages(clear_database_cache(path = project, ask = FALSE))
  expect_setequal(list.files(project), c("notes.csv", "config.json", "fitted_model.rds"))

  for (f in list.files(project, full.names = TRUE)) unlink(f)
  suppressMessages(load_database(doi = "10.5281/zenodo.1", path = project))
  suppressMessages(clear_database_cache(path = project, ask = FALSE))
  expect_true(dir.exists(project))
})

test_that("A project folder loads on its own offline, and seeds the cache once the repository confirms it", {
  src <- tempfile("releases")
  project <- tempfile("project")
  on.exit(unlink(c(src, project), recursive = TRUE), add = TRUE)
  cache <- local_test_cache()

  releases <- list("10.5281/zenodo.1" = make_release(src, "1", 3),
                   "10.5281/zenodo.2" = make_release(src, "2", 5))
  real_download <- download_database
  n_downloads <- 0
  local_mocked_bindings(
    resolve_doi_files = function(doi) releases[[doi]],
    download_database = function(...) {
      n_downloads <<- n_downloads + 1
      real_download(...)
    }
  )
  v1 <- suppressMessages(load_database(doi = "10.5281/zenodo.1", path = project))
  expect_identical(n_downloads, 1)

  # A project folder as traits.use 1.0 left it: the database and its record
  # there, nothing in the cache. Offline, it loads from the folder alone: the
  # cache takes nothing the repository has not confirmed.
  suppressMessages(clear_database_cache(ask = FALSE))
  expect_false(file.exists(file.path(cache, "MYtraits.rds")))
  local_mocked_bindings(resolve_doi_files = function(doi) stop("no internet"))
  expect_message(v1_again <- load_database(doi = "10.5281/zenodo.1", path = project),
                 "Could not update the record.*using the copy saved in .*project")
  expect_equal(v1_again, v1)
  expect_length(list.files(cache), 0)
  # update = FALSE does not ask the repository at all
  local_mocked_bindings(resolve_doi_files = function(doi) stop("the repository was asked"))
  msgs <- testthat::capture_messages(v1_again <- load_database(doi = "10.5281/zenodo.1", path = project, update = FALSE))
  expect_equal(v1_again, v1)
  expect_false(any(grepl("Could not update", msgs)))
  expect_length(list.files(cache), 0)

  # Online, the repository's record confirms the folder's copy, which then
  # fills the cache without a download
  local_mocked_bindings(resolve_doi_files = function(doi) releases[[doi]])
  expect_equal(suppressMessages(load_database(doi = "10.5281/zenodo.1", path = project)), v1)
  expect_identical(n_downloads, 1)
  expect_true(file.exists(file.path(cache, "MYtraits.rds")))
  expect_true(file.exists(file.path(cache, "10.5281_zenodo.1.json")))

  # The project's copy of another release under the same name is replaced
  suppressMessages(load_database(doi = "10.5281/zenodo.2", path = project))
  expect_identical(tools::md5sum(file.path(project, "MYtraits.rds"))[[1]], releases[["10.5281/zenodo.2"]]$files$md5)
  expect_message(load_database(doi = "10.5281/zenodo.1", path = project), "Saved a copy")
  expect_identical(tools::md5sum(file.path(project, "MYtraits.rds"))[[1]], releases[["10.5281/zenodo.1"]]$files$md5)
  # ...and an up-to-date copy is left alone
  expect_false(any(grepl("Saved a copy", testthat::capture_messages(load_database(doi = "10.5281/zenodo.1", path = project)))))

  # The cache folder given as `path` is just the cache
  expect_false(any(grepl("Saved a copy", testthat::capture_messages(load_database(doi = "10.5281/zenodo.1", path = cache)))))
})

test_that("A project folder's own record and file never reach the cache or another project", {
  src <- tempfile("releases")
  project <- tempfile("project")
  on.exit(unlink(c(src, project), recursive = TRUE), add = TRUE)
  cache <- local_test_cache()
  release <- make_release(src, "1", 3)
  n_fetches <- 0
  local_mocked_bindings(resolve_doi_files = function(doi) {
    n_fetches <<- n_fetches + 1
    release
  })

  # A folder holding a file that is not the published one, under the
  # release's name, with a record giving that file's checksum. The record is
  # new (as after a clone or unzip), so its age says nothing.
  dir.create(project)
  altered <- file.path(project, "MYtraits.rds")
  saveRDS(list(traits = data.frame(value = 1:99), taxa = data.frame(), methods = data.frame()), altered)
  own_record <- release
  own_record$files$md5 <- unname(tools::md5sum(altered))
  jsonlite::write_json(own_record, file.path(project, "10.5281_zenodo.1.json"))

  # Asked not to contact the repository, the folder is used as it is, alone
  db <- suppressMessages(load_database(doi = "10.5281/zenodo.1", path = project, update = FALSE))
  expect_equal(nrow(db$traits), 99)
  expect_identical(n_fetches, 0)
  expect_length(list.files(cache), 0)

  # Otherwise the repository is asked, and its release is what loads, here
  # and in any other project
  db <- suppressMessages(load_database(doi = "10.5281/zenodo.1", path = project))
  expect_identical(n_fetches, 1)
  expect_equal(nrow(db$traits), 3)
  expect_identical(tools::md5sum(file.path(cache, "MYtraits.rds"))[[1]], release$files$md5)
  expect_equal(nrow(suppressMessages(load_database(doi = "10.5281/zenodo.1"))$traits), 3)

  # Without a checksum, a file in the folder cannot be confirmed, so the
  # cache gets the repository's
  suppressMessages(clear_database_cache(ask = FALSE))
  saveRDS(list(traits = data.frame(value = 1:99), taxa = data.frame(), methods = data.frame()), altered)
  release$files$md5 <- NA
  db <- suppressMessages(load_database(doi = "10.5281/zenodo.1", update = TRUE, path = project))
  expect_equal(nrow(readRDS(file.path(cache, "MYtraits.rds"))$traits), 3)
  expect_equal(nrow(readRDS(altered)$traits), 3)
})

test_that("The saved record is fetched afresh once it is old, so a concept doi finds a new release", {
  src <- tempfile("releases")
  on.exit(unlink(src, recursive = TRUE), add = TRUE)
  cache <- local_test_cache()

  # A concept doi resolves to the latest release: release 1, then 2
  latest <- make_release(src, "1", 3)
  n_fetches <- 0
  local_mocked_bindings(resolve_doi_files = function(doi) {
    n_fetches <<- n_fetches + 1
    latest
  })
  concept <- "10.5281/zenodo.100"
  json <- file.path(cache, "10.5281_zenodo.100.json")

  expect_equal(nrow(suppressMessages(load_database(doi = concept))$traits), 3)
  expect_identical(n_fetches, 1)

  # A new release, not looked for until the saved record is 60 days old
  latest <- make_release(src, "2", 5)
  expect_equal(nrow(suppressMessages(load_database(doi = concept))$traits), 3)
  expect_identical(n_fetches, 1)
  Sys.setFileTime(json, Sys.time() - 59 * 86400)
  suppressMessages(load_database(doi = concept))
  expect_identical(n_fetches, 1)
  Sys.setFileTime(json, Sys.time() - 61 * 86400)
  expect_message(db <- load_database(doi = concept), "is version 2")
  expect_equal(nrow(db$traits), 5)
  expect_identical(n_fetches, 2)

  # update = FALSE never fetches a saved record, update = TRUE always does
  Sys.setFileTime(json, Sys.time() - 400 * 86400)
  suppressMessages(load_database(doi = concept, update = FALSE))
  expect_identical(n_fetches, 2)
  suppressMessages(load_database(doi = concept, update = TRUE))
  expect_identical(n_fetches, 3)
  suppressMessages(load_database(doi = concept, update = TRUE))
  expect_identical(n_fetches, 4)

  # The number of days is an option
  withr::local_options(traits.use.update_after_days = 0)
  suppressMessages(load_database(doi = concept))
  expect_identical(n_fetches, 5)
  withr::local_options(traits.use.update_after_days = "a")
  expect_error(load_database(doi = concept), "must be a number of days")

  expect_error(load_database(doi = concept, update = NA), "TRUE, FALSE or NULL")
  expect_error(load_database(doi = concept, update = "yes"), "TRUE, FALSE or NULL")
})

test_that("A cache that cannot be written to leaves only the path", {
  src <- tempfile("releases")
  project <- tempfile("project")
  on.exit(unlink(c(src, project), recursive = TRUE), add = TRUE)
  cache <- local_test_cache()
  release <- make_release(src, "1", 3)
  real_writable <- writable_folder
  local_mocked_bindings(
    resolve_doi_files = function(doi) release,
    writable_folder = function(path) !identical(path, cache) && real_writable(path)
  )

  expect_message(db <- load_database(doi = "10.5281/zenodo.1", path = project), "Cannot write to the cache folder")
  expect_equal(nrow(db$traits), 3)
  expect_true(file.exists(file.path(project, "MYtraits.rds")))
  expect_false(file.exists(file.path(cache, "MYtraits.rds")))
  expect_error(load_database(doi = "10.5281/zenodo.1"), "Cannot write to the cache folder")

  # A cache that already holds the release (e.g. one a group shares, read
  # only) is read as it is, without asking the repository, and can fill a `path`
  dir.create(cache)
  file.copy(file.path(project, c("MYtraits.rds", "10.5281_zenodo.1.json")), cache)
  local_mocked_bindings(resolve_doi_files = function(doi) stop("the repository was asked"))
  msgs <- testthat::capture_messages(db <- load_database(doi = "10.5281/zenodo.1"))
  expect_equal(nrow(db$traits), 3)
  expect_false(any(grepl("Cannot write|Could not update", msgs)))
  other <- tempfile("other")
  on.exit(unlink(other, recursive = TRUE), add = TRUE)
  expect_message(load_database(doi = "10.5281/zenodo.1", path = other), "Saved a copy")
  # but not a release it does not hold
  expect_error(load_database(doi = "10.5281/zenodo.2"), "Cannot write to the cache folder")
})

test_that("A project folder and a cache that name different releases ask the repository", {
  src <- tempfile("releases")
  shared <- tempfile("shared")
  on.exit(unlink(c(src, shared), recursive = TRUE), add = TRUE)
  concept <- "10.5281/zenodo.100"
  latest <- make_release(src, "1", 3)
  n_fetches <- 0
  local_mocked_bindings(resolve_doi_files = function(doi) {
    n_fetches <<- n_fetches + 1
    latest
  })

  # This computer fetched the concept doi when release 1 was the latest
  cache_b <- local_test_cache()
  suppressMessages(load_database(doi = concept))
  # A colleague's computer, later, saved release 2 in the shared folder
  latest <- make_release(src, "2", 5)
  withr::with_options(list(traits.use.cache_dir = tempfile("cache_a")),
                      suppressMessages(load_database(doi = concept, path = shared)))
  expect_equal(nrow(readRDS(file.path(shared, "MYtraits.rds"))$traits), 5)

  # Here the saved record is new, but disagrees with the folder's: the
  # repository is asked, and the folder keeps release 2
  n_fetches <- 0
  db <- suppressMessages(load_database(doi = concept, path = shared))
  expect_identical(n_fetches, 1)
  expect_equal(nrow(db$traits), 5)
  expect_equal(nrow(readRDS(file.path(shared, "MYtraits.rds"))$traits), 5)
  # and once they agree, it is not asked again
  suppressMessages(load_database(doi = concept, path = shared))
  expect_identical(n_fetches, 1)
})

test_that("Loading from the cache marks a database used, and older_than clears unused ones", {
  src <- tempfile("releases")
  cache <- tempfile("cache")
  on.exit(unlink(c(src, cache), recursive = TRUE), add = TRUE)
  withr::local_options(traits.use.cache_dir = cache)

  releases <- list("10.5281/zenodo.1" = make_release(src, "1", 3),
                   "10.5281/zenodo.4" = make_release(src, "4", 4))
  releases[["10.5281/zenodo.4"]]$files$key <- "OTHERtraits.rds"
  local_mocked_bindings(resolve_doi_files = function(doi) releases[[doi]])
  suppressMessages(load_database(doi = "10.5281/zenodo.1"))
  suppressMessages(load_database(doi = "10.5281/zenodo.4"))

  long_ago <- Sys.time() - 400 * 86400
  Sys.setFileTime(file.path(cache, c("MYtraits.rds", "OTHERtraits.rds")), long_ago)
  # Release 1 is used again; release 4 is not
  suppressMessages(load_database(doi = "10.5281/zenodo.1", update = FALSE))
  cached <- list_cached_databases()
  expect_gt(cached$last_used[cached$file == "MYtraits.rds"], Sys.time() - 3600)

  expect_message(clear_database_cache(older_than = 365, ask = FALSE), "Deleted 1 database.*OTHERtraits.rds")
  expect_identical(list_cached_databases()$file, "MYtraits.rds")
  expect_message(clear_database_cache(older_than = 365, ask = FALSE), "No databases to delete")
  expect_error(clear_database_cache(older_than = "a"), "number of days")
})

test_that("Offline, a saved record and database still load", {
  src <- tempfile("releases")
  cache <- tempfile("cache")
  on.exit(unlink(c(src, cache), recursive = TRUE), add = TRUE)
  withr::local_options(traits.use.cache_dir = cache)

  release <- make_release(src, "1", 3)
  local_mocked_bindings(resolve_doi_files = function(doi) release)
  v1 <- suppressMessages(load_database(doi = "10.5281/zenodo.1"))

  local_mocked_bindings(resolve_doi_files = function(doi) stop("no internet"))
  expect_message(v1_offline <- load_database(doi = "10.5281/zenodo.1", update = TRUE), "Could not update the record.*no internet")
  expect_equal(v1_offline, v1)
  # With nothing saved, the error is not hidden
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.2")), "no internet")

  # doi.org unreachable is a fallback too; a record since restricted is not
  local_mocked_bindings(resolve_doi_files = function(doi) resolve_doi(doi),
                        resolve_doi = function(doi) rlang::abort("Could not resolve doi 'x'", class = "traits_use_unreachable"))
  expect_message(load_database(doi = "10.5281/zenodo.1", update = TRUE), "Could not update the record")
  local_mocked_bindings(resolve_doi_files = function(doi) rlang::abort("The files for doi 'x' are restricted on Zenodo"))
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.1", update = TRUE)), "restricted")
})

test_that("A stale cached file that cannot be removed stops the load", {
  local_test_cache()
  src <- tempfile("releases")
  path <- tempfile("project")
  on.exit(unlink(c(src, path), recursive = TRUE), add = TRUE)
  release <- make_release(src, "1", 3)
  local_mocked_bindings(resolve_doi_files = function(doi) release,
                        remove_file = function(file) FALSE)
  # in the cache
  dir.create(database_cache_dir())
  writeLines("an older release", file.path(database_cache_dir(), "MYtraits.rds"))
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.1")), "Could not remove")
  # in the folder given as `path`, it only warns: the database loads from the cache
  unlink(file.path(database_cache_dir(), "MYtraits.rds"))
  dir.create(path)
  writeLines("an older release", file.path(path, "MYtraits.rds"))
  expect_warning(db <- suppressMessages(load_database(doi = "10.5281/zenodo.1", path = path)), "Could not replace")
  expect_equal(nrow(db$traits), 3)

  # as does a folder that cannot be written to
  local_mocked_bindings(remove_file = function(file) file.remove(file))
  blocked <- file.path(path, "MYtraits.rds", "not-a-folder")
  expect_warning(db <- suppressMessages(load_database(doi = "10.5281/zenodo.1", path = blocked)), "Could not save a copy")
  expect_equal(nrow(db$traits), 3)
})

test_that("The cache folder follows R_user_dir() unless the option is set", {
  withr::local_options(traits.use.cache_dir = NULL)
  expect_identical(database_cache_dir(), tools::R_user_dir("traits.use", which = "cache"))

  withr::local_options(traits.use.cache_dir = c("a", "b"))
  expect_error(database_cache_dir(), "single folder path")
})

test_that("means = TRUE loads the observed means published with a release", {
  local_test_cache()
  skip_if_not_installed("readr")
  src <- tempfile("meanssrc"); path_means <- tempfile("means")
  on.exit(unlink(c(src, path_means), recursive = TRUE), add = TRUE)
  dir.create(src)

  # A release as AusTraits publishes it: the database, and its means as csv.gz
  # and parquet, with a dictionary
  database <- extract_dataset(austraits_lite, c("Falster_2003", "Falster_2005_1"))
  published <- summarise_trait_means(database, by = "life_stage")
  saveRDS(database, file.path(src, "db-1.0.0.rds"))
  readr::write_csv(published, file.path(src, "db-1.0.0-observed-means.csv.gz"), na = "")
  writeLines("not read", file.path(src, "db-1.0.0-observed-means.parquet"))
  readr::write_csv(trait_means_dictionary(), file.path(src, "db-1.0.0-observed-means-dictionary.csv"))
  keys <- dir(src)
  files <- data.frame(key = keys, url = vapply(file.path(src, keys), file_url, ""),
                      md5 = unname(tools::md5sum(file.path(src, keys))))
  local_mocked_bindings(
    resolve_doi_files = function(doi) list(doi = doi, source = "zenodo", version = "1.0.0", files = files)
  )

  means <- suppressMessages(load_database(doi = "10.5281/zenodo.9", path = path_means, means = TRUE))
  # the same table, with the same column types, the `by` column as text
  expect_equal(as.data.frame(means), as.data.frame(published))
  expect_type(means$n_records, "integer")
  expect_type(means$value, "double")
  expect_type(means$life_stage, "character")

  # only the means were downloaded, then the database beside them on request
  expect_equal(dir(path_means, pattern = "csv|rds|parquet"), "db-1.0.0-observed-means.csv.gz")
  database_again <- suppressMessages(load_database(doi = "10.5281/zenodo.9", path = path_means, update = FALSE))
  expect_equal(nrow(database_again$traits), nrow(database$traits))
  expect_setequal(list_cached_databases(path_means)$file, c("db-1.0.0.rds", "db-1.0.0-observed-means.csv.gz"))

  # the extract_*() functions take the means table, as a flat table
  acacia <- extract_taxa(means, genus = "Acacia")
  expect_gt(nrow(acacia), 0)
  expect_true(all(acacia$genus == "Acacia"))
  expect_equal(unique(extract_trait(means, "leaf_area")$trait_name), "leaf_area")

  expect_error(load_database(doi = "10.5281/zenodo.9", path = path_means, means = TRUE, flattened = TRUE),
               "Choose one")
  expect_error(load_database(doi = "10.5281/zenodo.9", path = path_means, means = NA), "TRUE or FALSE")
})

test_that("means = TRUE reads the observed-means .rds when a release has one (AusTraits 8.0.0)", {
  local_test_cache()
  skip_if_not_installed("readr")
  src <- tempfile("meanssrc"); path_means <- tempfile("means")
  on.exit(unlink(c(src, path_means), recursive = TRUE), add = TRUE)
  dir.create(src)

  database <- extract_dataset(austraits_lite, "Falster_2003")
  published <- summarise_trait_means(database)
  saveRDS(database, file.path(src, "db-8.0.0.rds"))
  saveRDS(published, file.path(src, "db-8.0.0-observed-means.rds"))
  # rounded, as a csv round trip does, so a test that read it would not be identical
  readr::write_csv(dplyr::mutate(published, value = signif(value, 3)), file.path(src, "db-8.0.0-observed-means.csv.gz"), na = "")
  keys <- dir(src)
  files <- data.frame(key = keys, url = vapply(file.path(src, keys), file_url, ""),
                      md5 = unname(tools::md5sum(file.path(src, keys))))
  local_mocked_bindings(
    resolve_doi_files = function(doi) list(doi = doi, source = "zenodo", version = "8.0.0", files = files)
  )

  means <- suppressMessages(load_database(doi = "10.5281/zenodo.9", path = path_means, means = TRUE))
  expect_identical(means, tibble::as_tibble(published))
  expect_equal(dir(path_means, pattern = "csv|rds|parquet"), "db-8.0.0-observed-means.rds")
  expect_setequal(list_cached_databases(path_means)$file, "db-8.0.0-observed-means.rds")

  # a .rds that is not a table of means is refused
  saveRDS(list(a = 1), file.path(src, "db-8.0.0-observed-means.rds"))
  files$md5 <- unname(tools::md5sum(file.path(src, keys)))
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.9", path = tempfile("means2"), means = TRUE, update = TRUE)),
               "not a table of observed means")
})

test_that("a release without observed means says so", {
  local_test_cache()
  path_none <- tempfile("none")
  on.exit(unlink(path_none, recursive = TRUE), add = TRUE)
  local_mocked_bindings(
    resolve_doi_files = function(doi) list(doi = doi, source = "zenodo", version = "1",
      files = data.frame(key = "db-1.rds", url = "file:///nonexistent/db-1.rds", md5 = NA))
  )
  expect_error(suppressMessages(load_database(doi = "10.5281/zenodo.9", path = path_none, means = TRUE)),
               "No observed means")
})
