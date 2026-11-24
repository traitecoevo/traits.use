# Joining references to traits table

Function to merge the references each observation cites into the core
traits table of a traits.build database: the dataset's own citation, the
citation of the source the observation was taken from, and the dataset's
secondary references.

## Usage

``` r
join_sources(database, vars = "all")
```

## Arguments

- database:

  traits.build database (list object)

- vars:

  Columns to be joined to the traits table, defaulting to all of them
  (vars = "all"):

  - `dataset_id_type`: BibTeX type of the dataset's own reference
    (Article, Book, Thesis, ...)

  - `dataset_id_citation`: citation for the dataset's own reference

  - `source_id_citation`: citation for the reference the observation was
    taken from, `sources[[source_id]]`

  - `secondary_id`: keys, separated by `; `, of the dataset's secondary
    references (later publications that re-used the data)

  - `secondary_citation`: citations, separated by `; `, for those
    references

## Value

traits.build list object, but with additional fields (columns) for the
specified references appended to the traits table.

## Details

Each observation's `source_id` holds the key of the reference in
`sources` that it was taken from: the dataset's own reference (keyed by
the `dataset_id`), or, for a dataset compiled from several studies, the
study the observation came from. `source_id_citation` formats that
reference; the other columns come from the methods table and are the
same for every observation of a dataset. A `source_id` with no entry in
`sources` gets `NA`. In databases built with traits.build before 2.3, an
observation collected in the dataset's own study has no `source_id`, and
its `dataset_id` is used in its place.

the `join_` functions have been developed to join relational tables for
databases built using the traits.build workflow. Learn more at:
<https://github.com/traitecoevo/traits.build> &
<https://github.com/traitecoevo/traits.build-book>

## Examples

``` r
(austraits_lite %>% extract_dataset("Yang_2023") %>%
  join_sources(vars = c("dataset_id_citation", "source_id_citation")))$traits %>%
  dplyr::select(trait_name, value, source_id, dataset_id_citation, source_id_citation)
#> # A tibble: 2,635 × 5
#>    trait_name            value  source_id dataset_id_citation source_id_citation
#>    <chr>                 <chr>  <chr>     <chr>               <chr>             
#>  1 resprouting_capacity  fire_… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#>  2 post_fire_recruitment post_… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#>  3 post_fire_recruitment post_… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#>  4 resprouting_capacity  fire_… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#>  5 resprouting_capacity  fire_… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#>  6 bud_bank_location     basal… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#>  7 resprouting_capacity  respr… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#>  8 post_fire_recruitment post_… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#>  9 resprouting_capacity  fire_… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#> 10 bud_bank_location     basal… ABRS_2022 "S. Yang. \"Unpubl… Australian Biolog…
#> # ℹ 2,625 more rows
```
