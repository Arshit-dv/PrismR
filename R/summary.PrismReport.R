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

  invisible(object)

}
