# Detect Potential Data Leakage

Identifies potential sources of data leakage prior to predictive
modeling. The assessment includes identifier columns, duplicate columns,
high-cardinality features, predictors identical to the target, and
predictors showing an almost perfect correlation with the target.

## Usage

``` r
detect_leakage(data, target = NULL)
```

## Arguments

- data:

  A data.frame to assess.

- target:

  Optional name of the target variable. If supplied, predictors
  identical to the target or nearly perfectly correlated with the target
  are flagged as potential leakage.

## Value

A named list containing:

- identifier_columns:

  Names of columns identified as potential identifiers.

- duplicate_columns:

  Names of duplicated columns.

- high_cardinality_columns:

  Names of high-cardinality columns.

- target_leakage:

  Names of predictors identical to the target variable.

- correlation_leakage:

  Numeric predictors with near-perfect correlation to the target.

- leakage_score:

  Overall leakage score ranging from 0 to 100.

- variables:

  A data frame containing variable-level leakage diagnostics, including
  identifier, duplicate, high-cardinality, target leakage, correlation
  leakage, and leakage score.

## Examples

``` r
# Supervised leakage detection
res <- detect_leakage(airquality, target = "Ozone")
res$leakage_score
#> [1] 100
res$correlation_leakage
#> character(0)

# Unsupervised check for IDs and duplicates
res_unsupervised <- detect_leakage(iris)
res_unsupervised$identifier_columns
#> [1] "Sepal.Width" "Petal.Width"
```
