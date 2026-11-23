#' @title Produce location maps of trait values 
#' @description Plot location where trait data was collected from
#' @param database traits.build database OR traits table from a traits.build database. Note location details must be joined. See join_location_coordinates and examples
#' @param feature grouping/classification categories e.g trait_name, collection_type for <= v3.0.2, basis of record for >3.0.2
#' @param ... arguments passed to ggpointdensity::geom_pointdensity()
#' @param basemap The map to draw the locations over:
#' * `"world"` (the default): a map of the world's land, cropped to the
#'   locations being drawn, so that any database gets a map. It is a 0.05
#'   degree grid (about 5 km), rasterised from Natural Earth's 1:10m land
#'   (public domain, <https://www.naturalearthdata.com/>), and shown coarser
#'   when the locations span a large area.
#' * `NULL`: no map, just the locations.
#' * A data frame of map cells, with numeric columns `x` (longitude) and `y`
#'   (latitude), one row per land cell, as used by [ggplot2::geom_raster()];
#'   other columns, and rows missing `x` or `y`, are ignored. Locations beyond
#'   the map (plus half a degree) are left out, with a message saying how many
#'   records that affects; if no location lies on the map, it stops with an
#'   error. The `austraits` package passes its map of Australia here.
#' @author Dony Indiarto - d.indiarto@student.unsw.edu.au
#' @return ggplot of sites
#' @examplesIf rlang::is_installed(c("ggplot2", "ggpointdensity", "viridis"))
#' # All traits from a given study
#' data <- austraits_lite %>%
#'   extract_dataset(dataset_id = "Falster_2003") %>%
#'   join_location_coordinates()
#' data %>% plot_locations("trait_name")
#'
#' # Single trait
#' data <- austraits_lite %>%
#'   extract_trait(trait_names = "plant_height") %>%
#'   join_location_coordinates()
#' data$traits %>% plot_locations("trait_name")
#'
#' # Without a map
#' data$traits %>% plot_locations("trait_name", basemap = NULL)
#'
#' # Over your own map: pass `basemap`, a data frame of land cells with columns
#' # x and y, such as `raster::as.data.frame(r, xy = TRUE, na.rm = TRUE)` of a
#' # land raster `r`. `austraits::plot_locations()` draws a map of Australia.
#' @export


plot_locations <- function(database, feature="trait_name", ..., basemap = "world"){

  rlang::check_installed(c("ggplot2", "ggpointdensity", "viridis"), reason = "to use `plot_locations()`")

  if(identical(basemap, "australia")){
    cli::cli_abort(c(
      "The map of Australia is now in the {.pkg austraits} package.",
      "i" = "Use {.fn austraits::plot_locations}, or pass a data frame of map cells as {.arg basemap}."
    ))
  }
  if(!is.null(basemap) && !identical(basemap, "world") &&
     !(is.data.frame(basemap) && all(c("x", "y") %in% names(basemap)) &&
       is.numeric(basemap$x) && is.numeric(basemap$y) &&
       any(!is.na(basemap$x) & !is.na(basemap$y)))){
    cli::cli_abort("{.arg basemap} must be {.val world}, NULL or a data frame with numeric columns {.field x} (longitude) and {.field y} (latitude)")
  }
  
  # Check if traits.build object or the traits table
  # If traits.build, check if traits table contains coordinate cols
  if( !is_flat(database) ){
    
    # Extract traits table if needed
    traits <- get_traits_table(database)
    
    if( length(stringr::str_which(names(traits), "(deg)")) < 2 ){
      cli::cli_alert_info("Coordinate columns were not detected, joining location tables now.")
      database <- database %>% join_location_coordinates()
      traits <- get_traits_table(database)
    }
  } else {
    traits <- database #If not traits.build, assign traits table as traits
    
    # Check if traits contains coordinate cols in traits table
    if( length(stringr::str_which(names(traits), "(deg)")) < 2 ) 
      cli::cli_abort("No location data found in traits table - try `join_location_coordinates()` first before `plot_locations()`")
  }
  
  plot_locations2(traits, feature, basemap = basemap, ...)
}

#' Location plot for AusTraits versions > 3.0.2
#' @noRd
plot_locations2 <- function(database, feature, basemap = "world", ...){
  #Create site data
  sites <-
    database %>%
    dplyr::select(tidyselect::all_of(as.character(feature[!is.na(feature)])), tidyselect::any_of(c("site_name", "location_name", "latitude (deg)", "longitude (deg)"))) %>%
    tidyr::drop_na() %>%
    dplyr::mutate(dplyr::across(c("longitude (deg)","latitude (deg)"), ~ suppressWarnings(as.numeric(.x)))) %>%
    dplyr::filter(!is.na(`latitude (deg)`), !is.na(`longitude (deg)`))

  if(nrow(sites) == 0){
    cli::cli_abort("No records have a numeric `latitude (deg)` and `longitude (deg)` to plot")
  }

  site_map <- ggplot2::ggplot()
  # The window to show; NULL lets the data set it
  window <- NULL

  if(identical(basemap, "world")){
    # Coordinates beyond the world, such as latitude and longitude swapped or
    # longitudes from 0 to 360, can't be placed on it
    sites <- keep_on_map(sites, c(-180, 180), c(-90, 90))
    window <- map_window(sites$`longitude (deg)`, sites$`latitude (deg)`)
    land <- world_map_raster(window$x, window$y)
    # Drawn as an image, rather than one tile per land cell
    site_map <- site_map +
      ggplot2::annotation_raster(
        ifelse(land$is_land, "cadetblue4", "#FFFFFF00"),
        xmin = land$x[1], xmax = land$x[2], ymin = land$y[1], ymax = land$y[2]
      )
  } else if(!is.null(basemap)){
    map_cells <- basemap %>%
      dplyr::ungroup() %>%
      dplyr::select("x", "y") %>%
      dplyr::filter(!is.na(x), !is.na(y)) %>%
      dplyr::mutate(land = factor(1))

    # Leave out locations beyond the map (plus a margin), saying so, rather
    # than letting a handful of distant locations shrink the map
    margin <- 0.5
    sites <- keep_on_map(sites,
                         range(map_cells$x) + c(-1, 1) * margin,
                         range(map_cells$y) + c(-1, 1) * margin)

    site_map <- site_map +
      ggplot2::geom_raster(data = map_cells, ggplot2::aes(x = x, y = y, fill = land), show.legend = FALSE)
  }

  #Create site map
  site_map <-
    site_map +
    # Add trait data
    ggpointdensity::geom_pointdensity(
      data = sites,
      ggplot2::aes(y = `latitude (deg)`, x = `longitude (deg)`),
      inherit.aes = FALSE,
      show.legend = TRUE,
      adjust = 1,
      ...
    ) +
    ggplot2::scale_fill_manual(values = "cadetblue4", na.value="white", guide = "none") +
    viridis::scale_color_viridis(option = "plasma") +
    ggplot2::theme(
      legend.justification = c(-0.1, 0),
      legend.position = "bottom",
      legend.direction  = "horizontal",
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.background = ggplot2::element_blank(),
      panel.border = ggplot2::element_rect(colour = "black", fill=NA, linewidth = 1),
      axis.ticks.length = ggplot2::unit(1, "mm"),
      axis.ticks = ggplot2::element_line(linewidth = 1)
    )  + ggplot2::xlab("") + ggplot2::ylab("") + 
    ggplot2::coord_fixed(xlim = window$x, ylim = window$y, expand = is.null(window))
  
  # facet by feature if specified - default
  if(!is.na(feature)){
    site_map <- site_map + ggplot2::facet_wrap(paste("~", feature))
  }
  suppressWarnings(print(site_map))
}


#' Leave out the locations beyond a map, saying how many records that affects
#'
#' Stops with an error if no location lies on the map.
#' @param sites the locations, with columns `longitude (deg)` and
#'   `latitude (deg)`
#' @param xlim,ylim the extent of the map
#' @noRd
keep_on_map <- function(sites, xlim, ylim){
  inside <-
    dplyr::between(sites$`longitude (deg)`, xlim[1], xlim[2]) &
    dplyr::between(sites$`latitude (deg)`, ylim[1], ylim[2])

  if(!any(inside)){
    cli::cli_abort(paste0(
      "None of the ", nrow(sites), " record(s) lie on the map. ",
      "Use `basemap = NULL` to show every location."
    ))
  }

  if(any(!inside)){
    outside <- sites[!inside, ]
    n_locations <- nrow(dplyr::distinct(outside, `latitude (deg)`, `longitude (deg)`))
    cli::cli_alert_info(paste0(
      sum(!inside), " record(s) at ", n_locations,
      " location(s) lie beyond the map and are not shown. ",
      "Use `basemap = NULL` to show every location."
    ))
    sites <- sites[inside, ]
  }
  sites
}

#' The window of the world map around a set of locations
#'
#' Their extent plus a margin of a tenth of it, and at least two degrees, so that
#' a single location still gets a map around it; within the world.
#' @noRd
map_window <- function(lon, lat){
  pad <- function(v, lim){
    margin <- max(2, 0.1 * diff(range(v)))
    c(max(-lim, min(v) - margin), min(lim, max(v) + margin))
  }
  list(x = pad(lon, 180), y = pad(lat, 90))
}

# The world map, read from inst/extdata/world_land.rds when first needed
world_land_cache <- new.env(parent = emptyenv())

world_land <- function(){
  if(is.null(world_land_cache$map)){
    world_land_cache$map <- readRDS(system.file("extdata", "world_land.rds", package = "traits.use", mustWork = TRUE))
  }
  world_land_cache$map
}

#' The world map within a window
#'
#' Unpacks only the rows of the map in the window. A wide window is shown
#' coarser, taking every `step`-th cell, so that no side has more than
#' `max_cells` cells and the plot stays quick to draw.
#' @param xlim,ylim the window, in degrees of longitude and latitude
#' @param max_cells the most cells along either side of the window
#' @return a list: `is_land`, a logical matrix of the cells covering the
#'   window, rows north to south and columns west to east, and `x` and `y`,
#'   the longitudes and latitudes of its edges
#' @noRd
world_map_raster <- function(xlim, ylim, max_cells = 600){
  map <- world_land()
  res <- map$res
  n_rows <- nrow(map$bits)
  n_cols <- 8 * ncol(map$bits)

  # Rows run north to south from 90, columns west to east from -180; take
  # those whose cells overlap the window
  rows <- seq(max(1, floor((90 - ylim[2]) / res) + 1), min(n_rows, ceiling((90 - ylim[1]) / res)))
  cols <- seq(max(1, floor((xlim[1] + 180) / res) + 1), min(n_cols, ceiling((xlim[2] + 180) / res)))

  # A wide window keeps every `step`-th cell: the middle one of each block of
  # `step` cells, which the image then draws over the whole block
  step <- max(1, ceiling(max(length(rows), length(cols)) / max_cells))
  first_row <- rows[seq(1, length(rows), by = step)]
  first_col <- cols[seq(1, length(cols), by = step)]
  rows <- pmin(first_row + step %/% 2, n_rows)
  cols <- pmin(first_col + step %/% 2, n_cols)

  # Each row of `bits` packs a row of the map, 8 cells a byte
  is_land <- matrix(as.logical(rawToBits(t(map$bits[rows, , drop = FALSE]))),
                    nrow = length(rows), byrow = TRUE)[, cols, drop = FALSE]

  # Each cell kept stands for `step` cells of the map, along each side
  west <- -180 + (first_col[1] - 1) * res
  north <- 90 - (first_row[1] - 1) * res
  list(
    is_land = is_land,
    x = c(west, west + length(cols) * step * res),
    y = c(north - length(rows) * step * res, north)
  )
}


#' Produce location maps of trait values 
#'
#' @description `r lifecycle::badge('deprecated')`
#'
#'Plot location where trait data was collected from
#' @param trait_data traits table in a traits.build database with site details appended. See join_location_coordinates and examples
#' @param feature grouping/classification categories e.g trait_name, collection_type for <= v3.0.2
#' @param ... arguments passed to ggplot()
#' @author Dony Indiarto - d.indiarto@student.unsw.edu.au
#' @return ggplot of sites
#' @export

plot_site_locations <- function(trait_data, feature="trait_name", ...){
  # Extract function name
  function_name <- as.character(sys.calls()[[1]])[1]
  
  cli::cli_abort(c(
    "i" = "{function_name} has been deprecated!",
    ">" =  "Use plot_locations() instead"
  )
  )
}
