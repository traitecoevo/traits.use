# Load any traits.build database into R console

Loads a traits.build formatted database, given its doi. The doi is
resolved to its repository, the relational database `.rds` file is
downloaded (if there is no copy already, or if the copy does not match
the record's md5 checksum) and then loaded. Zenodo and Figshare records
are supported, as are dois that resolve directly to an `.rds` file.

By default the download is kept in a folder shared by all your projects
(see
[`database_cache_dir()`](https://traitecoevo.github.io/traits.use/reference/database_cache_dir.md)),
so each release is downloaded once per computer. Use
[`list_cached_databases()`](https://traitecoevo.github.io/traits.use/reference/database_cache_dir.md)
and
[`clear_database_cache()`](https://traitecoevo.github.io/traits.use/reference/database_cache_dir.md)
to see and delete what is there.

## Usage

``` r
load_database(doi = NULL, path = NULL, update = TRUE)
```

## Arguments

- doi:

  character string - doi of the database, e.g.
  "10.5281/zenodo.11188867". A Zenodo concept doi will load the latest
  version of that record.

- path:

  folder the database is downloaded to and cached in. If `NULL` (the
  default), the folder shared by all your projects, given by
  [`database_cache_dir()`](https://traitecoevo.github.io/traits.use/reference/database_cache_dir.md).
  Give a folder such as `"data/austraits"` to keep a copy with a project
  instead, or [`tempdir()`](https://rdrr.io/r/base/tempfile.html) for
  one session.

- update:

  if TRUE, the record's metadata .json will be re-downloaded; if that
  fails (e.g. offline), the saved copy is used. With `FALSE`, a concept
  doi loads the version last fetched into `path`, which for the cache
  folder may have been by another project.

## Value

a large list containing traits.build data tables

## See also

[`database_cache_dir()`](https://traitecoevo.github.io/traits.use/reference/database_cache_dir.md);
[`austraits::load_austraits()`](https://traitecoevo.github.io/austraits/reference/load_austraits.html),
which loads a release of AusTraits by version number

## Examples

``` r
if (FALSE) { # \dontrun{
# Downloaded the first time, then loaded from the cache
austraits <- load_database(doi = "10.5281/zenodo.11188867")

# Keeping a copy with a project instead
austraits <- load_database(doi = "10.5281/zenodo.11188867", path = "data/austraits")
} # }
```
