not_supported_austraits <- list(austraits_3.0.2_lite, austraits_4.2.0_lite)


test_that("Function doesn't throw error", {
  
  expect_s3_class(austraits_5.0.0_lite %>% plot_trait_distribution_jitter("leaf_mass_per_area", "dataset_id", "Bloomfield_2018"), "ggplot")

  # The beeswarm plot is deprecated: it draws the jitter plot instead
  lifecycle::expect_deprecated(
    p <- austraits_5.0.0_lite %>% plot_trait_distribution_beeswarm("leaf_mass_per_area", "dataset_id")
  )
  expect_s3_class(p, "ggplot")
  
  # this function is currently really slow, blocking effective testing
  expect_invisible((austraits_5.0.0_lite %>% extract_trait("wood_density") %>% join_location_coordinates())$trait %>% plot_locations())
  expect_invisible(austraits_5.0.0_lite %>% extract_trait("wood_density") %>% plot_locations())
 }) 



test_non_compatibile <- function(austraits){
  test_that("Throws correct errors for deprecated or non-compatible",{
    expect_error(austraits %>% 
                   extract_dataset("Falster_2003") %>% 
                   purrr::pluck("traits") %>% plot_locations()
    )
    
    expect_error(austraits %>% 
                   extract_dataset("Falster_2003") %>% 
                   purrr::pluck("traits") %>% plot_site_locations()
    )
  })
}

purrr::walk(not_supported_austraits,
            test_non_compatibile)

test_that("plot_locations draws over a basemap, reporting locations beyond it", {
  sites <- tibble::tibble(
    trait_name = "leaf_area",
    location_name = c("Perth", "Brisbane", "Byron Bay", "Torres Strait", "Lord Howe Island", "Kuala Lumpur"),
    `latitude (deg)` = c(-31.95, -27.47, -28.64, -9.4, -31.55, 3.14),
    `longitude (deg)` = c(115.86, 153.03, 153.61, 142.2, 159.08, 101.69)
  )
  shown <- function(p) sort(unique(p$layers[[length(p$layers)]]$data$location_name))

  # A coarse stand-in with the extent of the map of Australia the austraits
  # package passes (x 112.95 to 153.60, y -43.62 to -9.27), in the same shape:
  # x, y and a value column
  australia <- expand.grid(
    x = seq(112.95, 153.60, length.out = 20),
    y = seq(-43.616667, -9.266667, length.out = 20)
  )
  australia$australia <- 1

  # Brisbane and Byron Bay (east of 153) and the Torres Strait (north of -9.5)
  # are on the map; locations beyond it are reported
  expect_message(p <- plot_locations(sites, basemap = australia), "2 record\\(s\\) at 2 location\\(s\\) lie beyond the map")
  expect_equal(shown(p), sort(c("Perth", "Brisbane", "Byron Bay", "Torres Strait")))
  expect_length(p$layers, 2)

  # Without a map (the default), every location is shown
  p <- plot_locations(sites)
  expect_equal(shown(p), sort(sites$location_name))
  expect_length(p$layers, 1)

  # Coordinates that are not numbers are left out rather than failing
  sites_bad <- sites
  sites_bad$`latitude (deg)` <- as.character(sites_bad$`latitude (deg)`)
  sites_bad$`latitude (deg)`[1] <- "unknown"
  p <- plot_locations(sites_bad)
  expect_false("Perth" %in% shown(p))

  # feature = NA draws one map instead of one per feature
  p <- plot_locations(sites, feature = NA)
  expect_equal(shown(p), sort(sites$location_name))

  # The map of Australia is in the austraits package now
  expect_error(plot_locations(sites, basemap = "australia"), "austraits")
  expect_error(plot_locations(sites, basemap = "malaysia"), "must be NULL or a data frame")
  expect_error(plot_locations(sites, basemap = data.frame(lon = 1, lat = 1)), "must be NULL or a data frame")
  expect_error(plot_locations(sites, basemap = australia[0, ]), "must be NULL or a data frame")
  expect_error(plot_locations(sites, basemap = data.frame(x = NA_real_, y = NA_real_)), "must be NULL or a data frame")

  # Cells missing a coordinate are ignored, rather than making the extent NA,
  # and a grouped basemap works too
  with_na <- rbind(australia, data.frame(x = NA, y = -30, australia = NA))
  expect_message(p <- plot_locations(sites, basemap = with_na), "2 record\\(s\\) at 2 location\\(s\\)")
  expect_equal(nrow(p$layers[[1]]$data), nrow(australia))
  grouped <- dplyr::group_by(australia, australia)
  expect_no_message(p <- plot_locations(sites[1:4, ], basemap = grouped))
  expect_named(p$layers[[1]]$data, c("x", "y", "land"))

  # No location on the map says to use basemap = NULL, rather than failing
  # inside facet_wrap() on an empty layer
  expect_error(plot_locations(sites[sites$location_name == "Kuala Lumpur", ], basemap = australia), "Use `basemap = NULL`")
  sites_none <- sites
  sites_none$`latitude (deg)` <- "unknown"
  expect_error(plot_locations(sites_none), "No records have a numeric")
})

test_that("Function throws error", {
  expect_error(austraits_5.0.0_lite$traits |> plot_locations())
  expect_error(austraits_3.0.2_lite$traits |> plot_site_locations())
  expect_error(austraits_3.0.2_lite |> plot_site_locations())
  expect_error(austraits_3.0.2_lite |> plot_trait_distribution_jitter("leaf_area", "dataset_id"))
  expect_error(austraits_5.0.0_lite |> plot_trait_distribution_jitter("branch_mass_fraction", y_axis_category = "location_property"), "Incorrect grouping variable")
}) 


test_that("plotting functions say which suggested packages they need", {
  # Calls go through rlang::check_installed(), which stops when one is missing
  needed <- NULL
  local_mocked_bindings(
    check_installed = function(pkg, reason = NULL, ...) {
      needed <<- c(needed, pkg)
      rlang::abort(paste("needs", paste(pkg, collapse = ", ")))
    },
    .package = "rlang"
  )
  expect_error(plot_locations(austraits_5.0.0_lite), "needs")
  expect_equal(needed, c("ggplot2", "ggpointdensity", "viridis"))
  needed <- NULL
  expect_error(plot_trait_distribution_jitter(austraits_5.0.0_lite, "leaf_mass_per_area", "dataset_id"), "needs")
  expect_equal(needed, c("ggplot2", "forcats", "scales"))
  needed <- NULL
  expect_error(plot_categorical_trait_distribution(austraits_5.0.0_lite, "leaf_compoundness"), "needs")
  expect_equal(needed, "ggplot2")
})

trait_table <- function(value, value_type = "mean", family = "Myrtaceae",
                        trait_name = "leaf_area", unit = "mm2", ...) {
  tibble::tibble(
    dataset_id = "Test_2025", taxon_name = paste("Taxon", seq_along(value)),
    trait_name = trait_name, value = as.character(value), unit = unit,
    value_type = value_type, family = family, ...
  )
}

test_that("plot_trait_distribution_jitter plots numeric values by group", {
  d <- austraits_5.0.0_lite
  p <- plot_trait_distribution_jitter(d, "leaf_mass_per_area", "family", highlight = "Proteaceae")
  expect_s3_class(p, "ggplot")
  built <- ggplot2::ggplot_build(p)

  # family is joined from the taxa table, one row per family
  lma <- d$traits[d$traits$trait_name == "leaf_mass_per_area", ]
  families <- unique(d$taxa$family[d$taxa$taxon_name %in% lma$taxon_name])
  expect_setequal(levels(p$data$Group), stats::na.omit(families))
  expect_equal(nrow(p$data), nrow(lma))
  expect_true(all(p$data$colour[p$data$Group == "Proteaceae"] == "c"))
  # Values span more than a factor of 20, so the x-axis is on a log scale
  expect_equal(p$scales$get_scales("x")$trans$name, "log-10")

  # The trait name is matched exactly: leaf_area is not leaf_area_ratio etc.
  t <- rbind(trait_table(1:3), trait_table(100, trait_name = "leaf_area_ratio"))
  p <- plot_trait_distribution_jitter(t, "leaf_area", "family")
  expect_equal(sort(p$data$value), 1:3)

  # Bins, ranges and values that are not numbers are left out
  t <- trait_table(c("1", "2--5", "3", "unknown"), value_type = c("mean", "bin", "range", "mean"))
  p <- plot_trait_distribution_jitter(t, "leaf_area", "family")
  expect_equal(p$data$value, 1)

  # Nothing left to plot gives an empty plot saying so
  p <- plot_trait_distribution_jitter(trait_table("2--5", value_type = "bin"), "leaf_area", "family")
  expect_match(p$layers[[1]]$aes_params$label, "No numeric values of leaf_area")
})

test_that("plot_trait_distribution_jitter keeps every value within the limits", {
  # 0.8 * min used to cut off the lowest negative values
  t <- trait_table(c(-5, -1, 2, 10), family = c("A", "A", "B", "B"))
  p <- plot_trait_distribution_jitter(t, "leaf_area", "family")
  limits <- p$scales$get_scales("x")$limits
  expect_true(limits[1] < -5 && limits[2] > 10)
  # ggplot2 reports points outside the limits when the plot is drawn
  expect_no_warning(ggplot2::ggplotGrob(p))
  expect_no_warning(ggplot2::ggplotGrob(plot_trait_distribution_jitter(trait_table(c(-6, -1)), "leaf_area", "family")))

  # A single value, or all values zero, still plot
  expect_no_warning(ggplot2::ggplotGrob(plot_trait_distribution_jitter(trait_table(0), "leaf_area", "family")))
  expect_no_warning(ggplot2::ggplotGrob(plot_trait_distribution_jitter(trait_table(3), "leaf_area", "family")))
})

test_that("plot_categorical_trait_distribution plots proportions by family", {
  # Taxon 1 is scored twice, once as "simple compound", so counts 0.75 simple
  # and 0.25 compound; families are ordered by their proportion of the most
  # common value
  t <- tibble::tibble(
    dataset_id = c("D1", "D2", "D1", "D1", "D1", "D1"),
    taxon_name = c("T1", "T1", "T2", "T3", "T4", "T5"),
    trait_name = "leaf_compoundness", unit = NA_character_, value_type = "mode",
    value = c("simple", "simple compound", "simple", "compound", "compound", "simple"),
    family = c("A", "A", "A", "B", "B", "C")
  )
  p <- plot_categorical_trait_distribution(t, "leaf_compoundness")
  expect_s3_class(p, "ggplot")
  props <- p$data
  expect_equal(levels(props$value), c("simple", "compound"))
  expect_equal(props$prop[props$family == "A" & props$value == "simple"], 1.75 / 2)
  expect_equal(props$prop[props$family == "A" & props$value == "compound"], 0.25 / 2)
  expect_equal(props$prop[props$family == "B"], 1)
  expect_equal(as.vector(tapply(props$prop, props$family, sum)), c(1, 1, 1))
  expect_equal(levels(props$family), c("C", "A", "B"))

  # family_count keeps the families with the most taxa
  p <- plot_categorical_trait_distribution(t, "leaf_compoundness", family_count = 1)
  expect_equal(as.character(unique(p$data$family)), "A")

  # A whole database gets family from its taxa table
  p <- plot_categorical_trait_distribution(austraits_5.0.0_lite, "leaf_compoundness", family_count = 10)
  expect_equal(length(unique(p$data$family)), 10)
  expect_no_warning(ggplot2::ggplotGrob(p))

  expect_error(plot_categorical_trait_distribution(dplyr::select(t, -family), "leaf_compoundness"), "family")
  expect_error(plot_categorical_trait_distribution(t, c("a", "b")), "single trait name")
})

test_that("plot_trait_distribution picks the plot from the trait's type", {
  d <- austraits_5.0.0_lite
  p <- plot_trait_distribution(d, "leaf_compoundness")
  expect_true("counts_per_value" %in% names(p$data))
  p <- plot_trait_distribution(d, "plant_height", hide_ids = TRUE)
  expect_true("Group" %in% names(p$data))
  expect_equal(p$labels$y, "By family")

  # For a traits table, a trait without units is categorical
  t <- trait_table(c("simple", "compound"), trait_name = "leaf_compoundness", unit = NA_character_)
  expect_true("counts_per_value" %in% names(plot_trait_distribution(t, "leaf_compoundness")$data))
  p <- plot_trait_distribution(trait_table(1:3), "leaf_area", y_axis_category = "dataset_id")
  expect_equal(levels(p$data$Group), "Test_2025")
})

test_that("trait plots give a blank plot when there is nothing to plot", {
  label <- function(p) p$layers[[1]]$aes_params$label
  t <- trait_table(1:3)

  # A trait not in the data, an empty table, or NULL (as the portal passes)
  expect_match(label(plot_trait_distribution_jitter(t, "leaf_width", "family")), "No numeric values of leaf_width")
  expect_match(label(plot_categorical_trait_distribution(t[0, ], "leaf_area")), "No values of leaf_area")
  expect_match(label(plot_trait_distribution(NULL, "leaf_area")), "No values of leaf_area")
  expect_match(label(plot_trait_distribution(austraits_5.0.0_lite, "not_a_trait")), "No values of not_a_trait")

  # A plain data.frame works like a tibble
  p <- plot_trait_distribution_jitter(as.data.frame(t), "leaf_area", "family")
  expect_equal(sort(p$data$value), 1:3)
})

test_that("plot_trait_distribution ignores arguments the chosen plot does not take", {
  d <- austraits_5.0.0_lite
  args <- list(y_axis_category = "dataset_id", hide_ids = TRUE, family_count = 5)
  p <- do.call(plot_trait_distribution, c(list(d, "leaf_compoundness"), args))
  expect_lte(length(unique(p$data$family)), 5)
  p <- do.call(plot_trait_distribution, c(list(d, "plant_height"), args))
  expect_equal(p$labels$y, "By dataset_id")
})

test_that("plot_trait_distribution_jitter highlights several groups and labels without units", {
  t <- trait_table(1:4, family = c("A", "B", "C", "D"), unit = NA_character_)
  p <- plot_trait_distribution_jitter(t, "leaf_area", "family", highlight = c("A", "C"))
  expect_equal(sort(as.character(p$data$Group[p$data$colour == "c"])), c("A", "C"))
  expect_equal(p$scales$get_scales("x")$name, "leaf_area")
})
