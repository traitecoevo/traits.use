# Check compatibility of traits.build object

Function to check whether the data object has been compiled by the
traits.build workflow and therefore has a data structure that is
appropriate for use with traits.use functions.

A database built by traits.build 2.3 or later records the version of the
traits.build data model its tables follow, in
`metadata$data_model_version` (see
[`get_data_model_version()`](https://traitecoevo.github.io/traits.use/reference/get_data_model_version.md)).
It is compatible if that version's major number is one this version of
traits.use reads
([`supported_data_model_majors()`](https://traitecoevo.github.io/traits.use/reference/supported_data_model_majors.md)).
A database without that field is compatible if
`metadata$related_identifiers` says it was compiled by traits.build,
which is how releases built before the field existed, such as AusTraits
7.0.0 and earlier, are recognised.

## Usage

``` r
check_compatibility(database, single_table_allowed = FALSE)
```

## Arguments

- database:

  traits.build database (list object)

- single_table_allowed:

  logical for when the input might be a single table instead of a
  complete database; defaults to FALSE

## Value

logical (T/F) output and messaging for incompatible versions

## Author

Elizabeth Wenk - e.wenk@unsw.edu.au
