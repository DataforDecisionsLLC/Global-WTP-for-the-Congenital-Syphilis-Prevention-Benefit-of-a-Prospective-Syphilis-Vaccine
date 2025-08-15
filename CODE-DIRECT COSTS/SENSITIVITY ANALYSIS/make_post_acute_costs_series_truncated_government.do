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

capture log close
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_post_acute_costs_series_truncated_government", text replace

/*
inputs:
post_acute_costs_series_truncated.dta created in: make_post_acute_costs_series_truncated.do
government_share_health_expenditures.dta created in: make_government_share_health_expenditures.do
outputs:
post_acute_costs_series_truncated_government.dta
*/

use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_series_truncated", replace

merge m:1 country using "$output\ECONOMIC DATA\government_share_health_expenditures", keepusing(country pct_gov_2019)
assert _m!=1 
keep if _m==3 
drop _m 
sort country year 

foreach cost in hearingloss lbwpt neurosyph nonABO {
	replace lifetime_cost_`cost' = lifetime_cost_`cost'*pct_gov_2019
}

drop pct_gov_2019

save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_series_truncated_government", replace

log close 

exit 

// end