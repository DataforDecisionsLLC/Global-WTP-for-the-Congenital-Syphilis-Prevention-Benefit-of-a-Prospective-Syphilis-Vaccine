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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_government_share_health_expenditures", text replace

/*
inputs:
API_SH.XPD.GHED.CH.ZS_DS2_en_excel_v2_457338_import.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
download_s5ojhb.xlsx
who_regions_income_groups.dta created in: make_who_regions_income_groups.do 
outputs:
government_share_health_expenditures.dta
*/

////////////////////////////////////////////////////////////////////////////////
//// read in WHO GHE series of government share of total health expenditures ///
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\WHO\GHE\API_SH.XPD.GHED.CH.ZS_DS2_en_excel_v2_457338_import.xlsx", ///
clear first sheet("import") case(lower) cellrange(A2:Z268)

assert indicatorname=="Domestic general government health expenditure (% of current health expenditure)" 

drop countrycode indicatorname indicatorcode 
order country 

reshape long yr_, i(country) j(year)

ren yr_ govt_pct_total_exp
replace govt_pct_total_exp = govt_pct_total_exp/100

sum govt_pct_total_exp, d 

sort country year 

compress 
save "$output\ECONOMIC DATA\ghe_govt_pct_total_exp", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////// keep only the study countries ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\ghe_govt_pct_total_exp", clear 

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
replace country = "North Korea" if country =="Korea, Dem. People's Rep."
replace country = "Venezuela" if country =="Venezuela, RB"
replace country = "Vietnam" if country =="Viet Nam"

merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo"

assert country =="Taiwan" if _m==2

drop if _m==1 
drop _m 

qui tab country, m 
di "There are `r(r)' countries"

compress 
save "$output\ECONOMIC DATA\ghe_govt_pct_total_exp", replace

////////////////////////////////////////////////////////////////////////////////
///////////// get govt percent of 2019 health expenditures /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\ghe_govt_pct_total_exp", clear 
ren govt_pct_total_exp gov_pct_ 
replace year = 2019 if country == "Taiwan"
drop if year==.
reshape wide gov_pct_ , i(country) j(year)

drop gov_pct_2020 gov_pct_2021

gen pct_gov=gov_pct_2019
replace pct_gov = gov_pct_2018 if pct_gov==. & gov_pct_2018<.
replace pct_gov = gov_pct_2017 if pct_gov==. & gov_pct_2018==. &  gov_pct_2017<. 
replace pct_gov = gov_pct_2016 if pct_gov==. & gov_pct_2018==. &  gov_pct_2017==. & gov_pct_2016<. 
replace pct_gov = gov_pct_2015 if pct_gov==. & gov_pct_2018==. &  gov_pct_2017==. & gov_pct_2016==. & gov_pct_2015<. 
replace pct_gov = gov_pct_2014 if pct_gov==. & gov_pct_2018==. &  gov_pct_2017==. & gov_pct_2016==. & gov_pct_2015==. & gov_pct_2014<. 
replace pct_gov = gov_pct_2013 if pct_gov==. & gov_pct_2018==. &  gov_pct_2017==. & gov_pct_2016==. & gov_pct_2015==. & gov_pct_2014==. &  gov_pct_2013<. 
replace pct_gov = gov_pct_2012 if pct_gov==. & gov_pct_2018==. &  gov_pct_2017==. & gov_pct_2016==. & gov_pct_2015==. & gov_pct_2014==. &  gov_pct_2013==. &gov_pct_2012<.   
replace pct_gov = gov_pct_2011 if pct_gov==. & gov_pct_2018==. &  gov_pct_2017==. & gov_pct_2016==. & gov_pct_2015==. & gov_pct_2014==. &  gov_pct_2013==. &gov_pct_2012==. & gov_pct_2011<.

keep country who_region income_group_1 pct_gov  

ren  pct_gov  pct_gov_2019

compress 
save "$output\ECONOMIC DATA\government_share_health_expenditures", replace 

////////////////////////////////////////////////////////////////////////////////
////////////// use NTA data to derive government share for Taiwan //////////////
////////////////////////////////////////////////////////////////////////////////

// compute public vs private expenditure splits aggregated across all ages 

import excel using "$raw\NTA\download_s5ojhb.xlsx", ///
clear sheet("download_s5ojhb") first case(lower) cellrange(A1:DI299)

keep if country=="Taiwan"
compress

assert vartype == "Smooth Mean" 
assert singleorfiveyear == "Single"
assert status=="Public"
assert nominalorreal=="Nominal"
replace unit = "Units" if inlist(unit,"Unit","units")

drop attribute varname vartype nominalorreal singleorfiveyear status agegroups upperagegroup

forvalues a = 0/100 {
	destring age`a', replace
}

forvalues a = 0/100 {
	ren age`a' exp_`a'
}

reshape long exp_ , i(country year variablename unit) j(age)

// most countries do not have data for ages 91+; fill down missing data within a country year expenditure type 

sort country year variablename age 
by country year variablename: replace exp_ = exp[_n-1] if exp_==. & _n>1

ren variablename payer
isid country year age payer
replace payer = "public" if payer=="Public Consumption, Health"
replace payer = "private" if payer=="Private Consumption, Health"

// standardize the units 

replace exp_ = exp_*1000 if unit=="Thousands"
replace exp_ = exp_*1000000000 if unit=="Billions"
format exp_ %15.0g
drop unit

// keep the most recent year for each country 

sort country age payer year

by country age payer: keep if _n==_N 
compress
tab year 
assert `r(r)'==1

isid country payer age
sort country payer age

// collapse the data across all ages 

collapse (sum) exp_, by(country payer year)
isid country payer 

sort country payer 
by   country : egen tot_exp = total(exp_)

gen share_=exp_/tot_exp
by   country: egen check=total(share_)
sum check, d 
drop check tot_exp exp_

reshape wide share_, i(country year) j(payer) string

sum share_private 
sum share_public

keep country share_public

merge 1:1 country using "$output\ECONOMIC DATA\government_share_health_expenditures"
assert _m!=1 
replace pct_gov_2019 = share_public if _m==3 & country=="Taiwan"
drop _m share_public  
sort country 

compress 
save "$output\ECONOMIC DATA\government_share_health_expenditures", replace 

////////////////////////////////////////////////////////////////////////////////
// impute missing pct_gov_2019 to North Korea, Palestine & Somalia using ///////
/////////// the median value in who-region/income group ////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\government_share_health_expenditures", clear 
drop who_region income_group_1

merge 1:1 country using "$output\GEO DATA\who_regions_income_groups"
assert _m==3 
drop _m 
sort country 

gen income=""
replace income = "HIC" if income_group_1=="High Income"
replace income = "MIC" if income_group_1=="Middle Income"
replace income = "LIC" if income_group_1=="Low income"
assert income !=""

gen region_income=who_region + "_" + income 
tab region_income, m
drop income 

// there are no donors for North Korea, so recode region_income to WPRO_LIC"

replace region_income = "WPRO_LIC" if country =="North Korea"

list country region_income pct_gov_2019 if inlist(country,"North Korea", "Palestine", "Somalia")

keep if inlist(region_income,"WPRO_LIC","EMRO_MIC","EMRO_LIC")
sort region_income country 
by region_income: egen med_pct_gov = median(pct_gov_2019)
keep if inlist(country,"North Korea", "Palestine", "Somalia")

drop region_income

merge 1:1 country who_region income_group_1 using "$output\ECONOMIC DATA\government_share_health_expenditures"
assert _m!=1

replace pct_gov_2019 =  med_pct_gov if pct_gov_2019==. & _m==3 & inlist(country,"North Korea", "Palestine", "Somalia")
drop med_pct_gov _merge

assert country == "North Korea" if pct_gov_2019==. 

sum pct_gov_2019 if income_group_1=="Low income", d 
sum pct_gov_2019 if income_group_1=="Middle Income", d
sum pct_gov_2019 if income_group_1=="High Income", d

sort country 
count 

drop who_region income_group_1

compress 
save "$output\ECONOMIC DATA\government_share_health_expenditures", replace 

log close 

exit 

// end