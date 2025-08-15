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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_who_choice_tertiary_2019USDs", text replace

/*
inputs:
who_choice_2010.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
forex_2010_and_2019.dta created in: make_forex_2010_and_2019.do
P_Data_Extract_From_World_Development_Indicators-GDP deflators 2010-2022.xlsx
WEOOct2019all_import.xlsx
outputs:
wdi_deflators.dta
who_choice_tertiary_2019USDs.dta 
*/

////////////////////////////////////////////////////////////////////////////////
////////////////// WHO CHOICE hospital cost data in 2010 nominal USD ///////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\WHO CHOICE\who_choice_2010.xlsx", ///
clear sheet("bed_day_USD") cellrange(A4:D198) first case(lower)
keep regioncountry tertiaryhospital
ren regioncountry country
sort country 
replace tertiaryhospital = "" if tertiaryhospital=="NA"
destring tertiaryhospital, replace

isid country
count

///////////////////////// map on the region-income group ///////////////////////

replace country = "Tanzania" if country=="United Republic of Tanzania"
replace country = "Eswatini" if country=="Swaziland"
replace country = "Laos" if country=="Lao People's Democratic Republic"
replace country = "Bolivia" if country=="Bolivia Plurinational States of"
replace country = "Cape Verde" if country=="Cabo Verde Republic of"
replace country = "Cote d'Ivoire" if country=="Côte d'Ivoire"
replace country = "Curacao" if country=="Curaçao"
replace country = "Macao" if country=="Macau, China"
replace country = "Moldova" if country=="Moldova, Republic of"
replace country = "Palestine" if country=="Occupied Palestinian Territory"
replace country = "South Korea" if country=="Korea, Republic of"
replace country = "North Korea" if country=="Democratic People's Republic of Korea"
replace country = "Turkey" if country=="Türkiye"
replace country = "Vietnam" if country=="Viet Nam"
replace country = "Hong Kong" if country=="Hong Kong, China"
replace country = "Taiwan" if country=="Taiwan, China"
replace country = "Iran" if country=="Iran, Islamic Republic of"
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "South Korea" if country=="Republic of Korea"
replace country = "Iran" if country=="Iran (Islamic Republic of)"
replace country = "Moldova" if country=="Republic of Moldova"
replace country = "North Macedonia" if country=="The former Yugoslav Republic of Macedonia"
replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "United States" if country=="United States of America"
replace country = "Venezuela" if country=="Venezuela (Bolivarian Republic of)"
replace country = "Vietnam" if country=="Viet Nam"
replace country = "The Gambia" if country=="Gambia"
replace country = "The Bahamas" if country=="Bahamas"
replace country = "Swaziland" if country == "Eswatini"
replace country = "Macedonia" if country == "North Macedonia"
replace country = "Federated States of Micronesia" if regexm(country,"Micronesia")

merge 1:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
list _m country if _m<3, sep(0)

keep if _m==3 
drop _m 
sort country 

compress
save "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_tertiary_2010_USDs", replace

////////////////////////////////////////////////////////////////////////////////
////////////// convert 2010 nominal USDs to 2010 nominal LCUs //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\FOREX\forex_2010_and_2019", clear

replace country = "Swaziland" if country == "Eswatini"
replace country = "Macedonia" if country == "North Macedonia"
replace country = "The Gambia" if country=="Gambia"
replace country = "The Bahamas" if country=="Bahamas"
replace country = "Micronesia (Federated States of)" if country=="Micronesia (country)"
replace country = "Russian Federation" if country== "Russia" 
replace country = "Federated States of Micronesia" if regexm(country,"Micronesia")

merge 1:1 country using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_tertiary_2010_USDs"
sort country 
list country if _m==2, sep(0)

keep if _m==3
drop _m 

gen cost_2010LCU = tertiaryhospital*forex_2010

drop  tertiaryhospital

compress
save "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_tertiary_2010_LCUs", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////////// get gdp deflators from WDI ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/WDI/P_Data_Extract_From_World_Development_Indicators-GDP deflators 2010-2022.xlsx", ///
clear first sheet("Data") case(lower) cellrange(A1:Q218)

ren countryname country
assert seriesname=="GDP deflator (base year varies by country)"
keep country yr2010 yr2019
ren yr2010 wdi_deflator_2010
ren yr2019 wdi_deflator_2019

foreach y in 2010 2019 {
	replace wdi_deflator_`y'="" if wdi_deflator_`y'==".."
}

foreach y in 2010 2019 {
	destring wdi_deflator_`y', replace
}

drop if inlist(country,"Channel Islands","Virgin Islands (U.S.)")
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Congo" if country=="Congo, Rep."
replace country = "Democratic Republic of Congo" if country=="Congo, Dem. Rep."
replace country = "Faeroe Islands" if country=="Faroe Islands"
replace country = "Gambia" if country=="Gambia, The"
replace country = "Hong Kong" if country=="Hong Kong SAR, China"
replace country = "North Korea" if country=="Korea, Dem. People's Rep."
replace country = "South Korea" if country=="Korea, Rep."
replace country = "Kyrgyzstan" if country=="Kyrgyz Republic"
replace country = "Laos" if country=="Lao PDR"
replace country = "Macao" if country=="Macao SAR, China"
replace country = "Micronesia (country)" if country=="Micronesia, Fed. Sts."
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Saint Kitts and Nevis" if country=="St. Kitts and Nevis"
replace country = "Saint Lucia" if country=="St. Lucia"
replace country = "Saint Martin (French part)" if country=="St. Martin (French part)"
replace country = "Saint Vincent and the Grenadines" if country=="St. Vincent and the Grenadines"
replace country = "Turkey" if country=="Turkiye"
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Yemen" if country=="Yemen, Rep."
replace country = "Egypt" if country=="Egypt, Arab Rep."
replace country = "Palestine" if country=="West Bank and Gaza"
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Russia" if country=="Russian Federation"
replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "Iran" if regexm(country,"Iran")
replace country = "Federated States of Micronesia" if country=="Micronesia (country)"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "Russian Federation" if country=="Russia"
replace country = "Swaziland" if country=="Eswatini"
replace country = "The Gambia" if country=="Gambia"
replace country = "The Bahamas" if country=="Bahamas, The"

count 

compress 
save "$output\ECONOMIC DATA\wdi_deflators", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////////// get gdp deflators from IMF ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/IMF/WEOOct2019all_import.xlsx", clear first sheet("2002-2024") case(lower) cellrange(A1:Z8731)

keep if subjectdescriptor=="Gross domestic product, deflator"
assert units == "Index"
assert scale==""
drop units scale subjectnotes countryseriesspecificnotes

replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Congo" if country=="Democratic Republic of the Congo"
replace country = "Cote d'Ivoire" if country=="Côte d'Ivoire"
replace country = "Gambia" if country=="The Gambia"
replace country = "Kyrgyzstan" if country=="Kyrgyz Republic"
replace country = "Iran" if regexm(country,"Iran")
replace country = "Micronesia (country)" if country=="Micronesia"
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "South Korea" if country=="Korea"
replace country = "Saint Kitts and Nevis" if country=="St. Kitts and Nevis"
replace country = "Saint Lucia" if country=="St. Lucia"
replace country = "Saint Vincent and the Grenadines" if country=="St. Vincent and the Grenadines"
replace country = "Federated States of Micronesia" if country=="Micronesia (country)"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "Russian Federation" if country=="Russia"
replace country = "The Gambia" if country=="Gambia"
replace country = "Swaziland" if country=="Eswatini"
replace country = "Sao Tome and Principe" if country=="São Tomé and Príncipe"

merge 1:1 country using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_tertiary_2010_LCUs"
sort country
list country if _m==2, sep(0)

keep if _m==3 
drop _m 
sort country 

forvalues x=2002/2021 {
	replace year_`x' = "" if year_`x'=="n/a"
}

forvalues x=2002/2021 {
	destring year_`x', replace
}

keep country year_2010 year_2019 who_region income_group_1 cost_2010LCU forex_2019

merge 1:1 country using "$output\ECONOMIC DATA\wdi_deflators"

assert _m!= 1 
drop if _m==2 
drop _m 
compress 
sort country 

gen check_2010 = year_2010/wdi_deflator_2010
gen check_2019 = year_2019/wdi_deflator_2019

sum check_2010 , d 
sum check_2019 , d 

// use wdi as the default and imf for countries with missing wdi data

foreach y in 2010 2019 {
	ren year_`y' imf_deflator_`y'
}

order country wdi_deflator_2010 wdi_deflator_2019 imf_deflator_2010 imf_deflator_2019 

// use WDI deflators for countries who are missing IMF deflators for both years 

egen num_wdi = rownonmiss(wdi_deflator_2010 wdi_deflator_2019)
list num_wdi country wdi_deflator_2010 wdi_deflator_2019 imf_deflator_2010 imf_deflator_2019 if num_wdi<2 , sep(0)

////////////////////////////////////////////////////////////////////////////////
//////////////////////// convert 2010 LCUs to 2019 LCUs ////////////////////////
////////////////////////////////////////////////////////////////////////////////

gen cost_2019LCU = .
replace cost_2019LCU = cost_2010LCU*(wdi_deflator_2019/wdi_deflator_2010) if num_wdi==2
replace cost_2019LCU = cost_2010LCU*(imf_deflator_2019/imf_deflator_2010) if num_wdi<2
list country wdi_deflator_2010 wdi_deflator_2019 imf_deflator_2010 imf_deflator_2019 cost_2010LCU cost_2019LCU if cost_2019LCU==. , sep(0)

////////////////////////////////////////////////////////////////////////////////
//////////////////////// convert 2019 LCUs to 2019 USDs ////////////////////////
////////////////////////////////////////////////////////////////////////////////

gen cost_2019USD = cost_2019LCU/forex_2019

gen has_data=1 
replace has_data=0 if cost_2019USD==.

list has_data country wdi_deflator_2010 wdi_deflator_2019 imf_deflator_2010 imf_deflator_2019 forex_2019 cost_2010LCU cost_2019LCU cost_2019USD if cost_2019USD==. , sep(0)

keep  has_data country who_region income_group_1 cost_2019USD
order has_data country who_region income_group_1 cost_2019USD
ren who_region WHO_region
ren income_group_1 WB_income_group_1
ren cost_2019USD tert_hosp_2019USD
ren has_data has_tertiary 
sort country 
compress 

save "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_tertiary_2019USDs", replace

log close 

exit 

// end