# =========================================================================
# competitor_02_tuition_pull.R
# SHRS Competitor Analysis - Step 2: Pull Tuition Data
# =========================================================================
#
# WHAT THIS FILE DOES:
#   1. Reads the master_roster.csv from Step 1
#   2. Pulls GRADUATE tuition (in-state + out-of-state) from IPEDS API
#   3. Pivots the data wide (tuition_type rows -> in_state/out_of_state cols)
#   4. Joins tuition to Tier 1 and Tier 2 competitor lists
#   5. Builds a Pitt vs. competitors comparison table
#   6. Saves everything as CSVs
#
# REQUIRES:
#   competitor_data/ folder from competitor_01_pull.R
#
# HOW TO RUN:
#   source("competitor_02_tuition_pull.R")
#   Takes ~1-2 minutes (2 API calls for PA tuition 2020-2021).
#
# OUTPUTS (saved to competitor_data/):
#   tuition_raw.csv            - Raw tuition API data
#   tuition_latest.csv         - Graduate tuition, latest year, wide format
#   tier1_with_tuition.csv     - Tier 1 competitors + tuition
#   tier2_with_tuition.csv     - Tier 2 competitors + tuition
#   tuition_comparison.csv     - Pitt vs competitor avg/med/min/max
#
# NOTES:
#   - IPEDS tuition is institution-level, not program-specific
#   - The API uses tuition_type: 2=in-district, 3=in-state, 4=out-of-state
#   - level_of_study: 1=undergrad, 2=graduate
#   - Tuition endpoint only goes through 2021 (2022 not available)
#
# =========================================================================


# ---- 0. PACKAGES --------------------------------------------------------

library(tidyverse)
library(educationdata)

cat("\n====================================\n")
cat("SHRS Competitor Tuition Pull\n")
cat("====================================\n\n")


# ---- 1. LOAD STEP 1 DATA -----------------------------------------------

DATA_DIR <- "competitor_data"

master_roster <- read_csv(file.path(DATA_DIR, "master_roster.csv"), show_col_types = FALSE)
tier1         <- read_csv(file.path(DATA_DIR, "tier1_statewide.csv"), show_col_types = FALSE)
tier2         <- read_csv(file.path(DATA_DIR, "tier2_regional.csv"), show_col_types = FALSE)

PITT_UNITID <- 215293L

all_unitids <- unique(master_roster$unitid)
cat("Institutions to look up:", length(all_unitids), "\n\n")


# ---- 2. PULL TUITION DATA FROM IPEDS API --------------------------------
# academic-year-tuition endpoint, PA only, 2020-2021
# (2022 is not available for this endpoint)

cat("Pulling tuition data from IPEDS API...\n")

tuition_raw_list <- list()

for (yr in 2019:2021) {
  cat("  Year", yr, "...\n")

  result <- tryCatch({
    get_education_data(
      level   = "college-university",
      source  = "ipeds",
      topic   = "academic-year-tuition",
      filters = list(year = yr, fips = 42),
      add_labels = FALSE
    )
  }, error = function(e) {
    cat("    ERROR:", e$message, "\n")
    return(NULL)
  })

  if (!is.null(result) && nrow(result) > 0) {
    tuition_raw_list[[length(tuition_raw_list) + 1]] <- result
  }
}

tuition_raw <- bind_rows(tuition_raw_list)
cat("\nRaw tuition rows:", nrow(tuition_raw), "\n\n")


# ---- 3. CLEAN: PIVOT TO WIDE FORMAT ------------------------------------
# The API returns tuition_type as rows:
#   2 = in-district
#   3 = in-state
#   4 = out-of-state
# We want columns. We filter to graduate level (level_of_study == 2).

cat("Pivoting to wide format (graduate tuition only)...\n")

tuition_clean <- tuition_raw |>
  mutate(unitid = as.integer(unitid)) |>
  filter(unitid %in% all_unitids)

tuition_wide <- tuition_clean |>
  filter(level_of_study == 2) |>
  select(unitid, year, tuition_type, tuition_fees_ft) |>
  pivot_wider(
    names_from  = tuition_type,
    values_from = tuition_fees_ft,
    names_prefix = "type_"
  ) |>
  rename(
    tuition_in_state     = type_3,
    tuition_out_of_state = type_4
  ) |>
  select(unitid, year, tuition_in_state, tuition_out_of_state)

latest_tuition_year <- max(tuition_wide$year, na.rm = TRUE)
cat("  Latest tuition year:", latest_tuition_year, "\n")

tuition_latest <- tuition_wide |> filter(year == latest_tuition_year)
cat("  Institutions with graduate tuition:", nrow(tuition_latest), "\n")

# Pitt check
pitt_t <- tuition_latest |> filter(unitid == PITT_UNITID)
if (nrow(pitt_t) > 0) {
  cat("  Pitt in-state:", scales::dollar(pitt_t$tuition_in_state), "\n")
  cat("  Pitt out-of-state:", scales::dollar(pitt_t$tuition_out_of_state), "\n\n")
} else {
  cat("  WARNING: No tuition data found for Pitt\n\n")
}


# ---- 4. JOIN TUITION TO COMPETITOR TIERS --------------------------------

cat("Joining tuition to competitor rosters...\n")

tier1_tuition <- tier1 |>
  left_join(
    tuition_latest |> select(unitid, tuition_in_state, tuition_out_of_state),
    by = "unitid"
  ) |>
  mutate(is_pitt = unitid == PITT_UNITID)

tier2_tuition <- tier2 |>
  left_join(
    tuition_latest |> select(unitid, tuition_in_state, tuition_out_of_state),
    by = "unitid"
  ) |>
  mutate(is_pitt = unitid == PITT_UNITID)

t1_has <- sum(!is.na(tier1_tuition$tuition_in_state))
t1_miss <- sum(is.na(tier1_tuition$tuition_in_state))
cat("  Tier 1:", t1_has, "with tuition,", t1_miss, "missing\n")
cat("  Tier 2:", nrow(tier2_tuition), "rows\n\n")


# ---- 5. PITT VS COMPETITORS COMPARISON ---------------------------------

cat("Building tuition comparison...\n")

tuition_comparison <- tier1_tuition |>
  filter(!is.na(tuition_in_state)) |>
  group_by(shrs_program) |>
  summarise(
    n_schools         = n(),
    pitt_in_state     = max(tuition_in_state[is_pitt], na.rm = TRUE),
    pitt_out_of_state = max(tuition_out_of_state[is_pitt], na.rm = TRUE),
    avg_in_state      = round(mean(tuition_in_state[!is_pitt], na.rm = TRUE)),
    med_in_state      = round(median(tuition_in_state[!is_pitt], na.rm = TRUE)),
    min_in_state      = min(tuition_in_state[!is_pitt], na.rm = TRUE),
    max_in_state      = max(tuition_in_state[!is_pitt], na.rm = TRUE),
    avg_out_of_state  = round(mean(tuition_out_of_state[!is_pitt], na.rm = TRUE)),
    med_out_of_state  = round(median(tuition_out_of_state[!is_pitt], na.rm = TRUE)),
    .groups           = "drop"
  ) |>
  mutate(
    pitt_in_state     = if_else(is.infinite(pitt_in_state), NA_real_, pitt_in_state),
    pitt_out_of_state = if_else(is.infinite(pitt_out_of_state), NA_real_, pitt_out_of_state),
    pitt_vs_avg_in    = round(pitt_in_state - avg_in_state),
    pitt_vs_med_in    = round(pitt_in_state - med_in_state)
  )

cat("\n  Tuition Comparison (Graduate, In-State):\n")
print(as.data.frame(
  tuition_comparison |>
    select(shrs_program, n_schools, pitt_in_state, avg_in_state,
           med_in_state, min_in_state, max_in_state, pitt_vs_avg_in)
))
cat("\n")


# ---- 6. SAVE EVERYTHING ------------------------------------------------

cat("Saving CSVs to", DATA_DIR, "...\n")

write_csv(tuition_raw,        file.path(DATA_DIR, "tuition_raw.csv"))
write_csv(tuition_latest,     file.path(DATA_DIR, "tuition_latest.csv"))
write_csv(tier1_tuition,      file.path(DATA_DIR, "tier1_with_tuition.csv"))
write_csv(tier2_tuition,      file.path(DATA_DIR, "tier2_with_tuition.csv"))
write_csv(tuition_comparison, file.path(DATA_DIR, "tuition_comparison.csv"))

cat("\nFiles saved:\n")
list.files(DATA_DIR, pattern = "tuition") |> walk(~ cat("  ", .x, "\n"))

cat("\n====================================\n")
cat("DONE. Tuition data saved.\n")
cat("====================================\n")
