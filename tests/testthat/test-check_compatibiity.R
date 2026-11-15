# A database as traits.build writes it once it records its data model version
with_data_model_version <- function(database, version) {
  database$metadata$data_model_version <- version
  database
}

# The same database without the related identifier naming traits.build, as a
# renamed or moved engine would write it
without_compiled_by <- function(database) {
  database$metadata$related_identifiers <-
    Filter(function(x) x$relation_type != "isCompiledBy",
           database$metadata$related_identifiers)
  database
}

test_that("databases built before the data model version are recognised by the traits.build URL", {
  expect_silent(check_compatibility(austraits_5.0.0_lite))
  expect_true(check_compatibility(austraits_5.0.0_lite))
  expect_true(check_compatibility(austraits_lite))
  expect_identical(get_data_model_version(austraits_lite), NA_character_)

  expect_false(check_compatibility(without_compiled_by(austraits_5.0.0_lite)))
  expect_error(join_taxa(without_compiled_by(austraits_5.0.0_lite)), "no longer supports")
})

test_that("AusTraits 3.0.2 is not supported", {
  expect_false(check_compatibility(austraits_3.0.2_lite))

  expect_error(austraits_3.0.2_lite %>% join_location_coordinates())
  expect_error(austraits_3.0.2_lite %>% join_location_properties())
  expect_error(austraits_3.0.2_lite %>% join_contributors())
  expect_error(austraits_3.0.2_lite %>% join_methods())
  expect_error(austraits_3.0.2_lite %>% join_taxa())
  expect_error(austraits_3.0.2_lite %>% join_context_properties())
  expect_error(austraits_3.0.2_lite %>% extract_data("traits", "wood_density"))
})

test_that("a supported data model version makes a database compatible, without the traits.build URL", {
  db <- with_data_model_version(austraits_lite, "1.4.0")
  expect_identical(get_data_model_version(db), "1.4.0")
  expect_true(check_compatibility(db))

  # The point of #40: the engine's URL no longer decides it
  renamed <- without_compiled_by(db)
  expect_true(check_compatibility(renamed))
  expect_no_error(join_taxa(renamed))
  expect_no_error(extract_dataset(renamed, "Falster_2003"))

  # Any minor or patch version of a supported major
  expect_true(check_compatibility(with_data_model_version(austraits_lite, "1.0.0")))
  expect_true(check_compatibility(with_data_model_version(austraits_lite, "1.27.3")))
})

test_that("an unsupported data model version is refused, with advice to update traits.use", {
  newer <- with_data_model_version(austraits_lite, "2.0.0")
  # The version decides, even when the traits.build URL is there
  expect_true(nrow(get_compiled_by_traits.build(newer)) > 0)
  expect_false(check_compatibility(newer))

  expect_error(join_taxa(newer), "data model 2.0.0")
  expect_error(join_taxa(newer), "reads data model 1.x")
  expect_error(join_taxa(newer), "Install the latest version of traits.use")
  expect_error(extract_trait(newer, "leaf_area"), "data model 2.0.0")
  expect_error(get_references(newer), "data model 2.0.0")

  expect_false(check_compatibility(with_data_model_version(austraits_lite, "0.1.0")))
})

test_that("a data model version that is not major.minor.patch is refused", {
  for (bad in list("1.4", "one", "", c("1.4.0", "1.3.0"), NA)) {
    db <- with_data_model_version(austraits_lite, bad)
    expect_false(check_compatibility(db), label = format(bad))
  }
  expect_error(join_taxa(with_data_model_version(austraits_lite, "1.4")),
               "is not a version number")
})

test_that("a flat table is still allowed where a single table is", {
  expect_true(check_compatibility(austraits_lite$traits, single_table_allowed = TRUE))
})

test_that("the data model version survives extract_*() and bind_databases()", {
  db <- with_data_model_version(austraits_lite, "1.4.0")
  expect_identical(get_data_model_version(extract_dataset(db, "Falster_2003")), "1.4.0")
  expect_identical(get_data_model_version(extract_trait(db, "leaf_area")), "1.4.0")

  bound <- suppressWarnings(bind_databases(
    extract_dataset(db, "Falster_2003"),
    extract_dataset(db, "Westoby_2014")
  ))
  expect_identical(get_data_model_version(bound), "1.4.0")
})

test_that("print() shows the data model version", {
  out <- cli::cli_fmt(print(with_data_model_version(austraits_lite, "1.4.0")))
  expect_true(any(grepl("traits.build data model 1.4.0", out, fixed = TRUE)))

  out <- cli::cli_fmt(print(austraits_lite))
  expect_false(any(grepl("data model", out, fixed = TRUE)))

  out <- cli::cli_fmt(print(with_data_model_version(austraits_lite, "2.0.0")))
  expect_true(any(grepl("cannot read", out, fixed = TRUE)))
})
