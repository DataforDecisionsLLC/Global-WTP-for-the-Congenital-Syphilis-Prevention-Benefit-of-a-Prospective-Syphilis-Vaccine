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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_post_acute_costs_series_truncated_0pct", text replace

/*
inputs:
general_population_lifetime_medical_costs_truncated_0pct.dta created in: make_general_population_lifetime_medical_costs_truncated_0pct.do 
lifetime_expected_preterm_costs_truncated.dta created in: make_post_acute_costs_series_truncated.do 
lifetime_expected_hearing_loss_costs_truncated_0pct.dta created in: make_lifetime_expected_hearing_loss_costs_truncated_0pct.do
outputs:
post_acute_costs_series_truncated_0pct.dta
*/

////////////////////////////////////////////////////////////////////////////////
//// extrapolate lifetime cerebral palsey (neurosyphilis) costs as 1.8 times ///
///// general population lifetime medical costs citing the results in the //////
//////////////// abstract of Park et al for South Korea ////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated_0pct", clear 
gen cost_ns = 1.8*cost 
drop cost 
ren cost_ns cost 
replace healthstate="neurosyphilis"

order country year healthstate cost duration incremental discounted

save "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_neurosyphilis_costs_truncated_0pct" , replace 

////////////////////////////////////////////////////////////////////////////////
///////////////// combine all ABO and non-ABO post-acute costs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_preterm_costs_truncated", clear
append using "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_neurosyphilis_costs_truncated_0pct" 
append using "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated_0pct" 
append using "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated_0pct" 

sort country year healthstate 

assert duration == "lifetime"
drop discounted duration 
tab healthstate incremental , m 

drop incremental

replace healthstate="lbwpt" if healthstate=="LBW/preterm"
replace healthstate="hearingloss" if healthstate=="hearing loss"
replace healthstate="neurosyph" if healthstate=="neurosyphilis"
replace healthstate="nonABO" if healthstate=="non-ABO"

ren cost lifetime_cost_
reshape wide lifetime_cost_, i(country year ) j(healthstate) string

// add the nonABO cost to LBW/preterm and hearing loss since they are both incremental costs

replace lifetime_cost_hearingloss = lifetime_cost_hearingloss + lifetime_cost_nonABO
replace lifetime_cost_lbwpt = lifetime_cost_lbwpt + lifetime_cost_nonABO

sort country year 
compress 

drop if year<2030

foreach c in lifetime_cost_hearingloss lifetime_cost_lbwpt lifetime_cost_neurosyph lifetime_cost_nonABO {
	assert `c'<.
}

save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_series_truncated_0pct", replace

log close 

exit 

// end