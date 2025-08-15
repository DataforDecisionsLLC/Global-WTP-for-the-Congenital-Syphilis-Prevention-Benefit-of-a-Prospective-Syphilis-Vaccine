set more off
clear all
set type double
set excelxlsxlargefile on
version 18.0

/*
Instructions: Users need to replace "...." with the appropriate file path.
*/ 

gl root   "...."
gl raw    "$root\RAW DATA"
gl output "$root\OUTPUT"

/*
inputs:
age_aggregated_tree_results_vax_novax_truncated.dta created in: make_age_aggregated_tree_results_vax_novax_truncated
outputs:
basecase_country_tables.xlsx
*/

capture log close 
log using "$output\ANALYSIS\make_basecase_country_tables", text replace

////////////////////////////////////////////////////////////////////////////////
/////////////////// export base-case country level results /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BASECASE\age_aggregated_tree_results_vax_novax_truncated", clear 

keep country income_group_1 pop15 d_cost d_daly pcgdp wtp

sort country 
count 

replace d_cost = -1*d_cost 

replace income_group_1 = "Low Income" if income_group_1 =="Low income"

order income_group_1 country d_cost d_daly wtp

gen sortme=0 
replace sortme=1 if income_group_1 == "Low Income"
replace sortme=2 if income_group_1 == "Middle Income"
replace sortme=3 if income_group_1 == "High Income"
assert sortme>0 
sort sortme country 
drop sortme

export excel using "$output\ANALYSIS\basecase_country_tables.xlsx", ///
first(var) sheet("stata") sheetreplace  

log close 

exit 

// end