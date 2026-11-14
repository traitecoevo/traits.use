# Pivot long format traits table into wide format

Function to "widen" long format data ("tidy data").

Data in a traits.build databases' traits table are organised in a long
format where each trait measurement is on a different row and
measurement metadata is recorded in other columns. Multiple traits may
be measured as part of a single observation and this function pivots the
data wider, such that each trait is its own column. *Note that if two
trait measurements have the same observation_id but different value
types (min, mean, mode, etc.) these will be on separate rows.*

The function traits.use::trait_pivot_longer reverts the actions of this
function.

## Usage

``` r
trait_pivot_wider(database)
```

## Arguments

- database:

  The traits tibble from a traits.build database

## Value

traits.build traits table in wide format

## Details

\`trait_pivot_wider“ has been developed to pivot the traits table for a
database build using the traits.build workflow. Learn more at:
<https://github.com/traitecoevo/traits.build> &
<https://github.com/traitecoevo/traits.build-book>

Note to AusTraits users:

- This function works with AusTraits version \>= 5.0.0 (from Nov 2023
  release)

- For AusTraits versions \<= 4.2.0 (up to Sept 2023 release) see
  <https://github.com/traitecoevo/austraits> for how to install old
  versions of the package or download a newer version of the database.

## Author

Daniel Falster - daniel.falster@unsw.edu.au

## Examples

``` r
data <- austraits_lite$traits %>% dplyr::filter(dataset_id == "Falster_2003")
data # long format
#> # A tibble: 114 × 26
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
#> # ℹ 19 more variables: value_type <chr>, basis_of_value <chr>,
#> #   replicates <chr>, basis_of_record <chr>, life_stage <chr>,
#> #   population_id <chr>, individual_id <chr>, repeat_measurements_id <chr>,
#> #   temporal_context_id <chr>, source_id <chr>, location_id <chr>,
#> #   entity_context_id <chr>, plot_context_id <chr>, treatment_context_id <chr>,
#> #   collection_date <chr>, measurement_remarks <chr>, method_id <chr>, …
traits_wide <- trait_pivot_wider(data)
traits_wide # wide format
#> # A tibble: 76 × 22
#>    dataset_id   taxon_name observation_id entity_type basis_of_record life_stage
#>    <chr>        <chr>      <chr>          <chr>       <chr>           <chr>     
#>  1 Falster_2003 Acacia fl… 01             population  field           adult     
#>  2 Falster_2003 Acacia fl… 02             species     field           adult     
#>  3 Falster_2003 Acacia my… 03             population  field           adult     
#>  4 Falster_2003 Acacia my… 04             species     field           adult     
#>  5 Falster_2003 Acacia su… 05             population  field           adult     
#>  6 Falster_2003 Acacia su… 06             species     field           adult     
#>  7 Falster_2003 Angophora… 07             population  field           adult     
#>  8 Falster_2003 Angophora… 08             species     field           adult     
#>  9 Falster_2003 Astrotric… 09             population  field           adult     
#> 10 Falster_2003 Astrotric… 10             species     field           adult     
#> # ℹ 66 more rows
#> # ℹ 16 more variables: population_id <chr>, individual_id <chr>,
#> #   repeat_measurements_id <chr>, temporal_context_id <chr>, source_id <chr>,
#> #   location_id <chr>, entity_context_id <chr>, plot_context_id <chr>,
#> #   treatment_context_id <chr>, collection_date <chr>, method_id <chr>,
#> #   method_context_id <chr>, original_name <chr>, leaf_area <chr>,
#> #   leaf_inclination_angle <chr>, leaf_compoundness <chr>
```
