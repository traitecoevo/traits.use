# summarise_trait_means(): observed means of numeric traits and the most
# frequent values of categorical ones (#50)

# Trait records as a flat table, with the columns the summary reads
record <- function(taxon_name, trait_name, value, value_type = "raw",
                   dataset_id = "D1", location_id = "01", observation_id = "01",
                   basis_of_record = "field", unit = "m", life_stage = "adult",
                   taxon_rank = "species") {
  tibble::tibble(
    dataset_id = dataset_id, taxon_name = taxon_name, observation_id = observation_id,
    trait_name = trait_name, value = as.character(value), unit = unit,
    value_type = value_type, basis_of_record = basis_of_record,
    location_id = location_id, original_name = taxon_name, life_stage = life_stage,
    taxon_rank = taxon_rank, genus = sub(" .*", "", taxon_name), family = "Fabaceae",
    establishment_means = "native", taxon_id = paste0("id-", taxon_name)
  )
}

test_that("a numeric value is the geometric mean of location means and flora midpoints", {
  records <- dplyr::bind_rows(
    # one location with two records: geometric mean 2, arithmetic mean 2.5
    record("Acacia a", "plant_height", c(1, 4)),
    # a second location: 8
    record("Acacia a", "plant_height", 8, location_id = "02"),
    # a flora observation: geometric midpoint 4, arithmetic midpoint 5
    record("Acacia a", "plant_height", c(2, 8), value_type = c("minimum", "maximum"),
           dataset_id = "D2", location_id = NA, basis_of_record = "literature"),
    # none of these is used: a zero, a non-number, and a bound measured in the field
    record("Acacia a", "plant_height", 0),
    record("Acacia a", "plant_height", "tall"),
    record("Acacia a", "plant_height", 100, value_type = "maximum")
  )

  means <- summarise_trait_means(records)

  expect_equal(nrow(means), 1)
  expect_equal(means$value, 4)
  expect_equal(means$log_value, log(4))
  expect_equal(means$arithmetic_mean, mean(c(2.5, 8, 5)))
  expect_equal(c(means$value_min, means$value_max), c(1, 8))
  expect_equal(means$n_records, 5)
  expect_equal(means$n_locations, 2)
  expect_equal(means$n_datasets, 2)
  expect_equal(means$n_flora, 2)
  expect_equal(means$n_field, 3)
  expect_equal(means$sd_log, sd(log(c(1, 4, 8, 2, 8))))
  expect_equal(means$dataset_id, "D1; D2")
  # no source_id: each dataset is its own source
  expect_equal(means$source_id, "D1; D2")
  expect_equal(means$type, "numerical")
  expect_equal(means$estimate_type, "observed_mean")
  expect_equal(means$method, "geometric")
  expect_equal(means$reliability, "medium")
  expect_equal(means$taxon_id, "id-Acacia a")
})

test_that("the columns are those of the dictionary, whatever the traits", {
  numeric_only <- summarise_trait_means(record("Acacia a", "plant_height", 2))
  categorical_only <- summarise_trait_means(record("Acacia a", "plant_growth_form", "tree", unit = NA))

  expect_equal(names(numeric_only), trait_means_dictionary()$column)
  expect_equal(names(categorical_only), trait_means_dictionary()$column)
  expect_false(anyNA(trait_means_dictionary()$definition))

  # nothing usable gives the same columns and no rows
  none <- summarise_trait_means(record("Acacia a", "plant_height", 0))
  expect_equal(names(none), trait_means_dictionary()$column)
  expect_equal(nrow(none), 0)
})

test_that("a signed trait gets an arithmetic mean of every record", {
  records <- dplyr::bind_rows(
    # one location: -1 and -3, mean -2; another: 0
    record("Acacia a", "water_potential_midday", c(-1, -3), unit = "MPa"),
    record("Acacia a", "water_potential_midday", 0, unit = "MPa", location_id = "02"),
    # a flora range, midpoint -5
    record("Acacia a", "water_potential_midday", c(-8, -2), unit = "MPa",
           value_type = c("minimum", "maximum"), dataset_id = "D2",
           location_id = NA, basis_of_record = "literature"),
    # a positive-scale trait alongside, which keeps its geometric mean
    record("Acacia a", "plant_height", c(1, 4))
  )

  # a flat table: signed because it has a negative record
  means <- summarise_trait_means(records)
  wp <- means[means$trait_name == "water_potential_midday", ]
  expect_equal(wp$method, "arithmetic")
  expect_equal(wp$value, mean(c(-2, 0, -5)))
  expect_equal(wp$arithmetic_mean, wp$value)
  expect_true(is.na(wp$log_value))
  expect_true(is.na(wp$sd_log))
  expect_equal(wp$n_records, 5)
  expect_equal(c(wp$value_min, wp$value_max), c(-8, 0))

  height <- means[means$trait_name == "plant_height", ]
  expect_equal(height$method, "geometric")
  expect_equal(height$value, 2)

  # the relational database: signed because its definition allows negative
  # values, even in a subset whose records are all positive
  database <- austraits_lite
  signed <- names(Filter(function(d) isTRUE(as.numeric(d$allowed_values_min) < 0), database$definitions))
  skip_if(length(intersect(signed, database$traits$trait_name)) == 0)
  trait <- intersect(signed, database$traits$trait_name)[1]
  all_means <- summarise_trait_means(database, traits = trait)
  expect_equal(unique(all_means$method), "arithmetic")
  expect_equal(trait_means_signed(database, database$traits), signed)
})

test_that("source_id lists the references the records were taken from", {
  records <- dplyr::bind_rows(
    record("Acacia a", "plant_height", 1, dataset_id = "Compilation_2020"),
    record("Acacia a", "plant_height", 2, dataset_id = "Compilation_2020", location_id = "02"),
    record("Acacia a", "plant_height", 4, dataset_id = "Smith_2001"),
    record("Acacia a", "plant_growth_form", "tree", unit = NA, dataset_id = "Compilation_2020")
  )
  # two records name the studies the compilation took them from; the others
  # have none, so count their dataset
  records$source_id <- c("Jones_1990", "Brown_1985", NA, "Jones_1990")

  means <- summarise_trait_means(records)
  expect_equal(means$dataset_id, c("Compilation_2020", "Compilation_2020; Smith_2001"))
  expect_equal(means$source_id, c("Jones_1990", "Brown_1985; Jones_1990; Smith_2001"))
  expect_equal(names(means)[match(c("dataset_id", "source_id"), names(means))], c("dataset_id", "source_id"))

  # a database whose records name other sources
  lite <- summarise_trait_means(austraits_lite)
  expect_false(anyNA(lite$source_id))
  expect_true(any(lite$source_id != lite$dataset_id))
})

test_that("a lone flora bound stands in for the midpoint", {
  means <- summarise_trait_means(
    record("Acacia b", "plant_height", 3, value_type = "minimum", basis_of_record = "preserved_specimen")
  )
  expect_equal(means$value, 3)
  expect_equal(means$n_flora, 1)
  expect_true(is.na(means$sd_log))
  expect_equal(means$reliability, "low")
})

test_that("a dataset with a value-type rule enters by the value types listed", {
  records <- dplyr::bind_rows(
    record("Acacia c", "plant_height", c(1, 4), value_type = c("minimum", "maximum"),
           dataset_id = "Labels", location_id = NA, observation_id = c("01", "02"),
           basis_of_record = "preserved_specimen"),
    # not a listed value type for this dataset
    record("Acacia c", "plant_height", 100, dataset_id = "Labels", location_id = NA)
  )
  rules <- data.frame(dataset_id = "Labels", value_type = c("minimum", "maximum"))

  means <- summarise_trait_means(records, value_type_rules = rules)
  # the bounds are observations in one dataset x location group, not a flora midpoint
  expect_equal(means$value, 2)
  expect_equal(means$n_records, 2)
  expect_equal(means$n_locations, 1)
  expect_equal(means$n_flora, 0)

  # without the rule the bounds are a flora observation each, and the raw record is used
  expect_equal(summarise_trait_means(records)$n_records, 3)

  expect_error(summarise_trait_means(records, value_type_rules = "Labels"), "must be a data frame")
})

test_that("units of one trait are kept apart", {
  means <- summarise_trait_means(dplyr::bind_rows(
    record("Acacia a", "plant_height", 2),
    record("Acacia a", "plant_height", 200, unit = "cm")
  ))
  expect_equal(means$unit, c("cm", "m"))
  expect_equal(means$value, c(200, 2))
})

test_that("a categorical trait gets its modal value, with ties joined in sorted order", {
  records <- dplyr::bind_rows(
    record("Acacia a", "plant_growth_form", c("tree shrub", "tree", "shrub", "herb"), unit = NA),
    record("Acacia b", "plant_growth_form", c("tree", "tree"), unit = NA, dataset_id = c("D1", "D2")),
    # a record without a value is counted as a record, but adds no value
    record("Acacia c", "plant_growth_form", c("tree", NA), unit = NA)
  )
  means <- summarise_trait_means(records)

  a <- means[means$taxon_name == "Acacia a", ]
  expect_equal(a$value_mode, "shrub tree")
  expect_equal(a$value_count, "herb (1); shrub (2); tree (2)")
  expect_equal(a$n_records, 4)
  expect_equal(a$type, "categorical")
  expect_equal(a$method, "mode")
  expect_true(is.na(a$value))

  b <- means[means$taxon_name == "Acacia b", ]
  expect_equal(b$value_mode, "tree")
  expect_equal(b$n_datasets, 2)
  expect_equal(b$dataset_id, "D1; D2")

  expect_equal(means$value_count[means$taxon_name == "Acacia c"], "tree (1)")

  # a value a record lists twice counts once for that record
  repeated <- summarise_trait_means(
    record("Acacia a", "plant_growth_form", c("tree tree", "shrub", "shrub"), unit = NA)
  )
  expect_equal(repeated$value_mode, "shrub")
  expect_equal(repeated$value_count, "shrub (2); tree (1)")
})

test_that("a trait recording months is summarised month by month", {
  records <- record("Banksia a", "flowering_time", unit = NA, value = c(
    "yynnnnnnnyyy",   # Oct to Feb
    "yynnnnnnnyyy",
    "yynnnnnnnyyy",
    "nnnnnnnnnnyy",   # Nov, Dec
    "ynnnnnnyyyyy",   # Aug to Jan
    "yynnnnnnnnny"    # Dec to Feb
  ))
  means <- summarise_trait_means(records)

  expect_equal(means$n_records, 6)
  # every month a record marks, with its count, in calendar order
  expect_equal(means$value_count,
               "Jan (5); Feb (4); Aug (1); Sep (1); Oct (4); Nov (5); Dec (6)")
  # the months at least half the records mark: Jan, Feb, Oct, Nov, Dec
  expect_equal(means$value_mode, "yynnnnnnnyyy")
  expect_equal(means$type, "categorical")
  expect_equal(means$method, "majority")

  # with two records, a month either marks is at least half
  two <- summarise_trait_means(records[c(4, 5), ])
  expect_equal(two$value_mode, "ynnnnnnyyyyy")

  # a record that is not a month string is left out
  odd <- summarise_trait_means(dplyr::bind_rows(records[1, ], record("Banksia a", "flowering_time", "spring", unit = NA)))
  expect_equal(odd$value_count, "spring (1); yynnnnnnnyyy (1)")
})

test_that("months are recognised by definition, or by every record being a month string", {
  database <- austraits_lite
  # a definition of type monthly_presence (traits.build 3.0.0) decides on its own
  expect_equal(database$definitions$flowering_time$type, "monthly_presence")
  expect_true("flowering_time" %in% trait_means_monthly(database, database$traits))
  expect_false("leaf_phenology" %in% trait_means_monthly(database, database$traits))
  months <- summarise_trait_means(database, traits = "flowering_time")
  expect_true(all(grepl("^[yn]{12}$", months$value_mode)))
  expect_true(all(grepl("^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \\(", months$value_count)))

  # defined as categorical, as in AusTraits 7.0.0 and earlier, its records decide
  database$definitions$flowering_time$type <- "categorical"
  expect_true("flowering_time" %in% trait_means_monthly(database, database$traits))
  expect_identical(summarise_trait_means(database, traits = "flowering_time"), months)
})

test_that("subspecies, varieties and forms are rolled up to their species", {
  records <- dplyr::bind_rows(
    record("Acacia a", "plant_height", 2),
    record("Acacia a subsp. x", "plant_height", 8, location_id = "02", taxon_rank = "subspecies"),
    record("Acacia d var. y", "plant_height", 5, taxon_rank = "variety"),
    record("Acacia", "plant_height", 7, taxon_rank = "genus")
  )

  means <- summarise_trait_means(records)
  expect_equal(means$taxon_name, c("Acacia", "Acacia a", "Acacia d"))
  expect_equal(means$value, c(7, 4, 5))
  expect_equal(means$taxon_rank, c("genus", "species", "species"))
  # details come from the species' own row; a species without one has its
  # genus and family from its variety, and no identifier
  expect_equal(means$taxon_id, c("id-Acacia", "id-Acacia a", NA))
  expect_equal(means$genus, c("Acacia", "Acacia", "Acacia"))

  kept <- summarise_trait_means(records, collapse_to_species = FALSE)
  expect_equal(kept$taxon_name, c("Acacia", "Acacia a", "Acacia a subsp. x", "Acacia d var. y"))
  expect_equal(kept$taxon_rank, c("genus", "species", "subspecies", "variety"))
})

test_that("hybrids roll up to the nothospecies, and hybrid formulae not at all", {
  names <- c(
    "Mentha x piperita var. citrata",
    "Acacia trachycarpa x Acacia tumida var. pilbarensis",
    "Acacia adoxa var. adoxa x Acacia spondylophylla",
    "Myoporum acuminatum - Myoporum boninense subsp. australe",
    # ranked a variety, but with no rank marker to strip
    "Prostanthera latifolia",
    # zoological trinomials have no rank marker either
    "Agrilus (Agrilus) assimilis assimilis"
  )
  ranks <- c("variety", "variety", "variety", "subspecies", "variety", "subspecies")
  expect_equal(trait_means_species(names, ranks), c("Mentha x piperita", names[-1]))

  # a name the taxonomy does not rank infraspecific stays as it is, unless the
  # taxonomy is unknown, when the name alone decides
  expect_equal(trait_means_species("Acacia a subsp. x", NA), "Acacia a subsp. x")
  expect_equal(trait_means_species("Acacia a subsp. x"), "Acacia a")
})

test_that("a species takes from its subspecies what its own taxa row lacks", {
  records <- dplyr::bind_rows(
    record("Ephedra distachya", "plant_height", 1),
    record("Ephedra distachya subsp. helvetica", "plant_height", 1, taxon_rank = "subspecies")
  )
  # the species is outside the taxonomic reference: its row has nothing in it
  records[1, c("taxon_rank", "genus", "family", "establishment_means", "taxon_id")] <- NA

  means <- summarise_trait_means(records)
  expect_equal(means$taxon_name, "Ephedra distachya")
  expect_equal(means$taxon_rank, "species")
  expect_equal(means$genus, "Ephedra")
  expect_equal(means$family, "Fabaceae")
  expect_true(is.na(means$taxon_id))

  # whichever traits are summarised: here the subspecies has records only of
  # another trait
  records$trait_name[2] <- "leaf_length"
  height <- summarise_trait_means(records, traits = "plant_height")
  expect_equal(height[c("taxon_rank", "genus")], tibble::tibble(taxon_rank = "species", genus = "Ephedra"))
})

test_that("a record without a taxon name is not given a rank", {
  records <- dplyr::bind_rows(
    record("Acacia a", "plant_height", 1),
    record(NA_character_, "plant_height", 2, taxon_rank = NA_character_)
  )
  records$genus[2] <- NA
  means <- summarise_trait_means(records)
  expect_equal(means$taxon_rank, c("species", NA))
  expect_equal(trait_means_species(c("Acacia a subsp. b", NA)), c("Acacia a", NA))
})

test_that("`by` gives a row per group, with missing values a group of their own", {
  records <- dplyr::bind_rows(
    record("Acacia a", "plant_height", c(2, 8), life_stage = "adult"),
    record("Acacia a", "plant_height", 0.5, life_stage = "seedling"),
    record("Acacia a", "plant_height", 1, life_stage = NA),
    record("Acacia a", "plant_growth_form", c("tree", "herb"), unit = NA, life_stage = c("adult", "seedling"))
  )

  means <- summarise_trait_means(records, by = "life_stage")
  expect_equal(names(means), append(trait_means_dictionary()$column, "life_stage", after = 1))

  height <- means[means$trait_name == "plant_height", ]
  expect_equal(height$life_stage, c("adult", "seedling", NA))
  expect_equal(height$value, c(4, 0.5, 1))
  form <- means[means$trait_name == "plant_growth_form", ]
  expect_equal(form$value_mode, c("tree", "herb"))

  # no rows still gives the `by` column, of its type
  empty <- summarise_trait_means(records[0, ], by = "life_stage")
  expect_equal(names(empty), names(means))
  expect_type(empty$life_stage, "character")

  expect_error(summarise_trait_means(records, by = "sex"), "no column")
  expect_error(summarise_trait_means(records, by = "dataset_id"), "cannot include")
  expect_error(summarise_trait_means(records, by = 1), "character vector")
})

test_that("a trait with no records gives a warning naming it", {
  records <- record("Acacia a", "plant_height", 2)
  expect_warning(
    means <- summarise_trait_means(records, traits = c("plant_height", "plant_hite")),
    "plant_hite"
  )
  expect_equal(means$trait_name, "plant_height")
})

test_that("a database, its flattened table and its traits table give the same means", {
  database <- austraits_lite
  means <- summarise_trait_means(database)

  # every trait by default, one row per taxon x trait x unit
  expect_setequal(means$trait_name[means$type == "categorical"],
                  unique(database$traits$trait_name[is.na(database$traits$unit)]))
  expect_equal(anyDuplicated(means[c("taxon_name", "trait_name", "unit")]), 0)
  expect_equal(names(means), trait_means_dictionary()$column)

  arithmetic <- means[means$method %in% "arithmetic", ]
  expect_gt(nrow(arithmetic), 0)
  expect_equal(arithmetic$value, arithmetic$arithmetic_mean)
  expect_true(all(arithmetic$value >= arithmetic$value_min - 1e-9 &
                    arithmetic$value <= arithmetic$value_max + 1e-9))

  numeric <- means[means$type == "numerical" & means$method == "geometric", ]
  expect_true(all(numeric$value > 0))
  expect_true(all(numeric$value >= numeric$value_min * (1 - 1e-9)))
  expect_true(all(numeric$value <= numeric$value_max * (1 + 1e-9)))
  expect_true(all(numeric$arithmetic_mean >= numeric$value * (1 - 1e-9)))

  # no infraspecific taxa, other than hybrid formulae
  infraspecific <- means$taxon_rank %in% c("subspecies", "variety", "form")
  expect_false(any(infraspecific & !grepl("\\s(x|-)\\s[A-Z]", means$taxon_name)))

  # A flat table has no definitions, so it calls a trait signed only if it has
  # a negative record; the two agree on every other trait
  flat <- summarise_trait_means(flatten_database(database))
  signed_by_definition <- trait_means_signed(database, database$traits)
  signed_by_records <- trait_means_signed(flatten_database(database), database$traits)
  expect_true(all(signed_by_records %in% signed_by_definition))
  same <- !means$trait_name %in% signed_by_definition
  expect_equal(flat[!flat$trait_name %in% signed_by_definition, ], means[same, ])
  expect_equal(flat[flat$trait_name %in% signed_by_records, ], means[means$trait_name %in% signed_by_records, ])

  # a traits table carries no taxonomy: the same values, without the taxon
  # columns, rolled up by name alone; as a tibble or a plain data frame
  from_traits <- summarise_trait_means(database$traits)
  expect_equal(summarise_trait_means(as.data.frame(database$traits), collapse_to_species = FALSE),
               summarise_trait_means(database$traits, collapse_to_species = FALSE))
  expect_equal(names(from_traits), setdiff(names(means), c("taxon_rank", "genus", "family", "establishment_means", "taxon_id")))
  by_rank <- summarise_trait_means(database, traits = "leaf_length")
  by_name <- summarise_trait_means(database$traits, traits = "leaf_length")
  expect_true(all(by_name$taxon_name %in% by_rank$taxon_name))

  # a subset made with extract_*() can be summarised
  acacia <- summarise_trait_means(extract_taxa(database, genus = "Acacia"), traits = "leaf_length")
  expect_equal(acacia, means[means$trait_name == "leaf_length" & means$genus %in% "Acacia", ])
})

test_that("the summary agrees with a group-by-group calculation", {
  database <- austraits_lite
  means <- summarise_trait_means(database, traits = "leaf_length", collapse_to_species = FALSE)

  records <- database$traits |>
    dplyr::filter(trait_name == "leaf_length") |>
    dplyr::mutate(value = as.numeric(value)) |>
    dplyr::filter(value > 0)
  locations <- records |>
    dplyr::filter(value_type %in% c("raw", "mean", "median")) |>
    dplyr::group_by(taxon_name, unit, dataset_id, location_id) |>
    dplyr::summarise(log_mean = mean(log(value)), n = dplyr::n(), .groups = "drop")
  floras <- records |>
    dplyr::filter(value_type %in% c("minimum", "maximum"),
                  basis_of_record %in% c("preserved_specimen", "literature")) |>
    dplyr::group_by(taxon_name, unit, dataset_id, observation_id, original_name) |>
    dplyr::summarise(log_mean = mean(log(value)), n = dplyr::n(), .groups = "drop")
  expected <- dplyr::bind_rows(locations, floras) |>
    dplyr::group_by(taxon_name, unit) |>
    dplyr::summarise(value = exp(mean(log_mean)), n_records = sum(n), .groups = "drop") |>
    dplyr::arrange(taxon_name, unit)

  expect_equal(means$taxon_name, expected$taxon_name)
  expect_equal(means$value, expected$value)
  expect_equal(means$n_records, expected$n_records)
})

test_that("`by` takes a context property from the relational database", {
  database <- austraits_lite
  property <- "sampling season"
  expect_true(property %in% database$contexts$context_property)

  means <- summarise_trait_means(database, by = property)
  expect_true(property %in% names(means))
  expect_gt(dplyr::n_distinct(means[[property]], na.rm = TRUE), 1)
  # grouping only splits the records: the same number are used
  ungrouped <- summarise_trait_means(database)
  expect_equal(sum(means$n_records), sum(ungrouped$n_records))

  expect_error(summarise_trait_means(database, by = "no such property"), "neither")

  # a property whose name has characters a regular expression would read, as
  # AusTraits' "DBH (cm) [mean (min-max)]" does
  renamed <- database
  renamed$contexts$context_property[renamed$contexts$context_property == property] <- "season (sampled) [n+1]"
  by_renamed <- summarise_trait_means(renamed, by = "season (sampled) [n+1]")
  expect_equal(unname(by_renamed[["season (sampled) [n+1]"]]), unname(means[[property]]))

  # a database whose traits table already has its contexts joined in
  prejoined <- join_context_properties(database, format = "many_columns", include_description = FALSE)
  expect_equal(summarise_trait_means(prejoined, by = property)[[property]], means[[property]])
  # a flat table has its context properties joined into one column
  expect_error(summarise_trait_means(flatten_database(database), by = property), "no column")
})

test_that("something that is not a database is refused", {
  expect_error(summarise_trait_means(list(a = 1)))
  expect_error(summarise_trait_means(data.frame(trait_name = "x", dataset_id = "D1")), "lacks")
})
