# Extract data from traits.build database

Function to extract data from a traits.build database based on any
value(s) from any column in the traits, locations, contexts, methods,
taxa, taxonomic_updates, contributors and identifiers tables. The output
a traits.build formatted database with all tables subset based on the
specified table, column (variable) and column value.

## Usage

``` r
extract_data(
  database,
  table = NA,
  col,
  col_value,
  partial_matches_allowed = TRUE
)
```

## Arguments

- database:

  traits.build database (list object)

- table:

  Table within a traits.build database

- col:

  Column name within the specified table.

- col_value:

  Value (of column, from with a table) that is used to subset database.
  This can be a single value or a vector. It includes partial string
  matches.

- partial_matches_allowed:

  logical. If `TRUE` (the default), each value is matched as a
  case-insensitive regular expression, so `"Acacia"` also matches
  `"Acacia celsa"`; characters with special meaning in regular
  expressions, such as brackets, then need escaping. If `FALSE`, only
  exact matches are kept.

## Value

subset traits.build database

## Examples

``` r
if (FALSE) { # \dontrun{
extract_data(database = traits.build_database, table = "traits", 
col = "trait_name", col_value = "leaf_area")
} # }
```
