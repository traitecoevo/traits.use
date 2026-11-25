
test_that("functions should work without warnings", {
  expect_silent(join_location_coordinates(austraits_lite))
  expect_silent(join_methods(austraits_lite))
  expect_silent(join_context_properties(austraits_lite))
  expect_silent(join_taxa(austraits_lite))
  expect_silent(join_taxonomic_updates(austraits_lite))
})

test_that("structure doesn't change", {
  expect_type(join_location_coordinates(austraits_lite), "list")
  expect_type(join_methods(austraits_lite), "list")
  expect_type(join_context_properties(austraits_lite), "list")
  expect_type(join_taxa(austraits_lite), "list")
  expect_type(join_taxonomic_updates(austraits_lite), "list")
  expect_no_error(database_with_coordinates <- join_location_coordinates(austraits_lite))
  test_database_structure(database = database_with_coordinates)
  expect_no_error(database_with_methods <- join_methods(austraits_lite))
  test_database_structure(database = database_with_methods)
  expect_no_error(database_with_contexts <- join_context_properties(austraits_lite))
  test_database_structure(database = database_with_contexts)
})

test_that("variables are added", {
  expect_true(ncol(join_location_coordinates(austraits_lite)$traits) > ncol(austraits_lite$traits))
  expect_true(ncol(join_methods(austraits_lite)$traits) > ncol(austraits_lite$traits))
  expect_true(ncol(join_context_properties(austraits_lite)$traits) > ncol(austraits_lite$traits)) #Need an example where I have context information to add
  expect_true(ncol(join_taxa(austraits_lite)$traits) > ncol(austraits_lite$traits))
  expect_true(ncol(join_taxonomic_updates(austraits_lite)$traits) > ncol(austraits_lite$traits))
  
  expect_true(any(names(join_location_coordinates(austraits_lite)$traits) %in% c("latitude (deg)","longitude (deg)")))
  expect_true(any(names(join_taxa(austraits_lite)$traits) %in%c("family", "genus")))
  expect_true(any(names(join_methods(austraits_lite)$traits) %in%c("methods")))
})

test_that("fails appropriately", {
  expect_error(join_context_properties(austraits_lite, format = "bad"))
  expect_error(join_location_coordinates(austraits_lite, format = "bad"))
  expect_error(join_location_properties(austraits_lite, format = "bad"))
  expect_error(join_taxa(austraits_lite, format = "bad"))
  expect_error(join_contributors(austraits_lite, format = "bad"))
  
  })
test_that("`join_sources` adds each observation's references without adding rows", {
  joined <- join_sources(austraits_lite)
  expect_equal(nrow(joined$traits), nrow(austraits_lite$traits))
  expect_true(all(c("dataset_id_type", "dataset_id_citation", "source_id_citation", "secondary_id", "secondary_citation") %in% names(joined$traits)))

  # Read from the methods table's reference columns
  expected <- austraits_lite$methods %>%
    dplyr::distinct(dataset_id, dataset_id_citation)
  got <- joined$traits %>% dplyr::distinct(dataset_id, dataset_id_citation)
  expect_equal(
    got$dataset_id_citation[match(expected$dataset_id, got$dataset_id)],
    expected$dataset_id_citation
  )

  # An observation whose `source_id` is its dataset cites the dataset's own reference
  i <- joined$traits$source_id == "Apgaua_2017"
  expect_true(any(i))
  expect_equal(
    unique(joined$traits$source_id_citation[i]),
    format_citation(austraits_lite$sources[[which(names(austraits_lite$sources) == "Apgaua_2017")]])
  )

  # A release built before traits.build 2.3 (AusTraits 5.0.0) is read from the
  # old methods columns; it predates `source_primary_type`, so has no
  # `dataset_id_type` to join
  old <- join_sources(austraits_5.0.0_lite)
  expect_equal(nrow(old$traits), nrow(austraits_5.0.0_lite$traits))
  expect_false("dataset_id_type" %in% names(old$traits))
  expected <- austraits_5.0.0_lite$methods %>%
    dplyr::distinct(dataset_id, source_primary_citation)
  got <- old$traits %>% dplyr::distinct(dataset_id, dataset_id_citation)
  expect_equal(
    got$dataset_id_citation[match(expected$dataset_id, got$dataset_id)],
    expected$source_primary_citation
  )

  # ... and there an observation without a `source_id` cites the dataset's own reference
  i <- is.na(old$traits$source_id) & old$traits$dataset_id == "Apgaua_2017"
  expect_true(any(i))
  expect_equal(
    unique(old$traits$source_id_citation[i]),
    format_citation(austraits_5.0.0_lite$sources[[which(names(austraits_5.0.0_lite$sources) == "Apgaua_2017")]])
  )

  # A key with no entry in `sources` gets NA
  db <- austraits_lite
  db$traits$source_id[1] <- "Nobody_1900"
  expect_true(is.na(join_sources(db, vars = "source_id_citation")$traits$source_id_citation[1]))

  # `vars` selects the columns
  joined <- join_sources(austraits_lite, vars = "secondary_id")
  expect_equal(setdiff(names(joined$traits), names(austraits_lite$traits)), "secondary_id")
})

test_that("`flatten_database` takes references from `join_sources`, once", {
  flat <- flatten_database(austraits_lite)
  expect_true(all(c("dataset_id_citation", "source_id_citation") %in% names(flat)))
  expect_false(any(c("source_primary_citation", "source_secondary_key") %in% names(flat)))
  expect_false(any(grepl("\\.(x|y)$", names(flat))))
})

test_that("join_identifiers() works on a database without an identifiers table", {
  # AusTraits 5.0.0 predates the identifiers table; the result has the same
  # column as for an empty identifiers table
  database <- extract_dataset(austraits_5.0.0_lite, "Falster_2003")
  expect_null(database$identifiers)
  joined <- join_identifiers(database)
  expect_identical(setdiff(names(joined$traits), names(database$traits)), "identifier_types")
  expect_true(all(is.na(joined$traits$identifier_types)))
  expect_identical(joined$traits[names(database$traits)], database$traits)
  # The database is not given an identifiers table
  expect_identical(names(joined), names(database))
  expect_error(join_identifiers(database, format = "nonsense"))
})
