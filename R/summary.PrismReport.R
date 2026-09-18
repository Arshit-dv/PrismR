#' Summarize a PrismReport
#'
#' @param object A \code{PrismReport} object returned by \code{\link{prism}}.
#' @param ... Additional arguments passed to summary methods.
#'
#' @return Invisibly returns the input \code{PrismReport} object.
#' @examples
#' report <- prism(airquality, target = "Ozone")
#' summary(report)
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

    cat("\u2713 No feature transformations recommended.\n")

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
        "\u2022 ",
        x["variable"],
        " -> ",
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

  if (is.null(object$stability) || !is.list(object$stability)) {
    cat("Feature Stability analysis not available.\n")
  } else {
    stab_score <- object$stability$stability_score
    stab_verdict <- if (!is.null(object$stability$verdict)) object$stability$verdict else "Not Available"

    if (is.na(stab_score)) {
      cat("Overall Stability Score : Not Available\n")
    } else {
      cat("Overall Stability Score : ", stab_score, "/100\n", sep = "")
    }
    cat("Stability Verdict       : ", stab_verdict, "\n", sep = "")

    stab_df <- object$stability$variables
    if (is.data.frame(stab_df) && nrow(stab_df) > 0) {
      st_feats <- object$stability$stable_features
      mod_feats <- object$stability$moderate_features
      unst_feats <- object$stability$unstable_features

      cat("Stable Features         : ", length(st_feats), "\n", sep = "")
      cat("Moderate Drift          : ", length(mod_feats), "\n", sep = "")
      cat("Unstable Features       : ", length(unst_feats), "\n", sep = "")

      if (length(unst_feats) > 0) {
        cat("\n\u26A0 Unstable Features:\n")
        for (feat in unst_feats) {
          cat("\u2022 ", feat, "\n", sep = "")
        }
      }

      if (length(mod_feats) > 0) {
        cat("\nModerate Drift:\n")
        for (feat in mod_feats) {
          cat("\u2022 ", feat, "\n", sep = "")
        }
      }

      if (length(unst_feats) == 0 && length(mod_feats) == 0) {
        cat("\n\u2713 No unstable features detected.\n")
      }
    }
  }

  invisible(object)

}
