# Extract all data for specific traits

Function to subset all data associated with a particular trait from a
traits.build relational database.

## Usage

``` r
extract_trait(
  database,
  trait_names,
  taxon_names = NULL,
  partial_matches_allowed = TRUE
)
```

## Arguments

- database:

  traits.build database (list object), or a flat table from one: a table
  made by
  [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md)
  (whose class and stamp the result keeps), or a traits table

- trait_names:

  character string of trait(s) for which data will be extracted

- taxon_names:

  optional argument, specifying taxa for which data will be extracted

- partial_matches_allowed:

  logical. If `TRUE` (the default), each value is matched as a
  case-insensitive regular expression, so `"Acacia"` also matches
  `"Acacia celsa"`; a value that is itself in the column, such as a
  taxon name with brackets, is matched as plain text instead, so it
  finds itself and the values containing it; a value that is not a valid
  regular expression is also matched as plain text. If `FALSE`, only
  exact matches are kept.

## Value

List of tibbles containing all traits.build data and metadata for the
specified trait(s). For a flat table, the matching rows of it, as a
table of the same class.

## Details

`extract_trait` has been developed to extract data for specific traits
from databases built using the traits.build workflow. Learn more at:
<https://github.com/traitecoevo/traits.build> &
<https://github.com/traitecoevo/traits.build-book>

Note to AusTraits users:

- This function works with AusTraits version \>= 5.0.0 (from Nov 2023
  release)

- For AusTraits versions \<= 4.2.0 (up to Sept 2023 release) see
  <https://github.com/traitecoevo/austraits> for how to install old
  versions of the package or download a newer version of the database.

## Author

Daniel Falster - daniel.falster@unsw.edu.au

## Examples

``` r
extract_trait(database = austraits_lite, trait_names = "wood_density", taxon_names = "Acacia celsa")
#> 
#> ── This is 7.0.0 of AusTraits: a curated plant trait database for the Australian
#> ℹ This database is built using traits.build version 2.1.0
#> ℹ This database contains a total of 1 records, for 1 taxa and 1 traits.
#> 
#> ── This object is a 'list' with the following components: ──
#> 
#> • traits: A table containing measurements of traits.
#> • locations: A table containing observations of location/site characteristics
#> associated with information in `traits`. Cross referencing between the two
#> dataframes is possible using combinations of the variables `dataset_id`,
#> `location_name`.
#> • contexts: A table containing observations of contextual characteristics
#> associated with information in `traits`. Cross referencing between the two
#> dataframes is possible using combinations of the variables `dataset_id`,
#> `link_id`, and `link_vals`.
#> • methods: A table containing details on methods with which data were
#> collected, including time frame and source. Cross referencing with the `traits`
#> table is possible using combinations of the variables `dataset_id`,
#> `trait_name`.
#> • excluded_data: A table of data that did not pass quality test and so were
#> excluded from the master dataset.
#> • taxonomic_updates: A table of all taxonomic changes implemented in the
#> construction of AusTraits. Changes are determined by comparing against the APC
#> (Australian Plant Census) and APNI (Australian Plant Names Index).
#> • taxa: A table containing details on taxa associated with information in
#> `traits`. This information has been sourced from the APC (Australian Plant
#> Census) and APNI (Australian Plant Names Index) and is released under a CC-BY3
#> license.
#> • contributors: A table of people contributing to each study.
#> • identifiers: A table of identifiers that cross-references observations
#> between datasets or with other data resources such as museum or herbarium
#> specimens.
#> • sources: Bibtex entries for all primary and secondary sources in the
#> compilation.
#> • definitions: A copy of the definitions for all tables and terms. Information
#> included here was used to process data and generate any documentation for the
#> study.
#> • schema: A copy of the schema for all tables and terms. Information included
#> here was used to process data and generate any documentation for the study.
#> • metadata: Metadata associated with the dataset, including title, creators,
#> license, subject, funding sources.
#> • build_info: A description of the computing environment used to create this
#> version of the dataset, including version number, git commit and R
#> session_info.
#> ℹ To access a component, try using the $ e.g. database$traits
```
