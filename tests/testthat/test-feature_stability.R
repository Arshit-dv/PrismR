test_that("feature_stability returns a valid structure with score and verdict", {
  data <- data.frame(
    num1 = seq(1, 100),
    num2 = rnorm(100),
    cat1 = rep(c("A", "B", "C", "D"), 25),
    stringsAsFactors = FALSE
  )

  res <- feature_stability(data, verbose = FALSE)

  expect_type(res, "list")
  expect_named(res, c(
    "stability_score", "verdict", "variables",
    "unstable_features", "moderate_features", "stable_features", "method"
  ))
  expect_true(is.numeric(res$stability_score))
  expect_true(res$stability_score >= 0 && res$stability_score <= 100)
  expect_true(is.character(res$verdict))
  expect_true(is.data.frame(res$variables))
  expect_true(all(c("variable", "type", "psi", "wasserstein", "norm_wasserstein", "stability_score", "status") %in% names(res$variables)))
})

test_that("feature_stability evaluates both numeric and categorical features", {
  data <- data.frame(
    numeric_col = 1:50,
    factor_col = factor(rep(c("low", "med", "high"), length.out = 50)),
    char_col = rep(c("X", "Y"), 25),
    stringsAsFactors = FALSE
  )

  res <- feature_stability(data, verbose = FALSE)
  types <- res$variables$type
  expect_true("Numeric" %in% types)
  expect_true("Categorical" %in% types)
})

test_that("feature_stability detects distribution drift between reference and current", {
  ref <- data.frame(
    val = rnorm(100, mean = 0, sd = 1),
    group = rep("A", 100),
    stringsAsFactors = FALSE
  )
  cur <- data.frame(
    val = rnorm(100, mean = 10, sd = 1),
    group = rep("B", 100),
    stringsAsFactors = FALSE
  )

  res <- feature_stability(ref, current = cur, verbose = FALSE)

  # Extreme shift should be flagged as Unstable
  expect_true("val" %in% res$unstable_features)
  expect_true("group" %in% res$unstable_features)
  expect_match(res$verdict, "Drift Warning")
})

test_that("identical distributions return Stable status", {
  vals <- seq(1, 100)
  ref <- data.frame(num = vals, cat = rep(c("A", "B"), 50), stringsAsFactors = FALSE)
  cur <- data.frame(num = vals, cat = rep(c("A", "B"), 50), stringsAsFactors = FALSE)

  res <- feature_stability(ref, current = cur, verbose = FALSE)

  expect_equal(res$stability_score, 100)
  expect_equal(length(res$unstable_features), 0)
  expect_match(res$verdict, "Stable")
})

test_that("feature_stability handles single-dataset sequential mode deterministically", {
  data <- data.frame(
    x = 1:60,
    y = rep(c("alpha", "beta"), 30),
    stringsAsFactors = FALSE
  )

  res1 <- feature_stability(data, verbose = FALSE)
  res2 <- feature_stability(data, verbose = FALSE)

  expect_equal(res1$stability_score, res2$stability_score)
  expect_equal(res1$variables$psi, res2$variables$psi)
  expect_match(res1$method, "Sequential Partition")
})

test_that("feature_stability input validation guards work as expected", {
  expect_error(feature_stability("not_a_df"), "`data` must be a data.frame.")
  expect_error(feature_stability(data.frame(x = 1:5)), "`data` must contain at least 10 rows.")
  expect_error(
    feature_stability(data.frame(x = 1:20), current = "invalid"),
    "`current` must be a data.frame."
  )
  expect_error(
    feature_stability(data.frame(a = 1:20), current = data.frame(b = 1:20)),
    "`data` and `current` must share at least one common feature."
  )
})

test_that("feature_stability console reporting prints without error", {
  data <- data.frame(x = 1:40, y = rep(c("M", "F"), 20), stringsAsFactors = FALSE)
  expect_output(feature_stability(data, verbose = TRUE), "Feature Stability Assessment")
})
