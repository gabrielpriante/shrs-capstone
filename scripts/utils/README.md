# Utility Scripts

This directory contains shared utility functions used across analysis scripts.

## Files

### `mock_data.R`

Generates realistic simulated data for the SHRS Program Health analysis when external secure data is not available.

**Usage:**
```r
source(here::here("scripts", "utils", "mock_data.R"))
mock_data <- generate_mock_program_health_data()
```

**Returns:**
A named list containing:
- `enrollment`: Enrollment data by program and year (2018-2023)
- `program_metadata`: Program information (names, departments, degrees)
- `financial`: Revenue and cost data by program
- `outcomes`: Student outcomes (graduation, employment, licensure)
- `faculty`: Faculty counts and ratios by program

**Data Schema:**

All mock data matches the expected schema for SHRS program health analysis:

- **Programs**: 7 programs (SLP, AuD, CSD_UG, AT, DN, SS, SMN_UG)
- **Years**: 2018-2023 academic years
- **Departments**: Communication Science & Disorders, Sports Medicine & Nutrition
- **Degree Types**: MS, AuD, BS

**Deterministic:** Uses `set.seed(123)` for reproducible results.

**Purpose:** Enables testing, demonstration, and development of analysis pipelines without requiring access to actual sensitive institutional data.

## Adding New Utilities

When adding new shared utility functions:

1. Create a new `.R` file with a descriptive name
2. Document the function purpose and usage at the top
3. Use clear function names and parameter documentation
4. Update this README with the new utility
5. Ensure the utility works with both mock and external data modes if applicable
