# ==============================================================================
# Data Paths Configuration Template
# ==============================================================================
# This is an EXAMPLE configuration file. To use external data:
#
# 1. Copy this file to: scripts/config/data_paths.R
# 2. Edit data_paths.R with your actual secure data paths
# 3. DO NOT commit data_paths.R (it is in .gitignore)
#
# IMPORTANT: All data must be stored in secure, external locations that comply
# with institutional data governance policies and FERPA requirements.
# ==============================================================================

# Root directory for all SHRS analysis data
# CUSTOMIZE THIS: Replace with your actual secure data storage location
# Examples:
#   Windows: "C:/Users/YourName/SecureData/SHRS"
#   Mac/Linux: "~/SecureData/SHRS"
#   Network: "//network-share/secure/SHRS"
DATA_ROOT <- "/path/to/your/secure/data/folder"

# Data subdirectories
RAW_DATA_PATH <- file.path(DATA_ROOT, "raw")
PROCESSED_DATA_PATH <- file.path(DATA_ROOT, "processed")
ARCHIVE_PATH <- file.path(DATA_ROOT, "archive")

# ==============================================================================
# Specific Data File Paths
# ==============================================================================
# Define paths to each required data file.
# Adjust filenames to match your actual data files.

# Enrollment data (by program, year, cohort)
ENROLLMENT_DATA <- file.path(RAW_DATA_PATH, "enrollment_data.csv")

# Program metadata (program names, departments, degree types)
PROGRAM_METADATA <- file.path(RAW_DATA_PATH, "program_metadata.csv")

# Financial data (revenue, costs by program and year)
FINANCIAL_DATA <- file.path(RAW_DATA_PATH, "financial_data.xlsx")

# Student outcomes data (graduation, employment, licensure)
STUDENT_OUTCOMES_DATA <- file.path(RAW_DATA_PATH, "student_outcomes.csv")

# Faculty and resources data
FACULTY_DATA <- file.path(RAW_DATA_PATH, "faculty_data.csv")

# Admissions funnel data (applicants, acceptances, enrollments)
ADMISSIONS_DATA <- file.path(RAW_DATA_PATH, "admissions_data.csv")

# Retention and persistence data
RETENTION_DATA <- file.path(RAW_DATA_PATH, "retention_data.csv")

# Licensure exam results
LICENSURE_DATA <- file.path(RAW_DATA_PATH, "licensure_exam_results.csv")

# Student survey data (satisfaction, reasons for attrition)
SURVEY_DATA <- file.path(RAW_DATA_PATH, "student_survey_data.csv")

# Alumni employment outcomes
ALUMNI_DATA <- file.path(RAW_DATA_PATH, "alumni_employment.csv")

# ==============================================================================
# Usage Notes
# ==============================================================================
# After customizing this file and saving as data_paths.R, the analysis scripts
# will automatically load these paths and use them to access your data.
#
# To test your configuration:
#   source("scripts/config/data_paths.R")
#   print(DATA_ROOT)
#   dir.exists(DATA_ROOT)  # Should return TRUE if path is correct
# ==============================================================================
