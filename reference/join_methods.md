# Joining methodological information to traits table

Function to merge metadata from the methods table of a traits.build
database into the core traits table.

## Usage

``` r
join_methods(database, vars = c("methods"))
```

## Arguments

- database:

  traits.build database (list object)

- vars:

  Columns from the taxa table to be joined to the traits table,
  defaulting to c("methods").

## Value

traits.build list object, but with additional fields (columns) for the
specified variables from the methods table appended to the traits table.

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
(austraits_lite %>% extract_dataset("Falster_2003") %>% join_methods())$traits %>%
  dplyr::select(trait_name, value, methods)
#> # A tibble: 114 × 3
#>    trait_name             value  methods                                        
#>    <chr>                  <chr>  <chr>                                          
#>  1 leaf_area              142    For each individual, architectural information…
#>  2 leaf_inclination_angle 57     For each individual, architectural information…
#>  3 leaf_compoundness      simple expert opinion                                 
#>  4 leaf_area              319    For each individual, architectural information…
#>  5 leaf_inclination_angle 66.1   For each individual, architectural information…
#>  6 leaf_compoundness      simple expert opinion                                 
#>  7 leaf_area              562    For each individual, architectural information…
#>  8 leaf_inclination_angle 71.7   For each individual, architectural information…
#>  9 leaf_compoundness      simple expert opinion                                 
#> 10 leaf_area              1590   For each individual, architectural information…
#> # ℹ 104 more rows
```
