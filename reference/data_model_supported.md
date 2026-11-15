# Whether traits.use reads a data model version

Whether traits.use reads a data model version

## Usage

``` r
data_model_supported(version)
```

## Arguments

- version:

  A version string, from
  [`get_data_model_version()`](https://traitecoevo.github.io/traits.use/reference/get_data_model_version.md).

## Value

`TRUE` if `version` is `major.minor.patch` with a major version in
[`supported_data_model_majors()`](https://traitecoevo.github.io/traits.use/reference/supported_data_model_majors.md).
