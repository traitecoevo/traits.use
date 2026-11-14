#Extract a dataset
dataset_id <- c("ABRS_1981")
subset <- extract_dataset(austraits_5.0.0_lite, dataset_id = dataset_id)
bounded <- bind_trait_values(subset$traits)
seperated <-separate_trait_values(trait_data = bounded, austraits_5.0.0_lite$definitions)

test_that("binding/seperating was successful", {
  expect_true(grep("--", bounded$value) %>% any())
  expect_false(grep("--", seperated$value) %>% any())
})

test_that("structure of dataframes is what we expect", {
  expect_equal(nrow(subset$traits), nrow(seperated))
  expect_equal(ncol(subset$traits), ncol(seperated))
  expect_equal(colnames(subset$traits), colnames(seperated))
})

test_that("separate_trait_values() restores what bind_trait_values() joined", {
  sort_rows <- function(x) {
    x %>%
      dplyr::arrange(dataset_id, observation_id, trait_name, value, basis_of_value, replicates,
                     method_id, method_context_id, repeat_measurements_id, value_type) %>%
      as.data.frame()
  }
  # ABRS_1981 and Apgaua_2017 bind, with NA ids in the grouping columns;
  # Westoby_2014 has nothing to bind
  for (id in c("ABRS_1981", "Apgaua_2017", "Westoby_2014")) {
    traits <- extract_dataset(austraits_5.0.0_lite, id)$traits
    restored <- separate_trait_values(bind_trait_values(traits))
    expect_equal(sort_rows(restored), sort_rows(traits), info = id)
  }
  # definitions is not needed
  expect_no_error(separate_trait_values(bind_trait_values(subset$traits)))
})

test_that("Errors with incorrect argument inputs", {
  expect_error(bind_trait_values(subset), label = "Input is a list, not trait dataframe")
  expect_error(bind_trait_values(austraits_5.0.0_lite), label = "Input is a list, not trait dataframe")
  expect_error(separate_trait_values(austraits_5.0.0_lite), label = "Input is a list, not bounded dataframe")
})
