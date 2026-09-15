#' Feature Stability Assessment
#'
#' Evaluates feature distribution drift using Population Stability Index
#' (PSI) and Wasserstein distance.
#'
#' If only one dataset is supplied, the function creates two random
#' partitions of the data for a partition-based stability assessment.
#' For real-world monitoring, users should provide reference and current
#' datasets separately.
#'
#' @param data A data.frame used for single-dataset stability assessment.
#' @param current Optional current data.frame to compare against data.
#' @param verbose Logical. If TRUE, prints a human-readable stability
#'   report. Defaults to TRUE.
#'
#' @return A list containing:
#'   \item{stability_score}{Overall stability score from 0 to 100.}
#'   \item{variables}{Feature-level PSI, Wasserstein distance,
#'   stability score and status.}
#'   \item{unstable_features}{Names of unstable features.}
#'
#' @export
feature_stability <- function(data, current = NULL, verbose = TRUE) {

  # ==========================================================
  # Input validation
  # ==========================================================

  if (!is.data.frame(data)) {
    stop("data must be a data.frame.")
  }

  if (nrow(data) < 10) {
    stop("data must contain at least 10 rows.")
  }

  if (!is.logical(verbose) || length(verbose) != 1 || is.na(verbose)) {
    stop("verbose must be TRUE or FALSE.")
  }

  if (!is.null(current)) {

    if (!is.data.frame(current)) {
      stop("current must be a data.frame.")
    }

    if (nrow(current) < 10) {
      stop("current must contain at least 10 rows.")
    }

    common_features <- intersect(names(data), names(current))

    if (length(common_features) == 0) {
      stop(
        "data and current must contain at least one common feature."
      )
    }

    data <- data[, common_features, drop = FALSE]
    current <- current[, common_features, drop = FALSE]

  } else {

    # ========================================================
    # Single dataset mode
    # ========================================================
    #
    # Randomly partition observations into reference/current
    # groups rather than assuming row order represents drift.
    #

    set.seed(123)

    split_index <- sample(
      seq_len(nrow(data)),
      size = floor(nrow(data) / 2),
      replace = FALSE
    )

    current_index <- setdiff(
      seq_len(nrow(data)),
      split_index
    )

    current <- data[current_index, , drop = FALSE]
    data <- data[split_index, , drop = FALSE]
  }

  # ==========================================================
  # PSI calculation
  # ==========================================================

  calculate_psi <- function(reference, current, bins = 10) {

    reference <- reference[is.finite(reference)]
    current <- current[is.finite(current)]

    if (length(reference) < 2 || length(current) < 2) {
      return(NA_real_)
    }

    if (length(unique(reference)) < 2) {
      return(0)
    }

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

    ref_bins <- cut(
      reference,
      breaks = breaks,
      include.lowest = TRUE,
      right = TRUE
    )

    cur_bins <- cut(
      current,
      breaks = breaks,
      include.lowest = TRUE,
      right = TRUE
    )

    ref_dist <- prop.table(table(ref_bins))
    cur_dist <- prop.table(table(cur_bins))

    all_levels <- union(
      names(ref_dist),
      names(cur_dist)
    )

    ref_values <- rep(0, length(all_levels))
    cur_values <- rep(0, length(all_levels))

    names(ref_values) <- all_levels
    names(cur_values) <- all_levels

    ref_values[names(ref_dist)] <- as.numeric(ref_dist)
    cur_values[names(cur_dist)] <- as.numeric(cur_dist)

    # Avoid log(0)
    epsilon <- 1e-6

    ref_values <- pmax(ref_values, epsilon)
    cur_values <- pmax(cur_values, epsilon)

    sum(
      (cur_values - ref_values) *
        log(cur_values / ref_values)
    )
  }

  # ==========================================================
  # Wasserstein distance
  # ==========================================================

  calculate_wasserstein <- function(reference, current) {

    reference <- reference[is.finite(reference)]
    current <- current[is.finite(current)]

    if (length(reference) < 2 || length(current) < 2) {
      return(NA_real_)
    }

    probabilities <- seq(0, 1, length.out = 100)

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

    mean(abs(ref_quantiles - cur_quantiles))
  }

  # ==========================================================
  # Select numeric features
  # ==========================================================

  numeric_features <- names(
    data[vapply(data, is.numeric, logical(1))]
  )

  if (length(numeric_features) == 0) {

    if (verbose) {

      cat("\n")
      cat("====================================================\n")
      cat("          Feature Stability Assessment\n")
      cat("====================================================\n\n")

      cat(
        "No numeric features were found for stability analysis.\n"
      )

      cat("====================================================\n\n")
    }

    return(
      list(
        stability_score = 100,
        variables = data.frame(),
        unstable_features = character(0)
      )
    )
  }

  # ==========================================================
  # Analyze every numeric feature
  # ==========================================================

  results <- lapply(
    numeric_features,
    function(feature) {

      reference_values <- data[[feature]]
      current_values <- current[[feature]]

      reference_values <- reference_values[
        is.finite(reference_values)
      ]

      current_values <- current_values[
        is.finite(current_values)
      ]

      if (
        length(reference_values) < 5 ||
        length(current_values) < 5
      ) {

        return(
          data.frame(
            variable = feature,
            psi = NA_real_,
            wasserstein = NA_real_,
            stability = NA_real_,
            stability_score = NA_real_,
            status = "Insufficient Data",
            stringsAsFactors = FALSE
          )
        )
      }

      psi <- calculate_psi(
        reference_values,
        current_values
      )

      wasserstein <- calculate_wasserstein(
        reference_values,
        current_values
      )

      # ======================================================
      # Stability classification
      # ======================================================

      if (is.na(psi)) {

        stability <- NA_real_
        status <- "Insufficient Data"

      } else if (psi < 0.10) {

        stability <- 100
        status <- "Stable"

      } else if (psi < 0.25) {

        stability <- 70
        status <- "Moderate Drift"

      } else {

        stability <- 30
        status <- "Unstable"
      }

      data.frame(
        variable = feature,
        psi = round(psi, 4),
        wasserstein = round(wasserstein, 4),
        stability = stability,

        # Added so plotting functions can access
        # feature-level stability directly.
        stability_score = stability,

        status = status,
        stringsAsFactors = FALSE
      )
    }
  )

  variables <- do.call(rbind, results)

  # ==========================================================
  # Overall stability score
  # ==========================================================

  valid_scores <- variables$stability[
    !is.na(variables$stability)
  ]

  if (length(valid_scores) == 0) {
    overall_score <- NA_real_
  } else {
    overall_score <- mean(valid_scores)
  }

  # ==========================================================
  # Categorize features
  # ==========================================================

  stable_features <- variables$variable[
    variables$status == "Stable"
  ]

  moderate_features <- variables$variable[
    variables$status == "Moderate Drift"
  ]

  unstable_features <- variables$variable[
    variables$status == "Unstable"
  ]

  # ==========================================================
  # User-friendly output
  # ==========================================================

  if (verbose) {

    cat("\n")
    cat("====================================================\n")
    cat("          Feature Stability Assessment\n")
    cat("====================================================\n\n")

    if (is.na(overall_score)) {

      cat(
        "Overall Stability Score : Not Available\n\n"
      )

    } else {

      cat(
        sprintf(
          "Overall Stability Score : %.2f / 100\n\n",
          overall_score
        )
      )
    }

    cat(
      sprintf(
        "Stable Features         : %d\n",
        length(stable_features)
      )
    )

    cat(
      sprintf(
        "Moderate Drift          : %d\n",
        length(moderate_features)
      )
    )

    cat(
      sprintf(
        "Unstable Features       : %d\n\n",
        length(unstable_features)
      )
    )

    # --------------------------------------------------------
    # Unstable features
    # --------------------------------------------------------

    cat("----------------------------------------------------\n")
    cat("UNSTABLE FEATURES\n")
    cat("----------------------------------------------------\n")

    if (length(unstable_features) == 0) {

      cat("✓ No unstable features detected.\n")

    } else {

      for (feature in unstable_features) {
        cat("• ", feature, "\n", sep = "")
      }

      cat(
        "\n⚠ These features show significant distribution drift.\n"
      )
    }

    cat("\n")

    # --------------------------------------------------------
    # Moderate drift
    # --------------------------------------------------------

    cat("----------------------------------------------------\n")
    cat("MODERATE DRIFT\n")
    cat("----------------------------------------------------\n")

    if (length(moderate_features) == 0) {

      cat(
        "✓ No features with moderate drift detected.\n"
      )

    } else {

      for (feature in moderate_features) {
        cat("• ", feature, "\n", sep = "")
      }
    }

    cat("\n")

    # --------------------------------------------------------
    # Stable features
    # --------------------------------------------------------

    cat("----------------------------------------------------\n")
    cat("STABLE FEATURES\n")
    cat("----------------------------------------------------\n")

    if (length(stable_features) == 0) {

      cat("No stable features detected.\n")

    } else {

      for (feature in stable_features) {
        cat("• ", feature, "\n", sep = "")
      }
    }

    cat("\n")

    # --------------------------------------------------------
    # Detailed analysis
    # --------------------------------------------------------

    cat("----------------------------------------------------\n")
    cat("DETAILED FEATURE ANALYSIS\n")
    cat("----------------------------------------------------\n\n")

    print(
      variables,
      row.names = FALSE
    )

    cat(
      "\n====================================================\n\n"
    )
  }

  # ==========================================================
  # Return detailed results
  # ==========================================================

  invisible(
    list(
      stability_score = round(overall_score, 2),
      variables = variables,
      unstable_features = unstable_features
    )
  )
}