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
log using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\make_analytical_data_ihme_countries_age15_cohort_prob_true_positive", text replace 

gl analysis discounted 

/*
inputs:
analytical_data_ihme_countries_age15_cohort_truncated.dta created in: make_analytical_data_ihme_countries_age15_cohort_truncated.do 
who_regions_income_groups.dta created in: make_who_regions_income_groups.do 
outputs:
analytical_data_ihme_countries_age15_cohort_prob_true_positive.dta
*/

////////////////////////////////////////////////////////////////////////////////
/// recode probabilities of true positive and false negative in LICs to the ////
//////////////////////// values for MICs and HICs //////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\GEO DATA\who_regions_income_groups", clear 
keep country income_group_1

merge 1:m country using "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated"
assert _m!=2
keep if _m==3 
drop _m 

sort country year age 

qui tab country 
di "There are `r(r)' countries"
// 189 ihme countries 

assert prob_true_pos + prob_false_neg ==1

sum prob_true_pos if inlist(income_group_1, "High Income","Middle Income")
sum prob_true_pos if income_group_1 =="Low income"

replace prob_true_pos  = 0.995 if income_group_1 =="Low income"
replace prob_false_neg = 0.005 if income_group_1 =="Low income"

assert prob_true_pos  == 0.995  
assert prob_false_neg == 0.005 
assert prob_true_pos + prob_false_neg ==1

drop income_group_1

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
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_prob_true_positive", replace

log close 

exit 

// end 