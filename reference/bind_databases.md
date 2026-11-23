# Bind multiple traits.build data objects into a single data object

`bind_databases` binds all the listed studies into a single traits.build
database object as a large list.

## Usage

``` r
bind_databases(..., databases = list(...))
```

## Arguments

- ...:

  Arguments passed to other functions

- databases:

  List of traits.build databases to be bond together

## Value

Compiled database as a single large list

## Details

The combined `sources` hold the references of every database, with
duplicate keys removed. They are a
[`RefManageR::BibEntry()`](https://docs.ropensci.org/RefManageR/reference/BibEntry.html)
object with the class
[`traits_build_sources`](https://traitecoevo.github.io/traits.use/reference/traits_build_sources.md),
so a reference can be looked up by key with `$` as well as `[[` and `[`,
e.g. `database$sources$Falster_2005`.

Each table keeps one of each set of identical rows, so binding two
extracts of one database that overlap, e.g. by two contexts, holds each
shared observation once. A row of `traits` or `excluded_data` that
exactly copies another row of the *same* database is dropped too, but
with a warning naming the dataset: two genuine measurements differ in
`observation_id` or `repeat_measurements_id`, so an exact copy means the
dataset's configuration is wrong.

## See also

[traits_build_sources](https://traitecoevo.github.io/traits.use/reference/traits_build_sources.md)
for looking up `sources` by key

## Examples

``` r
a <- extract_dataset(austraits_lite, "Falster_2003")
b <- extract_dataset(austraits_lite, "Falster_2005_1")
both <- bind_databases(a, b)
unique(both$traits$dataset_id)
#> [1] "Falster_2003"   "Falster_2005_1"
```
