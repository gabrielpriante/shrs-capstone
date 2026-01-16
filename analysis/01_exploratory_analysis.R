# ==============================================================================
# Main Analysis Script
# ==============================================================================
# This script performs the primary econometric analysis
# Input: data/processed/cleaned_data.rds
# Output: output/regression_results.txt, output/figures/
# Last Updated: January 2026
# ==============================================================================

# Load required packages
library(tidyverse)   # Includes ggplot2, dplyr, tidyr, readr, etc.
library(here)
library(fixest)      # For fixed-effects estimation
library(modelsummary) # For regression tables

# Set seed for reproducibility
set.seed(123)

# ==============================================================================
# 1. LOAD PROCESSED DATA
# ==============================================================================

message("Loading processed data...")
analysis_data <- readRDS(here("data", "processed", "cleaned_data.rds"))

message("  - Analysis sample: ", nrow(analysis_data), " observations")

# ==============================================================================
# 2. DESCRIPTIVE STATISTICS
# ==============================================================================

message("\nGenerating descriptive statistics...")

# Summary statistics table
desc_stats <- analysis_data %>%
  select(outcome, covariate1, treatment) %>%
  summarise(
    across(
      everything(),
      list(
        Mean = ~mean(., na.rm = TRUE),
        SD = ~sd(., na.rm = TRUE),
        Min = ~min(., na.rm = TRUE),
        Max = ~max(., na.rm = TRUE),
        N = ~sum(!is.na(.))
      ),
      .names = "{.col}_{.fn}"
    )
  )

print(desc_stats)

# ==============================================================================
# 3. VISUALIZATION
# ==============================================================================

message("\nCreating visualizations...")

# Create output/figures directory if it doesn't exist
dir.create(here("output", "figures"), recursive = TRUE, showWarnings = FALSE)

# Plot 1: Distribution of outcome variable
p1 <- ggplot(analysis_data, aes(x = outcome)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  theme_minimal() +
  labs(
    title = "Distribution of Outcome Variable",
    x = "Outcome",
    y = "Frequency"
  )

ggsave(
  here("output", "figures", "outcome_distribution.png"),
  plot = p1,
  width = 8,
  height = 6,
  dpi = 300
)

# Plot 2: Outcome by treatment status
p2 <- ggplot(analysis_data, aes(x = treatment_status, y = outcome, fill = treatment_status)) +
  geom_boxplot(alpha = 0.7) +
  theme_minimal() +
  scale_fill_manual(values = c("Control" = "grey70", "Treatment" = "steelblue")) +
  labs(
    title = "Outcome by Treatment Status",
    x = "Treatment Status",
    y = "Outcome",
    fill = "Group"
  ) +
  theme(legend.position = "none")

ggsave(
  here("output", "figures", "outcome_by_treatment.png"),
  plot = p2,
  width = 8,
  height = 6,
  dpi = 300
)

message("  ✓ Figures saved to output/figures/")

# ==============================================================================
# 4. REGRESSION ANALYSIS
# ==============================================================================

message("\nRunning regression analysis...")

# Model 1: Simple regression (treatment effect only)
model1 <- feols(outcome ~ treatment, data = analysis_data)

# Model 2: Add control variables
model2 <- feols(outcome ~ treatment + covariate1, data = analysis_data)

# Model 3: Add year fixed effects
model3 <- feols(outcome ~ treatment + covariate1 | year, data = analysis_data)

# Model 4: Interaction term
model4 <- feols(outcome ~ treatment * covariate1 | year, data = analysis_data)

# Display results
print(summary(model1))
print(summary(model2))
print(summary(model3))
print(summary(model4))

# ==============================================================================
# 5. CREATE REGRESSION TABLE
# ==============================================================================

message("\nCreating regression table...")

# Create directory for tables
dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)

# Generate regression table
modelsummary(
  list(
    "(1)" = model1,
    "(2)" = model2,
    "(3)" = model3,
    "(4)" = model4
  ),
  output = here("output", "tables", "regression_results.html"),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  title = "Treatment Effect on Outcome: Main Results",
  notes = "Standard errors in parentheses. * p < 0.1, ** p < 0.05, *** p < 0.01"
)

# Also save as text file
modelsummary(
  list(
    "(1)" = model1,
    "(2)" = model2,
    "(3)" = model3,
    "(4)" = model4
  ),
  output = here("output", "tables", "regression_results.txt"),
  stars = c('*' = 0.1, '**' = 0.05, '***' = 0.01)
)

message("  ✓ Tables saved to output/tables/")

# ==============================================================================
# 6. EXPORT KEY RESULTS
# ==============================================================================

message("\nExporting key results...")

# Extract treatment effect from preferred model (model 3)
treatment_effect <- coef(model3)["treatment"]
se_treatment <- se(model3)["treatment"]

# Create results summary
results_summary <- tibble(
  Model = "Treatment Effect (Year FE)",
  Coefficient = treatment_effect,
  SE = se_treatment,
  `CI Lower` = treatment_effect - 1.96 * se_treatment,
  `CI Upper` = treatment_effect + 1.96 * se_treatment,
  N = nobs(model3)
)

print(results_summary)

# Save results summary
saveRDS(results_summary, here("output", "results_summary.rds"))
write_csv(results_summary, here("output", "results_summary.csv"))

# ==============================================================================
# SCRIPT COMPLETE
# ==============================================================================

message("\n=== Main analysis complete! ===")
message("Key outputs:")
message("  - Figures: output/figures/")
message("  - Tables: output/tables/")
message("  - Results summary: output/results_summary.csv")
message("\nNext step: Review results and run robustness checks")
