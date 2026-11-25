# Pivot long format traits table into wide format

Function to "widen" long format data ("tidy data").

Data in a traits.build databases' traits table are organised in a long
format where each trait measurement is on a different row and
measurement metadata is recorded in other columns. Multiple traits may
be measured as part of a single observation and this function pivots the
data wider, such that each trait is its own column. *Note that if two
trait measurements have the same observation_id but different value
types (min, mean, mode, etc.) these will be on separate rows.*

To pivot its output back into long format, use
[`tidyr::pivot_longer()`](https://tidyr.tidyverse.org/reference/pivot_longer.html)
([`trait_pivot_longer()`](https://traitecoevo.github.io/traits.use/reference/trait_pivot_longer.md)
is deprecated).

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
#>    dataset_id   source_id    taxon_name    observation_id trait_name value unit 
#>    <chr>        <chr>        <chr>         <chr>          <chr>      <chr> <chr>
#>  1 Falster_2003 Falster_2003 Acacia flori… 01             leaf_area  142   mm2  
#>  2 Falster_2003 Falster_2003 Acacia flori… 01             leaf_incl… 57    deg  
#>  3 Falster_2003 Falster_2003 Acacia flori… 02             leaf_comp… simp… NA   
#>  4 Falster_2003 Falster_2003 Acacia myrti… 03             leaf_area  319   mm2  
#>  5 Falster_2003 Falster_2003 Acacia myrti… 03             leaf_incl… 66.1  deg  
#>  6 Falster_2003 Falster_2003 Acacia myrti… 04             leaf_comp… simp… NA   
#>  7 Falster_2003 Falster_2003 Acacia suave… 05             leaf_area  562   mm2  
#>  8 Falster_2003 Falster_2003 Acacia suave… 05             leaf_incl… 71.7  deg  
#>  9 Falster_2003 Falster_2003 Acacia suave… 06             leaf_comp… simp… NA   
#> 10 Falster_2003 Falster_2003 Angophora hi… 07             leaf_area  1590  mm2  
#> # ℹ 104 more rows
#> # ℹ 19 more variables: entity_type <chr>, value_type <chr>,
#> #   basis_of_value <chr>, replicates <chr>, basis_of_record <chr>,
#> #   life_stage <chr>, population_id <chr>, individual_id <chr>,
#> #   repeat_measurements_id <chr>, temporal_context_id <chr>, location_id <chr>,
#> #   entity_context_id <chr>, plot_context_id <chr>, treatment_context_id <chr>,
#> #   collection_date <chr>, measurement_remarks <chr>, method_id <chr>, …
traits_wide <- trait_pivot_wider(data)
traits_wide # wide format
#> # A tibble: 76 × 22
#>    dataset_id   source_id  taxon_name observation_id entity_type basis_of_record
#>    <chr>        <chr>      <chr>      <chr>          <chr>       <chr>          
#>  1 Falster_2003 Falster_2… Acacia fl… 01             population  field          
#>  2 Falster_2003 Falster_2… Acacia fl… 02             species     field          
#>  3 Falster_2003 Falster_2… Acacia my… 03             population  field          
#>  4 Falster_2003 Falster_2… Acacia my… 04             species     field          
#>  5 Falster_2003 Falster_2… Acacia su… 05             population  field          
#>  6 Falster_2003 Falster_2… Acacia su… 06             species     field          
#>  7 Falster_2003 Falster_2… Angophora… 07             population  field          
#>  8 Falster_2003 Falster_2… Angophora… 08             species     field          
#>  9 Falster_2003 Falster_2… Astrotric… 09             population  field          
#> 10 Falster_2003 Falster_2… Astrotric… 10             species     field          
#> # ℹ 66 more rows
#> # ℹ 16 more variables: life_stage <chr>, population_id <chr>,
#> #   individual_id <chr>, repeat_measurements_id <chr>,
#> #   temporal_context_id <chr>, location_id <chr>, entity_context_id <chr>,
#> #   plot_context_id <chr>, treatment_context_id <chr>, collection_date <chr>,
#> #   method_id <chr>, method_context_id <chr>, original_name <chr>,
#> #   leaf_area <chr>, leaf_inclination_angle <chr>, leaf_compoundness <chr>
```
