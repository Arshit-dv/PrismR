#' Print a PrismReport
#'
#' @param x A \code{PrismReport} object returned by \code{\link{prism}}.
#' @param ... Additional arguments passed to print methods.
#'
#' @return Invisibly returns the input \code{PrismReport} object.
#' @examples
#' report <- prism(airquality, target = "Ozone")
#' print(report)
#'
#' @export
print.PrismReport <- function(x, ...) {

  # ==========================================================
  # Verdicts
  # ==========================================================

  quality_verdict <-
    if (x$quality$quality_score >= 90) {
      "Excellent"
    } else if (x$quality$quality_score >= 75) {
      "Good"
    } else if (x$quality$quality_score >= 60) {
      "Fair"
    } else if (x$quality$quality_score >= 40) {
      "Poor"
    } else {
      "Critical"
    }

  leakage_verdict <-
    if (x$leakage$leakage_score >= 95) {
      "Safe"
    } else if (x$leakage$leakage_score >= 80) {
      "Low Risk"
    } else if (x$leakage$leakage_score >= 60) {
      "Moderate Risk"
    } else if (x$leakage$leakage_score >= 40) {
      "High Risk"
    } else {
      "Critical Risk"
    }

  cat("\n")
  cat("=========================================================\n")
  cat("                     Prism Report\n")
  cat("=========================================================\n\n")

  cat("Model Readiness :", x$readiness, "\n")
  cat("Overall Verdict :", x$verdict, "\n\n")

  # ==========================================================
  # Data Quality
  # ==========================================================

  cat("=========================================================\n")
  cat("Data Quality\n")
  cat("=========================================================\n\n")

  cat("Quality Score :", x$quality$quality_score, "/100\n")
  cat("Verdict       :", quality_verdict, "\n\n")

  cat("Missing Values      :", x$quality$missing_percent, "%\n")
  cat("Duplicate Rows      :", x$quality$duplicate_rows, "\n")
  cat("Constant Columns    :", x$quality$n_constant_columns, "\n")

  if (x$quality$n_constant_columns > 0) {

    cat(
      "Column Names        :",
      paste(x$quality$constant_columns, collapse = ", "),
      "\n"
    )

  } else {

    cat("\n")
    cat("\u2713 No major data quality issues detected.\n")

  }

  cat("\n\n")

  # ==========================================================
  # Leakage Detection
  # ==========================================================

  cat("=========================================================\n")
  cat("Leakage Detection\n")
  cat("=========================================================\n\n")

  cat("Leakage Safety Score :", x$leakage$leakage_score, "/100\n")
  cat("Verdict              :", leakage_verdict, "\n\n")

  cat("Identifier Columns      :", length(x$leakage$identifier_columns), "\n")
  cat("Duplicate Columns       :", length(x$leakage$duplicate_columns), "\n")
  cat("High Cardinality        :", length(x$leakage$high_cardinality_columns), "\n")
  cat("Target Leakage          :", length(x$leakage$target_leakage), "\n")
  cat("Correlation Leakage     :", length(x$leakage$correlation_leakage), "\n")

  total_leaks <-
    length(x$leakage$identifier_columns) +
    length(x$leakage$duplicate_columns) +
    length(x$leakage$high_cardinality_columns) +
    length(x$leakage$target_leakage) +
    length(x$leakage$correlation_leakage)

  if (total_leaks == 0) {

    cat("\n")
    cat("\u2713 No potential leakage detected.\n")

  } else {

    cat("\nPotential Issues\n")
    cat("----------------\n")

    if (length(x$leakage$identifier_columns) > 0) {

      cat(
        "Identifiers          :",
        paste(x$leakage$identifier_columns, collapse = ", "),
        "\n"
      )

    }

    if (length(x$leakage$duplicate_columns) > 0) {

      cat(
        "Duplicate Columns    :",
        paste(x$leakage$duplicate_columns, collapse = ", "),
        "\n"
      )

    }

    if (length(x$leakage$high_cardinality_columns) > 0) {

      cat(
        "High Cardinality     :",
        paste(x$leakage$high_cardinality_columns, collapse = ", "),
        "\n"
      )

    }

    if (length(x$leakage$target_leakage) > 0) {

      cat(
        "Target Leakage       :",
        paste(x$leakage$target_leakage, collapse = ", "),
        "\n"
      )

    }

    if (length(x$leakage$correlation_leakage) > 0) {

      cat(
        "Correlation Leakage  :",
        paste(x$leakage$correlation_leakage, collapse = ", "),
        "\n"
      )

    }

  }

  cat("\n\n")

  # ==========================================================
  # Transformation Analysis
  # ==========================================================

  cat("=========================================================\n")
  cat("Transformation Analysis\n")
  cat("=========================================================\n\n")

  cat(
    "Numeric Variables Analysed :",
    x$transformation$n_numeric,
    "\n"
  )

  cat(
    "Transformations Needed     :",
    x$transformation$n_recommended,
    "\n"
  )

  if (x$transformation$n_recommended == 0) {

    cat("\n")
    cat("\u2713 No feature transformations are recommended.\n")

  } else {

    rec <- x$transformation$recommendations

    rec <- rec[
      rec$recommendation != "None",
      ,
      drop = FALSE
    ]

    cat("\n")

    cat(
      sprintf(
        "%-20s %-30s %-20s\n",
        "Variable",
        "Finding",
        "Recommendation"
      )
    )

    cat(
      paste(rep("-", 70), collapse = ""),
      "\n",
      sep = ""
    )

    for (i in seq_len(nrow(rec))) {

      cat(
        sprintf(
          "%-20s %-30s %-20s\n",
          rec$variable[i],
          rec$finding[i],
          rec$recommendation[i]
        )
      )

    }

    remaining <-
      x$transformation$n_numeric -
      x$transformation$n_recommended

    if (remaining > 0) {

      cat(
        "\n\u2713 Remaining",
        remaining,
        "variables require no transformation.\n"
      )

    }

  }

  # ==========================================================
  # Feature Stability
  # ==========================================================

  cat("\n=========================================================\n")
  cat("Feature Stability\n")
  cat("=========================================================\n\n")

  if (is.null(x$stability) || !is.list(x$stability)) {
    cat("Feature Stability analysis not available.\n")
  } else {
    stab_score <- x$stability$stability_score
    stab_verdict <- if (!is.null(x$stability$verdict)) x$stability$verdict else "Not Available"

    if (is.na(stab_score)) {
      cat("Overall Stability Score : Not Available\n")
    } else {
      cat("Overall Stability Score :", stab_score, "/100\n")
    }
    cat("Verdict                 :", stab_verdict, "\n\n")

    stab_df <- x$stability$variables
    if (is.data.frame(stab_df) && nrow(stab_df) > 0) {
      st_feats <- x$stability$stable_features
      mod_feats <- x$stability$moderate_features
      unst_feats <- x$stability$unstable_features

      cat("Evaluated Features      :", nrow(stab_df), "\n")
      cat("Stable Features         :", length(st_feats), "\n")
      cat("Moderate Drift          :", length(mod_feats), "\n")
      cat("Unstable Features       :", length(unst_feats), "\n")

      if (length(unst_feats) > 0) {
        cat("\nUnstable Features (Drift Detected)\n")
        cat("----------------------------------\n")
        for (feat in unst_feats) {
          sub_r <- stab_df[stab_df$variable == feat, ]
          cat(sprintf("\u2022 %-20s (PSI: %.4f)\n", feat, sub_r$psi[1]))
        }
      }

      if (length(mod_feats) > 0) {
        cat("\nModerate Drift\n")
        cat("--------------\n")
        for (feat in mod_feats) {
          sub_r <- stab_df[stab_df$variable == feat, ]
          cat(sprintf("\u2022 %-20s (PSI: %.4f)\n", feat, sub_r$psi[1]))
        }
      }

      if (length(unst_feats) == 0 && length(mod_feats) == 0) {
        cat("\n\u2713 No significant distribution drift detected across features.\n")
      }
    } else {
      cat("No features available for stability analysis.\n")
    }
  }

  cat("\n\n")
  invisible(x)
}
