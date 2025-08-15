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
log using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\make_analytical_data_ihme_countries_age15_cohort_lower", text replace 

gl analysis discounted 

/*
inputs:
analytical_data_ihme_countries_age15_cohort_truncated.dta created in: make_analytical_data_ihme_countries_age15_cohort_truncated.do 
probability_infected_vax_novax.dta created in: make_probability_infected_vax_novax_lower.do
daly_loss_case_preterm_2030_2064_truncated.dta created in: make_daly_loss_case_preterm_2030_2064_truncated_lower.do
daly_loss_case_early_symp_cs_2030_2064.dta created in: make_daly_loss_case_early_symp_cs_2030_2064_lower.do
daly_loss_case_late_symp_ns_2030_2064_truncated.dta created in: make_daly_loss_case_late_symp_ns_2030_2064_truncated_lower.do
daly_loss_case_late_symp_hl_2030_2064_truncated.dta created in: make_daly_loss_case_late_symp_hl_2030_2064_truncated_lower.do
outputs:
analytical_data_ihme_countries_age15_cohort_truncated_lower.dta
*/

use "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear 

drop prob_syph_vax prob_no_syph_vax prob_syph_novax prob_no_syph_novax ///
early_symp_cs_dalys preterm_dalys late_symp_hl_dalys late_symp_ns_dalys ///

save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", replace

////////////////////////////////////////////////////////////////////////////////
//////////////// map on the probability of infected with syphilis //////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", clear 

merge 1:1 country age year using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\LOWER\probability_infected_vax_novax"
assert _m!=1 
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==2
keep if _m==3 
drop _m

sort country year age 
isid country year age 
order country age year 
compress 

qui tab country 
di "There are `r(r)' countries"
// 189

save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////////////// map on the LBW/preterm DALYs //////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\LOWER\daly_loss_case_preterm_2030_2064_truncated.dta", clear 
ren birth_year year 
keep country year preterm_dalys

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower"
assert _m!=2
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==1
keep if _m==3 
drop _m 

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"
// 189

compress
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////// map on the early sypmtomatic CS DALYs /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\LOWER\daly_loss_case_early_symp_cs_2030_2064.dta", clear
ren birth_year year 
keep country year early_symp_cs_dalys

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower"
assert _m!=2
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==1
keep if _m==3 
drop _m 

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"
// 189

compress
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", replace

////////////////////////////////////////////////////////////////////////////////
////////////// map on the late sypmtomatic CS neurosyphilis DALYs //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\LOWER\daly_loss_case_late_symp_ns_2030_2064_truncated.dta", clear 
ren birth_year year 
keep country year late_symp_ns_dalys

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower"
assert _m!=2
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==1
keep if _m==3 
drop _m 

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"
// 189

compress
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", replace

////////////////////////////////////////////////////////////////////////////////
///////////////// map on the late sypmtomatic CS hearing loss DALYs ////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\LOWER\daly_loss_case_late_symp_hl_2030_2064_truncated.dta", clear 
ren birth_year year 
keep country year late_symp_hl_dalys

merge 1:1 country year using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower"
assert _m!=2
assert inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela") if _m==1
keep if _m==3 
drop _m 

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"
// 189

compress
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// compute the residual node probabilities /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", clear 

// create probability of no infection  

gen prob_no_syph_vax = 1-prob_syph_vax
gen prob_no_syph_novax = 1-prob_syph_novax

foreach p in prob_die prob_no_syph_vax prob_no_syph_novax prob_no_preg {
	assert `p'<.
}

sort country year age 
isid country year 
order country age year 

qui tab country 
di "There are `r(r)' countries"
// 189

compress
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", replace

////////////////////////////////////////////////////////////////////////////////
//////////////// confirm that all node probabilities sum to one ////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", clear 

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
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_truncated_lower", replace

log close 

exit 

// end 