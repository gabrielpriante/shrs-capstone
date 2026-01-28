# Market Analysis Module

## Purpose

The Market Analysis module provides external labor market context for SHRS program health evaluation. It synthesizes data on labor demand, credential requirements, peer program supply, and wage-to-cost relationships to inform strategic planning and dashboard development.

**This module produces aggregate counts and trends only—no student-level data.**

## Conceptual Framework

Market analysis evaluates programs across four dimensions:

1. **Labor Market Trends**: Employment demand and wage levels from BLS Occupational Employment and Wage Statistics (OEWS) and Employment Projections
2. **Credential Pressure**: Licensure requirements, exam pass rate trends, and scope-of-practice changes affecting program attractiveness
3. **Peer Program Supply**: Regional program saturation using IPEDS completions data and professional directories
4. **Wage vs. Cost Context**: Simple wage-to-tuition ratio as a proxy for return on investment attractiveness

These dimensions combine into a composite **Market Risk Index** that flags programs facing external headwinds.

## Data Sources

### External Data (Not Stored in Repository)

All external data must be placed in `$SHRS_DATA_ROOT/market/` or configured via `scripts/config/data_paths.R`:

- **BLS OEWS** (`bls_oews.csv`): Employment and wage data by SOC code
- **BLS Employment Projections** (`bls_projections.csv`): 10-year growth outlook by SOC code
- **IPEDS Program Counts** (`ipeds_program_counts.csv`): Peer institution program completions by region and CIP code
- **Credential Pressure Data** (`credential_pressure.csv`): Manually maintained file tracking licensure and exam trends
- **Internal Tuition Data** (`../internal/tuition_program_level.csv`): SHRS program-level tuition rates

If any file is missing, scripts generate a **TEMPLATE** file in `output/tables/` with the required schema and example rows.

### Data Safety

- **FERPA Compliance**: This module uses only aggregate counts and publicly available labor statistics—no student-level data
- **External Storage**: All source data resides outside the Git repository
- **Template Generation**: Scripts fail gracefully with clear instructions when data is unavailable

## How to Run

### Prerequisites

1. Ensure `scripts/00_setup.R` has been run to install required packages
2. Configure data root in one of two ways:
   - Set environment variable: `Sys.setenv(SHRS_DATA_ROOT = "/path/to/data")`
   - Create `scripts/config/data_paths.R` (gitignored) with `DATA_ROOT <- "/path/to/data"`
3. Place external data files in `$DATA_ROOT/market/` and `$DATA_ROOT/internal/`

### Execution Order

Run scripts in numbered order:
```r
# Configure paths and settings
source("analysis/04_market_analysis/00_market_config.R")

# Generate market context outputs
source("analysis/04_market_analysis/01_labor_market_trends.R")
source("analysis/04_market_analysis/02_credential_pressure.R")
source("analysis/04_market_analysis/03_peer_program_supply.R")
source("analysis/04_market_analysis/04_wage_vs_cost_context.R")
source("analysis/04_market_analysis/05_market_risk_index.R")
```

Each script:
- Validates required inputs
- Computes or refreshes outputs only when inputs change (unless `FORCE_REBUILD = TRUE`)
- Saves artifacts to `output/tables/` and `output/figures/`
- Produces both CSV and Markdown summary tables

### Refresh Policy

The module uses **event-driven refresh** via input file timestamps:

- On first run, all outputs are generated
- On subsequent runs, scripts check if input files have changed
- If unchanged and `FORCE_REBUILD = FALSE`, computation is skipped
- Cache metadata stored in `output/.cache/market_*_inputs.json`

To force rebuild:
```r
source("analysis/04_market_analysis/00_market_config.R")
MARKET_CONFIG$FORCE_REBUILD <- TRUE
source("analysis/04_market_analysis/01_labor_market_trends.R")  # etc.
```

## Outputs

### Tables (CSV + Markdown)

All tables saved to `output/tables/`:

- `market_labor_summary.csv|.md`: Labor market trends by program (employment, wages, growth outlook)
- `credential_pressure_summary.csv|.md`: Licensure and exam pressure indicators
- `peer_program_supply.csv|.md`: Regional peer saturation index
- `wage_vs_cost_context.csv|.md`: Wage-to-tuition ratio by program
- `market_risk_index.csv|.md`: Composite market risk score

### Figures

All figures saved to `output/figures/`:

- `labor_market_growth_vs_wage.png`: Scatter plot of projected growth vs. median wage
- `peer_program_supply_bars.png`: Bar chart of peer saturation by program and region
- `wage_vs_cost_context.png`: Scatter plot of wage index vs. tuition index

## Limitations & Disclaimers

**This module provides contextual indicators, not decision rules.**

- **External Factors Only**: Does not account for internal program quality, faculty expertise, or strategic priorities
- **Lagged Data**: BLS and IPEDS data are typically 1-2 years behind
- **Regional Assumptions**: Peer saturation uses broad regional categories; local market dynamics may differ
- **Composite Index Weights**: Market Risk Index weights are subjective and should be validated with stakeholders
- **Not Causal**: Correlations between market conditions and program health do not imply causation

**Use this analysis as one input among many in strategic planning.**

---

*Last Updated: January 2026*
