
test_that("Function is working", {
    expect_visible(austraits_lite %>% as_wide_table())
    out <- austraits_lite %>% as_wide_table()
    expect_named(out)
    expect_type(out, "list")
 
    # "Output is correct"
    expect_gt(out %>% ncol(), expected = austraits_lite$traits %>% ncol())
  })

expect_error(as_wide_table())

test_that("Most-used columns come first and no column is dropped (#25)", {
  first <- c(
    "dataset_id", "observation_id", "trait_name", "taxon_name", "value", "unit",
    "entity_type", "population_id", "individual_id", "value_type", "basis_of_value",
    "replicates", "collection_date", "basis_of_record", "life_stage", "sampling_strategy",
    "treatment_context_id", "temporal_context_id", "latitude (deg)", "longitude (deg)",
    "location", "plot_context_id", "context", "methods", "method_id", "method_context_id",
    "original_name", "dataset_description", "dataset_id_citation", "source_id_citation",
    "secondary_citation", "taxonomic_status", "taxon_distribution", "taxon_rank", "genus",
    "family"
  )
  for (db in list(austraits_lite, austraits_lite)) {
    out <- as_wide_table(db)
    expect_identical(names(out)[seq_along(first)], first)
    expect_true(all(c("source_id", "repeat_measurements_id", "location_id", "taxon_id") %in% names(out)))
    expect_true(all(names(db$traits) %in% names(out)))
  }
  # The wide table can be pivoted, which needs repeat_measurements_id
  out <- as_wide_table(extract_dataset(austraits_lite, "Falster_2003"))
  expect_no_error(trait_pivot_wider(out))
})


test_that("function `collapse_cols` works", {
    data <- (austraits_lite %>% extract_dataset("Bloomfield_2018"))$locations
    data_collapsed <- (data %>% collapse_cols())[[1]]
    expect_equal(stringr::str_count(data_collapsed, "="), 5)
    expect_equal(stringr::str_count(data_collapsed, "; "), 4)
})

test_that("A database without contexts or locations gives the same columns and values", {
  full <- as_wide_table(austraits_lite)
  # No contexts; no locations (a flora); locations without known values
  for (id in c("Falster_2003", "ABRS_1981", "Yang_2023")) {
    wide <- as_wide_table(extract_dataset(austraits_lite, id))
    expected <- full[full$dataset_id == id, ]
    expect_identical(names(wide), names(full), info = id)
    expect_identical(nrow(wide), nrow(expected), info = id)
    for (col in names(wide)) {
      expect_identical(as.character(wide[[col]]), as.character(expected[[col]]), info = paste(id, col))
    }
  }
})
