test_that("austraits_lite is a complete traits.build database", {
  expect_s3_class(austraits_lite, "traits.build")
  # As load_database() returns, so `$` looks references up by key
  expect_s3_class(austraits_lite$sources, "traits_build_sources")
  expect_identical(length(unique(austraits_lite$traits$dataset_id)), 24L)
  expect_identical(austraits_lite$metadata$version, "7.0.0")
  expect_gt(nrow(austraits_lite$identifiers), 0)

  # Every dataset's reference is kept, bar Westoby_2014, which has none in
  # the full release either
  cited <- unique(c(austraits_lite$methods$dataset_id, austraits_lite$methods$source_primary_key))
  expect_identical(setdiff(cited, names(austraits_lite$sources)), "Westoby_2014")
  expect_false(is.null(austraits_lite$sources$Falster_2003))
})
