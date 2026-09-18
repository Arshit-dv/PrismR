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
