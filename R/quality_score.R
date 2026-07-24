#' Data Quality Assessment
#'
#' Computes basic data quality metrics for a dataset, including
#' missing values, duplicate rows, constant columns, and an
#' overall quality score.
#'
#' @param data A data.frame to assess.
#'
#' @return A named list containing:
#' \describe{
#'   \item{missing_percent}{Percentage of missing values.}
#'   \item{duplicate_rows}{Number of duplicated rows.}
#'   \item{constant_columns}{Names of constant columns.}
#'   \item{n_constant_columns}{Number of constant columns.}
#'   \item{quality_score}{Overall quality score (0–100).}
#' }
#'
#' @export
quality_score <- function(data) {

  # ==========================================================
  # Input validation
  # ==========================================================
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame.")
  }

  n_rows <- nrow(data)
  n_cols <- ncol(data)

  # ==========================================================
  # Missing Value Assessment
  # ==========================================================
  total_cells <- n_rows * n_cols
  missing_values <- sum(is.na(data))

  missing_percent <-
    if (total_cells == 0) {
      0
    } else {
      (missing_values / total_cells) * 100
    }

  # ==========================================================
  # Duplicate Row Assessment
  # ==========================================================
  duplicate_rows <- sum(duplicated(data))

  duplicate_percent <-
    if (n_rows == 0) {
      0
    } else {
      (duplicate_rows / n_rows) * 100
    }
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

  n_duplicate_columns <- length(duplicate_columns)

  duplicate_column_percent <-
    if (n_cols == 0) {
      0
    } else {
      (n_duplicate_columns / n_cols) * 100
    }
  # ==========================================================
  # Constant Feature Assessment
  # A constant feature contains only one unique non-missing value.
  # Columns containing only NA values are also treated as constant.
  # ==========================================================
  constant_columns <- names(data)[
    sapply(data, function(x) {

      x <- x[!is.na(x)]

      if (length(x) == 0) {
        return(TRUE)
      }

      length(unique(x)) == 1
    })
  ]

  n_constant <- length(constant_columns)

  constant_percent <-
    if (n_cols == 0) {
      0
    } else {
      (n_constant / n_cols) * 100
    }

  # ==========================================================
  # Quality Score Calculation
  #
  # Starting score : 100
  #
  # Penalties
  #   • Missing values      : 50%
  #   • Duplicate rows      : 30%
  #   • Constant features   : 20%
  #
  # Final score is bounded between 0 and 100.
  # ==========================================================
  missing_penalty  <- missing_percent * 0.50
  duplicate_penalty <- duplicate_percent * 0.30
  constant_penalty <- constant_percent * 0.20

  score <-
    100 -
    missing_penalty -
    duplicate_penalty -
    constant_penalty

  score <- max(0, min(100, round(score, 1)))

  # ==========================================================
  # Return Quality Assessment
  # ==========================================================
  list(
    missing_percent = round(missing_percent, 2),
    duplicate_rows = duplicate_rows,
    constant_columns = constant_columns,
    n_constant_columns = n_constant,
    quality_score = score
  )
}
