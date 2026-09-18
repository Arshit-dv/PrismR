#' Detect Potential Data Leakage
#'
#' Identifies potential sources of data leakage prior to predictive modeling.
#' The assessment includes identifier columns, duplicate columns,
#' high-cardinality features, predictors identical to the target,
#' and predictors showing an almost perfect correlation with the target.
#'
#' @param data A data.frame to assess.
#' @param target Optional name of the target variable. If supplied,
#'   predictors identical to the target or nearly perfectly correlated
#'   with the target are flagged as potential leakage.
#'
#' @return A named list containing:
#' \describe{
#'   \item{identifier_columns}{Names of columns identified as potential identifiers.}
#'   \item{duplicate_columns}{Names of duplicated columns.}
#'   \item{high_cardinality_columns}{Names of high-cardinality columns.}
#'   \item{target_leakage}{Names of predictors identical to the target variable.}
#'   \item{correlation_leakage}{Numeric predictors with near-perfect correlation to the target.}
#'   \item{leakage_score}{Overall leakage score ranging from 0 to 100.}
#'   \item{variables}{
#'   A data frame containing variable-level leakage diagnostics,
#'   including identifier, duplicate, high-cardinality,
#'   target leakage, correlation leakage, and leakage score.
#'   }
#' }
#'
#' @examples
#' # Supervised leakage detection
#' res <- detect_leakage(airquality, target = "Ozone")
#' res$leakage_score
#' res$correlation_leakage
#'
#' # Unsupervised check for IDs and duplicates
#' res_unsupervised <- detect_leakage(iris)
#' res_unsupervised$identifier_columns
#'
#' @export
detect_leakage <- function(data, target = NULL) {

  # ==========================================================
  # Input validation
  # ==========================================================
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.")
  }

  n_cols <- ncol(data)

  # ==========================================================
  # Identifier Column Assessment
  #
  # A column is considered an identifier if:
  #   • its name contains id, key, uuid, or guid
  #   • OR it is an integer/character/factor column where
  #     at least 99% of non-missing values are unique.
  # ==========================================================
  identifier_columns <- names(data)[
    sapply(names(data), function(col) {

      x <- data[[col]]
      x <- x[!is.na(x)]

      if (length(x) == 0) {
        return(FALSE)
      }

      name_is_id <-
        grepl("(id|key|uuid|guid)", col, ignore.case = TRUE)

      unique_ratio <- length(unique(x)) / length(x)

      unique_identifier <-
        (is.character(x) ||
           is.factor(x) ||
           (is.numeric(x) && all(x %% 1 == 0))) &&
        unique_ratio >= 0.99

      name_is_id || unique_identifier
    })
  ]

  n_identifier <- length(identifier_columns)

  # ==========================================================
  # Duplicate Column Assessment
  # ==========================================================
  duplicate_columns <- character(0)

  if (n_cols > 1) {

    for (i in seq_len(n_cols - 1)) {

      for (j in (i + 1):n_cols) {

        if (identical(data[[i]], data[[j]])) {

          duplicate_columns <- c(
            duplicate_columns,
            names(data)[j]
          )

        }

      }

    }

  }

  duplicate_columns <- unique(duplicate_columns)

  n_duplicate <- length(duplicate_columns)

  # ==========================================================
  # High Cardinality Assessment
  #
  # A column is considered high-cardinality if:
  #   • it is a character, factor, or integer-like numeric column
  #   • AND more than 95% of its non-missing values are unique.
  # ==========================================================
  high_cardinality_columns <- names(data)[
    sapply(data, function(x) {

      x <- x[!is.na(x)]

      if (length(x) == 0) {
        return(FALSE)
      }

      # Continuous numeric variables are not treated as
      # high-cardinality identifiers.
      if (!(is.character(x) ||
            is.factor(x) ||
            (is.numeric(x) && all(x %% 1 == 0)))) {
        return(FALSE)
      }

      unique_ratio <- length(unique(x)) / length(x)

      unique_ratio > 0.95
    })
  ]

  n_high_cardinality <- length(high_cardinality_columns)

  # ==========================================================
  # Target Leakage Assessment
  # ==========================================================
  target_leakage <- character(0)

  if (!is.null(target)) {

    if (!target %in% names(data)) {
      stop("`target` column not found in data.")
    }

    y <- data[[target]]

    predictors <- setdiff(names(data), target)

    target_leakage <- predictors[
      sapply(predictors, function(col) {
        identical(data[[col]], y)
      })
    ]

  }

  n_target_leakage <- length(target_leakage)

  # ==========================================================
  # Correlation Leakage Assessment
  #
  # Detect numeric predictors that are almost perfectly
  # correlated with a numeric target.
  # ==========================================================
  correlation_leakage <- character(0)

  if (!is.null(target)) {

    y <- data[[target]]

    if (is.numeric(y)) {

      predictors <- setdiff(names(data), target)

      for (col in predictors) {

        x <- data[[col]]

        if (is.numeric(x)) {

          ok <- complete.cases(x, y)

          if (sum(ok) > 2) {

            r <- suppressWarnings(cor(x[ok], y[ok]))

            if (!is.na(r) && abs(r) >= 0.999) {

              correlation_leakage <-
                c(correlation_leakage, col)

            }

          }

        }

      }

    }

  }

  correlation_leakage <- unique(correlation_leakage)

  # ==========================================================
  # Leakage Score Calculation
  #
  # Starting score : 100
  #
  # Penalties
  #   • Identifier columns      : 25%
  #   • Duplicate columns       : 20%
  #   • High-cardinality        : 20%
  #   • Target leakage          : 20%
  #   • Correlation leakage     : 15%
  #
  # Final score is bounded between 0 and 100.
  # ==========================================================
  identifier_penalty <-
    (n_identifier / max(1, n_cols)) * 25

  duplicate_penalty <-
    (n_duplicate / max(1, n_cols)) * 20

  high_cardinality_penalty <-
    (n_high_cardinality / max(1, n_cols)) * 20

  target_penalty <-
    if (n_target_leakage > 0) 20 else 0

  correlation_penalty <-
    if (length(correlation_leakage) > 0) 15 else 0

  score <-
    100 -
    identifier_penalty -
    duplicate_penalty -
    high_cardinality_penalty -
    target_penalty -
    correlation_penalty

  leakage_score <- max(0, min(100, round(score, 1)))


  # ==========================================================
  # Variable-level Leakage Assessment
  # ==========================================================
  variable_metrics <- data.frame(
    variable = names(data),
    identifier = names(data) %in% identifier_columns,
    duplicate = names(data) %in% duplicate_columns,
    high_cardinality = names(data) %in% high_cardinality_columns,
    target_leakage = names(data) %in% target_leakage,
    correlation = names(data) %in% correlation_leakage,
    stringsAsFactors = FALSE
  )

  # Per-variable leakage score
  variable_metrics$leakage_score <- 100

  variable_metrics$leakage_score <-
    variable_metrics$leakage_score -
    ifelse(variable_metrics$identifier, 25, 0)

  variable_metrics$leakage_score <-
    variable_metrics$leakage_score -
    ifelse(variable_metrics$duplicate, 20, 0)

  variable_metrics$leakage_score <-
    variable_metrics$leakage_score -
    ifelse(variable_metrics$high_cardinality, 20, 0)

  variable_metrics$leakage_score <-
    variable_metrics$leakage_score -
    ifelse(variable_metrics$target_leakage, 20, 0)

  variable_metrics$leakage_score <-
    variable_metrics$leakage_score -
    ifelse(variable_metrics$correlation, 15, 0)

  variable_metrics$leakage_score <-
    pmax(0, variable_metrics$leakage_score)


  # ==========================================================
  # Return Leakage Assessment
  # ==========================================================
  list(
    identifier_columns = identifier_columns,
    duplicate_columns = duplicate_columns,
    high_cardinality_columns = high_cardinality_columns,
    target_leakage = target_leakage,
    correlation_leakage = correlation_leakage,
    leakage_score = leakage_score,

    variables = variable_metrics
  )

}
