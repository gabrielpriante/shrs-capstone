# ==============================================================================
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
  stop(sprintf("Labor market summary not found: %s\nPlease run 01_labor_market_trends.R first", LABOR_SUMMARY_FILE))
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
  stop(sprintf("Tuition file not found: %s\nTEMPLATE created: %s", TUITION_FILE, template_path))
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
