# =========================================================================
# competitor_01_pull.R
# SHRS Competitor Analysis - Step 1: Pull & Identify Competitors
# =========================================================================
#
# WHAT THIS FILE DOES:
#   1. Defines the CIP code crosswalk for all 9 SHRS programs
#   2. Pulls PA completions data from the IPEDS API (via Urban Institute)
#   3. Pulls the PA institution directory (names, cities, counties)
#   4. Builds Tier 1 (all PA) and Tier 2 (Pittsburgh-Erie) competitor lists
#   5. Saves everything as CSVs you can use anywhere
#
# HOW TO RUN:
#   Open in RStudio, then: source("competitor_01_pull.R")
#   Or just hit Ctrl+Shift+Enter to run the whole file.
#   Takes ~5 minutes (API pulls for PA only).
#
# OUTPUTS (saved to same folder as this script):
#   competitor_data/cip_crosswalk.csv          - CIP to program mapping
#   competitor_data/pa_completions_raw.csv     - Raw API data for PA
#   competitor_data/pa_institutions.csv        - PA institution directory
#   competitor_data/tier1_statewide.csv        - All PA competitors by program
#   competitor_data/tier2_regional.csv         - Pittsburgh-Erie competitors
#   competitor_data/tier1_summary.csv          - Tier 1 counts and Pitt share
#   competitor_data/tier2_summary.csv          - Tier 2 counts and Pitt share
#   competitor_data/master_roster.csv          - Combined roster with tier flags
#   competitor_data/pitt_rank.csv              - Pitt's rank per program in PA
#
# DEPENDENCIES:
#   install.packages(c("tidyverse", "educationdata"))
#
# CHANGELOG:
#   v2 - Fixed city_name -> city for directory endpoint
#      - Fixed degree_levels to include award levels 8, 9, 22, 23
#        (professional doctorates, post-masters certs used by many programs)
#
# =========================================================================


# ---- 0. PACKAGES --------------------------------------------------------

library(tidyverse)
library(educationdata)

cat("\n====================================\n")
cat("SHRS Competitor Identification\n")
cat("====================================\n\n")


# ---- 1. CONSTANTS & CROSSWALK -------------------------------------------

PITT_UNITID <- 215293L
PA_FIPS     <- 42L

# Award levels we care about
# The Urban Institute API uses these codes:
#   5  = Bachelor's
#   6  = Post-baccalaureate Certificate
#   7  = Master's
#   8  = Post-Master's Certificate
#   9  = Doctor's - Research/Scholarship
#   17 = Doctor's - Professional Practice (old coding)
#   18 = Doctor's - Research/Scholarship (old coding)
#   19 = Doctor's - Other (old coding)
#   22 = Doctor's - Research/Scholarship (new coding)
#   23 = Doctor's - Professional Practice (new coding, used by DPT, OTD, AuD, etc.)
degree_levels <- c(5L, 6L, 7L, 8L, 9L, 17L, 18L, 19L, 22L, 23L)

degree_labels <- tribble(
  ~award_level, ~degree_group,
  5L,           "Bachelors",
  6L,           "Post-Bacc Certificate",
  7L,           "Masters",
  8L,           "Post-Masters Certificate",
  9L,           "Doctorate",
  17L,          "Doctorate",
  18L,          "Doctorate",
  19L,          "Doctorate",
  22L,          "Doctorate",
  23L,          "Doctorate"
)

# All 9 SHRS programs mapped to their CIP codes and SOC codes
cip_crosswalk <- tribble(
  ~shrs_program, ~shrs_dept, ~soc_code,  ~cip_6digit, ~cip_display, ~cip_title,
  "SLP",         "CSD",      "29-1127",  510203L,     "51.0203",    "Speech-Language Pathology/Pathologist",
  "SLP",         "CSD",      "29-1127",  510204L,     "51.0204",    "Audiology/Audiologist and SLP (Combined)",
  "AuD",         "CSD",      "29-1181",  510202L,     "51.0202",    "Audiology/Audiologist",
  "AuD",         "CSD",      "29-1181",  510204L,     "51.0204",    "Audiology/Audiologist and SLP (Combined)",
  "DN",          "SMN",      "29-1031",  513101L,     "51.3101",    "Dietetics/Dietitian",
  "DN",          "SMN",      "29-1031",  513104L,     "51.3104",    "Dietitian Assistant",
  "AT",          "SMN",      "29-9091",  510913L,     "51.0913",    "Athletic Training/Trainer",
  "SS",          "SMN",      "29-1128",  260908L,     "26.0908",    "Exercise Physiology and Kinesiology",
  "SS",          "SMN",      "29-1128",  310505L,     "31.0505",    "Kinesiology and Exercise Science",
  "OTD",         "RST",      "29-1122",  512306L,     "51.2306",    "Occupational Therapy/Therapist",
  "DPT",         "RST",      "29-1123",  512308L,     "51.2308",    "Physical Therapy/Therapist",
  "PAS",         "PAS",      "29-1071",  510912L,     "51.0912",    "Physician Assistant",
  "HIM",         "HIM",      "29-9021",  510706L,     "51.0706",    "Health Info/Medical Records Admin",
  "HIM",         "HIM",      "29-9021",  510707L,     "51.0707",    "Health Info/Medical Records Tech"
)

target_cips <- unique(cip_crosswalk$cip_6digit)
cat("Programs:", paste(unique(cip_crosswalk$shrs_program), collapse = ", "), "\n")
cat("CIP codes:", length(target_cips), "\n\n")


# ---- 2. CREATE OUTPUT FOLDER -------------------------------------------

output_dir <- "competitor_data"
if (!dir.exists(output_dir)) dir.create(output_dir)
cat("Output folder:", output_dir, "\n\n")


# ---- 3. PULL PA COMPLETIONS FROM IPEDS API ------------------------------
# One CIP x year at a time. PA only, so this is fast.

cat("Pulling PA completions from IPEDS API...\n")

pull_grid <- expand.grid(
  cip  = target_cips,
  year = 2020:2022,
  stringsAsFactors = FALSE
)

cat("  ", nrow(pull_grid), "API calls to make\n")

raw_list <- list()

for (i in seq_len(nrow(pull_grid))) {
  cip <- pull_grid$cip[i]
  yr  <- pull_grid$year[i]
  cat("  [", i, "/", nrow(pull_grid), "] CIP", cip, "/ year", yr, "\n")

  result <- tryCatch({
    get_education_data(
      level   = "college-university",
      source  = "ipeds",
      topic   = "completions-cip-6",
      filters = list(year = yr, fips = PA_FIPS, cipcode_6digit = cip),
      add_labels = FALSE
    )
  }, error = function(e) {
    cat("    ERROR:", e$message, "\n")
    return(NULL)
  })

  if (!is.null(result) && nrow(result) > 0) {
    raw_list[[length(raw_list) + 1]] <- result
  }
}

raw_pa <- bind_rows(raw_list)
cat("\nRaw PA rows:", nrow(raw_pa), "\n")
cat("Years:", paste(sort(unique(raw_pa$year)), collapse = ", "), "\n\n")


# ---- 4. PULL PA INSTITUTION DIRECTORY -----------------------------------

cat("Pulling PA institution directory...\n")

pa_directory <- get_education_data(
  level   = "college-university",
  source  = "ipeds",
  topic   = "directory",
  filters = list(year = 2022, fips = PA_FIPS),
  add_labels = FALSE
)

pa_institutions <- pa_directory |>
  mutate(unitid = as.integer(unitid)) |>
  select(unitid, inst_name, city, county_fips,
         any_of(c("inst_control", "latitude", "longitude")))

cat("PA institutions:", nrow(pa_institutions), "\n\n")


# ---- 5. CLEAN AND AGGREGATE COMPLETIONS --------------------------------

cat("Cleaning completions data...\n")

pa_completions <- raw_pa |>
  mutate(
    cipcode_6digit = as.integer(cipcode_6digit),
    award_level    = as.integer(award_level),
    awards         = as.numeric(awards_6digit),
    fips           = as.integer(fips),
    unitid         = as.integer(unitid)
  ) |>
  filter(award_level %in% degree_levels, !is.na(awards), awards > 0) |>
  inner_join(
    cip_crosswalk |> select(cip_6digit, shrs_program, shrs_dept, soc_code),
    by = c("cipcode_6digit" = "cip_6digit"),
    relationship = "many-to-many"
  ) |>
  left_join(degree_labels, by = "award_level")

latest_year <- max(pa_completions$year, na.rm = TRUE)
cat("Latest IPEDS year:", latest_year, "\n")

# Aggregate: one row per institution x program
institution_awards <- pa_completions |>
  filter(year == latest_year) |>
  group_by(unitid, fips, shrs_program, shrs_dept) |>
  summarise(
    total_awards  = sum(awards, na.rm = TRUE),
    degree_levels = paste(sort(unique(degree_group)), collapse = ", "),
    .groups       = "drop"
  ) |>
  filter(total_awards > 0)

cat("Institution-program pairs:", nrow(institution_awards), "\n\n")


# ---- 6. TIER 1: ALL PA COMPETITORS -------------------------------------

cat("Building Tier 1 (Statewide)...\n")

tier1 <- institution_awards |>
  left_join(pa_institutions, by = "unitid") |>
  mutate(
    is_pitt = unitid == PITT_UNITID,
    tier    = "Tier 1: Statewide"
  ) |>
  arrange(shrs_program, desc(total_awards))

cat("  Tier 1 pairs:", nrow(tier1), "\n")
cat("  Unique institutions:", n_distinct(tier1$unitid), "\n")

# Summary
tier1_summary <- tier1 |>
  group_by(shrs_program, shrs_dept) |>
  summarise(
    n_competitors      = n(),
    n_competitors_excl = sum(!is_pitt),
    total_pa_graduates = sum(total_awards),
    pitt_graduates     = sum(total_awards[is_pitt]),
    pitt_share_pct     = round(pitt_graduates / total_pa_graduates * 100, 1),
    .groups            = "drop"
  )

cat("\n  Tier 1 Summary:\n")
print(as.data.frame(tier1_summary))
cat("\n")


# ---- 7. TIER 2: PITTSBURGH-ERIE CORRIDOR -------------------------------

cat("Building Tier 2 (Pittsburgh-Erie)...\n")

regional_counties <- tribble(
  ~county_fips, ~county_name,     ~region,
  42003L,       "Allegheny",      "Pittsburgh Metro",
  42129L,       "Westmoreland",   "Pittsburgh Metro",
  42125L,       "Washington",     "Pittsburgh Metro",
  42019L,       "Butler",         "Pittsburgh Metro",
  42007L,       "Beaver",         "Pittsburgh Metro",
  42051L,       "Fayette",        "Pittsburgh Metro",
  42059L,       "Greene",         "Pittsburgh Metro",
  42005L,       "Armstrong",      "Surrounding",
  42063L,       "Indiana",        "Surrounding",
  42073L,       "Lawrence",       "Surrounding",
  42085L,       "Mercer",         "I-79 Corridor",
  42121L,       "Venango",        "I-79 Corridor",
  42031L,       "Clarion",        "I-79 Corridor",
  42039L,       "Crawford",       "NW Pennsylvania",
  42123L,       "Warren",         "NW Pennsylvania",
  42053L,       "Forest",         "NW Pennsylvania",
  42049L,       "Erie",           "Erie Area"
)

tier1_with_county <- tier1 |>
  mutate(county_fips = as.integer(county_fips))

tier2_by_county <- tier1_with_county |>
  filter(county_fips %in% regional_counties$county_fips)

if (nrow(tier2_by_county) > 0) {
  tier2 <- tier2_by_county |>
    left_join(regional_counties, by = "county_fips") |>
    mutate(tier = "Tier 2: Regional")
  cat("  Built via county FIPS\n")
} else {
  # Fallback: city names
  regional_cities <- c(
    "Pittsburgh", "Erie", "Greensburg", "Washington", "Butler",
    "Beaver Falls", "Uniontown", "Indiana", "New Castle", "Meadville",
    "Oil City", "Slippery Rock", "Edinboro", "California", "Clarion",
    "Grove City", "Sharon", "Titusville", "Waynesburg"
  )
  tier2 <- tier1_with_county |>
    filter(tolower(city) %in% tolower(regional_cities)) |>
    mutate(tier = "Tier 2: Regional", county_name = NA, region = NA)
  cat("  Built via city name fallback\n")
}

cat("  Tier 2 pairs:", nrow(tier2), "\n")
cat("  Unique institutions:", n_distinct(tier2$unitid), "\n")

# Summary
tier2_summary <- tier2 |>
  group_by(shrs_program) |>
  summarise(
    n_competitors  = sum(!is_pitt),
    total_grads    = sum(total_awards),
    pitt_grads     = sum(total_awards[is_pitt]),
    pitt_share_pct = round(pitt_grads / total_grads * 100, 1),
    .groups        = "drop"
  )

cat("\n  Tier 2 Summary:\n")
print(as.data.frame(tier2_summary))
cat("\n")


# ---- 8. PITT'S RANK IN PA ----------------------------------------------

pitt_rank <- tier1 |>
  group_by(shrs_program) |>
  mutate(
    rank       = rank(desc(total_awards), ties.method = "min"),
    n_schools  = n(),
    percentile = round((1 - (rank - 1) / n_schools) * 100, 0)
  ) |>
  filter(is_pitt) |>
  ungroup() |>
  select(shrs_program, total_awards, rank, n_schools, percentile)

cat("Pitt's Position in PA:\n")
print(as.data.frame(pitt_rank))
cat("\n")


# ---- 9. MASTER ROSTER ---------------------------------------------------

master_roster <- tier1 |>
  select(unitid, inst_name, city, shrs_program, shrs_dept,
         total_awards, degree_levels, is_pitt) |>
  mutate(
    in_tier1 = TRUE,
    in_tier2 = unitid %in% unique(tier2$unitid)
  ) |>
  arrange(shrs_program, desc(total_awards))

cat("Master roster:", nrow(master_roster), "entries\n")
cat("Unique institutions:", n_distinct(master_roster$unitid), "\n\n")


# ---- 10. SAVE EVERYTHING -----------------------------------------------

cat("Saving CSVs to", output_dir, "...\n")

write_csv(cip_crosswalk,    file.path(output_dir, "cip_crosswalk.csv"))
write_csv(raw_pa,           file.path(output_dir, "pa_completions_raw.csv"))
write_csv(pa_institutions,  file.path(output_dir, "pa_institutions.csv"))
write_csv(tier1,            file.path(output_dir, "tier1_statewide.csv"))
write_csv(tier2,            file.path(output_dir, "tier2_regional.csv"))
write_csv(tier1_summary,    file.path(output_dir, "tier1_summary.csv"))
write_csv(tier2_summary,    file.path(output_dir, "tier2_summary.csv"))
write_csv(master_roster,    file.path(output_dir, "master_roster.csv"))
write_csv(pitt_rank,        file.path(output_dir, "pitt_rank.csv"))

cat("\nFiles saved:\n")
list.files(output_dir) |> walk(~ cat("  ", .x, "\n"))

cat("\n====================================\n")
cat("DONE. All competitor data saved.\n")
cat("====================================\n")
