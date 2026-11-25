# List the releases of a traits.build database

Finds every release of a database on its repository, given the doi of
any one of them or the doi of the whole record (a Zenodo concept doi, or
a Figshare doi without a version). Pass a release's doi to
[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
to load it. Zenodo and Figshare records are supported.

## Usage

``` r
list_versions(doi)
```

## Arguments

- doi:

  character string - a doi of the database, e.g. AusTraits' concept doi
  "10.5281/zenodo.3568417", or the doi of one of its releases

## Value

a tibble with one row per release, newest first: `version` (as recorded
on the repository, e.g. "v7.0.0" on Zenodo or "3" on Figshare), `doi`
(the release's own doi) and `publication_date`. A release whose files
are restricted is listed too, though
[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
cannot download it.

## See also

[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md);
`austraits::get_versions()`, which calls this for AusTraits and keeps a
copy of the list for offline use

## Examples

``` r
if (FALSE) { # interactive()
# The releases of AusTraits
versions <- list_versions("10.5281/zenodo.3568417")
versions

# Load the newest
austraits <- load_database(doi = versions$doi[1])
}
```
