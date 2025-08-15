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
births by cesarean (%) in 5 years preceding survey.xlsx
guttmacher_birth_costs_raw.dta created in: make_nonABO_acute_costs_series.do
births by cesarean (%) in 2-3 years preceding survey.xlsx
who_choice_countries_not_in_guttmacher.dta created in: make_nonABO_acute_costs_series.do 
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
outputs:
countries_w_missing_percent_csection.dta
*/

import excel using "$raw/WHO/births by cesarean (%) in 5 years preceding survey.xlsx", ///
clear first sheet("import") cellrange(H1:X865) case(lower)

keep location period dim1 factvaluenumeric
ren location country 
ren period year 
ren dim1 age_group 
ren factvaluenumeric pct_csection_
drop if pct_csection==. 
sort country age year
by country age: keep if _n==_N 
by country: assert _N==2 
drop year

replace age_group="15_19" if age_group=="15-19 years"
replace age_group="20_49" if age_group=="20-49 years"

replace pct_csection_=pct_csection_/100

reshape wide pct_csection_, i(country) j(age_group) string

replace country = "Bolivia" if country =="Bolivia (Plurinational State of)"
replace country = "The Gambia" if country =="Gambia"
replace country = "Cote d'Ivoire" if country =="CÃ´te dâ€™Ivoire"
replace country = "Swaziland" if country =="Eswatini"
replace country = "Turkey" if country =="TÃ¼rkiye"
replace country = "Tanzania" if country =="United Republic of Tanzania"
replace country = "Moldova" if country =="Republic of Moldova"

keep country 
isid country

merge 1:1 country using "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs_raw", keepusing(country)
assert _m!=1
keep if _m==2 
drop _m 
count 

save "$output\ECONOMIC DATA\DIRECT COSTS\countries_w_missing_percent_csection", replace



import excel using "$raw/WHO/births by cesarean (%) in 2-3 years preceding survey.xlsx", ///
clear first sheet("import") cellrange(A1:C174) case(lower)
destring birthsbycaesareansection, replace 
ren birthsbycaesareansection pct_csection
replace pct_csection=pct_csection/100
isid country 
keep country pct_csection
sort country 
compress 

replace country = "" if country ==""

replace country = "Bolivia" if country =="Bolivia (Plurinational State of)"
replace country = "The Gambia" if country =="Gambia"
replace country = "Cote d'Ivoire" if country =="CÃ´te dâ€™Ivoire"
replace country = "Netherlands" if country =="Netherlands (Kingdom of the)"
replace country = "South Korea" if country =="Republic of Korea"
replace country = "Swaziland" if country =="Eswatini"
replace country = "Turkey" if country =="TÃ¼rkiye"
replace country = "Tanzania" if country =="United Republic of Tanzania"
replace country = "United Kingdom" if country =="United Kingdom of Great Britain and Northern Ireland"
replace country = "United States" if country =="United States of America"

replace country = "Moldova" if country =="Republic of Moldova"
replace country = "Czech Republic" if country =="Czechia"
replace country = "Dominica" if country =="Dominican Republic"

keep country 
isid country 

merge 1:1 country using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_countries_not_in_guttmacher", keepusing(country)
keep if _m==2 
drop _m 

merge 1:1 country using "$output\ECONOMIC DATA\DIRECT COSTS\countries_w_missing_percent_csection"
assert _m!=3 
drop _m 
sort country 

merge 1:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", ///
keepusing(country who_region income_group_1)
assert _m!=1 

keep if _m==3 
drop _m 
isid country 
count 

save "$output\ECONOMIC DATA\DIRECT COSTS\countries_w_missing_percent_csection", replace