# Data Quality Assessment

Computes basic data quality metrics for a dataset, including missing
values, duplicate rows, constant columns, and an overall quality score.

## Usage

``` r
quality_score(data)
```

## Arguments

- data:

  A data.frame to assess.

## Value

A named list containing:

- missing_percent:

  Percentage of missing values.

- duplicate_rows:

  Number of duplicated rows.

- constant_columns:

  Names of constant columns.

- n_constant_columns:

  Number of constant columns.

- quality_score:

  Overall quality score (0-100).

- variables:

  A data frame containing variable-level quality metrics, including
  missing percentage, constant feature indicator, and quality score.

## Examples

``` r
res <- quality_score(airquality)
res$quality_score
#> [1] 97.6
res$missing_percent
#> [1] 4.79
```
