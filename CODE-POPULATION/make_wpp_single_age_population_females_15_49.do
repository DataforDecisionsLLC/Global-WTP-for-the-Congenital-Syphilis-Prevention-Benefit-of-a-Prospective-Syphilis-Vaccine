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
log using "$output\POPULATION\make_wpp_single_age_population_females_15_49", text replace

/*
inputs:
WPP2022_POP_F01_3_POPULATION_SINGLE_AGE_FEMALE.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis_with_geo.do
outputs:
wpp_single_age_population_females_15_49.dta
*/

////////////////////////////////////////////////////////////////////////////////
////////////////// get the population of 15 year olds //////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\WPP\WPP2022_POP_F01_3_POPULATION_SINGLE_AGE_FEMALE.xlsx", ///
clear sheet("import_estimates") first case(lower) cellrange(C1:AN709)
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

merge m:1 country using  "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert _m!=2 
drop if _m ==1 
drop _m 

forvalues a = 15/49 {
	ren age_`a' pop`a'
}

forvalues a = 15/49 {
	replace pop`a' = pop`a'*1000
}

compress 
save "$output\POPULATION\wpp_single_age_population_females_15_49", replace


import excel using "$raw\WPP\WPP2022_POP_F01_3_POPULATION_SINGLE_AGE_FEMALE.xlsx", ///
clear sheet("import_medium_variant") first case(lower) cellrange(C1:AN18645)
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

merge m:1 country using  "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert _m!=2 
drop if _m ==1 
drop _m 

forvalues a = 15/49 {
	ren age_`a' pop`a'
}

forvalues a = 15/49 {
	replace pop`a' = pop`a'*1000
}

append using "$output\POPULATION\wpp_single_age_population_females_15_49"
sort country year 
isid country year 

sort country year 
compress 

save "$output\POPULATION\wpp_single_age_population_females_15_49", replace

log close 

exit 

// end

