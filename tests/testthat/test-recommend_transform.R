test_that("recommend_transform identifies skewness and suggests proper transformations", {
  set.seed(42)
  df <- data.frame(
    normal_var = rnorm(100, mean = 50, sd = 5),
    skewed_positive = rlnorm(100, meanlog = 1, sdlog = 1.5),
    constant_var = rep(5, 100),
    cat_var = sample(c("A", "B", "C"), 100, replace = TRUE)
  )

  res <- recommend_transform(df)

  expect_type(res, "list")
  expect_equal(res$n_numeric, 3)
  expect_true(res$n_recommended >= 1)
  expect_s3_class(res$variables, "data.frame")

  # Skewed positive should recommend Log or Box-Cox / Yeo-Johnson
  skew_rec <- res$variables[res$variables$variable == "skewed_positive", "recommendation"]
  expect_true(skew_rec %in% c("Log", "Box-Cox", "Yeo-Johnson"))

  # Normal var should recommend None
  norm_rec <- res$variables[res$variables$variable == "normal_var", "recommendation"]
  expect_equal(norm_rec, "None")

  # recommendations data frame should only contain variables requiring transformation
  expect_equal(nrow(res$recommendations), res$n_recommended)
  expect_false("None" %in% res$recommendations$recommendation)
})

test_that("recommend_transform suggests Yeo-Johnson when non-positive values exist", {
  set.seed(123)
  # Skewed feature containing zeros and negative numbers
  x_skewed_with_neg <- -rexp(100, rate = 0.5)
  df <- data.frame(skew_neg = x_skewed_with_neg)

  res <- recommend_transform(df)
  expect_equal(res$n_numeric, 1)
  expect_equal(res$variables$recommendation[1], "Yeo-Johnson")
})

test_that("recommend_transform handles zero-variance and constant numeric columns", {
  df <- data.frame(
    constant_num = rep(10, 50),
    normal_col = rnorm(50)
  )

  res <- recommend_transform(df)
  expect_equal(res$n_numeric, 2)
  # Constant numeric should safely recommend None
  expect_equal(res$variables$recommendation[res$variables$variable == "constant_num"], "None")
})

test_that("recommend_transform validates input arguments", {
  expect_error(recommend_transform("not a dataframe"), "`data` must be a data.frame")
  expect_error(recommend_transform(list(a = 1:5)), "`data` must be a data.frame")
})
