test_that("plot.PrismReport renders ggplot objects for all 4 diagnostic types", {
  report <- prism(airquality, target = "Ozone")

  p_radial <- plot(report, type = "radial")
  expect_s3_class(p_radial, "ggplot")

  p_circular <- plot(report, type = "circular")
  expect_s3_class(p_circular, "ggplot")

  p_bubble <- plot(report, type = "bubble")
  expect_s3_class(p_bubble, "ggplot")

  p_radar <- plot(report, type = "radar", feature = "Solar.R")
  expect_s3_class(p_radar, "ggplot")
})

test_that("plot.PrismReport validates arguments and features", {
  report <- prism(airquality, target = "Ozone")

  expect_error(plot(report, type = "radar"), "Please specify 'feature'")
  expect_error(plot(report, type = "radar", feature = "non_existent_col"), "Feature .* not found")
  expect_error(plot.PrismReport("not a report"), "`x` must be a PrismReport object")
})

test_that("plot.PrismReport future-proofs stability automatically", {
  report <- prism(airquality, target = "Ozone")
  report$stability <- list(
    stability_score = 85,
    feature_stability = c(Ozone = 65, Solar.R = 90)
  )

  expect_s3_class(plot(report, type = "radial"), "ggplot")
  expect_s3_class(plot(report, type = "circular"), "ggplot")
  expect_s3_class(plot(report, type = "radar", feature = "Ozone"), "ggplot")
})

test_that("plot.PrismReport rejects invalid plot types gracefully", {
  report <- prism(airquality, target = "Ozone")
  expect_error(plot(report, type = "unsupported_type"), "Invalid plot type")
})
