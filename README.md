PrismR

A Statistical Validation Framework for Evaluating Dataset Readiness Before Predictive Modelling.

PrismR is an open-source R package that introduces the concept of Model Readiness: a structured statistical assessment of whether tabular data is suitable for predictive modelling before a machine learning algorithm is trained.

Rather than tuning models on compromised data, PrismR adds a dedicated Statistical Validation Layer between data preparation and model training.

Why PrismR?

In traditional machine learning pipelines, large amounts of effort are spent on model selection and tuning, while problems such as missing values, leakage, distributional anomalies, and feature drift may remain hidden.

Traditional Workflow

Raw Data
   |
   v
Cleaning
   |
   v
Feature Engineering
   |
   v
Model Training
   |
   v
Silent data issues may be discovered too late

PrismR Workflow

Raw Data
   |
   v
Cleaning
   |
   v
+----------------------------------+
|     Statistical Validation       |
|          PrismR Layer            |
|        (Model Readiness)         |
+----------------------------------+
   |
   v
Feature Engineering
   |
   v
Model Training

The "Prism" Philosophy

A physical prism separates white light into its hidden components. Similarly, PrismR refracts tabular data to reveal hidden data-quality problems, leakage channels, transformation requirements, and feature distribution drift without modifying the original dataset.

                         Tabular Dataset
                                |
                                v
                           +---------+
                           | PrismR  |
                           +---------+
                                |
           +--------------------+--------------------+
           |                    |                    |
           v                    v                    v
    Data Quality        Leakage Safety       Transformation
    (Missing/Dups)      (IDs/Leakage)        (Skew/Kurtosis)
           |
           +--------------------+--------------------+
                                |
                                v
                       Feature Stability
                          (Drift / PSI)
                                |
                                v
                     Overall Model Readiness

Quick Start

library(PrismR)

# Run the complete validation workflow
report <- prism(airquality, target = "Ozone")

# View the complete report
print(report)

# View the concise summary
summary(report)

High-Level Summary

summary(report)

The summary() method provides a concise overview of the major validation dimensions, including Feature Stability.

=========================================================
                     Prism Summary
=========================================================

Model Readiness : 96.5
Overall Verdict : Model Ready

Data Quality
-----------------------------------------
Data Quality Score : 97.6/100 (Excellent)

Leakage Detection
-----------------------------------------
Leakage Safety Score : 100/100 (Safe)

Transformation Analysis
-----------------------------------------
1 variable(s) require transformation.

• Ozone → Box-Cox

Feature Stability
-----------------------------------------
Overall Stability Score : 63.33/100

Stable Features   : 0
Moderate Drift    : 5
Unstable Features : 1

Unstable:
• Solar.R

Moderate Drift:
• Ozone
• Wind
• Temp
• Month
• Day

Detailed Diagnostic Audit

print(report)

The print() method provides the complete diagnostic report across all PrismR validation modules.

=========================================================
                     Prism Report
=========================================================

Model Readiness : 96.5
Overall Verdict : Model Ready

=========================================================
Data Quality
=========================================================

Quality Score : 97.6 /100
Verdict       : Excellent

Missing Values      : 4.79 %
Duplicate Rows      : 0
Constant Columns    : 0

✓ No major data quality issues detected.

=========================================================
Leakage Detection
=========================================================

Leakage Safety Score : 100 /100
Verdict              : Safe

Identifier Columns      : 0
Duplicate Columns       : 0
High Cardinality        : 0
Target Leakage          : 0
Correlation Leakage     : 0

✓ No potential leakage detected.

=========================================================
Transformation Analysis
=========================================================

Numeric Variables Analysed : 6
Transformations Needed     : 1

Variable             Finding                        Recommendation
----------------------------------------------------------------------
Ozone                Severely right-skewed          Box-Cox

✓ Remaining 5 variables require no transformation.

=========================================================
Feature Stability
=========================================================

Overall Stability Score : 63.33 /100

Stable Features         : 0
Moderate Drift          : 5
Unstable Features       : 1

Unstable Features
-----------------
• Solar.R

Moderate Drift
--------------
• Ozone
• Wind
• Temp
• Month
• Day

Feature Stability Analysis

PrismR includes a dedicated Feature Stability module for detecting distribution drift between a reference dataset and a current dataset.

The module provides:

Population Stability Index (PSI) as the primary drift metric.

Wasserstein distance as a supporting distribution-distance metric.

A per-feature stability score.

Automatic classification into Stable, Moderate Drift, and Unstable.

Feature Stability can compare two explicitly supplied datasets or, when only one dataset is supplied, use a deterministic internal partition for reproducible analysis.

Feature Stability Function

feature_stability(data, current = NULL, verbose = TRUE)

# Standalone feature stability assessment
stability <- feature_stability(airquality)

# Overall score
stability$stability_score

# Per-feature results
stability$variables

# Unstable feature names
stability$unstable_features

Reference vs. Current Data

stability <- feature_stability(
  reference_data,
  current = current_data
)

Both datasets should contain compatible feature columns.

When current is not supplied, PrismR creates a deterministic partition of the supplied dataset so that the analysis is reproducible.

Stability Metrics

Population Stability Index (PSI)

PSI is the primary metric used to classify feature distribution drift.

PSI Range

Classification

Stability Score

< 0.10

Stable

100

0.10 – < 0.25

Moderate Drift

70

>= 0.25

Unstable

30

Lower PSI values indicate that the current distribution is closer to the reference distribution.

Wasserstein Distance

Wasserstein distance provides an additional measure of the separation between two feature distributions.

Because Wasserstein distance is scale-dependent, PrismR uses it as a supporting metric rather than the primary classification criterion.

Example Feature Stability Output

For the built-in airquality dataset:

====================================================
          Feature Stability Assessment
====================================================

Overall Stability Score : 63.33 / 100

Stable Features         : 0
Moderate Drift          : 5
Unstable Features       : 1

----------------------------------------------------
UNSTABLE FEATURES
----------------------------------------------------
• Solar.R

⚠ These features show significant distribution drift.

----------------------------------------------------
MODERATE DRIFT
----------------------------------------------------
• Ozone
• Wind
• Temp
• Month
• Day

----------------------------------------------------
STABLE FEATURES
----------------------------------------------------
No stable features detected.

----------------------------------------------------
DETAILED FEATURE ANALYSIS
----------------------------------------------------

 variable    psi wasserstein stability stability_score         status
    Ozone 0.1830      7.6695        70              70 Moderate Drift
  Solar.R 0.2696     12.0425        30              30       Unstable
     Wind 0.1367      0.3928        70              70 Moderate Drift
     Temp 0.1885      1.1682        70              70 Moderate Drift
    Month 0.1582      0.4852        70              70 Moderate Drift
      Day 0.2014      1.1876        70              70 Moderate Drift

Feature Stability in prism()

Feature Stability is automatically integrated into the complete prism() workflow.

report <- prism(
  airquality,
  target = "Ozone"
)

The stability analysis is performed silently inside the pipeline and its results are stored in the returned PrismReport object.

report$stability

The stability object contains:

$stability_score
[1] 63.33

$variables
  variable    psi wasserstein stability stability_score         status
  Ozone       ...
  Solar.R     ...
  Wind        ...
  Temp        ...
  Month       ...
  Day         ...

$unstable_features
[1] "Solar.R"

The same stability results are reused by:

summary(report)

print(report)

plot(report, type = "radial")

plot(report, type = "circular")

plot(report, type = "bubble")

plot(report, type = "radar")

Visual Diagnostic Suite

PrismR includes four diagnostic visualizations built with ggplot2.

# Macro Dataset Health Gauge
plot(report, type = "radial")

# Feature Diagnostic Rose
plot(report, type = "circular")

# Statistical Feature Map
plot(report, type = "bubble")

# Single-Feature Radar Profile
plot(report, type = "radar", feature = "Solar.R")

1. Macro Dataset Health Gauge

type = "radial"

Tracks overall model readiness alongside the individual validation dimensions.

The visualization dynamically adds a Feature Stability track whenever stability analysis is available.

<p align="center">
  <img src="man/figures/radial_gauge.png" alt="PrismR Macro Dataset Health Gauge" width="520">
</p>

Tracks include:

Overall Model Readiness

Data Quality

Leakage Safety

Transformation Health

Feature Stability when available

2. Feature Diagnostic Rose

type = "circular"

A circular feature-level visualization combining completeness, leakage-related status, transformation recommendations, and stability information.

<p align="center">
  <img src="man/figures/circular_rose.png" alt="PrismR Feature Diagnostic Rose" width="560">
</p>

Feature status categories include:

🟩 Clean Feature

🟦 Identifier / High-Cardinality

🟧 Duplicate / Constant Feature

🟪 Unstable Distribution Drift

🟥 Target Leaker

The unstable-drift category is automatically activated using Feature Stability results.

3. Statistical Feature Map

type = "bubble"

Maps Feature Completeness against Distribution Skewness.

<p align="center">
  <img src="man/figures/bubble_map.png" alt="PrismR Statistical Feature Map" width="680">
</p>

The visualization includes:

A central region for approximately symmetric features.

Warning bands for moderate and severe skewness.

Transformation recommendations.

Leakage-related feature status.

Feature Stability integration for unstable drift.

ggrepel annotations and deterministic micro-jittering to reduce label collisions.

4. Single-Feature Radar Profile

type = "radar"

Assesses a selected feature across its statistical and validation dimensions.

<p align="center">
  <img src="man/figures/radar_profile.png" alt="PrismR Single-Feature Radar Profile" width="520">
</p>

The radar includes:

Completeness

Symmetry

Tail Normalcy

Uniqueness

Leakage Safety

Stability when Feature Stability is available

plot(
  report,
  type = "radar",
  feature = "Solar.R"
)

The radar automatically expands with a Stability axis when stability information is available for the selected feature.

Standalone Diagnostic Functions

Each PrismR module can also be used independently.

quality_score(data)

Evaluates:

Cell missingness

Duplicated rows

Duplicate columns

Zero-variance constant features

q <- quality_score(airquality)

q$quality_score
q$missing_percent
q$duplicate_rows
q$variables

detect_leakage(data, target = NULL)

Identifies:

ID/key columns

Duplicated columns

High-cardinality discrete columns

Exact target leakers

Near-perfect correlation leakage (|r| >= 0.999)

l <- detect_leakage(
  my_data,
  target = "outcome"
)

l$leakage_score
l$identifier_columns
l$target_leakage
l$correlation_leakage

recommend_transform(data)

Analyzes skewness and excess kurtosis and recommends appropriate transformations.

t <- recommend_transform(airquality)

t$variables[
  ,
  c(
    "variable",
    "skewness",
    "finding",
    "recommendation"
  )
]

Example:

Variable

Skewness

Finding

Recommendation

Ozone

1.21

Severely right-skewed

Box-Cox

Solar.R

-0.42

Approximately symmetric

None

Wind

0.34

Approximately symmetric

None

Temp

-0.37

Approximately symmetric

None

feature_stability(data, current = NULL, verbose = TRUE)

Evaluates feature distribution stability using:

Population Stability Index (PSI)

Wasserstein distance

Per-feature stability scores

Stable / Moderate Drift / Unstable classifications

stability <- feature_stability(
  airquality
)

stability$stability_score
stability$variables
stability$unstable_features

For explicit reference/current comparison:

stability <- feature_stability(
  reference_data,
  current = current_data
)

The verbose argument controls standalone output:

# Standalone diagnostic
feature_stability(
  airquality,
  verbose = TRUE
)

# Silent use inside prism()
feature_stability(
  airquality,
  verbose = FALSE
)

Model Readiness Scoring Logic

PrismR computes a weighted composite Readiness Score from the core readiness dimensions:

0.40 \times \text{Quality}
+
0.45 \times \text{Leakage}
+
0.15 \times \text{Transform Health}
$$

Feature Stability is reported as an additional validation dimension and is integrated into reporting and visualization.

Verdict

Score Thresholds

Action

Model Ready

Score ≥ 85 and Leakage ≥ 80

Proceed to feature engineering and modelling.

Proceed with Caution

Score ≥ 65 and Leakage ≥ 50

Inspect flagged issues before modelling.

Action Required

Score < 65 or Leakage < 50

Resolve severe data-quality or leakage issues.

Installation

# Install devtools once if required
# install.packages("devtools")

devtools::install_github("Arshit-dv/PrismR")

Running Unit Tests

PrismR includes a testthat suite for diagnostic pipelines, input validation, Feature Stability, and plotting functionality.

Run the complete test suite

testthat::test_dir("tests/testthat")

Run the Feature Stability tests only

testthat::test_file(
  "tests/testthat/test-feature_stability.R"
)

The Feature Stability tests cover:

Basic stability analysis

Deterministic partition behaviour

Stable feature detection

Moderate drift detection

Unstable drift detection

PSI calculation

Wasserstein distance

Insufficient-data handling

Non-numeric datasets

Reference/current dataset comparison

Input validation

Verbose and silent execution modes

Design Principles

Statistically Justified

Built on established statistical metrics including skewness, kurtosis, correlation thresholds, PSI, and Wasserstein distance.

Inspection Without Mutation

PrismR analyzes the dataset without modifying or transforming the raw data in place.

Modular

Each validation component can be used independently or as part of the complete prism() workflow.

Deterministic

Single-dataset Feature Stability analysis uses deterministic partitioning for reproducible results.

Integrated Visualization

Feature Stability results propagate into the summary, printed report, and supported diagnostic graphs.

Future-Proof

Visualizations dynamically incorporate stability information whenever Feature Stability analysis is available.

Authors & License

Authors: Arshit Choudhary and Vanshika Sharma

Repository: PrismR

License: MIT License (LICENSE.md)
