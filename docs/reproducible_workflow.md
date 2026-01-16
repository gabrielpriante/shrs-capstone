# Reproducible Workflow Guide - SHRS Program Health Analysis

## Overview

This document provides guidelines for maintaining a reproducible workflow throughout the SHRS capstone project. Following these practices ensures that all team members can replicate analytical methods and that the work is transparent and verifiable.

**Important**: This is a **data-free repository**. All data remains in external, secure locations. Reproducibility focuses on analytical methods and workflows, not data storage.

## Project Organization Principles

### 1. Directory Structure

The project follows a standardized, data-free structure:

- **`scripts/`**: Data processing and cleaning workflows (reference external data)
  - `config/`: Local configuration files for external data paths (not tracked in Git)
- **`analysis/`**: Analytical and modeling scripts
- **`output/`**: Generated outputs - illustrative templates only (figures, tables, reports)
- **`docs/`**: Documentation, methodology guides, and reports

**No `data/` directory**: All data is stored in external, secure locations configured through `scripts/config/data_paths.R`

### 2. File Naming Conventions

Use clear, descriptive names with consistent formatting:

- Use lowercase with underscores: `enrollment_trend_analysis.R`
- Number scripts to indicate order: `01_data_cleaning.R`, `02_financial_analysis.R`
- Include dates for versions if needed: `report_2026-01-15.Rmd`
- Avoid spaces and special characters
- Use descriptive names that reflect content: `program_health_metrics.R` not `analysis.R`

### 3. Version Control Best Practices

**Before starting work:**
```bash
git pull origin main
```

**Regular commits:**
```bash
git add filename.R
git commit -m "Clear description of changes"
git push origin branch-name
```

**Commit message guidelines:**
- Use present tense: "Add regression analysis" not "Added regression analysis"
- Be specific: "Fix missing value handling in cleaning script" not "Fix bug"
- Reference issues when relevant: "Closes #12: Add robustness checks"

## Coding Standards

### R Code Style

Follow these conventions for consistency:

1. **Use meaningful variable names**
   ```r
   # Good
   treatment_effect <- coef(model)["treatment"]
   
   # Avoid
   te <- coef(model)["treatment"]
   ```

2. **Add comments for clarity**
   ```r
   # Calculate treatment effect with robust standard errors
   model <- feols(outcome ~ treatment | year, 
                  data = analysis_data,
                  cluster = ~id)
   ```

3. **Use consistent indentation** (2 spaces, set in .Rproj file)

4. **Keep lines under 80 characters** when possible

5. **Use pipes for readability**
   ```r
   cleaned_data <- raw_data %>%
     filter(!is.na(id)) %>%
     mutate(log_outcome = log(outcome)) %>%
     arrange(year)
   ```

### Script Structure

Each script should follow this template:

```r
# ==============================================================================
# [Script Title]
# ==============================================================================
# Brief description of what the script does
# Input: [input files]
# Output: [output files]
# Last Updated: [Date]
# ==============================================================================

# Load required packages
library(tidyverse)
library(here)

# Set seed for reproducibility
set.seed(123)

# [Script content organized in sections]

# ==============================================================================
# SECTION 1: [Name]
# ==============================================================================

# Code here

# ==============================================================================
# SECTION 2: [Name]
# ==============================================================================

# More code

# ==============================================================================
# SCRIPT COMPLETE
# ==============================================================================
```

## Data Management - External Storage Model

### Critical Principle: No Data in Repository

**All data must be stored in external, secure locations** that comply with institutional data governance policies and FERPA requirements.

### Working with External Data

**Never commit data files to Git.** Instead:

1. **Store data externally**: Keep all data in a separate, secure directory outside the repository
2. **Configure paths locally**: Create `scripts/config/data_paths.R` with your data locations
3. **Reference via configuration**: Scripts load data using paths from configuration file
4. **Document sources**: Maintain metadata about data sources (separately from actual data)

```r
# Good: Reference external data via configuration
source(here("scripts", "config", "data_paths.R"))
enrollment_data <- read_csv(ENROLLMENT_DATA)

# Bad: Hard-coded paths or data in repository
enrollment_data <- read_csv(here("data", "raw", "enrollment.csv"))  # NO!
```

### Data Configuration Setup

Create `scripts/config/data_paths.R` (this file is in `.gitignore` and will not be committed):

```r
# Define external data root
DATA_ROOT <- "C:/SecureData/SHRS_Analysis"  # Customize for your environment

# Define paths to specific data files
ENROLLMENT_DATA <- file.path(DATA_ROOT, "raw", "enrollment.csv")
FINANCIAL_DATA <- file.path(DATA_ROOT, "raw", "financial.xlsx")
# ... additional data paths
```

See `scripts/config/README.md` for detailed configuration instructions.

### Saving Processed Data

Save all processed/cleaned data to external locations:

```r
# Good: Save to external processed data location
saveRDS(cleaned_data, file.path(PROCESSED_DATA_PATH, "cleaned_enrollment.rds"))

# Bad: Save to repository (violates data confidentiality)
saveRDS(cleaned_data, here("data", "processed", "cleaned_data.rds"))  # NO!
```

## Reproducibility Checklist

Before sharing your analysis, ensure:

- [ ] All required packages are listed in `scripts/00_setup.R`
- [ ] Data configuration instructions are documented
- [ ] No data files are committed to Git (check `.gitignore`)
- [ ] Scripts reference external data via configuration file
- [ ] Random seeds are set where needed (`set.seed()`)
- [ ] Scripts are numbered and can run in order (with proper data access)
- [ ] All outputs are marked as illustrative templates
- [ ] Code runs without errors on a fresh R session (with data access)
- [ ] README is up to date with current workflow
- [ ] Sensitive information is not committed to Git
- [ ] Configuration file template is provided (but not actual config)

## Running the Full Analysis

To reproduce the analytical workflow:

### One-Time Setup

1. **Setup environment**
   ```r
   source("scripts/00_setup.R")
   ```

2. **Configure data access**
   - Create `scripts/config/data_paths.R` (see template in `scripts/config/README.md`)
   - Ensure you have appropriate institutional data access permissions
   - Verify paths point to your secure data location

### Run Analysis Scripts

3. **Clean data**
   ```r
   source("scripts/01_data_cleaning.R")
   ```

4. **Run exploratory analysis**
   ```r
   source("analysis/01_exploratory_analysis.R")
   ```

5. **Additional analyses as developed**
   ```r
   source("analysis/02_financial_analysis.R")
   source("analysis/03_scenario_planning.R")
   ```

### Running Complete Workflow

Or run all scripts sequentially:

```r
# Define workflow scripts
workflow_scripts <- c(
  "scripts/00_setup.R",
  "scripts/01_data_cleaning.R",
  "analysis/01_exploratory_analysis.R"
  # Add additional scripts as developed
)

# Run complete workflow
for (script in workflow_scripts) {
  message("\n========================================")
  message("Running: ", script)
  message("========================================\n")
  source(here(script))
}
```

**Note**: This workflow assumes you have configured external data access. Without data access, scripts will generate placeholder outputs for demonstration.

## Collaboration Tips

### Before Starting Work

1. Pull latest changes: `git pull`
2. Create a new branch: `git checkout -b your-feature-name`
3. Review open issues and communicate with team

### While Working

1. Commit frequently with clear messages
2. Test your code before committing
3. Document complex operations
4. Keep scripts focused on single tasks

### When Sharing Results

1. Push your branch to GitHub
2. Create a pull request with description
3. Request review from team member
4. Address feedback and merge

## Common Pitfalls to Avoid

1. **Committing data files**: Always check that data files are in `.gitignore`
2. **Hard-coded data paths**: Use configuration file, not hard-coded paths
3. **Storing data in repository**: All data must be external to the repository
4. **Sharing sensitive information**: Never commit FERPA-protected or confidential data
5. **Missing data configuration**: Document how to configure data access
6. **Undocumented decisions**: Comment analytical choices and assumptions
7. **Treating outputs as final**: Remember outputs are illustrative templates
8. **Skipping data validation**: Always validate data after import and cleaning

## Data Security and Confidentiality

### FERPA Compliance

All work must comply with FERPA (Family Educational Rights and Privacy Act):

- **No student-level data in repository**: Even aggregated data should be external
- **De-identification when possible**: Work with aggregated or de-identified data
- **Secure data transfer**: Use encrypted channels for any data movement
- **Access control**: Only authorized users should access the data
- **Audit trail**: Document who accessed data and when (outside repository)

### Best Practices

1. **Separate code from data**: Code in repository, data in secure external location
2. **Configuration not hardcoding**: Use config files for data paths
3. **Template outputs**: Generated outputs should be clearly marked as illustrative
4. **Documentation**: Document data sources without including actual data
5. **Team training**: Ensure all team members understand data security requirements

## Session Info

Always record your R session info for reproducibility:

```r
# At the end of your analysis script
writeLines(capture.output(sessionInfo()), 
           here("output", "session_info.txt"))
```

## Getting Help

- **R Documentation**: `?function_name` or `help(package_name)`
- **Team Resources**: Check the project Wiki or Slack channel
- **Stack Overflow**: Search for similar questions
- **Package Vignettes**: `browseVignettes("package_name")`

## Additional Resources

- **R for Data Science**: https://r4ds.had.co.nz/
- **Advanced R**: https://adv-r.hadley.nz/
- **Tidyverse Style Guide**: https://style.tidyverse.org/
- **Happy Git with R**: https://happygitwithr.com/
- **R Markdown Guide**: https://rmarkdown.rstudio.com/

---

*This document is a living guide. Update it as the team develops new practices or conventions.*
