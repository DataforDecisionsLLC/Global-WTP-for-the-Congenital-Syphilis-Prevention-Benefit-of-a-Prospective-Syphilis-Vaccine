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
log using "$output\LIFE TABLES\make_raw_life_tables_females", text replace

/*
inputs: 
WPP2022_MORT_F06_3_SINGLE_AGE_LIFE_TABLE_PROJECTIONS_FEMALE.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
outputs:
raw_life_tables_females.dta
*/

////////////////////////////////////////////////////////////////////////////////
/////////////// read in UN single-age life tables 2015-2021 estimates //////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\LIFE TABLES\WPP2022_MORT_F06_3_SINGLE_AGE_LIFE_TABLE_PROJECTIONS_FEMALE.xlsx", ///
clear sheet("Medium 2022-2049 import") cellrange(C1:Q667409)  first case(lower)
assert type=="Country/Area"
drop type

ren agex age
ren ageintervaln n 
ren centraldeathratemxn m
ren probabilityofdyingqxn q
ren probabilityofsurvivingpxn p_surviving
ren numberofsurvivorslx survivors_l
ren numberofdeathsdxn d
ren numberofpersonyearslivedlx L
ren survivalratiosxn survival_ratio
ren personyearslivedtx T
ren expectationoflifeex e
ren averagenumberofyearsliveda a

compress
save "$output\LIFE TABLES\raw_life_tables_females", replace 

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

compress
save "$output\LIFE TABLES\raw_life_tables_females", replace 


import excel using "$raw\LIFE TABLES\WPP2022_MORT_F06_3_SINGLE_AGE_LIFE_TABLE_PROJECTIONS_FEMALE.xlsx", ///
clear sheet("Medium 2050-2079 import") cellrange(C1:Q715081)  first case(lower)
assert type=="Country/Area"
drop type

ren agex age
ren ageintervaln n 
ren centraldeathratemxn m
ren probabilityofdyingqxn q
ren probabilityofsurvivingpxn p_surviving
ren numberofsurvivorslx survivors_l
ren numberofdeathsdxn d
ren numberofpersonyearslivedlx L
ren survivalratiosxn survival_ratio
ren personyearslivedtx T
ren expectationoflifeex e
ren averagenumberofyearsliveda a

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

append using "$output\LIFE TABLES\raw_life_tables_females"
sort country year age 

compress
save "$output\LIFE TABLES\raw_life_tables_females", replace 

log close 

exit 

// end