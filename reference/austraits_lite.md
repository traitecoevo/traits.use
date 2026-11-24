# A small subset of AusTraits, for examples

A traits.build database with 24 of the datasets in AusTraits, the
Australian plant trait database, compiled from AusTraits' source after
the 7.0.0 release, in the form of the 8.0.0 release (traits.build data
model 1.4.0). It is in the same form as the databases
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
database: `traits` (87,001 values of 151 traits for 7,259 taxa),
`locations`, `contexts`, `methods`, `excluded_data`,
`taxonomic_updates`, `taxa`, `identifiers`, `contributors`, `sources`,
`definitions`, `schema`, `metadata` and `build_info`. Every observation
names the reference it was taken from in `source_id` (3,294 name another
study than their dataset), and the `methods` table has the reference
columns `dataset_id_type`, `dataset_id_citation`, `secondary_id` and
`secondary_citation` (see
[`join_sources()`](https://traitecoevo.github.io/traits.use/reference/join_sources.md)).

## Source

AusTraits,
[doi:10.5281/zenodo.3568417](https://doi.org/10.5281/zenodo.3568417) ,
whose compiled database is licensed under CC BY 4.0
(<https://creativecommons.org/licenses/by/4.0/>), compiled for 24
datasets by `data-raw/austraits_lite.R` in the package's GitHub
repository. Please cite AusTraits as described in Falster et al. (2021)
[doi:10.1038/s41597-021-01006-6](https://doi.org/10.1038/s41597-021-01006-6)
, and the original studies, listed in `sources`. The `taxa` table,
compiled from curated taxon lists such as the Australian Plant Census,
is released under CC BY 3.0, as its description in `schema` says. See
the file `COPYRIGHTS` installed with the package.

## Details

`austraits_lite` is compiled from AusTraits' source
(<https://github.com/traitecoevo/austraits.build>) at a given commit,
not taken from a release: traits.use is released before the AusTraits
release whose data model it reads, so its example data follows the data
model rather than the releases. This one was compiled from commit
`a8ae3d94` with traits.build 3.0.0, so `metadata$version` is
`"7.0.0.9000"` and `build_info$git_SHA` names the commit. Its values can
differ a little from those of the same datasets in AusTraits 8.0.0.

## Examples

``` r
austraits_lite
#> 
#> ── This is 7.0.0.9000 of AusTraits: a curated plant trait database for the Austr
#> ℹ This database is built using traits.build version 3.0.0
#> ℹ Its tables follow traits.build data model 1.4.0
#> ℹ This database contains a total of 87001 records, for 7259 taxa and 151
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
#>  1 atmospheric_CO2_concentration       217         1     17     0.00249  
#>  2 bark_C_per_dry_mass                 159         1     17     0.00183  
#>  3 bark_N_per_dry_mass                 159         1     17     0.00183  
#>  4 bark_delta13C                       159         1     17     0.00183  
#>  5 bark_delta15N                       159         1     17     0.00183  
#>  6 bark_thickness                      198         2     17     0.00228  
#>  7 branch_mass_fraction                 45         1     45     0.000517 
#>  8 bud_bank_location                   218         2    204     0.00251  
#>  9 clonal_spread_mechanism               7         1      7     0.0000805
#> 10 dispersal_appendage                  13         1     13     0.000149 
#> # ℹ 141 more rows
```
