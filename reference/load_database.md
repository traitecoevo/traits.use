# Load any traits.build database into R console

Loads a traits.build formatted database, given its doi. The doi is
resolved to its repository, the relational database `.rds` file is
downloaded to `path` (if not already there, or if the copy there does
not match the record's md5 checksum) and then loaded. Zenodo and
Figshare records are supported, as are dois that resolve directly to an
`.rds` file.

## Usage

``` r
load_database(doi = NULL, path, update = TRUE)
```

## Arguments

- doi:

  character string - doi of the database, e.g.
  "10.5281/zenodo.11188867". A Zenodo concept doi will load the latest
  version of that record.

- path:

  folder the database is downloaded to and cached in, e.g.
  `"data/traits.build"` in a project, or
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) for one session.
  There is no default, so nothing is written unless you say where.

- update:

  if TRUE, the record's metadata .json will be re-downloaded

## Value

a large list containing traits.build data tables

## See also

[`austraits::load_austraits()`](https://traitecoevo.github.io/austraits/reference/load_austraits.html),
which loads a release of AusTraits by version number

## Examples

``` r
if (FALSE) { # \dontrun{
austraits <- load_database(doi = "10.5281/zenodo.11188867", path = "data/austraits")
} # }
```
