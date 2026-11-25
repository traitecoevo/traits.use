## Build the tests' fixture of an older AusTraits release, kept internal (R/sysdata.rda)
## austraits::load_austraits() is in the austraits package (moved out of traits.use 0.1.1)
##
## The tests' main fixture is `austraits_lite`, the exported example database,
## built by data-raw/austraits_lite.R from austraits.build source. This one
## tests releases in the older form traits.use still reads. Releases before
## 5.0.0 are not supported, and have no fixture.

devtools::load_all()
path = "ignore/data/austraits"

# 5.0.0: a release built before traits.build 2.3, with no data model version,
# the old reference columns of `methods` (`source_primary_key` etc.), some
# observations without a `source_id`, and its sources a plain BibEntry, as in
# the .rds of a release. The datasets are the ones the tests name:
# - Westoby_2014: its own reference is keyed Gleason_2012
# - Prior_2003: a secondary reference (Prior_2004)
# - Choat_2012: an original dataset's reference (Brodribb_2009), and free-text
#   `source_id` values (Brodribb_unpub)
# - Yang_2023: a `source_id` that is not a key (Thiele_2017_1)
# - Apgaua_2017: observations without a `source_id`
# - Falster_2003, Falster_2005_1, Falster_2005_2, Crous_2013: the sources tests
austraits_5.0.0 <- austraits::load_austraits(version = "5.0.0", path = path)

lite_ids <- c("Apgaua_2017", "Choat_2012", "Crous_2013", "Falster_2003", "Falster_2005_1",
              "Falster_2005_2", "Prior_2003", "Westoby_2014", "Yang_2023")
austraits_5.0.0_lite <- austraits_5.0.0 %>% extract_dataset(dataset_id = lite_ids)
class(austraits_5.0.0_lite$sources) <- setdiff(class(austraits_5.0.0_lite$sources), "traits_build_sources")

## The map of Australia (`australia_map_raster`) moved to the austraits package
usethis::use_data(austraits_5.0.0_lite, internal = TRUE, compress = "xz", overwrite = TRUE)
