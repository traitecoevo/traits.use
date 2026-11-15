## code to prepare inst/extdata/world_land.rds, the world map that
## plot_locations() crops to the locations it draws (#42)
##
## Source: Natural Earth 1:10m land polygons (public domain,
## https://www.naturalearthdata.com/), rasterised to a 0.05 degree grid, the
## resolution of the map of Australia in the austraits package. A cell is land
## if its centre lies in a land polygon.
##
## Stored as a raw matrix of 3600 rows (latitude, north to south, from 90 to
## -90) by 900 bytes, each byte packing 8 cells of a row (longitude, west to
## east, from -180 to 180) with packBits(): 76 kB on disk, rather than the
## many MB of a data frame of land cells. world_map_raster() unpacks only the
## rows it needs.

res <- 0.05

land <- rnaturalearth::ne_download(scale = 10, type = "land", category = "physical", returnclass = "sf")

grid <- terra::rast(xmin = -180, xmax = 180, ymin = -90, ymax = 90, resolution = res)
is_land <- terra::rasterize(terra::vect(land), grid, background = 0)
is_land <- terra::as.matrix(is_land, wide = TRUE) == 1

stopifnot(dim(is_land) == c(180 / res, 360 / res), !anyNA(is_land))

bits <- matrix(packBits(as.logical(t(is_land)), "raw"), nrow = nrow(is_land), byrow = TRUE)

world_land <- list(
  bits = bits,
  res = res,
  source = paste0(
    "Natural Earth 1:10m land (public domain, https://www.naturalearthdata.com/), ",
    "downloaded ", Sys.Date(), " with rnaturalearth ", utils::packageVersion("rnaturalearth")
  )
)

saveRDS(world_land, "inst/extdata/world_land.rds", compress = "xz")
