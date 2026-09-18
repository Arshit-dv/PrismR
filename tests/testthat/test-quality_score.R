test_that("quality_score returns expected structure and metrics", {
  df <- data.frame(
    a = c(1, 2, 3, 4, 5),
    b = c(10, NA, 30, 40, 50),
    c = c(1, 1, 1, 1, 1) # constant
  )

  res <- quality_score(df)

  expect_type(res, "list")
  expect_named(res, c("missing_percent", "duplicate_rows", "constant_columns", "n_constant_columns", "quality_score", "variables"))
  expect_equal(res$n_constant_columns, 1)
  expect_equal(res$constant_columns, "c")
  expect_true(res$missing_percent > 0)
  expect_true(res$quality_score <= 100 && res$quality_score >= 0)
  expect_s3_class(res$variables, "data.frame")
})

test_that("quality_score handles pristine datasets perfectly", {
  df <- data.frame(
    x = 1:20,
    y = rnorm(20),
    z = letters[1:20]
  )

  res <- quality_score(df)

  expect_equal(res$missing_percent, 0)
  expect_equal(res$duplicate_rows, 0)
  expect_equal(res$n_constant_columns, 0)
  expect_equal(res$quality_score, 100)
})

test_that("quality_score detects duplicate rows and heavy missingness", {
  df <- data.frame(
    a = c(1, 1, 2, 3, 3),
    b = c("x", "x", "y", "z", "z"),
    c = c(NA, NA, NA, NA, NA) # 100% missing
  )

  res <- quality_score(df)
  expect_equal(res$duplicate_rows, 2)
  expect_true(res$missing_percent >= 33)
  expect_true(res$quality_score < 100)
  expect_true(res$variables$missing_percent[res$variables$variable == "c"] == 100)
})

test_that("quality_score handles multiple constant columns and factor types", {
  df <- data.frame(
    num_const = rep(42, 30),
    char_const = rep("A", 30),
    factor_const = factor(rep("group1", 30)),
    normal_col = 1:30
  )

  res <- quality_score(df)
  expect_equal(res$n_constant_columns, 3)
  expect_true(all(c("num_const", "char_const", "factor_const") %in% res$constant_columns))
})

test_that("quality_score validates data.frame input and empty data", {
  expect_error(quality_score("not a dataframe"), "`data` must be a data.frame")
  expect_error(quality_score(1:10), "`data` must be a data.frame")
})
