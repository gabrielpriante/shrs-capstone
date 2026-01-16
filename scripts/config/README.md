# Data Configuration Directory

## Purpose

This directory is for **local configuration files** that define paths to external data sources. These configuration files are **NOT tracked in Git** for security and privacy reasons.

## Required Configuration File

Create a file named `data_paths.R` in this directory with the following structure:

```r
# ==============================================================================
# Data Paths Configuration
# ==============================================================================
# This file defines paths to external data sources for the SHRS Program Health
# analysis. This file should NOT be committed to Git.
#
# IMPORTANT: All data must be stored in secure, external locations that comply
# with institutional data governance policies and FERPA requirements.
# ==============================================================================

# Root directory for all SHRS analysis data
# Customize this to point to your secure data storage location
DATA_ROOT <- "C:/SecureData/SHRS_Analysis"  # Windows example
# DATA_ROOT <- "/secure/data/SHRS_Analysis"  # Unix/Mac example
# DATA_ROOT <- "\\\\network\\share\\SHRS_Analysis"  # Network drive example

# Data subdirectories
RAW_DATA_PATH <- file.path(DATA_ROOT, "raw")
PROCESSED_DATA_PATH <- file.path(DATA_ROOT, "processed")
ARCHIVE_PATH <- file.path(DATA_ROOT, "archive")

# Specific data file paths
# Enrollment data
ENROLLMENT_DATA <- file.path(RAW_DATA_PATH, "enrollment_data.csv")

# Financial data
FINANCIAL_DATA <- file.path(RAW_DATA_PATH, "financial_data.xlsx")

# Student outcomes data
STUDENT_OUTCOMES_DATA <- file.path(RAW_DATA_PATH, "student_outcomes.csv")

# Faculty and resources data
FACULTY_DATA <- file.path(RAW_DATA_PATH, "faculty_data.csv")

# Admissions funnel data
ADMISSIONS_DATA <- file.path(RAW_DATA_PATH, "admissions_data.csv")

# Licensure exam data
LICENSURE_DATA <- file.path(RAW_DATA_PATH, "licensure_exam_results.csv")

# Survey data
SURVEY_DATA <- file.path(RAW_DATA_PATH, "student_survey_data.csv")

# Alumni employment data
ALUMNI_DATA <- file.path(RAW_DATA_PATH, "alumni_employment.csv")

# Add additional data source paths as needed
```

## Security Guidelines

1. **Never commit `data_paths.R` to Git** - It is already in `.gitignore`
2. **Use secure storage locations** - Network drives, encrypted folders, or institutional secure storage
3. **Follow institutional policies** - Comply with data governance and FERPA requirements
4. **Restrict access** - Ensure only authorized users can access the data locations
5. **Document data sources** - Maintain a separate (non-versioned) data dictionary

## Setup Instructions

1. Copy the template above
2. Create `scripts/config/data_paths.R` in your local repository
3. Customize the paths to match your secure data storage locations
4. Verify you have appropriate permissions to access the data
5. Test the configuration by running `source("scripts/config/data_paths.R")`

## Verification

After creating your configuration file, verify it works:

```r
# In R console:
source("scripts/config/data_paths.R")

# Check that paths are defined:
print(DATA_ROOT)
print(ENROLLMENT_DATA)

# Verify paths exist (adjust as needed):
dir.exists(DATA_ROOT)
file.exists(ENROLLMENT_DATA)
```

## Troubleshooting

**Problem**: Scripts can't find the configuration file
- **Solution**: Ensure `data_paths.R` exists in `scripts/config/` directory

**Problem**: Permission denied errors
- **Solution**: Verify you have read/write access to the data directories

**Problem**: File not found errors
- **Solution**: Check that file paths in `data_paths.R` match actual file locations

For additional help, see the main README.md or contact your data steward.
