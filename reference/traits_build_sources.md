# Look up references in a database's `sources` by key

The `sources` component of a traits.build database holds the
bibliographic references for every dataset, as a
[`RefManageR::BibEntry()`](https://docs.ropensci.org/RefManageR/reference/BibEntry.html)
object keyed by citation key (for example `"Falster_2005"`). austraits
gives it the extra class `traits_build_sources`, which makes `$` look an
entry up by its key. Any of these return the reference for
`Falster_2005`:

    database$sources$Falster_2005
    database$sources[["Falster_2005"]]
    database$sources["Falster_2005"]

and `database$sources[c("Falster_2003", "Falster_2005")]` returns
several. Use `names(database$sources)` to list the keys.

## Usage

``` r
# S3 method for class 'traits_build_sources'
x$name

# S3 method for class 'traits_build_sources'
x[i, j, ..., drop = FALSE]

# S3 method for class 'traits_build_sources'
c(..., recursive = FALSE)
```

## Arguments

- x:

  A `traits_build_sources` object: the `sources` component of a
  traits.build database.

- name:

  A citation key, or a `BibEntry` field name.

- i, j, ..., drop:

  Indices, as for RefManageR's `[` method for `BibEntry`.

- recursive:

  Ignored, as for RefManageR's [`c()`](https://rdrr.io/r/base/c.html)
  method for `BibEntry`.

## Value

For `$`, the entry with key `name` as a `traits_build_sources` object of
length one or, when `name` is not a key, the value of field `name` for
every entry. For `[` and [`c()`](https://rdrr.io/r/base/c.html), a
`traits_build_sources` object.

## Details

On a plain `BibEntry`, `$` is field access (`sources$title` returns the
title of every entry), so `sources$Falster_2005` returns a list of
`NULL`s, one per entry, instead of the reference. With the
`traits_build_sources` class, `$` looks up by key when the name is a
key, and otherwise falls back to field access, so `sources$title` and
`sources$author` work as before.

The class only adds behaviour; everything else is inherited from
`BibEntry`. Printing, [`format()`](https://rdrr.io/r/base/format.html),
[`RefManageR::WriteBib()`](https://docs.ropensci.org/RefManageR/reference/WriteBib.html)
and
[`RefManageR::toBiblatex()`](https://docs.ropensci.org/RefManageR/reference/toBiblatex.html)
give the same output with or without it. `[`, `[[` and
[`c()`](https://rdrr.io/r/base/c.html) keep the class (for
[`c()`](https://rdrr.io/r/base/c.html), when the first argument has it),
as do the RefManageR methods built on `[`, such as
[`sort()`](https://rdrr.io/r/base/sort.html),
[`unique()`](https://rdrr.io/r/base/unique.html) and
[`head()`](https://rdrr.io/r/utils/head.html). RefManageR's replacement
functions (`$<-`, `[<-`, `[[<-`) and
[`merge()`](https://rdrr.io/r/base/merge.html) return a plain
`BibEntry`.

[`bind_databases()`](https://traitecoevo.github.io/austraits/reference/bind_databases.md),
[`load_austraits()`](https://traitecoevo.github.io/austraits/reference/load_austraits.md)
and
[`extract_data()`](https://traitecoevo.github.io/austraits/reference/extract_data.md)
(and so the other `extract_*()` functions) add the class to the
`sources` they return, including for databases built before the class
existed. An object carrying the class behaves as a plain `BibEntry` in a
session where austraits is not loaded.

## See also

[`bind_databases()`](https://traitecoevo.github.io/austraits/reference/bind_databases.md),
[`load_austraits()`](https://traitecoevo.github.io/austraits/reference/load_austraits.md),
[`RefManageR::BibEntry()`](https://docs.ropensci.org/RefManageR/reference/BibEntry.html)

## Examples

``` r
sources <- c(
  RefManageR::BibEntry(
    bibtype = "Article", key = "Falster_2003",
    title = "Leaf size and angle vary widely across species",
    author = "Daniel S. Falster and Mark Westoby",
    journal = "New Phytologist", year = 2003
  ),
  RefManageR::BibEntry(
    bibtype = "Article", key = "Falster_2005",
    title = "Alternative height strategies among 45 dicot rain forest species",
    author = "Daniel S. Falster and Mark Westoby",
    journal = "Journal of Ecology", year = 2005
  )
)
database <- list(sources = sources)

# Without the class, `$` with a key returns a list of NULLs
database$sources$Falster_2005
#> $Falster_2003
#> NULL
#> 
#> $Falster_2005
#> NULL
#> 

# bind_databases(), load_austraits() and extract_data() add the class
class(database$sources) <- c("traits_build_sources", class(database$sources))
database$sources$Falster_2005
#> [1] D. S. Falster and M. Westoby. “Alternative height strategies among
#> 45 dicot rain forest species”. In: _Journal of Ecology_ (2005).
database$sources[["Falster_2005"]]
#> [1] D. S. Falster and M. Westoby. “Alternative height strategies among
#> 45 dicot rain forest species”. In: _Journal of Ecology_ (2005).

# Names that are not keys are still field access
database$sources$year
#> $Falster_2003
#> [1] "2003"
#> 
#> $Falster_2005
#> [1] "2005"
#> 
```
