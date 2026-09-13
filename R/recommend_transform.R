#============================================================
# Internal Constants
#============================================================

# Skewness thresholds
.SKEW_SYMMETRIC <- 0.5
.SKEW_SEVERE    <- 1.0

# Excess kurtosis thresholds
.KURT_HEAVY   <- 2.0
.KURT_EXTREME <- 5.0

# Transformation labels
.TRANS_NONE <- "None"
.TRANS_LOG  <- "Log"
.TRANS_BOX  <- "Box-Cox"
.TRANS_YJ   <- "Yeo-Johnson"

# Finding labels
.FIND_INSUFFICIENT <- "Insufficient data"
.FIND_CONSTANT     <- "Constant variable"

.FIND_SYMMETRIC <- "Approximately symmetric"

.FIND_RIGHT_MOD <- "Moderately right-skewed"
.FIND_RIGHT_SEV <- "Severely right-skewed"

.FIND_LEFT_MOD <- "Moderately left-skewed"
.FIND_LEFT_SEV <- "Severely left-skewed"

.FIND_HEAVY <- "with heavy tails"


#============================================================
# Analyse a Single Variable
#============================================================

recommend_one_variable <- function(x) {

  #----------------------------------------------------------
  # Remove missing values
  #----------------------------------------------------------

  x <- stats::na.omit(x)

  #----------------------------------------------------------
  # Validate data
  #----------------------------------------------------------

  if (length(x) < 3) {

    return(list(
      skewness = NA_real_,
      kurtosis = NA_real_,
      finding = .FIND_INSUFFICIENT,
      recommendation = NA_character_
    ))

  }

  if (stats::var(x) == 0) {

    return(list(
      skewness = 0,
      kurtosis = 0,
      finding = .FIND_CONSTANT,
      recommendation = .TRANS_NONE
    ))

  }

  #----------------------------------------------------------
  # Distribution statistics
  #----------------------------------------------------------

  skew <- e1071::skewness(
    x,
    type = 2,
    na.rm = TRUE
  )

  kurt <- e1071::kurtosis(
    x,
    type = 2,
    na.rm = TRUE
  )

  positive_only <- all(x > 0)

  finding <- NULL
  recommendation <- .TRANS_NONE

  #----------------------------------------------------------
  # Approximately symmetric
  #----------------------------------------------------------

  if (abs(skew) < .SKEW_SYMMETRIC) {

    if (kurt < .KURT_HEAVY) {

      finding <- .FIND_SYMMETRIC
      recommendation <- .TRANS_NONE

    } else {

      finding <- paste(
        .FIND_SYMMETRIC,
        .FIND_HEAVY
      )

      recommendation <- if (positive_only) {
        .TRANS_BOX
      } else {
        .TRANS_YJ
      }

    }

  }

  #----------------------------------------------------------
  # Moderate positive skew
  #----------------------------------------------------------

  else if (skew >= .SKEW_SYMMETRIC &&
           skew <= .SKEW_SEVERE) {

    if (kurt < .KURT_EXTREME) {

      finding <- .FIND_RIGHT_MOD

      recommendation <- if (positive_only) {
        .TRANS_LOG
      } else {
        .TRANS_YJ
      }

    } else {

      finding <- paste(
        .FIND_RIGHT_MOD,
        .FIND_HEAVY
      )

      recommendation <- if (positive_only) {
        .TRANS_BOX
      } else {
        .TRANS_YJ
      }

    }

  }

  #----------------------------------------------------------
  # Severe positive skew
  #----------------------------------------------------------

  else if (skew > .SKEW_SEVERE) {

    if (kurt < .KURT_EXTREME) {

      finding <- .FIND_RIGHT_SEV

    } else {

      finding <- paste(
        .FIND_RIGHT_SEV,
        .FIND_HEAVY
      )

    }

    recommendation <- if (positive_only) {
      .TRANS_BOX
    } else {
      .TRANS_YJ
    }

  }

  #----------------------------------------------------------
  # Moderate negative skew
  #----------------------------------------------------------

  else if (skew <= -.SKEW_SYMMETRIC &&
           skew >= -.SKEW_SEVERE) {

    if (kurt < .KURT_EXTREME) {

      finding <- .FIND_LEFT_MOD

    } else {

      finding <- paste(
        .FIND_LEFT_MOD,
        .FIND_HEAVY
      )

    }

    recommendation <- .TRANS_YJ

  }

  #----------------------------------------------------------
  # Severe negative skew
  #----------------------------------------------------------

  else {

    if (kurt < .KURT_EXTREME) {

      finding <- .FIND_LEFT_SEV

    } else {

      finding <- paste(
        .FIND_LEFT_SEV,
        .FIND_HEAVY
      )

    }

    recommendation <- .TRANS_YJ

  }

  list(
    skewness = skew,
    kurtosis = kurt,
    finding = finding,
    recommendation = recommendation
  )

}
#============================================================
# Recommend Transformations
#============================================================

#' Recommend Feature Transformations
#'
#' Analyses numeric variables in a data frame and recommends
#' suitable transformations based on skewness and excess kurtosis.
#' The function does not modify the data; it only provides
#' transformation recommendations to assist with preprocessing
#' before statistical modelling or machine learning.
#'
#' Recommendations are based on:
#' \itemize{
#'   \item Distribution skewness.
#'   \item Excess kurtosis (tail heaviness).
#'   \item Whether the variable contains non-positive values.
#' }
#'
#' Possible recommendations include:
#' \itemize{
#'   \item None
#'   \item Log
#'   \item Box-Cox
#'   \item Yeo-Johnson
#' }
#'
#' @param data A data.frame containing predictor variables.
#'
#' @return A list containing:
#' \describe{
#'   \item{recommendations}{
#'   A data frame containing:
#'   \itemize{
#'     \item variable
#'     \item skewness
#'     \item kurtosis
#'     \item finding
#'     \item recommendation
#'   }
#'   }
#'   \item{n_numeric}{
#'   Number of numeric variables analysed.
#'   }
#'   \item{n_recommended}{
#'   Number of variables for which a transformation was recommended.
#'   }
#'   \item{variables}{
#'   A data frame containing variable-level transformation
#'   diagnostics and recommendations.
#'   }
#' }
#'
#' @examples
#' recommend_transform(iris)
#'
#' @export
recommend_transform <- function(data) {

  #----------------------------------------------------------
  # Validate input
  #----------------------------------------------------------

  if (!is.data.frame(data)) {
    stop("'data' must be a data.frame.")
  }

  #----------------------------------------------------------
  # Identify numeric variables
  #----------------------------------------------------------

  numeric_cols <- names(data)[
    vapply(data, is.numeric, logical(1))
  ]

  #----------------------------------------------------------
  # No numeric variables
  #----------------------------------------------------------

  if (length(numeric_cols) == 0) {

    return(list(
      recommendations = data.frame(
        variable = character(),
        skewness = numeric(),
        kurtosis = numeric(),
        finding = character(),
        recommendation = character(),
        stringsAsFactors = FALSE
      ),
      n_numeric = 0L,
      n_recommended = 0L
    ))

  }

  #----------------------------------------------------------
  # Analyse each numeric variable
  #----------------------------------------------------------

  results <- lapply(numeric_cols, function(var) {

    result <- recommend_one_variable(data[[var]])

    data.frame(
      variable = var,
      skewness = result$skewness,
      kurtosis = result$kurtosis,
      finding = result$finding,
      recommendation = result$recommendation,
      stringsAsFactors = FALSE
    )

  })

  recommendations <- do.call(rbind, results)

  rownames(recommendations) <- NULL

  #----------------------------------------------------------
  # Summary statistics
  #----------------------------------------------------------

  n_numeric <- length(numeric_cols)

  n_recommended <- sum(
    recommendations$recommendation != .TRANS_NONE,
    na.rm = TRUE
  )

  #----------------------------------------------------------
  # Return results
  #----------------------------------------------------------

  list(
    recommendations = recommendations,
    n_numeric = n_numeric,
    n_recommended = n_recommended,

    variables = recommendations
  )
}
