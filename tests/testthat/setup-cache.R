# Keep every test's downloads out of the user's own cache folder. Tests that
# load databases also call local_test_cache() (helper.R), so that records
# saved by one test (the same fake dois, other files) never reach another.
local({
  cache <- tempfile("traits.use-cache")
  withr::local_options(traits.use.cache_dir = cache, .local_envir = testthat::teardown_env())
  withr::defer(unlink(cache, recursive = TRUE), envir = testthat::teardown_env())
})
