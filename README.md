# Global-WTP-for-the-Congenital-Syphilis-Prevention-Benefit-of-a-Prospective-Syphilis-Vaccine
This document contains supplementary material for the article “Global willingness-to-pay for the congenital-syphilis prevention benefit of a prospective syphilis vaccine” by: JP Sevilla, Daria Burnes and David E. Bloom. This material was created under a Creative Commons License Attribution 4.0 International.
# **<ins>Repository contents</ins>**
## CODE – This set of 13 folders contains all Stata code used in the analysis:
### - CODE-ANALYSIS     
### - CODE-DALY         
### - CODE-DECISION TREE
### - CODE-DIRECT COSTS 
### - CODE-ECONOMIC     
### - CODE-FOREX        
### - CODE-GEO DATA     
### - CODE-IHME         
### - CODE-INDIRECT COSTS
### - CODE-LIFE TABLES  
### - CODE-MANUSCRIPT   
### - CODE-MASTERS      
### - CODE-POPULATION  
## OUTPUT – This set of nine folders contains intermediate outputs and results not presented in the manuscript or appendix: 
### - OUTPUT-ANALYSIS   
### - OUTPUT-BASE FILE 
### - OUTPUT-ECONOMIC DATA
### - OUTPUT-FERTILITY.zip
### - OUTPUT-FOREX      
### - OUTPUT-GEO DATA  
### - OUTPUT-MANUSCRIPT 
### - OUTPUT-POPULATION
### - OUTPUT-TREE RESULTS
### The following files contain intermediate outputs and results not presented in the manuscript or appendix:
### - general_population_annual_medical_costs_per_capita_single_ages.zip
### - indirect_cost_hearing_loss_single_ages.zip
### - pcgdp_series_single_ages.zip
### - pcgdp_trajectory_birth_cohort.zip
### - raw_life_tables.zip
### - raw_life_tables_australia_2019.dta
### - raw_life_tables_females.zip
### - single_age_general_population_annual_medical_costs_w_life_tables.zip
### - single_age_hearing_loss_costs.zip
### - single_age_hearing_loss_costs_w_life_tables.zip
### - single_age_indirect_hearing_loss_costs_w_life_tables.zip
### Note that per our license restrictions, we cannot share any files that contain raw Global Burden of Disease Study 2021 (GBD 2021) data.
## RAW DATA – This set of 18 folders contains raw data used in the analysis: 
### - RAW DATA-DHS
### - RAW DATA-DIRECT COSTS
### - RAW DATA-FERTILITY RATES
### - RAW DATA-FOREX    
### - RAW DATA-GAVI     
### - RAW DATA-GEM      
### - RAW DATA-GEO DATA 
### - RAW DATA-GUTTMACHER
### - RAW DATA-HUANG    
### - RAW DATA-IMF      
### - RAW DATA-INDIRECT & INTANGIBLE COSTS
### - RAW DATA-KORENROMP
### - RAW DATA-NTA      
### - RAW DATA-UNICEF   
### - RAW DATA-WDI      
### - RAW DATA-WHO      
### - RAW DATA-WHO CHOICE
### - RAW DATA-WPP
## The following compressed files contain raw data used in the analysis:
### - WPP2022_MORT_F06_1_SINGLE_AGE_LIFE_TABLE_PROJECTIONS_BOTH_SEXES-Medium 2022-2049 import.zip
### - WPP2022_MORT_F06_1_SINGLE_AGE_LIFE_TABLE_PROJECTIONS_BOTH_SEXES-Medium 2050-2079 import.zip
### - WPP2022_MORT_F06_3_SINGLE_AGE_LIFE_TABLE_PROJECTIONS_FEMALE-Medium 2022-2049 import.zip
### - WPP2022_MORT_F06_3_SINGLE_AGE_LIFE_TABLE_PROJECTIONS_FEMALE-Medium 2050-2079 import.zip
## **<ins>GBD 2021 data exclusions and redactions</ins>**
## Per our license restrictions, we are not able to share GBD 2021 data. Therefore, the RAW DATA folder excludes GBD 2021 data downloads, and we deleted GBD 2021 data from the following Stata data files:
### - analytical_data_ihme_countries_age15_cohort_truncated.dta
### - bia_basefile_age15_cohort.dta
### - analytical_data_ihme_countries_age20_cohort.dta
### - analytical_data_ihme_countries_age25_cohort.dta
### - analytical_data_ihme_countries_age15_cohort_truncated_lower.dta
### - analytical_data_ihme_countries_age15_cohort_truncated_upper.dta
### - analytical_data_ihme_countries_age15_cohort_tree_basefile govt_costs.dta 
### - analytical_data_ihme_countries_age15_cohort_tree_basefile 0pct_health_0pct_costs.dta
### - analytical_data_ihme_countries_age15_cohort_tree_basefile 0pct_health_3pct_costs.dta
### - analytical_data_ihme_countries_age15_cohort_tree_basefile 6pct_health_6pct_costs.dta
### - analytical_data_ihme_countries_age15_cohort_tree_basefile direct_costs_minus_20_pct.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile direct_costs_plus_20_pct.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile fertility_high.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile fertility_low.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile indirect_costs_minus_20_pct.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile indirect_costs_plus_20_pct.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile prob_abo.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile prob_true_positive.dta
### - analytical_data_ihme_countries_age15_cohort_tree_basefile ve50_wane10.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile ve50_wane5.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile ve80_wane10.dta
###	- analytical_data_ihme_countries_age15_cohort_tree_basefile who_emtct.dta
###	- age_aggregated_tree_results_vax_novax_truncated.dta
### - age_aggregated_tree_results_vax_novax_tree_results age20_cohort.dta
###	- age_aggregated_tree_results_vax_novax_tree_results age25_cohort.dta
###	- age_aggregated_tree_results_vax_novax_tree_results govt_costs.dta 
###	- age_aggregated_tree_results_vax_novax_tree_results 0pct_health_0pct_costs.dta
###	- age_aggregated_tree_results_vax_novax_tree_results 0pct_health_3pct_costs.dta
###	- age_aggregated_tree_results_vax_novax_tree_results 6pct_health_6pct_costs.dta
###	- age_aggregated_tree_results_vax_novax_tree_results direct_costs_minus_20_pct.dta
###	- age_aggregated_tree_results_vax_novax_tree_results direct_costs_plus_20_pct.dta
###	- age_aggregated_tree_results_vax_novax_tree_results fertility_high.dta
###	- age_aggregated_tree_results_vax_novax_tree_results fertility_low.dta
###	- age_aggregated_tree_results_vax_novax_tree_results indirect_costs_minus_20_pct.dta
###	- age_aggregated_tree_results_vax_novax_tree_results indirect_costs_plus_20_pct.dta
###	- age_aggregated_tree_results_vax_novax_tree_results lower.dta
###	- age_aggregated_tree_results_vax_novax_tree_results prob_abo.dta
###	- age_aggregated_tree_results_vax_novax_tree_results true_positive.dta
###	- age_aggregated_tree_results_vax_novax_tree_results upper.dta
###	- age_aggregated_tree_results_vax_novax_tree_results ve50_wane10.dta
###	- age_aggregated_tree_results_vax_novax_tree_results ve50_wane5.dta
###	- age_aggregated_tree_results_vax_novax_tree_results ve80_wane10.dta
###	- age_aggregated_tree_results_vax_novax_tree_results who_emtct.dta
## **<ins>Notes on running code</ins>**
### 1. Due to the GBD 2021 data exclusions and redactions described above:
###	a. It is not possible to replicate all intermediate outputs using the data shared on this site.
###	b. It is not possible to replicate all the results presented in our manuscript and appendix using the data shared on this site. 
###	c. Error messages may be generated when running Stata .do files that rely on GBD 2021 data.
###	2. The top of each Stata .do file has a list of the input files used and output files generated by the program. 
###	3. To run programs, the user will need to replace the “……” file paths with the file path appropriate to their drive and directory. 
###	4. Each of the 12 Stata .do files in “CODE-MASTERS” runs a set of Stata .do files in batch mode. The individual .do files in these “master” programs must be run in the order given in the “master” do-files.
###	5. With the caveat that the GBD 2021 data exclusion and redactions noted above will prevent users from running some of our code and replicating all outputs, the order in which the master do-files contained in “CODE-MASTERS” would be run to replicate our analysis is given in grand_master.do.












