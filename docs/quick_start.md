# Quick Start Guide - SHRS Program Health Analysis

## First Time Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/gabrielpriante/shrs-capstone.git
   cd shrs-capstone
   ```

2. **Open in RStudio**
   - Double-click `shrs-capstone.Rproj`

3. **Install packages**
   ```r
   source("scripts/00_setup.R")
   ```

4. **Configure external data access**
   - Create `scripts/config/data_paths.R` (see template in `scripts/config/README.md`)
   - Define paths to your secure data storage location
   - **DO NOT commit this file** (it's in `.gitignore`)
   - Ensure you have institutional permissions for data access

## Important: Data Configuration Required

**This repository does not contain data.** Before running analyses:

1. Obtain appropriate institutional data access permissions
2. Store data in a secure, external location (outside the repository)
3. Create local configuration file: `scripts/config/data_paths.R`
4. See README.md and `scripts/config/README.md` for detailed instructions

## Daily Workflow

### Before You Start
```bash
git pull origin main
```

### While Working
1. Edit scripts in `scripts/` or `analysis/`
2. Reference external data via configuration file
3. Save outputs to `output/` (marked as illustrative templates)
4. Save frequently and test your code
5. Commit changes:
   ```bash
   git add filename.R
   git commit -m "Description of changes"
   git push
   ```

**Never commit data files or your `data_paths.R` configuration!**

## Useful R Commands

### Configure data access (one-time)
```r
# Check if configuration file exists
file.exists(here("scripts", "config", "data_paths.R"))

# Source configuration to load data paths
source(here("scripts", "config", "data_paths.R"))

# Verify paths are loaded
print(DATA_ROOT)
print(ENROLLMENT_DATA)
```

### Load data from external sources
```r
library(here)
library(tidyverse)

# Load configuration first
source(here("scripts", "config", "data_paths.R"))

# Read data from configured external location
enrollment_data <- read_csv(ENROLLMENT_DATA)
financial_data <- read_excel(FINANCIAL_DATA)

# For processed data saved externally
cleaned_data <- readRDS(file.path(PROCESSED_DATA_PATH, "cleaned_enrollment.rds"))
```

### Save outputs (illustrative templates)
```r
# Save figures to output folder
ggsave(here("output", "figures", "enrollment_trends.png"), 
       width = 10, height = 6)

# Save tables to output folder
write_csv(summary_table, here("output", "tables", "program_summary.csv"))

# Note: All outputs are illustrative templates, not final decisions
```

### Run analysis workflow
```r
# Run individual scripts
source(here("scripts", "00_setup.R"))
source(here("scripts", "01_data_cleaning.R"))
source(here("analysis", "01_exploratory_analysis.R"))

# Check working directory (should be project root)
here::here()
```

## Common Git Commands

```bash
# See what changed
git status
git diff

# Create new branch
git checkout -b my-feature

# Commit changes
git add .
git commit -m "Your message"
git push

# Update from main
git pull origin main
```

## Getting Help

- **R help**: `?function_name`
- **Package help**: `help(package = "tidyverse")`
- **Team**: Check project Wiki or ask in Slack

## Troubleshooting

**Can't find configuration file?**
- Create `scripts/config/data_paths.R` using the template in `scripts/config/README.md`
- This file should NOT be committed to Git
- Ensure it defines paths to your external data storage

**Can't find data files?**
- Check that your `data_paths.R` configuration points to correct locations
- Verify you have read access to the external data directory
- Ensure data files exist at the specified paths
- Contact your data steward for data access issues

**Package not found?**
- Run `install.packages("package_name")`
- Or re-run `source("scripts/00_setup.R")`

**Permission denied errors?**
- Verify you have appropriate institutional data access permissions
- Check file/folder permissions on your data storage location
- Ensure you're using approved secure data storage

**Configuration path errors?**
- Use forward slashes `/` or double backslashes `\\` in Windows paths
- Verify paths exist before running scripts
- Use `file.exists()` and `dir.exists()` to test paths

**Merge conflict?**
- Ask a team member for help
- Don't force push!
- Remember: Data files should never cause conflicts (they're not in the repo!)

## Data Security Reminders

⚠️ **Critical**: This repository must remain data-free

- ✅ **DO**: Store all data in external, secure locations
- ✅ **DO**: Use configuration files for data paths (not committed)
- ✅ **DO**: Mark all outputs as "illustrative templates"
- ❌ **DON'T**: Commit any data files to Git
- ❌ **DON'T**: Share your `data_paths.R` configuration
- ❌ **DON'T**: Include actual data in documentation or comments

## Need Help?

- **R help**: `?function_name`
- **Package help**: `help(package = "tidyverse")`
- **Data configuration**: See `scripts/config/README.md`
- **Workflow guide**: See `docs/reproducible_workflow.md`
- **Full documentation**: See main `README.md`
- **Team**: Check project documentation or contact team members

---

For detailed information, see:
- **README.md**: Complete project overview and context
- **docs/reproducible_workflow.md**: Detailed best practices guide
- **scripts/config/README.md**: Data configuration instructions
