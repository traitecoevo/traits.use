#' @title Plot the distribution of a trait
#' @description Plots the values of one trait, choosing the plot from the
#'   trait's type: [plot_trait_distribution_jitter()] by family for a numeric
#'   trait, [plot_categorical_trait_distribution()] for a categorical one.
#'
#' @param database traits.build database (list object), or its traits table
#'   (which must then have a `family` column, e.g. from [join_taxa()])
#' @param trait_name Name of the trait to plot (matched exactly)
#' @param ... Further named arguments: `y_axis_category` (default
#'   `"family"`), `highlight` and `hide_ids` for a numeric trait, passed to
#'   [plot_trait_distribution_jitter()]; `family_count` for a categorical
#'   trait, passed to [plot_categorical_trait_distribution()]. Arguments the
#'   chosen plot does not take are ignored, so one set of arguments can be
#'   used for traits of both types.
#'
#' @return A ggplot object. With no values to plot (an empty or `NULL`
#'   input, or a trait not in it), a blank plot saying so.
#' @export
#'
#' @examplesIf rlang::is_installed(c("ggplot2", "forcats", "scales"))
#' austraits_lite %>% plot_trait_distribution("wood_density")
#' austraits_lite %>% plot_trait_distribution("leaf_compoundness")
plot_trait_distribution <- function(database, trait_name, ...) {
  rlang::check_installed("ggplot2", reason = "to use `plot_trait_distribution()`")

  data <- trait_plot_data(database, trait_name)
  if (is.null(data) || nrow(data) == 0) {
    return(no_data_plot(paste0("No values of ", trait_name, " to plot")))
  }

  # The trait's type from its definition; for a traits table, categorical
  # traits are the ones without units
  type <- NA
  if (is.null(dim(database))) {
    type <- purrr::pluck(database, "definitions", trait_name, "type", .default = NA)
  }
  if (is.na(type)) {
    type <- if (all(is.na(data$unit))) "categorical" else "numeric"
  }

  if (identical(type, "categorical")) {
    plot_fn <- plot_categorical_trait_distribution
    args <- list()
  } else {
    plot_fn <- plot_trait_distribution_jitter
    args <- list(y_axis_category = "family")
  }

  # Keep the named arguments the chosen plot takes
  dots <- list(...)
  dots <- dots[intersect(names(dots), setdiff(names(formals(plot_fn)), c("database", "trait_name")))]
  args[names(dots)] <- dots

  do.call(plot_fn, c(list(data, trait_name), args))
}

#' @title Plot the distribution of a categorical trait by family
#' @description For the families with the most taxa scored for a categorical
#'   trait, plots the proportion of each family's taxa with each value of the
#'   trait. Each taxon counts once: within a dataset, a taxon's distinct values
#'   share its weight equally (a value cell such as `"simple compound"` counts
#'   as both values), and its datasets are then combined. Values are ordered
#'   from most to least common in the families shown. Ties between families at
#'   the `family_count` cut-off are broken alphabetically.
#'
#' @inheritParams plot_trait_distribution
#' @param family_count Number of families to show: those with the most taxa
#'   scored for the trait
#'
#' @return A ggplot object, or a blank plot saying there are no values to plot
#' @export
#'
#' @examplesIf rlang::is_installed("ggplot2")
#' austraits_lite %>% plot_categorical_trait_distribution("leaf_compoundness", family_count = 20)
plot_categorical_trait_distribution <- function(database, trait_name, family_count = 50) {
  rlang::check_installed("ggplot2", reason = "to use `plot_categorical_trait_distribution()`")

  data <- trait_plot_data(database, trait_name)

  if (is.null(data) || nrow(data) == 0) {
    return(no_data_plot(paste0("No values of ", trait_name, " to plot")))
  }
  if (!"family" %in% names(data)) {
    cli::cli_abort("The traits table needs a {.field family} column: pass the whole database, or use {.fn join_taxa} first.")
  }

  # Proportion of each taxon's observations with each value
  prop_by_species <- data %>%
    dplyr::select("family", "taxon_name", "value", "dataset_id") %>%
    # An observation with several values (polymorphic scorings) is split
    tidyr::separate_longer_delim("value", delim = " ") %>%
    dplyr::distinct() %>%
    # ... and each of its values gets a fractional weight
    dplyr::group_by(family, taxon_name, dataset_id) %>%
    dplyr::mutate(scaled_by_obs = 1 / dplyr::n()) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(family, taxon_name, value) %>%
    dplyr::summarise(counts = sum(scaled_by_obs), .groups = "drop") %>%
    dplyr::group_by(family, taxon_name) %>%
    dplyr::mutate(prop = counts / sum(counts)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-"counts")

  # The families with the most taxa scored
  most_common_families <- prop_by_species %>%
    dplyr::distinct(family, taxon_name) %>%
    dplyr::count(family, name = "species_per_family") %>%
    dplyr::arrange(dplyr::desc(species_per_family)) %>%
    dplyr::slice_head(n = family_count)

  # Combine taxon-level proportions into family-level ones
  prop_by_family <- prop_by_species %>%
    dplyr::filter(family %in% most_common_families$family) %>%
    dplyr::group_by(family, value) %>%
    dplyr::summarise(counts_per_value = sum(prop), .groups = "drop") %>%
    dplyr::group_by(family) %>%
    dplyr::mutate(prop = counts_per_value / sum(counts_per_value)) %>%
    dplyr::ungroup()

  # Order values (x-axis) from most to least common across all taxa
  counts_by_value <- prop_by_family %>%
    dplyr::group_by(value) %>%
    dplyr::summarise(total_counts = sum(counts_per_value), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(total_counts)) %>%
    dplyr::pull(value)

  prop_by_family <- prop_by_family %>%
    dplyr::mutate(value = factor(value, levels = counts_by_value))

  # Order families by their proportion of the most common value; families
  # without it by the next most common value, and so on
  family_vector <- prop_by_family %>%
    dplyr::arrange(value, dplyr::desc(prop)) %>%
    dplyr::mutate(row_counter = dplyr::row_number()) %>%
    dplyr::group_by(family) %>%
    dplyr::summarise(family_order = min(row_counter), .groups = "drop") %>%
    dplyr::arrange(family_order) %>%
    dplyr::pull(family)

  prop_by_family <- prop_by_family %>%
    dplyr::mutate(family = factor(family, levels = family_vector)) %>%
    # Occasional observations have no family
    dplyr::filter(!is.na(family), prop > 0) %>%
    dplyr::arrange(family)

  ggplot2::ggplot(prop_by_family, ggplot2::aes(y = family, x = value, fill = prop, size = counts_per_value)) +
    ggplot2::geom_jitter(shape = 21, width = 0.15, height = 0) +
    ggplot2::scale_size_continuous() +
    ggplot2::scale_fill_viridis_c(option = "D") +
    ggplot2::labs(
      x = NULL, y = NULL,
      fill = "prop of species in family",
      size = "species count"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.line.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor.x = ggplot2::element_blank(),
      panel.grid.minor.y = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(linewidth = 0.05)
    )
}

#' @title Plot the distribution of a numeric trait by group
#' @description Plots the values of a numeric trait as points, one row per
#'   group (e.g. dataset or family), with groups ordered by their mean value.
#'   The shape of each point shows whether it is a minimum, mean or maximum.
#'   The x-axis is on a log scale when the values are all positive and the
#'   largest is more than about 13 times the smallest (so the axis, padded by
#'   20% each side, spans more than a factor of 20). Values recorded as a bin
#'   or range are left out.
#'
#'   Replaces [plot_trait_distribution_beeswarm()], drawing many times faster.
#'
#' @inheritParams plot_trait_distribution
#' @param y_axis_category Column to group values by, e.g. `"dataset_id"` or
#'   `"family"`. `family` and `genus` are added from the taxa table when
#'   `database` is a whole database.
#' @param highlight One or more groups to highlight in a different colour
#' @param hide_ids Hide the group labels on the y-axis?
#'
#' @return A ggplot object, or a blank plot saying there are no numeric values
#'   to plot. Each point also carries a `text` aesthetic
#'   (`"dataset_id | taxon_name"`), which `plotly::ggplotly()` shows as a tooltip.
#' @export
#'
#' @examplesIf rlang::is_installed(c("ggplot2", "forcats", "scales"))
#' austraits_lite %>% plot_trait_distribution_jitter("wood_density", "dataset_id", "Westoby_2014")
#' @author Daniel Falster - daniel.falster@unsw.edu.au
plot_trait_distribution_jitter <- function(database,
                                           trait_name,
                                           y_axis_category,
                                           highlight = NA,
                                           hide_ids = FALSE) {
  rlang::check_installed(c("ggplot2", "forcats", "scales"), reason = "to use `plot_trait_distribution_jitter()`")

  data <- trait_plot_data(database, trait_name)
  if (is.null(data) || nrow(data) == 0) {
    return(no_data_plot(paste0("No numeric values of ", trait_name, " to plot")))
  }
  if (!y_axis_category %in% names(data)) {
    cli::cli_abort("Incorrect grouping variable! Grouping variable must be a variable in or joined to the traits table. Family and genus are supported if your input is a complete traits.build database.")
  }

  data <- data %>%
    dplyr::filter(!value_type %in% c("bin", "range")) %>%
    dplyr::mutate(value = suppressWarnings(as.numeric(value))) %>%
    dplyr::filter(!is.na(value))

  if (nrow(data) == 0) {
    return(no_data_plot(paste0("No numeric values of ", trait_name, " to plot")))
  }

  my_shapes <- c("Minimum" = 60, "Mean" = 16, "Maximum" = 62, "Unknown" = 18)

  as_shape <- function(value_type) {
    p <- rep("Unknown", length(value_type))
    p[grepl("mean", value_type)] <- "Mean"
    p[grepl("min", value_type)] <- "Minimum"
    p[grepl("max", value_type)] <- "Maximum"
    factor(p, levels = names(my_shapes))
  }

  data <- data %>%
    dplyr::mutate(shapes = as_shape(value_type))

  # Order groups by their mean value, on a log scale where possible
  if (min(data$value) > 0) {
    data$value2 <- log10(data$value)
  } else {
    data$value2 <- data$value
  }
  data$Group <- forcats::fct_reorder(as.character(data[[y_axis_category]]), data$value2, na.rm = TRUE)

  n_group <- length(levels(data$Group))

  # Alternate the colours of neighbouring groups
  data$colour <- ifelse(data$Group %in% levels(data$Group)[seq(1, n_group, by = 2)], "a", "b")

  if (!all(is.na(highlight)) && any(highlight %in% data$Group)) {
    data <- dplyr::mutate(data, colour = ifelse(Group %in% highlight, "c", colour))
  }

  # Pad the limits outwards by 20%, whatever the sign of the values
  pad <- function(x, outwards) ifelse(x >= 0, x * outwards, x / outwards)
  vals <- list(
    minimum = pad(min(data$value), 0.8),
    maximum = pad(max(data$value), 1.2)
  )

  y.text <- ifelse(n_group > 20, 0.75, 1)

  p <-
    ggplot2::ggplot(data, ggplot2::aes(
      x = value,
      y = Group,
      colour = colour,
      shape = shapes,
      text = paste0(dataset_id, " | ", taxon_name)
    )) +
    ggplot2::geom_jitter(width = 0) +
    ggplot2::ylab(paste("By", y_axis_category)) +
    # Shapes for minimum, mean, maximum, unknown
    ggplot2::scale_shape_manual(values = my_shapes, name = "Value Type", drop = FALSE) +
    ggplot2::scale_color_manual(values = c("a" = "#0072B2", "b" = "#E69F00", "c" = "#D55E00")) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.position = "right",
      legend.title = ggplot2::element_text(size = 10, face = "bold"),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor.x = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(size = ggplot2::rel(1.25)),
      axis.text.y = ggplot2::element_text(size = ggplot2::rel(y.text))
    ) +
    ggplot2::guides(colour = "none")

  if (hide_ids) {
    p <- p + ggplot2::theme(axis.text.y = ggplot2::element_blank())
  }

  x_label <- if (is.na(data$unit[1])) trait_name else paste0(trait_name, " (", data$unit[1], ")")
  range <- vals$maximum / vals$minimum

  # Log scale when the values are all positive and span a wide range
  if (vals$minimum > 0 && is.finite(range) && range > 20) {
    limits <- c(vals$minimum, vals$maximum)
    my_breaks <- scales::breaks_log(n = 6)(limits)
    my_breaks <- my_breaks[is.finite(my_breaks) & my_breaks >= limits[1] & my_breaks <= limits[2]]
    if (length(my_breaks) < 2) {
      my_breaks <- limits
    }
    p <- p + ggplot2::scale_x_log10(name = x_label, breaks = my_breaks, labels = my_breaks, limits = limits)
  } else if (vals$minimum < vals$maximum) {
    p <- p + ggplot2::scale_x_continuous(name = x_label, limits = c(vals$minimum, vals$maximum))
  } else {
    p <- p + ggplot2::xlab(x_label)
  }

  p
}

#' The values of one trait, with family and genus joined, for plotting.
#' NULL for a NULL input; no rows when the trait has no values.
#' @noRd
trait_plot_data <- function(database, trait_name) {
  if (!is.character(trait_name) || length(trait_name) != 1 || is.na(trait_name)) {
    cli::cli_abort("{.arg trait_name} must be a single trait name")
  }
  if (is.null(database)) {
    return(NULL)
  }
  # extract_trait() needs a traits table to be a tibble
  if (is.data.frame(database) && !tibble::is_tibble(database)) {
    database <- tibble::as_tibble(database)
  }

  status <- check_compatibility(database, single_table_allowed = TRUE)
  if (!status) {
    function_not_supported(database)
  }

  # extract_trait() stops when the trait has no values
  traits <- get_traits_table(database)
  if (nrow(traits) == 0 || !trait_name %in% traits$trait_name) {
    return(traits[0, ])
  }

  database_trait <- extract_trait(database, trait_name, partial_matches_allowed = FALSE)

  if (is.null(dim(database_trait))) {
    traits <- database_trait$traits
    # Add family and genus, unless already joined
    tax_cols <- setdiff(intersect(c("family", "genus"), names(database_trait$taxa)), names(traits))
    if (length(tax_cols) > 0) {
      traits <- traits %>%
        dplyr::left_join(
          database_trait$taxa %>% dplyr::select("taxon_name", tidyselect::all_of(tax_cols)),
          by = "taxon_name"
        )
    }
    traits
  } else {
    database_trait
  }
}

#' A blank plot saying there is nothing to plot
#' @noRd
no_data_plot <- function(label) {
  ggplot2::ggplot() +
    ggplot2::annotate("text", x = 0.5, y = 0.5, label = label, size = 6) +
    ggplot2::theme_void()
}
