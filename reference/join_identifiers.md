# Joining identifiers to traits table

Function to merge metadata from the identifiers table of a traits.build
database into the core traits table.

## Usage

``` r
join_identifiers(database, format = "single_column_pretty", vars = "all")
```

## Arguments

- database:

  traits.build database (list object)

- format:

  Specifies whether metadata from the identifiers is output in a human
  readable format ("single_column_pretty"; default), with each location
  property added as a separate column ("many_columns") or using json
  syntax ("single_column_json").

- vars:

  Identifier types for which data is to be appended to the traits table,
  defaulting to all identifier types (vars = "all").

## Value

traits.build list object, but with identifiers from the identifiers
table appended to the traits table.

## Details

the `join_` functions have been developed to join relational tables for
databases built using the traits.build workflow. Learn more at:
<https://github.com/traitecoevo/traits.build> &
<https://github.com/traitecoevo/traits.build-book>

Note to AusTraits users:

- This function works with AusTraits version \>=7.0.0 (2025 releases)

- For AusTraits versions \<= 4.2.0 (up to Sept 2023 release) see
  <https://github.com/traitecoevo/austraits> for how to install old
  versions of the package or download a newer version of the database.

## Examples

``` r
# Schulze_2014 records the tree each observation was taken from
(austraits_lite %>% extract_dataset("Schulze_2014") %>%
  join_identifiers(format = "single_column_pretty", vars = "all"))$traits %>%
  dplyr::select(observation_id, trait_name, value, identifier_types)
#> # A tibble: 2,473 × 4
#>    observation_id trait_name                        value       identifier_types
#>    <chr>          <chr>                             <chr>       <chr>           
#>  1 001            leaf_area                         12.201      catalogNumber==…
#>  2 002            leaf_type                         scale       catalogNumber==…
#>  3 002            plant_photosynthetic_organ        cladode     catalogNumber==…
#>  4 003            leaf_area                         17.651      catalogNumber==…
#>  5 004            plant_physical_defence_structures sharp_poin… catalogNumber==…
#>  6 005            leaf_type                         needle      catalogNumber==…
#>  7 005            plant_photosynthetic_organ        leaf        catalogNumber==…
#>  8 006            leaf_area                         73.905      catalogNumber==…
#>  9 007            plant_photosynthetic_organ        leaf        catalogNumber==…
#> 10 008            leaf_area                         37.2766667  catalogNumber==…
#> # ℹ 2,463 more rows
```
