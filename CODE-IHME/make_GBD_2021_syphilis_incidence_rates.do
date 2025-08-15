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
log using "$output\DECISION TREE\BASE FILE\make_GBD_2021_syphilis_incidence_rates", text replace

/*
inputs:
Data Explorer - Data - Syphilis - Incidence - Number, Rate (per 100,000) in China, North Korea, Taiwan, Camb...  2024-06-24 16-29-33.xlsx
Data Explorer - Data - Syphilis - Incidence - Rate (per 100,000), Number in China, North Korea, Taiwan, Camb...  2024-06-24 16-48-48.xlsx
Data Explorer - Data - Syphilis - Incidence - Rate (per 100,000), Number in China, North Korea, Taiwan, Camb...  2024-06-24 16-57-48.xlsx
Data Explorer - Data - Syphilis - Incidence - Rate (per 100,000), Number in China, North Korea, Taiwan, Camb...  2024-06-24 17-10-54.xlsx
outputs:
GBD_2021_syphilis_incidence_rates_reference_scenario.dta 
GBD_2021_syphilis_incidence_rates_safer_environment_scenario.dta 
GBD_2021_syphilis_incidence_rates_improved_behavioral_scenario.dta 
GBD_2021_syphilis_incidence_rates_combined_scenario.dta 
*/

////////////////////////////////////////////////////////////////////////////////
/////// read in the raw IHME data: reference forecasting scenario //////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "Data Explorer - Data - Syphilis - Incidence - Number, Rate (per 100,000) in China, North Korea, Taiwan, Camb...  2024-06-24 16-29-33.xlsx", clear first case(lower) 
ren location country 
assert sex=="Female" 
assert measure == "Incidence"
assert condition == "Syphilis"
drop sex measure condition lower upper datasuite 
replace unit = "rate" if unit=="Rate (per 100,000)"
replace unit = lower(unit)
destring value, replace 
ren value value_
reshape wide value_, i(country age forecastscenario year) j(unit) string
order country age year value_number value_rate forecastscenario
sort  country age year 
compress 

assert inlist(forecastscenario, "Past estimate","Reference")
save "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_reference_scenario", replace

////////////////////////////////////////////////////////////////////////////////
/////// read in the raw IHME data: Safer environment forecasting scenario //////
////////////////////////////////////////////////////////////////////////////////

import excel using "Data Explorer - Data - Syphilis - Incidence - Rate (per 100,000), Number in China, North Korea, Taiwan, Camb...  2024-06-24 16-48-48.xlsx", clear first case(lower) 
ren location country 
assert sex=="Female" 
assert measure == "Incidence"
assert condition == "Syphilis"
drop sex measure condition lower upper datasuite 
replace unit = "rate" if unit=="Rate (per 100,000)"
replace unit = lower(unit)
destring value, replace 
ren value value_
reshape wide value_, i(country age forecastscenario year) j(unit) string
order country age year value_number value_rate forecastscenario
sort  country age year 
compress 

assert forecastscenario=="Safer environment"
save "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_safer_environment_scenario", replace

////////////////////////////////////////////////////////////////////////////////
///// read in the raw IHME data: Improved behavioral forecasting scenario //////
////////////////////////////////////////////////////////////////////////////////

import excel using "Data Explorer - Data - Syphilis - Incidence - Rate (per 100,000), Number in China, North Korea, Taiwan, Camb...  2024-06-24 16-57-48.xlsx", clear first case(lower) 
ren location country 
assert sex=="Female" 
assert measure == "Incidence"
assert condition == "Syphilis"
drop sex measure condition lower upper datasuite 
replace unit = "rate" if unit=="Rate (per 100,000)"
replace unit = lower(unit)
destring value, replace 
ren value value_
reshape wide value_, i(country age forecastscenario year) j(unit) string
order country age year value_number value_rate forecastscenario
sort  country age year 
compress 

assert forecastscenario=="Improved behavioral and metabolic risk factors"
save "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_improved_behavioral_scenario", replace

////////////////////////////////////////////////////////////////////////////////
//////////// read in the raw IHME data: combined forecasting scenario //////////
////////////////////////////////////////////////////////////////////////////////

import excel using "Data Explorer - Data - Syphilis - Incidence - Rate (per 100,000), Number in China, North Korea, Taiwan, Camb...  2024-06-24 17-10-54.xlsx", clear first case(lower) 
ren location country 
assert sex=="Female" 
assert measure == "Incidence"
assert condition == "Syphilis"
drop sex measure condition lower upper datasuite 
replace unit = "rate" if unit=="Rate (per 100,000)"
replace unit = lower(unit)
destring value, replace 
ren value value_
reshape wide value_, i(country age forecastscenario year) j(unit) string
order country age year value_number value_rate forecastscenario
sort  country age year 
compress 

assert forecastscenario=="Combined"
save "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_combined_scenario", replace

log close 

exit 

// end