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

4. **Choose your data mode** (see below)

## Data Configuration: Two Options

**This repository does not contain data.** Choose one of these options:

### Option A: Use External Secure Data (Production Mode)

For actual analysis with real institutional data:

1. **Copy the example configuration:**
   ```bash
   cp scripts/config/data_paths.example.R scripts/config/data_paths.R
   ```

2. **Edit `scripts/config/data_paths.R`:**
   - Set `DATA_ROOT` to your secure data storage location
   - Update all file paths to match your data files
   - Ensure you have institutional data access permissions

3. **Run analysis scripts normally:**
   ```r
   source("scripts/01_data_cleaning.R")
   source("analysis/01_exploratory_analysis.R")
   ```

**Important:** `data_paths.R` is in `.gitignore` and will NOT be committed.

### Option B: Run with Mock Data (Testing/Demo Mode)

For testing the pipeline without secure data:

1. **Set the environment variable:**
   
   **In R:**
   ```r
   Sys.setenv(SHRS_USE_MOCK_DATA = "1")
   ```
   
   **In Bash/Terminal:**
   ```bash
   export SHRS_USE_MOCK_DATA=1
   ```

2. **Run analysis scripts:**
   ```r
   source("scripts/01_data_cleaning.R")
   source("analysis/01_exploratory_analysis.R")
   ```

Mock mode generates realistic simulated data automatically.

## Daily Workflow

### Before You Start
```bash
git pull origin main
```

### While Working
1. Edit scripts in `scripts/` or `analysis/`
2. Use Option A (external data) or Option B (mock data) as appropriate
3. Save outputs to `output/` (marked as illustrative templates)
4. Save frequently and test your code
5. Commit changes:
   ```bash
   git add filename.R
   git commit -m "Description of changes"
   git push
   ```

**Never commit data files or your `data_paths.R` configuration!**
**Never commit data files or your `data_paths.R` configuration!**

## Useful R Commands

### Quick Test: Mock Mode
```r
# Enable mock data mode
Sys.setenv(SHRS_USE_MOCK_DATA = "1")

# Run a script - it will use mock data
source("scripts/01_data_cleaning.R")

# Check mock mode is enabled
Sys.getenv("SHRS_USE_MOCK_DATA")  # Should return "1"
```

### Configure External Data (Option A)
```r
# Check if configuration file exists
file.exists(here("scripts", "config", "data_paths.R"))

# Load configuration and test
source(here("scripts", "config", "load_data_paths.R"))
paths <- load_data_paths()

# Verify paths are loaded
print(paths$DATA_ROOT)
print(paths$ENROLLMENT_DATA)
```

### Load Data in Scripts
```r
library(here)
library(tidyverse)

# Load the shared loader
source(here("scripts", "config", "load_data_paths.R"))
paths <- load_data_paths()

# The loader handles both mock and external data modes
if (paths$use_mock) {
  # Use mock data
  source(here("scripts", "utils", "mock_data.R"))
  data <- generate_mock_program_health_data()
} else {
  # Read from external location
  enrollment_data <- read_csv(paths$ENROLLMENT_DATA)
}
```

### Save Outputs (Illustrative Templates)
```r
# Create output directories if needed
dir.create(here("output", "figures"), recursive = TRUE, showWarnings = FALSE)

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
- **Option A**: Create `scripts/config/data_paths.R` from `data_paths.example.R`
- **Option B**: Use mock mode: `Sys.setenv(SHRS_USE_MOCK_DATA = "1")`
- See `scripts/config/README.md` for details

**Can't find data files?**
- Verify `data_paths.R` paths match actual file locations
- Check file permissions and access rights
- Ensure data files exist at specified paths
- OR use mock mode for testing

**"DATA CONFIGURATION REQUIRED" error?**
- Either create `scripts/config/data_paths.R` (Option A)
- Or enable mock mode with `SHRS_USE_MOCK_DATA=1` (Option B)
- Script will show clear instructions

**Mock mode not working?**
- Check: `Sys.getenv("SHRS_USE_MOCK_DATA")` - should return "1"
- Set it: `Sys.setenv(SHRS_USE_MOCK_DATA = "1")`  
- Must be set BEFORE running scripts

**Package not found?**
- Run `install.packages("package_name")`
- Or re-run `source("scripts/00_setup.R")`

**Permission denied errors?**
- Verify institutional data access permissions
- Check file/folder permissions on data storage
- Ensure using approved secure storage locations

**Merge conflict?**
- Ask a team member for help
- Don't force push!
- Data files should never cause conflicts (not in repo!)
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
