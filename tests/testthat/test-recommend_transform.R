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
})
