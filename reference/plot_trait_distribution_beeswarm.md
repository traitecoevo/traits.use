# Beeswarm Trait distribution

**\[deprecated\]**

Use
[`plot_trait_distribution_jitter()`](https://traitecoevo.github.io/traits.use/reference/plot_trait_distribution_jitter.md)
instead, which draws the same distribution many times faster.
`plot_trait_distribution_beeswarm()` now draws and returns the jitter
plot, with a deprecation warning.

## Usage

``` r
plot_trait_distribution_beeswarm(
  database,
  trait_name,
  y_axis_category,
  highlight = NA,
  hide_ids = FALSE
)
```

## Arguments

- database:

  traits.build database (list object), or its traits table (which must
  then have a `family` column, e.g. from
  [`join_taxa()`](https://traitecoevo.github.io/traits.use/reference/join_taxa.md))

- trait_name:

  Name of the trait to plot (matched exactly)

- y_axis_category:

  Column to group values by, e.g. `"dataset_id"` or `"family"`. `family`
  and `genus` are added from the taxa table when `database` is a whole
  database.

- highlight:

  One or more groups to highlight in a different colour

- hide_ids:

  Hide the group labels on the y-axis?

## Value

The plot from
[`plot_trait_distribution_jitter()`](https://traitecoevo.github.io/traits.use/reference/plot_trait_distribution_jitter.md),
invisibly, after drawing it

## Examples

``` r
if (FALSE) { # \dontrun{
austraits %>% plot_trait_distribution_jitter("wood_density", "dataset_id", "Westoby_2014")
} # }
```
