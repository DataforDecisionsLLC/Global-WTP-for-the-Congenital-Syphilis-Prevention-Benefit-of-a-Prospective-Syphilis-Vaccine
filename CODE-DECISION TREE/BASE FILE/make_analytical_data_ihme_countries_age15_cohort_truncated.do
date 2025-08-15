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
log using "$output\DECISION TREE\BASE FILE\make_analytical_data_ihme_countries_age15_cohort_truncated", text replace 

gl analysis discounted 

/*
inputs:
decision_tree_parameter_table_structure.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
raw_life_tables_females.dta created in: make_raw_life_tables.do
probability_infected_vax_novax.dta created in: make_probability_infected_vax_novax.do
probability_pregnant.dta created in: make_probability_pregnant.do 
coverage_data_series.dta created in: make_coverage_data_series.do 
who_regions_income_groups.dta created in: make_who_regions_income_groups.do 
acute_costs_series.dta created in: make_acute_costs_series.do 
post_acute_costs_series_truncated.dta created in: make_post_acute_costs_series_truncated.do
indirect_costs_cerebral_palsy.dta created in: make_indirect_costs_cerebral_palsy.do 
lifetime_expected_productivity_costs_hearing_loss_truncated.dta created in: make_lifetime_expected_indirect_costs_hearing_loss_truncated.do 
dalys_sb_nd_discounted.dta created in: make_dalys_sb_nd_discounted.do
daly_loss_case_preterm_2030_2064_truncated.dta created in: make_daly_loss_case_preterm_2030_2064_truncated.do
daly_loss_case_early_symp_cs_2030_2064.dta created in: make_daly_loss_case_early_symp_cs_2030_2064.do
daly_loss_case_late_symp_ns_2030_2064_truncated.dta created in: make_daly_loss_case_late_symp_ns_2030_2064_truncated.do
daly_loss_case_late_symp_hl_2030_2064_truncated.dta created in: make_daly_loss_case_late_symp_hl_2030_2064_truncated.do
probability_abo.dta created in: make_probability_abo.do 
outputs:
analytical_data_ihme_countries_age15_cohort_truncated.dta
*/

////////////////////////////////////////////////////////////////////////////////
////////// keep only the age 15 cohort over the reproductive lifespan //////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$output\DECISION TREE\BASE FILE\decision_tree_parameter_table_structure.xlsx", ///
clear sheet("data") first case(lower) 

replace country = "Antigua and Barbuda" if country=="Antigua & Barbuda" 
replace country = "Bosnia and Herzegovina" if country=="Bosnia & Herzegovina" 
replace country = "Democratic Republic of the Congo" if country=="Congo - Kinshasa" 
replace country = "Congo" if country=="Congo - Brazzaville" 
replace country = "Cote d'Ivoire" if regexm(country, "Ivoire")
replace country = "Czech Republic" if country=="Czechia" 
replace country = "Federated States of Micronesia" if country=="Micronesia (Federated States of)" 
replace country = "Macedonia" if country=="North Macedonia" 
replace country = "Myanmar" if country=="Myanmar (Burma)" 
replace country = "Palestine" if country=="Palestinian Territories" 
replace country = "Russian Federation" if country=="Russia" 
replace country = "Saint Kitts and Nevis" if country=="St. Kitts & Nevis" 
replace country = "Saint Lucia" if country=="St. Lucia" 
replace country = "Saint Vincent and the Grenadines" if country=="St. Vincent & Grenadines" 
replace country = "Sao Tome and Principe" if country=="São Tomé & Príncipe" 
replace country = "Swaziland" if country=="Eswatini" 
replace country = "The Bahamas" if country=="Bahamas" 
replace country = "The Gambia" if country=="Gambia" 
replace country = "Trinidad and Tobago" if country=="Trinidad & Tobago" 

merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country)
assert _m !=2
drop if _m==1
drop _m

qui tab country 
di "There are `r(r)' countries"

sort country year age 
gen age_year = strofreal(age) + "_" + strofreal(year)
order country age year age_year

gen keepme=0 
replace keepme=1 if inlist(age_year, ///
"14_2029", ///
"15_2030", ///
"16_2031", ///
"17_2032", ///
"18_2033", ///
"19_2034", ///
"20_2035", ///
"21_2036", ///
"22_2037")

replace keepme=1 if inlist(age_year, ///
"23_2038", ///
"24_2039", ///
"25_2040", ///
"26_2041", ///
"27_2042", ///
"28_2043", ///
"29_2044", ///
"30_2045", ///
"31_2046")

replace keepme=1 if inlist(age_year, ///
"32_2047", ///
"33_2048", ///
"34_2049", ///
"35_2050", ///
"36_2051", ///
"37_2052", ///
"38_2053", ///
"39_2054", ///
"40_2055")

replace keepme=1 if inlist(age_year, ///
"41_2056", ///
"42_2057", ///
"43_2058", ///
"44_2059", ///
"45_2060", ///
"46_2061", ///
"47_2062", ///
"48_2063", ///
"49_2064")

keep if keepme==1 
drop keepme 
isid country year

qui sum age 
assert `r(min)'==15
assert `r(max)'==35

qui sum year 
assert `r(min)'==2030
assert `r(max)'==2050

// extend the data 15 years to age 49
gen expand=0 
replace expand = 15 if year==2050
expand expand 
sort country age year
by country age: replace year = year[_n-1] + 1 if expand==15 & age==35 & _n>1
by country age: replace age = age[_n-1] + 1 if expand==15 & age==35 & _n>1

drop age_year expand

qui sum age 
assert `r(min)'==15 
assert `r(max)'==49

qui sum year 
assert `r(min)'==2030
assert `r(max)'==2064

qui tab country 
di "There are `r(r)' countries"

compress 
save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace 

////////////////////////////////////////////////////////////////////////////////
////////////// map on the survival ratio from the lifetables ///////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\LIFE TABLES\raw_life_tables_females", clear 
keep country year age survival_ratio
ren survival_ratio prob_survive
keep if year>=2030 & year<=2064

merge 1:1 country year age using "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated"
assert _m!=2 
keep if _m==3 
drop _m 

sort country year age 
isid country year age 
order country age year 
compress 

qui tab country 
di "There are `r(r)' countries"

save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// map on the probability of infected with syphilis //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear 

merge 1:1 country age year using "$output\DECISION TREE\BASE FILE\probability_infected_vax_novax"
assert _m!=1 

assert _m==3 
drop _m

sort country year age 
isid country year age 
order country age year 
compress 

qui tab country 
di "There are `r(r)' countries"

save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace 

////////////////////////////////////////////////////////////////////////////////
////////////////////// map on the probability of pregnancy /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear 

merge 1:1 country age year using "$output\FERTILITY\probability_pregnant"
assert _m!=1 
keep if _m==3 
drop _m who_region 

sort country year age 
isid country year age 
order country age year 
compress 

qui tab country 
di "There are `r(r)' countries"

save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace 

////////////////////////////////////////////////////////////////////////////////
///////////////////// map on the coverage parameters ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear 
 
merge 1:1 country year using "$output\DECISION TREE\BASE FILE\coverage_data_series"
assert _m==3 
drop _m 

sort country year age 
isid country year age 
order country age year 
compress 

qui tab country 
di "There are `r(r)' countries"

save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace 

////////////////////////////////////////////////////////////////////////////////
////// generate "true positive" and "false negative" parameters based on ///////
///////////////// country income group classification //////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\GEO DATA\who_regions_income_groups", clear 
keep country income_group_1

merge 1:m country using "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated"
assert _m==3 
drop _m 

sort country year age 

gen prob_true_pos = .
gen prob_false_neg = . 

replace prob_true_pos = 0.995 if inlist(income_group_1,"Middle Income","High Income")
replace prob_true_pos = 0.86 if income_group_1=="Low income"

replace prob_false_neg = 0.005 if inlist(income_group_1,"Middle Income","High Income")
replace prob_false_neg = 1-0.86 if income_group_1=="Low income"

assert prob_true_pos<. 
assert prob_false_neg<.
assert prob_true_pos + prob_false_neg==1

drop income_group_1

sort country year age 
isid country year age 
order country age year 
compress 

qui tab country 
di "There are `r(r)' countries"

save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace 

////////////////////////////////////////////////////////////////////////////////
// map on costs: acute direct, post acute direct, and indirect for ns and hl ///
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\acute_costs_series", clear 
drop if year<2030
merge 1:1 country year using "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_series_truncated"
assert _m==3 
drop _m 
sort country year

merge 1:1 country year using "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_cerebral_palsy"
drop if year<2030
assert _m==3 
drop _m 
ren indirect_costs_cerebral_palsy indirect_costs_neurosyph
sort country year

merge 1:1 country year using "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_hearing_loss_truncated" , ///
keepusing(country year prod_cost )
assert _m==3 
drop _m 
ren prod_cost indirect_costs_hearingloss
sort country year

gen cost_lbwpt = lifetime_cost_lbwpt
ren acute_cost_nd cost_nd
gen cost_cs = acute_cost_cs + lifetime_cost_nonABO
gen cost_nonABO_15_19 = acute_cost_nonABO_15_19 + lifetime_cost_nonABO
gen cost_nonABO_20_49 = acute_cost_nonABO_20_49 + lifetime_cost_nonABO
ren acute_cost_stillbirth_15_19 cost_stillbirth_15_19 
ren acute_cost_stillbirth_20_49 cost_stillbirth_20_49

gen cost_neurosyph_15_19 = acute_cost_nonABO_15_19 + lifetime_cost_neurosyph + indirect_costs_neurosyph
gen cost_neurosyph_20_49 = acute_cost_nonABO_20_49 + lifetime_cost_neurosyph + indirect_costs_neurosyph

gen cost_hearingloss_15_19 = acute_cost_nonABO_15_19 + lifetime_cost_hearinglos + indirect_costs_hearingloss
gen cost_hearingloss_20_49 = acute_cost_nonABO_20_49 + lifetime_cost_hearinglos + indirect_costs_hearingloss

drop acute* lifetime* indirect_*

merge 1:m country year using "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated"
assert _m!=1 
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==2
keep if _m==3 
drop _m 

gen cost_stillbirth=. 
gen cost_nonABO=. 

replace cost_stillbirth = cost_stillbirth_15_19 if age<=19
replace cost_stillbirth = cost_stillbirth_20_49 if age>19

replace cost_nonABO = cost_nonABO_15_19 if age<=19
replace cost_nonABO = cost_nonABO_20_49 if age>19

gen cost_neurosyph = . 
gen cost_hearingloss = .

replace cost_neurosyph = cost_neurosyph_15_19 if age<=19 
replace cost_neurosyph = cost_neurosyph_20_49 if age>19 

replace cost_hearingloss = cost_hearingloss_15_19 if age<=19
replace cost_hearingloss = cost_hearingloss_20_49 if age>19

drop cost_stillbirth_15_19 cost_stillbirth_20_49 cost_nonABO_15_19 cost_nonABO_20_49
drop cost_neurosyph_15_19 cost_neurosyph_20_49 cost_hearingloss_15_19 cost_hearingloss_20_49

foreach c in lbwpt cs neurosyph hearingloss  {
	assert cost_`c'> cost_nonABO
} 

sort country year age 
isid country year age 
order country age year 
compress 

qui tab country 
di "There are `r(r)' countries"

save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace 

////////////////////////////////////////////////////////////////////////////////
////////////// map on the stillbirths and neonatal death DALYs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear
merge m:1 country year using "$output\DALY\dalys_sb_nd_$analysis"
assert _m!=1 
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==2
keep if _m==3 
drop _m 

qui tab country 
di "There are `r(r)' countries"

save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////////////// map on the LBW/preterm DALYs //////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\daly_loss_case_preterm_2030_2064_truncated", clear 
ren birth_year year 
keep country year preterm_dalys

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated"
assert _m!=2
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==1
keep if _m==3 
drop _m 

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"

compress
save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////// map on the early sypmtomatic CS DALYs /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\daly_loss_case_early_symp_cs_2030_2064.dta", clear
ren birth_year year 
keep country year early_symp_cs_dalys

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated"
assert _m!=2
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==1
keep if _m==3 
drop _m 

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"

compress
save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace

////////////////////////////////////////////////////////////////////////////////
////////////// map on the late sypmtomatic CS neurosyphilis DALYs //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\daly_loss_case_late_symp_ns_2030_2064_truncated.dta", clear 
ren birth_year year 
keep country year late_symp_ns_dalys

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated"
assert _m!=2
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==1
keep if _m==3 
drop _m 

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"

compress
save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace

////////////////////////////////////////////////////////////////////////////////
///////////////// map on the late sypmtomatic CS hearing loss DALYs ////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\daly_loss_case_late_symp_hl_2030_2064_truncated.dta", clear 
ren birth_year year 
keep country year late_symp_hl_dalys

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated"
assert _m!=2
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==1
keep if _m==3 
drop _m 

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"

compress
save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// compute the residual node probabilities /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear 

// create the residual parameters 

gen prob_die = 1-prob_survive
gen prob_no_syph_vax = 1-prob_syph_vax
gen prob_no_syph_novax = 1-prob_syph_novax
gen prob_no_preg = 1-prob_preg

foreach p in prob_die prob_no_syph_vax prob_no_syph_novax prob_no_preg {
	assert `p'<.
}

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"

compress
save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////// map on the terminal node probabilities ///////////////////
//////////////// confirm that all node probabilities sum to one ////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\probability_abo", clear
keep if analysis == "basecase"
drop analysis 

append using "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated"

foreach var in prob_untr_cong_syph prob_trtd_cong_syph prob_untr_hearloss prob_trtd_hearloss prob_uninf_lbw_preterm prob_untr_lbw_preterm prob_trtd_lbw_preterm prob_uninf_neonatal_death prob_untr_neonatal_death prob_trtd_neonatal_death prob_untr_neurosyph prob_trtd_neurosyph prob_uninf_stillbirth prob_untr_stillbirth prob_trtd_stillbirth prob_uninf_normal prob_untr_normal prob_trtd_normal {
	replace `var' = `var'[_n-1] if _n>1
}

drop if country==""

order country age year ///
prob_survive prob_die ///
prob_syph_vax prob_no_syph_vax ///
prob_syph_novax prob_no_syph_novax ///
prob_preg prob_no_preg ///
prob_anc prob_no_anc ///
prob_testing prob_no_testing ///
prob_true_pos prob_false_neg ///
prob_treatment prob_no_treatment ///
prob_uninf_lbw_preterm prob_uninf_neonatal_death prob_uninf_stillbirth prob_uninf_normal ///
prob_untr_cong_syph prob_untr_hearloss prob_untr_lbw_preterm prob_untr_neonatal_death prob_untr_neurosyph prob_untr_stillbirth prob_untr_normal ///
prob_trtd_cong_syph prob_trtd_hearloss prob_trtd_lbw_preterm prob_trtd_neonatal_death prob_trtd_neurosyph prob_trtd_stillbirth prob_trtd_normal ///
cost_lbwpt cost_nd cost_nonABO cost_stillbirth cost_cs cost_neurosyph cost_hearingloss ///
neonatal_dalys stillbirth_dalys 

assert prob_survive + prob_die==1
assert prob_syph_vax + prob_no_syph_vax==1 
assert prob_syph_novax + prob_no_syph_novax==1
assert prob_preg + prob_no_preg==1
assert prob_anc + prob_no_anc==1 
assert prob_testing + prob_no_testing==1
assert prob_true_pos + prob_false_neg==1
assert prob_treatment + prob_no_treatment==1

assert prob_uninf_lbw_preterm + prob_uninf_neonatal_death + prob_uninf_stillbirth + prob_uninf_normal ==1
assert prob_untr_lbw_preterm + prob_untr_neonatal_death + prob_untr_stillbirth + prob_untr_cong_syph + prob_untr_neurosyph + prob_untr_hearloss + prob_untr_normal==1
assert prob_trtd_lbw_preterm + prob_trtd_neonatal_death + prob_trtd_stillbirth + prob_trtd_cong_syph + prob_trtd_neurosyph + prob_trtd_hearloss + prob_trtd_normal==1

qui des prob_*, varlist
local myvars = r(varlist)
di "`myvars'"
foreach p of local myvars {
	di "************** The variable is `p'*****************"
	assert `p'<.
}

qui des cost_*, varlist
local myvars = r(varlist)
di "`myvars'"
foreach p of local myvars {
	di "************** The variable is `p'*****************"
	assert `p'<.
}

qui des *_dalys, varlist
local myvars = r(varlist)
di "`myvars'"
foreach p of local myvars {
	di "************** The variable is `p'*****************"
	assert `p'<.
}

qui des , varlist
local myvars = r(varlist)
di "`myvars'"
foreach p of local myvars {
	di "************** The variable is `p'*****************"
	count if mi(`p')
	assert `r(N)'==0
}

qui sum age 
assert `r(min)'==15 
assert `r(max)'==49

qui sum year 
assert `r(min)'==2030
assert `r(max)'==2064

compress
save "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", replace

log close 

exit 

// end 