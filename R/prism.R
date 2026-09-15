#' Perform Complete Prism Statistical Validation
#'
#' Evaluates dataset readiness for predictive modeling across
#' data quality, data leakage, distribution transformations,
#' and feature stability.
#'
#' @param data A data.frame to assess.
#' @param target Optional name of the target variable.
#'
#' @return A \code{PrismReport} S3 object containing detailed
#'   validation metrics and readiness verdict.
#'
#' @examples
#' report <- prism(airquality, target = "Ozone")
#' print(report)
#' summary(report)
#'
#' @export
prism <- function(data, target = NULL) {

  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }

  quality <- quality_score(data)
  leakage <- detect_leakage(data, target)
  transformation <- recommend_transform(data)
  stability <- feature_stability(data,verbose=FALSE)

  # Calculate transformation health score (0-100)
  trans_health <- if (transformation$n_numeric > 0) {
    (1 - (transformation$n_recommended / transformation$n_numeric)) * 100
  } else {
    100
  }

  # Calculate composite readiness score (0-100)
  # Quality: 40%, Leakage: 45%, Transformation: 15%
  readiness_score <- round(
    0.40 * quality$quality_score +
    0.45 * leakage$leakage_score +
    0.15 * trans_health,
    1
  )
  readiness_score <- max(0, min(100, readiness_score))

  # Determine overall readiness verdict
  verdict <- if (readiness_score >= 85 && leakage$leakage_score >= 80) {
    "Model Ready"
  } else if (readiness_score >= 65 && leakage$leakage_score >= 50) {
    "Proceed with Caution"
  } else {
    "Action Required"
  }

  new_PrismReport(
    quality = quality,
    leakage = leakage,
    transformation = transformation,
    stability = stability,
    readiness = readiness_score,
    verdict = verdict
  )
}