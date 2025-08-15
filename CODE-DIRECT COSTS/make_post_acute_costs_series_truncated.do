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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_post_acute_costs_series_truncated", text replace

/*
inputs:
Congenital Syphilis Study-Post-acute direct costs-20231204.xlsx
wdi_forex.dta created in: make_acute_costs_2019_USD.do 
wdi_gdp_deflators.dta created in: make_acute_costs_2019_USD.do 
2019_pcgdp.dta created in: make_2019_pcgdp.do 
pcgdp_series.dta created in: make_pcgdp_series.do 
single_age_general_population_annual_medical_costs_w_life_tables.dta created in: make_general_population_lifetime_medical_costs_truncated.do 
general_population_lifetime_medical_costs_truncated.dta created in: make_general_population_lifetime_medical_costs_truncated.do 
lifetime_expected_hearing_loss_costs_truncated.dta created in: make_lifetime_expected_hearing_loss_costs_truncated.do
outputs:
post_acute_costs_donors_&_target_countries.dta
lifetime_expected_preterm_costs_truncated.dta 
post_acute_costs_series_truncated.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////////////////////// read in the direct costs /////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/DIRECT COSTS/Congenital Syphilis Study-Post-acute direct costs-20231204.xlsx", ///
clear first sheet("POST-ACUTE COSTS") case(lower) cellrange(A2:N77)
drop if post_acute_cost==.
drop if exclude=="yes"
drop exclude acute* 
gen donor=1 
compress
ren controlcosts control_cost
order donor healthstate country currency post_acute_cost control_cost

split currency, parse("")
ren currency1 year 
destring year, replace
drop currency 
ren currency2 currency

replace country = "United States" if country=="US" 
replace country = "United Kingdom" if inlist(country,"UK" ,"England and Wales")
sort healthstate country 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_donors_raw", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// create a file of currencies for conversion //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_donors_raw", clear 
keep country currency year
duplicates drop
sort country currency year
compress
save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_cost_currencies", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////////// get the forex variables from WDI /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_cost_currencies", clear 
keep country 
duplicates drop 

merge 1:1 country using "$output\FOREX\wdi_forex"
assert _m!=1 
keep if _m==3 
drop _m 

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_cost_currencies"
assert _m==3 
drop _m 

order country year currency
sort country year 

forvalues y = 2000/2022 {
	ren yr`y' forex_`y'
}

drop if currency=="INT$"

reshape long forex_, i(country currency year) j(forex)
sort country year 
keep if year==forex 
drop forex
ren forex_ forex

// get the 2019 forex 

merge m:1 country using "$output\FOREX\wdi_forex", keepusing(country yr2019)
assert _m!=1 
keep if _m==3 
drop _m 
ren yr2019 forex_2019
sort country year 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////////// get GDP deflators from WDI data /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_cost_currencies", clear 
keep country 
duplicates drop 

merge 1:1 country using "$output\ECONOMIC DATA\wdi_gdp_deflators"
assert _m!=1 
keep if _m==3 
drop _m 

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_cost_currencies"
assert _m==3 
drop _m 

order country year currency
sort country year 

forvalues y = 2000/2022 {
	ren yr`y' deflator_`y'
}

drop if currency=="INT$"

reshape long deflator_, i(country currency year) j(deflator)
sort country year 
keep if year==deflator 
drop deflator
ren deflator_ deflator

// get the 2019 deflator 

merge m:1 country using "$output\ECONOMIC DATA\wdi_gdp_deflators", keepusing(country yr2019)
assert _m!=1 
keep if _m==3 
drop _m 
ren yr2019 deflator_2019
sort country year 

// map to the forex file 

merge 1:1 country currency year using "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_forex_deflators"
assert _m==3 
drop _m 
sort country year 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
////////////// map the currency conversion factors to the costs ////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_donors_raw" , clear

merge m:1 country currency year using "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_forex_deflators"
assert _m==3 
drop _m 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_w_forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////// convert baseyear USDs to LCUs ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_w_forex_deflators", clear

replace post_acute_cost = post_acute_cost*forex if currency=="USD" & country!="United States"
replace control_cost =  control_cost*forex        if currency=="USD" & country!="United States"

////////////////////////////////////////////////////////////////////////////////
///////// convert baseyear LCUs to 2019 LCUs using local GDP deflator //////////
////////////////////////////////////////////////////////////////////////////////

gen inflation_adj = deflator_2019/deflator

levelsof year, local(year)
foreach y of local year {
	di "The currency year is `y'"
	tab country if year==`y'
	sum inflation_adj if year==`y'
}

gen post_acute_cost_2019_LCU = post_acute_cost*inflation_adj
gen control_cost_2019_LCU = control_cost*inflation_adj

drop deflator* post_acute_cost control_cost inflation_adj

////////////////////////////////////////////////////////////////////////////////
////////////////////// convert 2019 LCUs to 2019 USDs //////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach c in post_acute control {
	gen `c'_cost_2019_USD = `c'_cost_2019_LCU/forex_2019
}

drop forex* currency year *_LCU

gen incremental=""
replace incremental = "yes" if incrementalacutecosts=="Incremental" 
replace incremental = "no" if incrementalacutecosts=="Not incremental" 
tab incremental incrementalacutecosts, m
drop incrementalacutecosts

sort healthstate  country 

assert post_acute_cost_2019_USD<.

ren post_acute_duration duration

order donor healthstate country pcgdp2019usd post_acute_cost_2019_USD control_cost_2019_USD ///
duration incremental discounted

compress

sort healthstate country 

save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_donors_2019_USD", replace

////////////////////////////////////////////////////////////////////////////////
// map 2019 PCGDP from all IHME countries to direct costs for donor countries //
////////////////////////////////////////////////////////////////////////////////

use  "$output\ECONOMIC DATA\2019_pcgdp", clear 
ren yr2019_pcgdp_current_2019USD pcgdp2019usd

merge 1:m country pcgdp2019usd using "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_donors_2019_USD"
assert _m !=2 
replace donor=0 if _m==1
drop _m

order healthstate donor country pcgdp2019usd post_acute_cost_2019_USD control_cost_2019_USD duration incremental discounted
sort  healthstate country

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_donors_&_target_countries", replace

////////////////////////////////////////////////////////////////////////////////
/////////////// compute the percent pcgdp of direct costs //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_donors_&_target_countries", clear
keep if donor==1 
gen pct_pcgdp = post_acute_cost_2019_USD/pcgdp2019usd
order healthstate country pcgdp2019usd post_acute_cost_2019_USD pct_pcgdp duration incremental discounted ///
control_cost_2019_USD WHO_region income
sort healthstate country duration
replace duration = "age 0-18" if duration=="Discharge from initial hosplitalization through age 18"

list healthstate country source pct_pcgdp duration incremental discounted, sepby(healthstate)

keep if lookup=="25_LBW_preterm_US_2005_USD" 

list healthstate country source pct_pcgdp duration incremental discounted, sepby(healthstate)
keep healthstate country source pct_pcgdp duration incremental discounted

save "$output\ECONOMIC DATA\DIRECT COSTS\lbw_preterm_pct_pcgdp", replace 

////////////////////////////////////////////////////////////////////////////////
/////// extrapolate LBW/preterm lifetime costs based on 65.5% of pcgdp /////////
//////////////////////////// from IOM 2007 for USA /////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\lbw_preterm_pct_pcgdp", clear 
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

save "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_preterm_costs", replace 

////////////////////////////////////////////////////////////////////////////////
/// compute untruncated expected lifetime medical costs in general population //
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_untruncated" 
save          "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_untruncated" , emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\ECONOMIC DATA\DIRECT COSTS\single_age_general_population_annual_medical_costs_w_life_tables", clear 

keep if year==`year'
sort country year age

forvalues x = 0/0 {
	gen L_`x'=L
}

forvalues x = 0/0 {
	replace L_`x'=. if age<`x'
}

forvalues x = 0/0 {
	gen med_cost_`x'=gen_pop_medical_exp
}

forvalues x = 0/0 {
	replace med_cost_`x'=. if age<`x'
}

forvalues x = 0/0 {
	replace L_`x' = L_`x'*med_cost_`x'
}

forvalues x = 0/0 {
	drop med_cost_`x'
}

forvalues x = 0/0 {
	replace L_`x'= L_`x'/((1 + $r)^(age-`x'))
}

forvalues x = 0/0 {
	by country year: egen T_`x' = total(L_`x')
}

forvalues x = 0/0 {
	gen LE_`x' = .
}

forvalues x = 0/0 {
	replace LE_`x' = T_`x'/survivors_l if age==`x'
}

gen LE=., before(survivors_l)

forvalues x = 0/0 {
	replace LE=LE_`x' if age==`x'
}

drop survivors_l L L_* T_* LE_* gen_pop_medical_exp
ren LE cost

compress 

keep if age==0

compress 

append using "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_untruncated" 
sort country year age 
save         "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_untruncated"   , replace 

end

forvalues y = 2030/2064 {
	le `y'
}

use "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_untruncated"  , clear 
assert age==0 
drop age 
gen healthstate="non-ABO"
gen duration="lifetime"
gen incremental="no"
gen discounted=.03
order country year healthstate cost duration incremental discounted

save "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_untruncated" , replace 

////////////////////////////////////////////////////////////////////////////////
//// compute ratio of lbw to general population costs in untruncated data. /////
// compute lbw lifetime truncated costs as the product of this ratio and the /// 
///// corresponding truncated general population lifetime medical costs. ///////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_preterm_costs", clear 
assert healthstate=="LBW/preterm"
drop who_region income_group_1

ren cost lbw_cost
drop if year<2030
merge 1:1 country year using "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_untruncated", keepusing(country year cost)

assert _m==3 
drop _m 
sort country year 

gen ratio = lbw_cost/cost
drop lbw_cost cost 
merge 1:1 country year using "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated", keepusing(country year cost)
assert _m ==3 
drop _m 
sort country year 
replace cost = cost*ratio
drop ratio 
order country year cost

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_preterm_costs_truncated", replace 

////////////////////////////////////////////////////////////////////////////////
//// extrapolate lifetime cerebral palsey (neurosyphilis) costs as 1.8 times ///
///// general population lifetime medical costs citing the results in the //////
//////////////// abstract of Park et al for South Korea ////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated", clear 
gen cost_ns = 1.8*cost 
drop cost 
ren cost_ns cost 
replace healthstate="neurosyphilis"

order country year healthstate cost duration incremental discounted

save "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_neurosyphilis_costs_truncated" , replace 

////////////////////////////////////////////////////////////////////////////////
///////////////// combine all ABO and non-ABO post-acute costs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_preterm_costs_truncated", clear 
append using "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_neurosyphilis_costs_truncated" 
append using "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated" 
append using "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated" 

sort country year healthstate 
assert discounted == .03
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

save "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_series_truncated", replace

log close 

exit 

// end