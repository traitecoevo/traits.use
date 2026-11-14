# Joining data contributor metadata to traits table

Function to merge metadata from the data contributors table of a
traits.build database into the core traits table.

## Usage

``` r
join_contributors(database, format = "single_column_pretty", vars = "all")
```

## Arguments

- database:

  traits.build database (list object)

- format:

  Specifies whether metadata from the contributors table is output in a
  human readable format ("single_column_pretty"; default) or using json
  syntax ("single_column_json").

- vars:

  Columns from the taxa table to be joined to the traits table,
  defaulting to all columns (vars = "all").

## Value

traits.build list object, but with additional fields (columns) for the
specified variables from the data contributors table appended to the
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
(austraits_lite %>% extract_dataset("Falster_2003") %>%
  join_contributors(format = "single_column_pretty",
    vars = c("last_name", "given_name", "ORCID")))$traits %>%
  dplyr::select(trait_name, value, data_contributors)
#> # A tibble: 114 × 3
#>    trait_name             value  data_contributors                              
#>    <chr>                  <chr>  <chr>                                          
#>  1 leaf_area              142    Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#>  2 leaf_inclination_angle 57     Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#>  3 leaf_compoundness      simple Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#>  4 leaf_area              319    Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#>  5 leaf_inclination_angle 66.1   Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#>  6 leaf_compoundness      simple Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#>  7 leaf_area              562    Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#>  8 leaf_inclination_angle 71.7   Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#>  9 leaf_compoundness      simple Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#> 10 leaf_area              1590   Falster, Daniel <<ORCID==0000-0002-9814-092X>>…
#> # ℹ 104 more rows
```
