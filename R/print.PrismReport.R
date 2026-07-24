#' Print a PrismReport
#'
#' @param x A PrismReport object.
#' @param ... Additional arguments.
#'
#' @export
print.PrismReport <- function(x, ...) {

  cat("\n")
  cat("=====================================\n")
  cat("          Prism Report\n")
  cat("=====================================\n\n")

  cat("Model Readiness :", x$readiness, "\n")
  cat("Prism Verdict   :", x$verdict, "\n\n")

  # ==========================================================
  # Data Quality
  # ==========================================================
  cat("Data Quality\n")
  cat("-------------------------------------\n")
  cat("Quality Score    :", x$quality$quality_score, "/100\n")
  cat("Missing (%)      :", x$quality$missing_percent, "\n")
  cat("Duplicate Rows   :", x$quality$duplicate_rows, "\n")
  cat("Constant Columns :", length(x$quality$constant_columns), "\n")

  if (length(x$quality$constant_columns) > 0) {
    cat(
      "Column Names     :",
      paste(x$quality$constant_columns, collapse = ", "),
      "\n"
    )
  }

  cat("\n")

  # ==========================================================
  # Leakage Detection
  # ==========================================================
  cat("Leakage Detection\n")
  cat("-------------------------------------\n")
  cat("Leakage Safety Score          :", x$leakage$leakage_score, "/100\n")
  cat("Identifier Columns     :", length(x$leakage$identifier_columns), "\n")
  cat("Duplicate Columns      :", length(x$leakage$duplicate_columns), "\n")
  cat("High Cardinality       :", length(x$leakage$high_cardinality_columns), "\n")
  cat("Target Leakage         :", length(x$leakage$target_leakage), "\n")

  if (length(x$leakage$identifier_columns) > 0) {
    cat(
      "Identifiers           :",
      paste(x$leakage$identifier_columns, collapse = ", "),
      "\n"
    )
  }

  if (length(x$leakage$duplicate_columns) > 0) {
    cat(
      "Duplicate Columns     :",
      paste(x$leakage$duplicate_columns, collapse = ", "),
      "\n"
    )
  }

  if (length(x$leakage$high_cardinality_columns) > 0) {
    cat(
      "High Cardinality      :",
      paste(x$leakage$high_cardinality_columns, collapse = ", "),
      "\n"
    )
  }

  if (length(x$leakage$target_leakage) > 0) {
    cat(
      "Target Leakage        :",
      paste(x$leakage$target_leakage, collapse = ", "),
      "\n"
    )
  }

  invisible(x)

}
