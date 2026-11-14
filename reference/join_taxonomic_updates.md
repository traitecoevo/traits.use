# Joining taxonomic updates information to traits table

Function to merge metadata from the taxonomic_updates table of a
traits.build database into the core traits table.

## Usage

``` r
join_taxonomic_updates(database, vars = c("aligned_name"))
```

## Arguments

- database:

  traits.build database (list object)

- vars:

  Columns from the taxa table to be joined to the traits table,
  defaulting to c("aligned_name").

## Value

traits.build list object, but with additional fields (columns) for the
specified variables from the taxonomic_updates table appended to the
traits table.

## Details

the `join_` functions have been developed to join relational tables for
databases built using the traits.build workflow. Learn more at:
<https://github.com/traitecoevo/traits.build> &
<https://github.com/traitecoevo/traits.build-book>

Note to AusTraits users:

- This function works with AusTraits version \>= 5.0.0 (from Nov 2023
  release)

- For AusTraits versions \<= 4.2.0 (up to Sept 2023 release) see
  <https://github.com/traitecoevo/austraits> for how to install old
  versions of the package or download a newer version of the database.

## Examples

``` r
# Append taxonomic update details
(austraits_lite %>% extract_dataset("Falster_2003") %>% join_taxonomic_updates())$traits
#> # A tibble: 114 × 27
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
#> # ℹ 20 more variables: value_type <chr>, basis_of_value <chr>,
#> #   replicates <chr>, basis_of_record <chr>, life_stage <chr>,
#> #   population_id <chr>, individual_id <chr>, repeat_measurements_id <chr>,
#> #   temporal_context_id <chr>, source_id <chr>, location_id <chr>,
#> #   entity_context_id <chr>, plot_context_id <chr>, treatment_context_id <chr>,
#> #   collection_date <chr>, measurement_remarks <chr>, method_id <chr>, …
```
