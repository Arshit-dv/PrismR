#' Print a PrismReport
#'
#' @param x A PrismReport object.
#' @param ... Additional arguments.
#'
#' @export

print.PrismReport <- function(x,...){

  cat("Prism Report\n")
  cat("-------------------------\n")
  cat("Model Readiness: ",x$readiness,"\n")
  cat("Verdict        : ",x$verdict,"\n")

  invisible(x)
}
