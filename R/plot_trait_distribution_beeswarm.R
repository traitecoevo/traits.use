#' @title Beeswarm Trait distribution
#' @description `r lifecycle::badge('deprecated')`
#'
#' Use [plot_trait_distribution_jitter()] instead, which draws the same
#' distribution many times faster. `plot_trait_distribution_beeswarm()` now
#' draws and returns the jitter plot, with a deprecation warning.
#'
#' @inheritParams plot_trait_distribution_jitter
#'
#' @return The plot from [plot_trait_distribution_jitter()], invisibly, after
#'   drawing it
#' @keywords internal
#' @export
#'
#' @examples
#' \dontrun{
#' austraits %>% plot_trait_distribution_jitter("wood_density", "dataset_id", "Westoby_2014")
#' }
plot_trait_distribution_beeswarm <- function(database,
                                             trait_name,
                                             y_axis_category,
                                             highlight = NA,
                                             hide_ids = FALSE) {
  lifecycle::deprecate_warn(
    "0.1.0",
    "plot_trait_distribution_beeswarm()",
    "plot_trait_distribution_jitter()"
  )
  p <- plot_trait_distribution_jitter(database, trait_name, y_axis_category, highlight, hide_ids)
  print(p)
  invisible(p)
}
