database <- austraits_5.0.0_lite
flat <- flatten_database(database)

# The columns every flat table shares with the traits table, to compare rows
key <- function(x) {
  x <- if (is.data.frame(x)) x else x$traits
  x <- x %>%
    dplyr::select("dataset_id", "observation_id", "trait_name", "value", "taxon_name") %>%
    dplyr::arrange(dplyr::across(dplyr::everything())) %>%
    as.data.frame()
  attr(x, "traits.build_stamp") <- NULL
  x
}

test_that("flatten_database() stamps its output with the database it came from", {
  expect_s3_class(flat, c("traits.build_flat", "tbl_df", "tbl", "data.frame"), exact = TRUE)
  expect_equal(attr(flat, "traits.build_stamp"), list(
    title = database$metadata$title,
    version = "5.0.0",
    doi = database$metadata$doi,
    data_model_version = NA_character_,
    traits_build_version = "1.0.1"
  ))
  expect_equal(attr(flatten_database(austraits_lite), "traits.build_stamp")$traits_build_version, "2.1.0")

  # The data model version, which traits.build 2.3 and later records (#40)
  with_version <- database
  with_version$metadata$data_model_version <- "1.4.0"
  stamped <- flatten_database(with_version)
  expect_equal(attr(stamped, "traits.build_stamp")$data_model_version, "1.4.0")
  expect_identical(get_data_model_version(stamped), "1.4.0")
  expect_identical(get_data_model_version(flat), NA_character_)
  expect_identical(get_data_model_version(database$traits), NA_character_)

  # A database without the metadata gives NA, not an error
  bare <- database
  bare$metadata$related_identifiers <- NULL
  bare$metadata$doi <- NULL
  stamp <- attr(stamp_flat(flat, bare), "traits.build_stamp")
  expect_true(is.na(stamp$doi))
  expect_true(is.na(stamp$traits_build_version))
})

test_that("the stamp survives saveRDS() and is printed", {
  file <- withr::local_tempfile(fileext = ".rds")
  saveRDS(flat, file)
  loaded <- readRDS(file)
  expect_s3_class(loaded, "traits.build_flat")
  expect_identical(attr(loaded, "traits.build_stamp"), attr(flat, "traits.build_stamp"))

  skip_if_not_installed("pillar")
  header <- pillar::tbl_sum(flat)
  expect_named(header, c("A traits.build_flat table", "From"))
  expect_match(header[["From"]], "version 5.0.0, doi:10.5281/zenodo.3568417", fixed = TRUE)
})

test_that("extract_*() take a flat table, keep its class and stamp, and find the same rows", {
  out <- extract_trait(flat, "leaf_area")
  expect_s3_class(out, "traits.build_flat")
  expect_identical(attr(out, "traits.build_stamp"), attr(flat, "traits.build_stamp"))
  expect_equal(key(out), key(extract_trait(database, "leaf_area")))

  expect_equal(
    key(extract_trait(flat, "leaf_area", taxon_names = "Eucalyptus")),
    key(extract_trait(database, "leaf_area", taxon_names = "Eucalyptus"))
  )
  expect_equal(key(extract_taxa(flat, family = "Proteaceae")), key(extract_taxa(database, family = "Proteaceae")))
  expect_equal(key(extract_taxa(flat, genus = "Acacia")), key(extract_taxa(database, genus = "Acacia")))
  expect_equal(key(extract_dataset(flat, "Falster_2003")), key(extract_dataset(database, "Falster_2003")))

  # A flattened table's own columns can be extracted from, e.g. location_name
  out <- extract_data(flat, "locations", "location_name", "Cape Tribulation")
  expect_true(nrow(out) > 0)
  expect_true(all(out$location_name == "Cape Tribulation"))
})

test_that("extract_*() take a traits table and a plain data frame", {
  expect_equal(key(extract_dataset(database$traits, "Falster_2003")), key(extract_dataset(database, "Falster_2003")))
  out <- extract_trait(as.data.frame(flat), "leaf_area")
  expect_s3_class(out, "tbl_df")
  expect_equal(key(out), key(extract_trait(database, "leaf_area")))
})

test_that("summarise_database() gives the same summary of a flat table", {
  for (var in c("trait_name", "family", "genus")) {
    expect_equal(summarise_database(flat, var), summarise_database(database, var))
  }
  expect_equal(summarise_database(database$traits, "trait_name"), summarise_database(database, "trait_name"))
  # A traits table has no taxonomy
  expect_error(summarise_database(database$traits, "family"), "no family column")
})

test_that("the plots take a flat table", {
  skip_if_not_installed("ggplot2")
  for (trait in c("leaf_mass_per_area", "leaf_compoundness")) {
    from_flat <- suppressWarnings(plot_trait_distribution(flat, trait))
    from_database <- suppressWarnings(plot_trait_distribution(database, trait))
    expect_equal(nrow(from_flat$data), nrow(from_database$data))
  }

  skip_if_not_installed("ggpointdensity")
  skip_if_not_installed("viridis")
  expect_s3_class(plot_locations(extract_dataset(flat, "Falster_2003")), "ggplot")
})

test_that("functions needing the relational database stop on a flat table", {
  relational_only <- list(
    join_location_coordinates = join_location_coordinates,
    join_location_properties = join_location_properties,
    join_context_properties = join_context_properties,
    join_methods = join_methods,
    join_sources = join_sources,
    join_contributors = join_contributors,
    join_taxa = join_taxa,
    join_taxonomic_updates = join_taxonomic_updates,
    join_identifiers = join_identifiers,
    flatten_database = flatten_database,
    as_wide_table = as_wide_table,
    get_references = get_references
  )
  for (name in names(relational_only)) {
    expect_error(relational_only[[name]](flat), "needs the relational database", info = name)
    expect_error(relational_only[[name]](database$traits), "needs the relational database", info = name)
  }
  expect_error(lookup_trait(flat, "leaf"), "needs the relational database")
  expect_error(lookup_location_property(flat, "soil"), "needs the relational database")
  expect_error(lookup_context_property(flat, "temp"), "needs the relational database")
  expect_error(bind_databases(database, flat), "needs the relational database")

  # Properties are packed into text columns; `value` is the trait value
  expect_error(extract_data(flat, "contexts", "context_property", "age"), "context or location property")
  expect_error(extract_data(flat, "contexts", "value", "adult"), "context or location property")
  expect_error(extract_data(flat, "locations", "location_property", "soil"), "context or location property")
  expect_error(extract_data(flat, "locations", "value", "sand"), "context or location property")
})

test_that("anything that is not a database or a table from one stops", {
  expect_error(extract_trait(mtcars, "leaf_area"), "without a .*trait_name.* column")
  expect_error(extract_trait("austraits", "leaf_area"), "must be a traits.build database")
  expect_error(summarise_database(mtcars, "trait_name"), "without a .*trait_name.* column")
  expect_error(join_taxa(list(a = 1)), "must be a traits.build database")
})

test_that("a flat table stamped with an unsupported data model version is refused (#40)", {
  restamp <- function(version) {
    x <- flat
    attr(x, "traits.build_stamp")$data_model_version <- version
    x
  }
  expect_true(check_compatibility(restamp("1.4.0"), single_table_allowed = TRUE))
  expect_no_error(extract_trait(restamp("1.4.0"), "leaf_area"))

  newer <- restamp("2.0.0")
  expect_false(check_compatibility(newer, single_table_allowed = TRUE))
  expect_error(extract_trait(newer, "leaf_area"), "data model 2.0.0")
  expect_error(extract_trait(newer, "leaf_area"), "Install the latest version of traits.use")
  expect_error(extract_taxa(restamp("1.4"), "Eucalyptus"), "is not a version number")

  # A relational-only function still says it needs the relational database
  expect_error(join_taxa(newer), "needs the relational database")
})
