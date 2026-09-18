test_that("prism returns a valid PrismReport S3 object with correct verdicts", {
  report <- prism(airquality, target = "Ozone")

  expect_s3_class(report, "PrismReport")
  expect_named(report, c("quality", "leakage", "transformation", "stability", "readiness", "verdict"))
  expect_true(is.numeric(report$readiness))
  expect_true(report$readiness >= 0 && report$readiness <= 100)
  expect_true(report$verdict %in% c("Model Ready", "Proceed with Caution", "Action Required"))
})

test_that("prism print and summary methods execute cleanly and include stability", {
  report <- prism(airquality, target = "Ozone")

  expect_output(print(report), "Feature Stability")
  expect_output(summary(report), "Feature Stability")
})

test_that("prism visual diagnostic suite generates ggplot objects with stability integrated", {
  report <- prism(airquality, target = "Ozone")

  p_radial <- plot(report, type = "radial")
  expect_s3_class(p_radial, "ggplot")

  p_circular <- plot(report, type = "circular")
  expect_s3_class(p_circular, "ggplot")

  p_bubble <- plot(report, type = "bubble")
  expect_s3_class(p_bubble, "ggplot")

  p_radar <- plot(report, type = "radar", feature = "Wind")
  expect_s3_class(p_radar, "ggplot")
})

test_that("prism enforces hard gating veto when target leakers or drift exist", {
  n <- 50
  df <- data.frame(
    x1 = rnorm(n),
    x2 = rnorm(n),
    target = rnorm(n)
  )
  # Inject target leaker
  df$leaker <- df$target

  report <- prism(df, target = "target")
  # Despite pristine quality, leaker triggers hard veto
  expect_true(report$verdict %in% c("Proceed with Caution", "Action Required"))
})

test_that("prism accepts current dataset for two-sample drift evaluation", {
  train_df <- data.frame(x = rnorm(50, mean = 0), y = rnorm(50))
  test_df <- data.frame(x = rnorm(50, mean = 5), y = rnorm(50)) # drifted x

  report <- prism(train_df, target = "y", current = test_df)
  expect_s3_class(report, "PrismReport")
  expect_true("x" %in% report$stability$unstable_features || report$stability$stability_score < 100)
})

test_that("prism operates without a target column", {
  df <- data.frame(a = rnorm(30), b = rlnorm(30))
  report <- prism(df)
  expect_s3_class(report, "PrismReport")
  expect_null(report$leakage$target)
})
