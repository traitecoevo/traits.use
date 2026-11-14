# Bind trait values

This function condenses data for studies that have multiple observations
for a given trait into a single row. This function concatenates multiple
values into a single cell

## Usage

``` r
bind_trait_values(trait_data)
```

## Arguments

- trait_data:

  the traits table in a traits.build database – see example

## Value

tibble that is condensed down where multiple observations in value,
value_type and replicates are collapsed down and separated by '–'

## Author

Daniel Falster - daniel.falster@unsw.edu.au

## Examples

``` r
traits <- austraits_lite$traits %>%
  dplyr::filter(dataset_id == "Apgaua_2017")
traits
#> # A tibble: 1,080 × 26
#>    dataset_id  taxon_name      observation_id trait_name value unit  entity_type
#>    <chr>       <chr>           <chr>          <chr>      <chr> <chr> <chr>      
#>  1 Apgaua_2017 Aglaia meridio… 001            leaf_delt… -34.… {del… individual 
#>  2 Apgaua_2017 Aglaia meridio… 001            leaf_wate… 0.02… umol… individual 
#>  3 Apgaua_2017 Aglaia meridio… 001            sapwood_s… 14.6… kg/m… individual 
#>  4 Apgaua_2017 Aglaia meridio… 001            stem_vess… 71.0… {cou… individual 
#>  5 Apgaua_2017 Aglaia meridio… 001            stem_vess… 53.9… um    individual 
#>  6 Apgaua_2017 Aglaia meridio… 001            stem_vess… 82.5… um    individual 
#>  7 Apgaua_2017 Aglaia meridio… 001            stem_vess… 57.9… um    individual 
#>  8 Apgaua_2017 Aglaia meridio… 001            stem_vess… 0.16… mm2/… individual 
#>  9 Apgaua_2017 Aglaia meridio… 001            stem_vess… 0.625 {dim… individual 
#> 10 Apgaua_2017 Aglaia meridio… 001            stem_xyle… 0.77… um.m… individual 
#> # ℹ 1,070 more rows
#> # ℹ 19 more variables: value_type <chr>, basis_of_value <chr>,
#> #   replicates <chr>, basis_of_record <chr>, life_stage <chr>,
#> #   population_id <chr>, individual_id <chr>, repeat_measurements_id <chr>,
#> #   temporal_context_id <chr>, source_id <chr>, location_id <chr>,
#> #   entity_context_id <chr>, plot_context_id <chr>, treatment_context_id <chr>,
#> #   collection_date <chr>, measurement_remarks <chr>, method_id <chr>, …
traits_bind <- bind_trait_values(traits)
traits_bind
#> # A tibble: 990 × 26
#>    dataset_id  taxon_name      observation_id trait_name value unit  entity_type
#>    <chr>       <chr>           <chr>          <chr>      <chr> <chr> <chr>      
#>  1 Apgaua_2017 Aglaia meridio… 001            leaf_delt… -34.… {del… individual 
#>  2 Apgaua_2017 Aglaia meridio… 001            leaf_wate… 0.02… umol… individual 
#>  3 Apgaua_2017 Aglaia meridio… 001            sapwood_s… 14.6… kg/m… individual 
#>  4 Apgaua_2017 Aglaia meridio… 001            stem_vess… 71.0… {cou… individual 
#>  5 Apgaua_2017 Aglaia meridio… 001            stem_vess… 53.9… um    individual 
#>  6 Apgaua_2017 Aglaia meridio… 001            stem_vess… 57.9… um    individual 
#>  7 Apgaua_2017 Aglaia meridio… 001            stem_vess… 0.16… mm2/… individual 
#>  8 Apgaua_2017 Aglaia meridio… 001            stem_vess… 0.625 {dim… individual 
#>  9 Apgaua_2017 Aglaia meridio… 001            stem_xyle… 0.77… um.m… individual 
#> 10 Apgaua_2017 Aglaia meridio… 001            wood_dens… 0.64… mg/m… individual 
#> # ℹ 980 more rows
#> # ℹ 19 more variables: value_type <chr>, basis_of_value <chr>,
#> #   replicates <chr>, basis_of_record <chr>, life_stage <chr>,
#> #   population_id <chr>, individual_id <chr>, repeat_measurements_id <chr>,
#> #   temporal_context_id <chr>, source_id <chr>, location_id <chr>,
#> #   entity_context_id <chr>, plot_context_id <chr>, treatment_context_id <chr>,
#> #   collection_date <chr>, measurement_remarks <chr>, method_id <chr>, …
```
