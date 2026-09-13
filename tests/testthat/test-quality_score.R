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

test_that("quality_score validates data.frame input", {
  expect_error(quality_score("not a dataframe"), "`data` must be a data.frame")
})
