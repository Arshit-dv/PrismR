# Print a PrismReport

Print a PrismReport

## Usage

``` r
# S3 method for class 'PrismReport'
print(x, ...)
```

## Arguments

- x:

  A `PrismReport` object returned by
  [`prism`](https://arshit-dv.github.io/PrismR/reference/prism.md).

- ...:

  Additional arguments passed to print methods.

## Value

Invisibly returns the input `PrismReport` object.

## Examples

``` r
report <- prism(airquality, target = "Ozone")
print(report)
#> 
#> =========================================================
#>                      Prism Report
#> =========================================================
#> 
#> Model Readiness : 96.5 
#> Overall Verdict : Proceed with Caution 
#> 
#> =========================================================
#> Data Quality
#> =========================================================
#> 
#> Quality Score : 97.6 /100
#> Verdict       : Excellent 
#> 
#> Missing Values      : 4.79 %
#> Duplicate Rows      : 0 
#> Constant Columns    : 0 
#> 
#> ✓ No major data quality issues detected.
#> 
#> 
#> =========================================================
#> Leakage Detection
#> =========================================================
#> 
#> Leakage Safety Score : 100 /100
#> Verdict              : Safe 
#> 
#> Identifier Columns      : 0 
#> Duplicate Columns       : 0 
#> High Cardinality        : 0 
#> Target Leakage          : 0 
#> Correlation Leakage     : 0 
#> 
#> ✓ No potential leakage detected.
#> 
#> 
#> =========================================================
#> Transformation Analysis
#> =========================================================
#> 
#> Numeric Variables Analysed : 6 
#> Transformations Needed     : 1 
#> 
#> Variable             Finding                        Recommendation      
#> ----------------------------------------------------------------------
#> Ozone                Severely right-skewed          Box-Cox             
#> 
#> ✓ Remaining 5 variables require no transformation.
#> 
#> =========================================================
#> Feature Stability
#> =========================================================
#> 
#> Overall Stability Score : 43.3 /100
#> Verdict                 : Drift Warning (Unstable Features Detected) 
#> 
#> Evaluated Features      : 6 
#> Stable Features         : 0 
#> Moderate Drift          : 2 
#> Unstable Features       : 4 
#> 
#> Unstable Features (Drift Detected)
#> ----------------------------------
#> • Solar.R              (PSI: 0.3718)
#> • Wind                 (PSI: 0.2610)
#> • Temp                 (PSI: 0.5042)
#> • Month                (PSI: 5.0878)
#> 
#> Moderate Drift
#> --------------
#> • Ozone                (PSI: 0.1814)
#> • Day                  (PSI: 0.1401)
#> 
#> 
```
