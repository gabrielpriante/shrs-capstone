# ==============================================================================
# Exploratory Analysis Script - SHRS Program Health Analysis
# ==============================================================================
# This script demonstrates exploratory analysis and trend visualization
# for the SHRS Program Health evaluation
#
# Supports two modes:
#   1. External data: Reads from secure locations via scripts/config/data_paths.R
#   2. Mock data: Uses cleaned data from previous script or generates new mock data
#
# Input: Cleaned data from external location OR mock data OR global environment
# Output: output/figures/ and output/tables/ (illustrative templates)
# Last Updated: January 2026
# ==============================================================================

# ==============================================================================
# REQUIRED PACKAGES
# ==============================================================================
library(tidyverse)   # Includes ggplot2, dplyr, tidyr, readr, etc.
library(here)
library(fixest)      # For fixed-effects estimation
library(modelsummary) # For regression tables
library(gt)          # For table formatting

# Set seed for reproducibility
set.seed(123)

# ==============================================================================
# LOAD DATA PATHS CONFIGURATION
# ==============================================================================

# Load the data paths loader
source(here("scripts", "config", "load_data_paths.R"))

# Load paths (will return mock mode flag if SHRS_USE_MOCK_DATA=1)
paths <- load_data_paths()

# ==============================================================================
# 1. LOAD PROCESSED DATA
# ==============================================================================

message("Loading processed data...")

if (paths$use_mock) {
  # MOCK MODE: Check if data was created by previous script
  if (exists("cleaned_enrollment_data")) {
    message("  Using cleaned data from previous script (global environment)")
    analysis_data <- cleaned_enrollment_data
  } else {
    message("  Generating new mock data...")
    source(here("scripts", "utils", "mock_data.R"))
    mock_data <- generate_mock_program_health_data()
    analysis_data <- mock_data$enrollment
  }
  
} else {
  # EXTERNAL DATA MODE: Read from external location
  message("  Loading from external processed data location...")
  
  if (!is.null(paths$PROCESSED_DATA_PATH)) {
    cleaned_file <- file.path(paths$PROCESSED_DATA_PATH, "cleaned_enrollment.rds")
    
    if (file.exists(cleaned_file)) {
      analysis_data <- readRDS(cleaned_file)
      message("  ✓ Loaded cleaned enrollment data")
    } else {
      stop("Cleaned data file not found: ", cleaned_file, 
           "\nRun scripts/01_data_cleaning.R first")
    }
  } else {
    stop("PROCESSED_DATA_PATH not configured in data_paths.R")
  }
}

message("  - Analysis sample: ", nrow(analysis_data), " observations")
if ("program_code" %in% names(analysis_data)) {
  message("  - Programs: ", paste(unique(analysis_data$program_code), collapse = ", "))
}
if ("academic_year" %in% names(analysis_data)) {
  message("  - Years: ", min(analysis_data$academic_year), " to ", max(analysis_data$academic_year))
}

# ==============================================================================
# 2. DESCRIPTIVE STATISTICS
# ==============================================================================

message("\nGenerating descriptive statistics...")

# Ensure required columns exist and calculate total_revenue if needed
if (!"total_revenue" %in% names(analysis_data) && "tuition_revenue" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>%
    mutate(total_revenue = tuition_revenue)
} else if (!"total_revenue" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>%
    mutate(total_revenue = enrolled * revenue_per_student)
}

# Ensure program_category exists
if (!"program_category" %in% names(analysis_data) && "program_code" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>%
    mutate(
      program_category = case_when(
        program_code %in% c("SLP", "AuD", "CSD_UG") ~ "Communication Science & Disorders",
        program_code %in% c("AT", "DN", "SS", "SMN_UG") ~ "Sports Medicine & Nutrition",
        TRUE ~ "Other"
      )
    )
}

# Summary statistics by program category
desc_stats <- analysis_data %>%
  group_by(program_category) %>%
  summarise(
    n_programs = n_distinct(program_code),
    avg_enrollment = mean(enrolled, na.rm = TRUE),
    sd_enrollment = sd(enrolled, na.rm = TRUE),
    avg_revenue_per_student = mean(revenue_per_student, na.rm = TRUE),
    total_revenue_sum = sum(total_revenue, na.rm = TRUE),
    .groups = "drop"
  )

print(desc_stats)

# ==============================================================================
# 3. VISUALIZATION - ENROLLMENT TRENDS
# ==============================================================================

message("\nCreating visualizations...")

# Create output directories if they don't exist
dir.create(here("output", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output", "tables"), recursive = TRUE, showWarnings = FALSE)

# Plot 1: Enrollment trends by program
p1 <- ggplot(analysis_data, aes(x = academic_year, y = enrolled, color = program_code)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  facet_wrap(~program_category, ncol = 1, scales = "free_y") +
  theme_minimal() +
  theme(legend.position = "bottom") +
  labs(
    title = "Enrollment Trends by Program (2018-2023)",
    subtitle = "SHRS Program Health Analysis - Illustrative Template",
    x = "Academic Year",
    y = "Enrolled Students",
    color = "Program",
    caption = "Note: This is an illustrative template using placeholder data"
  ) +
  scale_color_brewer(palette = "Set2")

ggsave(
  here("output", "figures", "enrollment_trends.png"),
  plot = p1,
  width = 10,
  height = 8,
  dpi = 300
)

# Plot 2: Revenue per student by program
p2 <- ggplot(analysis_data, aes(x = program_code, y = revenue_per_student, fill = program_category)) +
  geom_boxplot(alpha = 0.7) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "top"
  ) +
  labs(
    title = "Revenue per Student Distribution by Program",
    subtitle = "SHRS Program Health Analysis - Illustrative Template",
    x = "Program Code",
    y = "Revenue per Student ($)",
    fill = "Program Category",
    caption = "Note: This is an illustrative template using placeholder data"
  ) +
  scale_fill_brewer(palette = "Set1") +
  scale_y_continuous(labels = scales::dollar_format())

ggsave(
  here("output", "figures", "revenue_per_student.png"),
  plot = p2,
  width = 10,
  height = 6,
  dpi = 300
)

message("  ✓ Figures saved to output/figures/")

# ==============================================================================
# 4. TREND ANALYSIS
# ==============================================================================

message("\nPerforming trend analysis...")

# Calculate year-over-year growth rates by program
growth_analysis <- analysis_data %>%
  group_by(program_code) %>%
  arrange(academic_year) %>%
  mutate(
    enrollment_yoy_change = enrolled - lag(enrolled),
    enrollment_yoy_pct = (enrolled - lag(enrolled)) / lag(enrolled) * 100
  ) %>%
  summarise(
    avg_annual_growth_pct = mean(enrollment_yoy_pct, na.rm = TRUE),
    total_enrollment_change = last(enrolled) - first(enrolled),
    .groups = "drop"
  )

print("Average Annual Enrollment Growth by Program:")
print(growth_analysis)

# ==============================================================================
# 5. CREATE SUMMARY TABLE
# ==============================================================================

message("\nCreating summary tables...")

# Program summary table
program_summary <- analysis_data %>%
  group_by(program_category, program_code) %>%
  summarise(
    years_observed = n_distinct(academic_year),
    avg_enrollment = round(mean(enrolled, na.rm = TRUE), 1),
    total_revenue_6yr = sum(total_revenue, na.rm = TRUE),
    avg_revenue_per_student = round(mean(revenue_per_student, na.rm = TRUE), 0),
    .groups = "drop"
  ) %>%
  arrange(program_category, program_code)

# Save as CSV
write_csv(program_summary, here("output", "tables", "program_summary.csv"))

# Create formatted HTML table
library(gt)

program_summary %>%
  gt() %>%
  tab_header(
    title = "SHRS Program Summary Statistics",
    subtitle = "Illustrative Template - 2018-2023"
  ) %>%
  fmt_number(
    columns = avg_enrollment,
    decimals = 1
  ) %>%
  fmt_currency(
    columns = c(total_revenue_6yr, avg_revenue_per_student),
    decimals = 0
  ) %>%
  tab_footnote(
    footnote = "This is an illustrative template using placeholder data"
  ) %>%
  gtsave(here("output", "tables", "program_summary.html"))

message("  ✓ Tables saved to output/tables/")

# ==============================================================================
# SCRIPT COMPLETE
# ==============================================================================

message("\n=== Exploratory analysis complete! ===")
message("Key outputs:")
message("  - Figures: output/figures/enrollment_trends.png, revenue_per_student.png")
message("  - Tables: output/tables/program_summary.csv, program_summary.html")

if (paths$use_mock) {
  message("\nREMINDER: Using mock data for demonstration purposes")
  message("To analyze real data: configure scripts/config/data_paths.R")
} else {
  message("\nREMINDER: These outputs are illustrative templates, not final decisions")
}

message("Next steps: Develop financial analysis and scenario planning scripts")
