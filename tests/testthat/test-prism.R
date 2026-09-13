test_that("prism returns a valid PrismReport S3 object with correct verdicts", {
  report <- prism(airquality, target = "Ozone")

  expect_s3_class(report, "PrismReport")
  expect_named(report, c("quality", "leakage", "transformation", "stability", "readiness", "verdict"))
  expect_true(is.numeric(report$readiness))
  expect_true(report$readiness >= 0 && report$readiness <= 100)
  expect_true(report$verdict %in% c("Model Ready", "Proceed with Caution", "Action Required"))
})

test_that("prism print and summary methods execute cleanly", {
  report <- prism(airquality, target = "Ozone")

  expect_output(print(report), "Prism Report")
  expect_output(summary(report), "Prism Summary")
})
