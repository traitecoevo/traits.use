# Plot the distribution of a trait

Plots the values of one trait, choosing the plot from the trait's type:
[`plot_trait_distribution_jitter()`](https://traitecoevo.github.io/traits.use/reference/plot_trait_distribution_jitter.md)
by family for a numeric trait,
[`plot_categorical_trait_distribution()`](https://traitecoevo.github.io/traits.use/reference/plot_categorical_trait_distribution.md)
for a categorical one.

## Usage

``` r
plot_trait_distribution(database, trait_name, ...)
```

## Arguments

- database:

  traits.build database (list object), or its traits table (which must
  then have a `family` column, e.g. from
  [`join_taxa()`](https://traitecoevo.github.io/traits.use/reference/join_taxa.md))

- trait_name:

  Name of the trait to plot (matched exactly)

- ...:

  Further named arguments: `y_axis_category` (default `"family"`),
  `highlight` and `hide_ids` for a numeric trait, passed to
  [`plot_trait_distribution_jitter()`](https://traitecoevo.github.io/traits.use/reference/plot_trait_distribution_jitter.md);
  `family_count` for a categorical trait, passed to
  [`plot_categorical_trait_distribution()`](https://traitecoevo.github.io/traits.use/reference/plot_categorical_trait_distribution.md).
  Arguments the chosen plot does not take are ignored, so one set of
  arguments can be used for traits of both types.

## Value

A ggplot object. With no values to plot (an empty or `NULL` input, or a
trait not in it), a blank plot saying so.

## Examples

``` r
if (FALSE) { # \dontrun{
austraits %>% plot_trait_distribution("wood_density")
austraits %>% plot_trait_distribution("leaf_compoundness")
} # }
```
