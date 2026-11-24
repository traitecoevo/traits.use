test_that("austraits_lite is a complete traits.build database", {
  expect_s3_class(austraits_lite, "traits.build")
  # As load_database() returns, so `$` looks references up by key
  expect_s3_class(austraits_lite$sources, "traits_build_sources")
  expect_identical(length(unique(austraits_lite$traits$dataset_id)), 24L)
  # Built from austraits.build source, not a release (data-raw/austraits_lite.R)
  expect_identical(austraits_lite$metadata$data_model_version, "1.4.0")
  expect_gt(nrow(austraits_lite$identifiers), 0)
  # The tables in the order of a release
  test_database_structure(austraits_lite)
  expect_identical(length(austraits_lite$sources), 88L)

  # Every reference cited is kept: each dataset's, each observation's source_id,
  # and the secondary references, which methods lists separated by "; "
  expect_false(anyNA(austraits_lite$traits$source_id))
  secondary <- unlist(strsplit(stats::na.omit(austraits_lite$methods$secondary_id), "; ", fixed = TRUE))
  cited <- unique(c(austraits_lite$methods$dataset_id, austraits_lite$traits$source_id,
                    austraits_lite$excluded_data$source_id, secondary))
  expect_identical(setdiff(cited, names(austraits_lite$sources)), character(0))
  expect_false(is.null(austraits_lite$sources$Falster_2003))
})

test_that("austraits_lite follows the data model of the traits.build installed", {
  # austraits_lite must be rebuilt (data-raw/austraits_lite.R) whenever
  # traits.build changes the data model, before traits.use is released (#13).
  # traits.use cannot depend on traits.build, so this runs only in
  # devtools::test() where traits.build is installed; R CMD check skips it,
  # since its library holds only declared dependencies
  skip_if_not_installed("traits.build")
  # an internal function of traits.build (>= 3.0.0)
  ns <- asNamespace("traits.build")
  skip_if_not(exists("data_model_version", envir = ns, inherits = FALSE),
              "this traits.build has no data_model_version()")
  installed <- get("data_model_version", envir = ns)()
  expect_identical(
    austraits_lite$metadata$data_model_version, installed,
    label = "austraits_lite's data model version",
    expected.label = sprintf(paste0("traits.build %s's (with the traits.build to be released installed, ",
                                    "rebuild austraits_lite with data-raw/austraits_lite.R)"),
                             utils::packageVersion("traits.build"))
  )
})
