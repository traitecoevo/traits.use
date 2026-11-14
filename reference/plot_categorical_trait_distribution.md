# Plot the distribution of a categorical trait by family

For the families with the most taxa scored for a categorical trait,
plots the proportion of each family's taxa with each value of the trait.
Each taxon counts once: within a dataset, a taxon's distinct values
share its weight equally (a value cell such as `"simple compound"`
counts as both values), and its datasets are then combined. Values are
ordered from most to least common in the families shown. Ties between
families at the `family_count` cut-off are broken alphabetically.

## Usage

``` r
plot_categorical_trait_distribution(database, trait_name, family_count = 50)
```

## Arguments

- database:

  traits.build database (list object), or its traits table (which must
  then have a `family` column, e.g. from
  [`join_taxa()`](https://traitecoevo.github.io/traits.use/reference/join_taxa.md))

- trait_name:

  Name of the trait to plot (matched exactly)

- family_count:

  Number of families to show: those with the most taxa scored for the
  trait

## Value

A ggplot object, or a blank plot saying there are no values to plot

## Examples

``` r
if (FALSE) { # \dontrun{
austraits %>% plot_categorical_trait_distribution("leaf_compoundness", family_count = 20)
} # }
```
