# A small subset of AusTraits, for examples

A traits.build database with 24 of the datasets in AusTraits 7.0.0, the
Australian plant trait database. It is in the same form as the databases
[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
downloads, so every function in the package works on it, and the
examples use it. For analysis, load a full release with
[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
instead.

## Usage

``` r
austraits_lite
```

## Format

A list of class `traits.build`, with the tables of a traits.build
database: `traits` (90,568 values of 151 traits for 7,259 taxa),
`locations`, `contexts`, `methods`, `excluded_data`,
`taxonomic_updates`, `taxa`, `identifiers`, `contributors`, `sources`,
`definitions`, `schema`, `metadata` and `build_info`. AusTraits 7.0.0
fills in `source_id` for only a few datasets, and predates the reference
columns of the `methods` table that traits.build 2.3 introduced (it has
`source_primary_key` and others; see
[`join_sources()`](https://traitecoevo.github.io/traits.use/reference/join_sources.md)).

## Source

AusTraits 7.0.0,
[doi:10.5281/zenodo.15718081](https://doi.org/10.5281/zenodo.15718081) ,
licensed under CC BY 4.0
(<https://creativecommons.org/licenses/by/4.0/>), cut down to 24
datasets with
[`extract_dataset()`](https://traitecoevo.github.io/traits.use/reference/extract_dataset.md)
(the script is `data-raw/create_data.R` in the package's GitHub
repository). Please cite AusTraits as described in Falster et al. (2021)
[doi:10.1038/s41597-021-01006-6](https://doi.org/10.1038/s41597-021-01006-6)
, and the original studies, listed in `sources` (as in the full release,
a few keys in `source_id` and the `methods` table, such as unpublished
data, have no entry). The `taxa` table, compiled from curated taxon
lists such as the Australian Plant Census, is released under CC BY 3.0,
as its description in `schema` says. See the file `COPYRIGHTS` installed
with the package.

## Examples

``` r
austraits_lite
#> 
#> ── This is 7.0.0 of AusTraits: a curated plant trait database for the Australian
#> ℹ This database is built using traits.build version 2.1.0
#> ℹ This database contains a total of 90568 records, for 7259 taxa and 151
#>   traits.
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
summarise_database(austraits_lite, "trait_name")
#> # A tibble: 151 × 5
#>    trait_name                    n_records n_dataset n_taxa percent_total
#>    <chr>                             <int>     <int>  <int>         <dbl>
#>  1 atmospheric_CO2_concentration       217         1     17     0.0024   
#>  2 bark_C_per_dry_mass                 159         1     17     0.00176  
#>  3 bark_N_per_dry_mass                 159         1     17     0.00176  
#>  4 bark_delta13C                       159         1     17     0.00176  
#>  5 bark_delta15N                       159         1     17     0.00176  
#>  6 bark_thickness                      198         2     17     0.00219  
#>  7 branch_mass_fraction                 45         1     45     0.000497 
#>  8 bud_bank_location                   218         2    204     0.00241  
#>  9 clonal_spread_mechanism               7         1      7     0.0000773
#> 10 dispersal_appendage                  13         1     13     0.000144 
#> # ℹ 141 more rows
```
