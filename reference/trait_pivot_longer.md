# Pivot wide format traits table into long format

**\[deprecated\]** trait_pivot_longer "gathers" wide format data into a
"tidy" format This function converts the data into long format where
observations are on different rows and the type of observation is
denoted by trait name. In other words, trait_pivot_longer reverts the
actions of trait_pivot_wider

## Usage

``` r
trait_pivot_longer(wide_data)
```

## Arguments

- wide_data:

  output from trait_pivot_wider.

## Value

A tibble in long format

A tibble in long format

## Details

- If `bind_trait_values` was applied prior to `trait_pivot_wider` for
  AusTraits \<= v3.0.2, `trait_pivot_longer` will return a tibble with
  fewer observations than the original traits table.

- For AusTraits version \>3.0.2, `trait_pivot_longer` will return a
  tibble with fewer columns than that original traits table

  - The excluded columns include: "unit", "replicates",
    "measurement_remarks", "basis_of_record", "basis_of_value"

This function reverts the actions of the function
traits.use::trait_pivot_wider.

It begins with a derivation of a traits.build traits table, where
multiple measurements that comprise a single observation are displayed
on a single row,with a column for each trait. It then converts the table
into long format where measurements of multiple traits that comprise a
single observation are on different rows and a column specifying the
trait names is added.

`trait_pivot_longer` has been developed to pivot the traits table for a
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
