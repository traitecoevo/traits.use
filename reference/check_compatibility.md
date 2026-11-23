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

A flat table (see `database_format()`) is accepted only when
`single_table_allowed` is `TRUE`, and, if
[`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md)
stamped it with a data model version, only if that version is supported;
otherwise it stops with an error saying the function needs the
relational database. Anything that is neither a relational database nor
a traits table stops with an error.

## Usage

``` r
check_compatibility(
  database,
  single_table_allowed = FALSE,
  call = rlang::caller_env()
)
```

## Arguments

- database:

  traits.build database (list object), or a flat table from one

- single_table_allowed:

  logical: can the calling function take a flat table (a flattened
  database, or a traits table)? Defaults to `FALSE`

- call:

  the calling function's environment, named in errors

## Value

logical (T/F) output and messaging for incompatible versions

## Author

Elizabeth Wenk - e.wenk@unsw.edu.au
