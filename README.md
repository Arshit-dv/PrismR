# PrismR

> **A statistical validation framework for evaluating dataset readiness before predictive modelling.**

PrismR is an open-source R package that introduces the concept of **Model Readiness**—a structured statistical assessment of whether a dataset is suitable for predictive modelling before any machine learning algorithm is trained.

Unlike traditional machine learning libraries that focus on model performance, PrismR focuses on **dataset readiness** by analysing data quality, leakage risk and feature characteristics before model development begins.

---

# Why PrismR?

In a typical machine learning workflow, considerable effort is spent on feature engineering and model tuning, yet there is rarely a systematic assessment of whether the dataset itself is ready for modelling.

PrismR introduces a dedicated **Statistical Validation Layer** between data preprocessing and model training.

Traditional workflow

```text
Raw Data
   │
Cleaning
   │
Feature Engineering
   │
Model Training
```

PrismR workflow

```text
Raw Data
   │
Cleaning
   │
──────────────────────────────
 Statistical Validation Layer
          (PrismR)
──────────────────────────────
   │
Feature Engineering
   │
Model Training
```

This additional validation stage helps identify potential issues before they negatively affect downstream models.

---

# Why the name "PrismR"?

A physical prism does not create new information—it separates light into its hidden components.

PrismR follows the same philosophy.

Rather than altering a dataset, it reveals statistical characteristics that are often hidden until model training.

```text
                Dataset
                   │
                   ▼
               PrismR
                   │
    ┌──────────────────────────────┐
    │ Data Quality                 │
    │ Leakage Detection            │
    │ Transformation Analysis      │
    │ Feature Stability            │
    │ Model Readiness              │
    └──────────────────────────────┘
```

PrismR acts as a **statistical prism**, exposing the properties of a dataset before predictive modelling begins.

---

# Features

Current Version

- ✔ Data Quality Assessment
- ✔ Leakage Detection
- ✔ Transformation Recommendation
- 🚧 Feature Stability (under development)

---

## Data Quality Assessment

Evaluates

- Missing values
- Duplicate rows
- Constant columns
- Duplicate columns
- Overall Data Quality Score

---

## Leakage Detection

Detects

- Identifier columns
- Duplicate columns
- High-cardinality features
- Target leakage
- Correlation leakage
- Leakage Safety Score

---

## Transformation Analysis

Analyses numeric variables using

- Skewness
- Excess kurtosis

and recommends

- None
- Log
- Box–Cox
- Yeo–Johnson

---

# Installation

```r
# install.packages("devtools")

devtools::install_github("YOUR_GITHUB_USERNAME/PrismR")
```

---

# Quick Start

```r
library(PrismR)

report <- prism(
  airquality
)

print(report)

summary(report)
```

or with a target variable

```r
report <- prism(
  data = my_data,
  target = "Outcome"
)
```

---

# Main Functions

| Function | Description |
|----------|-------------|
| `prism()` | Perform a complete Prism Analysis |
| `quality_score()` | Assess dataset quality |
| `detect_leakage()` | Detect potential data leakage |
| `recommend_transform()` | Recommend feature transformations |
| `feature_stability()` | Assess feature stability *(under development)* |

---

# Output

`prism()` returns a **PrismReport** S3 object.

Supported methods

```r
print(report)

summary(report)

plot(report)   # Coming soon
```

---

# Design Principles

PrismR is designed to

- Introduce a dedicated statistical validation layer
- Focus on datasets rather than predictive models
- Produce statistically justified recommendations
- Follow CRAN package conventions
- Remain modular and extensible
- Provide reproducible analyses through S3 objects

---


# Contributing

Contributions, bug reports and feature requests are welcome.

If you discover an issue or have suggestions for improving PrismR, please open an issue or submit a pull request.

---

# License

MIT License

---

# Citation

If you use PrismR in academic work, please cite the package.

(Citation information will be added after the first public release.)
