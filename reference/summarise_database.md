# Summarise counts for a particular variable of interest

Summarise counts for a particular variable of interest

## Usage

``` r
summarise_database(database, var)
```

## Arguments

- database:

  traits.build database (list object), or a flat table from one: a table
  made by
  [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md),
  or a traits table (for `"family"` or `"genus"`, it must then have that
  column, e.g. from
  [`join_taxa()`](https://traitecoevo.github.io/traits.use/reference/join_taxa.md))

- var:

  variable you use wish to see summary of (trait_name, genus, family)

## Value

dataframe of unique levels of variable with counts and percentage

## Examples

``` r
summarise_database(database = austraits_lite, "trait_name")
#> # A tibble: 151 × 5
#>    trait_name                    n_records n_dataset n_taxa percent_total
#>    <chr>                             <int>     <int>  <int>         <dbl>
#>  1 atmospheric_CO2_concentration       217         1     17     0.00249  
#>  2 bark_C_per_dry_mass                 159         1     17     0.00183  
#>  3 bark_N_per_dry_mass                 159         1     17     0.00183  
#>  4 bark_delta13C                       159         1     17     0.00183  
#>  5 bark_delta15N                       159         1     17     0.00183  
#>  6 bark_thickness                      198         2     17     0.00228  
#>  7 branch_mass_fraction                 45         1     45     0.000517 
#>  8 bud_bank_location                   218         2    204     0.00251  
#>  9 clonal_spread_mechanism               7         1      7     0.0000805
#> 10 dispersal_appendage                  13         1     13     0.000149 
#> # ℹ 141 more rows
summarise_database(database = austraits_lite, "family")
#> # A tibble: 207 × 5
#>    family           n_records n_dataset n_taxa percent_total
#>    <chr>                <int>     <int>  <int>         <dbl>
#>  1 Acanthaceae            148         1     14     0.0017   
#>  2 Achariaceae             32         2      2     0.000368 
#>  3 Actinidiaceae           10         1      1     0.000115 
#>  4 Agapanthaceae            3         1      1     0.0000345
#>  5 Akaniaceae              10         1      1     0.000115 
#>  6 Alismataceae             1         1      1     0.0000115
#>  7 Alliaceae               11         2      9     0.000126 
#>  8 Alseuosmiaceae          23         1      2     0.000264 
#>  9 Alstroemeriaceae        11         2      2     0.000126 
#> 10 Amaranthaceae           33         2      4     0.000379 
#> # ℹ 197 more rows
```
