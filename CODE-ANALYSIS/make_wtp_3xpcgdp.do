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
tree_results_cost_novax_collapsed_truncated.dta created in: make_age_aggregated_tree_results_vax_novax_truncated.do  
tree_results_cost_vax_collapsed_truncated.dta created in: make_age_aggregated_tree_results_vax_novax_truncated.do 
tree_results_daly_novax_collapsed_truncated.dta created in: make_age_aggregated_tree_results_vax_novax_truncated.do 
tree_results_daly_vax_collapsed_truncated.dta created in: make_age_aggregated_tree_results_vax_novax_truncated.do 
outputs:
Final results table.xlsx; 'wtp_3xpcgdp' tab 
*/

capture log close 
log using "$output\ANALYSIS\BASECASE\make_wtp_3xpcgdp", text replace

////////////////////////////////////////////////////////////////////////////////
//////// combine the collapsed files; compute d_cost and d_daly ////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\tree_results_cost_novax_collapsed_truncated", clear
merge 1:1 country year age using "$output\DECISION TREE\TREE RESULTS\tree_results_cost_vax_collapsed_truncated"
assert _m==3 
drop _m 
merge 1:1 country year age using "$output\DECISION TREE\TREE RESULTS\tree_results_daly_novax_collapsed_truncated"
assert _m==3 
drop _m 
merge 1:1 country year age using "$output\DECISION TREE\TREE RESULTS\tree_results_daly_vax_collapsed_truncated"
assert _m==3 
drop _m 

foreach x in cost daly {
	gen d_`x' = `x'_novax - `x'_vax
}

isid country 
sort country 

compress 
save "$output\ANALYSIS\BASECASE\wtp_3xpcgdp", replace 

////////////////////////////////////////////////////////////////////////////////
////////// map on 2030 pcgdp; compute wtp and wtp as a % of pcgdp //////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\ANALYSIS\BASECASE\wtp_3xpcgdp", clear 

assert year == 2030 
merge 1:1 country year using "$output\ECONOMIC DATA\pcgdp_series", keepusing(country year pcgdp)
assert _m!=1 
assert year!=2030 if _m==2 
keep if _m==3 
drop _m 
sort country 

gen wtp = (3*pcgdp*d_daly) + d_cost

sum wtp, d

order country year age year wtp d_cost d_daly
keep  country year age year wtp d_cost d_daly

compress 
save "$output\ANALYSIS\BASECASE\wtp_3xpcgdp", replace 

////////////////////////////////////////////////////////////////////////////////
/////////////// map on the population age 15 year olds in 2030 /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BASECASE\wtp_3xpcgdp", clear 
assert year==2030

merge 1:1 country year using "$output\POPULATION\wpp_single_age_population_females_15_49", ///
keepusing(country year pop15)
assert _m!=1  
keep if _m==3 
drop _m 
sort country 

compress 
save "$output\ANALYSIS\BASECASE\wtp_3xpcgdp", replace 

////////////////////////////////////////////////////////////////////////////////
///////////////////////// map on the income group //////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\GEO DATA\who_regions_income_groups", clear 
keep country income_group_1
duplicates drop 

merge 1:1 country using "$output\ANALYSIS\BASECASE\wtp_3xpcgdp"
assert _m!= 2
keep if _m==3 
drop _m 
sort country

assert income_group_1 !="" 

assert year == 2030 
assert age==15 
drop year age 

save "$output\ANALYSIS\BASECASE\wtp_3xpcgdp", replace 

log close 

exit 

// end