# Pivot wide format traits table into long format

**\[deprecated\]** `trait_pivot_longer()` is deprecated, and gives an
error. To pivot the output of
[`trait_pivot_wider()`](https://traitecoevo.github.io/traits.use/reference/trait_pivot_wider.md)
back into long format, use
[`tidyr::pivot_longer()`](https://tidyr.tidyverse.org/reference/pivot_longer.html),
as in the example.

## Usage

``` r
trait_pivot_longer(wide_data)
```

## Arguments

- wide_data:

  output from trait_pivot_wider.

## Value

None: the function stops with an error.

## Author

Daniel Falster - daniel.falster@unsw.edu.au

Fonti Kar - fonti.kar@unsw.edu.au

## Examples

``` r
# trait_pivot_longer() is deprecated, and gives an error. Pivot the output
# of trait_pivot_wider() back with tidyr::pivot_longer() instead:
data <- austraits_lite$traits %>%
  dplyr::filter(dataset_id == "Falster_2003")
traits_wide <- trait_pivot_wider(data)
tidyr::pivot_longer(traits_wide, cols = dplyr::all_of(unique(data$trait_name)),
  names_to = "trait_name", values_to = "value", values_drop_na = TRUE)
#> # A tibble: 114 × 21
#>    dataset_id   source_id  taxon_name observation_id entity_type basis_of_record
#>    <chr>        <chr>      <chr>      <chr>          <chr>       <chr>          
#>  1 Falster_2003 Falster_2… Acacia fl… 01             population  field          
#>  2 Falster_2003 Falster_2… Acacia fl… 01             population  field          
#>  3 Falster_2003 Falster_2… Acacia fl… 02             species     field          
#>  4 Falster_2003 Falster_2… Acacia my… 03             population  field          
#>  5 Falster_2003 Falster_2… Acacia my… 03             population  field          
#>  6 Falster_2003 Falster_2… Acacia my… 04             species     field          
#>  7 Falster_2003 Falster_2… Acacia su… 05             population  field          
#>  8 Falster_2003 Falster_2… Acacia su… 05             population  field          
#>  9 Falster_2003 Falster_2… Acacia su… 06             species     field          
#> 10 Falster_2003 Falster_2… Angophora… 07             population  field          
#> # ℹ 104 more rows
#> # ℹ 15 more variables: life_stage <chr>, population_id <chr>,
#> #   individual_id <chr>, repeat_measurements_id <chr>,
#> #   temporal_context_id <chr>, location_id <chr>, entity_context_id <chr>,
#> #   plot_context_id <chr>, treatment_context_id <chr>, collection_date <chr>,
#> #   method_id <chr>, method_context_id <chr>, original_name <chr>,
#> #   trait_name <chr>, value <chr>
```
