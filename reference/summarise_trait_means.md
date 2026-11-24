# Summarise each taxon's trait values: observed means and most frequent values

One row per taxon and trait, computed directly from the records, with no
model: for a numeric trait, the **observed mean**, a geometric mean, or
an arithmetic mean for a trait on a signed scale; for a categorical
trait, the most frequent value and the count of every value. Works on a
whole database, on any subset of one made with the `extract_*()`
functions (the taxa of one family, the records from one state), and on a
table made by
[`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md).

## Usage

``` r
summarise_trait_means(
  database,
  traits = NULL,
  by = NULL,
  collapse_to_species = TRUE,
  value_type_rules = NULL
)
```

## Arguments

- database:

  a traits.build database (a list of tables), or a flat table from one:
  a table made by
  [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md),
  or a traits table.

- traits:

  names of the traits to summarise. The default, `NULL`, is every trait
  in `database`. A trait named here that has no records gives a warning.

- by:

  names of further variables to group by, as well as taxon and trait:
  columns of the traits table or, when `database` is the relational
  database, context properties. The default, `NULL`, is none.

- collapse_to_species:

  logical: count the records of subspecies, varieties and forms towards
  their species? Default `TRUE`.

- value_type_rules:

  a data frame with columns `dataset_id` and `value_type`, one row per
  value type to use from a dataset in place of the default raw, mean and
  median, for a dataset that reports numeric values another way. For
  example, a dataset of specimen labels that gives one bound per
  specimen and no raw values would have a row for `minimum` and one for
  `maximum`, each bound then counting as an observation. The default,
  `NULL`, is no such datasets.

## Value

A tibble with one row per taxon, `by` group and trait (and unit, for a
numeric trait), ordered by those.
[`trait_means_dictionary()`](https://traitecoevo.github.io/traits.use/reference/trait_means_dictionary.md)
defines its columns. The taxon columns (`taxon_rank`, `genus`, `family`,
`establishment_means`, `taxon_id`) are those the database's taxa table
has.

## Details

**Numeric traits.** Records are first summarised in groups, and the
taxon's value is the mean of the groups, each counting once whatever its
number of records, so a study that measured many individuals at one site
counts once for that site.

- Records with `value_type` raw, mean or median are grouped by dataset
  and location. They are used whatever their basis of record or life
  stage.

- Minimum and maximum records whose `basis_of_record` is
  `preserved_specimen` or `literature` (floras) are grouped by
  observation; a flora's range gives one midpoint. Other minimum and
  maximum records are not used.

- A dataset named in `value_type_rules` contributes the value types
  given there instead, grouped by dataset and location.

Everything is done on the log scale: a group's value is the geometric
mean of its records (for a flora range, the geometric midpoint,
`sqrt(minimum * maximum)`, or the lone bound if only one is given), and
`value` is the geometric mean of the groups. Traits are treated as
log-normal, for which the geometric mean is the median. A geometric mean
needs positive values, so records with a zero or negative value are not
used. The arithmetic mean of the same groups is given alongside, in
`arithmetic_mean`.

**Signed traits.** A trait whose values can be negative, such as a water
potential, a temperature or an isotope ratio, is not log-normal and has
no geometric mean. For such a trait `value` is the arithmetic mean of
the same groups (a flora range gives its arithmetic midpoint), every
record is used, including zeros and negative values, `method` is
`"arithmetic"`, and `log_value` and `sd_log` are empty. A trait is
signed when its definition allows values below zero
(`allowed_values_min` in the database's `definitions`). A flat table
carries no definitions, so there a trait is signed when any of its
records is negative; summarise the relational database to have the
definitions decide, so that a subset whose records all happen to be
positive is treated as the whole database is.

**Categorical traits.** A record listing several space-separated values
counts once for each. `value_mode` is the most frequent value, with tied
values joined by a space, and `value_count` lists every value with its
count, and `method` is `"mode"`.

**Months.** A trait that records the months of something, such as
`flowering_time` or `fruiting_time`, holds a twelve-letter string of `y`
and `n` per record, one letter per month from January. Its records are
summarised month by month: `value_count` lists each month at least one
record marks, in calendar order, with the number of records marking it
(`"Sep (2); Oct (5); Nov (5)"`), so the months listed are those any
record gives; `value_mode` is a twelve-letter string marking the months
at least half the records give, and `method` is `"majority"`. A trait is
treated so when its definition's type is `monthly_presence`, or when
every one of its records is such a string (as in releases whose
definitions call these traits categorical).

**Taxa.** With `collapse_to_species = TRUE`, records of a subspecies,
variety or form are counted towards their species: the name up to its
rank marker (`subsp.`, `var.`, `f.`), so that *Mentha x piperita var.
citrata* becomes *Mentha x piperita*. Hybrid formulae and intergrades,
such as *Acacia trachycarpa x Acacia tumida var. pilbarensis*, belong to
neither parent and keep their own rows, as do genus-level names. Names
without a rank marker, as in zoological trinomials, are not collapsed.

**Groups.** `by` splits each taxon's records further, giving one row per
taxon, group and trait: by a column of the traits table, such as
`"life_stage"`, or, given the database, by a context property, such as
`"sex"` in a database that records it as a context. Records without a
value for a `by` variable form a group of their own (`NA`).

**How much evidence.** `n_records`, `n_datasets`, `n_locations`,
`n_flora` and `n_field` count what is behind each value, and `sd_log` is
the spread of the records on the log scale (empty for a signed trait).
`reliability` is a provisional class from those counts: `high` with at
least 3 datasets and 10 records, `medium` with at least 2 datasets or 5
records, `low` otherwise.

The observed mean does not adjust for where in a taxon's range, or under
what conditions, its records were collected.

## See also

[`trait_means_dictionary()`](https://traitecoevo.github.io/traits.use/reference/trait_means_dictionary.md)
for the columns;
[`extract_data()`](https://traitecoevo.github.io/traits.use/reference/extract_data.md),
[`extract_taxa()`](https://traitecoevo.github.io/traits.use/reference/extract_taxa.md)
and
[`extract_trait()`](https://traitecoevo.github.io/traits.use/reference/extract_trait.md)
to subset a database first.

## Examples

``` r
means <- summarise_trait_means(austraits_lite, traits = c("leaf_length", "leaf_phenology"))
means
#> # A tibble: 6,852 × 27
#>    taxon_name         trait_name     unit  estimate_type method  value log_value
#>    <chr>              <chr>          <chr> <chr>         <chr>   <dbl>     <dbl>
#>  1 Abroma molle       leaf_length    mm    observed_mean geomet… 122.       4.81
#>  2 Abroma molle       leaf_phenology NA    observed_mean mode     NA       NA   
#>  3 Abrophyllum ornans leaf_length    mm    observed_mean geomet…  99.5      4.60
#>  4 Abrophyllum ornans leaf_phenology NA    observed_mean mode     NA       NA   
#>  5 Abrus precatorius  leaf_length    mm    observed_mean geomet…  11.2      2.41
#>  6 Abrus precatorius  leaf_phenology NA    observed_mean mode     NA       NA   
#>  7 Abutilon auritum   leaf_length    mm    observed_mean geomet…  59.2      4.08
#>  8 Abutilon auritum   leaf_phenology NA    observed_mean mode     NA       NA   
#>  9 Abutilon hannii    leaf_length    mm    observed_mean geomet…  54.8      4.00
#> 10 Abutilon hannii    leaf_phenology NA    observed_mean mode     NA       NA   
#> # ℹ 6,842 more rows
#> # ℹ 20 more variables: arithmetic_mean <dbl>, value_min <dbl>, value_max <dbl>,
#> #   n_records <int>, n_locations <int>, n_datasets <int>, n_flora <int>,
#> #   n_field <int>, sd_log <dbl>, reliability <chr>, dataset_id <chr>,
#> #   source_id <chr>, type <chr>, value_mode <chr>, value_count <chr>,
#> #   taxon_rank <chr>, genus <chr>, family <chr>, establishment_means <chr>,
#> #   taxon_id <chr>

# One genus, split by life stage
austraits_lite |>
  extract_taxa(genus = "Acacia") |>
  summarise_trait_means(traits = "leaf_length", by = "life_stage")
#> # A tibble: 37 × 28
#>    taxon_name  life_stage trait_name unit  estimate_type method  value log_value
#>    <chr>       <chr>      <chr>      <chr> <chr>         <chr>   <dbl>     <dbl>
#>  1 Acacia aul… adult      leaf_leng… mm    observed_mean geome…  61.2       4.11
#>  2 Acacia aur… adult      leaf_leng… mm    observed_mean geome… 134.        4.90
#>  3 Acacia bak… adult      leaf_leng… mm    observed_mean geome…  70.7       4.26
#>  4 Acacia bin… adult      leaf_leng… mm    observed_mean geome…  91.7       4.52
#>  5 Acacia bla… adult      leaf_leng… mm    observed_mean geome…  92.2       4.52
#>  6 Acacia bra… adult      leaf_leng… mm    observed_mean geome… 138.        4.93
#>  7 Acacia cel… adult      leaf_leng… mm    observed_mean geome…  88.0       4.48
#>  8 Acacia chr… adult      leaf_leng… mm    observed_mean geome…   6.93      1.94
#>  9 Acacia cin… adult      leaf_leng… mm    observed_mean geome… 133.        4.89
#> 10 Acacia cra… adult      leaf_leng… mm    observed_mean geome… 147.        4.99
#> # ℹ 27 more rows
#> # ℹ 20 more variables: arithmetic_mean <dbl>, value_min <dbl>, value_max <dbl>,
#> #   n_records <int>, n_locations <int>, n_datasets <int>, n_flora <int>,
#> #   n_field <int>, sd_log <dbl>, reliability <chr>, dataset_id <chr>,
#> #   source_id <chr>, type <chr>, value_mode <chr>, value_count <chr>,
#> #   taxon_rank <chr>, genus <chr>, family <chr>, establishment_means <chr>,
#> #   taxon_id <chr>
```
