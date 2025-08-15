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

cd "$raw\IHME\GBD 2021\SYPHILIS\"

capture log close 
log using "$output\DECISION TREE\BASE FILE\make_GBD_2021_syphilis_incidence_rates_upper_lower", text replace

/*
inputs:
Data Explorer - Data - Syphilis - Incidence - Number, Rate (per 100,000) in China, North Korea, Taiwan, Camb...  2024-06-24 16-29-33.xlsx
outputs:
GBD_2021_syphilis_incidence_rates_reference_scenario_lower.dta 
GBD_2021_syphilis_incidence_rates_reference_scenario_upper.dta 
*/

////////////////////////////////////////////////////////////////////////////////
/////// read in the raw IHME data: reference forecasting scenario //////////////
////////////////////////////////////////////////////////////////////////////////

//////////////////////////// lower bound scenario //////////////////////////////

import excel using "Data Explorer - Data - Syphilis - Incidence - Number, Rate (per 100,000) in China, North Korea, Taiwan, Camb...  2024-06-24 16-29-33.xlsx", clear first case(lower) 
ren location country 
assert sex=="Female" 
assert measure == "Incidence"
assert condition == "Syphilis"
drop sex measure condition value upper datasuite 
replace unit = "rate" if unit=="Rate (per 100,000)"
replace unit = lower(unit)
destring lower, replace 
ren lower value_
reshape wide value_, i(country age forecastscenario year) j(unit) string
order country age year value_number value_rate forecastscenario
sort  country age year 
compress 

assert inlist(forecastscenario, "Past estimate","Reference")
save "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_reference_scenario_lower", replace

//////////////////////////// upper bound scenario //////////////////////////////

import excel using "Data Explorer - Data - Syphilis - Incidence - Number, Rate (per 100,000) in China, North Korea, Taiwan, Camb...  2024-06-24 16-29-33.xlsx", clear first case(lower) 
ren location country 
assert sex=="Female" 
assert measure == "Incidence"
assert condition == "Syphilis"
drop sex measure condition value lower datasuite 
replace unit = "rate" if unit=="Rate (per 100,000)"
replace unit = lower(unit)
destring upper, replace 
ren upper value_
reshape wide value_, i(country age forecastscenario year) j(unit) string
order country age year value_number value_rate forecastscenario
sort  country age year 
compress 

assert inlist(forecastscenario, "Past estimate","Reference")
save "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_reference_scenario_upper", replace


log close 

exit 

// end