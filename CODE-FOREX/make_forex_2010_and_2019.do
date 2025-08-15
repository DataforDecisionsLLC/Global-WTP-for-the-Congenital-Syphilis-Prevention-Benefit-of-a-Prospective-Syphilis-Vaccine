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
log using "$output\FOREX\make_forex_2010_and_2019", text replace

/*
inputs:
who_choice_2010.xlsx
P_Data_Extract_From_World_Development_Indicators-Forex.xlsx
RprtRateXchg_20010331_20220930.xlsx
Exchange rate, new LCU per USD extended backward, period average.xlsx
outputs:
WHO_choice_countries.dta
forex_2010_and_2019.dta 
*/

////////////////////////////////////////////////////////////////////////////////
///////////// get the countries with WHO CHOICE hospital cost data /////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\WHO CHOICE\who_choice_2010.xlsx", ///
clear sheet("bed_day_USD") cellrange(A4:D198) first case(lower)
keep regioncountry primaryhospital
ren regioncountry country
sort country 
replace primaryhospital = "" if primaryhospital=="NA"
destring primaryhospital, replace

isid country
count

replace country = "Tanzania" if country=="United Republic of Tanzania"
replace country = "Eswatini" if country=="Swaziland"
replace country = "Micronesia (country)" if country=="Micronesia (Federated States of)"
replace country = "Laos" if country=="Lao People's Democratic Republic"
replace country = "Bolivia" if country=="Bolivia Plurinational States of"
replace country = "Cape Verde" if country=="Cabo Verde Republic of"
replace country = "Czechia" if country=="Czech Republic"
replace country = "Cote d'Ivoire" if country=="Côte d'Ivoire"
replace country = "Curacao" if country=="Curaçao"
replace country = "Macao" if country=="Macau, China"
replace country = "Moldova" if country=="Moldova, Republic of"
replace country = "Palestine" if country=="Occupied Palestinian Territory"
replace country = "Russia" if country=="Russian Federation"
replace country = "South Korea" if country=="Korea, Republic of"
replace country = "North Korea" if country=="Democratic People's Republic of Korea"
replace country = "Turkey" if country=="Türkiye"
replace country = "Vietnam" if country=="Viet Nam"
replace country = "Hong Kong" if country=="Hong Kong, China"
replace country = "Taiwan" if country=="Taiwan, China"
replace country = "Iran" if country=="Iran, Islamic Republic of"
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Democratic Republic of Congo" if country=="Democratic Republic of the Congo"
replace country = "South Korea" if country=="Republic of Korea"
replace country = "Iran" if country=="Iran (Islamic Republic of)"
replace country = "Moldova" if country=="Republic of Moldova"
replace country = "Russia" if country=="Russian Federation"
replace country = "North Macedonia" if country=="The former Yugoslav Republic of Macedonia"
replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "United States" if country=="United States of America"
replace country = "Venezuela" if country=="Venezuela (Bolivarian Republic of)"
replace country = "Vietnam" if country=="Viet Nam"

compress
drop if primaryhospital==.
count 

save "$output\ECONOMIC DATA\DIRECT COSTS\WHO_choice_countries", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////////////// get forex from the WDI data ///////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/WDI/P_Data_Extract_From_World_Development_Indicators-Forex.xlsx", ///
clear first sheet("Data") case(lower) cellrange(A1:P218)

assert seriesname=="Official exchange rate (LCU per US$, period average)"
keep countryname yr*
ren countryname country

forvalues y = 2010/2021 {
	ren yr`y' forex_`y'
}

forvalues y = 2010/2021 {
	replace forex_`y'="" if forex_`y'==".."
}

forvalues y = 2010/2021 {
	destring forex_`y', replace
}

keep country forex_2010 forex_2019
egen numrecs = rownonmiss(forex_2010 forex_2019) 
compress
isid country 
count 

replace country = "Bahamas" if country=="Bahamas, The"
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

// keep the countries with hospital data 

merge 1:1 country using "$output\ECONOMIC DATA\DIRECT COSTS\WHO_choice_countries"
drop if _m==1 
drop _m primaryhospital

save "$output\FOREX\forex_2010_and_2019", replace

////////////////////////////////////////////////////////////////////////////////
/// get the county-years that do not have WDI data for 2010 and/or 2019 ////////
////////////////////////////////////////////////////////////////////////////////

use "$output\FOREX\forex_2010_and_2019", clear
keep if numrecs<2
reshape long forex_, i(country) j(year)
ren forex forex_wdi
compress 
save "$output\FOREX\missing_2010_2019_WDI_forex", replace

////////////////////////////////////////////////////////////////////////////////
// source: US Department of the Treasury and the Bureau of the Fiscal Service //
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\FOREX\RprtRateXchg_20010331_20220930.xlsx", ///
clear first sheet("RprtRateXchg_20010331_20220930") cellrange(A1:E16304) case(lower)

gen month=month(recorddate), before(recorddate)
gen year=year(recorddate), before(month)
keep if month==12 & (year >=2010 & year<=2019)
drop month recorddate countrycurrencydescription 
replace country = proper(country)
replace currency = upper(currency)
duplicates drop

replace country = "Antigua" if country=="Antigua & Barbuda"
replace country = "Bosnia and Herzegovina" if country=="Bosnia"
replace country = "Cote d'Ivoire" if country=="Cote D'Ivoire"
replace country = "Eswatini" if country=="Swaziland"
replace country = "Guinea-Bissau" if country=="Guinea Bissau"
replace country = "North Macedonia" if country=="Macedonia Fyrom"
replace country = "Somalia" if country=="Somali"
replace country = "South Sudan" if country=="South Sudanese"
replace country = "Timor-Leste" if country=="Timor"
replace country = "Trinidad and Tobago" if country=="Trinidad & Tobago"
replace country = "Czechia" if regexm(country,"Czech")
replace country = "Democratic Republic of Congo" if inlist(country,"Congo, Dem. Rep","Dem. Rep. Of Congo","Democratic Republic Of Congo")
replace country = "South Korea" if country=="Korea"
replace country = "Sao Tome and Principe" if country=="Sao Tome & Principe"

replace country = strtrim(country) if regexm(country,"Myanmar")
replace country = strtrim(country) if regexm(country,"Netherlands")

sort country year 

// drop countries with multiple exchange rates in a year 
duplicates tag country year, gen(dups)
drop if dups>0 
drop dups
isid country year

// filter to countries with missing 2010 and/or 2019 IMF data
merge m:1 country year using "$output\FOREX\missing_2010_2019_WDI_forex"
drop if _m==1
drop _m

list country year exchangerate forex_wdi numrecs if forex_wdi==. & exchangerate<., sepby(country)

replace forex_wdi=exchangerate if forex_wdi==. & exchangerate<.
drop exchangerate currency
list country year if forex_wdi==., sepby(country)

compress 
save "$output\FOREX\missing_2010_2019_WDI_forex", replace

////////////////////////////////////////////////////////////////////////////////
/////////// fill in missing IRS forex with forex from IMF GEM //////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\GEM\Exchange rate, new LCU per USD extended backward, period average.xlsx", ///
clear first sheet("annual") cellrange(A1:GR32)
ren A year 

keep if inlist(year,2010, 2019)

keep year Cyprus Netherlands Slovenia VenezuelaRB 

qui des, varlist
local myvars=r(varlist)
foreach var of local myvars {
	di "*****************************************************************"
	di "****************** the country is `var' *************************"
	di "*****************************************************************"
	capture replace `var'="" if `var'=="NA"
	destring `var', replace
}

xpose, clear varname
ren _varname country
order country 

ren v1 forex_2010
ren v2 forex_2019

foreach y in 2010 2019 {
	assert forex_`y'[1] == `y'
}

drop if country=="year"
compress 

replace country = "Venezuela" if country=="VenezuelaRB"

reshape long forex_, i(country) j(year)
ren forex_ gem_forex

merge 1:1 country year using "$output\FOREX\missing_2010_2019_WDI_forex"
assert _m!=1
sort country year 
replace forex_wdi = gem_forex if forex_wdi==. & gem_forex<. & _m==3
drop gem_forex _m numrecs
ren forex_ update_
reshape wide update_, i(country) j(year)

merge 1:1 country using "$output\FOREX\forex_2010_and_2019"
assert _m!=1
sort country 

foreach y in 2010 2019 {
	replace forex_`y' = update_`y' if forex_`y'==. & update_`y'<. & _m==3
}

drop update* _m numrecs

egen numrecs = rownonmiss(forex_2010 forex_2019) 
tab numrecs, m
order numrecs
sort country 
list if numrecs<2, sep(0)

compress 
sort country 
isid country 
count 

save "$output\FOREX\forex_2010_and_2019", replace

log close 

exit

// end