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
log using "$output\FERTILITY\make_probability_pregnant", text replace 

/*
inputs:
WPP2022_FERT_F01_FERTILITY_RATES_BY_SINGLE_AGE_OF_MOTHER.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
STATcompilerExport2023921_16509.xlsx
Huang_2008_figure_2.xlsx
outputs:
dhs_ratio_tb_lb.dta
probability_pregnant.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////// single age fertility rates (live births per 1,000 women) /////////////
///////////////////////////// 2019-2100 ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\WPP\WPP2022_FERT_F01_FERTILITY_RATES_BY_SINGLE_AGE_OF_MOTHER.xlsx", ///
clear sheet("import_estimates") first case(lower) cellrange(C2:AN710)
drop type 
compress

// keep only the ihme countries 

replace country = "Bolivia" if country=="Bolivia (Plurinational State of)"
replace country = "Czech Republic" if country=="Czechia"
replace country = "North Korea" if country=="Dem. People's Republic of Korea"
replace country = "Swaziland" if country=="Eswatini"
replace country = "The Gambia" if country=="Gambia"
replace country = "Iran" if country=="Iran (Islamic Republic of)"
replace country = "Laos" if country=="Lao People's Democratic Republic"
replace country = "Federated States of Micronesia" if country=="Micronesia (Fed. States of)"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "South Korea" if country=="Republic of Korea"
replace country = "Moldova" if country=="Republic of Moldova"
replace country = "Syria" if country=="Syrian Arab Republic" 
replace country = "Tanzania" if country=="United Republic of Tanzania"
replace country = "Venezuela" if country=="Venezuela (Bolivarian Republic of)"
replace country = "Vietnam" if country=="Viet Nam"
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Cote d'Ivoire" if country=="Côte d'Ivoire"
replace country = "Palestine" if country=="State of Palestine"
replace country = "Taiwan" if country=="China, Taiwan Province of China"
replace country = "The Bahamas" if country=="Bahamas"
replace country = "Turkey" if country=="Türkiye"
replace country = "United States" if country=="United States of America" 

compress 
save "$output\FERTILITY\wpp_single_age_fertility_rates", replace

merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert _m!=2 
drop if _m ==1 
drop _m 

compress 
save "$output\FERTILITY\wpp_single_age_fertility_rates", replace

import excel using "$raw\WPP\WPP2022_FERT_F01_FERTILITY_RATES_BY_SINGLE_AGE_OF_MOTHER.xlsx", ///
clear sheet("import_medium_variant") first case(lower) cellrange(C2:AN18646)
drop type 
compress

ren regionsubregioncountryorar country 

// keep only the ihme countries 

replace country = "Bolivia" if country=="Bolivia (Plurinational State of)"
replace country = "Czech Republic" if country=="Czechia"
replace country = "North Korea" if country=="Dem. People's Republic of Korea"
replace country = "Swaziland" if country=="Eswatini"
replace country = "The Gambia" if country=="Gambia"
replace country = "Iran" if country=="Iran (Islamic Republic of)"
replace country = "Laos" if country=="Lao People's Democratic Republic"
replace country = "Federated States of Micronesia" if country=="Micronesia (Fed. States of)"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "South Korea" if country=="Republic of Korea"
replace country = "Moldova" if country=="Republic of Moldova"
replace country = "Syria" if country=="Syrian Arab Republic" 
replace country = "Tanzania" if country=="United Republic of Tanzania"
replace country = "Venezuela" if country=="Venezuela (Bolivarian Republic of)"
replace country = "Vietnam" if country=="Viet Nam"
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Cote d'Ivoire" if country=="Côte d'Ivoire"
replace country = "Palestine" if country=="State of Palestine"
replace country = "Taiwan" if country=="China, Taiwan Province of China"
replace country = "The Bahamas" if country=="Bahamas"
replace country = "Turkey" if country=="Türkiye"
replace country = "United States" if country=="United States of America" 

merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert _m!=2 
drop if _m ==1 
drop _m 

append using "$output\FERTILITY\wpp_single_age_fertility_rates"
sort country year 
isid country year 
compress 
save         "$output\FERTILITY\wpp_single_age_fertility_rates", replace

////////////////////////////////////////////////////////////////////////////////
///////////// age group specific share of total stillbirths from DHS ///////////
///////////////////////////// time invariant ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\DHS\STATcompilerExport2023921_16509.xlsx", ///
clear sheet("Indicator Data") first case(lower) cellrange(B1:I2041)
drop surveyname byvariable characteristiccategory
compress
ren countryname country
keep if indicator=="Stillbirth rate"
ren characteristiclabel age_group
isid country surveyyear age_group 

// keep the most recent surveyyear for which there are non-missing and positive stillbirth rates 
 
ren value sb_rate
drop if sb_rate==.
drop if sb_rate==0
 
sort country age_group surveyyear
by country age_group : keep if _n==_N
isid country age_group
drop surveyyear

replace age_group = "15-19" if age_group=="<20"
drop if age_group =="Total 15-49"
sort country age_group 

// compute the live birth rate as 1000-stillbirth rate

gen lb_rate = 1000-sb_rate 

// compute ratio of total births to live births 

gen ratio_tb_lb = (lb_rate + sb_rate)/lb_rate
keep country age_group ratio_tb_lb

// extrapolate this ratio to all single ages in an age group

split age_group, parse("-") gen(age)
destring age1, replace 
destring age2, replace 
gen expand = age2-age1 + 1
expand expand 
sort country age_group age1
by country age_group: replace age1=age1[_n-1] +1 if _n>1
by country age_group: assert age1==age2 if _n==_N
drop age2 age_group expand 
ren age1 age

order country age ratio_tb_lb
sort country age 
compress 

// keep only the ihme countries 

replace country = "Swaziland" if country=="Eswatini"
replace country = "The Gambia" if country=="Gambia" 
replace country = "Kyrgyzstan" if country=="Kyrgyz Republic" 

merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert _m!=1
keep if _m==3
drop _m 
  
assert  ratio_tb_lb>1 & ratio_tb_lb<.
sum ratio_tb_lb,d

compress  
save "$output\FERTILITY\dhs_ratio_tb_lb", replace

////////////////////////////////////////////////////////////////////////////////
////// multiply the single age ratios of total births to live births to the ////
////// single age fertility rates to compute the adjusted fertility rates //////
////////////////////////////////////////////////////////////////////////////////

use "$output\FERTILITY\wpp_single_age_fertility_rates", clear 

forvalues a = 15/49 {
	ren age_`a' fert_`a'
}

reshape long fert_, i(country year who_region income_group_1 ) j(age)
sort country year age 

merge m:1 country age using "$output\FERTILITY\dhs_ratio_tb_lb"
assert _m!=2 
keep if _m==3 
drop _m 
sort country year age 
assert ratio_tb_lb>=1 & ratio_tb_lb<.
gen dhs_fert=fert_*ratio_tb_lb
drop fert_ ratio_tb_lb
order country year age dhs_fert
isid country year age
assert dhs_fert<. 
drop if year>2064
compress
save "$output\FERTILITY\dhs_adj_single_age_fertility_rates", replace

////////////////////////////////////////////////////////////////////////////////
//// map ratio of total births to live births for younger (age 15-34) and //////
////// older (age 35+) mothers from Huang to the single age fertility rates ////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\HUANG\Huang_2008_figure_2.xlsx", ///
clear sheet("import") first case(lower) cellrange(A1:K39)
keep if rownum=="totals" 
keep ratio_tb_lb_older ratio_tb_lb_younger
 
append using "$output\FERTILITY\wpp_single_age_fertility_rates"
replace ratio_tb_lb_older = ratio_tb_lb_older[_n-1] if _n>1 & ratio_tb_lb_older==.
replace ratio_tb_lb_younger = ratio_tb_lb_younger[_n-1] if _n>1 & ratio_tb_lb_younger==.

foreach a in older younger {
	assert ratio_tb_lb_`a'>1 & ratio_tb_lb_`a'<.
}

drop if country==""
order country 

forvalues a = 15/49 {
	gen huang_fert_`a' = .
}

forvalues a = 15/34 {
	replace huang_fert_`a' = age_`a'*ratio_tb_lb_younger
}

forvalues a = 35/49 {
	replace huang_fert_`a' = age_`a'*ratio_tb_lb_older
}

keep country year who_region income_group_1 huang_fert_*
drop if year>2064 

forvalues a = 15/49 {
	assert huang_fert_`a' < .
}

reshape long huang_fert_, i(country who_region income_group_1 year) j(age)
reshape wide huang_fert_, i(country who_region income_group_1 age) j(year)

save "$output\FERTILITY\huang_adj_single_age_fertility_rates", replace

////////////////////////////////////////////////////////////////////////////////
////////////// combine the dhs and huang adjected fertility rates //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\FERTILITY\huang_adj_single_age_fertility_rates", clear 
reshape long huang_fert_, i(country who_region income_group_1 age) j(year)
ren huang_fert_ huang_fert

isid country year age 
merge 1:1 country age year who_region income_group_1  using "$output\FERTILITY\dhs_adj_single_age_fertility_rates"
assert _m!=2 

tab who_region income_group_1 if _m==1 
tab country who_region if _m==1 & income_group_1=="Low income", m

sort country age 
keep if year>=2030 & year<=2064

qui sum age 
assert `r(min)'==15 
assert `r(max)'==49

qui sum year 
assert `r(min)'==2030
assert `r(max)'==2064

gen compare=dhs_fert/huang_fert
sum compare if _m==3 , d 

drop compare
assert dhs_fert>0

gen adj_fert=. 
replace adj_fert=huang_fert if _m==1 & huang_fert<. 
replace adj_fert=dhs_fert if dhs_fert<. & adj_fert==.
assert adj_fert<.

keep country year age adj_fert who_region income_group_1

sum adj_fert,d
replace adj_fert=adj_fert/1000
sum adj_fert,d

// convert fertility rates to a pregnancy probability

gen prob_preg = 1-exp(-1*adj_fert) 
sum prob_preg, d
drop adj_fert

qui tab country 
di "There are `r(r)' countries"

compress 

save "$output\FERTILITY\probability_pregnant", replace 

log close 

exit 

// end 