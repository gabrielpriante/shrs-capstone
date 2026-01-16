# Data Configuration Directory

## Purpose

This directory contains configuration files for accessing external data sources. These files are **NOT tracked in Git** for security and privacy.

## Files

- **`data_paths.example.R`** (TRACKED): Template showing required configuration structure
- **`data_paths.R`** (NOT TRACKED): Your local configuration with actual data paths
- **`load_data_paths.R`** (TRACKED): Shared loader function used by all scripts

## Quick Start

### Option A: Use External Secure Data

1. **Copy the example configuration:**
   ```bash
   cp scripts/config/data_paths.example.R scripts/config/data_paths.R
   ```
   Or manually copy and rename the file in your file browser

2. **Edit `data_paths.R`** with your actual secure data paths:
   ```r
   DATA_ROOT <- "/your/actual/secure/path/SHRS_Analysis"
   # Update all file paths to match your data location
   ```

3. **Run analysis scripts normally** - they will automatically use your configuration

### Option B: Run with Mock Data (Testing/Demonstration)

**In R:**
```r
Sys.setenv(SHRS_USE_MOCK_DATA = "1")
source("scripts/01_data_cleaning.R")
```

**In Bash/Terminal:**
```bash
export SHRS_USE_MOCK_DATA=1
Rscript scripts/01_data_cleaning.R
```

Mock mode generates realistic simulated data for testing the analysis pipeline without requiring access to actual secure data.

## Why is `data_paths.R` Ignored?

**Security & Privacy**: `data_paths.R` contains file paths that may reveal:
- Your computer username or directory structure
- Network share locations
- Institutional data storage patterns

**FERPA Compliance**: Paths could indirectly identify data sources containing protected student information.

**Portability**: Each user needs their own configuration matching their local or network storage setup.

## How the Loader Works

The `load_data_paths.R` function:

1. **Checks for mock mode**: If `SHRS_USE_MOCK_DATA=1`, enables mock data
2. **Looks for your config**: Searches for `scripts/config/data_paths.R`
3. **Loads paths**: If found, sources the file and returns path variables
4. **Fails helpfully**: If not found (and not mock mode), shows clear setup instructions

All analysis scripts use this shared loader for consistent behavior.

## What is Mock Mode For?

Mock mode allows you to:
- **Test the pipeline** without secure data access
- **Demonstrate methods** in presentations or training
- **Develop new analyses** before data is available
- **Verify installation** and package dependencies
- **Run CI/CD checks** in automated environments

Mock data is deterministic (set.seed(123)) and matches the expected schema of real SHRS program health data.

## Configuration Template

See `data_paths.example.R` for the complete template. Key variables:

- `DATA_ROOT`: Base directory for all data
- `RAW_DATA_PATH`: Location of unprocessed institutional data
- `PROCESSED_DATA_PATH`: Location for cleaned analytical datasets  
- Individual file paths: `ENROLLMENT_DATA`, `FINANCIAL_DATA`, etc.

## Verification

After creating your `data_paths.R`, test it:

```r
source("scripts/config/data_paths.R")
print(DATA_ROOT)
dir.exists(DATA_ROOT)          # Should return TRUE
file.exists(ENROLLMENT_DATA)   # Should return TRUE if file exists
```

## Troubleshooting

**"DATA CONFIGURATION REQUIRED" error:**
- Create `data_paths.R` from the example, OR
- Enable mock mode with `SHRS_USE_MOCK_DATA=1`

**"File not found" errors:**
- Verify paths in `data_paths.R` match actual file locations
- Check file permissions and access rights
- Ensure data files exist at specified paths

**Mock mode not working:**
- Check environment variable: `Sys.getenv("SHRS_USE_MOCK_DATA")`
- Must be exactly "1" (as string)
- Set before loading: `Sys.setenv(SHRS_USE_MOCK_DATA = "1")`

## Important Reminders

✅ **DO**: Copy `data_paths.example.R` to create your local `data_paths.R`  
✅ **DO**: Keep data in secure, external locations outside the repository  
✅ **DO**: Use mock mode for testing and demonstration  
✅ **DO**: Follow institutional data governance policies

❌ **DON'T**: Commit `data_paths.R` to Git (it's in `.gitignore`)  
❌ **DON'T**: Put actual data files in the repository  
❌ **DON'T**: Share your `data_paths.R` file (it's environment-specific)  
❌ **DON'T**: Use paths that identify real institutions in committed files

For more information:
- Main README: Project overview and FERPA considerations
- `docs/quick_start.md`: Step-by-step setup guide
- `docs/reproducible_workflow.md`: Detailed best practices
