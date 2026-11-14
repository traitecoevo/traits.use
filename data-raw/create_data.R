
## code to prepare an example dataset, that go public
## austraits::load_austraits() is in the austraits package (moved out of traits.use 0.1.0)

devtools::load_all()
path = "ignore/data/austraits"

# 3.0.2
austraits_3.0.2 <- austraits::load_austraits(version = "3.0.2", path = path)

austraits_3.0.2_lite <- list()

austraits_3.0.2_lite$traits <- austraits_3.0.2$traits %>% dplyr::filter(is.na(dataset_id))

# 4.2.0
austraits_4.2.0 <- austraits::load_austraits(version = "4.2.0", path = path)

austraits_4.2.0_lite <- list()
austraits_4.2.0_lite$traits <- austraits_4.2.0$traits %>% dplyr::filter(is.na(dataset_id))
austraits_4.2.0_lite$metadata <- austraits_4.2.0$metadata

# 5.0.0
austraits_5.0.0 <- austraits::load_austraits(version = "5.0.0", path = path)

set.seed(109)

dataset_id <- c(unique(austraits_5.0.0$traits$dataset_id) %>% sample(5))


datasets <- c("Falster_2003", "Falster_2005_1", "Falster_2005_2",
              "Crous_2013", "Crous_2019", "Buckton_2019", "Kooyman_2011", "Bloomfield_2018", 
              "Wright_2019", "Westoby_2014", "Vesk_2019", "Leigh_2003", "Prior_2003",
              "Prior_2016", "Choat_2006", "Choat_2012", "ABRS_1981", "Cernusak_2006", "Yang_2023")

# Exported as `austraits_lite`, the database used in the examples and tests
# (the tests call it austraits_5.0.0_lite, see tests/testthat/helper.R)
austraits_lite <- austraits_5.0.0 %>% extract_dataset(dataset_id = c(dataset_id, datasets))

## The map of Australia (`australia_map_raster`) moved to the austraits package
usethis::use_data(austraits_lite, compress = "xz", overwrite = TRUE)
usethis::use_data(austraits_3.0.2_lite, austraits_4.2.0_lite, internal = TRUE, overwrite = TRUE)
