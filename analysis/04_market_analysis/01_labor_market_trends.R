# ==============================================================================
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
  stop(sprintf("BLS OEWS data file not found: %s\nA TEMPLATE file has been created: %s", OEWS_FILE, template_path))
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
  stop(sprintf("BLS Projections data file not found: %s\nA TEMPLATE file has been created: %s", PROJ_FILE, template_path))
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
