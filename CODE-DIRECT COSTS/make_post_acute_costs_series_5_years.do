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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_post_acute_costs_series_5_years", text replace

/*
inputs:
post_acute_costs_donors_&_target_countries.dta created in: make_post_acute_costs_series_truncate.do 
pcgdp_series.dta created in: make_pcgdp_series.do 
general_population_lifetime_medical_costs_5_years.dta created in: make_general_population_lifetime_medical_costs_5_years.do
lifetime_expected_hearing_loss_costs_5_years.dta created in: make_lifetime_expected_hearing_loss_costs_5_years.do
government_share_health_expenditures.dta created in: make_government_share_health_expenditures.do
outputs:
lifetime_expected_preterm_costs_5_years.dta 
post_acute_costs_series_5_years.dta
*/

////////////////////////////////////////////////////////////////////////////////
/////////////// compute the percent pcgdp of direct costs //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_donors_&_target_countries", clear

keep if lookup=="64_LBW_preterm_US_2005_USD" 

gen cost_annual = post_acute_cost_2019_USD/8
gen cost_5years = cost_annual*5

gen pct_pcgdp = cost_5years/pcgdp2019usd

list healthstate country source pct_pcgdp duration incremental discounted, sepby(healthstate)

keep healthstate country source pct_pcgdp duration incremental discounted
save "$output\ECONOMIC DATA\DIRECT COSTS\lbw_preterm_pct_pcgdp_ages_5_years", replace 

////////////////////////////////////////////////////////////////////////////////
/////// extrapolate LBW/preterm lifetime costs based on 54.5% of pcgdp /////////
////////// from IOM 2007 for USA for ages 0-7 years ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\lbw_preterm_pct_pcgdp_ages_5_years", clear 
keep pct_pcgdp duration incremental discounted
append using "$output\ECONOMIC DATA\pcgdp_series"

foreach var in pct_pcgdp duration incremental discounted {
	replace `var' = `var'[_n-1] if _n>1
}

drop if country==""

gen cost = pct_pcgdp*pcgdp 
gen healthstate="LBW/preterm"
keep  country year healthstate cost duration incremental discounted who_region income_group_1
order country year healthstate cost duration incremental discounted who_region income_group_1

save "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_preterm_costs_5_years" , replace 

////////////////////////////////////////////////////////////////////////////////
//// extrapolate lifetime cerebral palsey (neurosyphilis) costs as 1.8 times ///
///// general population lifetime medical costs citing the results in the //////
//////////////// abstract of Park et al for South Korea ////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_5_years", clear 
gen cost_ns = 1.8*cost 
drop cost 
ren cost_ns cost 
replace healthstate="neurosyphilis"

order country year healthstate cost duration incremental discounted

save "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_neurosyphilis_costs_5_years" , replace 

////////////////////////////////////////////////////////////////////////////////
///////////////// combine all ABO and non-ABO post-acute costs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_preterm_costs_5_years", clear 
append using "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_neurosyphilis_costs_5_years" 
append using "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_5_years"
append using "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_5_years"

sort country year healthstate 
drop discounted duration who_region income_group_1 incremental

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
drop if year>2034

foreach c in lifetime_cost_hearingloss lifetime_cost_lbwpt lifetime_cost_neurosyph lifetime_cost_nonABO {
	assert `c'<.
}

save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_series_5_years", replace

////////////////////////////////////////////////////////////////////////////////
///////////////// keep the government share of costs for bia ///////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_series_5_years", replace

merge m:1 country using "$output\ECONOMIC DATA\government_share_health_expenditures", keepusing(country pct_gov_2019)
assert _m!=1 
keep if _m==3 
drop _m 
sort country year 

foreach cost in hearingloss lbwpt neurosyph nonABO {
	replace lifetime_cost_`cost' = lifetime_cost_`cost'*pct_gov_2019
}

drop pct_gov_2019

save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_series_5_years", replace


log close 

exit 

// end