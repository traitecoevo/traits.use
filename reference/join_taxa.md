# Joining taxonomy to traits table

Function to merge metadata from the taxa table of a traits.build
database into the core traits table.

## Usage

``` r
join_taxa(
  database,
  vars = c("family", "genus", "taxon_rank", "establishment_means")
)
```

## Arguments

- database:

  traits.build database (list object)

- vars:

  Columns from the taxa table to be joined to the traits table,
  defaulting to c("family", "genus", "taxon_rank",
  "establishment_means").

## Value

traits.build list object, but with additional fields (columns) for the
specified variables from the taxa table appended to the traits table.

## Details

the `join_` functions have been developed to join relational tables for
databases built using the traits.build workflow. Learn more at:
<https://github.com/traitecoevo/traits.build> &
<https://github.com/traitecoevo/traits.build-book>

Note to AusTraits users:

- This function works with AusTraits version \>= 5.0.0 (from Nov 2023
  release)

- For AusTraits versions \<= 4.2.0 (up to Sept 2023 release) see
  <https://github.com/traitecoevo/austraits> for how to install old
  versions of the package or download a newer version of the database.

## Examples

``` r
# Append taxonomic details
(austraits_lite %>% extract_dataset("Falster_2003") %>% join_taxa())$traits %>%
  dplyr::select(taxon_name, trait_name, value, family, genus, taxon_rank)
#> # A tibble: 114 × 6
#>    taxon_name        trait_name             value  family    genus    taxon_rank
#>    <chr>             <chr>                  <chr>  <chr>     <chr>    <chr>     
#>  1 Acacia floribunda leaf_area              142    Fabaceae  Acacia   species   
#>  2 Acacia floribunda leaf_inclination_angle 57     Fabaceae  Acacia   species   
#>  3 Acacia floribunda leaf_compoundness      simple Fabaceae  Acacia   species   
#>  4 Acacia myrtifolia leaf_area              319    Fabaceae  Acacia   species   
#>  5 Acacia myrtifolia leaf_inclination_angle 66.1   Fabaceae  Acacia   species   
#>  6 Acacia myrtifolia leaf_compoundness      simple Fabaceae  Acacia   species   
#>  7 Acacia suaveolens leaf_area              562    Fabaceae  Acacia   species   
#>  8 Acacia suaveolens leaf_inclination_angle 71.7   Fabaceae  Acacia   species   
#>  9 Acacia suaveolens leaf_compoundness      simple Fabaceae  Acacia   species   
#> 10 Angophora hispida leaf_area              1590   Myrtaceae Angopho… species   
#> # ℹ 104 more rows
```
