set more off
clear all
set type double
set excelxlsxlargefile on
version 18

/*
Instructions: Users need to replace "...." with the appropriate file path.
*/ 

gl root   "...."
gl raw    "$root\RAW DATA"
gl output "$root\OUTPUT"

/*
inputs:
Data Explorer - Data - Early symptomatic congenital syphilis, infectious syndrome - Prevalence, Incidence,...  2024-04-03 12-16-01.xlsx
regions.dta created in: make_regions.do
outputs:
ihme_country_list_syphilis_with_geo.dta 
*/

capture log close
log using "$output\IHME\SYPHILIS\make_ihme_country_list_syphilis_with_geo", text replace

////////////////////////////////////////////////////////////////////////////////
/////////////// import the GBD 2021 congenital syphilis data ///////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\IHME\GBD 2021\CS\Data Explorer - Data - Early symptomatic congenital syphilis, infectious syndrome - Prevalence, Incidence,...  2024-04-03 12-16-01.xlsx", clear first case(lower) 

keep location 
duplicates drop 
ren location country 
count 

sort country 
compress 
save "$output\IHME\SYPHILIS\ihme_country_list", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// map on the regional classifications ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\GEO DATA\regions.dta", clear

replace country = "Czech Republic" if country == "Czechia"
replace country = "Democratic Republic of the Congo" if country == "Democratic Republic of Congo"
replace country = "Federated States of Micronesia" if country == "Micronesia (country)"
replace country = "Russian Federation" if country == "Russia"
replace country = "Swaziland" if country == "Eswatini"
replace country = "The Bahamas" if country == "Bahamas"
replace country = "The Gambia" if country == "Gambia"
replace country = "Macedonia" if country == "North Macedonia"

merge 1:1 country using "$output\IHME\SYPHILIS\ihme_country_list"
drop if _m==1 
sort country 
list country if _m==2 , sep(0)

replace who_region = "WPRO" if inlist(country,"Taiwan") & _m== 2
replace who_region = "EMRO" if country=="Palestine" & _m== 2

assert who_region!="" 
assert who_region!="Not Classified" 

replace income_group_1 = "High Income" if inlist(country,"Taiwan") & _m== 2
replace income_group_1 = "Middle Income" if country == "Palestine" & _m== 2 

assert income_group_1!=""
assert income_group_1!="Not Classified"

drop _m un_region un_subregion unicef_region income_group_2 world_bank_region mdg_region sdg_region

sort country 

compress 
save "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", replace

////////////////////////////////////////////////////////////////////////////////
/////////////////////// compare to preliminary file ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", clear 
merge 1:1 _all using "$output\IHME\SYPHILIS\OBSOLETE-2024-04-23\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert _m==3 
drop _m 

log close 

exit 

// end