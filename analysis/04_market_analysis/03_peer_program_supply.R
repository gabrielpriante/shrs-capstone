# ==============================================================================
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
  stop(sprintf("IPEDS file not found: %s\nTEMPLATE created: %s", IPEDS_FILE, template_path))
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
