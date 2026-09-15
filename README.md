# PrismR

> **A Statistical Validation Framework for Evaluating Dataset Readiness Before Predictive Modelling.**

PrismR is an open-source R package that introduces the concept of **Model Readiness**—a structured statistical assessment of whether tabular data is truly suitable for predictive modelling before any machine learning algorithm is trained.

Rather than tuning hyperparameters on compromised data, PrismR introduces a dedicated **Statistical Validation Layer** between preprocessing and model training.

---

## Why PrismR?

In traditional machine learning pipelines, vast effort is invested in model architectures and tuning, yet data quality, leakage risks, distributional anomalies, and feature drift often remain undetected until model performance degrades in production.

```text
Traditional Workflow:
Raw Data ──► Cleaning ──► Feature Engineering ──► Model Training
                              ▲
                              └── [Silent issues discovered too late]

PrismR Workflow:
Raw Data ──► Cleaning ──► ┌──────────────────────────────┐
                          │  Statistical Validation      │ ◄── PrismR
                          │  Layer (Model Readiness)     │
                          └──────────────┬───────────────┘
                                         │
                          Feature Engineering ──► Model Training
The "Prism" Philosophy
A physical prism does not create new light—it separates white light into its hidden spectral components. Similarly, PrismR does not mutate or alter your dataset; it refracts tabular data to reveal latent quality deficiencies, leakage channels, mathematical transformation requirements, and feature distribution drift.
                   Tabular Dataset
                         │
                         ▼
                      [ PrismR ]
                         │
        ┌────────────────┼──────────────────┐
        ▼                ▼                  ▼
  Data Quality    Leakage Safety    Transformation    Feature Stability
  (Missing/Dups)  (Collinear/IDs)   (Skew/Kurtosis)    (Drift/PSI)
        └────────────────┬──────────────────┘
                         ▼
               Overall Model Readiness
Quick Start
Run a complete Model Readiness inspection in just three lines of R:
library(PrismR)

# Run full validation with an optional target column
report <- prism(airquality, target = "Ozone")

# View the complete diagnostic report
print(report)
High-Level Summary: summary(report)
The summary() method provides a concise overview of the major validation dimensions, including Feature Stability.
========================================================
                    Prism Summary
========================================================

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
Detailed Diagnostic Audit: print(report)
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
The module uses:

Population Stability Index (PSI) as the primary drift metric.
Wasserstein distance as a supporting distribution-distance metric.
Per-feature stability scores.
Automatic classification into:
Stable
Moderate Drift
Unstable
Feature Stability can be used with either an explicitly supplied current dataset or, when only one dataset is supplied, a deterministic internal partition of the data.
Feature Stability Function
feature_stability(data, current = NULL, verbose = TRUE)
The function evaluates the distributional stability of numeric features.
# Standalone feature stability assessment
stability <- feature_stability(airquality)

# Access the overall stability score
stability$stability_score

# Access per-feature stability results
stability$variables

# Access unstable features
stability$unstable_features
Reference vs. Current Dataset
For production-style drift analysis, a reference dataset and current dataset can be supplied separately:
stability <- feature_stability(
  reference_data,
  current = current_data
)
Both datasets must contain compatible feature columns.
When current is not supplied, PrismR creates a deterministic partition of the supplied dataset so that the two portions can be compared reproducibly.

Stability Metrics
Population Stability Index (PSI)
PSI is the primary metric used to classify feature distribution drift.
PSI Range	Classification	Stability Score
< 0.10	Stable	100
0.10 – < 0.25	Moderate Drift	70
>= 0.25	Unstable	30
A lower PSI indicates that the current distribution is closer to the reference distribution.
Wasserstein Distance
Wasserstein distance provides an additional measure of how far two feature distributions are from each other.
Because Wasserstein distance depends on the scale of the feature, PrismR uses it as a supporting metric rather than the primary classification criterion.

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
The stability analysis is performed silently as part of the pipeline and its results are stored inside the returned PrismReport object.
report$stability
Example structure:
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
This allows the same Feature Stability results to be reused by:
summary(report)
print(report)
plot(report, type = "radial")
plot(report, type = "circular")
plot(report, type = "bubble")
plot(report, type = "radar")
Visual Diagnostic Suite: plot(report)
PrismR features a publication-ready diagnostic visualization suite built on ggplot2.
# 1. Macro Dataset Health Gauge
plot(report, type = "radial")

# 2. Feature Diagnostic Rose
plot(report, type = "circular")

# 3. Statistical Feature Map
plot(report, type = "bubble")

# 4. Single-Feature Spider Radar Profile
plot(report, type = "radar", feature = "Solar.R")
1. Macro Dataset Health Gauge (type = "radial")
Tracks overall composite readiness alongside individual validation scores.
The visualization dynamically incorporates Feature Stability whenever stability analysis is available.

<p align="center"> <img src="man/figures/radial_gauge.png" alt="Macro Dataset Health Gauge" width="520px" /> </p>
Outer Ring: Overall Model Readiness Score.
Data Quality Ring: Data Quality Score.
Leakage Ring: Leakage Safety Score.
Transformation Ring: Transformation Health Score.
Dynamic Stability Ring: Automatically adds a Feature Stability track when stability analysis is available.
2. Feature Diagnostic Rose (type = "circular")
A Florence Nightingale coxcomb visualization mapping feature-level diagnostic metrics around an open donut core.
<p align="center"> <img src="man/figures/circular_rose.png" alt="Feature Diagnostic Rose" width="560px" /> </p>
Petal Length: Feature Completeness (100% - Missing%).
Petal Color: Feature Integrity & Leakage Vector:
🟩 Clean Feature
🟦 Identifier / High-Cardinality
🟧 Duplicate / Constant Feature
🟪 Unstable Distribution Drift
🟥 Target Leaker
Unstable Distribution Drift is automatically activated when the feature's stability score falls below the instability threshold used by the visualization.
Outer Rim Cap: Exact mathematical transformation recommended (None, Log, Box-Cox, Yeo-Johnson, Categorical).
Visual Color Swatches: Direct graphical legend entries for immediate interpretation.
3. Statistical Feature Map (type = "bubble")
Resolves feature distribution properties on a 2D coordinate plane:
Feature Completeness on the X-axis.
Distribution Skewness on the Y-axis.
<p align="center"> <img src="man/figures/bubble_map.png" alt="Statistical Feature Map" width="680px" /> </p>
Green Central Zone: Marks the statistically symmetric boundary [-0.5, 0.5] where no transformation is needed.
Warning Bands: Highlight moderate skew ([0.5, 1.0] and [-1.0, -0.5]) and severe skew (> 1.0 or < -1.0).
Point Aesthetics: Point colors reflect leakage risk; point shapes reflect the recommended mathematical transformation.
Stability Integration: Features with sufficiently low stability scores are visually identified as unstable drift.
Zero Collision: Powered by ggrepel leader lines and deterministic micro-jittering.
4. Single-Feature Radar Profile (type = "radar", feature = "col")
A spider radar chart assessing an individual feature across its statistical and validation dimensions.
<p align="center"> <img src="man/figures/radar_profile.png" alt="Feature Radar Profile" width="520px" /> </p>
The radar profile includes:

Completeness: 100% - Missing%
Symmetry: Based on absolute skewness.
Tail Normalcy: Based on absolute excess kurtosis.
Uniqueness: Non-redundant unique value density.
Leakage Safety: Feature-level leakage penalty score.
Stability: Automatically added when Feature Stability data is available for the selected feature.
plot(
  report,
  type = "radar",
  feature = "Solar.R"
)
Dashed Green Benchmark: 80% readiness boundary.
Dynamic Stability Spoke: Automatically expands the radar with a Stability axis when Feature Stability is available.
Standalone Diagnostic Functions
Each PrismR module can also be called as an independent diagnostic function.
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
Analyzes skewness and excess kurtosis using type-2 moments via e1071 and accounts for strictly positive constraints.
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
Variable	Skewness	Finding	Recommendation
Ozone	1.21	Severely right-skewed	Box-Cox
Solar.R	-0.42	Approximately symmetric	None
Wind	0.34	Approximately symmetric	None
Temp	-0.37	Approximately symmetric	None
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
For reference/current distribution comparison:
stability <- feature_stability(
  reference_data,
  current = current_data
)
The function supports a verbose argument so that it can be used either as a standalone diagnostic or silently inside the complete prism() workflow:
# Standalone diagnostic
feature_stability(
  airquality,
  verbose = TRUE
)

# Silent integration inside a larger pipeline
feature_stability(
  airquality,
  verbose = FALSE
)
Model Readiness Scoring Logic
PrismR computes a weighted composite Readiness Score (0 - 100):
$$ \text{Readiness Score} = 0.40 \times \text{Quality} + 0.45 \times \text{Leakage} + 0.15 \times \text{Transform Health} $$
Feature Stability is reported as an additional validation dimension and is integrated into the diagnostic and visualization layers.

Verdict	Score Thresholds	Action
Model Ready	Score ≥ 85 and Leakage ≥ 80	Proceed directly to feature engineering and modelling.
Proceed with Caution	Score ≥ 65 and Leakage ≥ 50	Inspect flagged items (outliers, skewness, moderate leakage).
Action Required	Score < 65 or Leakage < 50	Resolve severe issues (target leakers, constant features, heavy missingness).
Installation
# install.packages("devtools")

devtools::install_github(
  "Arshit-dv/PrismR"
)
Running Unit Tests
PrismR includes a comprehensive testthat suite verifying diagnostic pipelines, error guards, Feature Stability functionality, and plotting methods.
# Run the complete test suite
testthat::test_dir("tests/testthat")
Feature Stability can also be tested independently:
testthat::test_file(
  "tests/testthat/test-feature_stability.R"
)
The test suite covers:
Basic Feature Stability analysis
Deterministic partition behaviour
Stable feature detection
Moderate drift detection
Unstable drift detection
PSI calculation
Wasserstein distance
Missing / insufficient data handling
Non-numeric datasets
Reference/current dataset comparison
Input validation
Verbose and silent execution modes
Design Principles
Statistically Justified: Built on established statistical metrics including excess kurtosis, skewness, correlation thresholds, PSI, and Wasserstein distance.
Inspection Without Mutation: Never modifies or transforms your raw data in place.
CRAN-Compliant & Modular: Follows R package standards, clean S3 method dispatches, and decoupled functions.
Deterministic Analysis: Single-dataset Feature Stability analysis uses deterministic partitioning for reproducible results.
Modular Diagnostics: Each validation component can operate independently or as part of the complete prism() workflow.
Integrated Visualization: Stability results automatically propagate into summary reports and supported visual diagnostics.
Automated Future-Proofing: Visualizations automatically incorporate stability metrics whenever Feature Stability analysis is available.
Authors & License
Author: Arshit Choudhary and Vanshika Sharma(@Arshit-dv)
License: MIT License (LICENSE.md)

This version reflects the Feature Stability work you just merged: it is no longer described as under development, and the README documents its **PSI/Wasserstein metrics, thresholds, `verbose` behavior, `prism()` integration, summary/print integration, and all four graph integrations**. :contentReference[oaicite:0]{index=0}
