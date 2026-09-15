#' Summarize a PrismReport
#'
#' @param object A PrismReport object.
#' @param ... Additional arguments.
#'
#' @export
summary.PrismReport <- function(object, ...) {

  # ==========================================================
  # Verdicts
  # ==========================================================

  quality_verdict <-
    if (object$quality$quality_score >= 90) {
      "Excellent"
    } else if (object$quality$quality_score >= 75) {
      "Good"
    } else if (object$quality$quality_score >= 60) {
      "Fair"
    } else if (object$quality$quality_score >= 40) {
      "Poor"
    } else {
      "Critical"
    }

  leakage_verdict <-
    if (object$leakage$leakage_score >= 95) {
      "Safe"
    } else if (object$leakage$leakage_score >= 80) {
      "Low Risk"
    } else if (object$leakage$leakage_score >= 60) {
      "Moderate Risk"
    } else if (object$leakage$leakage_score >= 40) {
      "High Risk"
    } else {
      "Critical Risk"
    }

  cat("\n")
  cat("=========================================================\n")
  cat("                    Prism Summary\n")
  cat("=========================================================\n\n")

  cat("Model Readiness :", object$readiness, "\n")
  cat("Overall Verdict :", object$verdict, "\n\n")

  # ==========================================================
  # Quality
  # ==========================================================

  cat("Data Quality\n")
  cat("-----------------------------------------\n")
  cat(
    "Data Quality Score : ",
    object$quality$quality_score,
    "/100 (",
    quality_verdict,
    ")\n",
    sep = ""
  )

  # ==========================================================
  # Leakage
  # ==========================================================

  cat("\nLeakage Detection\n")
  cat("-----------------------------------------\n")
  cat(
    "Leakage Safety Score : ",
    object$leakage$leakage_score,
    "/100 (",
    leakage_verdict,
    ")\n",
    sep = ""
  )

  # ==========================================================
  # Transformations
  # ==========================================================

  cat("\nTransformation Analysis\n")
  cat("-----------------------------------------\n")

  if (object$transformation$n_recommended == 0) {

    cat("✓ No feature transformations recommended.\n")

  } else {

    cat(
      object$transformation$n_recommended,
      "variable(s) require transformation.\n\n"
    )

    rec <- object$transformation$recommendations
    rec <- rec[
      rec$recommendation != "None",
      ,
      drop = FALSE
    ]

    apply(rec, 1, function(x) {

      cat(
        "• ",
        x["variable"],
        " → ",
        x["recommendation"],
        "\n",
        sep = ""
      )

    })
  }

  # ==========================================================
  # Feature Stability
  # ==========================================================

  cat("\nFeature Stability\n")
  cat("-----------------------------------------\n")

  if (is.null(object$stability)) {

    cat("Feature Stability analysis not available.\n")

  } else {

    stability_score <- object$stability$stability_score

    if (is.na(stability_score)) {

      cat("Overall Stability Score : Not Available\n")

    } else {

      cat(
        "Overall Stability Score : ",
        stability_score,
        "/100\n",
        sep = ""
      )
    }

    stability_data <- object$stability$variables

    if (!is.null(stability_data) &&
        nrow(stability_data) > 0) {

      stable_features <- stability_data$variable[
        stability_data$status == "Stable"
      ]

      moderate_features <- stability_data$variable[
        stability_data$status == "Moderate Drift"
      ]

      unstable_features <- stability_data$variable[
        stability_data$status == "Unstable"
      ]

      cat(
        "Stable Features         : ",
        length(stable_features),
        "\n",
        sep = ""
      )

      cat(
        "Moderate Drift          : ",
        length(moderate_features),
        "\n",
        sep = ""
      )

      cat(
        "Unstable Features       : ",
        length(unstable_features),
        "\n",
        sep = ""
      )

      # --------------------------------------------------------
      # Unstable features
      # --------------------------------------------------------

      if (length(unstable_features) > 0) {

        cat("\n⚠ Unstable Features:\n")

        for (feature in unstable_features) {
          cat("• ", feature, "\n", sep = "")
        }

      } else {

        cat("\n✓ No unstable features detected.\n")
      }

      # --------------------------------------------------------
      # Moderate drift
      # --------------------------------------------------------

      if (length(moderate_features) > 0) {

        cat("\nModerate Drift:\n")

        for (feature in moderate_features) {
          cat("• ", feature, "\n", sep = "")
        }
      }
    }
  }

  invisible(object)
}