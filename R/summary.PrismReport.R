#' Summarize a PrismReport
#'
#' @param object A PrismReport object.
#' @param ... Additional arguments.
#'
#' @export

summary.PrismReport <- function(object, ...) {

  print(object)

  cat("\n")
  cat("Quality Summary\n")
  cat("-------------------------------------\n")

  if (object$quality$quality_score >= 90) {

    cat("Excellent dataset quality.\n")

  } else if (object$quality$quality_score >= 75) {

    cat("Good dataset quality with minor issues.\n")

  } else if (object$quality$quality_score >= 60) {

    cat("Moderate dataset quality. Review preprocessing.\n")

  } else {

    cat("Poor dataset quality. Significant preprocessing required.\n")

  }

  invisible(object)
}
