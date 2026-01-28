#!/usr/bin/env python3
"""
SHRS Capstone: Market Analysis Module Generator

SAVE AS: create_market_analysis.py (in your shrs-capstone root folder)
RUN: python create_market_analysis.py
"""

import os

def create_file(filepath, content):
    """Create a file with given content"""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Created file: {filepath}")

# Base directory
base_dir = "analysis/04_market_analysis"

# Ensure directory exists
os.makedirs(base_dir, exist_ok=True)
print(f"Created directory: {base_dir}/")

# ==============================================================================
# FILE 1: README
# ==============================================================================
readme_content = """# Market Analysis Module

## Purpose

The Market Analysis module provides external labor market context for SHRS program health evaluation. It synthesizes data on labor demand, credential requirements, peer program supply, and wage-to-cost relationships to inform strategic planning and dashboard development.

**This module produces aggregate counts and trends only—no student-level data.**

## Conceptual Framework

Market analysis evaluates programs across four dimensions:

1. **Labor Market Trends**: Employment demand and wage levels from BLS Occupational Employment and Wage Statistics (OEWS) and Employment Projections
2. **Credential Pressure**: Licensure requirements, exam pass rate trends, and scope-of-practice changes affecting program attractiveness
3. **Peer Program Supply**: Regional program saturation using IPEDS completions data and professional directories
4. **Wage vs. Cost Context**: Simple wage-to-tuition ratio as a proxy for return on investment attractiveness

These dimensions combine into a composite **Market Risk Index** that flags programs facing external headwinds.

## Data Sources

### External Data (Not Stored in Repository)

All external data must be placed in `$SHRS_DATA_ROOT/market/` or configured via `scripts/config/data_paths.R`:

- **BLS OEWS** (`bls_oews.csv`): Employment and wage data by SOC code
- **BLS Employment Projections** (`bls_projections.csv`): 10-year growth outlook by SOC code
- **IPEDS Program Counts** (`ipeds_program_counts.csv`): Peer institution program completions by region and CIP code
- **Credential Pressure Data** (`credential_pressure.csv`): Manually maintained file tracking licensure and exam trends
- **Internal Tuition Data** (`../internal/tuition_program_level.csv`): SHRS program-level tuition rates

If any file is missing, scripts generate a **TEMPLATE** file in `output/tables/` with the required schema and example rows.

### Data Safety

- **FERPA Compliance**: This module uses only aggregate counts and publicly available labor statistics—no student-level data
- **External Storage**: All source data resides outside the Git repository
- **Template Generation**: Scripts fail gracefully with clear instructions when data is unavailable

## How to Run

### Prerequisites

1. Ensure `scripts/00_setup.R` has been run to install required packages
2. Configure data root in one of two ways:
   - Set environment variable: `Sys.setenv(SHRS_DATA_ROOT = "/path/to/data")`
   - Create `scripts/config/data_paths.R` (gitignored) with `DATA_ROOT <- "/path/to/data"`
3. Place external data files in `$DATA_ROOT/market/` and `$DATA_ROOT/internal/`

### Execution Order

Run scripts in numbered order:
```r
# Configure paths and settings
source("analysis/04_market_analysis/00_market_config.R")

# Generate market context outputs
source("analysis/04_market_analysis/01_labor_market_trends.R")
source("analysis/04_market_analysis/02_credential_pressure.R")
source("analysis/04_market_analysis/03_peer_program_supply.R")
source("analysis/04_market_analysis/04_wage_vs_cost_context.R")
source("analysis/04_market_analysis/05_market_risk_index.R")
```

Each script:
- Validates required inputs
- Computes or refreshes outputs only when inputs change (unless `FORCE_REBUILD = TRUE`)
- Saves artifacts to `output/tables/` and `output/figures/`
- Produces both CSV and Markdown summary tables

### Refresh Policy

The module uses **event-driven refresh** via input file timestamps:

- On first run, all outputs are generated
- On subsequent runs, scripts check if input files have changed
- If unchanged and `FORCE_REBUILD = FALSE`, computation is skipped
- Cache metadata stored in `output/.cache/market_*_inputs.json`

To force rebuild:
```r
source("analysis/04_market_analysis/00_market_config.R")
MARKET_CONFIG$FORCE_REBUILD <- TRUE
source("analysis/04_market_analysis/01_labor_market_trends.R")  # etc.
```

## Outputs

### Tables (CSV + Markdown)

All tables saved to `output/tables/`:

- `market_labor_summary.csv|.md`: Labor market trends by program (employment, wages, growth outlook)
- `credential_pressure_summary.csv|.md`: Licensure and exam pressure indicators
- `peer_program_supply.csv|.md`: Regional peer saturation index
- `wage_vs_cost_context.csv|.md`: Wage-to-tuition ratio by program
- `market_risk_index.csv|.md`: Composite market risk score

### Figures

All figures saved to `output/figures/`:

- `labor_market_growth_vs_wage.png`: Scatter plot of projected growth vs. median wage
- `peer_program_supply_bars.png`: Bar chart of peer saturation by program and region
- `wage_vs_cost_context.png`: Scatter plot of wage index vs. tuition index

## Limitations & Disclaimers

**This module provides contextual indicators, not decision rules.**

- **External Factors Only**: Does not account for internal program quality, faculty expertise, or strategic priorities
- **Lagged Data**: BLS and IPEDS data are typically 1-2 years behind
- **Regional Assumptions**: Peer saturation uses broad regional categories; local market dynamics may differ
- **Composite Index Weights**: Market Risk Index weights are subjective and should be validated with stakeholders
- **Not Causal**: Correlations between market conditions and program health do not imply causation

**Use this analysis as one input among many in strategic planning.**

---

*Last Updated: January 2026*
"""

create_file(f"{base_dir}/README_market_analysis.md", readme_content)

# ==============================================================================
# FILE 2: Config
# ==============================================================================
config_content = '''# ==============================================================================
# Market Analysis Configuration
# ==============================================================================
# Purpose: Define paths, settings, and utilities for market analysis module
# Inputs:  Environment variable SHRS_DATA_ROOT or scripts/config/data_paths.R
# Outputs: MARKET_CONFIG list object with paths and settings
# Usage:   source("analysis/04_market_analysis/00_market_config.R")
# ==============================================================================

# Required packages
if (!require("digest", quietly = TRUE)) install.packages("digest")
if (!require("jsonlite", quietly = TRUE)) install.packages("jsonlite")
if (!require("knitr", quietly = TRUE)) install.packages("knitr")

library(digest)

# ==============================================================================
# Helper Function: Get Data Root Path
# ==============================================================================
get_data_root <- function() {
  env_root <- Sys.getenv("SHRS_DATA_ROOT", unset = "")
  if (nzchar(env_root)) {
    if (!dir.exists(env_root)) {
      stop(sprintf("SHRS_DATA_ROOT environment variable set but directory does not exist: %s", env_root))
    }
    return(env_root)
  }
  
  config_file <- "scripts/config/data_paths.R"
  if (file.exists(config_file)) {
    source(config_file, local = TRUE)
    if (exists("DATA_ROOT")) {
      if (!dir.exists(DATA_ROOT)) {
        stop(sprintf("DATA_ROOT defined in %s but directory does not exist: %s", config_file, DATA_ROOT))
      }
      return(DATA_ROOT)
    }
  }
  
  stop(paste0(
    "Data root not configured. Please either:\\n",
    "  1. Set environment variable: Sys.setenv(SHRS_DATA_ROOT = '/path/to/data')\\n",
    "  2. Create scripts/config/data_paths.R with: DATA_ROOT <- '/path/to/data'\\n"
  ))
}

# ==============================================================================
# Configuration Object
# ==============================================================================
MARKET_CONFIG <- list(
  data_root = get_data_root(),
  market_data_dir = file.path(get_data_root(), "market"),
  internal_data_dir = file.path(get_data_root(), "internal"),
  output_tables = "output/tables",
  output_figures = "output/figures",
  output_reports = "output/reports",
  cache_dir = "output/.cache",
  FORCE_REBUILD = FALSE,
  programs = c("CSD_SLP", "CSD_AuD", "CSD_UG", "SMN_AT", "SMN_DN", "SMN_SS", "SMN_UG"),
  risk_weights = list(
    labor_demand = 0.35,
    wage_level = 0.25,
    peer_saturation = 0.20,
    credential_pressure = 0.20
  )
)

if (abs(sum(unlist(MARKET_CONFIG$risk_weights)) - 1.0) > 0.001) {
  stop("MARKET_CONFIG$risk_weights must sum to 1.0")
}

# ==============================================================================
# Create Output Directories
# ==============================================================================
for (dir_path in c(MARKET_CONFIG$output_tables, MARKET_CONFIG$output_figures, 
                   MARKET_CONFIG$output_reports, MARKET_CONFIG$cache_dir)) {
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
    message(sprintf("Created directory: %s", dir_path))
  }
}

# ==============================================================================
# Utility Functions
# ==============================================================================

should_rebuild <- function(script_name, input_files) {
  if (MARKET_CONFIG$FORCE_REBUILD) return(TRUE)
  
  cache_file <- file.path(MARKET_CONFIG$cache_dir, 
                          sprintf("market_%s_inputs.json", script_name))
  
  if (!file.exists(cache_file)) return(TRUE)
  
  cache_data <- jsonlite::fromJSON(cache_file)
  
  for (f in input_files) {
    if (!file.exists(f)) return(TRUE)
    
    current_mtime <- as.character(file.info(f)$mtime)
    cached_mtime <- cache_data$input_files[[f]]
    
    if (is.null(cached_mtime) || current_mtime != cached_mtime) {
      return(TRUE)
    }
  }
  
  return(FALSE)
}

save_cache_metadata <- function(script_name, input_files) {
  cache_file <- file.path(MARKET_CONFIG$cache_dir, 
                          sprintf("market_%s_inputs.json", script_name))
  
  metadata <- list(
    script_name = script_name,
    run_timestamp = as.character(Sys.time()),
    input_files = setNames(
      lapply(input_files, function(f) as.character(file.info(f)$mtime)),
      input_files
    )
  )
  
  jsonlite::write_json(metadata, cache_file, pretty = TRUE, auto_unbox = TRUE)
}

write_dual_format <- function(df, base_name, output_dir = MARKET_CONFIG$output_tables) {
  csv_path <- file.path(output_dir, paste0(base_name, ".csv"))
  write.csv(df, csv_path, row.names = FALSE)
  message(sprintf("Wrote: %s", csv_path))
  
  md_path <- file.path(output_dir, paste0(base_name, ".md"))
  sink(md_path)
  cat(sprintf("# %s\\n\\n", base_name))
  cat(sprintf("*Generated: %s*\\n\\n", Sys.time()))
  print(knitr::kable(df, format = "markdown"))
  sink()
  message(sprintf("Wrote: %s", md_path))
}

message("=== Market Analysis Configuration Loaded ===")
message(sprintf("Data Root: %s", MARKET_CONFIG$data_root))
message(sprintf("Force Rebuild: %s", MARKET_CONFIG$FORCE_REBUILD))
message("============================================")
'''

create_file(f"{base_dir}/00_market_config.R", config_content)

# ==============================================================================
# FILE 3: Labor Market Trends
# ==============================================================================
labor_content = '''# ==============================================================================
# Labor Market Trends Analysis
# ==============================================================================
# Purpose: Produce labor market context table for SHRS programs using BLS data
# Inputs:  
#   - DATA_ROOT/market/bls_oews.csv
#   - DATA_ROOT/market/bls_projections.csv
# Outputs: 
#   - output/tables/market_labor_summary.csv|.md
#   - output/figures/labor_market_growth_vs_wage.png
# ==============================================================================

if (!exists("MARKET_CONFIG")) {
  source("analysis/04_market_analysis/00_market_config.R")
}

library(tidyverse)

OEWS_FILE <- file.path(MARKET_CONFIG$market_data_dir, "bls_oews.csv")
PROJ_FILE <- file.path(MARKET_CONFIG$market_data_dir, "bls_projections.csv")

if (!should_rebuild("labor_market_trends", c(OEWS_FILE, PROJ_FILE))) {
  message("=== Labor Market Trends: Cache Valid ===")
  message("Inputs unchanged; skipping rebuild. Set FORCE_REBUILD=TRUE to rerun.")
  quit(save = "no", status = 0)
}

validate_required_columns <- function(df, required_cols, df_name) {
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop(sprintf("%s is missing required columns: %s", df_name, paste(missing_cols, collapse = ", ")))
  }
}

standardize_soc_code <- function(x) {
  x <- gsub("-", "", x)
  x <- str_pad(x, width = 6, side = "right", pad = "0")
  return(x)
}

build_shrs_soc_crosswalk <- function() {
  tibble::tribble(
    ~program,    ~soc_code,  ~occupation_title,
    "CSD_SLP",   "291127",   "Speech-Language Pathologists",
    "CSD_AuD",   "291181",   "Audiologists",
    "CSD_UG",    "291127",   "Speech-Language Pathologists",
    "SMN_AT",    "299091",   "Athletic Trainers",
    "SMN_DN",    "291031",   "Dietitians and Nutritionists",
    "SMN_SS",    "271029",   "Exercise Physiologists and Kinesiotherapists",
    "SMN_UG",    "271029",   "Exercise Physiologists and Kinesiotherapists"
  )
}

if (!file.exists(OEWS_FILE)) {
  template_oews <- tibble::tribble(
    ~soc_code, ~occupation_title, ~employment, ~median_wage_annual, ~data_year,
    "291127", "Speech-Language Pathologists", 145100, 84140, 2023,
    "291181", "Audiologists", 13590, 86490, 2023,
    "299091", "Athletic Trainers", 35330, 51070, 2023,
    "291031", "Dietitians and Nutritionists", 76530, 68650, 2023,
    "271029", "Exercise Physiologists and Kinesiotherapists", 25370, 54730, 2023
  )
  template_path <- file.path(MARKET_CONFIG$output_tables, "bls_oews_TEMPLATE.csv")
  write.csv(template_oews, template_path, row.names = FALSE)
  stop(sprintf("BLS OEWS data file not found: %s\\nA TEMPLATE file has been created: %s", OEWS_FILE, template_path))
}

if (!file.exists(PROJ_FILE)) {
  template_proj <- tibble::tribble(
    ~soc_code, ~occupation_title, ~base_year_employment, ~projected_year_employment, ~change_numeric, ~change_percent, ~base_year, ~projected_year,
    "291127", "Speech-Language Pathologists", 145100, 173600, 28500, 19.6, 2023, 2033,
    "291181", "Audiologists", 13590, 15000, 1410, 10.4, 2023, 2033,
    "299091", "Athletic Trainers", 35330, 39500, 4170, 11.8, 2023, 2033,
    "291031", "Dietitians and Nutritionists", 76530, 85500, 8970, 11.7, 2023, 2033,
    "271029", "Exercise Physiologists and Kinesiotherapists", 25370, 28400, 3030, 11.9, 2023, 2033
  )
  template_path <- file.path(MARKET_CONFIG$output_tables, "bls_projections_TEMPLATE.csv")
  write.csv(template_proj, template_path, row.names = FALSE)
  stop(sprintf("BLS Projections data file not found: %s\\nA TEMPLATE file has been created: %s", PROJ_FILE, template_path))
}

message("Reading BLS data...")
oews_df <- read_csv(OEWS_FILE, show_col_types = FALSE)
validate_required_columns(oews_df, c("soc_code", "occupation_title", "employment", "median_wage_annual"), "BLS OEWS data")

proj_df <- read_csv(PROJ_FILE, show_col_types = FALSE)
validate_required_columns(proj_df, c("soc_code", "occupation_title", "change_percent"), "BLS Projections data")

oews_df <- oews_df %>% mutate(soc_code = standardize_soc_code(soc_code))
proj_df <- proj_df %>% mutate(soc_code = standardize_soc_code(soc_code))

compute_labor_market_summary <- function(oews_df, proj_df, crosswalk_df) {
  labor_data <- crosswalk_df %>%
    left_join(oews_df, by = "soc_code", suffix = c("_program", "_oews")) %>%
    left_join(proj_df %>% select(soc_code, change_percent, base_year, projected_year), by = "soc_code")
  
  grand_median_wage <- median(labor_data$median_wage_annual, na.rm = TRUE)
  
  labor_summary <- labor_data %>%
    mutate(
      wage_index = median_wage_annual / grand_median_wage,
      growth_category = case_when(
        is.na(change_percent) ~ "Unknown",
        change_percent >= 15 ~ "High Growth",
        change_percent >= 8 ~ "Moderate Growth",
        change_percent >= 0 ~ "Slow Growth",
        TRUE ~ "Decline"
      )
    ) %>%
    select(
      program,
      occupation_title = occupation_title_oews,
      employment,
      median_wage_annual,
      wage_index,
      projected_growth_pct = change_percent,
      growth_category,
      projection_period = base_year
    ) %>%
    arrange(desc(projected_growth_pct))
  
  return(labor_summary)
}

message("Computing labor market summary...")
crosswalk <- build_shrs_soc_crosswalk()
labor_summary <- compute_labor_market_summary(oews_df, proj_df, crosswalk)

message("Writing labor market summary tables...")
write_dual_format(labor_summary, "market_labor_summary")

message("Creating growth vs. wage visualization...")
plot_data <- labor_summary %>% filter(!is.na(projected_growth_pct))

p <- ggplot(plot_data, aes(x = median_wage_annual, y = projected_growth_pct)) +
  geom_point(aes(color = growth_category, size = employment), alpha = 0.7) +
  geom_text(aes(label = program), vjust = -0.8, size = 3) +
  scale_color_manual(
    values = c("High Growth" = "#2E7D32", "Moderate Growth" = "#FFA726", 
               "Slow Growth" = "#FDD835", "Decline" = "#D32F2F", "Unknown" = "#757575")
  ) +
  scale_size_continuous(range = c(3, 10), labels = scales::comma) +
  labs(
    title = "Labor Market Outlook: Projected Growth vs. Median Wage",
    subtitle = "SHRS Programs Mapped to BLS Occupational Projections",
    x = "Median Annual Wage ($)",
    y = "Projected 10-Year Employment Growth (%)",
    color = "Growth Category",
    size = "Current Employment",
    caption = sprintf("Source: BLS | Generated: %s", Sys.Date())
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    legend.position = "right"
  )

fig_path <- file.path(MARKET_CONFIG$output_figures, "labor_market_growth_vs_wage.png")
ggsave(fig_path, plot = p, width = 10, height = 6, dpi = 300)
message(sprintf("Wrote: %s", fig_path))

save_cache_metadata("labor_market_trends", c(OEWS_FILE, PROJ_FILE))

message("=== Labor Market Trends Analysis Complete ===")
'''

create_file(f"{base_dir}/01_labor_market_trends.R", labor_content)

# ==============================================================================
# FILE 4: Credential Pressure
# ==============================================================================
credential_content = '''# ==============================================================================
# Credential Pressure Analysis
# ==============================================================================
# Purpose: Track licensure requirements and exam pass rate trends
# Inputs:  DATA_ROOT/market/credential_pressure.csv
# Outputs: output/tables/credential_pressure_summary.csv|.md
# ==============================================================================

if (!exists("MARKET_CONFIG")) {
  source("analysis/04_market_analysis/00_market_config.R")
}

library(tidyverse)

CREDENTIAL_FILE <- file.path(MARKET_CONFIG$market_data_dir, "credential_pressure.csv")

if (!should_rebuild("credential_pressure", c(CREDENTIAL_FILE))) {
  message("=== Credential Pressure: Cache Valid ===")
  message("Inputs unchanged; skipping rebuild.")
  quit(save = "no", status = 0)
}

validate_exam_trends <- function(df) {
  allowed_values <- c("Up", "Stable", "Down", "Unknown")
  invalid_rows <- df %>% filter(!exam_trend %in% allowed_values)
  if (nrow(invalid_rows) > 0) {
    stop(sprintf("Invalid exam_trend values. Allowed: %s", paste(allowed_values, collapse = ", ")))
  }
}

if (!file.exists(CREDENTIAL_FILE)) {
  template_credential <- tibble::tribble(
    ~program, ~licensure_required, ~exam_trend, ~pass_rate_recent, ~scope_of_practice_notes,
    "CSD_SLP", "Yes", "Stable", "95%", "ASHA certification required; no recent scope changes",
    "CSD_AuD", "Yes", "Stable", "92%", "State licensure required; telehealth expansion",
    "CSD_UG", "No", "Unknown", "N/A", "Pipeline program",
    "SMN_AT", "Yes", "Down", "78%", "BOC exam pass rates declining",
    "SMN_DN", "Yes", "Stable", "88%", "RDN credential required",
    "SMN_SS", "No", "Unknown", "N/A", "Varied career paths",
    "SMN_UG", "No", "Unknown", "N/A", "Pipeline program"
  )
  template_path <- file.path(MARKET_CONFIG$output_tables, "credential_pressure_TEMPLATE.csv")
  write.csv(template_credential, template_path, row.names = FALSE)
  stop(sprintf("Credential pressure file not found: %s\\nTEMPLATE created: %s", CREDENTIAL_FILE, template_path))
}

message("Reading credential pressure data...")
credential_df <- read_csv(CREDENTIAL_FILE, show_col_types = FALSE)

validate_required_columns <- function(df, required_cols, df_name) {
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) stop(sprintf("%s missing columns: %s", df_name, paste(missing_cols, collapse = ", ")))
}

validate_required_columns(credential_df, c("program", "licensure_required", "exam_trend", "scope_of_practice_notes"), "Credential pressure data")
validate_exam_trends(credential_df)

message("Processing credential pressure indicators...")
credential_summary <- credential_df %>%
  mutate(
    credential_risk_score = case_when(
      licensure_required == "No" & exam_trend == "Unknown" ~ 0.2,
      licensure_required == "Yes" & exam_trend == "Stable" ~ 0.3,
      licensure_required == "Yes" & exam_trend == "Up" ~ 0.5,
      licensure_required == "Yes" & exam_trend == "Down" ~ 0.6,
      exam_trend == "Unknown" ~ 0.4,
      TRUE ~ 0.3
    ),
    credential_risk_category = case_when(
      credential_risk_score <= 0.25 ~ "Low",
      credential_risk_score <= 0.45 ~ "Moderate",
      TRUE ~ "High"
    )
  ) %>%
  select(program, licensure_required, exam_trend, pass_rate_recent, credential_risk_score, credential_risk_category, scope_of_practice_notes) %>%
  arrange(desc(credential_risk_score))

message("Writing credential pressure summary tables...")
write_dual_format(credential_summary, "credential_pressure_summary")

save_cache_metadata("credential_pressure", c(CREDENTIAL_FILE))

message("=== Credential Pressure Analysis Complete ===")
'''

create_file(f"{base_dir}/02_credential_pressure.R", credential_content)

# ==============================================================================
# FILE 5: Peer Program Supply
# ==============================================================================
peer_content = '''# ==============================================================================
# Peer Program Supply Analysis
# ==============================================================================
# Purpose: Analyze regional peer saturation using IPEDS data
# Inputs:  DATA_ROOT/market/ipeds_program_counts.csv
# Outputs: 
#   - output/tables/peer_program_supply.csv|.md
#   - output/figures/peer_program_supply_bars.png
# ==============================================================================

if (!exists("MARKET_CONFIG")) {
  source("analysis/04_market_analysis/00_market_config.R")
}

library(tidyverse)

IPEDS_FILE <- file.path(MARKET_CONFIG$market_data_dir, "ipeds_program_counts.csv")

if (!should_rebuild("peer_program_supply", c(IPEDS_FILE))) {
  message("=== Peer Program Supply: Cache Valid ===")
  message("Inputs unchanged; skipping rebuild.")
  quit(save = "no", status = 0)
}

validate_required_columns <- function(df, required_cols, df_name) {
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) stop(sprintf("%s missing columns: %s", df_name, paste(missing_cols, collapse = ", ")))
}

if (!file.exists(IPEDS_FILE)) {
  template_ipeds <- tibble::tribble(
    ~region, ~cip_code, ~program_type, ~num_programs, ~total_completions, ~data_year,
    "Mid-Atlantic", "510203", "Speech-Language", 45, 1820, 2023,
    "Mid-Atlantic", "510202", "Audiology", 12, 380, 2023,
    "Mid-Atlantic", "512308", "Athletic Training", 38, 980, 2023,
    "Mid-Atlantic", "513101", "Dietetics", 52, 1450, 2023,
    "Mid-Atlantic", "310505", "Exercise Science", 78, 2340, 2023,
    "Northeast", "510203", "Speech-Language", 62, 2450, 2023,
    "Northeast", "510202", "Audiology", 18, 520, 2023,
    "Northeast", "512308", "Athletic Training", 51, 1340, 2023,
    "Northeast", "513101", "Dietetics", 68, 1920, 2023,
    "Northeast", "310505", "Exercise Science", 95, 3100, 2023
  )
  template_path <- file.path(MARKET_CONFIG$output_tables, "ipeds_program_counts_TEMPLATE.csv")
  write.csv(template_ipeds, template_path, row.names = FALSE)
  stop(sprintf("IPEDS file not found: %s\\nTEMPLATE created: %s", IPEDS_FILE, template_path))
}

message("Reading IPEDS program counts data...")
ipeds_df <- read_csv(IPEDS_FILE, show_col_types = FALSE)
validate_required_columns(ipeds_df, c("region", "program_type", "num_programs", "total_completions"), "IPEDS program counts data")

build_shrs_ipeds_crosswalk <- function() {
  tibble::tribble(
    ~program, ~program_type,
    "CSD_SLP", "Speech-Language",
    "CSD_AuD", "Audiology",
    "CSD_UG", "Speech-Language",
    "SMN_AT", "Athletic Training",
    "SMN_DN", "Dietetics",
    "SMN_SS", "Exercise Science",
    "SMN_UG", "Exercise Science"
  )
}

message("Computing peer saturation index...")
crosswalk <- build_shrs_ipeds_crosswalk()

peer_supply <- crosswalk %>%
  left_join(ipeds_df, by = "program_type") %>%
  filter(!is.na(region)) %>%
  group_by(region) %>%
  mutate(
    saturation_percentile = percent_rank(num_programs),
    saturation_index = case_when(
      saturation_percentile <= 0.33 ~ "Low",
      saturation_percentile <= 0.67 ~ "Medium",
      TRUE ~ "High"
    )
  ) %>%
  ungroup() %>%
  select(program, program_type, region, num_programs, total_completions, saturation_percentile, saturation_index) %>%
  arrange(program, region)

message("Writing peer program supply tables...")
write_dual_format(peer_supply, "peer_program_supply")

message("Creating peer saturation visualization...")
plot_data <- peer_supply %>%
  group_by(program, program_type) %>%
  summarize(avg_num_programs = mean(num_programs, na.rm = TRUE), .groups = "drop") %>%
  arrange(desc(avg_num_programs))

p <- ggplot(plot_data, aes(x = reorder(program, avg_num_programs), y = avg_num_programs)) +
  geom_col(aes(fill = program_type), alpha = 0.8) +
  geom_text(aes(label = round(avg_num_programs, 0)), hjust = -0.2, size = 3.5) +
  coord_flip() +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Peer Program Supply: Average Number of Competing Programs",
    subtitle = "Based on IPEDS Completions Data (Averaged Across Regions)",
    x = "SHRS Program",
    y = "Average Number of Peer Programs",
    fill = "Program Type",
    caption = sprintf("Source: IPEDS | Generated: %s", Sys.Date())
  ) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14), legend.position = "bottom")

fig_path <- file.path(MARKET_CONFIG$output_figures, "peer_program_supply_bars.png")
ggsave(fig_path, plot = p, width = 10, height = 6, dpi = 300)
message(sprintf("Wrote: %s", fig_path))

save_cache_metadata("peer_program_supply", c(IPEDS_FILE))

message("=== Peer Program Supply Analysis Complete ===")
'''

create_file(f"{base_dir}/03_peer_program_supply.R", peer_content)

# ==============================================================================
# FILE 6: Wage vs Cost Context
# ==============================================================================
wage_cost_content = '''# ==============================================================================
# Wage vs. Cost Context Analysis
# ==============================================================================
# Purpose: Compute wage-to-tuition ratio as ROI context indicator
# Inputs:  
#   - output/tables/market_labor_summary.csv
#   - DATA_ROOT/internal/tuition_program_level.csv
# Outputs: 
#   - output/tables/wage_vs_cost_context.csv|.md
#   - output/figures/wage_vs_cost_context.png
# ==============================================================================

if (!exists("MARKET_CONFIG")) {
  source("analysis/04_market_analysis/00_market_config.R")
}

library(tidyverse)

LABOR_SUMMARY_FILE <- file.path(MARKET_CONFIG$output_tables, "market_labor_summary.csv")
TUITION_FILE <- file.path(MARKET_CONFIG$internal_data_dir, "tuition_program_level.csv")

if (!should_rebuild("wage_vs_cost_context", c(LABOR_SUMMARY_FILE, TUITION_FILE))) {
  message("=== Wage vs. Cost Context: Cache Valid ===")
  message("Inputs unchanged; skipping rebuild.")
  quit(save = "no", status = 0)
}

validate_required_columns <- function(df, required_cols, df_name) {
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) stop(sprintf("%s missing columns: %s", df_name, paste(missing_cols, collapse = ", ")))
}

if (!file.exists(LABOR_SUMMARY_FILE)) {
  stop(sprintf("Labor market summary not found: %s\\nPlease run 01_labor_market_trends.R first", LABOR_SUMMARY_FILE))
}

if (!file.exists(TUITION_FILE)) {
  template_tuition <- tibble::tribble(
    ~program, ~program_length_years, ~annual_tuition, ~total_program_cost, ~academic_year,
    "CSD_SLP", 2.0, 32500, 65000, "2024-25",
    "CSD_AuD", 4.0, 31200, 124800, "2024-25",
    "CSD_UG", 4.0, 20500, 82000, "2024-25",
    "SMN_AT", 2.0, 29800, 59600, "2024-25",
    "SMN_DN", 2.0, 28900, 57800, "2024-25",
    "SMN_SS", 2.0, 28900, 57800, "2024-25",
    "SMN_UG", 4.0, 20500, 82000, "2024-25"
  )
  template_path <- file.path(MARKET_CONFIG$output_tables, "tuition_program_level_TEMPLATE.csv")
  write.csv(template_tuition, template_path, row.names = FALSE)
  stop(sprintf("Tuition file not found: %s\\nTEMPLATE created: %s", TUITION_FILE, template_path))
}

message("Reading data...")
labor_df <- read_csv(LABOR_SUMMARY_FILE, show_col_types = FALSE)
tuition_df <- read_csv(TUITION_FILE, show_col_types = FALSE)

validate_required_columns(tuition_df, c("program", "total_program_cost"), "Tuition data")

message("Computing wage vs. cost context...")
wage_cost <- labor_df %>%
  select(program, median_wage_annual, wage_index) %>%
  left_join(tuition_df %>% select(program, total_program_cost, program_length_years, academic_year), by = "program")

wage_cost_context <- wage_cost %>%
  mutate(
    wage_to_cost_ratio = median_wage_annual / total_program_cost,
    tuition_index = total_program_cost / mean(total_program_cost, na.rm = TRUE),
    context_category = case_when(
      wage_to_cost_ratio >= 1.2 ~ "Favorable",
      wage_to_cost_ratio >= 0.9 ~ "Moderate",
      TRUE ~ "Challenging"
    )
  ) %>%
  select(program, median_wage_annual, total_program_cost, program_length_years, wage_to_cost_ratio, wage_index, tuition_index, context_category, academic_year) %>%
  arrange(desc(wage_to_cost_ratio))

message("Writing wage vs. cost context tables...")
write_dual_format(wage_cost_context, "wage_vs_cost_context")

message("Creating visualization...")
p <- ggplot(wage_cost_context, aes(x = tuition_index, y = wage_index)) +
  geom_point(aes(color = context_category, size = wage_to_cost_ratio), alpha = 0.7) +
  geom_text(aes(label = program), vjust = -1, size = 3) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50", alpha = 0.5) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50", alpha = 0.5) +
  scale_color_manual(values = c("Favorable" = "#2E7D32", "Moderate" = "#FFA726", "Challenging" = "#D32F2F")) +
  scale_size_continuous(range = c(3, 10)) +
  labs(
    title = "Wage vs. Cost Context: Market Attractiveness Indicator",
    subtitle = "Wage Index vs. Tuition Index (Both Relative to Mean = 1.0)",
    x = "Tuition Index",
    y = "Wage Index",
    color = "Context Category",
    size = "Wage-to-Cost Ratio",
    caption = sprintf("Source: BLS + SHRS Tuition | Generated: %s", Sys.Date())
  ) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", size = 14), legend.position = "right")

fig_path <- file.path(MARKET_CONFIG$output_figures, "wage_vs_cost_context.png")
ggsave(fig_path, plot = p, width = 10, height = 6, dpi = 300)
message(sprintf("Wrote: %s", fig_path))

save_cache_metadata("wage_vs_cost_context", c(LABOR_SUMMARY_FILE, TUITION_FILE))

message("=== Wage vs. Cost Context Analysis Complete ===")
'''

create_file(f"{base_dir}/04_wage_vs_cost_context.R", wage_cost_content)

# ==============================================================================
# FILE 7: Market Risk Index
# ==============================================================================
risk_index_content = '''# ==============================================================================
# Market Risk Index Composite
# ==============================================================================
# Purpose: Build composite market risk index from all components
# Inputs:  
#   - output/tables/market_labor_summary.csv
#   - output/tables/credential_pressure_summary.csv
#   - output/tables/peer_program_supply.csv
# Outputs: output/tables/market_risk_index.csv|.md
# ==============================================================================

if (!exists("MARKET_CONFIG")) {
  source("analysis/04_market_analysis/00_market_config.R")
}

library(tidyverse)

LABOR_SUMMARY_FILE <- file.path(MARKET_CONFIG$output_tables, "market_labor_summary.csv")
CREDENTIAL_FILE <- file.path(MARKET_CONFIG$output_tables, "credential_pressure_summary.csv")
PEER_SUPPLY_FILE <- file.path(MARKET_CONFIG$output_tables, "peer_program_supply.csv")

if (!should_rebuild("market_risk_index", c(LABOR_SUMMARY_FILE, CREDENTIAL_FILE, PEER_SUPPLY_FILE))) {
  message("=== Market Risk Index: Cache Valid ===")
  message("Inputs unchanged; skipping rebuild.")
  quit(save = "no", status = 0)
}

required_files <- list(labor = LABOR_SUMMARY_FILE, credential = CREDENTIAL_FILE, peer = PEER_SUPPLY_FILE)
for (file_type in names(required_files)) {
  if (!file.exists(required_files[[file_type]])) {
    stop(sprintf("%s file not found: %s\\nPlease run the corresponding script first", file_type, required_files[[file_type]]))
  }
}

message("Reading component files...")
labor_df <- read_csv(LABOR_SUMMARY_FILE, show_col_types = FALSE)
credential_df <- read_csv(CREDENTIAL_FILE, show_col_types = FALSE)
peer_df <- read_csv(PEER_SUPPLY_FILE, show_col_types = FALSE)

message("Standardizing risk components...")
labor_risk <- labor_df %>%
  select(program, projected_growth_pct, wage_index) %>%
  mutate(
    labor_demand_risk = case_when(
      is.na(projected_growth_pct) ~ 0.5,
      projected_growth_pct >= 15 ~ 0.1,
      projected_growth_pct >= 8 ~ 0.3,
      projected_growth_pct >= 0 ~ 0.6,
      TRUE ~ 0.9
    ),
    wage_level_risk = 1 - pmin(wage_index / max(wage_index, na.rm = TRUE), 1.0)
  ) %>%
  select(program, labor_demand_risk, wage_level_risk)

credential_risk <- credential_df %>%
  select(program, credential_pressure_risk = credential_risk_score)

peer_risk <- peer_df %>%
  group_by(program) %>%
  summarize(avg_saturation_percentile = mean(saturation_percentile, na.rm = TRUE), .groups = "drop") %>%
  mutate(peer_saturation_risk = avg_saturation_percentile) %>%
  select(program, peer_saturation_risk)

message("Computing composite market risk index...")
weights <- MARKET_CONFIG$risk_weights

market_risk <- labor_risk %>%
  left_join(credential_risk, by = "program") %>%
  left_join(peer_risk, by = "program") %>%
  mutate(
    market_risk_index = 
      (labor_demand_risk * weights$labor_demand) +
      (wage_level_risk * weights$wage_level) +
      (peer_saturation_risk * weights$peer_saturation) +
      (credential_pressure_risk * weights$credential_pressure),
    risk_category = case_when(
      market_risk_index <= 0.35 ~ "Low Risk",
      market_risk_index <= 0.55 ~ "Moderate Risk",
      TRUE ~ "High Risk"
    )
  ) %>%
  select(program, market_risk_index, risk_category, labor_demand_risk, wage_level_risk, peer_saturation_risk, credential_pressure_risk) %>%
  arrange(desc(market_risk_index))

market_risk_final <- market_risk %>%
  mutate(
    index_version = "1.0",
    generated_date = as.character(Sys.Date()),
    disclaimer = "Contextual indicator only; not a decision rule."
  )

message("Writing market risk index tables...")
write_dual_format(market_risk_final %>% select(-disclaimer), "market_risk_index")

weights_doc <- tibble::tribble(
  ~component, ~weight, ~description,
  "Labor Demand", weights$labor_demand, "BLS 10-year employment growth outlook",
  "Wage Level", weights$wage_level, "Median wage relative to benchmark",
  "Peer Saturation", weights$peer_saturation, "Regional program supply density",
  "Credential Pressure", weights$credential_pressure, "Licensure and exam uncertainty"
)

weights_path <- file.path(MARKET_CONFIG$output_tables, "market_risk_index_weights.csv")
write.csv(weights_doc, weights_path, row.names = FALSE)
message(sprintf("Wrote: %s", weights_path))

message("\\n=== Market Risk Index Summary ===")
message(sprintf("Index Version: %s", market_risk_final$index_version[1]))
message(sprintf("Generated: %s", market_risk_final$generated_date[1]))
message("\\nRisk Distribution:")
print(table(market_risk_final$risk_category))
message("\\nTop 3 Highest Risk Programs:")
print(market_risk_final %>% select(program, market_risk_index, risk_category) %>% head(3))
message("\\nComponent Weights Used:")
print(weights_doc)
message("\\nDISCLAIMER: Contextual indicator only; not a decision rule.")
message("=================================")

save_cache_metadata("market_risk_index", c(LABOR_SUMMARY_FILE, CREDENTIAL_FILE, PEER_SUPPLY_FILE))

message("=== Market Risk Index Computation Complete ===")
'''

create_file(f"{base_dir}/05_market_risk_index.R", risk_index_content)

# ==============================================================================
# COMPLETION MESSAGE
# ==============================================================================
print("\n" + "="*70)
print("SUCCESS! All 7 files created in analysis/04_market_analysis/")
print("="*70)
print("\nFiles created:")
print("  1. README_market_analysis.md")
print("  2. 00_market_config.R")
print("  3. 01_labor_market_trends.R")
print("  4. 02_credential_pressure.R")
print("  5. 03_peer_program_supply.R")
print("  6. 04_wage_vs_cost_context.R")
print("  7. 05_market_risk_index.R")
print("\nNext steps:")
print("  - Review the README_market_analysis.md file")
print("  - Configure your data paths (see README for instructions)")
print("  - Run scripts in numbered order when you have data")
print("="*70)