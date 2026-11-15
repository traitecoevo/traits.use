# The traits.build data model version a database's tables follow

The traits.build data model version a database's tables follow

## Usage

``` r
get_data_model_version(database)
```

## Arguments

- database:

  traits.build database (list object)

## Value

The version as a string, such as `"1.4.0"`, or `NA` for a database built
before traits.build recorded it (traits.build 2.2 and earlier).
