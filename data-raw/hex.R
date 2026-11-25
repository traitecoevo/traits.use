## Make the traits.use hex sticker, man/figures/logo.png.
##
## Same look as traits.build's hex (white, green border and name), with its
## own icon: a database on the left with arrows carrying data out of it, and
## the AusTraits gumnut sprig, the family's stamp, in white on the database.
## Run from the root of the package; needs data-raw/austraits_sprig.svg (the
## AusTraits logo) and the rsvg package.

library(ggplot2)

green <- "chartreuse4"
light_green <- "#9BC27A"

# The database: three bands between lower half-ellipses, and a top cap
half_ellipse <- function(y, x0, a = 0.8, b = 0.22, n = 60) {
  t <- seq(pi, 2 * pi, length.out = n)
  data.frame(x = x0 + a * cos(t), y = y + b * sin(t))
}
band <- function(x0, bottom, height, id) {
  lower <- half_ellipse(bottom, x0)
  upper <- half_ellipse(bottom + height, x0)
  data.frame(rbind(lower, upper[nrow(upper):1, ]), id = id)
}
db_x <- -1.05
db_y <- 0.75
height <- 0.5
gap <- 0.12
bands <- do.call(rbind, lapply(0:2, function(i) band(db_x, db_y + i * (height + gap), height, i)))
top_y <- db_y + 2 * (height + gap) + height
t <- seq(0, 2 * pi, length.out = 120)
top <- data.frame(x = db_x + 0.8 * cos(t), y = top_y + 0.22 * sin(t))

# Arrows fanning gently out of the database, each carrying a few cells of data
arrows <- data.frame(x = db_x + 0.95, y = db_y + c(1.3, 0.95, 0.6),
                     xend = 0.85, yend = db_y + c(1.62, 0.95, 0.28))
cells <- do.call(rbind, lapply(seq_len(nrow(arrows)), function(i) {
  dx <- arrows$xend[i] - arrows$x[i]
  dy <- arrows$yend[i] - arrows$y[i]
  along <- c(1.22, 1.5, 1.73)
  data.frame(x = arrows$x[i] + dx * along, y = arrows$y[i] + dy * along,
             size = c(0.13, 0.1, 0.075))
}))

# The AusTraits sprig, stamped in white on the database
svg <- sub("#20542C", "#FFFFFF", readLines("data-raw/austraits_sprig.svg"), fixed = TRUE)
sprig <- magick::image_read_svg(paste(svg, collapse = "\n"), width = 900) |>
  magick::image_morphology("Dilate", "Disk:4") |>
  as.raster()

icon <- ggplot() +
  geom_polygon(data = bands, aes(x, y, group = id), fill = green, colour = NA) +
  geom_polygon(data = top, aes(x, y), fill = green, colour = "white", linewidth = 1) +
  geom_segment(data = arrows, aes(x, y, xend = xend, yend = yend),
               colour = "black", linewidth = 1.3, lineend = "round", linejoin = "mitre",
               arrow = arrow(length = unit(0.035, "npc"), type = "closed")) +
  geom_rect(data = cells, aes(xmin = x - size, xmax = x + size, ymin = y - size, ymax = y + size),
            fill = light_green, colour = green, linewidth = 0.4) +
  annotation_raster(sprig, xmin = db_x - 0.66, xmax = db_x + 0.66, ymin = db_y + 0.12, ymax = db_y + 1.44) +
  coord_fixed(xlim = c(-2, 2.2), ylim = c(0.2, 3.1)) +
  theme_void() +
  theme(plot.background = element_rect(fill = "transparent", colour = NA),
        panel.background = element_rect(fill = "transparent", colour = NA))

make <- function(filename, p_size = 22) {
  hexSticker::sticker(
    icon, package = "traits.use",
    p_color = green, p_size = p_size, p_y = 1.5,
    s_x = 1.04, s_y = 0.86, s_width = 1.45, s_height = 1.45,
    h_fill = "white", h_color = green, h_size = 1.1,
    filename = filename
  )
}

make("man/figures/logo.png")
