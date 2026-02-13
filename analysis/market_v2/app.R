# =============================================================================
# SHRS Program Health Dashboard — Full Visualization Showcase
# University of Pittsburgh — SHRS MQE Capstone
#
# FILE LOCATION:
#   /Users/gpps/Documents/shrs-capstone/analysis/market_v2/app.R
#   (Same folder as market_01_data_prep.Rmd, market_02_analysis.Rmd,
#    and skills_01_analysis.Rmd)
#
# WHAT THIS DOES:
#   Shows EVERY visualization from market_02_analysis.Rmd and
#   skills_01_analysis.Rmd in an interactive Shiny dashboard.
#   Sources market_01_data_prep.Rmd for all data loading.
#
# TO RUN: Click "Run App" in RStudio
# =============================================================================

library(shiny)
library(tidyverse)
library(readxl)
library(janitor)
library(scales)
library(DT)
library(plotly)
library(bslib)
library(knitr)

# =============================================================================
# DATA LOADING — sources your existing pipeline
# =============================================================================

message(">>> Sourcing market_01_data_prep.Rmd...")
source(knitr::purl("market_01_data_prep.Rmd", output = tempfile(), quiet = TRUE))
message(">>> Data prep complete.")

MARKET_ROOT      <- file.path(path.expand("~"), "Documents", "SHRS_Analysis",
                               "market_analysis")
BLS_ROOT         <- file.path(MARKET_ROOT, "bls")
BLS_SKILLS_PATH  <- file.path(MARKET_ROOT, "skills", "bls", "skills.xlsx")
ONET_SKILLS_PATH <- file.path(MARKET_ROOT, "skills", "onet", "Skills-2.xlsx")
ONET_EDU_PATH    <- file.path(MARKET_ROOT, "skills", "onet",
                               "Education__Training__and_Experience.xlsx")

# Search for education.xlsx
EDUCATION_PATH <- NULL
for (p in c(file.path(BLS_ROOT, "projections", "education.xlsx"),
            file.path(BLS_ROOT, "education.xlsx"),
            "education.xlsx")) {
  if (file.exists(p)) { EDUCATION_PATH <- p; break }
}

# Search for industry matrix CSV
IND_MATRIX_PATH <- NULL
for (p in c(file.path(BLS_ROOT, "industry", "National_Employment_Matrix_IND_621990.csv"),
            file.path(BLS_ROOT, "projections", "National_Employment_Matrix_IND_621990.csv"),
            "National_Employment_Matrix_IND_621990.csv")) {
  if (file.exists(p)) { IND_MATRIX_PATH <- p; break }
}

# Full 9-program crosswalk (skills_01 scope)
soc_crosswalk_full <- tribble(
  ~shrs_program, ~shrs_dept, ~soc_code, ~occupation_title,                ~pitt_degree,
  "SLP","CSD","29-1127","Speech-Language Pathologists","Master's",
  "AuD","CSD","29-1181","Audiologists","Doctoral",
  "HIM","HIM","29-9021","Health Information Technologists","Master's",
  "OTD","OT","29-1122","Occupational Therapists","Doctoral",
  "DPT","PT","29-1123","Physical Therapists","Doctoral",
  "PAS","PAS","29-1071","Physician Assistants","Master's",
  "AT","SMN","29-9091","Athletic Trainers","Master's",
  "DN","SMN","29-1031","Dietitians and Nutritionists","Master's",
  "SS","SMN","29-1128","Exercise Physiologists","Master's"
)
target_socs_full <- soc_crosswalk_full$soc_code

program_colors <- c(
  "SLP"="#2c7bb6","AuD"="#abd9e9","HIM"="#756bb1","OTD"="#e6550d",
  "DPT"="#31a354","PAS"="#de2d26","AT"="#fdae61","DN"="#d7191c","SS"="#1a9641"
)

# =============================================================================
# LOAD ALL ADDITIONAL DATA SOURCES
# =============================================================================

# --- BLS Skills ---
bls_skills <- NULL
if (file.exists(BLS_SKILLS_PATH)) {
  bw <- read_excel(BLS_SKILLS_PATH, sheet = "Table 6.5", skip = 1, col_types = "text") |> clean_names()
  names(bw)[1:2] <- c("occupation_title", "soc_code")
  bls_skills <- bw |> filter(soc_code %in% target_socs_full) |>
    pivot_longer(-c(occupation_title, soc_code), names_to = "skill", values_to = "percentile") |>
    mutate(percentile = as.numeric(percentile),
           skill = str_replace_all(skill, "_", " ") |> str_to_title()) |>
    left_join(soc_crosswalk_full |> select(shrs_program, shrs_dept, soc_code), by = "soc_code")
}

# --- O*NET Skills ---
onet_skills <- NULL; onet_clustered <- NULL
if (file.exists(ONET_SKILLS_PATH)) {
  or <- read_excel(ONET_SKILLS_PATH, sheet = "Skills") |> clean_names()
  onet_skills <- or |>
    mutate(soc_code = str_sub(o_net_soc_code, 1, 7)) |>
    filter(soc_code %in% target_socs_full, scale_id == "IM",
           recommend_suppress != "Y" | is.na(recommend_suppress)) |>
    select(soc_code, skill = element_name, importance = data_value) |>
    left_join(soc_crosswalk_full |> select(shrs_program, shrs_dept, soc_code), by = "soc_code")

  cm <- tribble(~skill,~cluster,
    "Active Listening","Communication","Speaking","Communication",
    "Writing","Communication","Reading Comprehension","Communication",
    "Social Perceptiveness","Interpersonal","Coordination","Interpersonal",
    "Persuasion","Interpersonal","Negotiation","Interpersonal",
    "Instructing","Interpersonal","Service Orientation","Interpersonal",
    "Critical Thinking","Analytical","Complex Problem Solving","Analytical",
    "Judgment and Decision Making","Analytical","Systems Analysis","Analytical",
    "Systems Evaluation","Analytical","Operations Analysis","Analytical",
    "Active Learning","Learning & Adaptability","Learning Strategies","Learning & Adaptability",
    "Monitoring","Learning & Adaptability",
    "Time Management","Management","Management of Personnel Resources","Management",
    "Management of Material Resources","Management","Management of Financial Resources","Management",
    "Quality Control Analysis","Technical","Technology Design","Technical",
    "Equipment Selection","Technical","Installation","Technical",
    "Programming","Technical","Operations Monitoring","Technical",
    "Operation and Control","Technical","Equipment Maintenance","Technical",
    "Troubleshooting","Technical","Repairing","Technical",
    "Mathematics","Science & Math","Science","Science & Math")
  onet_clustered <- onet_skills |> left_join(cm, by = "skill") |>
    filter(!is.na(cluster)) |>
    group_by(shrs_program, cluster) |>
    summarise(avg_importance = mean(importance, na.rm = TRUE), .groups = "drop")
}

# --- O*NET Education ---
onet_edu <- NULL
if (file.exists(ONET_EDU_PATH)) {
  onet_edu <- read_excel(ONET_EDU_PATH, sheet = "Education, Training, and Experi") |>
    clean_names() |> mutate(soc_code = str_sub(o_net_soc_code, 1, 7)) |>
    filter(soc_code %in% target_socs_full) |>
    left_join(soc_crosswalk_full |> select(shrs_program, shrs_dept, soc_code), by = "soc_code")
}

# --- Industry Matrix ---
ind_matrix <- NULL; ind_matrix_shrs <- NULL
if (!is.null(IND_MATRIX_PATH)) {
  ind_matrix <- read_csv(IND_MATRIX_PATH, show_col_types = FALSE) |> clean_names() |>
    mutate(occupation_code = str_remove_all(occupation_code, '=|"'),
           across(c(x2024_employment, projected_2034_employment,
                    employment_change_2024_2034, employment_percent_change_2024_2034,
                    x2024_percent_of_industry, x2024_percent_of_occupation,
                    projected_2034_percent_of_industry, projected_2034_percent_of_occupation),
                  ~ as.numeric(as.character(.x))))
  ind_matrix_shrs <- ind_matrix |>
    filter(occupation_code %in% target_socs_full, occupation_type == "Line Item") |>
    left_join(soc_crosswalk_full, by = c("occupation_code" = "soc_code"))
}

# --- Education Tables ---
edu_premium <- NULL; edu_employment <- NULL
edu_requirements_shrs <- NULL; edu_attainment_shrs <- NULL
if (!is.null(EDUCATION_PATH)) {
  edu_premium <- read_excel(EDUCATION_PATH, sheet = "Table 5.1", skip = 1) |> clean_names()
  names(edu_premium) <- c("edu_level", "median_weekly_earnings", "unemployment_rate")
  edu_premium <- edu_premium |> mutate(across(-edu_level, as.numeric),
                                        median_annual_earnings = median_weekly_earnings * 52)

  edu_employment <- read_excel(EDUCATION_PATH, sheet = "Table 5.2", skip = 1) |> clean_names()
  cn52 <- names(edu_employment); names(edu_employment)[1] <- "edu_level"
  pc <- str_which(cn52, "percent"); wc <- str_which(cn52, "wage|median")
  if (length(pc)>0) names(edu_employment)[pc[length(pc)]] <- "emp_change_pct"
  if (length(wc)>0) names(edu_employment)[wc[length(wc)]] <- "median_wage"
  edu_employment <- edu_employment |> mutate(across(-edu_level, ~as.numeric(as.character(.x))))

  t53 <- read_excel(EDUCATION_PATH, sheet = "Table 5.3", skip = 1) |> clean_names()
  cn53 <- names(t53); names(t53)[1:2] <- c("occupation_title","soc_code")
  bc<-str_which(cn53,"bachelor"); mc<-str_which(cn53,"master"); dc<-str_which(cn53,"doctor|professional")
  if(length(bc)>0) names(t53)[bc[1]]<-"bachelors"
  if(length(mc)>0) names(t53)[mc[1]]<-"masters"
  if(length(dc)>0) names(t53)[dc[1]]<-"doctoral"
  edu_attainment_shrs <- t53 |> filter(soc_code %in% target_socs_full) |>
    mutate(across(c(bachelors,masters,doctoral), as.numeric)) |>
    left_join(soc_crosswalk_full |> select(shrs_program,soc_code), by="soc_code")

  t54 <- read_excel(EDUCATION_PATH, sheet = "Table 5.4", skip = 1) |> clean_names()
  names(t54)[1:5] <- c("occupation_title","soc_code","typical_entry_education","work_experience","ojt_required")
  edu_requirements_shrs <- t54 |> filter(soc_code %in% target_socs_full) |>
    left_join(soc_crosswalk_full |> select(shrs_program,soc_code), by="soc_code")
}

# =============================================================================
# BUILD ALL ANALYSIS OBJECTS (from market_02)
# =============================================================================

emp_growth <- oews |> group_by(shrs_program, occ_title) |>
  summarise(emp_first_year=first(tot_emp), emp_last_year=last(tot_emp),
            year_start=min(year), year_end=max(year),
            abs_change=last(tot_emp)-first(tot_emp),
            pct_change=round((last(tot_emp)/first(tot_emp)-1)*100,1), .groups="drop") |>
  arrange(desc(pct_change))

proj_latest <- projections |> filter(base_year == max(base_year))
latest_year <- max(oews$year)

# Credential alignment
credential_alignment <- NULL; credential_scores <- NULL; scorecard <- NULL
if (!is.null(edu_requirements_shrs) && !is.null(edu_attainment_shrs)) {
  erd <- edu_requirements_shrs |> distinct(soc_code,.keep_all=TRUE) |>
    select(soc_code, bls_entry_education=typical_entry_education, ojt=ojt_required)
  ead <- edu_attainment_shrs |> distinct(soc_code,.keep_all=TRUE) |>
    select(soc_code, bachelors, masters, doctoral)

  credential_alignment <- soc_crosswalk |>
    select(shrs_program,shrs_dept,soc_code,pitt_degree) |>
    left_join(erd, by="soc_code") |> left_join(ead, by="soc_code") |>
    mutate(
      pitt_degree_group = case_when(str_detect(pitt_degree,"Doctoral|Post-Professional")~"doctoral", TRUE~"masters"),
      workforce_pct_at_pitt_level = case_when(pitt_degree_group=="doctoral"~doctoral, pitt_degree_group=="masters"~masters, TRUE~NA_real_),
      bls_requires_group = case_when(
        str_detect(bls_entry_education,regex("doctoral|professional",ignore_case=TRUE))~"doctoral",
        str_detect(bls_entry_education,regex("master",ignore_case=TRUE))~"masters",
        str_detect(bls_entry_education,regex("bachelor",ignore_case=TRUE))~"bachelors", TRUE~"other"),
      credential_match = case_when(
        pitt_degree_group==bls_requires_group~"Aligned",
        pitt_degree_group=="doctoral"&bls_requires_group=="masters"~"Above Required",
        pitt_degree_group=="masters"&bls_requires_group=="bachelors"~"Above Required",
        pitt_degree_group=="masters"&bls_requires_group=="doctoral"~"Below Required",
        pitt_degree_group=="masters"&bls_requires_group=="other"~"Above Required", TRUE~"Review"))

  credential_scores <- credential_alignment |> mutate(credential_score = case_when(
    credential_match=="Aligned"&workforce_pct_at_pitt_level>=60~5,
    credential_match=="Aligned"&workforce_pct_at_pitt_level>=40~4,
    credential_match=="Aligned"~3,
    credential_match=="Above Required"&workforce_pct_at_pitt_level>=30~3,
    credential_match=="Above Required"~2, credential_match=="Below Required"~1, TRUE~0))

  eps <- credential_alignment |> mutate(edu_premium_score=case_when(
    pitt_degree_group=="doctoral"~3, pitt_degree_group=="masters"~2, TRUE~1)) |>
    select(shrs_program, edu_premium_score)

  psc <- proj_latest |> select(soc_code,emp_change_pct,annual_openings,median_wage) |> distinct(soc_code,.keep_all=TRUE)
  ssc <- separations |> select(soc_code,total_sep_rate) |> distinct(soc_code,.keep_all=TRUE)
  gsc <- emp_growth |> left_join(soc_crosswalk|>select(shrs_program,soc_code),by="shrs_program") |>
    select(soc_code,historical_growth_pct=pct_change) |> distinct(soc_code,.keep_all=TRUE)

  scorecard <- soc_crosswalk |> select(shrs_program,shrs_dept,soc_code) |>
    left_join(psc,by="soc_code") |> left_join(gsc,by="soc_code") |> left_join(ssc,by="soc_code") |>
    left_join(credential_scores|>select(shrs_program,credential_score,credential_match),by="shrs_program") |>
    left_join(eps,by="shrs_program") |>
    mutate(
      growth_score=case_when(emp_change_pct>=all_occ_growth_pct*2~3,emp_change_pct>=all_occ_growth_pct~2,emp_change_pct>=0~1,TRUE~0),
      wage_score=case_when(median_wage>=90000~3,median_wage>=60000~2,median_wage>=40000~1,TRUE~0),
      openings_score=case_when(annual_openings>=10~3,annual_openings>=3~2,annual_openings>=1~1,TRUE~0),
      turnover_score=case_when(total_sep_rate>=6~3,total_sep_rate>=4~2,total_sep_rate>=2~1,TRUE~0),
      raw_score=growth_score+wage_score+openings_score+turnover_score+credential_score+edu_premium_score,
      composite_score=round(raw_score/20*100),
      market_signal=case_when(composite_score>=80~"Strong",composite_score>=60~"Favorable",
                              composite_score>=40~"Moderate",composite_score>=20~"Weak",TRUE~"Critical"))
}

message(">>> All objects built. Launching dashboard...")

# =============================================================================
# UI — Every visualization organized by section
# =============================================================================

ui <- page_navbar(
  title = tags$span(tags$strong("SHRS"), " Market Analysis Dashboard"),
  id = "main_nav",
  theme = bs_theme(version=5, bootswatch="flatly", primary="#003594", secondary="#FFB81C",
                   "navbar-bg"="#003594", base_font=font_google("Source Sans Pro"), font_scale=0.95),
  header = tags$head(tags$style(HTML("
    .navbar{border-bottom:3px solid #FFB81C}
    .card{border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,.08)}
    .card-header{font-weight:600}
  "))),

  # ═══════════════════════════════════════════════════════════════════════════
  # TAB 1: SCORECARD & OVERVIEW (market_02 Sections 8 + 4.1)
  # ═══════════════════════════════════════════════════════════════════════════
  nav_panel("Scorecard", icon=icon("dashboard"),
    layout_columns(col_widths=c(3,3,3,3),
      value_box("Programs",nrow(soc_crosswalk),showcase=icon("heartbeat"),theme="primary"),
      value_box("OEWS Years",paste0(min(oews$year),"-",max(oews$year)),showcase=icon("calendar"),theme="info"),
      value_box("Avg Growth",if(!is.null(scorecard))paste0(round(mean(scorecard$emp_change_pct,na.rm=TRUE),1),"%")else"-",showcase=icon("chart-line"),theme="success"),
      value_box("Benchmark",paste0(all_occ_growth_pct,"%"),showcase=icon("balance-scale"),theme="secondary")),
    layout_columns(col_widths=c(7,5),
      card(card_header("8.1 — Scorecard Table (v2.1, 0-100)"), card_body(DTOutput("sc_table"))),
      card(card_header("8.3 — Health Signal (Red-to-Green)"), card_body(plotOutput("sc_signal",height="380px")))),
    layout_columns(col_widths=c(12),
      card(card_header("8.2 — Scorecard Decomposition"), card_body(plotOutput("sc_decomp",height="450px")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("4.1 — Growth vs Benchmarks"), card_body(plotOutput("benchmark_chart",height="380px"))),
      card(card_header("4.3 — Labor Force Overview"), card_body(DTOutput("lf_table"))))
  ),

  # ═══════════════════════════════════════════════════════════════════════════
  # TAB 2: HISTORICAL TRENDS (market_02 Section 1)
  # ═══════════════════════════════════════════════════════════════════════════
  nav_panel("Employment & Wages", icon=icon("chart-line"),
    layout_columns(col_widths=c(12),
      card(card_header("1.1 — Employment Over Time"), card_body(plotOutput("emp_trends",height="550px")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("1.2 — Employment Growth Summary"), card_body(DTOutput("emp_growth_tbl"))),
      card(card_header("1.4 — Wage Comparison (Latest Year)"), card_body(plotOutput("wage_comp",height="350px")))),
    layout_columns(col_widths=c(12),
      card(card_header("1.3 — Wage Trends"), card_body(plotOutput("wage_trends",height="550px"))))
  ),

  # ═══════════════════════════════════════════════════════════════════════════
  # TAB 3: PROJECTIONS & SEPARATIONS (market_02 Sections 2 + 3)
  # ═══════════════════════════════════════════════════════════════════════════
  nav_panel("Projections", icon=icon("chart-bar"),
    layout_columns(col_widths=c(12),
      card(card_header("2.1 — Projected Growth Across Cycles"), card_body(plotOutput("proj_cycles",height="550px")))),
    layout_columns(col_widths=c(12),
      card(card_header("2.2 — Projections Summary (Latest Cycle)"), card_body(DTOutput("proj_table")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("3 — Job Openings Components"), card_body(plotOutput("sep_chart",height="380px"))),
      card(card_header("3 — Separations Table"), card_body(DTOutput("sep_table"))))
  ),

  # ═══════════════════════════════════════════════════════════════════════════
  # TAB 4: EDUCATION PREMIUM & CREDENTIALS (market_02 Sections 5 + 6)
  # ═══════════════════════════════════════════════════════════════════════════
  nav_panel("Credentials", icon=icon("graduation-cap"),
    layout_columns(col_widths=c(6,6),
      card(card_header("5.1 — Education Premium Curve"), card_body(plotOutput("edu_premium_curve",height="400px"))),
      card(card_header("5.2 — Employment Growth by Education Tier"), card_body(plotOutput("edu_growth_tiers",height="400px")))),
    layout_columns(col_widths=c(12),
      card(card_header("5.3 — Education Premium Summary"), card_body(DTOutput("edu_premium_tbl")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("6.1 — Credential Alignment Table"), card_body(DTOutput("cred_table"))),
      card(card_header("6.3 — Credential Scoring"), card_body(DTOutput("cred_score_tbl")))),
    layout_columns(col_widths=c(12),
      card(card_header("6.2 — Workforce Education Distribution"), card_body(plotOutput("cred_viz",height="500px"))))
  ),

  # ═══════════════════════════════════════════════════════════════════════════
  # TAB 5: INDUSTRY PRESENCE (market_02 Section 7)
  # ═══════════════════════════════════════════════════════════════════════════
  nav_panel("Industry", icon=icon("industry"),
    layout_columns(col_widths=c(6,6),
      card(card_header("7.1 — SHRS in Ambulatory Care (NAICS 621990)"), card_body(DTOutput("ind_presence_tbl"))),
      card(card_header("7.2 — Industry Concentration"), card_body(plotOutput("ind_concentration",height="350px")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("7.3 — Industry Diversification"), card_body(DTOutput("ind_missing_tbl"))),
      card(card_header("7.4 — Top 15 Growing Occupations in 621990"), card_body(plotOutput("ind_top15",height="400px"))))
  ),

  # ═══════════════════════════════════════════════════════════════════════════
  # TAB 6: BLS SKILLS (skills_01 Section 1)
  # ═══════════════════════════════════════════════════════════════════════════
  nav_panel("BLS Skills", icon=icon("brain"),
    layout_columns(col_widths=c(12),
      card(card_header("1.1 — BLS Skill Heatmap (9 Programs)"), card_body(plotOutput("bls_heatmap",height="550px")))),
    layout_columns(col_widths=c(12),
      card(card_header("1.2 — Skill Profiles by Program"), card_body(plotOutput("bls_radar",height="750px")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("1.3 — Top 3 Skills per Program"), card_body(DTOutput("bls_top3_tbl"))),
      card(card_header("1.4 — Distinguishing Skills"), card_body(DTOutput("bls_distinguish_tbl"))))
  ),

  # ═══════════════════════════════════════════════════════════════════════════
  # TAB 7: O*NET SKILLS (skills_01 Section 2)
  # ═══════════════════════════════════════════════════════════════════════════
  nav_panel("O*NET Skills", icon=icon("cogs"),
    layout_columns(col_widths=c(12),
      card(card_header("2.1 — Top 10 Skills by Program (Importance)"), card_body(plotOutput("onet_top10",height="750px")))),
    layout_columns(col_widths=c(12),
      card(card_header("2.2 — Full O*NET Skill Heatmap"), card_body(plotOutput("onet_heatmap",height="750px")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("2.3 — Skill Clusters (Bar)"), card_body(plotOutput("onet_cluster_bar",height="400px"))),
      card(card_header("2.3 — Skill Cluster Heatmap"), card_body(plotOutput("onet_cluster_heat",height="350px"))))
  ),

  # ═══════════════════════════════════════════════════════════════════════════
  # TAB 8: EDUCATION PATHWAYS (skills_01 Section 3)
  # ═══════════════════════════════════════════════════════════════════════════
  nav_panel("Education Pathways", icon=icon("book"),
    layout_columns(col_widths=c(6,6),
      card(card_header("3.1 — Education Level Distribution (O*NET)"), card_body(plotOutput("onet_edu_dist",height="400px"))),
      card(card_header("3.2 — Work Experience Distribution"), card_body(plotOutput("onet_exp_dist",height="400px")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("3.3 — OJT Requirements"), card_body(plotOutput("onet_ojt_dist",height="350px"))),
      card(card_header("3.1 — Education Level Table"), card_body(DTOutput("onet_edu_tbl"))))
  ),

  # ═══════════════════════════════════════════════════════════════════════════
  # TAB 9: SYNTHESIS & CLUSTERING (skills_01 Sections 4 + 5)
  # ═══════════════════════════════════════════════════════════════════════════
  nav_panel("Synthesis", icon=icon("project-diagram"),
    layout_columns(col_widths=c(12),
      card(card_header("4.0 — Skills & Education Synthesis"), card_body(DTOutput("synthesis_tbl")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("4.1 — Program Positioning Map"), card_body(plotOutput("positioning",height="400px"))),
      card(card_header("5.1 — Skill Similarity Dendrogram"), card_body(plotOutput("dendrogram",height="400px")))),
    layout_columns(col_widths=c(6,6),
      card(card_header("5.2 — Universal Skills (Above 50th pctl)"), card_body(DTOutput("shared_skills_tbl"))),
      card(card_header("5.2 — Signature Skill per Program"), card_body(DTOutput("unique_skills_tbl"))))
  ),

  nav_spacer(),
  nav_item(tags$span(style="color:#FFB81C;font-size:.85em","MQE Capstone 2026"))
)

# =============================================================================
# SERVER — Every render function, one per visualization
# =============================================================================

server <- function(input, output, session) {

  # ═══ TAB 1: SCORECARD ══════════════════════════════════════════════════════

  output$sc_table <- renderDT({
    req(scorecard)
    scorecard |> select(Program=shrs_program,Dept=shrs_dept,
      `Hist Growth (%)`=historical_growth_pct, `Proj Growth (%)`=emp_change_pct,
      `Median Wage`=median_wage, `Openings/yr (K)`=annual_openings,
      `Sep Rate (%)`=total_sep_rate, `Cred Match`=credential_match,
      `Score (0-100)`=composite_score, Signal=market_signal) |>
      arrange(desc(`Score (0-100)`)) |>
      datatable(options=list(dom='t',pageLength=15),rownames=FALSE,class="compact stripe") |>
      formatStyle("Signal",color=styleEqual(c("Strong","Favorable","Moderate","Weak","Critical"),
        c("#1a9641","#2c7bb6","#e6960d","#fd8d3c","#d7191c")),fontWeight="bold") |>
      formatCurrency("Median Wage",digits=0)
  })

  output$sc_signal <- renderPlot({
    req(scorecard)
    scorecard |> ggplot(aes(x=reorder(shrs_program,composite_score),y=composite_score,fill=composite_score/100)) +
      geom_col(width=.6) + geom_text(aes(label=paste0(composite_score,"/100")),hjust=-.1,size=4) +
      coord_flip() + scale_fill_gradientn(colors=c("#d73027","#fdae61","#fee08b","#a6d96a","#1a9641"),
        values=c(0,.25,.5,.75,1),limits=c(0,1),name="Health\nSignal") +
      scale_y_continuous(limits=c(0,115),expand=expansion(mult=c(0,0))) +
      labs(title="Program Market Health Signal",subtitle="Red-to-Green | 6-dimension composite (0-100)",
           x=NULL,y="Composite Score (0-100)") + theme_minimal(base_size=13) + theme(legend.position="right")
  })

  output$sc_decomp <- renderPlot({
    req(scorecard)
    scorecard |> transmute(shrs_program,`Growth (0-3)`=growth_score,`Wage (0-3)`=wage_score,
      `Openings (0-3)`=openings_score,`Replacement (0-3)`=turnover_score,
      `Credential (0-5)`=credential_score,`Edu Premium (0-3)`=edu_premium_score) |>
      pivot_longer(-shrs_program,names_to="dimension",values_to="score") |>
      ggplot(aes(x=dimension,y=score,fill=dimension)) + geom_col(width=.7) +
      facet_wrap(~shrs_program,ncol=3) + scale_y_continuous(limits=c(0,5),breaks=0:5) +
      labs(title="Scorecard Decomposition",x=NULL,y="Score") +
      theme_minimal(base_size=11) + theme(legend.position="none",axis.text.x=element_text(angle=55,hjust=1))
  })

  output$benchmark_chart <- renderPlot({
    req(scorecard)
    scorecard |> select(shrs_program,emp_change_pct) |>
      bind_rows(tibble(shrs_program="All Occupations",emp_change_pct=all_occ_growth_pct),
                tibble(shrs_program="Labor Force",emp_change_pct=lf_growth_2024_2034)) |>
      mutate(fill_color=if_else(shrs_program %in% c("All Occupations","Labor Force"),"Benchmark","SHRS Program")) |>
      ggplot(aes(x=reorder(shrs_program,emp_change_pct),y=emp_change_pct,fill=fill_color)) +
      geom_col(width=.6) + geom_text(aes(label=paste0(emp_change_pct,"%")),hjust=-.1,size=4) +
      coord_flip() + scale_fill_manual(values=c("SHRS Program"="#2c7bb6","Benchmark"="#cccccc")) +
      scale_y_continuous(expand=expansion(mult=c(0,.2))) +
      labs(title="Projected Growth: SHRS vs Benchmarks",x=NULL,y="Projected Growth (%)",fill=NULL) +
      theme_minimal(base_size=13) + theme(legend.position="bottom")
  })

  output$lf_table <- renderDT({ datatable(lf_summary,options=list(dom='t'),rownames=FALSE,class="compact stripe") })

  # ═══ TAB 2: EMPLOYMENT & WAGES ═════════════════════════════════════════════

  output$emp_trends <- renderPlot({
    oews |> ggplot(aes(x=year,y=tot_emp,color=shrs_program)) + geom_line(linewidth=1.2) + geom_point(size=2.5) +
      facet_wrap(~shrs_program,scales="free_y",ncol=3) + scale_y_continuous(labels=comma) +
      scale_x_continuous(breaks=unique(oews$year)) +
      labs(title="National Employment Trends by SHRS Occupation",subtitle="Source: BLS OEWS",x=NULL,y="Total Employment") +
      theme_minimal(base_size=13) + theme(legend.position="none",axis.text.x=element_text(angle=45,hjust=1))
  })

  output$emp_growth_tbl <- renderDT({
    emp_growth |> select(Program=shrs_program,Occupation=occ_title,
      `Start Emp`=emp_first_year,`End Emp`=emp_last_year,Change=abs_change,`Growth (%)`=pct_change) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe") |>
      formatRound(c("Start Emp","End Emp","Change"),digits=0)
  })

  output$wage_comp <- renderPlot({
    oews |> filter(year==latest_year) |>
      ggplot(aes(x=reorder(shrs_program,a_median),y=a_median,fill=shrs_dept)) +
      geom_col(width=.6) + geom_text(aes(label=dollar(a_median)),hjust=-.1,size=4) +
      coord_flip() + scale_y_continuous(labels=dollar,expand=expansion(mult=c(0,.2))) +
      labs(title=paste0("Median Annual Wage (",latest_year,")"),x=NULL,y="Median Annual Wage",fill="Dept") +
      theme_minimal(base_size=13)
  })

  output$wage_trends <- renderPlot({
    oews |> ggplot(aes(x=year,y=a_median,color=shrs_program)) + geom_line(linewidth=1.2) + geom_point(size=2.5) +
      facet_wrap(~shrs_program,scales="free_y",ncol=3) + scale_y_continuous(labels=dollar) +
      scale_x_continuous(breaks=unique(oews$year)) +
      labs(title="Median Annual Wage Trends",subtitle="Source: BLS OEWS",x=NULL,y="Median Annual Wage") +
      theme_minimal(base_size=13) + theme(legend.position="none",axis.text.x=element_text(angle=45,hjust=1))
  })

  # ═══ TAB 3: PROJECTIONS ════════════════════════════════════════════════════

  output$proj_cycles <- renderPlot({
    projections |> ggplot(aes(x=cycle,y=emp_change_pct,fill=shrs_program)) +
      geom_col(position="dodge",width=.7) +
      geom_hline(yintercept=all_occ_growth_pct,linetype="dashed",color="gray40") +
      facet_wrap(~shrs_program,ncol=3,scales="free_y") +
      labs(title="BLS Projected Growth (%) Across Cycles",x="Cycle",y="Projected Growth (%)") +
      theme_minimal(base_size=13) + theme(legend.position="none",axis.text.x=element_text(angle=45,hjust=1))
  })

  output$proj_table <- renderDT({
    proj_latest |> mutate(vs_bench=round(emp_change_pct-all_occ_growth_pct,1),
      signal=case_when(emp_change_pct>=all_occ_growth_pct*2~"Strong Growth",
        emp_change_pct>=all_occ_growth_pct~"Above Average",emp_change_pct>=0~"Below Average",TRUE~"Declining")) |>
      select(Program=shrs_program,Cycle=cycle,`Base (K)`=emp_base,`Proj (K)`=emp_projected,
        `Growth (%)`=emp_change_pct,`vs Bench`=vs_bench,Signal=signal,`Openings/yr`=annual_openings,`Med Wage`=median_wage) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe") |> formatCurrency("Med Wage",digits=0)
  })

  output$sep_chart <- renderPlot({
    separations |> select(shrs_program,lf_exits,occ_transfers,emp_change_numeric) |>
      rename(`Labor Force Exits`=lf_exits,`Occupational Transfers`=occ_transfers,Growth=emp_change_numeric) |>
      pivot_longer(-shrs_program,names_to="component",values_to="value") |>
      ggplot(aes(x=reorder(shrs_program,value,sum),y=value,fill=component)) + geom_col(width=.6) + coord_flip() +
      scale_fill_manual(values=c(Growth="#2c7bb6",`Labor Force Exits`="#d7191c",`Occupational Transfers`="#fdae61")) +
      labs(title="Components of Annual Job Openings",x=NULL,y="Annual Openings (K)",fill=NULL) +
      theme_minimal(base_size=13) + theme(legend.position="bottom")
  })

  output$sep_table <- renderDT({
    separations |> select(Program=shrs_program,`Exit Rate (%)`=lf_exit_rate,
      `Transfer Rate (%)`=occ_transfer_rate,`Total Sep Rate (%)`=total_sep_rate,
      `Annual Openings (K)`=annual_openings) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe")
  })

  # ═══ TAB 4: CREDENTIALS ════════════════════════════════════════════════════

  output$edu_premium_curve <- renderPlot({
    req(edu_premium)
    edu_order <- c("Less than a high school diploma","High school diploma",
                   "Some college, no degree","Associate's degree",
                   "Bachelor's degree","Master's degree","Professional degree","Doctoral degree")
    shrs_tiers <- c("Master's degree","Doctoral degree")
    edu_premium |> mutate(edu_level=factor(edu_level,levels=edu_order)) |> filter(!is.na(edu_level)) |>
      ggplot(aes(x=edu_level,y=median_annual_earnings)) +
      geom_col(aes(fill=edu_level%in%shrs_tiers),width=.7) +
      geom_text(aes(label=dollar(median_annual_earnings)),vjust=-.3,size=3.5) +
      scale_fill_manual(values=c("FALSE"="#cccccc","TRUE"="#2c7bb6"),labels=c("Other","SHRS-relevant"),name=NULL) +
      scale_y_continuous(labels=dollar,expand=expansion(mult=c(0,.15))) +
      labs(title="Median Annual Earnings by Education Level (2024)",x=NULL,y="Median Annual Earnings") +
      theme_minimal(base_size=12) + theme(axis.text.x=element_text(angle=35,hjust=1),legend.position="bottom")
  })

  output$edu_growth_tiers <- renderPlot({
    req(edu_employment)
    edu_employment |> filter(!is.na(emp_change_pct),!str_detect(edu_level,regex("total",ignore_case=TRUE))) |>
      mutate(is_shrs=str_detect(edu_level,regex("master|doctoral|professional",ignore_case=TRUE))) |>
      ggplot(aes(x=reorder(edu_level,emp_change_pct),y=emp_change_pct,fill=is_shrs)) +
      geom_col(width=.6) + geom_text(aes(label=paste0(emp_change_pct,"%")),hjust=-.1,size=3.5) +
      coord_flip() + scale_fill_manual(values=c("FALSE"="#cccccc","TRUE"="#2c7bb6"),labels=c("Other","SHRS"),name=NULL) +
      scale_y_continuous(expand=expansion(mult=c(0,.2))) +
      labs(title="Employment Growth by Entry Education (2024-2034)",x=NULL,y="Growth (%)") +
      theme_minimal(base_size=12) + theme(legend.position="bottom")
  })

  output$edu_premium_tbl <- renderDT({
    req(edu_premium,edu_employment)
    xwalk <- tribble(~e51,~e52,"Doctoral degree","Doctoral or professional degree",
      "Professional degree","Doctoral or professional degree","Master's degree","Master's degree",
      "Bachelor's degree","Bachelor's degree")
    edu_premium |> filter(str_detect(edu_level,regex("master|doctoral|professional|bachelor",ignore_case=TRUE))) |>
      left_join(xwalk,by=c("edu_level"="e51")) |>
      left_join(edu_employment|>select(edu_level,emp_change_pct,median_wage),by=c("e52"="edu_level")) |>
      select(`Education`=edu_level,`Weekly $`=median_weekly_earnings,`Annual $`=median_annual_earnings,
        `Unemp %`=unemployment_rate,`Growth %`=emp_change_pct) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe") |>
      formatCurrency(c("Weekly $","Annual $"),digits=0)
  })

  output$cred_table <- renderDT({
    req(credential_alignment)
    credential_alignment |> select(Program=shrs_program,Dept=shrs_dept,
      `Pitt Awards`=pitt_degree,`BLS Requires`=bls_entry_education,Match=credential_match,
      `% at Pitt Level`=workforce_pct_at_pitt_level,
      `% Bach`=bachelors,`% Mast`=masters,`% Doct`=doctoral) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe") |> formatRound(5:9,1)
  })

  output$cred_score_tbl <- renderDT({
    req(credential_scores)
    credential_scores |> select(Program=shrs_program,`Pitt Awards`=pitt_degree,
      `BLS Requires`=bls_entry_education,Match=credential_match,
      `Workforce %`=workforce_pct_at_pitt_level,`Score (0-5)`=credential_score) |>
      arrange(desc(`Score (0-5)`)) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe") |> formatRound("Workforce %",1)
  })

  output$cred_viz <- renderPlot({
    req(credential_alignment)
    cl <- credential_alignment |> select(shrs_program,bachelors,masters,doctoral) |>
      pivot_longer(-shrs_program,names_to="deg",values_to="pct") |>
      mutate(deg=factor(deg,levels=c("bachelors","masters","doctoral"),labels=c("Bachelor's","Master's","Doctoral+")))
    pm <- credential_alignment |> select(shrs_program,pitt_degree_group,workforce_pct_at_pitt_level) |>
      mutate(deg=factor(case_when(pitt_degree_group=="doctoral"~"Doctoral+",TRUE~"Master's"),
                        levels=c("Bachelor's","Master's","Doctoral+")))
    cl |> ggplot(aes(x=deg,y=pct,fill=deg)) + geom_col(width=.6) +
      geom_point(data=pm,aes(x=deg,y=workforce_pct_at_pitt_level),shape=18,size=5,color="red",inherit.aes=FALSE) +
      facet_wrap(~shrs_program,ncol=3) +
      scale_fill_manual(values=c("Bachelor's"="#fdae61","Master's"="#2c7bb6","Doctoral+"="#1a9641")) +
      labs(title="Workforce Education Distribution",subtitle="Red diamond = Pitt's degree level",
           x=NULL,y="% of Workers",fill=NULL) +
      theme_minimal(base_size=12) + theme(legend.position="bottom",axis.text.x=element_text(angle=30,hjust=1))
  })

  # ═══ TAB 5: INDUSTRY ═══════════════════════════════════════════════════════

  output$ind_presence_tbl <- renderDT({
    req(ind_matrix_shrs); if(nrow(ind_matrix_shrs)==0) return(NULL)
    ind_matrix_shrs |> select(Program=shrs_program,Occupation=occupation_title,
      `2024 (K)`=x2024_employment,`2034 (K)`=projected_2034_employment,
      `Growth %`=employment_percent_change_2024_2034,
      `% of Industry`=x2024_percent_of_industry,`% of Occ`=x2024_percent_of_occupation) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe") |> formatRound(3:7,1)
  })

  output$ind_concentration <- renderPlot({
    req(ind_matrix_shrs); if(nrow(ind_matrix_shrs)==0) return(NULL)
    ind_matrix_shrs |> ggplot(aes(x=reorder(shrs_program,x2024_percent_of_occupation),
      y=x2024_percent_of_occupation)) + geom_col(fill="#2c7bb6",width=.6) +
      geom_text(aes(label=paste0(round(x2024_percent_of_occupation,1),"%")),hjust=-.1,size=4) +
      coord_flip() + scale_y_continuous(expand=expansion(mult=c(0,.3))) +
      labs(title="Share of Occupation in NAICS 621990",x=NULL,y="% of Occupation") + theme_minimal(base_size=13)
  })

  output$ind_missing_tbl <- renderDT({
    socs_present <- if(!is.null(ind_matrix_shrs)) ind_matrix_shrs$occupation_code else character(0)
    socs_missing <- setdiff(target_socs, socs_present)
    missing <- soc_crosswalk |> filter(soc_code %in% socs_missing) |>
      select(Program=shrs_program,Occupation=occupation_title,SOC=soc_code)
    datatable(missing,options=list(dom='t'),rownames=FALSE,class="compact stripe")
  })

  output$ind_top15 <- renderPlot({
    req(ind_matrix)
    ind_matrix |> filter(occupation_type=="Line Item",!is.na(employment_percent_change_2024_2034)) |>
      slice_max(employment_percent_change_2024_2034,n=15) |>
      mutate(is_shrs=occupation_code%in%target_socs,
             label=if_else(is_shrs,paste0(occupation_title," *"),occupation_title)) |>
      ggplot(aes(x=reorder(label,employment_percent_change_2024_2034),
                 y=employment_percent_change_2024_2034,fill=is_shrs)) +
      geom_col(width=.6) + coord_flip() +
      scale_fill_manual(values=c("FALSE"="#cccccc","TRUE"="#2c7bb6"),labels=c("Other","SHRS"),name=NULL) +
      labs(title="Top 15 Fastest-Growing in NAICS 621990",x=NULL,y="Growth %") +
      theme_minimal(base_size=11) + theme(legend.position="bottom")
  })

  # ═══ TAB 6: BLS SKILLS ═════════════════════════════════════════════════════

  output$bls_heatmap <- renderPlot({
    req(bls_skills)
    bls_skills |> ggplot(aes(x=shrs_program,y=reorder(skill,percentile),fill=percentile)) +
      geom_tile(color="white",linewidth=.5) + geom_text(aes(label=percentile),size=2.8) +
      scale_fill_gradient2(low="#d73027",mid="#fee08b",high="#1a9850",midpoint=50,limits=c(0,100),name="Percentile") +
      labs(title="BLS Skill Percentile Ranks by SHRS Program",x=NULL,y=NULL) +
      theme_minimal(base_size=12) + theme(axis.text.x=element_text(face="bold",angle=30,hjust=1),panel.grid=element_blank())
  })

  output$bls_radar <- renderPlot({
    req(bls_skills)
    bls_skills |> ggplot(aes(x=reorder(skill,percentile),y=percentile,fill=shrs_program)) +
      geom_col(width=.7) + geom_hline(yintercept=50,linetype="dashed",color="gray50") +
      coord_flip() + facet_wrap(~shrs_program,ncol=2) +
      scale_fill_manual(values=program_colors) + scale_y_continuous(limits=c(0,100)) +
      labs(title="Skill Profiles by Program",x=NULL,y="Percentile (0-100)") +
      theme_minimal(base_size=10) + theme(legend.position="none")
  })

  output$bls_top3_tbl <- renderDT({
    req(bls_skills)
    bls_skills |> group_by(shrs_program) |> slice_max(percentile,n=3) |> arrange(shrs_program,desc(percentile)) |>
      select(Program=shrs_program,Skill=skill,Percentile=percentile) |>
      datatable(options=list(dom='t',pageLength=30),rownames=FALSE,class="compact stripe")
  })

  output$bls_distinguish_tbl <- renderDT({
    req(bls_skills)
    n_oth <- n_distinct(bls_skills$soc_code)-1
    bls_skills |> group_by(skill) |> mutate(others_mean=(sum(percentile)-percentile)/n_oth) |> ungroup() |>
      mutate(diff=percentile-others_mean) |> group_by(shrs_program) |> slice_max(abs(diff),n=5) |>
      arrange(shrs_program,desc(diff)) |>
      select(Program=shrs_program,Skill=skill,Pctl=percentile,`Others Avg`=others_mean,Diff=diff) |>
      mutate(across(where(is.numeric),~round(.x,1))) |>
      datatable(options=list(dom='t',pageLength=50),rownames=FALSE,class="compact stripe")
  })

  # ═══ TAB 7: O*NET SKILLS ═══════════════════════════════════════════════════

  output$onet_top10 <- renderPlot({
    req(onet_skills)
    onet_skills |> group_by(shrs_program) |> slice_max(importance,n=10) |>
      ggplot(aes(x=reorder(skill,importance),y=importance,fill=shrs_program)) +
      geom_col(width=.7) + coord_flip() + facet_wrap(~shrs_program,ncol=2,scales="free_y") +
      scale_fill_manual(values=program_colors) + scale_y_continuous(limits=c(0,5)) +
      labs(title="Top 10 Skills by Program (O*NET Importance)",x=NULL,y="Importance (1-5)") +
      theme_minimal(base_size=10) + theme(legend.position="none")
  })

  output$onet_heatmap <- renderPlot({
    req(onet_skills)
    onet_skills |> ggplot(aes(x=shrs_program,y=reorder(skill,importance),fill=importance)) +
      geom_tile(color="white",linewidth=.2) + geom_text(aes(label=round(importance,1)),size=2.5) +
      scale_fill_gradient2(low="#d73027",mid="#fee08b",high="#1a9850",midpoint=2.5,limits=c(1,5),name="Imp") +
      labs(title="O*NET Skill Importance",x=NULL,y=NULL) +
      theme_minimal(base_size=11) + theme(axis.text.x=element_text(face="bold",angle=30,hjust=1),panel.grid=element_blank())
  })

  output$onet_cluster_bar <- renderPlot({
    req(onet_clustered)
    onet_clustered |> ggplot(aes(x=cluster,y=avg_importance,fill=shrs_program)) +
      geom_col(position="dodge",width=.7) + scale_fill_manual(values=program_colors) +
      scale_y_continuous(limits=c(0,5)) +
      labs(title="Avg Skill Importance by Cluster",x=NULL,y="Avg Importance (1-5)",fill="Program") +
      theme_minimal(base_size=12) + theme(axis.text.x=element_text(angle=30,hjust=1))
  })

  output$onet_cluster_heat <- renderPlot({
    req(onet_clustered)
    onet_clustered |> ggplot(aes(x=shrs_program,y=cluster,fill=avg_importance)) +
      geom_tile(color="white",linewidth=.5) + geom_text(aes(label=round(avg_importance,2)),size=3.2) +
      scale_fill_gradient2(low="#d73027",mid="#fee08b",high="#1a9850",midpoint=2.5,limits=c(1,5),name="Avg Imp") +
      labs(title="Skill Cluster Heatmap",x=NULL,y=NULL) +
      theme_minimal(base_size=12) + theme(axis.text.x=element_text(face="bold",angle=30,hjust=1),panel.grid=element_blank())
  })

  # ═══ TAB 8: EDUCATION PATHWAYS ═════════════════════════════════════════════

  output$onet_edu_dist <- renderPlot({
    req(onet_edu)
    el <- tribble(~category,~edu_level,1,"Less than HS",2,"HS Diploma/GED",3,"Post-sec Cert",
      4,"Some College",5,"Associate's",6,"Bachelor's",7,"Post-bacc Cert",8,"Master's",
      9,"Post-master's Cert",10,"First Professional",11,"Doctoral",12,"Post-doctoral")
    onet_edu |> filter(element_id=="2.D.1",scale_id=="RL") |>
      mutate(category=as.integer(category),pct=as.numeric(data_value)) |> filter(pct>0) |>
      left_join(el,by="category") |> mutate(edu_level=factor(edu_level,levels=el$edu_level)) |>
      ggplot(aes(x=shrs_program,y=pct,fill=edu_level)) + geom_col(width=.7) +
      scale_fill_viridis_d(option="D",direction=-1,name="Education Level") +
      labs(title="Education Distribution by Occupation (O*NET)",x=NULL,y="% of Workers") +
      theme_minimal(base_size=12) + theme(legend.position="right",axis.text.x=element_text(angle=30,hjust=1))
  })

  output$onet_exp_dist <- renderPlot({
    req(onet_edu)
    xl <- tribble(~category,~experience,1,"None",2,"Up to 1 mo",3,"1-3 mo",4,"3-6 mo",
      5,"6 mo-1 yr",6,"1-2 yr",7,"2-4 yr",8,"4-6 yr",9,"6-10 yr",10,"10+ yr")
    onet_edu |> filter(element_id=="3.A.1",scale_id=="RW") |>
      mutate(category=as.integer(category),pct=as.numeric(data_value)) |> filter(pct>0,category!=11) |>
      left_join(xl,by="category") |> mutate(experience=factor(experience,levels=xl$experience)) |>
      ggplot(aes(x=shrs_program,y=pct,fill=experience)) + geom_col(width=.7) +
      scale_fill_viridis_d(option="C",direction=-1,name="Experience") +
      labs(title="Work Experience Distribution (O*NET)",x=NULL,y="% of Workers") +
      theme_minimal(base_size=12) + theme(legend.position="right",axis.text.x=element_text(angle=30,hjust=1))
  })

  output$onet_ojt_dist <- renderPlot({
    req(onet_edu)
    ol <- tribble(~category,~training,1,"None",2,"1d-1mo",3,"1-3mo",4,"3-6mo",
      5,"6mo-1yr",6,"1-2yr",7,"2-4yr",8,"4-10yr",9,"10+yr")
    df <- onet_edu |> filter(element_id=="3.A.3",scale_id=="OJ") |>
      mutate(category=as.integer(category),pct=as.numeric(data_value)) |> filter(pct>0) |>
      left_join(ol,by="category") |> mutate(training=factor(training,levels=ol$training))
    if(nrow(df)>0) {
      df |> ggplot(aes(x=shrs_program,y=pct,fill=training)) + geom_col(width=.7) +
        scale_fill_viridis_d(option="B",direction=-1,name="OJT") +
        labs(title="On-the-Job Training (O*NET)",x=NULL,y="% of Workers") +
        theme_minimal(base_size=12) + theme(legend.position="right",axis.text.x=element_text(angle=30,hjust=1))
    }
  })

  output$onet_edu_tbl <- renderDT({
    req(onet_edu)
    el <- tribble(~category,~edu_level,1,"Less than HS",2,"HS",3,"Post-sec Cert",4,"Some College",
      5,"Associate's",6,"Bachelor's",7,"Post-bacc",8,"Master's",9,"Post-master's",
      10,"First Prof",11,"Doctoral",12,"Post-doctoral")
    onet_edu |> filter(element_id=="2.D.1",scale_id=="RL") |>
      mutate(category=as.integer(category),pct=round(as.numeric(data_value),1)) |> filter(pct>0) |>
      left_join(el,by="category") |> select(Program=shrs_program,`Education Level`=edu_level,`%`=pct) |>
      datatable(options=list(dom='ft',pageLength=50),rownames=FALSE,class="compact stripe")
  })

  # ═══ TAB 9: SYNTHESIS ══════════════════════════════════════════════════════

  output$synthesis_tbl <- renderDT({
    req(onet_skills,onet_clustered,bls_skills,onet_edu)
    el <- tribble(~category,~edu_level,1,"Less than HS",2,"HS",3,"Post-sec Cert",4,"Some College",
      5,"Associate's",6,"Bachelor's",7,"Post-bacc",8,"Master's",9,"Post-master's",
      10,"First Prof",11,"Doctoral",12,"Post-doctoral")
    dom_edu <- onet_edu |> filter(element_id=="2.D.1",scale_id=="RL") |>
      mutate(category=as.integer(category),pct=as.numeric(data_value)) |>
      group_by(shrs_program) |> slice_max(pct,n=1) |> left_join(el,by="category") |>
      select(shrs_program,dominant_edu=edu_level,edu_pct=pct)
    top_cl <- onet_clustered |> group_by(shrs_program) |> slice_max(avg_importance,n=1) |>
      select(shrs_program,top_cluster=cluster)
    top_bls <- bls_skills |> group_by(shrs_program) |> slice_max(percentile,n=1) |>
      select(shrs_program,top_bls_skill=skill)
    avg_int <- onet_skills |> group_by(shrs_program) |>
      summarise(avg_skill=round(mean(importance,na.rm=TRUE),2),.groups="drop")
    syn <- soc_crosswalk_full |> select(shrs_program,shrs_dept) |>
      left_join(dom_edu,by="shrs_program") |> left_join(top_cl,by="shrs_program") |>
      left_join(top_bls,by="shrs_program") |> left_join(avg_int,by="shrs_program")
    syn |> select(Program=shrs_program,Dept=shrs_dept,`Primary Edu`=dominant_edu,`% at Level`=edu_pct,
      `Top Cluster`=top_cluster,`Top BLS Skill`=top_bls_skill,`Skill Intensity`=avg_skill) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe") |> formatRound("% at Level",1)
  })

  output$positioning <- renderPlot({
    req(onet_skills,onet_edu)
    em <- tribble(~category,~edu_years,6,16,8,18,11,21)
    el <- tribble(~category,~edu_level,1,"<HS",2,"HS",3,"Cert",4,"Some",5,"Assoc",
      6,"Bach",7,"Post-bacc",8,"Master's",9,"Post-mast",10,"Prof",11,"Doctoral",12,"Post-doc")
    ai <- onet_skills |> group_by(shrs_program) |> summarise(avg_imp=round(mean(importance,na.rm=TRUE),2),.groups="drop")
    de <- onet_edu |> filter(element_id=="2.D.1",scale_id=="RL") |>
      mutate(category=as.integer(category),pct=as.numeric(data_value)) |>
      group_by(shrs_program) |> slice_max(pct,n=1) |> ungroup() |>
      left_join(em,by="category") |> select(shrs_program,edu_years)
    pos <- ai |> left_join(de,by="shrs_program") |> filter(!is.na(edu_years))
    pos |> ggplot(aes(x=edu_years,y=avg_imp,color=shrs_program,label=shrs_program)) +
      geom_point(size=5) + geom_text(vjust=-1.2,size=4.5,fontface="bold") +
      scale_color_manual(values=program_colors) +
      scale_x_continuous(breaks=c(16,18,21),labels=c("Bachelor's","Master's","Doctoral")) +
      labs(title="Program Positioning: Education vs Skill Intensity",
           x="Dominant Education Level",y="Avg Skill Importance (1-5)") +
      theme_minimal(base_size=13) + theme(legend.position="none")
  })

  output$dendrogram <- renderPlot({
    req(bls_skills)
    sm <- bls_skills |> select(shrs_program,skill,percentile) |>
      pivot_wider(names_from=skill,values_from=percentile)
    if(nrow(sm)>=3) {
      d <- dist(sm|>select(-shrs_program)); hc <- hclust(d,method="ward.D2")
      hc$labels <- sm$shrs_program
      plot(hc,main="SHRS Programs Clustered by BLS Skill Similarity",
           sub="Ward's method on 17 skill dimensions",xlab="",ylab="Distance")
    }
  })

  output$shared_skills_tbl <- renderDT({
    req(bls_skills)
    bls_skills |> group_by(skill) |>
      summarise(min_pctl=min(percentile),max_pctl=max(percentile),avg_pctl=mean(percentile),.groups="drop") |>
      filter(min_pctl>=50) |> arrange(desc(avg_pctl)) |>
      select(Skill=skill,`Min Pctl`=min_pctl,`Max Pctl`=max_pctl,Avg=avg_pctl) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe")
  })

  output$unique_skills_tbl <- renderDT({
    req(bls_skills)
    n_oth <- n_distinct(bls_skills$soc_code)-1
    bls_skills |> group_by(skill) |> mutate(others_mean=(sum(percentile)-percentile)/n_oth) |> ungroup() |>
      mutate(diff=percentile-others_mean) |> group_by(shrs_program) |> slice_max(diff,n=1) |>
      select(Program=shrs_program,`Signature Skill`=skill,Pctl=percentile,`Others Avg`=others_mean,Advantage=diff) |>
      mutate(across(where(is.numeric),~round(.x,1))) |>
      datatable(options=list(dom='t'),rownames=FALSE,class="compact stripe")
  })

}

shinyApp(ui=ui, server=server)
