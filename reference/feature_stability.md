# Feature Stability and Distribution Drift Assessment

Evaluates feature distribution drift between reference and current
datasets (or across sequential time partitions of a single dataset)
using the Population Stability Index (PSI) and scale-normalized
Wasserstein distance across both numeric and categorical variables.

## Usage

``` r
feature_stability(
  data,
  current = NULL,
  split_ratio = 0.5,
  partition_col = NULL,
  verbose = FALSE
)
```

## Arguments

- data:

  A data.frame used as the reference baseline dataset (or the full
  dataset for single-dataset drift evaluation).

- current:

  Optional current data.frame to compare against `data`.

- split_ratio:

  Numeric. Proportion of rows to allocate to the reference dataset in
  single-dataset mode. Defaults to 0.5 (first 50% vs. last 50%).

- partition_col:

  Optional character. Column name to order by before partitioning in
  single-dataset mode (e.g., a timestamp or sequence ID).

- verbose:

  Logical. If TRUE, prints a formatted console stability report.
  Defaults to FALSE.

## Value

A list containing:

- stability_score:

  Overall stability score from 0 to 100.

- verdict:

  Categorical stability verdict: `"Stable"`, `"Moderate Drift"`, or
  `"Unstable"`.

- variables:

  A data frame of feature-level diagnostics containing `variable`,
  `type`, `psi`, `wasserstein`, `stability_score`, and `status`.

- unstable_features:

  Character vector of features flagged with severe drift (PSI \>= 0.25).

- moderate_features:

  Character vector of features flagged with moderate drift (0.10 \<= PSI
  \< 0.25).

- stable_features:

  Character vector of features exhibiting stable distributions (PSI \<
  0.10).

- method:

  Character string describing the assessment method used
  (`"two_sample_comparison"` or `"sequential_partition"`).

## Details

Feature drift is evaluated using standard industry thresholds:

- **Stable (PSI \< 0.10)**: Insignificant distributional shift.

- **Moderate Drift (0.10 \<= PSI \< 0.25)**: Noticeable shift;
  monitoring recommended.

- **Unstable / Severe Drift (PSI \>= 0.25)**: Severe distributional
  divergence; retraining or feature review required.

For categorical variables and discrete bins, Bayesian Laplace smoothing
is applied to prevent division-by-zero errors when frequencies are zero
in one partition.

If only one dataset is supplied, the function performs a sequential
partition-based stability assessment (comparing the first partition to
the second partition of observations). For production monitoring, users
should provide reference and current datasets separately via `data` and
`current`.

## Examples

``` r
# Single-dataset sequential drift evaluation
res <- feature_stability(airquality)
res$stability_score
#> [1] 43.3
res$verdict
#> [1] "Drift Warning (Unstable Features Detected)"

# Comparing reference baseline vs current dataset
ref <- data.frame(val = rnorm(100, 0, 1))
cur <- data.frame(val = rnorm(100, 2, 1))
res2 <- feature_stability(ref, current = cur)
res2$verdict
#> [1] "Drift Warning (Unstable Features Detected)"
```
