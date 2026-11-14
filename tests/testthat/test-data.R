test_that("austraits_lite is a complete traits.build database", {
  expect_s3_class(austraits_lite, "traits.build")
  # As load_database() returns, so `$` looks references up by key
  expect_s3_class(austraits_lite$sources, "traits_build_sources")
  expect_identical(length(unique(austraits_lite$traits$dataset_id)), 23L)

  # Every dataset's reference is kept, bar Westoby_2014, which has none in
  # the full 5.0.0 release either (an older fixture had only 31 of the 60)
  cited <- unique(c(austraits_lite$methods$dataset_id, austraits_lite$methods$source_primary_key))
  expect_identical(setdiff(cited, names(austraits_lite$sources)), "Westoby_2014")
  expect_identical(length(austraits_lite$sources), 60L)
  expect_false(is.null(austraits_lite$sources$Falster_2003))
})
