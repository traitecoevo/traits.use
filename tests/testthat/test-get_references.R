db <- austraits_5.0.0_lite

# The fixture in the shape of a database built with traits.build 2.3, where a
# dataset's own reference is keyed by its `dataset_id`, every observation
# names its reference in `source_id`, and the methods table's reference
# columns are renamed
as_traits_build_2.3 <- function(database) {
  database$methods <- database$methods %>%
    dplyr::rename(
      dataset_id_citation = "source_primary_citation",
      secondary_id = "source_secondary_key",
      secondary_citation = "source_secondary_citation"
    ) %>%
    dplyr::select(-c("source_primary_key", "source_original_dataset_key",
                     "source_original_dataset_citation"))
  database$traits$source_id <- dplyr::coalesce(database$traits$source_id, database$traits$dataset_id)
  database
}

test_that("lists every reference the database cites, sorted, with its type", {
  expect_no_warning(refs <- get_references(db))
  expect_s3_class(refs, "tbl_df")
  expect_named(refs, c("key", "citation", "type"))

  # A release cites every reference in its `sources`
  expect_identical(refs$key, sort(unname(names(db$sources)), method = "radix"))
  expect_false(anyNA(refs$citation))
  expect_equal(
    as.list(table(refs$type)),
    list(dataset = 23L, secondary = 7L, source = 30L)
  )

  # Westoby_2014's own reference is Gleason_2012 (`source_primary_key`)
  expect_identical(refs$type[refs$key == "Gleason_2012"], "dataset")
  expect_false("Westoby_2014" %in% refs$key)
  expect_identical(refs$type[refs$key == "Prior_2004"], "secondary")
  # A study in `source_original_dataset_key`
  expect_identical(refs$type[refs$key == "Brodribb_2009"], "source")
  # In a release built before traits.build 2.3, a `source_id` that is not a
  # key is not a citation (it was free text)
  expect_false("Thiele_2017_1" %in% refs$key)
  expect_contains(db$traits$source_id, "Thiele_2017_1")
})

test_that("citations read as in join_sources() and the methods table", {
  refs <- get_references(db)
  i <- which(names(db$sources) == "Falster_2003")
  expect_identical(
    refs$citation[refs$key == "Falster_2003"],
    format_citation(db$sources[[i]])
  )

  # traits.build writes the methods table's citations with curly quotes
  methods <- dplyr::distinct(db$methods, source_primary_key, source_primary_citation)
  expected <- gsub("[\u201c\u201d]", "\"", methods$source_primary_citation)
  expect_identical(refs$citation[match(methods$source_primary_key, refs$key)], expected)

  # ... in any time zone. The references' dates are stored as midnight in
  # Sydney, which is the day before in UTC, so 1 January 2003 was formatted
  # as 2002 there
  for (tz in c("UTC", "America/Los_Angeles", "Pacific/Auckland")) {
    withr::with_timezone(tz, refs <- get_references(db))
    expect_identical(refs$citation[match(methods$source_primary_key, refs$key)], expected)
    expect_match(refs$citation[refs$key == "Falster_2003"], "(2003)", fixed = TRUE)
  }
})

test_that("lists the references in the `sources` of an extract_*() result", {
  extracted <- list(
    extract_dataset(db, "Choat_2012"),
    extract_dataset(db, c("Westoby_2014", "Prior_2003")),
    extract_taxa(db, genus = "Acacia"),
    extract_trait(db, "leaf_mass_per_area")
  )
  for (x in extracted) {
    expect_no_warning(refs <- get_references(x))
    expect_identical(refs$key, sort(unname(names(x$sources)), method = "radix"))
  }
})

test_that("a reference cited only by an observation's `source_id` is listed and extracted", {
  extra <- RefManageR::BibEntry(
    bibtype = "Article", key = "Extra_2000", title = "An extra study",
    author = "A. Person", journal = "Journal", year = 2000
  )
  x <- db
  x$sources <- c(x$sources, extra)
  x$traits$source_id[x$traits$dataset_id == "Choat_2012"][1] <- "Extra_2000"

  refs <- get_references(x)
  expect_identical(refs$type[refs$key == "Extra_2000"], "source")

  extracted <- extract_dataset(x, "Choat_2012")
  expect_contains(names(extracted$sources), "Extra_2000")
  expect_contains(get_references(extracted)$key, "Extra_2000")

  # ... also from `excluded_data` (the fixture has none)
  x <- db
  x$sources <- c(x$sources, extra)
  excluded <- x$traits[x$traits$dataset_id == "Choat_2012", ][1, ]
  excluded$source_id <- "Extra_2000"
  x$excluded_data <- dplyr::bind_rows(x$excluded_data, excluded)
  refs <- get_references(x)
  expect_identical(refs$type[refs$key == "Extra_2000"], "source")
})

test_that("each dataset of a combined database is read by its own build's rules", {
  # Westoby_2014 as built by traits.build 2.3, citing a study with no reference
  newer <- as_traits_build_2.3(extract_dataset(db, "Westoby_2014"))
  newer$traits$source_id[1] <- "Missing_2099"
  older <- extract_dataset(db, "Choat_2012")
  expect_warning(
    refs <- get_references(bind_databases(older, newer)),
    "Missing_2099"
  )
  expect_contains(refs$key[is.na(refs$citation)], c("Missing_2099", "Westoby_2014"))
  # Choat_2012's free-text `source_id` values are still not read as keys
  free_text <- setdiff(older$traits$source_id, c(NA, names(older$sources)))
  expect_gt(length(free_text), 0)
  expect_false(any(free_text %in% refs$key))
  expect_identical(
    refs$key[refs$key %in% names(older$sources)],
    sort(unname(names(older$sources)), method = "radix")
  )
})

test_that("an extraction citing no reference in `sources` lists its keys", {
  # extract_data() gives an empty list for `sources` here
  x <- as_traits_build_2.3(db)
  x$sources <- x$sources[which(names(x$sources) != "Falster_2003")]
  extracted <- suppressMessages(extract_dataset(x, "Falster_2003"))
  expect_length(extracted$sources, 0)
  expect_warning(refs <- get_references(extracted), "Falster_2003")
  expect_identical(refs$key, "Falster_2003")
  expect_true(is.na(refs$citation))
})

test_that("keys with no reference in `sources` are listed with a warning", {
  db_2.3 <- as_traits_build_2.3(db)
  expect_warning(refs <- get_references(db_2.3), "no reference in `sources`")

  # Westoby_2014's reference is under another key, and some studies named in
  # `source_id` (e.g. Brodribb_unpub) have no reference
  missing <- refs$key[is.na(refs$citation)]
  expect_contains(missing, c("Westoby_2014", "Brodribb_unpub"))
  expect_identical(refs$type[refs$key == "Westoby_2014"], "dataset")
  expect_false(any(missing %in% names(db$sources)))
  expect_false(anyNA(refs$citation[refs$key %in% names(db$sources)]))

  # From traits.build 2.3 a dataset's reference is keyed by its `dataset_id`
  expect_true(all(unique(db$methods$dataset_id) %in% refs$key))
  expect_identical(unique(refs$type[refs$key %in% db$methods$dataset_id]), "dataset")
})

test_that("`file` writes the references in `sources` as BibTeX", {
  x <- extract_dataset(db, c("Choat_2012", "Prior_2003"))
  file <- withr::local_tempfile(fileext = ".bib")
  refs <- get_references(x, file = file)
  expect_identical(refs, get_references(x))

  bib <- RefManageR::ReadBib(file, check = FALSE)
  expect_identical(unname(names(bib)), refs$key)

  # `.bib` is added to a name without it
  stem <- withr::local_tempfile()
  get_references(x, file = stem)
  expect_true(file.exists(paste0(stem, ".bib")))
  withr::defer(unlink(paste0(stem, ".bib")))

  # Keys with no reference are not written
  file <- withr::local_tempfile(fileext = ".bib")
  refs <- suppressWarnings(get_references(as_traits_build_2.3(x), file = file))
  bib <- RefManageR::ReadBib(file, check = FALSE)
  expect_identical(unname(names(bib)), refs$key[!is.na(refs$citation)])

  # No references gives an empty file
  file <- withr::local_tempfile(fileext = ".bib")
  expect_silent(write_references(NULL, file))
  expect_true(file.exists(file))
  expect_identical(readLines(file), character())

  # ... also from get_references(), without RefManageR's "No results."
  x$sources <- x$sources[1]
  x$traits$source_id <- "Nobody_1900"
  x$methods$source_primary_key <- "Nobody_1900"
  x$methods$source_secondary_key <- NA
  x$methods$source_original_dataset_key <- NA
  file <- withr::local_tempfile(fileext = ".bib")
  expect_no_message(suppressWarnings(get_references(as_traits_build_2.3(x), file = file)))
  expect_identical(readLines(file), character())
})

test_that("fails without a relational database", {
  expect_error(get_references(flatten_database(db)), "flattened")
  expect_error(get_references(list(traits = db$traits)), "sources")
  expect_error(get_references("Falster_2003"), "traits.build database")
})

test_that("`file` must be one path", {
  for (file in list(c("a.bib", "b.bib"), NA_character_, 1, character())) {
    expect_error(get_references(db, file = file), "single file path")
  }
})
