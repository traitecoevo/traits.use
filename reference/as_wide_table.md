# Create a single wide table from a traits.build data object

Create a single wide table from a traits.build data object

## Usage

``` r
as_wide_table(database)
```

## Arguments

- database:

  traits.build database (list object)

## Value

A single wide table with collapsed contexts and locations text and with
some cols renamed for alignment with other resources

## Examples

``` r
austraits_lite %>%
  extract_dataset("Falster_2003") %>%
  as_wide_table()
#> # A tibble: 114 × 59
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
#> # ℹ 52 more variables: value_type <chr>, basis_of_value <chr>,
#> #   replicates <chr>, basis_of_record <chr>, life_stage <chr>,
#> #   population_id <chr>, individual_id <chr>, repeat_measurements_id <chr>,
#> #   temporal_context_id <chr>, source_id <chr>, location_id <chr>,
#> #   entity_context_id <chr>, plot_context_id <chr>, treatment_context_id <chr>,
#> #   collection_date <chr>, measurement_remarks <chr>, method_id <chr>, …
```
