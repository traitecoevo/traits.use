# Load any traits.build database into R console

Works like
[`load_austraits()`](https://traitecoevo.github.io/austraits/reference/load_austraits.md),
but accepts the doi of any traits.build formatted database. The doi is
resolved to its repository, the relational database `.rds` file is
downloaded to `path` (if not already there, or if the copy there does
not match the record's md5 checksum) and then loaded. Zenodo and
Figshare records are supported, as are dois that resolve directly to an
`.rds` file.

## Usage

``` r
load_database(doi = NULL, path = "data/traits.build", update = TRUE)
```

## Arguments

- doi:

  character string - doi of the database, e.g.
  "10.5281/zenodo.11188867". A Zenodo concept doi will load the latest
  version of that record.

- path:

  file path to where the database will be downloaded

- update:

  if TRUE, the record's metadata .json will be re-downloaded

## Value

a large list containing traits.build data tables

## See also

load_austraits

## Examples

``` r
if (FALSE) { # \dontrun{
austraits <- load_database(doi = "10.5281/zenodo.11188867", path = "data/austraits")
} # }
```
