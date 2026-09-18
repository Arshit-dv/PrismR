# ==========================================================
# Plot PrismReport
# ==========================================================

# Silence R CMD check notes for ggplot2 aesthetic evaluation variables
if (getRversion() >= "2.15.1") {
  utils::globalVariables(
    c(
      "variable", "completeness", "skewness", "leak_status", "recommendation",
      "x", "y", "xend", "yend", "xmin", "xmax", "ymin", "ymax",
      "group", "fill", "color", "label", "angle", "hjust", "vjust",
      "alpha", "petal_color", "rim_color", "score", "axis", "dimension",
      "value", "pct", "status", "stability_score", "stability_status"
    )
  )
}

#' Build Variable Diagnostic Profile
#'
#' Internal helper to merge quality, leakage, and transformation
#' metrics across all variables in a PrismReport into a single
#' comprehensive data frame.
#'
#' @param x A \code{PrismReport} object.
#' @return A data.frame containing unified variable-level diagnostics.
#' @keywords internal
#' @noRd
build_profile <- function(x) {
  if (!inherits(x, "PrismReport")) {
    stop("`x` must be a PrismReport object.", call. = FALSE)
  }

  q_df <- x$quality$variables
  l_df <- x$leakage$variables
  t_df <- x$transformation$variables

  # Merge quality and leakage by variable
  prof <- merge(q_df, l_df, by = "variable", all = TRUE)

  # Merge transformation if available
  if (is.data.frame(t_df) && nrow(t_df) > 0) {
    prof <- merge(prof, t_df, by = "variable", all.x = TRUE)
  } else {
    prof$skewness <- NA_real_
    prof$kurtosis <- NA_real_
    prof$finding <- "Non-numeric"
    prof$recommendation <- "None"
  }

  # Merge stability if available
  if (!is.null(x$stability) && is.list(x$stability)) {
    if (is.data.frame(x$stability$variables) && "variable" %in% names(x$stability$variables)) {
      s_df <- x$stability$variables
      if ("status" %in% names(s_df)) {
        names(s_df)[names(s_df) == "status"] <- "stability_status"
      }
      prof <- merge(prof, s_df, by = "variable", all.x = TRUE)
    } else if (!is.null(x$stability$feature_stability) && !is.null(names(x$stability$feature_stability))) {
      stab_df <- data.frame(
        variable = names(x$stability$feature_stability),
        stability_score = as.numeric(x$stability$feature_stability),
        stringsAsFactors = FALSE
      )
      prof <- merge(prof, stab_df, by = "variable", all.x = TRUE)
    }
  }
  if (!"stability_score" %in% names(prof)) {
    prof$stability_score <- NA_real_
  }

  # Fill missing transformation attributes for non-numeric variables
  prof$recommendation[is.na(prof$recommendation)] <- "Categorical"
  prof$finding[is.na(prof$finding)] <- "Categorical / Discrete"
  prof$missing_percent[is.na(prof$missing_percent)] <- 0

  # Compute feature readiness status tier (integrates stability when available)
  prof$status <- ifelse(
    prof$quality_score >= 80 & prof$leakage_score >= 80 & (is.na(prof$stability_score) | prof$stability_score >= 80),
    "Ready",
    ifelse(
      prof$quality_score < 50 | prof$leakage_score < 50 | (!is.na(prof$stability_score) & prof$stability_score < 50),
      "Critical",
      "Warning"
    )
  )
  prof$status <- factor(prof$status, levels = c("Ready", "Warning", "Critical"))

  prof
}

#' Custom Prism Theme for ggplot2
#'
#' @param base_size Base font size.
#' @param dark Logical indicating if dark mode palette should be used.
#' @return A ggplot2 theme.
#' @keywords internal
#' @noRd
theme_prism <- function(base_size = 11, dark = FALSE) {
  if (dark) {
    bg_color <- "#0b132b"
    panel_color <- "#14203c"
    grid_color <- "#1e293b"
    text_color <- "#f8fafc"
    sub_color <- "#94a3b8"
  } else {
    bg_color <- "#ffffff"
    panel_color <- "#f8fafc"
    grid_color <- "#e2e8f0"
    text_color <- "#0f172a"
    sub_color <- "#64748b"
  }

  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = bg_color, color = NA),
      panel.background = ggplot2::element_rect(fill = panel_color, color = grid_color, linewidth = 0.6),
      panel.grid.major = ggplot2::element_line(color = grid_color, linewidth = 0.5),
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(
        face = "bold",
        size = ggplot2::rel(1.2),
        color = text_color,
        margin = ggplot2::margin(b = 4)
      ),
      plot.subtitle = ggplot2::element_text(
        size = ggplot2::rel(0.95),
        color = sub_color,
        margin = ggplot2::margin(b = 10)
      ),
      plot.caption = ggplot2::element_text(
        size = ggplot2::rel(0.8),
        color = sub_color,
        margin = ggplot2::margin(t = 8)
      ),
      axis.title = ggplot2::element_text(
        face = "bold",
        size = ggplot2::rel(0.9),
        color = text_color
      ),
      axis.text = ggplot2::element_text(
        color = sub_color,
        size = ggplot2::rel(0.85)
      ),
      legend.position = "right",
      legend.title = ggplot2::element_text(face = "bold", size = ggplot2::rel(0.85), color = text_color),
      legend.text = ggplot2::element_text(size = ggplot2::rel(0.8), color = text_color),
      legend.background = ggplot2::element_rect(fill = bg_color, color = NA),
      plot.margin = ggplot2::margin(12, 12, 12, 12)
    )
}

# ==========================================================
# 1. Bubble Plot: Statistical Feature Map
# ==========================================================

#' Plot Statistical Feature Map (Bubble Plot)
#'
#' Displays dataset features mapped across Data Completeness (X-axis)
#' and Distribution Skewness (Y-axis), with point colors indicating
#' leakage risks and shapes representing recommended transformations.
#'
#' @param x A \code{PrismReport} object.
#' @return A ggplot object.
#' @keywords internal
#' @noRd
plot_bubble <- function(x) {
  prof <- build_profile(x)
  n_vars <- nrow(prof)

  completeness <- 100 - prof$missing_percent
  skew <- ifelse(is.na(prof$skewness), 0, prof$skewness)
  rec <- as.character(prof$recommendation)
  rec[is.na(rec) | rec == ""] <- "Categorical"

  # Determine Leakage & Stability Vector status per feature
  leak_status <- ifelse(
    prof$target_leakage | prof$correlation, "Target Leaker",
    ifelse(
      prof$duplicate, "Duplicate Column",
      ifelse(
        !is.na(prof$stability_score) & prof$stability_score < 60, "Unstable Drift",
        ifelse(
          prof$identifier | prof$high_cardinality, "Identifier / High-Card",
          "Clean Feature"
        )
      )
    )
  )

  df <- data.frame(
    variable = prof$variable,
    completeness = completeness,
    skewness = skew,
    leak_status = factor(leak_status, levels = c("Clean Feature", "Identifier / High-Card", "Duplicate Column", "Unstable Drift", "Target Leaker")),
    recommendation = factor(rec, levels = c("None", "Log", "Box-Cox", "Yeo-Johnson", "Categorical")),
    stringsAsFactors = FALSE
  )

  # Deterministic micro-jitter if features have identical (completeness, skewness) coordinates
  dup_coords <- duplicated(df[, c("completeness", "skewness")]) | duplicated(df[, c("completeness", "skewness")], fromLast = TRUE)
  if (any(dup_coords)) {
    coord_groups <- split(seq_len(nrow(df)), paste(round(df$completeness, 2), round(df$skewness, 2)))
    for (grp in coord_groups) {
      if (length(grp) > 1) {
        offsets <- seq(-0.06 * (length(grp) - 1), 0.06 * (length(grp) - 1), length.out = length(grp))
        df$skewness[grp] <- df$skewness[grp] + offsets
      }
    }
  }

  y_min <- min(-1.2, min(df$skewness) - 0.4)
  y_max <- max(1.2, max(df$skewness) + 0.4)
  x_min <- max(0, min(75, min(df$completeness) - 8))
  x_max <- 104

  p <- ggplot2::ggplot(df, ggplot2::aes(x = completeness, y = skewness)) +
    # 1. Background Shaded Bands
    # Upper Severely Skewed
    ggplot2::annotate("rect", xmin = x_min, xmax = x_max, ymin = 1.0, ymax = y_max, fill = "#ffedd5", alpha = 0.4) +
    # Upper Moderately Skewed
    ggplot2::annotate("rect", xmin = x_min, xmax = x_max, ymin = 0.5, ymax = 1.0, fill = "#fef9c3", alpha = 0.45) +
    # Center Symmetric Zone
    ggplot2::annotate("rect", xmin = x_min, xmax = x_max, ymin = -0.5, ymax = 0.5, fill = "#d1fae5", alpha = 0.5) +
    # Lower Moderately Skewed
    ggplot2::annotate("rect", xmin = x_min, xmax = x_max, ymin = -1.0, ymax = -0.5, fill = "#fef9c3", alpha = 0.45) +
    # Lower Severely Skewed
    ggplot2::annotate("rect", xmin = x_min, xmax = x_max, ymin = y_min, ymax = -1.0, fill = "#ffedd5", alpha = 0.4) +
    # 2. Reference Lines
    ggplot2::geom_hline(yintercept = 0, color = "#059669", linetype = "solid", linewidth = 0.6, alpha = 0.7) +
    ggplot2::geom_hline(yintercept = c(-0.5, 0.5), color = "#10b981", linetype = "dashed", linewidth = 0.5) +
    ggplot2::geom_vline(xintercept = 80, color = "#94a3b8", linetype = "dashed", linewidth = 0.6) +
    # Band Text Annotations
    ggplot2::annotate("text", x = x_min + 1, y = 0, label = "Symmetric Zone (No Transform Required)",
                      hjust = 0, fontface = "italic", color = "#047857", size = 3.3) +
    # 3. Feature Points
    ggplot2::geom_point(
      ggplot2::aes(color = leak_status, shape = recommendation),
      size = 4.5,
      stroke = 1.2,
      alpha = 0.9
    ) +
    # 4. Collision-Free Labels with Guaranteed Leader Lines
    ggrepel::geom_text_repel(
      ggplot2::aes(label = variable),
      size = 3.8,
      fontface = "bold",
      color = "#0f172a",
      box.padding = 0.45,
      point.padding = 0.35,
      force = 3,
      min.segment.length = 0,
      segment.color = "#94a3b8",
      segment.size = 0.5,
      max.overlaps = 35,
      seed = 42
    ) +
    # 5. Scales & Legends
    ggplot2::scale_color_manual(
      values = c(
        "Clean Feature" = "#10b981",
        "Identifier / High-Card" = "#0284c7",
        "Duplicate Column" = "#f59e0b",
        "Unstable Drift" = "#8b5cf6",
        "Target Leaker" = "#ef4444"
      ),
      drop = TRUE,
      name = "Feature Status"
    ) +
    ggplot2::scale_shape_manual(
      values = c(
        "None" = 16,
        "Log" = 18,
        "Box-Cox" = 17,
        "Yeo-Johnson" = 15,
        "Categorical" = 8
      ),
      drop = TRUE,
      name = "Transformation"
    ) +
    ggplot2::guides(
      color = ggplot2::guide_legend(override.aes = list(size = 4.5, shape = 16)),
      shape = ggplot2::guide_legend(override.aes = list(size = 4.5, color = "#334155"))
    ) +
    ggplot2::scale_x_continuous(
      limits = c(x_min, x_max),
      breaks = seq(0, 100, 20),
      labels = paste0(seq(0, 100, 20), "%")
    ) +
    ggplot2::scale_y_continuous(
      limits = c(y_min, y_max)
    ) +
    ggplot2::labs(
      title = "PrismR: Statistical Feature Map",
      subtitle = "Feature Completeness (100% - Missing%) vs. Distribution Skewness",
      x = "Data Completeness (%)",
      y = "Distribution Skewness",
      caption = "Green Zone [-0.5, 0.5]: Statistically symmetric | Dashed vertical line: 80% completeness benchmark"
    ) +
    theme_prism() +
    ggplot2::theme(
      legend.position = "right",
      legend.box = "vertical",
      legend.spacing.y = ggplot2::unit(8, "pt"),
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(size = 10.5, color = "#64748b", margin = ggplot2::margin(b = 10))
    )

  p
}

# ==========================================================
# 2. Radial Plot: Macro Dataset Health Gauge
# ==========================================================

#' Plot PrismR Radial Module Health Gauge
#'
#' Displays a multi-track circular radial gauge summarizing
#' dataset-level health across all PrismR modules:
#' \itemize{
#'   \item \strong{Outer Ring (4)}: Overall Model Readiness Score.
#'   \item \strong{Mid-Outer Ring (3)}: Data Quality Score.
#'   \item \strong{Mid-Inner Ring (2)}: Leakage Safety Score.
#'   \item \strong{Inner Ring (1)}: Transformation Health Score.
#'   \item \strong{Dynamic Track}: Automatically incorporates Feature
#'   Stability once evaluated.
#' }
#'
#' @param x A \code{PrismReport} object.
#' @return A ggplot object.
#' @keywords internal
#' @noRd
plot_radial <- function(x) {
  q_score <- as.numeric(x$quality$quality_score)
  l_score <- as.numeric(x$leakage$leakage_score)
  t_score <- if (x$transformation$n_numeric > 0) {
    round((1 - (x$transformation$n_recommended / x$transformation$n_numeric)) * 100, 1)
  } else {
    100
  }

  # Check if feature stability is evaluated
  has_stab <- !is.null(x$stability) &&
              is.list(x$stability) &&
              !is.null(x$stability$stability_score) &&
              !is.na(x$stability$stability_score)
  s_score <- if (has_stab) as.numeric(x$stability$stability_score) else NA_real_

  r_score <- if (!is.na(x$readiness[1])) as.numeric(x$readiness[1]) else round(0.40 * q_score + 0.45 * l_score + 0.15 * t_score, 1)
  verdict <- as.character(x$verdict[1])

  # Build dynamic tracks data frame
  if (has_stab) {
    tracks <- data.frame(
      ring = 1:5,
      metric = c("Feature Stability", "Transform Health", "Leakage Safety", "Data Quality", "Overall Readiness"),
      score = c(s_score, t_score, l_score, q_score, r_score),
      color = c("#06b6d4", "#8b5cf6", "#0284c7", "#10b981", "#f59e0b"),
      stringsAsFactors = FALSE
    )
  } else {
    tracks <- data.frame(
      ring = 1:4,
      metric = c("Transform Health", "Leakage Safety", "Data Quality", "Overall Readiness"),
      score = c(t_score, l_score, q_score, r_score),
      color = c("#8b5cf6", "#0284c7", "#10b981", "#f59e0b"),
      stringsAsFactors = FALSE
    )
  }

  n_tracks <- nrow(tracks)

  # Background full 360-degree guide tracks (0 to 100%)
  bg_df <- data.frame(
    xmin = tracks$ring - 0.36,
    xmax = tracks$ring + 0.36,
    ymin = 0,
    ymax = 100,
    stringsAsFactors = FALSE
  )

  # Foreground score arcs
  fg_df <- data.frame(
    xmin = tracks$ring - 0.36,
    xmax = tracks$ring + 0.36,
    ymin = 0,
    ymax = pmax(2, tracks$score),
    fill = tracks$color,
    label = paste0(round(tracks$score), "%"),
    stringsAsFactors = FALSE
  )

  # Tick marks at 25%, 50%, 75%, 100%
  ticks_df <- expand.grid(tick = c(25, 50, 75, 100), ring = 1:n_tracks)

  p <- ggplot2::ggplot() +
    # Background full circular tracks
    ggplot2::geom_rect(
      data = bg_df,
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      fill = "#f1f5f9",
      color = "#e2e8f0",
      linewidth = 0.5
    ) +
    # Tick lines across tracks
    ggplot2::geom_segment(
      data = ticks_df,
      ggplot2::aes(x = ring - 0.36, xend = ring + 0.36, y = tick, yend = tick),
      color = "white",
      linewidth = 0.8
    ) +
    # Foreground progress arcs
    ggplot2::geom_rect(
      data = fg_df,
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = fill),
      linewidth = 0.5
    ) +
    ggplot2::scale_fill_identity() +
    # Score labels at the head of each arc
    ggplot2::geom_text(
      data = fg_df,
      ggplot2::aes(x = (xmin + xmax)/2, y = pmax(6, ymax - 4.5), label = label),
      color = "white",
      fontface = "bold",
      size = 3.5
    ) +
    # Polar coordinate mapping
    ggplot2::scale_x_continuous(
      limits = c(0, n_tracks + 0.8),
      breaks = 1:n_tracks,
      labels = tracks$metric
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 100)
    ) +
    ggplot2::coord_polar(theta = "y", start = 0) +
    ggplot2::labs(
      title = "PrismR: Macro Dataset Health Gauge",
      subtitle = paste0("Overall Readiness: ", r_score, "% | Verdict: ", verdict),
      caption = "Outer Ring = Overall Readiness | Mid-Outer = Data Quality | Mid-Inner = Leakage Safety | Inner = Transform Health",
      x = NULL,
      y = NULL
    ) +
    theme_prism() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 10.5, color = "#0f172a", face = "bold"),
      axis.ticks = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 15, hjust = 0.5),
      plot.subtitle = ggplot2::element_text(size = 11, color = "#64748b", hjust = 0.5, margin = ggplot2::margin(b = 10)),
      plot.caption = ggplot2::element_text(size = 8.5, color = "#475569", hjust = 0.5, margin = ggplot2::margin(t = 10))
    )

  p
}

# ==========================================================
# 3. Circular Plot: Feature Diagnostic Rose
# ==========================================================

#' Plot Feature Diagnostic Rose
#'
#' Visualises feature-level diagnostics using a Nightingale Rose
#' (coxcomb) architecture focusing on raw feature metrics:
#' \itemize{
#'   \item \strong{Petal Length}: Feature Completeness (100\% - Missing\%).
#'   \item \strong{Petal Color}: Feature Redundancy and Leakage Status (Clean, Identifier/High-Card, Duplicate/Constant, Target Leaker).
#'   \item \strong{Outer Rim}: Recommended mathematical feature transformation.
#' }
#'
#' @param x A \code{PrismReport} object.
#' @return A ggplot object.
#' @keywords internal
#' @noRd
plot_circular <- function(x) {
  prof <- build_profile(x)
  n_vars <- nrow(prof)

  # Feature-level metrics: Completeness (100% - Missing%)
  missing_pct <- as.numeric(prof$missing_percent)
  completeness <- round(pmax(0, 100 - missing_pct), 1)

  # Feature-level Redundancy, Leakage & Stability Status
  status_vec <- ifelse(
    prof$target_leakage | prof$correlation, "Target Leaker",
    ifelse(
      prof$duplicate | prof$constant, "Duplicate / Constant",
      ifelse(
        !is.na(prof$stability_score) & prof$stability_score < 60, "Unstable Drift",
        ifelse(
          prof$identifier | prof$high_cardinality, "Identifier / High-Card",
          "Clean Feature"
        )
      )
    )
  )

  status_factor <- factor(
    status_vec,
    levels = c("Clean Feature", "Identifier / High-Card", "Duplicate / Constant", "Unstable Drift", "Target Leaker")
  )

  status_colors <- c(
    "Clean Feature" = "#10b981",
    "Identifier / High-Card" = "#0ea5e9",
    "Duplicate / Constant" = "#f59e0b",
    "Unstable Drift" = "#8b5cf6",
    "Target Leaker" = "#ef4444"
  )

  rec_trans <- as.character(prof$recommendation)
  rec_trans[is.na(rec_trans) | rec_trans == ""] <- "Categorical"

  trans_tiers <- factor(
    rec_trans,
    levels = c("None", "Log", "Box-Cox", "Yeo-Johnson", "Categorical")
  )

  trans_colors <- c(
    "None" = "#10b981",
    "Log" = "#0ea5e9",
    "Box-Cox" = "#f59e0b",
    "Yeo-Johnson" = "#8b5cf6",
    "Categorical" = "#64748b"
  )

  # Radial layout geometry
  y_inner <- 18
  y_petal_max <- 84
  y_span <- y_petal_max - y_inner

  petal_tops <- y_inner + (pmax(5, completeness) / 100) * y_span

  df_petals <- data.frame(
    id = seq_len(n_vars),
    variable = prof$variable,
    xmin = seq_len(n_vars) - 0.44,
    xmax = seq_len(n_vars) + 0.44,
    ymin = y_inner,
    ymax = petal_tops,
    completeness = completeness,
    label_pct = paste0(completeness, "%"),
    status = status_factor,
    trans_tier = trans_tiers,
    stringsAsFactors = FALSE
  )
  df_petals$trans_hex <- unname(trans_colors[as.character(df_petals$trans_tier)])

  # Background track sectors (visualise 100% capacity)
  df_bg_track <- data.frame(
    xmin = seq_len(n_vars) - 0.44,
    xmax = seq_len(n_vars) + 0.44,
    ymin = y_inner,
    ymax = y_petal_max
  )

  # Benchmark smooth concentric circles at 25%, 50%, 75%, 100% Completeness
  grid_pcts <- c(25, 50, 75, 100)
  grid_y <- y_inner + (grid_pcts / 100) * y_span

  # Determine dynamically present levels to sync legend swatches
  present_trans <- levels(droplevels(df_petals$trans_tier))

  font_sz <- max(2.2, min(3.5, 24 / max(1, n_vars)))
  axis_txt_sz <- if (n_vars > 20) 7.5 else if (n_vars > 12) 9.0 else 11.0

  p <- ggplot2::ggplot() +
    # 1. Background full guide sectors (subtle light grey track for 100% capacity)
    ggplot2::geom_rect(
      data = df_bg_track,
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      fill = "#f8fafc",
      color = "#e2e8f0",
      linewidth = 0.4
    ) +
    # 2. Benchmark smooth concentric circles (native smooth curves in polar coords)
    ggplot2::geom_hline(
      yintercept = grid_y,
      color = "#e2e8f0",
      linetype = "dashed",
      linewidth = 0.5
    ) +
    # 100% capacity solid outer benchmark ring
    ggplot2::geom_hline(
      yintercept = y_petal_max,
      color = "#cbd5e1",
      linetype = "solid",
      linewidth = 0.5
    ) +
    # 3. Nightingale Rose Petals (Height = Completeness %, Color = Redundancy & Leakage)
    ggplot2::geom_rect(
      data = df_petals,
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = status),
      color = "white",
      linewidth = if (n_vars > 12) 0.7 else 1.1
    ) +
    # 4. Feature completeness % label placed inside petal
    ggplot2::geom_text(
      data = df_petals,
      ggplot2::aes(x = (xmin + xmax) / 2, y = pmax(ymin + 8.5, ymax - 6.5), label = label_pct),
      color = "white",
      fontface = "bold",
      size = font_sz
    ) +
    # 5. Outer Rim Cap (Recommended Transformation)
    ggplot2::geom_rect(
      data = df_petals,
      ggplot2::aes(xmin = xmin, xmax = xmax, ymin = 89, ymax = 95, color = trans_tier),
      fill = df_petals$trans_hex,
      linewidth = 0.8
    ) +
    # 6. Smooth open center donut hole (no hub, no overall score)
    ggplot2::geom_hline(
      yintercept = y_inner,
      color = "#94a3b8",
      linewidth = 0.8
    ) +
    # 7. Real Visual Color Swatches (Dual Legend)
    ggplot2::scale_fill_manual(
      name = "Feature Integrity & Leakage (Petal)",
      values = status_colors,
      drop = TRUE,
      guide = ggplot2::guide_legend(
        order = 1,
        nrow = 1,
        title.position = "top",
        title.hjust = 0.5,
        override.aes = list(color = "white", linewidth = 0.5)
      )
    ) +
    ggplot2::scale_color_manual(
      name = "Recommended Transformation (Outer Rim)",
      values = trans_colors,
      drop = TRUE,
      guide = ggplot2::guide_legend(
        order = 2,
        nrow = 1,
        title.position = "top",
        title.hjust = 0.5,
        override.aes = list(
          fill = unname(trans_colors[present_trans]),
          color = "white",
          size = 5
        )
      )
    ) +
    # 8. Coordinates & Axis
    ggplot2::scale_x_continuous(
      limits = c(0.5, n_vars + 0.5),
      breaks = seq_len(n_vars),
      labels = prof$variable
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 102)
    ) +
    ggplot2::coord_polar(theta = "x", start = 0) +
    ggplot2::labs(
      title = "PrismR: Feature Diagnostic Rose",
      subtitle = "Petal Length = Feature Completeness (100% - Missing%) | Color = Leakage & Redundancy | Outer Rim = Transform",
      caption = "Concentric guide rings represent 25%, 50%, 75%, and 100% completeness benchmarks",
      x = NULL,
      y = NULL
    ) +
    theme_prism() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(size = axis_txt_sz, face = "bold", color = "#0f172a"),
      panel.grid = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 15, hjust = 0.5),
      plot.subtitle = ggplot2::element_text(size = 9.8, color = "#64748b", hjust = 0.5, margin = ggplot2::margin(b = 10)),
      plot.caption = ggplot2::element_text(size = 8.5, color = "#64748b", hjust = 0.5, margin = ggplot2::margin(t = 8)),
      legend.position = "bottom",
      legend.box = "horizontal",
      legend.spacing.x = ggplot2::unit(20, "pt"),
      legend.title = ggplot2::element_text(size = 9.5, face = "bold", color = "#334155"),
      legend.text = ggplot2::element_text(size = 9, color = "#475569"),
      plot.margin = ggplot2::margin(t = 15, r = 20, b = 15, l = 20)
    )

  p
}

# ==========================================================
# 4. Radar Plot: Single Variable Diagnostic Spider Profile
# ==========================================================

#' Plot Feature Radar Profile
#'
#' Visualises a single feature's deep-dive diagnostic profile
#' across 5 raw statistical dimensions: Completeness, Symmetry,
#' Tail Normalcy, Uniqueness, and Leakage Safety (with a dynamic
#' 6th slot for Feature Stability when evaluated).
#'
#' @param x A \code{PrismReport} object.
#' @param feature Name of the feature to display.
#' @return A ggplot object.
#' @keywords internal
#' @noRd
plot_radar <- function(x, feature) {
  prof <- build_profile(x)
  row <- prof[prof$variable == feature, , drop = FALSE]

  if (nrow(row) == 0) {
    stop(paste0("Feature '", feature, "' not found in PrismReport."), call. = FALSE)
  }

  # 1. Feature-specific raw statistical metrics
  # Completeness %
  comp_val <- max(0, min(100, 100 - row$missing_percent[1]))

  # Symmetry % (100% = perfectly symmetric, penalize absolute skewness)
  is_num <- !is.na(row$skewness[1])
  skew <- if (is_num) row$skewness[1] else 0
  sym_val <- if (is_num) max(0, min(100, 100 - abs(skew) * 30)) else 100

  # Tail Normalcy % (100% = normal tails, penalize excess kurtosis)
  kurt <- if (is_num && !is.na(row$kurtosis[1])) row$kurtosis[1] else 0
  tail_val <- if (is_num) max(0, min(100, 100 - abs(kurt) * 15)) else 100

  # Uniqueness % (Ratio of unique values to total rows)
  n_total <- if (!is.null(x$quality$n_rows)) x$quality$n_rows else 100
  uniq_ratio <- if (!is.null(row$unique_count) && !is.na(row$unique_count[1])) {
    min(100, (row$unique_count[1] / max(1, n_total)) * 100)
  } else if (!is.null(row$unique_ratio) && !is.na(row$unique_ratio[1])) {
    min(100, row$unique_ratio[1] * 100)
  } else {
    80
  }

  # Leakage Safety % (Feature-specific leakage score)
  l_val <- as.numeric(row$leakage_score[1])

  # Dynamic Feature Stability check
  stab_val <- if (!is.null(row$stability_score) && !is.na(row$stability_score[1])) {
    as.numeric(row$stability_score[1])
  } else if (!is.null(x$stability) && is.list(x$stability) && !is.null(x$stability$feature_stability) && feature %in% names(x$stability$feature_stability)) {
    as.numeric(x$stability$feature_stability[[feature]])
  } else {
    NA_real_
  }

  has_stab <- !is.na(stab_val)

  if (has_stab) {
    axes_names <- c("Completeness", "Symmetry", "Tail Normalcy", "Uniqueness", "Leakage Safety", "Stability")
    scores <- c(comp_val, sym_val, tail_val, uniq_ratio, l_val, stab_val)
  } else {
    axes_names <- c("Completeness", "Symmetry", "Tail Normalcy", "Uniqueness", "Leakage Safety")
    scores <- c(comp_val, sym_val, tail_val, uniq_ratio, l_val)
  }

  n <- length(axes_names)
  angles <- pi / 2 - (2 * pi * (0:(n - 1)) / n)

  get_coords <- function(vals) {
    r <- vals / 100
    data.frame(
      x = r * cos(angles),
      y = r * sin(angles)
    )
  }

  # Concentric grid webs at 25%, 50%, 75%, 100%
  grid_df <- do.call(rbind, lapply(c(25, 50, 75, 100), function(pct) {
    df <- get_coords(rep(pct, n))
    df$pct <- pct
    df$group <- paste0(pct, "%")
    df
  }))

  # 80% benchmark polygon
  ref_df <- get_coords(rep(80, n))

  # Spoke radial lines
  spokes_df <- data.frame(
    x = 0,
    y = 0,
    xend = cos(angles),
    yend = sin(angles),
    axis = axes_names
  )

  # Actual feature polygon
  feat_coords <- get_coords(scores)
  feat_coords$score <- scores
  feat_coords$axis <- axes_names

  # Smart axis label placement with generous spacing
  label_r <- 1.20
  labels_df <- data.frame(
    x = label_r * cos(angles),
    y = label_r * sin(angles),
    axis = axes_names,
    hjust = ifelse(abs(cos(angles)) < 0.2, 0.5, ifelse(cos(angles) > 0, 0, 1)),
    vjust = ifelse(abs(sin(angles)) < 0.2, 0.5, ifelse(sin(angles) > 0, 0, 1))
  )

  sub_text <- if (is_num) {
    paste0(
      "Status: ", row$status[1], " | Missing: ", round(row$missing_percent[1], 1),
      "% | Skewness: ", round(skew, 2), " | Transform: ", row$recommendation[1]
    )
  } else {
    paste0(
      "Status: ", row$status[1], " | Missing: ", round(row$missing_percent[1], 1),
      "% | Type: Categorical / Discrete"
    )
  }

  p <- ggplot2::ggplot() +
    # Background concentric webs
    ggplot2::geom_polygon(
      data = grid_df,
      ggplot2::aes(x = x, y = y, group = group),
      fill = NA,
      color = "#cbd5e1",
      linewidth = 0.55
    ) +
    # Web percentage labels on vertical spoke
    ggplot2::annotate("text", x = -0.02, y = c(0.25, 0.50, 0.75, 1.0),
                      label = c("25%", "50%", "75%", "100%"),
                      color = "#94a3b8", size = 2.8, vjust = -0.3, hjust = 1) +
    # Radial spoke lines
    ggplot2::geom_segment(
      data = spokes_df,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      color = "#cbd5e1",
      linewidth = 0.55
    ) +
    # 80% Benchmark Reference Polygon
    ggplot2::geom_polygon(
      data = ref_df,
      ggplot2::aes(x = x, y = y),
      fill = NA,
      color = "#10b981",
      linetype = "dashed",
      linewidth = 0.85
    ) +
    # Feature Data Polygon
    ggplot2::geom_polygon(
      data = feat_coords,
      ggplot2::aes(x = x, y = y),
      fill = "#0284c7",
      alpha = 0.35,
      color = "#0284c7",
      linewidth = 1.3
    ) +
    # Feature Vertex Points
    ggplot2::geom_point(
      data = feat_coords,
      ggplot2::aes(x = x, y = y),
      color = "#0284c7",
      fill = "white",
      shape = 21,
      size = 4.5,
      stroke = 1.8
    ) +
    # Spoke Axis Labels
    ggplot2::geom_text(
      data = labels_df,
      ggplot2::aes(x = x, y = y, label = axis, hjust = hjust, vjust = vjust),
      fontface = "bold",
      size = 4.0,
      color = "#0f172a"
    ) +
    # Score label pills
    ggplot2::geom_label(
      data = feat_coords,
      ggplot2::aes(
        x = x * 0.85,
        y = y * 0.85,
        label = paste0(round(score), "%")
      ),
      fontface = "bold",
      size = 3.2,
      color = "#0284c7",
      fill = "white",
      label.padding = ggplot2::unit(1.5, "pt"),
      linewidth = 0.3,
      alpha = 0.95
    ) +
    ggplot2::coord_equal(xlim = c(-1.95, 1.95), ylim = c(-1.55, 1.55), clip = "off") +
    ggplot2::labs(
      title = paste0("PrismR Radar Profile: ", feature),
      subtitle = sub_text,
      caption = "Dashed Green Web = 80% Readiness Benchmark | Feature-level raw statistical diagnostics"
    ) +
    theme_prism() +
    ggplot2::theme(
      axis.title = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.border = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 15, hjust = 0.5),
      plot.subtitle = ggplot2::element_text(size = 10.5, color = "#64748b", hjust = 0.5, margin = ggplot2::margin(b = 12)),
      plot.caption = ggplot2::element_text(size = 9, color = "#475569", hjust = 0.5, margin = ggplot2::margin(t = 12)),
      plot.margin = ggplot2::margin(t = 15, r = 25, b = 15, l = 25)
    )

  p
}

# ==========================================================
# Main S3 Plot Method
# ==========================================================

#' Plot a Prism Report
#'
#' Visualises the results of a Prism Analysis using one of
#' several diagnostic plots.
#'
#' Available visualisations include:
#' \itemize{
#'   \item \strong{radial}: Radial/gauge chart summarising the
#'   overall health of each PrismR module and dataset readiness.
#'   \item \strong{circular}: Feature Diagnostic Rose (coxcomb) displaying
#'   feature Completeness (petal length), Redundancy & Leakage Status (petal color),
#'   and Recommended Transformation (outer rim cap) around an open donut center.
#'   \item \strong{bubble}: Statistical feature map displaying Data
#'   Completeness (100% - Missing%) versus Distribution Skewness,
#'   with leakage vector colors and transformation shapes.
#'   \item \strong{radar}: Spider/radar chart displaying the raw statistical
#'   diagnostic profile of a selected variable (Completeness, Symmetry,
#'   Tail Normalcy, Uniqueness, Leakage Safety, and Feature Stability).
#' }
#'
#' @param x A \code{PrismReport} object returned by
#'   \code{\link{prism}}.
#' @param type Character string specifying the plot to
#'   display. One of \code{"radial"}, \code{"circular"},
#'   \code{"bubble"}, or \code{"radar"}.
#' @param feature Character string specifying the variable to
#'   display when \code{type = "radar"}.
#' @param ... Additional graphical arguments reserved for
#'   future extensions.
#'
#' @return A ggplot object.
#'
#' @seealso \code{\link{prism}}
#'
#' @examples
#' \dontrun{
#' report <- prism(airquality, target = "Ozone")
#' plot(report, type = "radial")
#' plot(report, type = "circular")
#' plot(report, type = "bubble")
#' plot(report, type = "radar", feature = "Solar.R")
#' }
#'
#' @export
plot.PrismReport <- function(
    x,
    type = c(
      "radial",
      "circular",
      "bubble",
      "radar"
    ),
    feature = NULL,
    ...
) {

  if (!inherits(x, "PrismReport")) {
    stop("`x` must be a PrismReport object.", call. = FALSE)
  }

  # Match requested plot type
  type <- match.arg(type)

  # Generate requested visualisation
  switch(
    type,
    radial = plot_radial(x),
    circular = plot_circular(x),
    bubble = plot_bubble(x),
    radar = {
      profile <- build_profile(x)
      if (is.null(feature)) {
        stop("Please specify 'feature' for radar plot. (e.g. plot(report, type = 'radar', feature = 'col_name'))", call. = FALSE)
      }
      if (!feature %in% profile$variable) {
        stop(
          paste0("Feature '", feature, "' not found. Available features: ", paste(profile$variable, collapse = ", ")),
          call. = FALSE
        )
      }
      plot_radar(x, feature)
    }
  )
}

