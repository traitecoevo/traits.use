# Extracted from test-sources.R:82

# prequel ----------------------------------------------------------------------
plain <- austraits_5.0.0_lite$sources
sources <- as_traits_build_sources(plain)
key <- "Falster_2003"
some_keys <- c("Falster_2003", "Falster_2005_1", "Crous_2013")

# test -------------------------------------------------------------------------
entry <- function(key, title) {
    RefManageR::BibEntry(bibtype = "Article", key = key, title = title,
                         author = "Ann Author", journal = "J", year = 2001)
  }
k <- as_traits_build_sources(c(entry("title", "T"), entry("key", "K"), entry("Smith_2001", "S")))
expect_identical(names(k), c("title", "key", "Smith_2001"))
