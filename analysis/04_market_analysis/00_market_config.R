# ==============================================================================
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
    "Data root not configured. Please either:\n",
    "  1. Set environment variable: Sys.setenv(SHRS_DATA_ROOT = '/path/to/data')\n",
    "  2. Create scripts/config/data_paths.R with: DATA_ROOT <- '/path/to/data'\n"
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
  cat(sprintf("# %s\n\n", base_name))
  cat(sprintf("*Generated: %s*\n\n", Sys.time()))
  print(knitr::kable(df, format = "markdown"))
  sink()
  message(sprintf("Wrote: %s", md_path))
}

message("=== Market Analysis Configuration Loaded ===")
message(sprintf("Data Root: %s", MARKET_CONFIG$data_root))
message(sprintf("Force Rebuild: %s", MARKET_CONFIG$FORCE_REBUILD))
message("============================================")
