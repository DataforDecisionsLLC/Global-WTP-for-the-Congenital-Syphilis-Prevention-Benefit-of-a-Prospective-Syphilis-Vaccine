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
log using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\make_analytical_data_ihme_countries_age15_cohort_ve50_wane5", text replace 

gl analysis discounted 

/*
inputs:
analytical_data_ihme_countries_age15_cohort_truncated.dta created in: make_analytical_data_ihme_countries_age15_cohort_truncated.do 
probability_infected_vax_novax_ve50_wane5.dta created in: make_probability_infected_vax_novax_ve50_wane5.do
outputs:
analytical_data_ihme_countries_age15_cohort_ve50_wane5.dta
*/

use "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear 

drop prob_syph_vax prob_no_syph_vax

save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_ve50_wane5", replace

////////////////////////////////////////////////////////////////////////////////
//////////////// map on the probability of infected with syphilis //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_ve50_wane5", clear 

merge 1:1 country age year using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_infected_vax_novax_ve50_wane5" 
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

save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_ve50_wane5", replace 

////////////////////////////////////////////////////////////////////////////////
////////////////// compute probability of no syphilis under vax ////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_ve50_wane5", clear 

gen prob_no_syph_vax = 1-prob_syph_vax

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
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_ve50_wane5", replace

////////////////////////////////////////////////////////////////////////////////
//////////////// confirm that all node probabilities sum to one ////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_ve50_wane5" , clear

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
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_ve50_wane5", replace

log close 

exit 

// end 