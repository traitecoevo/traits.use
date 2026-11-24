#' Summarise each taxon's trait values: observed means and most frequent values
#'
#' @description
#' One row per taxon and trait, computed directly from the records, with no
#' model: for a numeric trait, the **observed mean**, a geometric mean, or an
#' arithmetic mean for a trait on a signed scale; for a categorical trait, the
#' most frequent value and the count of every value.
#' Works on a whole database, on any subset of one made with the `extract_*()`
#' functions (the taxa of one family, the records from one state), and on a
#' table made by [flatten_database()].
#'
#' @details
#' **Numeric traits.** Records are first summarised in groups, and the taxon's
#' value is the mean of the groups, each counting once whatever its number of
#' records, so a study that measured many individuals at one site counts once
#' for that site.
#'
#' - Records with `value_type` raw, mean or median are grouped by dataset and
#'   location. They are used whatever their basis of record or life stage.
#' - Minimum and maximum records whose `basis_of_record` is
#'   `preserved_specimen` or `literature` (floras) are grouped by observation;
#'   a flora's range gives one midpoint. Other minimum and maximum records are
#'   not used.
#' - A dataset named in `value_type_rules` contributes the value types given
#'   there instead, grouped by dataset and location.
#'
#' Everything is done on the log scale: a group's value is the geometric mean
#' of its records (for a flora range, the geometric midpoint,
#' `sqrt(minimum * maximum)`, or the lone bound if only one is given), and
#' `value` is the geometric mean of the groups. Traits are treated as
#' log-normal, for which the geometric mean is the median. A geometric mean
#' needs positive values, so records with a zero or negative value are not
#' used. The arithmetic mean of the same groups is given alongside, in
#' `arithmetic_mean`.
#'
#' **Signed traits.** A trait whose values can be negative, such as a water
#' potential, a temperature or an isotope ratio, is not log-normal and has no
#' geometric mean. For such a trait `value` is the arithmetic mean of the same
#' groups (a flora range gives its arithmetic midpoint), every record is used,
#' including zeros and negative values, `method` is `"arithmetic"`, and
#' `log_value` and `sd_log` are empty. A trait is signed when its definition
#' allows values below zero (`allowed_values_min` in the database's
#' `definitions`). A flat table carries no definitions, so there a trait is
#' signed when any of its records is negative; summarise the relational
#' database to have the definitions decide, so that a subset whose records
#' all happen to be positive is treated as the whole database is.
#'
#' **Categorical traits.** A record listing several space-separated values
#' counts once for each. `value_mode` is the most frequent value, with tied
#' values joined by a space, and `value_count` lists every value with its
#' count. Traits recorded as one string per record, such as a `flowering_time`
#' of twelve letters, one per month, are summarised as whole strings.
#'
#' **Taxa.** With `roll_up = TRUE`, records of a subspecies, variety or form
#' are counted towards their species: the name up to its rank marker
#' (`subsp.`, `var.`, `f.`), so that *Mentha x piperita var. citrata* becomes
#' *Mentha x piperita*. Hybrid formulae and intergrades, such as *Acacia
#' trachycarpa x Acacia tumida var. pilbarensis*, belong to neither parent and
#' keep their own rows, as do genus-level names. Names without a rank marker,
#' as in zoological trinomials, are not rolled up.
#'
#' **Groups.** `by` splits each taxon's records further, giving one row per
#' taxon, group and trait: by a column of the traits table, such as
#' `"life_stage"`, or, given the database, by a context property, such as
#' `"sex"` in a database that records it as a context. Records without a
#' value for a `by` variable form a group of their own (`NA`).
#'
#' **How much evidence.** `n_records`, `n_datasets`, `n_locations`, `n_flora`
#' and `n_field` count what is behind each value, and `sd_log` is the spread
#' of the records on the log scale (empty for a signed trait). `reliability` is a provisional class from those counts:
#' `high` with at least 3 datasets and 10 records, `medium` with at least 2
#' datasets or 5 records, `low` otherwise.
#'
#' The observed mean does not adjust for where in a taxon's range, or under
#' what conditions, its records were collected.
#'
#' @param database a traits.build database (a list of tables), or a flat table
#'   from one: a table made by [flatten_database()], or a traits table.
#' @param traits names of the traits to summarise. The default, `NULL`, is
#'   every trait in `database`. A trait named here that has no records gives a
#'   warning.
#' @param by names of further variables to group by, as well as taxon and
#'   trait: columns of the traits table or, when `database` is the relational
#'   database, context properties. The default, `NULL`, is none.
#' @param roll_up logical: count the records of subspecies, varieties and forms
#'   towards their species? Default `TRUE`.
#' @param value_type_rules a data frame with columns `dataset_id` and
#'   `value_type`, one row per value type to use from a dataset in place of the
#'   default raw, mean and median, for a dataset that reports numeric values
#'   another way. For example, a dataset of specimen labels that gives one
#'   bound per specimen and no raw values would have a row for `minimum` and
#'   one for `maximum`, each bound then counting as an observation. The
#'   default, `NULL`, is no such datasets.
#'
#' @return A tibble with one row per taxon, `by` group and trait (and unit,
#'   for a numeric trait), ordered by those. [trait_means_dictionary()]
#'   defines its columns. The taxon columns (`taxon_rank`, `genus`, `family`,
#'   `establishment_means`, `taxon_id`) are those the database's taxa table
#'   has.
#' @seealso [trait_means_dictionary()] for the columns; [extract_data()],
#'   [extract_taxa()] and [extract_trait()] to subset a database first.
#' @export
#'
#' @examples
#' means <- summarise_trait_means(austraits_lite, traits = c("leaf_length", "leaf_phenology"))
#' means
#'
#' # One genus, split by life stage
#' austraits_lite |>
#'   extract_taxa(genus = "Acacia") |>
#'   summarise_trait_means(traits = "leaf_length", by = "life_stage")
summarise_trait_means <- function(database,
                                  traits = NULL,
                                  by = NULL,
                                  roll_up = TRUE,
                                  value_type_rules = NULL) {

  if (!check_compatibility(database, single_table_allowed = TRUE)) {
    function_not_supported(database)
  }

  value_type_rules <- trait_means_check_rules(value_type_rules)
  if (!is.null(by) && !is.character(by)) {
    cli::cli_abort("{.arg by} must be a character vector of variable names, or {.code NULL}.")
  }
  by <- unique(by)

  input <- trait_means_input(database, by)
  records <- input$records
  taxa <- input$taxa

  if (!is.null(traits)) {
    absent <- setdiff(traits, records$trait_name)
    if (length(absent) > 0) {
      cli::cli_warn(c(
        "!" = "No records of {length(absent)} trait{?s} in {.arg traits}: {.val {absent}}.",
        "i" = "Check the spelling against the database's trait names; {.fn lookup_trait} searches them."
      ))
    }
    records <- records[records$trait_name %in% traits, ]
  }

  # Roll infraspecific names up to their species
  details <- taxa
  if (isTRUE(roll_up)) {
    # Over every name the taxa table has, not only those of the traits asked
    # for, so a species' details do not depend on which traits are summarised
    names_in <- unique(c(taxa$taxon_name, records$taxon_name))
    rank <- if ("taxon_rank" %in% names(taxa)) taxa$taxon_rank[match(names_in, taxa$taxon_name)]
    species <- trait_means_roll_up(names_in, rank)
    rolled <- (species != names_in) %in% TRUE
    records$taxon_name <- species[match(records$taxon_name, names_in)]

    # A species takes from its infraspecific taxa what its own row of the taxa
    # table lacks, or all of it if it has no row: being a species, its genus
    # and its family. A species name outside the taxonomic reference has a
    # row with nothing in it, while its subspecies' rows are complete.
    from_infraspecific <- taxa[match(names_in[rolled], taxa$taxon_name), intersect(c("genus", "family"), names(taxa)), drop = FALSE]
    from_infraspecific$taxon_name <- species[rolled]
    if ("taxon_rank" %in% names(taxa)) {
      from_infraspecific$taxon_rank <- rep("species", nrow(from_infraspecific))
    }
    details <- dplyr::bind_rows(taxa, from_infraspecific)
    for (column in setdiff(names(from_infraspecific), "taxon_name")) {
      known <- !is.na(details[[column]])
      details[[column]] <- details[[column]][known][match(details$taxon_name, details$taxon_name[known])]
    }
  }
  details <- details[!duplicated(details$taxon_name), ]

  numeric <- trait_means_numeric(records[!is.na(records$unit), ], by, value_type_rules, input$signed)
  categorical <- trait_means_categorical(records[is.na(records$unit), ], by)

  taxon_columns <- setdiff(names(details), "taxon_name")
  columns <- trait_means_dictionary()$column
  columns <- c("taxon_name", by, setdiff(columns, c("taxon_name", setdiff(trait_means_taxon_columns, taxon_columns))))

  means <- dplyr::bind_rows(trait_means_template(), numeric, categorical)
  for (variable in setdiff(by, names(means))) {
    # an empty result: the column, of its type in the records
    means[[variable]] <- rep(records[[variable]][NA_integer_], nrow(means))
  }
  means$estimate_type <- rep("observed_mean", nrow(means))
  means$method[is.na(means$method)] <- "geometric"
  means$reliability <- trait_means_reliability(means$n_datasets, means$n_records)

  means <- dplyr::left_join(means, details, by = "taxon_name")
  means <- means[do.call(order, c(unname(as.list(means[c("taxon_name", by, "trait_name", "unit")])), method = "radix")), ]

  tibble::as_tibble(means[columns])
}

#' Columns of the table of trait means
#'
#' The columns [summarise_trait_means()] returns, in order, with a definition
#' of each, for writing beside a saved copy of the table. The `by` variables a
#' call adds follow `taxon_name` and are not listed, and a taxon column is in
#' the table only if the database's taxa table has it.
#'
#' @return A tibble with columns `column` and `definition`.
#' @seealso [summarise_trait_means()]
#' @export
#'
#' @examples
#' trait_means_dictionary()
trait_means_dictionary <- function() {
  tibble::tribble(
    ~column, ~definition,
    "taxon_name", "Taxon name as aligned in the database, with subspecies, varieties and forms rolled up to their species unless roll_up = FALSE. Genus-level names and hybrid formulae are kept as their own rows.",
    "trait_name", "Trait name.",
    "unit", "Unit of the numeric trait values; empty for categorical traits.",
    "estimate_type", "Always observed_mean: computed directly from the records, with no model.",
    "method", "geometric for a trait on a positive scale; arithmetic for a trait on a signed scale, whose definition allows values below zero (a water potential, a temperature, an isotope ratio), for which a geometric mean does not exist.",
    "value", "Numeric traits: the observed mean. With method geometric, a geometric mean: records are averaged on the log scale within each dataset x location, flora minimum and maximum bounds give a geometric midpoint per observation, and the value is exp(mean) over those groups, each group counting once; records with zero or negative values are not used. With method arithmetic, the arithmetic mean over the same groups, using every record.",
    "log_value", "Natural log of value; empty with method arithmetic.",
    "arithmetic_mean", "Arithmetic mean over the same groups and records (each group's arithmetic mean or midpoint, then their mean). With method geometric it is not the observed mean and is given for comparison; with method arithmetic it equals value.",
    "value_min", "Smallest record value used.",
    "value_max", "Largest record value used.",
    "n_records", "Number of records used.",
    "n_locations", "Numeric traits: number of distinct dataset x location groups.",
    "n_datasets", "Number of datasets contributing records.",
    "n_flora", "Numeric traits: number of minimum and maximum records from preserved specimens or the literature (floras) used.",
    "n_field", "Number of records used whose basis of record is field.",
    "sd_log", "Numeric traits: standard deviation of the natural log of the record values used; empty with a single record, or with method arithmetic.",
    "reliability", "Provisional class from the evidence behind the value: high (at least 3 datasets and 10 records), medium (at least 2 datasets or 5 records), low (otherwise). Thresholds are provisional.",
    "dataset_id", "Datasets contributing, sorted, joined by '; '. Each dataset's reference is in the database's sources table under the same key.",
    "source_id", "References the contributing records were taken from, sorted, joined by '; ': keys of the database's sources table. The same as dataset_id except for a dataset that compiles other studies, whose records name the study they came from. A record without a source_id, as in databases built before traits.build 2.3, counts its dataset as its source.",
    "type", "numerical or categorical.",
    "value_mode", "Categorical traits: the most frequent value; tied values are joined by a space.",
    "value_count", "Categorical traits: each value with the number of records carrying it, as 'value (n)' joined by '; '. A record listing several space-separated values counts once for each.",
    "taxon_rank", "Taxonomic rank of taxon_name; empty for a name the database's taxonomy does not rank.",
    "genus", "Genus.",
    "family", "Family.",
    "establishment_means", "Native, naturalised or both, where the database records it.",
    "taxon_id", "Identifier of the taxon in the database's taxonomic reference."
  )
}

# Taxon columns copied from the taxa table when it has them
trait_means_taxon_columns <- c("taxon_rank", "genus", "family", "establishment_means", "taxon_id")

# Columns of the traits table the method reads
trait_means_record_columns <- c(
  "dataset_id", "taxon_name", "observation_id", "trait_name", "value", "unit",
  "value_type", "basis_of_record", "location_id", "original_name"
)

# The records and the taxon details, from either format of a database
trait_means_input <- function(database, by, call = rlang::caller_env()) {

  clash <- intersect(by, c(trait_means_dictionary()$column, trait_means_record_columns))
  if (length(clash) > 0) {
    cli::cli_abort(c(
      "x" = "{.arg by} cannot include {.val {clash}}: the summary already uses {cli::qty(clash)}{?that column/those columns}.",
      "i" = "To summarise part of a database, subset it first with {.fn extract_data}, {.fn extract_dataset}, {.fn extract_taxa} or {.fn extract_trait}."
    ), call = call)
  }

  if (is_flat(database)) {

    records <- database
    missing <- setdiff(by, names(records))
    if (length(missing) > 0) {
      cli::cli_abort(c(
        "x" = "{.arg database} has no column {.val {missing}} to group by.",
        "i" = "A flat table can be grouped by its own columns. To group by a context property, pass the relational database."
      ), call = call)
    }
    taxa <- as.data.frame(records)[intersect(c("taxon_name", trait_means_taxon_columns), names(records))]
    taxa <- taxa[!duplicated(taxa$taxon_name), , drop = FALSE]

  } else {

    records <- database$traits

    # A `by` variable that is not a column of the traits table is a context
    # property: join each as its own column
    contexts <- setdiff(by, names(records))
    unknown <- setdiff(contexts, database$contexts$context_property)
    if (length(unknown) > 0) {
      cli::cli_abort(c(
        "x" = "{.arg by} names {.val {unknown}}, which {cli::qty(unknown)}{?is/are} neither {?a column/columns} of the traits table nor {?a context property/context properties} of this database.",
        "i" = "See {.code names(database$traits)} and {.code unique(database$contexts$context_property)}."
      ), call = call)
    }
    if (length(contexts) > 0) {
      # The columns `join_context_properties()` names "<category>: <property>",
      # one per category a property is recorded under. Matched by their exact
      # names, since a property name can hold brackets and other characters a
      # regular expression would read. A traits table that already has them
      # joined in is joined afresh, rather than given suffixed copies.
      contexts_used <- database$contexts[database$contexts$context_property %in% contexts, ]
      wanted <- unique(paste0(contexts_used$category, ": ", contexts_used$context_property))
      fresh <- database
      fresh$traits <- fresh$traits[setdiff(names(fresh$traits), wanted)]
      joined <- join_context_properties(
        fresh, format = "many_columns", vars = contexts, include_description = FALSE
      )$traits
      for (property in contexts) {
        columns <- intersect(
          paste0(unique(contexts_used$category[contexts_used$context_property == property]), ": ", property),
          names(joined)
        )
        records[[property]] <- if (length(columns) == 0) {
          rep(NA_character_, nrow(records))
        } else {
          do.call(dplyr::coalesce, unname(as.list(joined[columns])))
        }
      }
    }

    taxa <- as.data.frame(database$taxa)[intersect(c("taxon_name", trait_means_taxon_columns), names(database$taxa))]
    taxa <- taxa[!duplicated(taxa$taxon_name), , drop = FALSE]
  }

  missing <- setdiff(trait_means_record_columns, names(records))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "x" = "{.arg database} lacks {cli::qty(missing)}{?a column/columns} the summary needs: {.val {missing}}.",
      "i" = "Pass a traits.build database, its traits table, or a table made by {.fn flatten_database}."
    ), call = call)
  }

  # The reference each record was taken from. A database built before
  # traits.build 2.3 has no `source_id`, and a record collected in the
  # dataset's own study may leave it empty: the dataset is the source then.
  source_id <- if ("source_id" %in% names(records)) as.character(records$source_id) else rep(NA_character_, nrow(records))
  records <- tibble::as_tibble(as.data.frame(records)[c(trait_means_record_columns, by)])
  records$source_id <- dplyr::coalesce(source_id, records$dataset_id)
  records$value <- as.character(records$value)

  list(records = records, taxa = tibble::as_tibble(as.data.frame(taxa)),
       signed = trait_means_signed(database, records))
}

# Traits on a signed scale, which get an arithmetic mean: those whose
# definition allows values below zero, or, for a flat table, which carries no
# definitions, those with a negative record
trait_means_signed <- function(database, records) {
  if (!is_flat(database) && length(database$definitions) > 0) {
    minimum <- vapply(database$definitions, function(definition) {
      x <- suppressWarnings(as.numeric(definition$allowed_values_min))
      if (length(x) == 1) x else NA_real_
    }, numeric(1))
    return(names(minimum)[!is.na(minimum) & minimum < 0])
  }
  value <- suppressWarnings(as.numeric(records$value))
  unique(records$trait_name[!is.na(value) & value < 0 & !is.na(records$unit)])
}

trait_means_check_rules <- function(rules, call = rlang::caller_env()) {
  if (is.null(rules)) {
    return(data.frame(dataset_id = character(), value_type = character()))
  }
  if (!is.data.frame(rules) || !all(c("dataset_id", "value_type") %in% names(rules))) {
    cli::cli_abort(
      "{.arg value_type_rules} must be a data frame with columns {.field dataset_id} and {.field value_type}, or {.code NULL}.",
      call = call
    )
  }
  rules
}

# The species of each name: the name up to its rank marker, for a subspecies,
# variety or form that is not a hybrid formula or intergrade ("A x B var. c",
# "A - B subsp. c"). `rank` is `NULL` when the taxonomy is not known, and the
# name alone then decides.
trait_means_roll_up <- function(taxon_name, rank = NULL) {
  rank_marker <- "\\s(subsp|var|f|forma|nothosubsp|nothovar)\\.\\s.*$"
  hybrid_formula <- "\\s(x|-)\\s[A-Z]"

  infraspecific <- (grepl(rank_marker, taxon_name) & !grepl(hybrid_formula, taxon_name)) %in% TRUE
  if (!is.null(rank)) {
    infraspecific <- infraspecific & rank %in% c("subspecies", "variety", "form")
  }
  taxon_name <- as.character(taxon_name)
  taxon_name[infraspecific] <- sub(rank_marker, "", taxon_name[infraspecific])
  taxon_name
}

trait_means_reliability <- function(n_datasets, n_records) {
  dplyr::case_when(
    n_datasets >= 3 & n_records >= 10 ~ "high",
    n_datasets >= 2 | n_records >= 5 ~ "medium",
    TRUE ~ "low"
  )
}

# The result's columns with no rows, so that a database with no numeric
# traits, or no categorical ones, still gives every column
trait_means_template <- function() {
  template <- tibble::tibble(
    taxon_name = character(), trait_name = character(), unit = character(),
    method = character(),
    value = numeric(), log_value = numeric(), arithmetic_mean = numeric(),
    value_min = numeric(), value_max = numeric(),
    n_records = integer(), n_locations = integer(), n_datasets = integer(),
    n_flora = integer(), n_field = integer(), sd_log = numeric(),
    dataset_id = character(), source_id = character(), type = character(),
    value_mode = character(), value_count = character()
  )
  template
}

## The summaries below are computed with group indices and `rowsum()` rather
## than a grouped `dplyr::summarise()`: a database has several hundred
## thousand taxon x trait groups, and evaluating expressions group by group
## takes a hundred times as long.

# Group rows by all columns of `data`: the group of each row, the groups'
# values (sorted, in the C locale) and their number
trait_means_groups <- function(data) {
  grouped <- dplyr::group_by(data, dplyr::across(dplyr::everything()))
  list(
    id = dplyr::group_indices(grouped),
    keys = dplyr::ungroup(dplyr::group_keys(grouped)),
    n = dplyr::n_groups(grouped)
  )
}

# Sum of `x` within each of `n` groups
trait_means_sum <- function(x, id, n) {
  out <- numeric(n)
  sums <- rowsum(as.numeric(x), id, reorder = FALSE)
  out[as.integer(rownames(sums))] <- sums[, 1]
  out
}

# Paste together the values of `x` within each of `n` groups, in the order
# given. Most groups hold one value, which needs no pasting.
trait_means_collapse <- function(x, id, n, sep) {
  out <- rep(NA_character_, n)
  single <- tabulate(id, n)[id] == 1
  out[id[single]] <- x[single]
  if (any(!single)) {
    several <- split(x[!single], id[!single])
    out[as.integer(names(several))] <- vapply(several, paste, character(1), collapse = sep)
  }
  out
}

# The distinct keys (datasets, sources) of each group: their number, and the
# keys sorted and joined
trait_means_keys <- function(key, id, n) {
  pairs <- trait_means_groups(tibble::tibble(id = id, key = key))$keys
  list(
    n = tabulate(pairs$id, n),
    keys = trait_means_collapse(pairs$key, pairs$id, n, "; ")
  )
}

trait_means_numeric <- function(records, by, rules, signed = character()) {

  # A signed trait keeps every value; the others need positive ones
  records$value <- suppressWarnings(as.numeric(records$value))
  records <- records[!is.na(records$value) & (records$value > 0 | records$trait_name %in% signed), ]

  # Records summarised per dataset x location: raw, mean and median records,
  # and whatever the rules allow for the datasets they name. Bounds from
  # floras are summarised per observation.
  ruled <- records$dataset_id %in% rules$dataset_id
  location <-
    (ruled & paste(records$dataset_id, records$value_type) %in% paste(rules$dataset_id, rules$value_type)) |
    (!ruled & records$value_type %in% c("raw", "mean", "median"))
  flora <- !ruled &
    records$value_type %in% c("minimum", "maximum") &
    records$basis_of_record %in% c("preserved_specimen", "literature")

  records <- records[location | flora, ]
  flora <- flora[location | flora]
  if (nrow(records) == 0) {
    return(NULL)
  }
  # Logs of the positive-scale traits; empty for the signed ones
  log_value <- rep(NA_real_, nrow(records))
  positive <- !records$trait_name %in% signed
  log_value[positive] <- log(records$value[positive])

  taxa <- trait_means_groups(records[c("taxon_name", by, "trait_name", "unit")])

  # The groups whose values are averaged: a dataset's records at a location,
  # or one flora observation
  groups <- trait_means_groups(tibble::tibble(
    taxon = taxa$id,
    dataset_id = records$dataset_id,
    flora = flora,
    within = ifelse(flora, records$observation_id, records$location_id),
    name = ifelse(flora, records$original_name, NA_character_)
  ))
  size <- tabulate(groups$id, groups$n)
  group_log_mean <- trait_means_sum(log_value, groups$id, groups$n) / size
  group_mean <- trait_means_sum(records$value, groups$id, groups$n) / size

  taxon <- groups$keys$taxon
  n_groups <- tabulate(taxon, taxa$n)
  n_records <- tabulate(taxa$id, taxa$n)

  # Spread of the records, about each taxon's own mean of logs
  mean_log <- trait_means_sum(log_value, taxa$id, taxa$n) / n_records
  sum_squares <- trait_means_sum((log_value - mean_log[taxa$id])^2, taxa$id, taxa$n)
  sd_log <- ifelse(n_records > 1, sqrt(sum_squares / (n_records - 1)), NA_real_)

  # Smallest and largest record of each taxon: the first and last in order
  by_value <- order(taxa$id, records$value)
  ordered_id <- taxa$id[by_value]
  value_min <- records$value[by_value][!duplicated(ordered_id)]
  value_max <- records$value[by_value][!duplicated(ordered_id, fromLast = TRUE)]

  datasets <- trait_means_keys(records$dataset_id, taxa$id, taxa$n)
  sources <- trait_means_keys(records$source_id, taxa$id, taxa$n)
  log_mean <- trait_means_sum(group_log_mean, taxon, taxa$n) / n_groups
  arithmetic_mean <- trait_means_sum(group_mean, taxon, taxa$n) / n_groups
  arithmetic <- taxa$keys$trait_name %in% signed

  dplyr::bind_cols(
    taxa$keys,
    tibble::tibble(
      method = ifelse(arithmetic, "arithmetic", "geometric"),
      value = ifelse(arithmetic, arithmetic_mean, exp(log_mean)),
      log_value = ifelse(arithmetic, NA_real_, log_mean),
      arithmetic_mean = arithmetic_mean,
      value_min = value_min,
      value_max = value_max,
      n_records = n_records,
      n_locations = as.integer(trait_means_sum(!groups$keys$flora, taxon, taxa$n)),
      n_datasets = datasets$n,
      n_flora = as.integer(trait_means_sum(flora, taxa$id, taxa$n)),
      n_field = as.integer(trait_means_sum(records$basis_of_record %in% "field", taxa$id, taxa$n)),
      sd_log = ifelse(arithmetic, NA_real_, sd_log),
      dataset_id = datasets$keys,
      source_id = sources$keys,
      type = "numerical"
    )
  )
}

trait_means_categorical <- function(records, by) {

  if (nrow(records) == 0) {
    return(NULL)
  }

  taxa <- trait_means_groups(records[c("taxon_name", by, "trait_name")])

  # One row per value a record lists, each value once per record
  values <- stringr::str_split(records$value, " ")
  several <- lengths(values) > 1
  values[several] <- lapply(values[several], unique)
  listed <- tibble::tibble(taxon = rep(taxa$id, lengths(values)), value = unlist(values))
  listed <- listed[!is.na(listed$value) & listed$value != "", ]

  # Records carrying each value, in order of taxon then value
  counted <- trait_means_groups(listed)
  n <- tabulate(counted$id, counted$n)
  taxon <- counted$keys$taxon
  value <- counted$keys$value

  # The largest count of each taxon: the first in decreasing order
  by_count <- order(taxon, -n)
  largest <- integer(taxa$n)
  largest[taxon[by_count][!duplicated(taxon[by_count])]] <- n[by_count][!duplicated(taxon[by_count])]
  modal <- n == largest[taxon]

  datasets <- trait_means_keys(records$dataset_id, taxa$id, taxa$n)
  sources <- trait_means_keys(records$source_id, taxa$id, taxa$n)

  dplyr::bind_cols(
    taxa$keys,
    tibble::tibble(
      n_records = tabulate(taxa$id, taxa$n),
      n_datasets = datasets$n,
      n_field = as.integer(trait_means_sum(records$basis_of_record %in% "field", taxa$id, taxa$n)),
      dataset_id = datasets$keys,
      source_id = sources$keys,
      type = "categorical",
      value_mode = trait_means_collapse(value[modal], taxon[modal], taxa$n, " "),
      value_count = trait_means_collapse(paste0(value, " (", n, ")"), taxon, taxa$n, "; ")
    )
  )
}
