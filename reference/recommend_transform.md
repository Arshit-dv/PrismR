# Recommend Feature Transformations

Analyses numeric variables in a data frame and recommends suitable
transformations based on skewness and excess kurtosis. The function does
not modify the data; it only provides transformation recommendations to
assist with preprocessing before statistical modelling or machine
learning.

## Usage

``` r
recommend_transform(data)
```

## Arguments

- data:

  A data.frame containing predictor variables.

## Value

A list containing:

- recommendations:

  A data frame of features requiring transformation (excluding
  `"None"`).

- n_numeric:

  Number of numeric variables analysed.

- n_recommended:

  Number of variables for which a transformation was recommended.

- variables:

  A complete data frame of all analysed numeric features and their
  metrics.

## Details

Recommendations are based on:

- Distribution skewness.

- Excess kurtosis (tail heaviness).

- Whether the variable contains non-positive values.

Possible recommendations include:

- None

- Log

- Box-Cox

- Yeo-Johnson

## Examples

``` r
recommend_transform(iris)
#> $recommendations
#> [1] variable       skewness       kurtosis       finding        recommendation
#> <0 rows> (or 0-length row.names)
#> 
#> $n_numeric
#> [1] 4
#> 
#> $n_recommended
#> [1] 0
#> 
#> $variables
#>       variable   skewness  kurtosis                 finding recommendation
#> 1 Sepal.Length  0.3149110 -0.552064 Approximately symmetric           None
#> 2  Sepal.Width  0.3189657  0.228249 Approximately symmetric           None
#> 3 Petal.Length -0.2748842 -1.402103 Approximately symmetric           None
#> 4  Petal.Width -0.1029667 -1.340604 Approximately symmetric           None
#> 
```
