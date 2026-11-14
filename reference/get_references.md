# List the references a database cites

Lists the references cited by the data in a traits.build database, or in
the part of one returned by an `extract_*()` function, each formatted as
a citation. With `file`, it also writes them to a BibTeX file. Use it to
cite the studies behind the data you use.

## Usage

``` r
get_references(database, file = NULL)
```

## Arguments

- database:

  traits.build database (list object), or the result of an `extract_*()`
  function.

- file:

  Path of a BibTeX file to write the references to, or `NULL` (the
  default) to write none. An existing file is overwritten. As with
  [`RefManageR::WriteBib()`](https://docs.ropensci.org/RefManageR/reference/WriteBib.html),
  `.bib` is added to a name that does not end in it.

## Value

A tibble with one row per reference, sorted by key in the C locale, and
columns:

- `key`: the reference's citation key, as in `sources`.

- `citation`: the reference, formatted as in the citation columns of
  [`join_sources()`](https://traitecoevo.github.io/traits.use/reference/join_sources.md)
  and the methods table, or `NA` when `sources` has no entry for the
  key.

- `type`: how the data cite it. `"dataset"`: the reference describing a
  dataset. `"source"`: a study that observations were taken from, in a
  dataset compiled from several studies. `"secondary"`: a further
  reference for a dataset, such as a later paper using the same data.

## Details

The references are the ones the data cite, read from the traits,
excluded data and methods tables: each dataset's own reference, each
observation's `source_id` and each dataset's secondary references. These
are also the references
[`extract_data()`](https://traitecoevo.github.io/traits.use/reference/extract_data.md)
keeps in `sources`, so for a database or any `extract_*()` result the
references listed are those in its `sources`. A key cited in more than
one way gets the first type of `"dataset"`, `"source"` and
`"secondary"`.

In databases built with traits.build 2.3 or later, a dataset's own
reference is keyed by its `dataset_id`, and every `source_id` is a key
in `sources`. In older ones a dataset's own reference is the methods
table's `source_primary_key`, the studies are listed in its
`source_original_dataset_key`, and `source_id` was free text, so only
the values that are keys in `sources` are read. Each dataset of a
database combined with
[`bind_databases()`](https://traitecoevo.github.io/traits.use/reference/bind_databases.md)
is read by the rules of its own build.

A cited key with no entry in `sources` is listed with an `NA` citation
and a warning, rather than silently dropped. A database can have such
keys when a dataset names a study it took observations from without
giving its reference. Only the references in `sources` are written to
`file`.

A flattened database (one table, see
[`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md))
has no `sources`, so its references cannot be listed.

## See also

[`join_sources()`](https://traitecoevo.github.io/traits.use/reference/join_sources.md)
to add each observation's references to the traits table,
[traits_build_sources](https://traitecoevo.github.io/traits.use/reference/traits_build_sources.md)
to look up `sources` by key.

## Examples

``` r
refs <- austraits_lite %>%
  extract_dataset("Falster_2003") %>%
  get_references()
refs
#> # A tibble: 1 × 3
#>   key          citation                                                    type 
#>   <chr>        <chr>                                                       <chr>
#> 1 Falster_2003 "D. S. Falster and M. Westoby. \"Leaf size and angle vary … data…

# Write the references to a BibTeX file too
bib_file <- tempfile(fileext = ".bib")
refs <- austraits_lite %>%
  extract_taxa(genus = "Eucalyptus") %>%
  get_references(file = bib_file)
head(readLines(bib_file))
#> [1] "@Online{ABRS_2022,"                                                                         
#> [2] "  year = {2022},"                                                                           
#> [3] "  author = {{Australian Biological Resources Study}},"                                      
#> [4] "  title = {{Flora of Australia, Australian Biological Resources Study, Canberra.}},"        
#> [5] "  publisher = {Department of Climate Change, Energy, the Environment and Water, Canberra.},"
#> [6] "  url = {http://www.ausflora.org.au},"                                                      
unlink(bib_file)
```
