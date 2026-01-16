# ==============================================================================
# Setup Script - Package Installation and Loading
# ==============================================================================
# This script installs and loads all required packages for the SHRS capstone
# project focused on Program Health Analysis
# Run this script once when first setting up the project
# Last Updated: January 2026
# ==============================================================================

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages) > 0) {
    message("Installing missing packages: ", paste(new_packages, collapse = ", "))
    install.packages(new_packages, dependencies = TRUE)
  } else {
    message("All required packages are already installed.")
  }
}

# Core packages for data manipulation and analysis
core_packages <- c(
  "tidyverse",    # Data manipulation and visualization (includes readr, ggplot2, dplyr, tidyr, etc.)
  "here",         # Relative file paths
  "haven",        # Reading Stata, SPSS, SAS files
  "readxl",       # Reading Excel files
  "data.table"    # Fast data manipulation
)

# Statistical analysis packages
stats_packages <- c(
  "fixest",       # Fast fixed-effects estimations
  "lfe",          # Linear group fixed effects
  "estimatr",     # Robust standard errors
  "sandwich",     # Robust covariance matrix estimators
  "lmtest"        # Testing linear regression models
)

# Visualization packages (additional to tidyverse)
viz_packages <- c(
  "scales",       # Scale functions for visualization
  "gridExtra",    # Arranging multiple plots
  "patchwork",    # Combining ggplots
  "ggthemes",     # Additional themes for ggplot2
  "plotly"        # Interactive visualizations
)

# Tables and output packages
output_packages <- c(
  "gt",           # Modern table creation
  "modelsummary", # Modern regression tables
  "knitr",        # Dynamic report generation
  "kableExtra"    # Enhanced table formatting
)

# Combine all packages
all_packages <- unique(c(
  core_packages,
  stats_packages,
  viz_packages,
  output_packages
))

# Install missing packages
message("Checking and installing required packages...")
install_if_missing(all_packages)

# Load core packages
message("\nLoading core packages...")
library(tidyverse)
library(here)

# Print session info for reproducibility
message("\n=== Session Info ===")
print(sessionInfo())

# Reminder about data configuration
message("\n=== IMPORTANT: Data Configuration ===")
message("This repository does not contain data files.")
message("Before running analysis scripts, you must:")
message("  1. Create scripts/config/data_paths.R (not tracked in Git)")
message("  2. Define paths to your external data sources")
message("  3. Ensure you have appropriate data access permissions")
message("\nSee README.md for detailed data configuration instructions.")

message("\n=== Setup Complete ===")
message("All required packages are installed and ready to use.")
message("Remember to configure external data paths before running analysis scripts.")
