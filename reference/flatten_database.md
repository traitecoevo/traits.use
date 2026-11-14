# Create combined traits.build table

Create a single database output that merges together the information in
all relational tables within a traits.build database. Trait measurements
are still output in long format (1 row per trait value), but all
measurement-related metadata (methods, location properties, context
properties, contributors, references) are now included as additional
columns in a single table. References are joined by
[`join_sources()`](https://traitecoevo.github.io/traits.use/reference/join_sources.md),
so `vars$sources` selects among its columns, and the reference columns
of the methods table are not repeated.

## Usage

``` r
flatten_database(database, format, vars, include_description)
```

## Arguments

- database:

  traits.build database (list object)

- format:

  A parameter for the locations, contexts and data contributors tables
  specifying how data are packed. All three can be formatted as a single
  compacted column(s) will have a human readable column
  ("single_column_pretty") or using json ("single_column_json") syntax.
  For location properties or context properties there is also the option
  to add each `location_property` or `context_property` to the traits
  table as its own column ("many_columns"); the contributors column
  defaults to "single_column_pretty" when this option is selected.

- vars:

  List specifying which columns or properties to include from each
  table. The detail is for all columns/properties to be included.

- include_description:

  A logical indicating whether to include (TRUE) or omit (FALSE) the
  context_property descriptions; defaults to TRUE.

## Value

A table combining information in 8 traits.build relational tables:
traits, locations, contexts, methods, taxa, taxonomic_updates,
contributors, and identifiers

## Examples

``` r
flat <- austraits_lite %>%
  extract_dataset("Falster_2003") %>%
  flatten_database()
flat
#> # A tibble: 114 × 66
#>    dataset_id   taxon_name     observation_id trait_name value unit  entity_type
#>    <chr>        <chr>          <chr>          <chr>      <chr> <chr> <chr>      
#>  1 Falster_2003 Acacia florib… 01             leaf_area  142   mm2   population 
#>  2 Falster_2003 Acacia florib… 01             leaf_incl… 57    deg   population 
#>  3 Falster_2003 Acacia florib… 02             leaf_comp… simp… NA    species    
#>  4 Falster_2003 Acacia myrtif… 03             leaf_area  319   mm2   population 
#>  5 Falster_2003 Acacia myrtif… 03             leaf_incl… 66.1  deg   population 
#>  6 Falster_2003 Acacia myrtif… 04             leaf_comp… simp… NA    species    
#>  7 Falster_2003 Acacia suaveo… 05             leaf_area  562   mm2   population 
#>  8 Falster_2003 Acacia suaveo… 05             leaf_incl… 71.7  deg   population 
#>  9 Falster_2003 Acacia suaveo… 06             leaf_comp… simp… NA    species    
#> 10 Falster_2003 Angophora his… 07             leaf_area  1590  mm2   population 
#> # ℹ 104 more rows
#> # ℹ 59 more variables: value_type <chr>, basis_of_value <chr>,
#> #   replicates <chr>, basis_of_record <chr>, life_stage <chr>,
#> #   population_id <chr>, individual_id <chr>, repeat_measurements_id <chr>,
#> #   temporal_context_id <chr>, source_id <chr>, location_id <chr>,
#> #   entity_context_id <chr>, plot_context_id <chr>, treatment_context_id <chr>,
#> #   collection_date <chr>, measurement_remarks <chr>, method_id <chr>, …
```
