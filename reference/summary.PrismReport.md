# Summarize a PrismReport

Summarize a PrismReport

## Usage

``` r
# S3 method for class 'PrismReport'
summary(object, ...)
```

## Arguments

- object:

  A `PrismReport` object returned by
  [`prism`](https://arshit-dv.github.io/PrismR/reference/prism.md).

- ...:

  Additional arguments passed to summary methods.

## Value

Invisibly returns the input `PrismReport` object.

## Examples

``` r
report <- prism(airquality, target = "Ozone")
summary(report)
#> 
#> =========================================================
#>                     Prism Summary
#> =========================================================
#> 
#> Model Readiness : 96.5 
#> Overall Verdict : Proceed with Caution 
#> 
#> Data Quality
#> -----------------------------------------
#> Data Quality Score : 97.6/100 (Excellent)
#> 
#> Leakage Detection
#> -----------------------------------------
#> Leakage Safety Score : 100/100 (Safe)
#> 
#> Transformation Analysis
#> -----------------------------------------
#> 1 variable(s) require transformation.
#> 
#> • Ozone -> Box-Cox
#> 
#> Feature Stability
#> -----------------------------------------
#> Overall Stability Score : 43.3/100
#> Stability Verdict       : Drift Warning (Unstable Features Detected)
#> Stable Features         : 0
#> Moderate Drift          : 2
#> Unstable Features       : 4
#> 
#> ⚠ Unstable Features:
#> • Solar.R
#> • Wind
#> • Temp
#> • Month
#> 
#> Moderate Drift:
#> • Ozone
#> • Day
```
