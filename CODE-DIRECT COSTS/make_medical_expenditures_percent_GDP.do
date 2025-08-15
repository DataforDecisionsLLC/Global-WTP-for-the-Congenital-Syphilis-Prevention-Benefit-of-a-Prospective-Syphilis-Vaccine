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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_medical_expenditures_percent_GDP", text replace

/*
inputs:
P_Data_Extract_From_World_Development_Indicators-current health expenditures 1989-2022.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
who_regions_income_groups.dta created in: make_who_regions_income_groups.do 
outputs:
medical_expenditures_percent_GDP.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////////// get medical expenditures as a % of GDP from the WDI //////////////
////////////////////////////////////////////////////////////////////////////////

import excel using ///
"$raw\WDI\P_Data_Extract_From_World_Development_Indicators-current health expenditures 1989-2022.xlsx", ///
clear sheet("Data") cellrange(A1:AL435) first case(lower)

keep if seriesname == "Current health expenditure (% of GDP)"

drop countrycode seriescode seriesname
ren countryname country

forvalues y = 1989/2022 {
	replace yr`y'="" if yr`y'==".."
} 

forvalues y = 1989/2022 {
	destring yr`y', replace
} 

forvalues y=1989/1999 {
	assert yr`y'==.
}

drop yr1989-yr1999

compress

qui tab country, m 
di "There are `r(r)' countries"

replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "Faeroe Islands" if country=="Faroe Islands"
replace country = "Congo" if country=="Congo, Rep."
replace country = "Bahamas" if regexm(country,"Bahamas")
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Democratic Republic of Congo" if country=="Congo, Dem. Rep."
replace country = "Egypt" if regexm(country,"Egypt")
replace country = "Gambia" if regexm(country,"Gambia")
replace country = "Hong Kong" if regexm(country,"Hong Kong")
replace country = "Iran" if regexm(country,"Iran, Islamic Rep.")
replace country = "South Korea" if country=="Korea, Rep."
replace country = "North Korea" if country=="Korea, Dem. People's Rep."
replace country = "Kyrgyzstan" if country=="Kyrgyz Republic"
replace country = "Laos" if country=="Lao PDR"
replace country = "Macao" if regexm(country,"Macao")
replace country = "Micronesia (country)" if regexm(country,"Micronesia")
replace country = "Russia" if country=="Russian Federation"
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Saint Kitts and Nevis" if country=="St. Kitts and Nevis"
replace country = "Saint Lucia" if country=="St. Lucia"
replace country = "Saint Vincent and the Grenadines" if country=="St. Vincent and the Grenadines"
replace country = "Saint Martin" if country=="St. Martin (French part)"
replace country = "Turkey" if country=="Turkiye"
replace country = "Yemen" if country=="Yemen, Rep."
replace country = "Palestine" if country=="West Bank and Gaza"
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Czech Republic" if country=="Czechia"
replace country = "Democratic Republic of the Congo" if country=="Democratic Republic of Congo"
replace country = "Federated States of Micronesia" if country=="Micronesia (country)"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "Russian Federation" if country=="Russia"
replace country = "Swaziland" if country=="Eswatini"
replace country = "The Bahamas" if country=="Bahamas"
replace country = "The Gambia" if country=="Gambia"
replace country = "Vietnam" if country=="Viet Nam"

merge m:1 country using  "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert country == "Taiwan" if _m==2
drop if _m==1 
drop _m 

order country who_region income_group_1
isid country 
count 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\wdi_medical_expenditures_percent_gdp_series_raw", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// map on the who region and world bank income group /////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\wdi_medical_expenditures_percent_gdp_series_raw", clear 
drop who_region income_group_1

merge 1:1 country using "$output\GEO DATA\who_regions_income_groups"
assert _m==3 
drop _m 
sort country 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\wdi_medical_expenditures_percent_gdp_series_raw", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// keep the most recently year prior to 2020  ////////////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\ECONOMIC DATA\DIRECT COSTS\wdi_medical_expenditures_percent_gdp_series_raw", clear 

// drop countries with all missing data 

egen numyears = rownonmiss(yr2000 yr2001 yr2002 yr2003 yr2004 yr2005 yr2006 yr2007 yr2008 yr2009 yr2010 yr2011 yr2012 yr2013 yr2014 yr2015 yr2016 yr2017 yr2018 yr2019 yr2020 yr2021 yr2022)

tab numyears , m

list country if numyears==0, sep(0)

drop if numyears==0 
count 
 
drop numyears

// keep the last year closest to 2019 

reshape long yr, i(country who_region income_group_1) j(year)
ren yr pctgdp 
drop if year>2019
drop if pctgdp ==.
sort country year 
by country: keep if _n==_N
tab year 

keep country pctgdp who_region income_group_1
count 

replace pctgdp = pctgdp/100
gen has_pct_gdp=1
order country has_pct_gdp pctgdp

save "$output\ECONOMIC DATA\DIRECT COSTS\medical_expenditures_percent_GDP", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////// identify the countries without data ///////////////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\ECONOMIC DATA\DIRECT COSTS\wdi_medical_expenditures_percent_gdp_series_raw", clear 

egen numyears = rownonmiss(yr2000 yr2001 yr2002 yr2003 yr2004 yr2005 yr2006 yr2007 yr2008 yr2009 yr2010 yr2011 yr2012 yr2013 yr2014 yr2015 yr2016 yr2017 yr2018 yr2019 yr2020 yr2021 yr2022)

tab numyears , m

keep if numyears==0

// exclude North Korea since it does not have any PCGDP data

drop if country == "North Korea"
sort who_region income_group_1 country 
list who_region income_group_1 country , sepby(who_region) 

keep country who_region income_group_1
save  "$output\ECONOMIC DATA\DIRECT COSTS\wdi_medical_expenditures_percent_gdp_countries_w_missing_data", replace

////////////////////////////////////////////////////////////////////////////////
////// use the region-income average for the countries without data ////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\medical_expenditures_percent_GDP", clear 

gen keepme=0
replace keepme=1 if who_region=="EMRO" & inlist(income_group_1,"Low income","Middle Income")
replace keepme=1 if who_region=="WPRO" & income_group_1=="High Income"
keep if keepme==1 
drop keepme 
egen group = group(who_region income_group_1)
order group 
sort group country
by group: egen mean_pct=mean(pctgdp) 
by group: keep if _n==1 
keep who_region income_group_1 mean_pct 
ren mean_pct  pctgdp

merge 1:m who_region income_group_1 using "$output\ECONOMIC DATA\DIRECT COSTS\wdi_medical_expenditures_percent_gdp_countries_w_missing_data"
assert _m==3 
drop _m 

gen has_pct_gdp=0

append using "$output\ECONOMIC DATA\DIRECT COSTS\medical_expenditures_percent_GDP"
order has_pct_gdp country pctgdp who_region income_group_1

levelsof income_group_1, local(income)
foreach i of local income {
	di "The income group is `i'"
	sum pctgdp if income_group_1=="`i'", d 
}

count 

drop who_region income_group_1

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\medical_expenditures_percent_GDP", replace

log close 

exit 
// end