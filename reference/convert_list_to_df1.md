# Convert list with single entries to dataframe

Convert a list with a single level of entries to a dataframe, useful
when converting a yaml into a dataframe.

## Usage

``` r
convert_list_to_df1(my_list)
```

## Arguments

- my_list:

  A list with single entries

## Value

A tibble with two columns

## Examples

``` r
convert_list_to_df1(as.list(dplyr::starwars)[2])
#> # A tibble: 87 × 2
#>    key    value
#>    <chr>  <int>
#>  1 height   172
#>  2 height   167
#>  3 height    96
#>  4 height   202
#>  5 height   150
#>  6 height   178
#>  7 height   165
#>  8 height    97
#>  9 height   183
#> 10 height   182
#> # ℹ 77 more rows
```
