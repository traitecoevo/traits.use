not_supported_austraits <- list(austraits_3.0.2_lite, austraits_4.2.0_lite)


test_that("Function doesn't throw error", {
  
  #expect_invisible(austraits_5.0.0_lite %>% plot_trait_distribution_beeswarm("leaf_mass_per_area", "dataset_id", "Bloomfield_2018"))
  
  expect_invisible(austraits_5.0.0_lite %>% plot_trait_distribution_beeswarm("leaf_mass_per_area", "dataset_id"))
  
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
  expect_error(austraits_3.0.2_lite |> plot_trait_distribution_beeswarm())
  expect_error(austraits_5.0.0_lite |> plot_trait_distribution_beeswarm("branch_mass_fraction", y_axis_category = "location_property"))
}) 


# Tear down code
unlink("Rplots.pdf")