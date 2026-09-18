# Perform Complete Prism Statistical Validation

Evaluates dataset readiness for predictive modeling across four
foundational statistical pillars: data quality, data leakage,
distribution transformations, and feature stability. Produces an overall
Model Readiness score (0-100) and a gatekeeping verdict.

## Usage

``` r
prism(data, target = NULL, current = NULL)
```

## Arguments

- data:

  A data.frame to assess.

- target:

  Optional character string specifying the name of the target/label
  variable.

- current:

  Optional current data.frame to evaluate distribution drift against
  baseline `data`.

## Value

A `PrismReport` S3 object containing:

- quality:

  List of data quality metrics returned by
  [`quality_score`](https://arshit-dv.github.io/PrismR/reference/quality_score.md).

- leakage:

  List of data leakage diagnostics returned by
  [`detect_leakage`](https://arshit-dv.github.io/PrismR/reference/detect_leakage.md).

- transformation:

  List of transformation recommendations returned by
  [`recommend_transform`](https://arshit-dv.github.io/PrismR/reference/recommend_transform.md).

- stability:

  List of stability metrics returned by
  [`feature_stability`](https://arshit-dv.github.io/PrismR/reference/feature_stability.md).

- readiness:

  Overall composite Model Readiness score (0-100).

- verdict:

  Gatekeeping verdict: `"Model Ready"`, `"Proceed with Caution"`, or
  `"Action Required"`.

## Details

The four evaluation dimensions include:

- **Data Quality**: Evaluates missingness, duplicate rows, and constant
  features.

- **Data Leakage**: Identifies identifier keys, duplicate features,
  high-cardinality columns, and target correlation leakers.

- **Transformations**: Evaluates skewness and excess kurtosis to
  recommend variance-stabilizing transforms (Box-Cox, Yeo-Johnson, Log).

- **Feature Stability**: Assesses covariate distribution drift via
  Population Stability Index (PSI) and Wasserstein distance.

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
