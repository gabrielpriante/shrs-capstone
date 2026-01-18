# SHRS MQE Capstone Project: Program Health Analysis

## Project Background & Problem Statement

This repository contains the methodological and analytical framework for a Master of Quantitative Economics (MQE) capstone project focused on evaluating the **financial performance, sustainability, and long-term viability** of academic programs within the University of Pittsburgh's School of Health and Rehabilitation Sciences (SHRS).

**This is a workflow-first, data-free repository** due to confidentiality and FERPA (Family Educational Rights and Privacy Act) considerations. No student-level or sensitive institutional data is stored in this repository. All analyses reference external, non-versioned data sources through configuration placeholders.

The project addresses a critical need: developing a comprehensive framework to assess program health across multiple dimensions—enrollment trends, financial sustainability, resource efficiency, and competitiveness—to inform strategic planning and resource allocation decisions.

## Stakeholder Vision: The Program Health Dashboard

The long-term aspiration of this work is to develop a **"Program Health Dashboard"**—a comprehensive analytical tool analogous to hospital patient health dashboards that clinicians use to quickly assess vital signs and diagnose issues.

This dashboard would provide SHRS leadership with:
- Real-time metrics on program enrollment, revenue, and efficiency
- Early warning indicators for programs at risk
- Data-driven insights for resource allocation and strategic planning
- Comparative benchmarks across programs and against peer institutions

**Important Note**: This dashboard is a **future-state vision beyond the current course timeline**. This capstone project establishes the foundational analytical framework and proof-of-concept methodologies that would support such a dashboard's development.

## Scope of Analysis

The analysis focuses on the following SHRS academic programs:

### Communication Science & Disorders (CSD)
- **SLP**: Speech-Language Pathology (Graduate)
- **AuD**: Audiology (Doctorate)
- **UG**: Undergraduate programs in Communication Science

### Sports Medicine & Nutrition (SMN)
- **AT**: Athletic Training (Graduate)
- **DN**: Dietetics & Nutrition (Graduate)
- **SS**: Sports Science (Graduate)
- **UG**: Undergraduate programs in Sports Medicine & Nutrition

## Key Evaluation Dimensions

The analytical framework examines programs across multiple critical dimensions:

1. **Enrollment Trends**: Historical patterns, growth trajectories, cohort sizes
2. **Competitiveness**: Applicant pools, acceptance rates, yield rates
3. **Resource Requirements**: Faculty ratios, instructional costs, facility needs
4. **Financial Performance**: Revenue generation, cost structures, contribution margins
5. **Net Revenue per Student**: Program-level profitability and efficiency metrics
6. **Scale Scenarios**: Impact of enrollment changes on financial sustainability
7. **Efficiency Gains**: Opportunities for operational optimization
8. **Sunset Criteria**: Evidence-based thresholds for program continuation decisions

## Data Sources

**Note**: Due to confidentiality and FERPA requirements, **no actual data files are included in this repository**. The following data sources inform the analysis methodology:

- **Alumni Employment Outcomes**: Post-graduation employment rates, salary data, career placement
- **Departmental & Institutional Overviews**: Program structure, mission statements, strategic priorities
- **Faculty Counts**: Faculty headcount, FTE, student-faculty ratios by program
- **Applicants, Acceptances & Enrollment**: Admissions funnel metrics across years and programs
- **Licensure Exam Pass Rates**: Professional certification and licensing exam performance
- **Student Survey Data**: Reasons for enrollment declines, attrition factors, satisfaction metrics
- **Average Student Loan Amounts**: Financial burden and debt load by program
- **Pitt Enrollment & Gross Tuition**: Institutional-level enrollment and revenue data
- **Retention Rates**: Year-over-year student persistence by program
- **Tuition Rates**: Program-specific tuition and fee structures

All scripts in this repository include **placeholder references** to external data locations that must be configured by authorized users with appropriate data access.

## Team

- **Isabella Ortiz** - MQE Student, Data Consultant I
- **Taylor Lee** - MQE Student, Data Consultant II
- **Gabe Penedo** - MQE Student, Data Consultant III
- **Dave DeJong** - MQE Faculty Contact & Advisor

## Analytical Methodology

This project employs rigorous quantitative methods to evaluate program health:

1. **Data Integration & Cleaning**: Harmonizing data from multiple institutional sources
2. **Trend Analysis**: Time-series analysis of enrollment, revenue, and resource metrics
3. **Financial Modeling**: Cost-benefit analysis, contribution margin calculations, break-even analysis
4. **Comparative Benchmarking**: Cross-program and peer institution comparisons
5. **Scenario Planning**: Sensitivity analysis for enrollment changes and resource allocation
6. **Visualization**: Publication-quality dashboards and reports for stakeholder communication

**Key R Packages Used**:
- `tidyverse` - Data manipulation and visualization
- `haven` / `readr` - Data import from institutional systems
- `fixest` / `lfe` - Panel data and econometric analysis
- `modelsummary` / `gt` - Professional tables for reporting
- `ggplot2` / `plotly` - Static and interactive visualizations

## Repository Structure

**This repository is organized as a reproducible workflow guide**, not a data repository. The structure supports transparent, repeatable analysis:

```
shrs-capstone/
├── scripts/              # Data processing and preparation workflows
│   ├── 00_setup.R           # Package installation and environment setup
│   ├── 01_data_cleaning.R   # Data cleaning workflow (references external data)
│   └── config/              # Configuration files for external data paths
├── analysis/             # Analytical scripts and modeling
│   ├── 01_exploratory_analysis.R  # Descriptive statistics and trends
│   ├── 02_financial_analysis.R    # Revenue and cost modeling
│   └── 03_scenario_planning.R     # What-if scenarios and projections
├── output/               # Generated outputs (illustrative templates)
│   ├── figures/             # Charts, graphs, and visualizations
│   ├── tables/              # Summary statistics and regression tables
│   └── reports/             # Compiled analytical reports
├── docs/                 # Documentation and methodology guides
│   ├── reproducible_workflow.md   # Best practices for reproducibility
│   ├── data_dictionary.md         # Variable definitions (no actual data)
│   └── methodology_notes.md       # Technical documentation
├── README.md             # This file - project overview and guide
├── shrs-capstone.Rproj   # RStudio project file
└── .gitignore            # Excludes data files and sensitive outputs
```

**Key Principles**:
- **No Data in Repository**: All data references are external placeholders
- **Workflow Documentation**: Scripts demonstrate methodology, not results
- **Illustrative Outputs**: Generated outputs are templates, not final decisions
- **Reproducible Methods**: Clear, numbered workflow for transparency

## Getting Started

### Prerequisites

- R (version 4.0 or higher recommended)
- RStudio (recommended IDE)
- Access to external SHRS data sources (institutional access required)
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

4. **Configure external data access**:
   - **DO NOT place data files in this repository**
   - Edit `scripts/config/data_paths.R` to point to your external data location
   - Ensure you have appropriate institutional permissions for data access
   - Contact your data steward for secure data access protocols

### Workflow

The analysis follows a numbered workflow for reproducibility and transparency:

1. **`scripts/00_setup.R`** - Install and load required packages
2. **`scripts/config/data_paths.R`** - Configure external data source locations (create this file locally)
3. **`scripts/01_data_cleaning.R`** - Import and clean data from external sources
4. **`analysis/01_exploratory_analysis.R`** - Descriptive statistics and trend analysis
5. **`analysis/02_financial_analysis.R`** - Revenue and cost modeling
6. **`analysis/03_scenario_planning.R`** - Sensitivity analysis and projections

**Important**: Scripts are configured with placeholder paths. You must create a local `scripts/config/data_paths.R` file (not tracked in Git) that defines actual paths to your data sources.

All scripts should be run in order. Outputs will be saved to the `output/` folder as illustrative templates.

## Data Management & Confidentiality

**Critical**: This project involves sensitive student and institutional data protected by:
- **FERPA** (Family Educational Rights and Privacy Act)
- **University data governance policies**
- **Institutional Review Board (IRB) protocols**

### Data Handling Principles

- **No Data in Repository**: Raw or processed data files are **never** committed to Git
- **External Storage Only**: All data resides in secure, institutionally-approved locations
- **Access Control**: Data access requires appropriate institutional permissions
- **De-identification**: When possible, work with de-identified or aggregated data
- **Secure Transfer**: Use encrypted channels for any data transmission

### Working with External Data

1. **Store data outside the repository**: Keep data in a separate, secure directory
2. **Use configuration files**: Create a local `scripts/config/data_paths.R` file (not tracked)
3. **Reference via placeholders**: Scripts include example paths you must customize
4. **Document data sources**: Maintain a separate, secure data dictionary

Example configuration file (`scripts/config/data_paths.R` - **create locally, do not commit**):
```r
# External data paths - CUSTOMIZE FOR YOUR ENVIRONMENT
# This file should NOT be committed to Git

DATA_ROOT <- "C:/SecureData/SHRS_Analysis"  # or network path
RAW_DATA_PATH <- file.path(DATA_ROOT, "raw")
PROCESSED_DATA_PATH <- file.path(DATA_ROOT, "processed")

# Specific data file paths
ENROLLMENT_DATA <- file.path(RAW_DATA_PATH, "enrollment_data.csv")
FINANCIAL_DATA <- file.path(RAW_DATA_PATH, "financial_data.xlsx")
# ... additional paths as needed
```

## Reproducibility Guidelines

To ensure reproducible and transparent research:

1. **Never commit data files** - All data stays external to the repository
2. **Document your environment** - Use `sessionInfo()` to record package versions
3. **Use relative references** - The R Project file and config ensure portability
4. **Set seeds** - Use `set.seed()` for any random processes
5. **Comment your code** - Explain analytical decisions and assumptions
6. **Version control workflow** - Commit regularly with descriptive messages
7. **Maintain data lineage** - Document transformations from raw to analytical datasets

## Collaboration Norms

Team members should adhere to these collaborative practices:

### Communication
- **Regular Check-ins**: Weekly team meetings to discuss progress and challenges
- **Documentation**: Clearly document analytical decisions and methodological choices
- **Code Review**: Peer review of analytical scripts before finalizing
- **Transparency**: Share interim findings and solicit feedback early

### Version Control Practices
1. **Pull before you push**: Always `git pull` before starting work
2. **Descriptive commits**: Write clear, informative commit messages
3. **Feature branches**: Create branches for major analytical additions
4. **Small commits**: Commit logical units of work, not massive changes
5. **Test before committing**: Ensure scripts run without errors

### Code Quality
- Follow the tidyverse style guide for R code
- Use meaningful variable names that reflect analytical concepts
- Structure scripts with clear sections and comments
- Avoid hard-coded values; use configuration files instead
- Write modular, reusable functions when appropriate

## Important Disclaimers

### Outputs Are Illustrative Templates

**All outputs generated by this repository are illustrative templates and methodological demonstrations**, not final institutional decisions. Actual program evaluation decisions require:
- Comprehensive stakeholder input
- Qualitative context beyond quantitative metrics
- Consideration of strategic priorities and mission alignment
- Formal institutional review processes
- Approval by appropriate governance bodies

### Limitations and Scope

This capstone project:
- Provides a **methodological framework**, not definitive answers
- Demonstrates **analytical approaches** that could inform decision-making
- Establishes **proof-of-concept** for future dashboard development
- Does **not** represent official SHRS or University of Pittsburgh policy

The Program Health Dashboard vision is a **long-term aspiration beyond the course timeline** and would require substantial additional development, validation, and institutional buy-in.

## Contributing

Team members should:

1. Review collaboration norms above before contributing
2. Create feature branches for major analytical work
3. Write clear, descriptive commit messages
4. Test all scripts before committing
5. Document methodological choices and assumptions
6. Update documentation when adding new analyses
7. Respect data confidentiality at all times

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Note**: While the code and methodology are open source, this license does **not** grant access to any underlying data, which remains subject to institutional data governance policies and FERPA protections.

## Contact & Support

For questions about this project:

- **Project Team**: Contact via University of Pittsburgh email
- **MQE Program**: Dave Dejung, MQE Faculty Contact
- **Institution**: University of Pittsburgh, School of Health and Rehabilitation Sciences (SHRS)
- **Program**: Master of Quantitative Economics (MQE)

For data access requests: Contact SHRS administration through official university channels.

## Acknowledgments

This project was conducted as part of the MQE capstone requirement at the University of Pittsburgh. We thank:
- SHRS leadership for defining this important research question
- MQE faculty for methodological guidance
- Institutional research staff for data access support

---

*Last Updated: January 2026*

**Repository Purpose**: This is a methodological and analytical framework repository, not a data repository. All analyses reference external data sources due to confidentiality requirements.
