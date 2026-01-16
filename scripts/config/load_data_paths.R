# ==============================================================================
# Data Paths Loader
# ==============================================================================
# This function provides a unified way to load data paths across all scripts.
# It supports both external data mode and mock data mode.
#
# Usage:
#   source(here::here("scripts", "config", "load_data_paths.R"))
#   paths <- load_data_paths()
#   
#   if (paths$use_mock) {
#     # Use mock data
#   } else {
#     # Use external data from paths$ENROLLMENT_DATA, etc.
#   }
# ==============================================================================

load_data_paths <- function() {
  # Check for mock mode environment variable
  use_mock <- Sys.getenv("SHRS_USE_MOCK_DATA") == "1"
  
  if (use_mock) {
    message("\n=== MOCK DATA MODE ENABLED ===")
    message("Using simulated data for demonstration purposes.")
    message("Set SHRS_USE_MOCK_DATA=0 or unset to use external data.")
    message("===============================\n")
    
    return(list(
      use_mock = TRUE,
      DATA_ROOT = NULL,
      RAW_DATA_PATH = NULL,
      PROCESSED_DATA_PATH = NULL
    ))
  }
  
  # Check if user's data_paths.R exists
  config_file <- here::here("scripts", "config", "data_paths.R")
  example_file <- here::here("scripts", "config", "data_paths.example.R")
  
  if (file.exists(config_file)) {
    # Load the configuration
    message("Loading data paths from configuration file...")
    source(config_file, local = TRUE)
    
    # Return a list of all defined paths
    # Note: This assumes data_paths.R defines these variables
    result <- list(
      use_mock = FALSE,
      DATA_ROOT = if(exists("DATA_ROOT")) DATA_ROOT else NULL,
      RAW_DATA_PATH = if(exists("RAW_DATA_PATH")) RAW_DATA_PATH else NULL,
      PROCESSED_DATA_PATH = if(exists("PROCESSED_DATA_PATH")) PROCESSED_DATA_PATH else NULL,
      ARCHIVE_PATH = if(exists("ARCHIVE_PATH")) ARCHIVE_PATH else NULL,
      ENROLLMENT_DATA = if(exists("ENROLLMENT_DATA")) ENROLLMENT_DATA else NULL,
      PROGRAM_METADATA = if(exists("PROGRAM_METADATA")) PROGRAM_METADATA else NULL,
      FINANCIAL_DATA = if(exists("FINANCIAL_DATA")) FINANCIAL_DATA else NULL,
      STUDENT_OUTCOMES_DATA = if(exists("STUDENT_OUTCOMES_DATA")) STUDENT_OUTCOMES_DATA else NULL,
      FACULTY_DATA = if(exists("FACULTY_DATA")) FACULTY_DATA else NULL,
      ADMISSIONS_DATA = if(exists("ADMISSIONS_DATA")) ADMISSIONS_DATA else NULL,
      RETENTION_DATA = if(exists("RETENTION_DATA")) RETENTION_DATA else NULL,
      LICENSURE_DATA = if(exists("LICENSURE_DATA")) LICENSURE_DATA else NULL,
      SURVEY_DATA = if(exists("SURVEY_DATA")) SURVEY_DATA else NULL,
      ALUMNI_DATA = if(exists("ALUMNI_DATA")) ALUMNI_DATA else NULL
    )
    
    message("✓ Data paths loaded successfully")
    return(result)
    
  } else {
    # Configuration file doesn't exist - provide helpful error
    stop(
      "\n╔═══════════════════════════════════════════════════════════════════╗\n",
      "║          DATA CONFIGURATION REQUIRED                              ║\n",
      "╚═══════════════════════════════════════════════════════════════════╝\n\n",
      "You have two options to run this analysis:\n\n",
      "OPTION A: Use External Secure Data\n",
      "  1. Copy the example configuration:\n",
      "     cp scripts/config/data_paths.example.R scripts/config/data_paths.R\n",
      "     (or manually copy and rename the file)\n\n",
      "  2. Edit scripts/config/data_paths.R with your secure data paths\n\n",
      "  3. Run the analysis scripts normally\n\n",
      "OPTION B: Run with Mock Data (for testing/demonstration)\n",
      "  Run this in your R session or terminal:\n",
      "    Sys.setenv(SHRS_USE_MOCK_DATA = \"1\")\n",
      "  Or in bash/terminal:\n",
      "    export SHRS_USE_MOCK_DATA=1\n",
      "  Then run the analysis scripts\n\n",
      "For more information, see:\n",
      "  - scripts/config/README.md\n",
      "  - docs/quick_start.md\n\n",
      "NOTE: scripts/config/data_paths.R is in .gitignore and will NOT be committed.\n"
    )
  }
}
