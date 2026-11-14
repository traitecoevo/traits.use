# Produce location maps of trait values

Plot location where trait data was collected from

## Usage

``` r
plot_locations(database, feature = "trait_name", ..., basemap = NULL)
```

## Arguments

- database:

  traits.build database OR traits table from a traits.build database.
  Note location details must be joined. See join_location_coordinates
  and examples

- feature:

  grouping/classification categories e.g trait_name, collection_type for
  \<= v3.0.2, basis of record for \>3.0.2

- ...:

  arguments passed to ggpointdensity::geom_pointdensity()

- basemap:

  `NULL` (the default) draws every location without a map. Or a data
  frame of map cells to draw the locations over, with numeric columns
  `x` (longitude) and `y` (latitude), one row per land cell, as used by
  [`ggplot2::geom_raster()`](https://ggplot2.tidyverse.org/reference/geom_tile.html);
  other columns, and rows missing `x` or `y`, are ignored. Locations
  beyond the map (plus half a degree) are left out, with a message
  saying how many records that affects; if no location lies on the map,
  it stops with an error. The `austraits` package passes a map of
  Australia here.

## Value

ggplot of sites

## Author

Dony Indiarto - d.indiarto@student.unsw.edu.au

## Examples

``` r
if (FALSE) { # \dontrun{
#All traits from a given study
data <- austraits %>% extract_dataset(dataset_id = "Falster_2003") %>% join_location_coordinates()
data %>% plot_locations("trait_name")

#Single trait
data <- austraits %>% extract_trait(trait_names = c("plant_height")) %>% join_location_coordinates()
data$traits %>% plot_locations("trait_name")

#Over a map: a data frame of land cells with columns x and y, such as
#`raster::as.data.frame(r, xy = TRUE, na.rm = TRUE)` of a land raster `r`
land <- raster::as.data.frame(r, xy = TRUE, na.rm = TRUE)
data$traits %>% plot_locations("trait_name", basemap = land)
} # }
```
