# Load any traits.build database into R console

Loads a traits.build formatted database, given its doi. The doi is
resolved to its repository, the relational database `.rds` file (or with
`flattened = TRUE`, the flattened one) is downloaded (if there is no
copy already, or if the copy does not match the record's md5 checksum)
and then loaded. Zenodo and Figshare records are supported, as are dois
that resolve directly to an `.rds` file.

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
load_database(doi = NULL, path = NULL, update = TRUE, flattened = FALSE)
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

- flattened:

  if `TRUE`, load the flattened version of the database instead: one
  table with the other tables joined to the traits table, made with
  [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md)
  when the release was built. Releases of AusTraits from 7.0.0 include
  it. Its reference columns follow the
  [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md)
  of that time, so may differ from what
  [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md)
  makes now (e.g. AusTraits 7.0.0 has `source_primary_citation`, not
  `dataset_id_citation`). It is several times larger than the relational
  database (AusTraits 7.0.0: a 77 MB download, about 1 GB once loaded).

## Value

a large list containing traits.build data tables, or with
`flattened = TRUE`, a single table (tibble)

## See also

[`database_cache_dir()`](https://traitecoevo.github.io/traits.use/reference/database_cache_dir.md);
[`austraits::load_austraits()`](https://traitecoevo.github.io/austraits/reference/load_austraits.html),
which loads a release of AusTraits by version number

## Examples

``` r
if (FALSE) { # interactive()
# Downloads AusTraits (about 20 MB, several hundred MB once loaded) the
# first time, then loads it from the cache. To try the package without
# downloading anything, see ?austraits_lite.
austraits <- load_database(doi = "10.5281/zenodo.11188867")

# Keeping a copy in a folder of your choice instead, here a temporary one
austraits <- load_database(doi = "10.5281/zenodo.11188867",
  path = file.path(tempdir(), "austraits"))
}
```
