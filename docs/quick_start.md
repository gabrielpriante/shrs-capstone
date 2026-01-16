# Quick Start Guide

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

4. **Add your data**
   - Place raw data files in `data/raw/`

## Daily Workflow

### Before You Start
```bash
git pull origin main
```

### While Working
1. Edit your scripts in `scripts/` or `analysis/`
2. Save frequently
3. Test your code
4. Commit changes:
   ```bash
   git add filename.R
   git commit -m "Description of changes"
   git push
   ```

## Useful R Commands

### Load data
```r
library(here)
library(tidyverse)

# Read processed data
data <- readRDS(here("data", "processed", "cleaned_data.rds"))

# Read CSV
data <- read_csv(here("data", "raw", "mydata.csv"))
```

### Save outputs
```r
# Save figure
ggsave(here("output", "figures", "my_plot.png"), 
       width = 8, height = 6)

# Save table
write_csv(results, here("output", "tables", "results.csv"))
```

### Run analysis
```r
# Run single script
source(here("analysis", "01_exploratory_analysis.R"))

# Check working directory
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

**Can't find file?**
- Use `here()` package for paths
- Check you're in the R Project (see top-right in RStudio)

**Package not found?**
- Run `install.packages("package_name")`
- Or re-run `source("scripts/00_setup.R")`

**Merge conflict?**
- Ask a team member for help
- Don't force push!

---

For detailed information, see:
- **README.md**: Full project documentation
- **docs/reproducible_workflow.md**: Best practices guide
