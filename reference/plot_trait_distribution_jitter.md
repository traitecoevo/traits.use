# Plot the distribution of a numeric trait by group

Plots the values of a numeric trait as points, one row per group (e.g.
dataset or family), with groups ordered by their mean value. The shape
of each point shows whether it is a minimum, mean or maximum. The x-axis
is on a log scale when the values are all positive and the largest is
more than about 13 times the smallest (so the axis, padded by 20% each
side, spans more than a factor of 20). Values recorded as a bin or range
are left out.

Replaces
[`plot_trait_distribution_beeswarm()`](https://traitecoevo.github.io/traits.use/reference/plot_trait_distribution_beeswarm.md),
drawing many times faster.

## Usage

``` r
plot_trait_distribution_jitter(
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

A ggplot object, or a blank plot saying there are no numeric values to
plot. Each point also carries a `text` aesthetic
(`"dataset_id | taxon_name"`), which `plotly::ggplotly()` shows as a
tooltip.

## Author

Daniel Falster - daniel.falster@unsw.edu.au

## Examples

``` r
if (FALSE) { # \dontrun{
austraits %>% plot_trait_distribution_jitter("wood_density", "dataset_id", "Westoby_2014")
} # }
```
