# Major versions of the traits.build data model that traits.use reads

The traits.build data model (<https://w3id.org/traits.build/>) is
versioned `major.minor.patch`, and a change to the tables that an
existing reader cannot read is a new major version. traits.use reads
every minor and patch version of the major versions listed here. To read
a new major version, add it here and release traits.use **before**
traits.build writes it: traits.build's tests check that the version it
writes is one traits.use reads.

## Usage

``` r
supported_data_model_majors()
```

## Value

An integer vector.
