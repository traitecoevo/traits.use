# Summarise counts for a particular variable of interest

Summarise counts for a particular variable of interest

## Usage

``` r
summarise_database(database, var)
```

## Arguments

- database:

  traits.build database (list object)

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
#>  1 atmospheric_CO2_concentration       217         1     17     0.0024   
#>  2 bark_C_per_dry_mass                 159         1     17     0.00176  
#>  3 bark_N_per_dry_mass                 159         1     17     0.00176  
#>  4 bark_delta13C                       159         1     17     0.00176  
#>  5 bark_delta15N                       159         1     17     0.00176  
#>  6 bark_thickness                      198         2     17     0.00219  
#>  7 branch_mass_fraction                 45         1     45     0.000497 
#>  8 bud_bank_location                   218         2    204     0.00241  
#>  9 clonal_spread_mechanism               7         1      7     0.0000773
#> 10 dispersal_appendage                  13         1     13     0.000144 
#> # ℹ 141 more rows
summarise_database(database = austraits_lite, "family")
#> # A tibble: 207 × 5
#>    family           n_records n_dataset n_taxa percent_total
#>    <chr>                <int>     <int>  <int>         <dbl>
#>  1 Acanthaceae            177         1     14     0.00195  
#>  2 Achariaceae             38         2      2     0.00042  
#>  3 Actinidiaceae           13         1      1     0.000144 
#>  4 Agapanthaceae            3         1      1     0.0000331
#>  5 Akaniaceae              11         1      1     0.000121 
#>  6 Alismataceae             1         1      1     0.000011 
#>  7 Alliaceae               11         2      9     0.000121 
#>  8 Alseuosmiaceae          26         1      2     0.000287 
#>  9 Alstroemeriaceae        11         2      2     0.000121 
#> 10 Amaranthaceae           37         2      4     0.000409 
#> # ℹ 197 more rows
```
