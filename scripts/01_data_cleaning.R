# ==============================================================================
# Data Cleaning Script - SHRS Program Health Analysis
# ==============================================================================
# This script demonstrates the data cleaning workflow for program health analysis
# 
# Supports two modes:
#   1. External data: Reads from secure locations via scripts/config/data_paths.R
#   2. Mock data: Uses simulated data via SHRS_USE_MOCK_DATA=1 environment variable
#
# Input: External data files OR mock data generator
# Output: Cleaned analytical datasets (saved to external location or memory)
# Last Updated: January 2026
# ==============================================================================

# ==============================================================================
# REQUIRED PACKAGES
# ==============================================================================
# Load required packages
library(tidyverse)
library(here)
library(haven)    # For reading Stata/SPSS files
library(readxl)   # For reading Excel files

# Set seed for reproducibility
set.seed(123)

# ==============================================================================
# LOAD DATA PATHS CONFIGURATION
# ==============================================================================

# Load the data paths loader
source(here("scripts", "config", "load_data_paths.R"))

# Load paths (will return mock mode flag if SHRS_USE_MOCK_DATA=1)
paths <- load_data_paths()

# ==============================================================================
# 1. IMPORT RAW DATA
# ==============================================================================

message("Step 1: Importing data...")

if (paths$use_mock) {
  # MOCK MODE: Generate simulated data
  message("  Using mock data for demonstration")
  source(here("scripts", "utils", "mock_data.R"))
  mock_data <- generate_mock_program_health_data()
  
  enrollment_raw <- mock_data$enrollment
  program_metadata <- mock_data$program_metadata
  financial_raw <- mock_data$financial
  
} else {
  # EXTERNAL DATA MODE: Read from secure locations
  message("  Loading from external data sources...")
  
  # Read enrollment data
  if (!is.null(paths$ENROLLMENT_DATA) && file.exists(paths$ENROLLMENT_DATA)) {
    enrollment_raw <- read_csv(paths$ENROLLMENT_DATA, show_col_types = FALSE)
    message("  ✓ Loaded enrollment data")
  } else {
    stop("Enrollment data file not found: ", paths$ENROLLMENT_DATA)
  }
  
  # Read program metadata
  if (!is.null(paths$PROGRAM_METADATA) && file.exists(paths$PROGRAM_METADATA)) {
    program_metadata <- read_csv(paths$PROGRAM_METADATA, show_col_types = FALSE)
    message("  ✓ Loaded program metadata")
  } else {
    # Create basic metadata from enrollment if not available
    program_metadata <- enrollment_raw %>%
      distinct(program_code) %>%
      mutate(
        program_name = program_code,
        department = "Unknown",
        degree_type = "Unknown"
      )
    message("  ⚠ Program metadata not found, using minimal metadata")
  }
  
  # Read financial data (if available)
  if (!is.null(paths$FINANCIAL_DATA) && file.exists(paths$FINANCIAL_DATA)) {
    if (grepl("\\.xlsx?$", paths$FINANCIAL_DATA)) {
      financial_raw <- read_excel(paths$FINANCIAL_DATA)
    } else {
      financial_raw <- read_csv(paths$FINANCIAL_DATA, show_col_types = FALSE)
    }
    message("  ✓ Loaded financial data")
  } else {
    financial_raw <- NULL
    message("  ⚠ Financial data not available")
  }
}

message("  - Raw enrollment dimensions: ", nrow(enrollment_raw), " rows x ", ncol(enrollment_raw), " columns")

# ==============================================================================
# 2. DATA CLEANING AND VALIDATION
# ==============================================================================

message("\nStep 2: Cleaning and validating data...")

cleaned_enrollment <- enrollment_raw %>%
  # Remove any duplicate records
  distinct() %>%
  
  # Filter to focus programs only (exclude "Other" if present)
  filter(!program_code %in% c("Other", "")) %>%
  
  # Ensure valid year range
  filter(academic_year >= 2018 & academic_year <= 2023) %>%
  
  # Calculate derived metrics if not already present
  mutate(
    # Acceptance rate (if acceptances available)
    acceptance_rate = if_else(
      !is.na(acceptances) & !is.na(applicants) & applicants > 0,
      acceptances / applicants,
      NA_real_
    ),
    
    # Yield rate
    yield_rate = if_else(
      !is.na(acceptances) & !is.na(enrolled) & acceptances > 0,
      enrolled / acceptances,
      NA_real_
    ),
    
    # Revenue per enrolled student
    revenue_per_student = if_else(
      !is.na(tuition_revenue) & !is.na(enrolled) & enrolled > 0,
      tuition_revenue / enrolled,
      if_else(!is.na(tuition_per_student), tuition_per_student, NA_real_)
    ),
    
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
# 4. SAVE PROCESSED DATA
# ==============================================================================

message("\nStep 4: Saving processed data...")

if (paths$use_mock) {
  # MOCK MODE: Save to memory/global environment for next script
  message("  Mock mode: Saving to global environment")
  assign("cleaned_enrollment_data", cleaned_enrollment, envir = .GlobalEnv)
  if (!is.null(financial_raw)) {
    assign("cleaned_financial_data", financial_raw, envir = .GlobalEnv)
  }
  if (!is.null(program_metadata)) {
    assign("program_metadata_data", program_metadata, envir = .GlobalEnv)
  }
  message("  ✓ Data saved to global environment for use in analysis scripts")
  
} else {
  # EXTERNAL DATA MODE: Save to external location
  message("  Saving to external processed data location...")
  
  if (!is.null(paths$PROCESSED_DATA_PATH)) {
    # Create directory if it doesn't exist
    if (!dir.exists(paths$PROCESSED_DATA_PATH)) {
      dir.create(paths$PROCESSED_DATA_PATH, recursive = TRUE)
      message("  Created directory: ", paths$PROCESSED_DATA_PATH)
    }
    
    # Save cleaned enrollment data
    saveRDS(cleaned_enrollment, 
            file.path(paths$PROCESSED_DATA_PATH, "cleaned_enrollment.rds"))
    write_csv(cleaned_enrollment, 
              file.path(paths$PROCESSED_DATA_PATH, "cleaned_enrollment.csv"))
    message("  ✓ Saved cleaned enrollment data")
    
    # Save financial data if available
    if (!is.null(financial_raw)) {
      saveRDS(financial_raw, 
              file.path(paths$PROCESSED_DATA_PATH, "cleaned_financial.rds"))
      message("  ✓ Saved cleaned financial data")
    }
    
    # Save program metadata
    if (!is.null(program_metadata)) {
      saveRDS(program_metadata,
              file.path(paths$PROCESSED_DATA_PATH, "program_metadata.rds"))
      message("  ✓ Saved program metadata")
    }
    
  } else {
    warning("PROCESSED_DATA_PATH not configured, data not saved to disk")
  }
}

# ==============================================================================
# SCRIPT COMPLETE
# ==============================================================================

message("\n=== Data cleaning workflow complete! ===")
if (paths$use_mock) {
  message("REMINDER: Using mock data for demonstration")
  message("To use real data: configure scripts/config/data_paths.R")
} else {
  message("REMINDER: All data files stored in external, secure locations")
}
message("Next step: Run analysis/01_exploratory_analysis.R")
