test_database_structure <- function(database, taxa = NA, dataset_id = NA, n_row = NA) {
  
  table_names <- c("traits", "locations", "contexts", "methods", "excluded_data", "taxonomic_updates", "taxa", "identifiers", "contributors", 
                   "sources", "definitions", "schema", "metadata", "build_info")
  
  testthat::expect_type(database, "list")
  testthat::expect_equal(class(database), "traits.build")
  
  # idnetifiers are optional
  if(!("identifiers" %in% names(database))) {
    table_names <- table_names[table_names != "identifiers"]
  }

  testthat::expect_equal(names(database), table_names)
  
  testthat::expect_contains(database$traits$taxon_name |> unique(), database$taxa$taxon_name |> unique())
  testthat::expect_contains(database$traits$dataset_id |> unique(), database$methods$dataset_id |> unique())
  # A trait in methods has records, or had them all excluded (traits.build 3.0.0
  # lists those in methods too, e.g. Westoby_2014's leaf_specific_hydraulic_conductance)
  testthat::expect_contains(unique(c(paste(database$traits$dataset_id, database$traits$trait_name),
                                     paste(database$excluded_data$dataset_id, database$excluded_data$trait_name))),
                            paste(database$methods$dataset_id, database$methods$trait_name) |> unique())
  
  if(!is.na(taxa)) {
    testthat::expect_contains(database$traits$taxon_name |> unique(), taxa |> unique())
  }
  
  if(!is.na(dataset_id)) {
    testthat::expect_contains(database$traits$dataset_id |> unique(), dataset_id |> unique())
  }
  
  if(!is.na(n_row)) {
    testthat::expect_equal(database$traits |> nrow(), n_row)
  }
}

# A cache folder of the test's own, removed when it ends
local_test_cache <- function(env = parent.frame()) {
  cache <- tempfile("cache")
  withr::local_options(traits.use.cache_dir = cache, .local_envir = env)
  withr::defer(unlink(cache, recursive = TRUE), envir = env)
  cache
}
