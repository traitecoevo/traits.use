# traits.use

`traits.use` helps you **load, explore and wrangle data** from trait
databases built with
[traits.build](https://github.com/traitecoevo/traits.build), such as
[AusTraits](https://austraits.org/), the Australian plant trait
database. It works with any traits.build database, whichever group of
organisms or region it covers.

With `traits.use` you can:

- load a database from its DOI
  ([`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)),
  downloading each release once per computer and keeping it in a cache
  shared by all your projects;
- filter it to particular traits, taxa or datasets
  ([`extract_trait()`](https://traitecoevo.github.io/traits.use/reference/extract_trait.md),
  [`extract_taxa()`](https://traitecoevo.github.io/traits.use/reference/extract_taxa.md),
  [`extract_dataset()`](https://traitecoevo.github.io/traits.use/reference/extract_dataset.md),
  [`extract_data()`](https://traitecoevo.github.io/traits.use/reference/extract_data.md)),
  keeping every table consistent;
- join information from the database’s other tables onto the trait
  values
  ([`join_location_coordinates()`](https://traitecoevo.github.io/traits.use/reference/join_location_coordinates.md),
  [`join_taxa()`](https://traitecoevo.github.io/traits.use/reference/join_taxa.md),
  [`join_methods()`](https://traitecoevo.github.io/traits.use/reference/join_methods.md),
  [`join_context_properties()`](https://traitecoevo.github.io/traits.use/reference/join_context_properties.md)
  and more);
- reshape and flatten it
  ([`trait_pivot_wider()`](https://traitecoevo.github.io/traits.use/reference/trait_pivot_wider.md),
  [`as_wide_table()`](https://traitecoevo.github.io/traits.use/reference/as_wide_table.md),
  [`flatten_database()`](https://traitecoevo.github.io/traits.use/reference/flatten_database.md)),
  or combine several databases
  ([`bind_databases()`](https://traitecoevo.github.io/traits.use/reference/bind_databases.md));
- look up traits, references and properties
  ([`lookup_trait()`](https://traitecoevo.github.io/traits.use/reference/lookup_trait.md),
  `database$sources$Falster_2005`), summarise what it contains
  ([`summarise_database()`](https://traitecoevo.github.io/traits.use/reference/summarise_database.md)),
  and plot trait distributions and locations.

## Installation

`traits.use` is not yet on CRAN. Install the development version from
GitHub:

``` r

# install.packages("remotes")
remotes::install_github("traitecoevo/traits.use", dependencies = TRUE, upgrade = "ask")
```

Leave out `dependencies = TRUE` for a lighter installation without the
packages used for plotting.

## Getting started

``` r

library(traits.use)

# Load any traits.build database from its DOI. It is downloaded the first
# time and loaded from your cache after that (see ?database_cache_dir); give
# `path` to keep a copy with a project instead
database <- load_database("10.5281/zenodo.11188867")

# Pick out the traits you want, then add site coordinates to each value
wood_density <- database |>
  extract_trait("wood_density") |>
  join_location_coordinates()

summarise_database(wood_density, "family")
```

The [Getting Started
tutorial](https://traitecoevo.github.io/austraits/articles/austraits.html)
in the `austraits` package walks through these functions using
AusTraits. The [traits.build
book](https://traitecoevo.github.io/traits.build-book/) explains how a
traits.build database is structured: its tables, identifiers and how
they link.

## For AusTraits users

AusTraits is built with traits.build, so everything in `traits.use`
works on it: load a release with
[`load_database()`](https://traitecoevo.github.io/traits.use/reference/load_database.md)
and its DOI. The [`austraits`](https://github.com/traitecoevo/austraits)
package adds what is specific to AusTraits: `load_austraits()` loads a
release by version number,
[`plot_locations()`](https://traitecoevo.github.io/traits.use/reference/plot_locations.md)
draws a map of Australia, and the Getting Started tutorial uses
AusTraits throughout. AusTraits releases on
[Zenodo](https://doi.org/10.5281/zenodo.3568417) also include the data
as plain-text `.csv` files for users of Python and other tools. You can
look up each trait’s definition in the [AusTraits Plant
Dictionary](https://w3id.org/APD/).

The current functions support AusTraits 5.0.0 and later. For older
releases (4.2 and earlier), install an older version of the `austraits`
package:

``` r

remotes::install_github("traitecoevo/austraits@v2.2.2", dependencies = TRUE, upgrade = "ask")
```

To check which version of AusTraits you have loaded, run
`database$build_info$version`.

## History

`traits.use` began in 2021 as the `austraits` R package, an interface to
the AusTraits plant trait database ([Falster et
al. 2021](https://doi.org/10.1038/s41597-021-01006-6)). In 2024
(`austraits` 3.0) its functions were generalised to work with any
database compiled with traits.build, not just AusTraits. As other
traits.build databases appeared, the general-purpose code was split out
in 2026 into this package, `traits.use`, carrying over the full
development history and its contributors. The `austraits` package
continues as a thin AusTraits-specific layer built on `traits.use`
([austraits#188](https://github.com/traitecoevo/austraits/issues/188)).

## Citation

Please consider citing `traits.use` if you use it in your work:

``` r

citation("traits.use")
#> To cite traits.use in publications, please use the first reference
#> below. If you use AusTraits data, please also cite the AusTraits
#> database (second reference).
#> 
#>   Wenk, E., Kar, F., Falster, D. and Indiarto, D. (2026) traits.use:
#>   Access and Wrangle Data from 'traits.build' Trait Databases. R
#>   package version 0.1.0. https://github.com/traitecoevo/traits.use
#> 
#>   Falster, D., Gallagher, R., Wenk, E.H. et al. (2021) AusTraits, a
#>   curated plant trait database for the Australian flora. Scientific
#>   Data 8, 254. https://doi.org/10.1038/s41597-021-01006-6
#> 
#> To see these entries in BibTeX format, use 'print(<citation>,
#> bibtex=TRUE)', 'toBibtex(.)', or set
#> 'options(citation.bibtex.max=999)'.
```

## Find a bug?

Please let us know on the [issue
tracker](https://github.com/traitecoevo/traits.use/issues).

## AusTraits family

`traits.use` is part of the **AusTraits family** of packages maintained
by the [AusTraits](https://austraits.org) team. See
**[austraits.org](https://austraits.org)** for the project, the data,
and the people behind it. To see how AusTraits itself is compiled, look
at [austraits.build](https://github.com/traitecoevo/austraits.build).

Contributing? Issues across the family are tracked on one board,
[AusTraits \#9](https://github.com/orgs/traitecoevo/projects/9), and new
issues are auto-added. Please read the [issue & labelling
guide](https://github.com/traitecoevo/austraits-meta/blob/master/governance/issue-guide.md)
in [`austraits-meta`](https://github.com/traitecoevo/austraits-meta),
the family’s cross-package knowledge and governance hub, before filing.

## Acknowledgements

AusTraits is made possible by contributions from our partner
organisations — the [University of New South
Wales](https://www.unsw.edu.au/), [Western Sydney
University](https://www.westernsydney.edu.au/), [Botanic Gardens of
Sydney](https://www.botanicgardens.org.au/), [the University of
Melbourne](https://www.unimelb.edu.au/), the [Atlas of Living
Australia](https://www.ala.org.au/), and the Australian Government
[Department of Climate Change, Energy, the Environment and
Water](https://www.dcceew.gov.au) — and from our [advisory board, data
contributors, and past
partners](https://austraits.org/team/team-partners.html).

AusTraits is a co-investment partnership with the [Australian Research
Data Commons](https://ardc.edu.au/) (ARDC) through the Planet Research
Data Commons ([DOI:
10.3565/nyk4-4r91](https://doi.org/10.3565/nyk4-4r91)). The ARDC is
enabled by the Australian Government’s [National Collaborative Research
Infrastructure Strategy](https://www.education.gov.au/ncris) (NCRIS).
