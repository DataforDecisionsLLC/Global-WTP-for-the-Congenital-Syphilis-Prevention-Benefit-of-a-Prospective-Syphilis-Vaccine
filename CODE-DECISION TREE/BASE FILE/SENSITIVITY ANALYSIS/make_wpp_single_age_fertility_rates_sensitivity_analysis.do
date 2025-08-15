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
log using "$output\FERTILITY\SENSITIVITY ANALYSIS\make_wpp_single_age_fertility_rates_sensitivity_analysis", text replace 

/*
inputs:
WPP2022_FERT_F01_FERTILITY_RATES_BY_SINGLE_AGE_OF_MOTHER.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
output:
wpp_single_age_fertility_rates_sensitivity_analysis.dta
*/

////////////////////////////////////////////////////////////////////////////////
///// single age fertility rates (live births per 1,000 women) 2022-2100  //////
///////////////////////////// high variant /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\WPP\WPP2022_FERT_F01_FERTILITY_RATES_BY_SINGLE_AGE_OF_MOTHER.xlsx", ///
clear sheet("import_high_variant") first case(lower) cellrange(C2:AN18646)
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

gen variant="high"
order variant

sort country year 
isid country year 
compress 
save         "$output\FERTILITY\SENSITIVITY ANALYSIS\wpp_single_age_fertility_rates_high_variant", replace

////////////////////////////////////////////////////////////////////////////////
///// single age fertility rates (live births per 1,000 women) 2022-2100  //////
////////////////////////////// low variant /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\WPP\WPP2022_FERT_F01_FERTILITY_RATES_BY_SINGLE_AGE_OF_MOTHER.xlsx", ///
clear sheet("import_low_variant") first case(lower) cellrange(C2:AN18646)
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

gen variant="low"
order variant

append using "$output\FERTILITY\SENSITIVITY ANALYSIS\wpp_single_age_fertility_rates_high_variant"
sort country year variant
isid country year variant
compress 
save         "$output\FERTILITY\SENSITIVITY ANALYSIS\wpp_single_age_fertility_rates_sensitivity_analysis", replace

log close 
exit 

// end 
