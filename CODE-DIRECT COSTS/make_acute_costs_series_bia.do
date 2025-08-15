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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_acute_costs_series_bia", text replace

/*
inputs:
acute_costs_series.dta created in: make_acute_costs_series.do 
government_share_health_expenditures.dta created in: make_government_share_health_expenditures.do
outputs:
acute_costs_series_bia.dta
*/

////////////////////////////////////////////////////////////////////////////////
//// compute median percent pcgdp of acute medical costs paid by government ////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\acute_costs_series" , clear 

merge m:1 country using "$output\ECONOMIC DATA\government_share_health_expenditures", keepusing(country pct_gov_2019)
assert _m!=1
keep if _m==3 
drop _m 

foreach c in lbwpt cs nd nonABO_15_19 nonABO_20_49 stillbirth_15_19 stillbirth_20_49 {
	replace acute_cost_`c' = acute_cost_`c'*pct_gov_2019
}

drop pct_gov_2019

compress

save "$output\ECONOMIC DATA\DIRECT COSTS\acute_costs_series_bia", replace

log close 

exit 

// end
