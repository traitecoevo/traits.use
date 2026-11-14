# Manage the folder where downloaded databases are kept

By default,
[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
keeps the databases it downloads in one folder per user, so each release
is downloaded once per computer and shared by every project and R
session that loads it.

- `database_cache_dir()` gives the folder.

- `list_cached_databases()` lists the databases in it, with their size
  and when each was last used.

- `clear_database_cache()` deletes some or all of them, e.g. those not
  used for six months with `older_than = 180`.

A release of AusTraits is around 100 MB or more, and each new release is
usually kept beside the old ones, so delete the ones you no longer use.

The folder is, in order of preference:

1.  the `traits.use.cache_dir` option, if set, e.g. with
    `options(traits.use.cache_dir = "~/data/traits")` in your
    `.Rprofile`;

2.  otherwise `tools::R_user_dir("traits.use", which = "cache")`, which
    follows each operating system's convention for cache files (and the
    `R_USER_CACHE_DIR` environment variable, if set).

To keep a copy of a database with a project instead, give
[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
a `path`; the functions here take the same `path`. They only ever touch
the files
[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
wrote there: the database `.rds` files named in its record files
(`10.*.json`, one per doi).

## Usage

``` r
database_cache_dir()

list_cached_databases(path = database_cache_dir())

clear_database_cache(
  files = NULL,
  path = database_cache_dir(),
  older_than = NULL,
  ask = interactive()
)
```

## Arguments

- path:

  folder to list or clear; the cache folder by default.

- files:

  names of the database `.rds` files to delete, as listed by
  `list_cached_databases()`.

- older_than:

  delete the databases not used (loaded from the cache) for this many
  days. In a folder given as `path`, or where the cache cannot be
  written to, this is days since the file was downloaded.

- ask:

  if `TRUE`, asks for confirmation before deleting anything.

## Value

`database_cache_dir()` returns the folder's path (which may not exist
yet). `list_cached_databases()` returns a tibble with one row per
database: `file`, `size_mb` and `last_used`. `clear_database_cache()`
invisibly returns the paths of the files it deleted.

## Details

With neither `files` nor `older_than`, `clear_database_cache()` deletes
every database in `path`, with its record file.

## See also

[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)

## Examples

``` r
database_cache_dir()
#> [1] "/Users/runner/Library/Caches/org.R-project.R/R/traits.use"
list_cached_databases()
#> # A tibble: 0 × 3
#> # ℹ 3 variables: file <chr>, size_mb <dbl>, last_used <dttm>

# Delete the cached databases not used for six months
if (FALSE) { # \dontrun{
clear_database_cache(older_than = 180)
} # }
```
