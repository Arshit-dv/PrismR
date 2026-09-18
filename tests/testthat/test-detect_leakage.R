test_that("detect_leakage detects ID columns, duplicate columns, and leakers", {
  n <- 50
  df <- data.frame(
    id_col = 1:n,
    dup_col = rep(10, n),
    normal_feature = rnorm(n),
    target = rnorm(n)
  )
  df$leaker <- df$target # exact target leaker

  res <- detect_leakage(df, target = "target")

  expect_type(res, "list")
  expect_true("id_col" %in% res$identifier_columns)
  expect_true("leaker" %in% res$target_leakage)
  expect_true(res$leakage_score < 100)
  expect_s3_class(res$variables, "data.frame")
})

test_that("detect_leakage detects correlation leakage", {
  n <- 50
  y <- rnorm(n)
  df <- data.frame(
    x_correlated = y + 1e-6,
    x_normal = rnorm(n),
    y = y
  )

  res <- detect_leakage(df, target = "y")

  expect_true("x_correlated" %in% res$correlation_leakage)
})

test_that("detect_leakage detects negative correlation leakage", {
  n <- 50
  y <- rnorm(n)
  df <- data.frame(
    x_neg_correlated = -y + 1e-6,
    x_normal = rnorm(n),
    y = y
  )

  res <- detect_leakage(df, target = "y")
  expect_true("x_neg_correlated" %in% res$correlation_leakage)
})

test_that("detect_leakage operates without a target variable (unsupervised mode)", {
  n <- 40
  df <- data.frame(
    id = paste0("ID_", 1:n),
    col1 = 1:n,
    col2 = 1:n # duplicate of col1
  )

  res <- detect_leakage(df, target = NULL)
  expect_type(res, "list")
  expect_true("id" %in% res$identifier_columns)
  expect_true("col2" %in% res$duplicate_columns)
  expect_equal(length(res$target_leakage), 0)
  expect_equal(length(res$correlation_leakage), 0)
})

test_that("detect_leakage flags high-cardinality discrete features", {
  n <- 60
  df <- data.frame(
    unique_codes = paste0("CODE_", 1:n),
    target = rnorm(n),
    stringsAsFactors = FALSE
  )

  res <- detect_leakage(df, target = "target")
  expect_true("unique_codes" %in% res$high_cardinality_columns)
})

test_that("detect_leakage validates target existence and data.frame input", {
  df <- data.frame(a = 1:10)
  expect_error(detect_leakage(df, target = "missing_target"), "target.*column not found")
  expect_error(detect_leakage("not_a_df"), "`data` must be a data.frame")
})
