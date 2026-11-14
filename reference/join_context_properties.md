# Joining context properties to traits table

Function to merge metadata from the contexts table of a traits.build
database into the core traits table.

## Usage

``` r
join_context_properties(
  database,
  format = "single_column_pretty",
  vars = "all",
  include_description = TRUE
)
```

## Arguments

- database:

  traits.build database (list object)

- format:

  Specifies whether metadata from the contexts is output in a human
  readable format ("single_column_pretty"; default), with each context
  property added as a separate column ("many_columns") or using json
  syntax ("single_column_json").

- vars:

  Location properties for which data is to be appended to the traits
  table, defaulting to all context properties (vars = "all").

- include_description:

  A logical indicating whether to include (TRUE) or omit (FALSE) the
  context_property descriptions.

## Value

traits.build list object, but context properties from the contexts table
appended to the traits table.

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
(austraits_lite %>% extract_dataset("Crous_2013") %>%
  join_context_properties(format = "many_columns", vars = "all",
    include_description = TRUE))$traits %>%
  dplyr::select(trait_name, value, dplyr::contains("_context: "))
#> # A tibble: 391 × 7
#>    trait_name                value treatment_context: t…¹ treatment_context: C…²
#>    <chr>                     <chr> <chr>                  <chr>                 
#>  1 leaf_N_per_area           1.43  elevated <<Plants gro… 400 ppm <<Plants grow…
#>  2 leaf_N_per_dry_mass       30.3… elevated <<Plants gro… 400 ppm <<Plants grow…
#>  3 leaf_light_respiration_p… 2690  elevated <<Plants gro… 400 ppm <<Plants grow…
#>  4 leaf_light_respiration_p… 2270  elevated <<Plants gro… 400 ppm <<Plants grow…
#>  5 leaf_mass_per_area        47.02 elevated <<Plants gro… 400 ppm <<Plants grow…
#>  6 leaf_photosynthesis_Jmax… 183.… elevated <<Plants gro… 400 ppm <<Plants grow…
#>  7 leaf_photosynthesis_Jmax… 168.… elevated <<Plants gro… 400 ppm <<Plants grow…
#>  8 leaf_photosynthesis_Vcma… 94.48 elevated <<Plants gro… 400 ppm <<Plants grow…
#>  9 leaf_photosynthesis_Vcma… 112.… elevated <<Plants gro… 400 ppm <<Plants grow…
#> 10 leaf_photosynthetic_rate… 27.7… elevated <<Plants gro… 400 ppm <<Plants grow…
#> # ℹ 381 more rows
#> # ℹ abbreviated names: ¹​`treatment_context: temperature treatment`,
#> #   ²​`treatment_context: CO2 treatment`
#> # ℹ 3 more variables: `plot_context: plots` <chr>,
#> #   `temporal_context: sampling season` <chr>,
#> #   `method_context: measurement temperature` <chr>
```
