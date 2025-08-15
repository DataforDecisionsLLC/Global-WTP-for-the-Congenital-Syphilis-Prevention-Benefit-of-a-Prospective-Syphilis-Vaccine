
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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_nonABO_acute_costs_series", text replace

/*
inputs:
AIU Detailed Costing Dataset.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
who_choice_2019USDs.dta created in: make_who_choice_2019USDs.do
who_choice_extrapolations.dta created in: make_who_choice_extrapolations.do 
births by cesarean (%) in 5 years preceding survey.xlsx
births by cesarean (%) in 2-3 years preceding survey.xlsx
2019_pcgdp.dta created in: make_2019_pcgdp.do
pcgdp_series.dta created in: make_pcgdp_series.do
outputs:
guttmacher_birth_costs_raw.dta
guttmacher_birth_costs.dta
nonABO_birth_costs_countries_not_in_guttmacher.dta
who_choice_countries_not_in_guttmacher.dta
nonABO_acute_costs_series.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////////////// vaginal deliver and c-section costs //////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/GUTTMACHER/AIU Detailed Costing Dataset.xlsx", ///
clear first sheet("AIU Detailed Costing Dataset") 
keep c_country c_vagdev* c_csection*
ren c_country country
count 

replace country = "Cape Verde" if country=="Cabo Verde" 
replace country = "The Gambia" if country=="Gambia" 
replace country = "Laos" if country=="Lao People's Dem. Republic" 
replace country = "Federated States of Micronesia" if country=="Micronesia" 
replace country = "Palestine" if country=="State of Palestine" 
replace country = "Timor-Leste" if country=="Timor" 
replace country = "Vietnam" if country=="Viet Nam" 

// keep only the IHME relavant data 

merge 1:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", ///
keepusing(country who_region income_group_1)
assert _m!=1 
keep if _m==3 
drop _m 
tab who_region income_group_1 , m 

compress 
sort country 

sum c_csection_sup c_vagdev_sup

save "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs_raw", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// combine WHO CHOICE and guttmacher data //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_2019USDs", clear
drop if has_data==0
keep country prim_hosp_2019USD tert_hosp_2019USD pcgdp2019usd
append using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_extrapolations"
assert prim_hosp_2019USD<.
assert tert_hosp_2019USD<.
sort country 
count 

merge 1:1 country using "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs_raw"
keep if _m==3 
drop _m 
sort country 

isid country 
count 

order country prim_hosp_2019USD tert_hosp_2019USD c_csection_sup c_csection_pers c_csection_hosp c_vagdev_sup c_vagdev_pers c_vagdev_hosp who_region income_group_1

compress 
sort country 
save "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs", replace

////////////////////////////////////////////////////////////////////////////////
//// impute missing % births by c-section data to guttmacher countries using ///
//////////////////// the who region average values /////////////////////////////
////////////////////////////////////////////////////////////////////////////////

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

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs", keepusing(country who_region)
keep if _m==3 
drop _m 
collapse (mean) pct_csection_15_19_region = pct_csection_15_19 pct_csection_20_49_region = pct_csection_20_49, by(who_region)
save "$output\ECONOMIC DATA\DIRECT COSTS\percent_csection_by_region_guttmacher_countries", replace

////////////////////////////////////////////////////////////////////////////////
/////////////// map on the percent of births by c-section //////////////////////
////////////////////////////////////////////////////////////////////////////////

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

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs"
assert _m!=1
drop _m 

merge m:1 who_region using "$output\ECONOMIC DATA\DIRECT COSTS\percent_csection_by_region_guttmacher_countries"
assert _m==3 
drop _m 

replace pct_csection_15_19 = pct_csection_15_19_region if pct_csection_15_19==.
replace pct_csection_20_49 = pct_csection_20_49_region if pct_csection_20_49==.

drop c_csection_pers c_csection_hosp c_vagdev_pers c_vagdev_hosp pct_csection_15_19_region pct_csection_20_49_region

sort country 

gen cost_rvd = 2*prim_hosp_2019USD + c_vagdev_sup
gen cost_cs  = 7*tert_hosp_2019USD + c_csection_sup

gen cost_birth_15_19 = cost_cs*pct_csection_15_19 + cost_rvd*(1-pct_csection_15_19)
gen cost_birth_20_49 = cost_cs*pct_csection_20_49 + cost_rvd*(1-pct_csection_20_49)

assert cost_birth_15_19<.
assert cost_birth_20_49<. 

save "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs", replace 

////////////////////////////////////////////////////////////////////////////////
//////// get WHO CHOICE data for MICs/HICs not in guttmacher data //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_2019USDs", clear
drop if has_data==0
keep country prim_hosp_2019USD tert_hosp_2019USD pcgdp2019usd
append using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_extrapolations"
assert prim_hosp_2019USD<.
assert tert_hosp_2019USD<.
sort country 
count 

// keep only the IHME relavant data 

merge 1:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", ///
keepusing(country who_region income_group_1)
assert _m!=1 
keep if _m==3 
drop _m 

// keep countries in WHO CHOICE not in guttmacher 

merge 1:1 country using "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs_raw", keepusing(country)
keep if _m==1 
drop _m 
sort country 
isid country 
count 

compress 
sort country 
save "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_countries_not_in_guttmacher", replace

////////////////////////////////////////////////////////////////////////////////
//// impute missing births by c-section data to countries not in guttmacher ////
//////////////////// the who region average values /////////////////////////////
////////////////////////////////////////////////////////////////////////////////

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

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_countries_not_in_guttmacher", keepusing(country who_region)
keep if _m==3 
drop _m 
collapse (mean) pct_csection_region = pct_csection, by(who_region)
save "$output\ECONOMIC DATA\DIRECT COSTS\percent_csection_by_region_countries_not_in_guttmacher", replace

////////////////////////////////////////////////////////////////////////////////
/////////////// map on the percent of births by c-section //////////////////////
////////////////////////////////////////////////////////////////////////////////

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

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_countries_not_in_guttmacher"
drop if _m==1
drop _m 

merge m:1 who_region using "$output\ECONOMIC DATA\DIRECT COSTS\percent_csection_by_region_countries_not_in_guttmacher"
assert _m==3 
drop _m 

replace pct_csection = pct_csection_region if pct_csection==.
drop pct_csection_region

compress 
sort country 
save "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_countries_not_in_guttmacher", replace

////////////////////////////////////////////////////////////////////////////////
///////// compute average ratio of supply costs to hospital costs //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs", clear

keep  country cost_rvd cost_cs prim_hosp_2019USD tert_hosp_2019USD c_csection_sup c_vagdev_sup
order country country prim_hosp_2019USD c_vagdev_sup cost_rvd tert_hosp_2019USD c_csection_sup cost_cs

gen ratio_rvd = c_vagdev_sup/(2*prim_hosp_2019USD)
gen ratio_cs = c_csection_sup/(7*tert_hosp_2019USD)

keep country ratio_rvd ratio_cs

collapse (median) ratio_rvd ratio_cs
list 

save "$output\ECONOMIC DATA\DIRECT COSTS\ratios_supply_to_hospital_costs_guttmacher", replace

////////////////////////////////////////////////////////////////////////////////
// use supply to hospital cost ratios to estimate supply costs for WHO CHOICE //
/////////////////////// countries not in guttmacher ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\ratios_supply_to_hospital_costs_guttmacher", clear
append using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_countries_not_in_guttmacher"

foreach var in ratio_rvd ratio_cs {
	replace `var' = `var'[_n-1] if _n>1 & `var'==.
}

drop if country==""

gen hos_rvd = 2*prim_hosp_2019USD
gen hos_cs = 7*tert_hosp_2019USD

gen c_vagdev_sup   = ratio_rvd*hos_rvd
gen c_csection_sup = ratio_cs*hos_cs

gen cost_rvd = 2*prim_hosp_2019USD + c_vagdev_sup
gen cost_cs  = 7*tert_hosp_2019USD + c_csection_sup

gen cost_birth = cost_cs*pct_csection + cost_rvd*(1-pct_csection)

gen cost_birth_15_19 = cost_birth
gen cost_birth_20_49 = cost_birth
drop cost_birth

gen guttmacher = "no"
keep  guttmacher country cost_birth_15_19 cost_birth_20_49 pcgdp2019usd who_region income_group_1
order guttmacher country cost_birth_15_19 cost_birth_20_49 pcgdp2019usd

compress 

save "$output\ECONOMIC DATA\DIRECT COSTS\nonABO_birth_costs_countries_not_in_guttmacher", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// combine guttmacher and non-guttmacher countries ///////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\guttmacher_birth_costs", clear
gen guttmacher = "yes"
keep guttmacher country who_region income_group_1 pcgdp2019usd cost_birth_15_19 cost_birth_20_49
append using "$output\ECONOMIC DATA\DIRECT COSTS\nonABO_birth_costs_countries_not_in_guttmacher"
order guttmacher country who_region income_group_1 pcgdp2019usd cost_birth_15_19 cost_birth_20_49

compress 
count 

gen pct_pcgdp_15_19 = cost_birth_15_19/pcgdp2019usd
gen pct_pcgdp_20_49 = cost_birth_20_49/pcgdp2019usd
sum pct_pcgdp_15_19, d 
sum pct_pcgdp_20_49, d

save "$output\ECONOMIC DATA\DIRECT COSTS\nonABO_birth_costs_2019USD", replace 

////////////////////////////////////////////////////////////////////////////////
//// map percent pcgdp to the pcgdp series and compute cost as a percent of ////
/////////////////////////// pcgdp from 2022 to 2064 ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\nonABO_birth_costs_2019USD", clear 
keep country who_region income_group_1 pct_pcgdp_15_19 pct_pcgdp_20_49
merge 1:m country who_region income_group_1 using "$output\ECONOMIC DATA\pcgdp_series"
tab country if _m==1 

assert _m!=2
keep if _m==3 
drop _m 
sort country year 

gen acute_cost_nonABO_15_19=pct_pcgdp_15_19*pcgdp
gen acute_cost_nonABO_20_49=pct_pcgdp_20_49*pcgdp

keep country year acute_cost_nonABO_15_19 acute_cost_nonABO_20_49

qui tab country 
di "There are `r(r)' countries in the series"
// 189 countries

save "$output\ECONOMIC DATA\DIRECT COSTS\nonABO_acute_costs_series", replace

log close 
exit 

// end