#' Perform Complete Prism Statistical Validation
#'
#' Evaluates dataset readiness for predictive modeling across four foundational
#' statistical pillars: data quality, data leakage, distribution transformations,
#' and feature stability. Produces an overall Model Readiness score (0-100) and
#' a gatekeeping verdict.
#'
#' The four evaluation dimensions include:
#' \itemize{
#'   \item \strong{Data Quality}: Evaluates missingness, duplicate rows, and constant features.
#'   \item \strong{Data Leakage}: Identifies identifier keys, duplicate features, high-cardinality columns, and target correlation leakers.
#'   \item \strong{Transformations}: Evaluates skewness and excess kurtosis to recommend variance-stabilizing transforms (Box-Cox, Yeo-Johnson, Log).
#'   \item \strong{Feature Stability}: Assesses covariate distribution drift via Population Stability Index (PSI) and Wasserstein distance.
#' }
#'
#' @param data A data.frame to assess.
#' @param target Optional character string specifying the name of the target/label variable.
#' @param current Optional current data.frame to evaluate distribution drift against baseline \code{data}.
#'
#' @return A \code{PrismReport} S3 object containing:
#' \describe{
#'   \item{quality}{List of data quality metrics returned by \code{\link{quality_score}}.}
#'   \item{leakage}{List of data leakage diagnostics returned by \code{\link{detect_leakage}}.}
#'   \item{transformation}{List of transformation recommendations returned by \code{\link{recommend_transform}}.}
#'   \item{stability}{List of stability metrics returned by \code{\link{feature_stability}}.}
#'   \item{readiness}{Overall composite Model Readiness score (0-100).}
#'   \item{verdict}{Gatekeeping verdict: \code{"Model Ready"}, \code{"Proceed with Caution"}, or \code{"Action Required"}.}
#' }
#'
#' @examples
#' report <- prism(airquality, target = "Ozone")
#' print(report)
#' summary(report)
#'
#' @importFrom stats complete.cases cor quantile sd var
#' @importFrom utils globalVariables
#'
#' @export
prism <- function(data, target = NULL, current = NULL) {

  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.", call. = FALSE)
  }

  quality <- quality_score(data)
  leakage <- detect_leakage(data, target)
  transformation <- recommend_transform(data)
  stability <- feature_stability(data, current = current, verbose = FALSE)

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

  # Determine overall readiness verdict (gated by leakage and feature stability)
  has_unstable_drift <- !is.null(stability$unstable_features) &&
                        length(stability$unstable_features) > 0

  verdict <- if (readiness_score >= 85 && leakage$leakage_score >= 80 && !has_unstable_drift) {
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

