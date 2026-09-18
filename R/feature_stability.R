#' Feature Stability Assessment
#'
#' Evaluates feature distribution drift using Population Stability Index
#' (PSI) and Wasserstein distance across numeric and categorical features.
#'
#' If only one dataset is supplied, the function performs a sequential
#' partition-based stability assessment (comparing the first half to the
#' second half of observations). For real-world monitoring, users should
#' provide reference and current datasets separately.
#'
#' @param data A data.frame used as the reference dataset (or for single-dataset
#'   drift evaluation).
#' @param current Optional current data.frame to compare against \code{data}.
#' @param split_ratio Numeric. Proportion of rows to allocate to the reference
#'   dataset in single-dataset mode. Defaults to 0.5 (first 50% vs. last 50%).
#' @param partition_col Optional character. Column name to order by before
#'   partitioning in single-dataset mode (e.g. a date or time column).
#' @param verbose Logical. If TRUE, prints a human-readable stability
#'   report. Defaults to FALSE.
#'
#' @return A list containing:
#'   \item{stability_score}{Overall stability score from 0 to 100.}
#'   \item{variables}{Feature-level PSI, Wasserstein distance,
#'   stability score and status.}
#'   \item{unstable_features}{Character vector of unstable feature names.}
#'   \item{method}{Assessment method used.}
#'
#' @examples
#' # Single-dataset sequential drift evaluation
#' res <- feature_stability(airquality)
#' res$stability_score
#' res$verdict
#'
#' # Comparing reference baseline vs current dataset
#' ref <- data.frame(val = rnorm(100, 0, 1))
#' cur <- data.frame(val = rnorm(100, 2, 1))
#' res2 <- feature_stability(ref, current = cur)
#' res2$verdict
#'
#' @export
feature_stability <- function(data,
                              current = NULL,
                              split_ratio = 0.5,
                              partition_col = NULL,
                              verbose = FALSE) {

  # ==========================================================
  # Step 1: Input Validation
  # ==========================================================

  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }

  if (nrow(data) < 10) {
    stop("`data` must contain at least 10 rows.", call. = FALSE)
  }

  if (ncol(data) == 0) {
    stop("`data` must contain at least one column.", call. = FALSE)
  }

  if (!is.numeric(split_ratio) || length(split_ratio) != 1 ||
      is.na(split_ratio) || split_ratio <= 0 || split_ratio >= 1) {
    stop(
      "`split_ratio` must be a single number between 0 and 1 (e.g., 0.5).",
      call. = FALSE
    )
  }

  if (!is.null(partition_col)) {
    if (!is.character(partition_col) || length(partition_col) != 1 ||
        !partition_col %in% names(data)) {
      stop(
        "`partition_col` must be a valid column name in `data`.",
        call. = FALSE
      )
    }
  }

  if (!is.logical(verbose) || length(verbose) != 1 || is.na(verbose)) {
    stop("`verbose` must be TRUE or FALSE.", call. = FALSE)
  }

  # ==========================================================
  # Step 2: Partitioning & Alignment
  # ==========================================================

  if (!is.null(current)) {
    if (!is.data.frame(current)) {
      stop("`current` must be a data.frame.", call. = FALSE)
    }

    if (nrow(current) < 10) {
      stop("`current` must contain at least 10 rows.", call. = FALSE)
    }

    common_features <- intersect(names(data), names(current))

    if (length(common_features) == 0) {
      stop(
        "`data` and `current` must share at least one common feature.",
        call. = FALSE
      )
    }

    data <- data[, common_features, drop = FALSE]
    current <- current[, common_features, drop = FALSE]
    assessment_method <- "Reference vs. Current Dataset"

  } else {

    # --------------------------------------------------------
    # Single-Dataset Mode: Deterministic Sequential Split
    # --------------------------------------------------------
    # Evaluates temporal / ingestion drift (baseline vs. recent)
    # without random sampling noise or altering global RNG seed.

    n_rows <- nrow(data)

    if (!is.null(partition_col)) {
      order_idx <- order(data[[partition_col]])
      data <- data[order_idx, , drop = FALSE]
    }

    split_point <- floor(n_rows * split_ratio)
    split_point <- max(5, min(n_rows - 5, split_point))

    current <- data[seq(split_point + 1, n_rows), , drop = FALSE]
    data <- data[seq_len(split_point), , drop = FALSE]

    assessment_method <- if (!is.null(partition_col)) {
      sprintf(
        "Ordered by '%s' (%d%% baseline / %d%% current)",
        partition_col,
        round(split_ratio * 100),
        round((1 - split_ratio) * 100)
      )
    } else {
      sprintf(
        "Sequential Partition (%d%% baseline / %d%% current)",
        round(split_ratio * 100),
        round((1 - split_ratio) * 100)
      )
    }
  }

  # ==========================================================
  # Step 3: Robust PSI Engines (Numeric & Categorical)
  # ==========================================================

  calculate_numeric_psi <- function(reference, current) {
    reference <- reference[is.finite(reference)]
    current <- current[is.finite(current)]

    if (length(reference) < 5 || length(current) < 5) {
      return(NA_real_)
    }

    if (length(unique(reference)) < 2) {
      if (all(current == reference[1])) return(0) else return(1.0)
    }

    # Adaptive binning: scale bins with sample size to prevent over-segmentation
    n_ref <- length(reference)
    n_cur <- length(current)
    bins <- min(10, max(2, floor(min(n_ref, n_cur) / 15)))

    breaks <- unique(
      quantile(
        reference,
        probs = seq(0, 1, length.out = bins + 1),
        na.rm = TRUE,
        type = 7
      )
    )

    if (length(breaks) < 3) {
      return(0)
    }

    breaks[1] <- -Inf
    breaks[length(breaks)] <- Inf

    ref_bins <- cut(reference, breaks = breaks, include.lowest = TRUE, right = TRUE)
    cur_bins <- cut(current, breaks = breaks, include.lowest = TRUE, right = TRUE)

    ref_counts <- as.numeric(table(ref_bins))
    cur_counts <- as.numeric(table(cur_bins))
    k_bins <- length(ref_counts)

    # Laplace pseudo-count smoothing (alpha = 0.5):
    # Prevents zero-frequency log explosion while preserving sum(p) == 1
    alpha <- 0.5
    ref_probs <- (ref_counts + alpha) / (n_ref + alpha * k_bins)
    cur_probs <- (cur_counts + alpha) / (n_cur + alpha * k_bins)

    sum((cur_probs - ref_probs) * log(cur_probs / ref_probs))
  }

  calculate_categorical_psi <- function(reference, current) {
    reference <- as.character(reference[!is.na(reference)])
    current <- as.character(current[!is.na(current)])

    if (length(reference) < 5 || length(current) < 5) {
      return(NA_real_)
    }

    all_categories <- union(unique(reference), unique(current))
    k_cats <- length(all_categories)

    if (k_cats <= 1) {
      return(0)
    }

    n_ref <- length(reference)
    n_cur <- length(current)

    ref_tab <- table(factor(reference, levels = all_categories))
    cur_tab <- table(factor(current, levels = all_categories))

    ref_counts <- as.numeric(ref_tab)
    cur_counts <- as.numeric(cur_tab)

    # Laplace smoothing (alpha = 0.5):
    alpha <- 0.5
    ref_probs <- (ref_counts + alpha) / (n_ref + alpha * k_cats)
    cur_probs <- (cur_counts + alpha) / (n_cur + alpha * k_cats)

    sum((cur_probs - ref_probs) * log(cur_probs / ref_probs))
  }

  # ==========================================================
  # Step 4: Dual Wasserstein Distance (Raw & Normalized)
  # ==========================================================

  calculate_wasserstein <- function(reference, current) {
    reference <- reference[is.finite(reference)]
    current <- current[is.finite(current)]

    if (length(reference) < 2 || length(current) < 2) {
      return(list(raw = NA_real_, normalized = NA_real_))
    }

    probabilities <- seq(0.01, 0.99, length.out = 100)

    ref_quantiles <- quantile(
      reference,
      probs = probabilities,
      na.rm = TRUE
    )

    cur_quantiles <- quantile(
      current,
      probs = probabilities,
      na.rm = TRUE
    )

    raw_w1 <- mean(abs(ref_quantiles - cur_quantiles))

    # Scale normalization via pooled standard deviation
    n_ref <- length(reference)
    n_cur <- length(current)
    var_ref <- var(reference)
    var_cur <- var(current)

    pooled_sd <- if (n_ref + n_cur > 2 && !is.na(var_ref) && !is.na(var_cur)) {
      sqrt(((n_ref - 1) * var_ref + (n_cur - 1) * var_cur) / (n_ref + n_cur - 2))
    } else {
      sd(c(reference, current))
    }

    norm_w1 <- if (!is.na(pooled_sd) && pooled_sd > 1e-9) {
      raw_w1 / pooled_sd
    } else if (raw_w1 == 0) {
      0
    } else {
      NA_real_
    }

    list(
      raw = raw_w1,
      normalized = norm_w1
    )
  }

  # ==========================================================
  # Step 5: Feature Detection (Numeric & Categorical)
  # ==========================================================

  numeric_features <- names(data)[
    vapply(data, is.numeric, logical(1))
  ]

  categorical_features <- names(data)[
    vapply(data, function(col) {
      is.character(col) || is.factor(col) || is.logical(col)
    }, logical(1))
  ]

  all_features <- c(numeric_features, categorical_features)

  if (length(all_features) == 0) {
    if (verbose) {
      cat("\n")
      cat("====================================================\n")
      cat("          Feature Stability Assessment\n")
      cat("====================================================\n\n")
      cat("No evaluatable features found for stability analysis.\n")
      cat("====================================================\n\n")
    }

    return(
      list(
        stability_score = 100,
        variables = data.frame(),
        unstable_features = character(0),
        method = assessment_method
      )
    )
  }

  # ==========================================================
  # Step 6: Feature Evaluation & Dual-Layer Scoring
  # ==========================================================

  results <- lapply(
    all_features,
    function(feature) {
      is_num <- feature %in% numeric_features

      if (is_num) {
        ref_vals <- data[[feature]]
        cur_vals <- current[[feature]]

        ref_finite <- ref_vals[is.finite(ref_vals)]
        cur_finite <- cur_vals[is.finite(cur_vals)]

        if (length(ref_finite) < 5 || length(cur_finite) < 5) {
          return(
            data.frame(
              variable = feature,
              type = "Numeric",
              psi = NA_real_,
              wasserstein = NA_real_,
              norm_wasserstein = NA_real_,
              stability = NA_real_,
              stability_score = NA_real_,
              status = "Insufficient Data",
              stringsAsFactors = FALSE
            )
          )
        }

        psi_val <- calculate_numeric_psi(ref_finite, cur_finite)
        w_res <- calculate_wasserstein(ref_finite, cur_finite)
        raw_w1 <- w_res$raw
        norm_w1 <- w_res$normalized
        feat_type <- "Numeric"

      } else {
        # Categorical / Discrete Feature
        ref_vals <- data[[feature]]
        cur_vals <- current[[feature]]

        ref_clean <- ref_vals[!is.na(ref_vals)]
        cur_clean <- cur_vals[!is.na(cur_vals)]

        if (length(ref_clean) < 5 || length(cur_clean) < 5) {
          return(
            data.frame(
              variable = feature,
              type = "Categorical",
              psi = NA_real_,
              wasserstein = NA_real_,
              norm_wasserstein = NA_real_,
              stability = NA_real_,
              stability_score = NA_real_,
              status = "Insufficient Data",
              stringsAsFactors = FALSE
            )
          )
        }

        psi_val <- calculate_categorical_psi(ref_clean, cur_clean)
        raw_w1 <- NA_real_
        norm_w1 <- NA_real_
        feat_type <- "Categorical"
      }

      # --------------------------------------------------------
      # Actionable Stability Classification
      # --------------------------------------------------------
      if (is.na(psi_val)) {
        stability <- NA_real_
        status <- "Insufficient Data"
      } else if (psi_val < 0.10) {
        stability <- 100
        status <- "Stable"
      } else if (psi_val < 0.25) {
        stability <- 70
        status <- "Moderate Drift"
      } else {
        stability <- 30
        status <- "Unstable"
      }

      data.frame(
        variable = feature,
        type = feat_type,
        psi = round(psi_val, 4),
        wasserstein = if (is.na(raw_w1)) NA_real_ else round(raw_w1, 4),
        norm_wasserstein = if (is.na(norm_w1)) NA_real_ else round(norm_w1, 4),
        stability = stability,
        stability_score = stability,
        status = status,
        stringsAsFactors = FALSE
      )
    }
  )

  variables <- do.call(rbind, results)

  # ==========================================================
  # Dual-Layer Scoring & Gating Verdict
  # ==========================================================

  valid_scores <- variables$stability[!is.na(variables$stability)]

  overall_score <- if (length(valid_scores) == 0) {
    NA_real_
  } else {
    mean(valid_scores)
  }

  stable_features <- variables$variable[variables$status == "Stable"]
  moderate_features <- variables$variable[variables$status == "Moderate Drift"]
  unstable_features <- variables$variable[variables$status == "Unstable"]

  # Gating Verdict (The Veto Rule):
  # A high average score cannot mask unstable features!
  verdict <- if (length(unstable_features) > 0) {
    "Drift Warning (Unstable Features Detected)"
  } else if (length(moderate_features) > 0) {
    "Moderate Drift (Proceed with Caution)"
  } else if (length(stable_features) > 0) {
    "Stable (No Significant Drift)"
  } else {
    "Indeterminate (Insufficient Data)"
  }

  # ==========================================================
  # User-Friendly Console Output
  # ==========================================================

  if (verbose) {
    cat("\n")
    cat("====================================================\n")
    cat("          Feature Stability Assessment\n")
    cat("====================================================\n\n")

    cat("Assessment Mode         : ", assessment_method, "\n", sep = "")

    if (is.na(overall_score)) {
      cat("Overall Stability Score : Not Available\n")
    } else {
      cat(sprintf("Overall Stability Score : %.1f / 100\n", overall_score))
    }

    cat("Stability Verdict       : ", verdict, "\n\n", sep = "")

    cat(sprintf("Evaluated Features      : %d\n", nrow(variables)))
    cat(sprintf("Stable Features         : %d\n", length(stable_features)))
    cat(sprintf("Moderate Drift          : %d\n", length(moderate_features)))
    cat(sprintf("Unstable Features       : %d\n\n", length(unstable_features)))

    # --------------------------------------------------------
    # Unstable Features (Veto Highlight)
    # --------------------------------------------------------
    if (length(unstable_features) > 0) {
      cat("----------------------------------------------------\n")
      cat("UNSTABLE FEATURES (VETO BLOCKERS)\n")
      cat("----------------------------------------------------\n")
      for (feat in unstable_features) {
        sub_row <- variables[variables$variable == feat, ]
        cat(sprintf("• %s [%s] — PSI: %.4f\n", feat, sub_row$type, sub_row$psi))
      }
      cat("\n⚠ These features show significant distribution shift.\n")
      cat("  Feeding them into models risks severe production degradation.\n\n")
    }

    # --------------------------------------------------------
    # Moderate Drift
    # --------------------------------------------------------
    if (length(moderate_features) > 0) {
      cat("----------------------------------------------------\n")
      cat("MODERATE DRIFT (MONITOR)\n")
      cat("----------------------------------------------------\n")
      for (feat in moderate_features) {
        sub_row <- variables[variables$variable == feat, ]
        cat(sprintf("• %s [%s] — PSI: %.4f\n", feat, sub_row$type, sub_row$psi))
      }
      cat("\n")
    }

    # --------------------------------------------------------
    # Stable Features Summary
    # --------------------------------------------------------
    if (length(unstable_features) == 0 && length(moderate_features) == 0) {
      cat("✓ All evaluated features are stable across partitions.\n\n")
    }

    # --------------------------------------------------------
    # Detailed Table
    # --------------------------------------------------------
    cat("----------------------------------------------------\n")
    cat("DETAILED FEATURE BREAKDOWN\n")
    cat("----------------------------------------------------\n\n")
    print(variables, row.names = FALSE)
    cat("\n====================================================\n\n")
  }

  # ==========================================================
  # Return S3-compatible structure
  # ==========================================================

  invisible(
    list(
      stability_score = if (is.na(overall_score)) NA_real_ else round(overall_score, 1),
      verdict = verdict,
      variables = variables,
      unstable_features = unstable_features,
      moderate_features = moderate_features,
      stable_features = stable_features,
      method = assessment_method
    )
  )
}