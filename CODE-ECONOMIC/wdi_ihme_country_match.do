set more off
clear all
set type double
version 18.0

/*
Instructions: Users need to replace "...." with the appropriate file path.
*/ 

gl root   "...."
gl raw    "$root\RAW DATA"
gl output "$root\OUTPUT"

capture log close
log using "$output\ECONOMIC DATA\wdi_ihme_country_match", text replace

/*
inputs:
P_Data_Extract_From_World_Development_Indicators.xlsx
P_Data_Extract_From_World_Development_Indicators_per_capita_GDP.xlsx
WEOOct2019all_import.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
outputs:
wdi_data_all_countries.dta
wdi_ihme_country_match.dta 
*/

////////////////////////////////////////////////////////////////////////////////
/// get final consumption and GNI per capita in 2019 USD from WDI from WDI /////
////////////////////////////////////////////////////////////////////////////////

import excel using ///
"$raw\WDI\P_Data_Extract_From_World_Development_Indicators.xlsx", ///
clear sheet("Data") cellrange(A1:E2777) first case(lower)

compress
drop if yr2019==".."
destring yr2019, replace

drop seriescode countrycode
ren countryname country

qui tab country, m 
di "There are `r(r)' countries"

replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "Faeroe Islands" if country=="Faroe Islands"
replace country = "Congo" if country=="Congo, Rep."
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Democratic Republic of the Congo" if country=="Congo, Dem. Rep."
replace country = "Egypt" if regexm(country,"Egypt")
replace country = "Hong Kong" if regexm(country,"Hong Kong")
replace country = "Iran" if regexm(country,"Iran, Islamic Rep.")
replace country = "South Korea" if country=="Korea, Rep."
replace country = "Kyrgyzstan" if country=="Kyrgyz Republic"
replace country = "Laos" if country=="Lao PDR"
replace country = "Macao" if regexm(country,"Macao")
replace country = "Federated States of Micronesia" if regexm(country,"Micronesia")
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Saint Kitts and Nevis" if country=="St. Kitts and Nevis"
replace country = "Saint Lucia" if country=="St. Lucia"
replace country = "Saint Vincent and the Grenadines" if country=="St. Vincent and the Grenadines"
replace country = "Turkey" if country=="Turkiye"
replace country = "Yemen" if country=="Yemen, Rep."
replace country = "Palestine" if country=="West Bank and Gaza"

replace country = "Czech Republic" if country=="Czechia"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "Swaziland" if country=="Eswatini"
replace country = "The Bahamas" if country=="Bahamas, The"
replace country = "The Gambia" if country=="Gambia, The"

save "$output\ECONOMIC DATA\wdi_data_all_countries", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// get gdp per capita in 2019 USD from WDI /////////////////////
//////////////////////////////////////////////////////////////////////////////// 

import excel using ///
"$raw\WDI\P_Data_Extract_From_World_Development_Indicators_per_capita_GDP.xlsx", ///
clear sheet("Data") cellrange(A1:E869) first case(lower)

compress
drop if yr2019==".."
destring yr2019, replace

drop seriescode countrycode
ren countryname country

qui tab country, m 
di "There are `r(r)' countries"

keep if seriesname =="GDP per capita (current US$)"

replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "Faeroe Islands" if country=="Faroe Islands"
replace country = "Congo" if country=="Congo, Rep."
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Democratic Republic of the Congo" if country=="Congo, Dem. Rep."
replace country = "Egypt" if regexm(country,"Egypt")
replace country = "Hong Kong" if regexm(country,"Hong Kong")
replace country = "Iran" if regexm(country,"Iran, Islamic Rep.")
replace country = "South Korea" if country=="Korea, Rep."
replace country = "Kyrgyzstan" if country=="Kyrgyz Republic"
replace country = "Laos" if country=="Lao PDR"
replace country = "Macao" if regexm(country,"Macao")
replace country = "Federated States of Micronesia" if regexm(country,"Micronesia")
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Saint Kitts and Nevis" if country=="St. Kitts and Nevis"
replace country = "Saint Lucia" if country=="St. Lucia"
replace country = "Saint Vincent and the Grenadines" if country=="St. Vincent and the Grenadines"
replace country = "Turkey" if country=="Turkiye"
replace country = "Yemen" if country=="Yemen, Rep."
replace country = "Palestine" if country=="West Bank and Gaza"

replace country = "Czech Republic" if country=="Czechia"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "Swaziland" if country=="Eswatini"
replace country = "The Bahamas" if country=="Bahamas, The"
replace country = "The Gambia" if country=="Gambia, The"

append using "$output\ECONOMIC DATA\wdi_data_all_countries"
sort country seriesname

save "$output\ECONOMIC DATA\wdi_data_all_countries", replace

////////////////////////////////////////////////////////////////////////////////
/// get gdp per capita for Eritrea, South Sudan, Taiwan, and Venezuela from IMF data ////
////////////////////////////////////////////////////////////////////////////////

import excel using ///
"$raw\IMF\WEOOct2019all_import.xlsx", ///
clear sheet("import") cellrange(A1:P8731) first case(lower)
keep if inlist(country,"South Sudan","Taiwan Province of China","Venezuela","Eritrea")
keep if subjectdescriptor=="Gross domestic product per capita, current prices"
keep if units=="U.S. dollars"
assert scale=="Units"
keep country year_2019
ren  year_2019  yr2019
gen seriesname = "GDP per capita (current US$)"
order country seriesname yr2019
destring yr2019, replace

replace country = "Taiwan" if country=="Taiwan Province of China"

sort country 
compress
list 

append using "$output\ECONOMIC DATA\wdi_data_all_countries"
save "$output\ECONOMIC DATA\wdi_data_all_countries", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// filter to the IHME syphilis countries ///////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\wdi_data_all_countries", clear 

drop if seriesname=="GDP (current US$)"
drop if seriesname=="GDP (current LCU)"
drop if seriesname=="GDP (constant 2015 US$)"
drop if seriesname=="GDP (constant LCU)"

drop if regexm(series,"constant")
drop if regexm(series,"LCU")
drop if seriesname=="Final consumption expenditure (% of GDP)"
drop if seriesname=="Final consumption expenditure (current LCU)"

gen series="", before(seriesname)
replace series="cons_current_USD"      if seriesname=="Final consumption expenditure (current US$)"
replace series="pcgni_current_USD"     if seriesname=="GNI per capita, Atlas method (current US$)"
replace series="pcgdp_current_2019USD" if seriesname=="GDP per capita (current US$)"

assert series!=""
tab series, m 
assert `r(r)' ==3 

drop seriesname
sort country series
ren yr2019 yr2019_
reshape wide yr2019_, i(country) j(series) string

sort country 
isid country
compress

merge m:1 country using  "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert country=="North Korea" if _m==2 
keep if _m ==3 
drop _m 

sort country
isid country

qui tab country, m 
di "There are `r(r)' countries"

compress

save "$output\ECONOMIC DATA\wdi_ihme_country_match", replace

log close 

exit

// end