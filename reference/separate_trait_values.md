# Separate bounded trait values

This function reverts the action of bind_trait_values. This function
separates values that were concatenated so that studies that have
multiple observations for a given trait will have separate row for each
observation.

## Usage

``` r
separate_trait_values(trait_data, definitions = NULL)
```

## Arguments

- trait_data:

  The traits table in a traits.build database, after
  [`bind_trait_values()`](https://traitecoevo.github.io/traits.use/reference/bind_trait_values.md) -
  see example

- definitions:

  Not used; kept so that existing code passing the database's
  definitions still works.

## Value

trait tibble, with one row per value

## Author

Daniel Falster - daniel.falster@unsw.edu.au

## Examples

``` r
# A dataset with several values per observation and trait
trait_data <- austraits_lite$traits %>%
  dplyr::filter(dataset_id == "Apgaua_2017")
nrow(trait_data)
#> [1] 1080

# One row per observation and trait, values joined with "--"
traits_bind <- bind_trait_values(trait_data)
nrow(traits_bind)
#> [1] 990
traits_bind %>%
  dplyr::filter(grepl("--", value)) %>%
  dplyr::select(observation_id, trait_name, value, value_type)
#> # A tibble: 90 × 4
#>    observation_id trait_name           value                    value_type   
#>    <chr>          <chr>                <chr>                    <chr>        
#>  1 001            stem_vessel_diameter 53.95769819--82.51063733 mean--maximum
#>  2 003            stem_vessel_diameter 183.7818765--250.0572818 mean--maximum
#>  3 005            stem_vessel_diameter 107.4165069--162.7522903 mean--maximum
#>  4 007            stem_vessel_diameter 111.8421742--193.0407842 mean--maximum
#>  5 009            stem_vessel_diameter 22.89204368--29.2235397  mean--maximum
#>  6 013            stem_vessel_diameter 56.48465445--74.97623139 mean--maximum
#>  7 015            stem_vessel_diameter 71.9452453--99.04573875  mean--maximum
#>  8 017            stem_vessel_diameter 24.74156122--39.85608429 mean--maximum
#>  9 019            stem_vessel_diameter 137.106731--264.2239295  mean--maximum
#> 10 021            stem_vessel_diameter 23.24565594--33.69488496 mean--maximum
#> # ℹ 80 more rows

# Back to one row per value
nrow(separate_trait_values(traits_bind))
#> [1] 1080
```
