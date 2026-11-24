# Columns of the table of trait means

The columns
[`summarise_trait_means()`](https://traitecoevo.github.io/traits.use/reference/summarise_trait_means.md)
returns, in order, with a definition of each, for writing beside a saved
copy of the table. The `by` variables a call adds follow `taxon_name`
and are not listed, and a taxon column is in the table only if the
database's taxa table has it.

## Usage

``` r
trait_means_dictionary()
```

## Value

A tibble with columns `column` and `definition`.

## See also

[`summarise_trait_means()`](https://traitecoevo.github.io/traits.use/reference/summarise_trait_means.md)

## Examples

``` r
trait_means_dictionary()
#> # A tibble: 27 × 2
#>    column          definition                                                   
#>    <chr>           <chr>                                                        
#>  1 taxon_name      Taxon name as aligned in the database, with subspecies, vari…
#>  2 trait_name      Trait name.                                                  
#>  3 unit            Unit of the numeric trait values; empty for categorical trai…
#>  4 estimate_type   Always observed_mean: computed directly from the records, wi…
#>  5 method          How value or value_mode was found. Numeric traits: geometric…
#>  6 value           Numeric traits: the observed mean. With method geometric, a …
#>  7 log_value       Natural log of value; empty with method arithmetic.          
#>  8 arithmetic_mean Arithmetic mean over the same groups and records (each group…
#>  9 value_min       Smallest record value used.                                  
#> 10 value_max       Largest record value used.                                   
#> # ℹ 17 more rows
```
