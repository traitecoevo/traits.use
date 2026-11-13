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
[`traits_build_sources`](https://traitecoevo.github.io/austraits/reference/traits_build_sources.md),
so a reference can be looked up by key with `$` as well as `[[` and `[`,
e.g. `database$sources$Falster_2005`.

## See also

[traits_build_sources](https://traitecoevo.github.io/austraits/reference/traits_build_sources.md)
for looking up `sources` by key
