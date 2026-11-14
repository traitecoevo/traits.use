# Joining location coordinates to traits table

Function to merge geographic coordinates (latitude/longitude) stored in
the locations table of a traits.build database into the core traits
table.

## Usage

``` r
join_location_coordinates(database)
```

## Arguments

- database:

  traits.build database (list object)

## Value

traits.build list object, but with additional fields (columns) for
latitude and longitude appended to `traits` dataframe

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
(austraits_lite %>% extract_dataset("Falster_2003") %>% join_location_coordinates())$traits %>%
  dplyr::select(observation_id, trait_name, value, location_name,
    `latitude (deg)`, `longitude (deg)`)
#> # A tibble: 114 × 6
#>    observation_id trait_name             value  location_name   `latitude (deg)`
#>    <chr>          <chr>                  <chr>  <chr>           <chr>           
#>  1 01             leaf_area              142    Ku-ring-gai Ch… -33.57889       
#>  2 01             leaf_inclination_angle 57     Ku-ring-gai Ch… -33.57889       
#>  3 02             leaf_compoundness      simple NA              NA              
#>  4 03             leaf_area              319    Ku-ring-gai Ch… -33.69389       
#>  5 03             leaf_inclination_angle 66.1   Ku-ring-gai Ch… -33.69389       
#>  6 04             leaf_compoundness      simple NA              NA              
#>  7 05             leaf_area              562    Ku-ring-gai Ch… -33.69389       
#>  8 05             leaf_inclination_angle 71.7   Ku-ring-gai Ch… -33.69389       
#>  9 06             leaf_compoundness      simple NA              NA              
#> 10 07             leaf_area              1590   Ku-ring-gai Ch… -33.69389       
#> # ℹ 104 more rows
#> # ℹ 1 more variable: `longitude (deg)` <chr>
```
