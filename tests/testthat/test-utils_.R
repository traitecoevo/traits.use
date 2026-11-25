
# Miscellaneous bugs that have been raised

test_that("Dataframe is extracted correctly", {
  # Extracting by genus then trait gives the same values as by trait then genus
  austraits <- austraits_lite

  # Extract Acacia first
  acacia <- extract_taxa(austraits, genus = "Acacia")

  # Filter to leaf area using dplyr
  acacia_leaf_area <- acacia$traits %>%
    dplyr::filter(trait_name == "leaf_area")
  expect_gt(nrow(acacia_leaf_area), 0)

  # Extract trait after
  acacia %>% extract_trait("leaf_area") -> genus_first

  # Extract trait first
  austraits %>% extract_trait("leaf_area") -> leaf_area

  # Extract taxa after
  leaf_area %>% extract_taxa(genus = "Acacia") -> trait_first

  expect_setequal(trait_first$traits$value, acacia_leaf_area$value)
  expect_setequal(trait_first$traits$value, genus_first$traits$value)
  expect_setequal(acacia_leaf_area$value, genus_first$traits$value)
})

test_that("Function executes - convert functions", {
  expect_visible(convert_df_to_list(dplyr::starwars))
  expect_visible(convert_list_to_df1(as.list(dplyr::starwars)[2]))
  
  demo_list1 <- list(word1 = "this", word2 = "is", word3 = "an", word4 = "example", word5 = "list")
  demo_list2 <- list(word1 = "and", word2 = "a", word3 = "second", word4 = "list", word5 = "also")
  combined_list <- list(demo_list1, demo_list2)
  
  expect_named(convert_list_to_df2(combined_list))
})


test_that("Function throws error - function not supported", {
  expect_error(function_not_supported(austraits_lite$traits))
  expect_error(
    function_not_supported(list(traits = austraits_lite$traits, metadata = list(title = "x"))),
    "doesn't look like a database built by traits.build"
  )
}
)
