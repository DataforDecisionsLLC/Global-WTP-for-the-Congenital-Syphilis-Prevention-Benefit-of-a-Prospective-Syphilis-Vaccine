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
log using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\make_analytical_data_ihme_countries_age15_cohort_indirect_costs_minus_20_pct", text replace 

gl analysis discounted 

/*
inputs:
analytical_data_ihme_countries_age15_cohort_truncated.dta created in: make_analytical_data_ihme_countries_age15_cohort_truncated.do
acute_costs_series.dta created in: make_acute_costs_series.do 
post_acute_costs_series_truncated.dta created in: make_post_acute_costs_series_truncated.do
indirect_costs_cerebral_palsy.dta created in: make_indirect_costs_cerebral_palsy.do 
lifetime_expected_productivity_costs_hearing_loss_truncated.dta created in: make_lifetime_expected_indirect_costs_hearing_loss_truncated.do 
outputs:
analytical_data_ihme_countries_age15_cohort_indirect_costs_minus_20_pct.dta
*/

use  "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear 
drop cost_lbwpt cost_nd cost_nonABO cost_stillbirth cost_cs cost_neurosyph cost_hearingloss
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_indirect_costs_minus_20_pct", replace

////////////////////////////////////////////////////////////////////////////////
// map on costs: acute direct, post acute direct, and indirect for ns and hl ///
///////////////////// decrease indirect costs by 20% ///////////////////////////
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

foreach var in indirect_costs_neurosyph indirect_costs_hearingloss {
	replace `var' = `var'*.8
}

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

merge 1:m country year using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_indirect_costs_minus_20_pct"
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
// 189

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
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_indirect_costs_minus_20_pct", replace

log close 

exit 

// end 