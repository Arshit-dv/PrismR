#' Plot a PrismReport
#'
#' @param x A PrismReport object.
#' @param ... Additional arguments.
#'
#' @export

plot.PrismReport <- function(x, ...) {

  metrics <- c(
    QualityScore = x$quality$quality_score,
    Missing = x$quality$missing_percent,
    DuplicateRows = x$quality$duplicate_rows,
    ConstantColumns = length(x$quality$constant_columns)
  )

  barplot(
    metrics,
    main = "PrismR Data Quality Summary",
    ylab = "Value",
    ylim = c(0, max(metrics) * 1.2),
    las = 2
  )
}
