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
some cols renamed for alignment with other resources. The most-used
columns come first; the other columns of the traits, methods and taxa
tables follow them.

## Examples

``` r
austraits_lite %>%
  extract_dataset("Falster_2003") %>%
  as_wide_table()
#> # A tibble: 114 × 59
#>    dataset_id   observation_id trait_name     taxon_name value unit  entity_type
#>    <chr>        <chr>          <chr>          <chr>      <chr> <chr> <chr>      
#>  1 Falster_2003 01             leaf_area      Acacia fl… 142   mm2   population 
#>  2 Falster_2003 01             leaf_inclinat… Acacia fl… 57    deg   population 
#>  3 Falster_2003 02             leaf_compound… Acacia fl… simp… NA    species    
#>  4 Falster_2003 03             leaf_area      Acacia my… 319   mm2   population 
#>  5 Falster_2003 03             leaf_inclinat… Acacia my… 66.1  deg   population 
#>  6 Falster_2003 04             leaf_compound… Acacia my… simp… NA    species    
#>  7 Falster_2003 05             leaf_area      Acacia su… 562   mm2   population 
#>  8 Falster_2003 05             leaf_inclinat… Acacia su… 71.7  deg   population 
#>  9 Falster_2003 06             leaf_compound… Acacia su… simp… NA    species    
#> 10 Falster_2003 07             leaf_area      Angophora… 1590  mm2   population 
#> # ℹ 104 more rows
#> # ℹ 52 more variables: population_id <chr>, individual_id <chr>,
#> #   value_type <chr>, basis_of_value <chr>, replicates <chr>,
#> #   collection_date <chr>, basis_of_record <chr>, life_stage <chr>,
#> #   sampling_strategy <chr>, treatment_context_id <chr>,
#> #   temporal_context_id <chr>, `latitude (deg)` <chr>, `longitude (deg)` <chr>,
#> #   location <chr>, plot_context_id <chr>, context <chr>, methods <chr>, …
```
