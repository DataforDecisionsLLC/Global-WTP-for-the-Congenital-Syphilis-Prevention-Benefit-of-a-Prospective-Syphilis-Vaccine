
/*
Instructions: 
Users need to replace "...." with the appropriate file path.
Do-files must be run in the order listed.
*/ 

do "....\CODE\GEO DATA\make_regions.do"

do "....\CODE\IHME\make_ihme_country_list_syphilis_with_geo.do"

do "....\CODE\GEO DATA\make_who_regions_income_groups.do"

do "....\CODE\LIFE TABLES\make_raw_life_tables_females.do"

do "....\CODE\LIFE TABLES\make_raw_life_tables.do"

do "....\CODE\POPULATION\make_wpp_single_age_population_females_15_49.do"

do "....\CODE\FOREX\make_forex_2010_and_2019.do"

do "....\CODE\ECONOMIC\wdi_ihme_country_match.do"

do "....\CODE\ECONOMIC\make_2019_pcgdp.do"

do "....\CODE\ECONOMIC\make_pcgdp_series.do"

do "....\CODE\MASTERS\master_ihme_data.do"

do "....\CODE\MASTERS\master_direct_costs.do"

do "....\CODE\MASTERS\master_direct_costs_sensitivity_analysis.do"

do "....\CODE\MASTERS\master_indirect_costs.do"

do "....\CODE\MASTERS\master_daly.do"

do "....\CODE\MASTERS\master_daly_sensitivity_analysis.do"

do "....\CODE\MASTERS\master_decision_tree_basefile.do"

do "....\CODE\MASTERS\master_decision_tree_basefile_sensitivity_analysis.do"

do "....\CODE\MASTERS\master_decision_tree_results.do"

do "....\CODE\MASTERS\master_decision_tree_results_sensitivity_analysis.do"

do "....\CODE\MASTERS\master_analysis.do"