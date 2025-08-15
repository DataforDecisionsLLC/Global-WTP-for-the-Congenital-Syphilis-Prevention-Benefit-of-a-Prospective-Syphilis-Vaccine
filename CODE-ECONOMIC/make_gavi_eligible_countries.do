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
Gavi eligible countries 2024.xlsx
outputs:
gavi_eligible_countries.dta
*/

capture log close 
log using "$output\ECONOMIC DATA\make_gavi_eligible_countries", text replace

////////////////////////////////////////////////////////////////////////////////
//////////////////////// get the gavi eligible countries ///////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\GAVI\Gavi eligible countries 2024.xlsx", clear sheet("Initial self-financing") first case(lower)
ren initialselffinancing country 
gen gavi_eligibility = "Initial self-financing"
sort country 
compress 
save "$output\ECONOMIC DATA\gavi_eligible_countries", replace 

import excel using "$raw\GAVI\Gavi eligible countries 2024.xlsx", clear sheet("Preparatory transition phase") first case(lower)
ren preparatorytransitionphase country 
gen gavi_eligibility = "Preparatory transition phase"
sort country 
compress 

append using "$output\ECONOMIC DATA\gavi_eligible_countries"
save "$output\ECONOMIC DATA\gavi_eligible_countries", replace 

import excel using "$raw\GAVI\Gavi eligible countries 2024.xlsx", clear sheet("Accelerated transition phase") first case(lower)
ren acceleratedtransitionphase country 
gen gavi_eligibility = "Accelerated transition phase"
sort country 
compress 

append using "$output\ECONOMIC DATA\gavi_eligible_countries"
sort gavi_eligibility country 

replace country = trim(country)

replace country = "Cote d'Ivoire" if country=="Côte d'Ivoire"
replace country = "North Korea" if country=="Democratic People's Republic of Korea"
replace country = "The Gambia" if country=="Gambia"
replace country = "Laos" if regexm(country,"Lao")
replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "Tanzania" if country=="UR Tanzania"

save "$output\ECONOMIC DATA\gavi_eligible_countries", replace 

log close 

exit 

// end


