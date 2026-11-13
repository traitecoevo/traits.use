# Load AusTraits database into R console

Load AusTraits database into R console

## Usage

``` r
load_austraits(
  doi = NULL,
  version = NULL,
  path = "data/austraits",
  update = TRUE
)
```

## Arguments

- doi:

  character string - doi of particular version

- version:

  character string - version number of database

- path:

  file path to where AusTraits will be downloaded

- update:

  if TRUE, AusTraits versions .json will be re-downloaded

## Value

a large list containing AusTraits data tables. Its `sources` are given
the class
[`traits_build_sources`](https://traitecoevo.github.io/traits.use/reference/traits_build_sources.md),
also for releases built before that class existed, so a reference can be
looked up by key with `$` as well as `[[` and `[`, e.g.
`austraits$sources$Falster_2005`.

## See also

get_versions get_version_latest

## Examples

``` r
if (FALSE) { # \dontrun{
austraits <- load_austraits(version = "3.0.2", path = "data/austraits")
} # }
```
