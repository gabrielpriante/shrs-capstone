# Reproducible Workflow Guide

## Overview

This document provides guidelines for maintaining a reproducible workflow throughout the SHRS capstone project. Following these practices ensures that all team members can replicate results and that the analysis is transparent and verifiable.

## Project Organization Principles

### 1. Directory Structure

The project follows a standardized structure:

- **`data/raw/`**: Original, unmodified data files (never edit these!)
- **`data/processed/`**: Cleaned and processed datasets ready for analysis
- **`scripts/`**: Data cleaning and processing scripts
- **`analysis/`**: Analysis and modeling scripts
- **`output/`**: All generated outputs (figures, tables, results)
- **`docs/`**: Documentation, reports, and presentations

### 2. File Naming Conventions

Use clear, descriptive names with consistent formatting:

- Use lowercase with underscores: `my_analysis_file.R`
- Number scripts to indicate order: `01_clean_data.R`, `02_analyze.R`
- Include dates for versions if needed: `report_2026-01-15.Rmd`
- Avoid spaces and special characters

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

## Data Management

### Working with Raw Data

**Never modify raw data files.** All transformations should be scripted.

```r
# Good: Read raw data and transform via script
raw_data <- read_csv(here("data", "raw", "original_data.csv"))
cleaned_data <- raw_data %>% filter(!is.na(key_var))

# Bad: Manually editing Excel files
```

### Saving Processed Data

Use appropriate formats:

```r
# For R-only workflows (preserves data types)
saveRDS(data, here("data", "processed", "clean_data.rds"))

# For sharing with other software
write_csv(data, here("data", "processed", "clean_data.csv"))

# For Stata users
haven::write_dta(data, here("data", "processed", "clean_data.dta"))
```

### File Paths

Always use relative paths with the `here` package:

```r
# Good: Works on any computer
data <- read_csv(here("data", "raw", "mydata.csv"))

# Avoid: Absolute paths won't work on other machines
data <- read_csv("C:/Users/YourName/Documents/project/data/raw/mydata.csv")
```

## Reproducibility Checklist

Before sharing your analysis, ensure:

- [ ] All required packages are listed in `scripts/00_setup.R`
- [ ] No absolute file paths in code
- [ ] Random seeds are set where needed (`set.seed()`)
- [ ] Scripts are numbered and can run in order
- [ ] Raw data is not modified
- [ ] All outputs can be regenerated from scripts
- [ ] Code runs without errors on a fresh R session
- [ ] README is up to date with current workflow
- [ ] Sensitive data is not committed to Git

## Running the Full Analysis

To reproduce the entire analysis from scratch:

1. **Setup environment**
   ```r
   source("scripts/00_setup.R")
   ```

2. **Clean data**
   ```r
   source("scripts/01_data_cleaning.R")
   ```

3. **Run analysis**
   ```r
   source("analysis/01_exploratory_analysis.R")
   ```

4. **Add additional scripts as needed**
   - Create `scripts/02_data_processing.R` for additional data transformations
   - Create `analysis/02_robustness_checks.R` for sensitivity analysis
   - Add more analysis scripts following the numbered convention

Or run all scripts sequentially:

```r
# Run complete workflow
scripts <- c(
  "scripts/00_setup.R",
  "scripts/01_data_cleaning.R",
  "analysis/01_exploratory_analysis.R"
)

for (script in scripts) {
  message("Running: ", script)
  source(here(script))
}
```

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

1. **Hard-coded values**: Use variables and configuration files instead
2. **Overwriting processed data**: Use version suffixes if needed
3. **Uncommitted changes**: Commit regularly to avoid losing work
4. **Missing dependencies**: Always list required packages
5. **Undocumented decisions**: Comment why you made specific choices
6. **Large files in Git**: Use `.gitignore` for data and output files

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
