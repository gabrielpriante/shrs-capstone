# ==============================================================================
# Data Cleaning Script - SHRS Program Health Analysis
# ==============================================================================
# This script demonstrates the data cleaning workflow for program health analysis
# 
# IMPORTANT: This script contains PLACEHOLDER PATHS to external data sources
# You must create scripts/config/data_paths.R locally (not tracked in Git)
# to define actual paths to your secure data locations
#
# Input: External data files (enrollment, financial, student outcomes, etc.)
# Output: Cleaned analytical datasets (saved to external location)
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
# LOAD EXTERNAL DATA CONFIGURATION
# ==============================================================================

# Check if data paths configuration exists
config_file <- here("scripts", "config", "data_paths.R")

if (file.exists(config_file)) {
  source(config_file)
  message("Loaded data paths from configuration file")
} else {
  stop(
    "\n*** DATA CONFIGURATION REQUIRED ***\n",
    "Create the file: scripts/config/data_paths.R\n",
    "This file should define paths to your external data sources.\n\n",
    "Example contents:\n",
    "  DATA_ROOT <- 'C:/SecureData/SHRS_Analysis'\n",
    "  RAW_DATA_PATH <- file.path(DATA_ROOT, 'raw')\n",
    "  PROCESSED_DATA_PATH <- file.path(DATA_ROOT, 'processed')\n",
    "  ENROLLMENT_DATA <- file.path(RAW_DATA_PATH, 'enrollment.csv')\n",
    "  FINANCIAL_DATA <- file.path(RAW_DATA_PATH, 'financial.xlsx')\n\n",
    "See README.md for more details.\n",
    "*** This file should NOT be committed to Git ***\n"
  )
}

# ==============================================================================
# 1. IMPORT RAW DATA FROM EXTERNAL SOURCES
# ==============================================================================

message("Step 1: Importing data from external sources...")

# PLACEHOLDER: Example data import code
# Replace these with actual paths from your data_paths.R configuration
#
# Examples of data sources for SHRS Program Health Analysis:
#
# 1. Enrollment data by program and year
# enrollment_raw <- read_csv(ENROLLMENT_DATA)
#
# 2. Financial data (revenue, costs by program)
# financial_raw <- read_excel(FINANCIAL_DATA, sheet = "Program_Finances")
#
# 3. Student outcomes (licensure pass rates, employment)
# outcomes_raw <- read_csv(STUDENT_OUTCOMES_DATA)
#
# 4. Faculty and resource data
# faculty_raw <- read_csv(FACULTY_DATA)
#
# 5. Applicant and admissions data
# admissions_raw <- read_csv(ADMISSIONS_DATA)

# For demonstration: create placeholder structure showing expected data
# REMOVE THIS when working with actual data
message("  NOTE: Using placeholder data structure for demonstration")
message("  Replace with actual data import code when configured")

enrollment_raw <- tibble(
  academic_year = rep(2018:2023, each = 8),
  program_code = rep(c("SLP", "AuD", "CSD_UG", "AT", "DN", "SS", "SMN_UG", "Other"), 6),
  applicants = sample(20:150, 48, replace = TRUE),
  acceptances = NA_integer_,
  enrolled = sample(10:80, 48, replace = TRUE),
  tuition_revenue = sample(100000:800000, 48, replace = TRUE)
)

message("  - Raw data dimensions: ", nrow(enrollment_raw), " rows x ", ncol(enrollment_raw), " columns")

# ==============================================================================
# 2. DATA CLEANING AND VALIDATION
# ==============================================================================

message("\nStep 2: Cleaning and validating data...")

cleaned_enrollment <- enrollment_raw %>%
  # Remove any duplicate records
  distinct() %>%
  
  # Filter to focus programs only (exclude "Other")
  filter(program_code != "Other") %>%
  
  # Ensure valid year range
  filter(academic_year >= 2018 & academic_year <= 2023) %>%
  
  # Calculate derived metrics
  mutate(
    # Acceptance rate (if acceptances available)
    acceptance_rate = if_else(!is.na(acceptances) & applicants > 0,
                             acceptances / applicants,
                             NA_real_),
    
    # Yield rate
    yield_rate = if_else(!is.na(acceptances) & acceptances > 0,
                        enrolled / acceptances,
                        NA_real_),
    
    # Revenue per enrolled student
    revenue_per_student = if_else(enrolled > 0,
                                  tuition_revenue / enrolled,
                                  NA_real_),
    
    # Program category grouping
    program_category = case_when(
      program_code %in% c("SLP", "AuD", "CSD_UG") ~ "Communication Science & Disorders",
      program_code %in% c("AT", "DN", "SS", "SMN_UG") ~ "Sports Medicine & Nutrition",
      TRUE ~ "Other"
    )
  ) %>%
  
  # Arrange by program and year
  arrange(program_category, program_code, academic_year)

message("  - Cleaned data dimensions: ", nrow(cleaned_enrollment), " rows x ", ncol(cleaned_enrollment), " columns")
message("  - Observations removed: ", nrow(enrollment_raw) - nrow(cleaned_enrollment))

# ==============================================================================
# 3. DATA VALIDATION CHECKS
# ==============================================================================

message("\nStep 3: Validating cleaned data...")

# Check for expected programs
expected_programs <- c("SLP", "AuD", "CSD_UG", "AT", "DN", "SS", "SMN_UG")
missing_programs <- setdiff(expected_programs, unique(cleaned_enrollment$program_code))

if (length(missing_programs) > 0) {
  warning("Missing expected programs: ", paste(missing_programs, collapse = ", "))
} else {
  message("  ✓ All expected programs present")
}

# Check for missing values in key variables
key_vars <- c("academic_year", "program_code", "enrolled", "tuition_revenue")
missing_counts <- cleaned_enrollment %>%
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
print(summary(cleaned_enrollment %>% 
              select(academic_year, enrolled, tuition_revenue, revenue_per_student)))

# ==============================================================================
# 4. SAVE PROCESSED DATA TO EXTERNAL LOCATION
# ==============================================================================

message("\nStep 4: Saving processed data to external location...")

# IMPORTANT: Save to external location, NOT in repository
# Use paths from your data_paths.R configuration

# Example: Save cleaned enrollment data
# saveRDS(cleaned_enrollment, 
#         file.path(PROCESSED_DATA_PATH, "cleaned_enrollment.rds"))
# write_csv(cleaned_enrollment, 
#          file.path(PROCESSED_DATA_PATH, "cleaned_enrollment.csv"))

# For demonstration only (remove when using actual external storage):
message("  NOTE: In actual use, save to external PROCESSED_DATA_PATH")
message("  Example: saveRDS(data, file.path(PROCESSED_DATA_PATH, 'cleaned_enrollment.rds'))")

# ==============================================================================
# SCRIPT COMPLETE
# ==============================================================================

message("\n=== Data cleaning workflow complete! ===")
message("REMINDER: All data files should be stored in external, secure locations")
message("Next step: Run analysis/01_exploratory_analysis.R")
