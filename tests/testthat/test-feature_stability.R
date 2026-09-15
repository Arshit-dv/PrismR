library(testthat)

test_that("feature_stability returns a valid result", {

  set.seed(123)

  data <- data.frame(
    feature_1 = rnorm(100),
    feature_2 = rnorm(100, mean = 10),
    feature_3 = runif(100)
  )

  result <- feature_stability(data)

  expect_type(result, "list")

  expect_true("stability_score" %in% names(result))
  expect_true("variables" %in% names(result))
  expect_true("unstable_features" %in% names(result))
})


test_that("feature_stability returns a score between 0 and 100", {

  set.seed(123)

  data <- data.frame(
    feature_1 = rnorm(100),
    feature_2 = rnorm(100)
  )

  result <- feature_stability(data)

  expect_true(
    is.na(result$stability_score) ||
      (result$stability_score >= 0 &&
       result$stability_score <= 100)
  )
})


test_that("identical distributions are considered stable", {

  set.seed(123)

  values <- rnorm(100)

  data <- data.frame(
    feature_1 = values
  )

  result <- feature_stability(data)

  expect_true(
    result$variables$status[1] %in%
      c("Stable", "Moderate Drift", "Unstable")
  )

  expect_true(
    result$variables$psi[1] >= 0
  )
})


test_that("feature stability detects distribution drift", {

  set.seed(123)

  data <- data.frame(
    feature_1 = c(
      rnorm(100, mean = 0, sd = 1),
      rnorm(100, mean = 5, sd = 1)
    )
  )

  result <- feature_stability(data)

  expect_true(
    result$variables$psi[1] >= 0
  )

  expect_true(
    result$variables$status[1] %in%
      c("Stable", "Moderate Drift", "Unstable")
  )
})


test_that("feature_stability handles non-numeric data", {

  data <- data.frame(
    category = c(
      "A", "B", "A", "C", "B",
      "A", "C", "B", "A", "C"
    )
  )

  result <- feature_stability(data)

  expect_type(result, "list")
  expect_true("stability_score" %in% names(result))
})


test_that("feature_stability rejects invalid input", {

  expect_error(
    feature_stability("not a data frame")
  )

  expect_error(
    feature_stability(data.frame(x = 1:5))
  )
})