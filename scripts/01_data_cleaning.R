# ==============================================================================
# Data Cleaning Script
# ==============================================================================
# This script imports and cleans raw data files
# Input: data/raw/[your-raw-data-file]
# Output: data/processed/cleaned_data.rds
# Last Updated: January 2026
# ==============================================================================

# Load required packages
library(tidyverse)
library(here)
library(haven)    # For reading Stata/SPSS files
library(readxl)   # For reading Excel files

# Set seed for reproducibility (if using any random processes)
set.seed(123)

# ==============================================================================
# 1. IMPORT RAW DATA
# ==============================================================================

message("Step 1: Importing raw data...")

# Example: Reading CSV file
# raw_data <- read_csv(here("data", "raw", "your_data_file.csv"))

# Example: Reading Stata file
# raw_data <- read_dta(here("data", "raw", "your_data_file.dta"))

# Example: Reading Excel file
# raw_data <- read_excel(here("data", "raw", "your_data_file.xlsx"))

# For demonstration purposes, create a sample dataset
# REPLACE THIS with your actual data import code
raw_data <- tibble(
  id = 1:100,
  year = sample(2015:2020, 100, replace = TRUE),
  treatment = sample(c(0, 1), 100, replace = TRUE),
  outcome = rnorm(100, mean = 50, sd = 10),
  covariate1 = rnorm(100, mean = 0, sd = 1),
  covariate2 = sample(c("A", "B", "C"), 100, replace = TRUE),
  missing_var = ifelse(runif(100) < 0.1, NA, rnorm(100))
)

message("  - Raw data dimensions: ", nrow(raw_data), " rows x ", ncol(raw_data), " columns")

# ==============================================================================
# 2. DATA CLEANING
# ==============================================================================

message("\nStep 2: Cleaning data...")

cleaned_data <- raw_data %>%
  # Remove duplicates based on ID
  distinct(id, .keep_all = TRUE) %>%
  
  # Handle missing values
  # Option 1: Drop rows with any missing values
  # drop_na() %>%
  
  # Option 2: Drop rows with missing values in specific columns
  drop_na(outcome) %>%
  
  # Filter out invalid observations
  filter(
    year >= 2015 & year <= 2020,  # Keep only valid years
    !is.na(id)                      # Ensure ID is not missing
  ) %>%
  
  # Recode variables
  mutate(
    # Convert treatment to factor
    treatment_status = factor(
      treatment,
      levels = c(0, 1),
      labels = c("Control", "Treatment")
    ),
    
    # Create categorical variable
    covariate2_factor = factor(covariate2),
    
    # Create new variables
    outcome_log = log(outcome + 1),  # Log transformation
    
    # Standardize continuous variables
    covariate1_std = scale(covariate1)[, 1]
  ) %>%
  
  # Arrange data
  arrange(id, year)

message("  - Cleaned data dimensions: ", nrow(cleaned_data), " rows x ", ncol(cleaned_data), " columns")
message("  - Observations removed: ", nrow(raw_data) - nrow(cleaned_data))

# ==============================================================================
# 3. DATA VALIDATION
# ==============================================================================

message("\nStep 3: Validating cleaned data...")

# Check for duplicates
if (any(duplicated(cleaned_data$id))) {
  warning("Duplicate IDs found in cleaned data!")
} else {
  message("  ✓ No duplicate IDs")
}

# Check for missing values in key variables
key_vars <- c("id", "year", "outcome", "treatment")
missing_counts <- cleaned_data %>%
  select(all_of(key_vars)) %>%
  summarise(across(everything(), ~sum(is.na(.))))

if (any(missing_counts > 0)) {
  warning("Missing values found in key variables:")
  print(missing_counts)
} else {
  message("  ✓ No missing values in key variables")
}

# Summary statistics
message("\nSummary statistics:")
print(summary(cleaned_data %>% select(outcome, covariate1, treatment)))

# ==============================================================================
# 4. SAVE PROCESSED DATA
# ==============================================================================

message("\nStep 4: Saving processed data...")

# Save as RDS (recommended for R objects, preserves data types)
saveRDS(cleaned_data, here("data", "processed", "cleaned_data.rds"))
message("  ✓ Saved as RDS: data/processed/cleaned_data.rds")

# Optionally save as CSV for compatibility with other software
write_csv(cleaned_data, here("data", "processed", "cleaned_data.csv"))
message("  ✓ Saved as CSV: data/processed/cleaned_data.csv")

# ==============================================================================
# SCRIPT COMPLETE
# ==============================================================================

message("\n=== Data cleaning complete! ===")
message("Next step: Run scripts/02_data_processing.R")
