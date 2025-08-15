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
log using "$output\GEO DATA\make_who_regions_income_groups", text replace

/*
inputs:
who-regions.xlsx
world_bank_classification.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis_with_geo.do
outputs:
who_regions_income_groups.dta 
*/

////////////////////////////////////////////////////////////////////////////////
///////////////////////////// get the who regions  /////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\GEO DATA\who-regions.xlsx", clear first case(lower)
ren whoregion who_region

ren entity country 
duplicates drop
isid country 

replace country="Czech Republic" if country=="Czechia"
replace country="Timor-Leste" if country =="East Timor"

compress 
save "$output\GEO DATA\who_regions_income_groups", replace

////////////////////////////////////////////////////////////////////////////////
////////////// map on the income group classification //////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\GEO DATA\world_bank_classification.xlsx", ///
clear first sheet("List of economies") case(lower) cellrange(A1:D219)
drop code 
ren region wb_region 
ren economy country 
ren incomegroup  wb_income_group

sort country 
isid country
count 

compress 

replace country="Brunei" if country=="Brunei Darussalam"
replace country="Czech Republic" if country=="Czechia"
replace country="Russia" if country=="Russian Federation"
replace country="China, Hong Kong SAR" if country=="Hong Kong SAR, China"
replace country="China, Macao SAR" if country=="Macao SAR, China"
replace country="Congo" if country=="Congo, Rep."
replace country="Egypt" if country=="Egypt, Arab Rep."
replace country="Federated States of Micronesia" if country=="Micronesia, Fed. Sts."
replace country="French Saint Martin" if country=="St. Martin (French part)"
replace country="Iran" if country=="Iran, Islamic Rep."
replace country="Kyrgyzstan" if country=="Kyrgyz Republic"
replace country="Laos" if country=="Lao PDR"
replace country="North Korea" if country=="Korea, Dem. People's Rep."
replace country="South Korea" if country=="Korea, Rep."
replace country="Palestine" if country=="West Bank and Gaza"
replace country="Saint Kitts and Nevis" if country=="St. Kitts and Nevis"
replace country="Saint Lucia" if country=="St. Lucia"
replace country="Saint Vincent and the Grenadines" if country=="St. Vincent and the Grenadines"
replace country="Syria" if country=="Syrian Arab Republic"
replace country="The Bahamas" if country=="Bahamas, The"
replace country="The Gambia" if country=="Gambia, The"
replace country="Turkey" if country=="Türkiye"
replace country="United States Virgin Islands" if country=="Virgin Islands (U.S.)"
replace country="Venezuela" if country=="Venezuela, RB"
replace country="Yemen" if country=="Yemen, Rep."
replace country="Democratic Republic of the Congo" if country=="Congo, Dem. Rep."
replace country="Dutch Saint Martin" if country=="Sint Maarten (Dutch part)"
replace country="Cape Verde" if country=="Cabo Verde"
replace country="Slovakia" if country=="Slovak Republic"
replace country="Cote d'Ivoire" if regexm(country,"Ivoire")
replace country="Curacao" if country=="Curaçao"
replace country="Faeroe Islands" if country=="Faroe Islands"
replace country="Sao Tome and Principe" if country=="São Tomé and Príncipe"
replace country="Taiwan" if country=="Taiwan, China"

merge 1:1 country using "$output\GEO DATA\who_regions_income_groups"
drop _m code year

replace country="Russian Federation" if country=="Russia"
replace country="Swaziland" if country=="Eswatini"
replace country="Macedonia" if country=="North Macedonia"

replace wb_income_group = "High Income" if wb_income_group=="High income"
gen income_group_1 = wb_income_group
replace income_group_1 = "Middle Income" if inlist(wb_income_group,"Lower middle income", "Upper middle income")
tab income_group_1 wb_income_group, m 
drop wb_income_group 

gen region="" 
replace region = "AFRO"  if who_region == "Africa"
replace region = "AMRO"  if who_region == "Americas"
replace region = "EMRO"  if who_region == "Eastern Mediterranean"
replace region = "EURO"  if who_region == "Europe"
replace region = "SEARO" if who_region == "South-East Asia"
replace region = "WPRO"  if who_region == "Western Pacific"

tab region who_region, m 
drop who_region 
ren region who_region 

sort country 
compress 
save "$output\GEO DATA\who_regions_income_groups", replace 

// keep only the study countries 

use "$output\GEO DATA\who_regions_income_groups", clear 

merge 1:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country)
assert _m!=2
keep if _m==3 
drop _m 
sort country 
compress 
isid country 
count 

order country who_region wb_region income_group_1

replace who_region = "WPRO" if who_region==""  & wb_region == "East Asia & Pacific"
replace who_region = "EMRO" if who_region =="" & wb_region=="Middle East & North Africa"

assert who_region !=""

replace income_group_1 = "Middle Income" if income_group_1 =="" & country == "Venezuela"

assert income_group_1 !=""

drop wb_region

sort country 
compress 
save "$output\GEO DATA\who_regions_income_groups", replace 

log close 
exit 

// end 
