
/*
Instructions: 
Users need to replace "...." with the appropriate file path.
Do-files must be run in the order listed.
*/ 

do "....\CODE\ANALYSIS\make_age_aggregated_tree_results_vax_novax_truncated.do"

do "....\CODE\ANALYSIS\make_age_aggregated_tree_results_vax_novax_bia.do"

do "....\CODE\ANALYSIS\SENSITIVITY ANALYSIS\make_age_aggregated_tree_results_vax_novax_age20_cohort.do"

do "....\CODE\ANALYSIS\SENSITIVITY ANALYSIS\make_age_aggregated_tree_results_vax_novax_age25_cohort.do"

do "....\CODE\ANALYSIS\SENSITIVITY ANALYSIS\make_age_aggregated_tree_results_vax_novax_sensitivity_analyses.do"

do "....\CODE\ECONOMIC\make_gavi_eligible_countries.do"

do "....\CODE\ECONOMIC\make_gavi_status_2030.do"

do "....\CODE\ANALYSIS\make_wtp_3xpcgdp.do"

do "....\CODE\ANALYSIS\make_table_2.do"

do "....\CODE\ANALYSIS\make_basecase_country_tables.do"

do "....\CODE\ANALYSIS\make_bar_chart.do"

do "....\CODE\MANUSCRIPT\make_gavi_country_table.do"

do "....\CODE\MANUSCRIPT\model_input_summary_statistics.do"
