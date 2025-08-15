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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_2019_pcgdp", text replace

/*
inputs:
wdi_data_all_countries.dta created in: wdi_ihme_country_match.do
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
P_Data_Extract_From_World_Development_Indicators-2019 PCGDP Syria.xlsx
outputs:
2019_pcgdp.dta 
*/

////////////////////////////////////////////////////////////////////////////////
////////// get the 2019 per capita GDP for all IHME countries //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\wdi_data_all_countries", clear
keep if seriesname=="GDP per capita (current US$)"
drop seriesname
ren yr2019 yr2019_pcgdp_current_2019USD
sort country 
isid country
compress
count 

merge 1:1 country using  "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert inlist(country,"Eritrea","North Korea","Syria") if _m==2
drop if _m==1 
drop _m 

ren who_region WHO_region 

split income_group_1, parse("") gen(income_)

gen income=""
replace income="LIC" if income_1=="Low"
replace income="MIC" if income_1=="Middle"
replace income="HIC" if income_1=="High"
tab income income_1, m 

drop income_1 income_2 income_group_1

compress
save "$output\ECONOMIC DATA\2019_pcgdp", replace

// get the PC GDP for Syria from WDI

import excel using "$raw/WDI/P_Data_Extract_From_World_Development_Indicators-2019 PCGDP Syria.xlsx", ///
clear first sheet("Data") case(lower) cellrange(A1:E2)
assert seriesname=="GDP per capita (current US$)"
keep countryname yr*
ren countryname country
replace country="Syria" if country =="Syrian Arab Republic"
merge 1:1 country using "$output\ECONOMIC DATA\2019_pcgdp"
assert _m!=1 
replace yr2019_pcgdp_current_2019USD = yr2019 if _m==3 
drop _m yr2019
sort country
list if yr2019_pcgdp_current_2019USD==. 

compress
save "$output\ECONOMIC DATA\2019_pcgdp", replace

assert country =="North Korea" if yr2019_pcgdp_current_2019USD==. 

sort country

compress
save "$output\ECONOMIC DATA\2019_pcgdp", replace

log close 

exit 

// end