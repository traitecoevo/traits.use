
inputs <- list(austraits_lite, austraits_lite$traits)

test_pivot_success <- function(austraits){
  test_that("pivot on subset of data", {
    
    expect_silent(
      wide_data <- austraits %>% trait_pivot_wider()
    )
    
    expect_type(wide_data, "list")
    expect_named(wide_data)
  })
}

purrr::walk(inputs,
            test_pivot_success)


test_that("Widen structure is expected", {
  wide_data <- austraits_lite %>% trait_pivot_wider()
  names(wide_data)
  #Checking if widened data has the same length as variables that we are spreading
  expect_gt(ncol(wide_data), ncol(austraits_lite$traits)) 
  expect_lt(nrow(wide_data), nrow(austraits_lite$traits)) 
  expect_true(any(colnames(wide_data) %in% unique(austraits_lite$traits$trait_name)))
}
)
test_that("functions should throw error when provided wrong input", {
  expect_error(trait_pivot_wider(austraits_lite$taxa), label = "Relevent column names from trait data frame not found")
  expect_error(trait_pivot_wider(austraits_lite$methods), label = "Relevent column names from trait data frame not found")
  # trait_pivot_longer() is deprecated, and gives an error
  expect_error(trait_pivot_longer(austraits_lite$traits))
})
