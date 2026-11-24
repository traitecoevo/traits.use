## Build `austraits_lite`, the example database exported by traits.use.
##
## Usage, from the root of traits.use:
##   Rscript data-raw/austraits_lite.R [path to an austraits.build clone] [git ref]
## The defaults are ../austraits.build and origin/develop (fetch it first).
##
## `austraits_lite` is built from austraits.build *source at a pinned commit*,
## with the traits.build installed here, rather than taken from a release of
## AusTraits (#13). A traits.use release has to come before the AusTraits
## release whose data model it reads, so the example data could never be from
## that release. Rebuild it whenever traits.build changes the data model: a test
## (test-data.R) fails until `austraits_lite` records the newest data model
## traits.use reads. Release order: traits.build develop -> rebuild this ->
## traits.use release -> traits.build release -> AusTraits release.
##
## Update `?austraits_lite` (R/data.R) with the commit and traits.build version
## this prints.

args <- commandArgs(trailingOnly = TRUE)
repo <- if (length(args) >= 1) args[[1]] else "../austraits.build"
ref <- if (length(args) >= 2) args[[2]] else "origin/develop"

# The datasets: the 24 of the AusTraits 5.0.0 and 7.0.0 builds of
# `austraits_lite`, chosen for coverage (contexts, locations, sources,
# identifiers from Schulze_2014, several value types).
dataset_ids <- c(
  "ABRS_1981", "Apgaua_2017", "Bloomfield_2018", "Buckton_2019", "Cernusak_2006",
  "Choat_2006", "Choat_2012", "Crous_2013", "Crous_2019", "Falster_2003",
  "Falster_2005_1", "Falster_2005_2", "Grigg_2008", "Kew_2019_2", "Kooyman_2011",
  "Leigh_2003", "Prior_2003", "Prior_2016", "Roderick_1999", "Schulze_2014",
  "Vesk_2019", "Westoby_2014", "Wright_2019", "Yang_2023"
)

devtools::load_all()
library(traits.build)

sha <- system2("git", c("-C", repo, "rev-parse", paste0(ref, "^{commit}")), stdout = TRUE)
src <- tempfile("austraits.build-")
dir.create(src)
status <- system(sprintf("git -C %s archive %s | tar -x -C %s", shQuote(repo), sha, shQuote(src)))
stopifnot(status == 0)

missing <- dataset_ids[!dir.exists(file.path(src, "data", dataset_ids))]
if (length(missing) > 0) {
  stop("Not in austraits.build ", sha, ": ", paste(missing, collapse = ", "))
}

austraits_lite <- withr::with_dir(src, {
  schema <- get_schema()
  resource_metadata <- get_schema("config/metadata.yml", "metadata")
  definitions <- get_schema("config/traits.yml", "traits")
  unit_conversions <- get_unit_conversions("config/unit_conversions.csv")
  taxon_list <- read_csv_char("config/taxon_list.csv")

  datasets <- lapply(dataset_ids, function(id) {
    config <- dataset_configure(file.path("data", id, "metadata.yml"), definitions)
    raw <- dataset_process(file.path("data", id, "data.csv"), config, schema,
                           resource_metadata, unit_conversions)
    dataset_update_taxonomy(raw, taxon_list)
  })

  database <- do.call(bind_databases, datasets)
  database <- build_add_version(database, util_get_version("config/metadata.yml"), sha)
  build_post_process(database)
})

message(sprintf(
  "austraits_lite: %d datasets, %d trait rows, data model %s, from austraits.build %s (version %s) with traits.build %s",
  length(unique(austraits_lite$traits$dataset_id)), nrow(austraits_lite$traits),
  austraits_lite$metadata$data_model_version, sha, austraits_lite$build_info$version,
  packageVersion("traits.build")
))

usethis::use_data(austraits_lite, compress = "xz", overwrite = TRUE)
