# ==============================================================================
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
    stop(sprintf("%s file not found: %s\nPlease run the corresponding script first", file_type, required_files[[file_type]]))
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

message("\n=== Market Risk Index Summary ===")
message(sprintf("Index Version: %s", market_risk_final$index_version[1]))
message(sprintf("Generated: %s", market_risk_final$generated_date[1]))
message("\nRisk Distribution:")
print(table(market_risk_final$risk_category))
message("\nTop 3 Highest Risk Programs:")
print(market_risk_final %>% select(program, market_risk_index, risk_category) %>% head(3))
message("\nComponent Weights Used:")
print(weights_doc)
message("\nDISCLAIMER: Contextual indicator only; not a decision rule.")
message("=================================")

save_cache_metadata("market_risk_index", c(LABOR_SUMMARY_FILE, CREDENTIAL_FILE, PEER_SUPPLY_FILE))

message("=== Market Risk Index Computation Complete ===")
