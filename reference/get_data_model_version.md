# The traits.build data model version a database's tables follow

The one place the version is read, for both the compatibility check and
the stamp
[`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md)
puts on a flat table.

## Usage

``` r
get_data_model_version(database)
```

## Arguments

- database:

  traits.build database (list object), or a flat table

## Value

The version as a string, such as `"1.4.0"`, or `NA` for a database built
before traits.build recorded it (traits.build 2.2 and earlier), and for
a flat table without a stamp. A field that is there but is not one
string is returned as text, e.g. `"NA"` or `""`, which
[`data_model_supported()`](https://traitecoevo.github.io/traits.use/reference/data_model_supported.md)
rejects.
