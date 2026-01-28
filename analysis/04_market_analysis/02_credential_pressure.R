# ==============================================================================
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
  stop(sprintf("Credential pressure file not found: %s\nTEMPLATE created: %s", CREDENTIAL_FILE, template_path))
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
