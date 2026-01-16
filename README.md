# MQE Capstone Project - SHRS Team 2026

## Project Overview

This repository contains the capstone project for the Master of Quantitative Economics (MQE) program, completed by the SHRS team. The project aims to conduct rigorous empirical analysis using R to address important economic questions with real-world data.

## Research Question

[To be defined by the team - Please update this section with your specific research question]

Example: "What is the impact of [policy/intervention] on [outcome variable] across [population/region], controlling for [relevant factors]?"

## Data Sources

The project utilizes the following data sources:

- **Primary Dataset**: [Dataset name and source]
  - Description: [Brief description of the dataset]
  - Access: [How to access/download the data]
  - Time Period: [Date range covered]
  
- **Secondary Datasets**: [Additional datasets if applicable]
  - [List any supplementary data sources]

*Note: Raw data files should be placed in `data/raw/` and are not tracked in version control. See Data Management section below.*

## Methodology

The analysis employs the following methods:

1. **Data Processing**: Cleaning and preparation of raw data
2. **Exploratory Data Analysis**: Descriptive statistics and visualization
3. **Econometric Analysis**: [e.g., Regression analysis, Panel data methods, Time series analysis]
4. **Robustness Checks**: Sensitivity analysis and validation
5. **Visualization**: Publication-quality figures and tables

**Key R Packages Used**:
- `tidyverse` - Data manipulation and visualization
- `haven` / `readr` - Data import
- `fixest` / `lfe` - Econometric analysis
- `stargazer` / `modelsummary` - Results tables
- `ggplot2` - Visualization

## Repository Structure

```
shrs-capstone/
├── data/
│   ├── raw/              # Original, unmodified data (not tracked in Git)
│   └── processed/        # Cleaned and processed data files
├── scripts/              # R scripts for data processing and cleaning
├── analysis/             # R scripts for statistical analysis and modeling
├── output/               # Generated figures, tables, and results
├── docs/                 # Documentation, reports, and presentations
├── README.md             # This file
├── shrs-capstone.Rproj   # RStudio project file
└── .gitignore            # Git ignore rules
```

## Team Members and Roles

- **[Team Member 1]** - [Role/Responsibilities, e.g., Data Collection & Processing]
- **[Team Member 2]** - [Role/Responsibilities, e.g., Statistical Analysis]
- **[Team Member 3]** - [Role/Responsibilities, e.g., Visualization & Reporting]
- **[Team Member 4]** - [Role/Responsibilities, e.g., Literature Review & Writing]

*Please update this section with actual team member names and roles.*

## Getting Started

### Prerequisites

- R (version 4.0 or higher recommended)
- RStudio (recommended IDE)
- Required R packages (see `scripts/00_setup.R`)

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone https://github.com/gabrielpriante/shrs-capstone.git
   cd shrs-capstone
   ```

2. **Open the R Project**:
   - Double-click `shrs-capstone.Rproj` to open in RStudio
   - This ensures consistent working directory and project settings

3. **Install required packages**:
   ```r
   source("scripts/00_setup.R")
   ```

4. **Add data files**:
   - Place raw data files in `data/raw/`
   - These files are not tracked in Git (see `.gitignore`)

### Workflow

The analysis follows a numbered workflow for reproducibility:

1. **`scripts/00_setup.R`** - Install and load required packages
2. **`scripts/01_data_cleaning.R`** - Import and clean raw data
3. **`scripts/02_data_processing.R`** - Create analysis variables
4. **`analysis/01_exploratory_analysis.R`** - Descriptive statistics and EDA
5. **`analysis/02_main_analysis.R`** - Primary econometric analysis
6. **`analysis/03_robustness_checks.R`** - Sensitivity analysis

All scripts should be run in order. Processed data and outputs will be saved to their respective folders.

## Data Management

- **Raw Data**: Store in `data/raw/`. Not tracked in version control due to size and privacy.
- **Processed Data**: Save cleaned datasets to `data/processed/` as `.rds` or `.csv` files.
- **Output**: All figures (`.png`, `.pdf`) and tables (`.tex`, `.html`) go in `output/`.
- **Documentation**: Final reports, presentations, and documentation in `docs/`.

## Reproducibility Guidelines

To ensure reproducible research:

1. **Never modify raw data files** - All changes should be scripted
2. **Use relative paths** - The R Project file ensures consistent working directory
3. **Set seeds** - Use `set.seed()` for any random processes
4. **Document dependencies** - List all required packages and versions
5. **Comment your code** - Explain complex operations and decisions
6. **Version control** - Commit regularly with descriptive messages

## Contributing

Team members should:

1. Create a new branch for major changes
2. Write clear commit messages
3. Test code before committing
4. Document any new functions or complex code
5. Update the README if adding new components

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For questions or collaboration inquiries, please contact:

- Project Lead: [Name and email]
- Institution: [University/Institution name]
- Program: Master of Quantitative Economics (MQE)

---

*Last Updated: January 2026*
