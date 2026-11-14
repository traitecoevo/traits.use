# Joining location properties to traits table

Function to merge metadata from the locations table of a traits.build
database into the core traits table.

## Usage

``` r
join_location_properties(
  database,
  format = "single_column_pretty",
  vars = "all"
)
```

## Arguments

- database:

  traits.build database (list object)

- format:

  Specifies whether metadata from the locations is output in a human
  readable format ("single_column_pretty"; default), with each location
  property added as a separate column ("many_columns") or using json
  syntax ("single_column_json").

- vars:

  Location properties for which data is to be appended to the traits
  table, defaulting to all location properties (vars = "all").

## Value

traits.build list object, but location properties from the locations
table appended to the traits table.

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
(austraits_lite %>% extract_dataset("Falster_2003") %>%
  join_location_properties(format = "single_column_pretty", vars = "all"))$traits %>%
  dplyr::select(trait_name, value, location_name, location_properties)
#> # A tibble: 114 × 4
#>    trait_name             value  location_name               location_properties
#>    <chr>                  <chr>  <chr>                       <chr>              
#>  1 leaf_area              142    Ku-ring-gai Chase National… description==fire-…
#>  2 leaf_inclination_angle 57     Ku-ring-gai Chase National… description==fire-…
#>  3 leaf_compoundness      simple NA                          NA                 
#>  4 leaf_area              319    Ku-ring-gai Chase National… description==fire-…
#>  5 leaf_inclination_angle 66.1   Ku-ring-gai Chase National… description==fire-…
#>  6 leaf_compoundness      simple NA                          NA                 
#>  7 leaf_area              562    Ku-ring-gai Chase National… description==fire-…
#>  8 leaf_inclination_angle 71.7   Ku-ring-gai Chase National… description==fire-…
#>  9 leaf_compoundness      simple NA                          NA                 
#> 10 leaf_area              1590   Ku-ring-gai Chase National… description==fire-…
#> # ℹ 104 more rows
```
