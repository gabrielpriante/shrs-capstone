# ==============================================================================
# Mock Data Generator - SHRS Program Health Analysis
# ==============================================================================
# This script generates realistic mock data for testing and demonstration
# purposes when external secure data is not available.
#
# The mock data matches the schema expected by analysis scripts but contains
# only simulated values.
#
# Usage:
#   source(here::here("scripts", "utils", "mock_data.R"))
#   mock_data <- generate_mock_program_health_data()
#   enrollment_raw <- mock_data$enrollment
#   program_metadata <- mock_data$program_metadata
# ==============================================================================

generate_mock_program_health_data <- function() {
  # Set seed for reproducibility
  set.seed(123)
  
  message("Generating mock program health data...")
  
  # Define programs matching SHRS structure
  programs <- tibble::tibble(
    program_code = c("SLP", "AuD", "CSD_UG", "AT", "DN", "SS", "SMN_UG"),
    program_name = c(
      "Speech-Language Pathology",
      "Audiology",
      "Communication Science & Disorders (UG)",
      "Athletic Training",
      "Dietetics & Nutrition",
      "Sports Science",
      "Sports Medicine & Nutrition (UG)"
    ),
    department = c(
      "Communication Science & Disorders",
      "Communication Science & Disorders",
      "Communication Science & Disorders",
      "Sports Medicine & Nutrition",
      "Sports Medicine & Nutrition",
      "Sports Medicine & Nutrition",
      "Sports Medicine & Nutrition"
    ),
    degree_type = c("MS", "AuD", "BS", "MS", "MS", "MS", "BS")
  )
  
  # Generate enrollment data for 2018-2023
  years <- 2018:2023
  
  enrollment_data <- expand.grid(
    academic_year = years,
    program_code = programs$program_code,
    stringsAsFactors = FALSE
  ) %>%
    tibble::as_tibble() %>%
    dplyr::left_join(programs, by = "program_code") %>%
    dplyr::mutate(
      # Base enrollment varies by program
      base_enrollment = dplyr::case_when(
        program_code == "SLP" ~ 65,
        program_code == "AuD" ~ 25,
        program_code == "CSD_UG" ~ 45,
        program_code == "AT" ~ 35,
        program_code == "DN" ~ 30,
        program_code == "SS" ~ 20,
        program_code == "SMN_UG" ~ 55,
        TRUE ~ 30
      ),
      # Add some year-over-year variation
      year_trend = (academic_year - 2018) * runif(dplyr::n(), -2, 3),
      random_variation = rnorm(dplyr::n(), 0, 5),
      
      # Calculate final enrolled count
      enrolled = pmax(5, round(base_enrollment + year_trend + random_variation)),
      
      # Applicants (higher than enrolled, varies by selectivity)
      applicants = round(enrolled * runif(dplyr::n(), 1.5, 3.5)),
      
      # Acceptances (between enrolled and applicants)
      acceptances = round(enrolled * runif(dplyr::n(), 1.1, 1.8)),
      
      # Tuition revenue varies by program type
      tuition_per_student = dplyr::case_when(
        degree_type == "AuD" ~ runif(dplyr::n(), 38000, 42000),
        degree_type == "MS" ~ runif(dplyr::n(), 28000, 35000),
        degree_type == "BS" ~ runif(dplyr::n(), 18000, 22000),
        TRUE ~ 25000
      ),
      
      tuition_revenue = round(enrolled * tuition_per_student, 0),
      
      # Retention rate (varies by program)
      retention_rate = pmin(1.0, pmax(0.70, rnorm(dplyr::n(), 0.87, 0.08)))
    ) %>%
    dplyr::select(
      academic_year, program_code, program_name, department, degree_type,
      applicants, acceptances, enrolled, retention_rate,
      tuition_per_student, tuition_revenue
    ) %>%
    dplyr::arrange(department, program_code, academic_year)
  
  # Generate financial data
  financial_data <- enrollment_data %>%
    dplyr::group_by(academic_year, program_code, program_name, department) %>%
    dplyr::summarise(
      total_revenue = sum(tuition_revenue),
      # Estimate costs (faculty, facilities, etc.)
      faculty_costs = round(total_revenue * runif(1, 0.45, 0.65)),
      facilities_costs = round(total_revenue * runif(1, 0.10, 0.15)),
      admin_overhead = round(total_revenue * runif(1, 0.08, 0.12)),
      total_costs = faculty_costs + facilities_costs + admin_overhead,
      net_revenue = total_revenue - total_costs,
      .groups = "drop"
    )
  
  # Generate student outcomes data
  outcomes_data <- enrollment_data %>%
    dplyr::filter(academic_year >= 2020) %>%  # Only recent cohorts
    dplyr::mutate(
      cohort = paste0("Class of ", academic_year + 2),  # Assuming 2-year programs
      graduation_rate = pmin(1.0, pmax(0.75, rnorm(dplyr::n(), 0.91, 0.06))),
      employment_rate = pmin(1.0, pmax(0.80, rnorm(dplyr::n(), 0.94, 0.05))),
      licensure_pass_rate = dplyr::case_when(
        program_code %in% c("SLP", "AuD", "AT", "DN") ~ 
          pmin(1.0, pmax(0.85, rnorm(dplyr::n(), 0.96, 0.04))),
        TRUE ~ NA_real_
      ),
      avg_starting_salary = dplyr::case_when(
        program_code == "SLP" ~ rnorm(dplyr::n(), 58000, 5000),
        program_code == "AuD" ~ rnorm(dplyr::n(), 65000, 6000),
        program_code == "AT" ~ rnorm(dplyr::n(), 48000, 4000),
        program_code == "DN" ~ rnorm(dplyr::n(), 52000, 4500),
        program_code == "SS" ~ rnorm(dplyr::n(), 45000, 4000),
        TRUE ~ rnorm(dplyr::n(), 42000, 5000)
      )
    ) %>%
    dplyr::select(
      academic_year, program_code, program_name, cohort,
      graduation_rate, employment_rate, licensure_pass_rate, avg_starting_salary
    )
  
  # Generate faculty data
  faculty_data <- programs %>%
    dplyr::mutate(
      faculty_fte = dplyr::case_when(
        program_code %in% c("SLP", "CSD_UG") ~ runif(1, 8, 12),
        program_code == "AuD" ~ runif(1, 4, 6),
        program_code %in% c("AT", "DN", "SMN_UG") ~ runif(1, 5, 8),
        TRUE ~ runif(1, 3, 5)
      ),
      avg_faculty_salary = rnorm(dplyr::n(), 85000, 12000),
      student_faculty_ratio = NA_real_  # Will be calculated with enrollment
    )
  
  message("✓ Mock data generated successfully")
  message("  - Programs: ", nrow(programs))
  message("  - Enrollment records: ", nrow(enrollment_data))
  message("  - Financial records: ", nrow(financial_data))
  message("  - Outcomes records: ", nrow(outcomes_data))
  message("  - Faculty records: ", nrow(faculty_data))
  
  # Return as a named list
  return(list(
    enrollment = enrollment_data,
    program_metadata = programs,
    financial = financial_data,
    outcomes = outcomes_data,
    faculty = faculty_data
  ))
}
