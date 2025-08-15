set more off
clear all
set type double
set excelxlsxlargefile on
version 18

/*
Instructions: Users need to replace "...." with the appropriate file path.
*/ 

gl root   "...."
gl raw    "$root\RAW DATA"
gl output "$root\OUTPUT"

capture log close
log using "$output\DECISION TREE\BASE FILE\make_coverage_data_ihme_countries", text replace

/*
inputs:
pone.0211720.s002-DB.xlsx
Maternal-and-Newborn-Health-Coverage-Database-Dec-2022.xlsx
Antenatal care coverage by age group - at least one visit (in the 2 or 3 years preceding the survey) (%).xlsx
Women accessing antenatal care (ANC) services who were tested for syphilis (%).xlsx
WHO\Antenatal care attendees positive for syphilis who received treatment (%).xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
outputs:
coverage_data_ihme_countries.dta 
*/

////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// KORENROMP DATASETS ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\KORENROMP\pone.0211720.s002-DB.xlsx", ///
clear sheet("S2 Country estimates") first case(lower) cellrange(A3:G624)
ren a country
drop if regexm(country,"^WHO")
replace country="" if inlist(country,"2012","2016")
replace country = country[_n-1] if country=="" & country[_n-1] !="" & _n>1
drop if pregnancies==. 
keep country anc1coverage syphilisscreeningcoverage treatmentcoverage
ren anc1coverage anc1_koren 
ren syphilisscreeningcoverage testing_koren
ren treatmentcoverage treatment_koren

gen recnum=_n, before(country)
gen year=., before(anc1_koren)

sort country recnum 
by country: replace year = 2012 if _n==1 
by country: replace year = 2016 if _n==2
drop recnum

foreach var in anc1_koren testing_koren treatment_koren {
	replace `var'= subinstr(`var',"*","",.)
}

foreach var in anc1_koren testing_koren treatment_koren {
	destring `var', replace
}

qui tab country
di "There are `r(r)' countries"

compress 
sort country year 
isid country year 

// standardize names to the IHME naming

replace country = "Bolivia" if country=="Bolivia (Plurinational State of)" 
replace country = "Brunei" if country=="Brunei Darussalam" 
replace country = "Congo" if country=="Congo (Brazzaville)" 
replace country = "Cote d'Ivoire" if country=="Côte d'Ivoire" 
replace country = "Federated States of Micronesia" if country=="Micronesia (Federated States of)" 
replace country = "Iran" if country=="Iran (Islamic Republic of)" 
replace country = "Laos" if country=="Lao People's Democratic Republic" 
replace country = "Libya" if country=="Libyan Arab Jamahiriya" 
replace country = "Macedonia" if country=="The former Yugoslav Republic of Macedonia" 
replace country = "Moldova" if country=="Republic of Moldova" 
replace country = "North Korea" if country=="Democratic People's Republic of Korea" 
replace country = "Palestine" if country=="State of Palestine" 
replace country = "South Korea" if country=="Republic of Korea" 
replace country = "Syria" if country=="Syrian Arab Republic" 
replace country = "The Bahamas" if country=="Bahamas"
replace country = "The Gambia" if country=="Gambia" 
replace country = "United Kingdom" if country=="United Kingdom of Great Britain and Northern Ireland" 
replace country = "United States" if country=="United States of America" 
replace country = "Tanzania" if country=="United Republic of Tanzania" 
replace country = "Venezuela" if country=="Venezuela (Bolivarian Republic of)" 
replace country = "Vietnam" if country=="Viet Nam" 

save "$output\DECISION TREE\BASE FILE\coverage_data_korenromp", replace

////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// UNICEF DATASET /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\UNICEF\Maternal-and-Newborn-Health-Coverage-Database-Dec-2022.xlsx", ///
clear sheet("ANC1") first case(lower) 
ren countriesandareas country
qui tab country
di "There are `r(r)' countries"

keep country year national
assert national<.
assert year<. 
tab year, m

qui tab country if year>=2017
di "There are `r(r)' countries"

ren national anc1_unicef
sort country year 
isid country year
compress 

// standardize names to the IHME naming

replace country = "Bolivia" if country=="Bolivia (Plurinational State of)" 
replace country = "Brunei" if country=="Brunei Darussalam" 
replace country = "Cape Verde" if country=="Cabo Verde" 
replace country = "Cote d'Ivoire" if country=="Côte d'Ivoire" 
replace country = "Federated States of Micronesia" if country=="Micronesia (Federated States of)" 
replace country = "Iran" if country=="Iran (Islamic Republic of)" 
replace country = "Laos" if country=="Lao People's Democratic Republic"  
replace country = "Macedonia" if country=="North Macedonia" 
replace country = "Moldova" if country=="Republic of Moldova" 
replace country = "North Korea" if country=="Democratic People's Republic of Korea" 
replace country = "Palestine" if country=="State of Palestine" 
replace country = "Swaziland" if country=="Eswatini" 
replace country = "Syria" if country=="Syrian Arab Republic" 
replace country = "The Bahamas" if country=="Bahamas"
replace country = "The Gambia" if country=="Gambia" 
replace country = "Tanzania" if country=="United Republic of Tanzania" 
replace country = "Venezuela" if country=="Venezuela (Bolivarian Republic of)" 
replace country = "Vietnam" if country=="Viet Nam" 

save "$output\DECISION TREE\BASE FILE\unicef_anc1", replace

////////////////////////////////////////////////////////////////////////////////
///////////////// WHO Global Health Observatory (GHO) DATASETS /////////////////
////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////// ANC1 ///////////////////////////////////////

import excel using "$raw\WHO\Antenatal care coverage by age group - at least one visit (in the 2 or 3 years preceding the survey) (%).xlsx", ///
clear sheet("data") first case(lower) cellrange(H1:X865)
ren location country 
ren period year 
ren dim1 age_group 
ren factvaluenumeric anc1_who_
keep country year age_group anc1_who_
replace age_group = "15_19" if age_group=="15-19 years"
replace age_group = "20_49" if age_group=="20-49 years"

reshape wide anc1_who_, i(country year) j(age_group) string

qui tab country 
di "There are `r(r)' countries"

egen check = rownonmiss(anc1_who_15_19 anc1_who_20_49)
drop if check==0
drop check 

qui tab country 
di "There are `r(r)' countries"

qui tab country if year>=2017 & year<.
di "There are `r(r)' countries"

sort country year 
isid country year
compress 

save "$output\DECISION TREE\BASE FILE\who_gho_age_group_anc1", replace

/////////////////////////////// TESTING COVERAGE ///////////////////////////////

import excel using "$raw\WHO\Women accessing antenatal care (ANC) services who were tested for syphilis (%).xlsx", ///
clear sheet("data") first case(lower) 
keep location period factvaluenumeric
ren location country 
ren period year 
ren factvaluenumeric testing_who

tab year, m
qui tab country,m
di "There are `r(r)' countries"

qui tab country if year>=2017 & year<.
di "There are `r(r)' countries"

sort country year 
isid country year
assert testing_who<. 
compress 

save "$output\DECISION TREE\BASE FILE\who_gho_testing", replace

///////////////////////////////// TREATMENT COVERAGE ///////////////////////////

import excel using "$raw\WHO\Antenatal care attendees positive for syphilis who received treatment (%).xlsx", ///
clear sheet("data") first case(lower) 
keep location period factvaluenumeric
ren location country 
ren period year 
ren factvaluenumeric treatment_who

qui tab country, m
di "There are `r(r)' countries"

drop if treatment_who==. 

qui tab country, m
di "There are `r(r)' countries"

tab year, m
qui tab country if year>=2017 & year<.
di "There are `r(r)' countries"

// Brazil has 2 records in 2021: keep the largest treatment_who value 
sort country year treatment_who
by country year: keep if _n==_N

assert treatment_who<.
isid country year
compress 

save "$output\DECISION TREE\BASE FILE\who_gho_treatment", replace

////////////////////////////// COMBINE WHO GHO DATASETS ////////////////////////

use "$output\DECISION TREE\BASE FILE\who_gho_testing", clear
merge 1:1 country year using "$output\DECISION TREE\BASE FILE\who_gho_treatment"
drop _m 
merge 1:1 country year using "$output\DECISION TREE\BASE FILE\who_gho_age_group_anc1"
drop _m 
sort country year 
compress 
isid country year 
order country year anc1_who_15_19 anc1_who_20_49 testing_who treatment_who

replace country = "Bolivia" if country=="Bolivia (Plurinational State of)" 
replace country = "Brunei" if country=="Brunei Darussalam" 
replace country = "Cape Verde" if country=="Cabo Verde" 
replace country = "Cote d'Ivoire" if country=="CÃ´te dâ€™Ivoire" 
replace country = "Czech Republic" if country=="Czechia" 
replace country = "Federated States of Micronesia" if country=="Micronesia (Federated States of)" 
replace country = "Iran" if country=="Iran (Islamic Republic of)" 
replace country = "Laos" if country=="Lao People's Democratic Republic" 
replace country = "Macedonia" if country=="The former Yugoslav Republic of Macedonia" 
replace country = "Moldova" if country=="Republic of Moldova" 
replace country = "North Korea" if country=="Democratic People's Republic of Korea" 
replace country = "Swaziland" if country=="Eswatini" 
replace country = "The Bahamas" if country=="Bahamas"
replace country = "The Gambia" if country=="Gambia" 
replace country = "Turkey" if country=="TÃ¼rkiye" 
replace country = "United Kingdom" if country=="United Kingdom of Great Britain and Northern Ireland" 
replace country = "Tanzania" if country=="United Republic of Tanzania" 
replace country = "Venezuela" if country=="Venezuela (Bolivarian Republic of)" 
replace country = "Vietnam" if country=="Viet Nam" 

qui tab country 
di "There are `r(r)' countries"

// filter to the IHME relevant countries 

merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country income_group_1)
assert country=="Cook Islands" if _m==1 
drop if _m==1 

tab income_group_1 _m, m

drop _m income_group_1 
compress 
save "$output\DECISION TREE\BASE FILE\who_gho_coverage", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////////////// COMBINE ALL DATASETS ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\coverage_data_korenromp", clear
merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country)
assert country=="Taiwan" if _m==2
drop if _m==1
drop _m

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\who_gho_coverage"
drop _m 
sort country year 
 
compress 
save "$output\DECISION TREE\BASE FILE\coverage_data_ihme_countries", replace

use "$output\DECISION TREE\BASE FILE\unicef_anc1", clear
merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country)
drop if _m==1
drop _m

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\coverage_data_ihme_countries"
drop _m 
sort country year 

foreach var in anc1_unicef anc1_koren testing_koren treatment_koren anc1_who_15_19 anc1_who_20_49 testing_who treatment_who {
	replace `var' = `var'/100
}

compress 
save "$output\DECISION TREE\BASE FILE\coverage_data_ihme_countries", replace

log close 

exit 

// end