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

/*
inputs:
Birth probabilities for treated and untreated infected mothers.xlsx
outputs:
probability_abo.dta
*/

capture log close 
log using "$output\DECISION TREE\BASE FILE\make_probability_abo", text replace 

////////////////////////////////////////////////////////////////////////////////
///////////////////// basecase analysis: Gomez et al ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$output\DECISION TREE\BASE FILE\Birth probabilities for treated and untreated infected mothers.xlsx", ///
clear sheet("Table S1 w ns & hl-import") first cellrange(A5:G13) case(lower)

keep c_1 c_2 c_4 c_7
ren c_1 abo 
ren c_2 prob_uninf_
ren c_4 prob_untr_
ren c_7 prob_trtd_

replace abo = strtrim(abo)
drop if abo=="Late symptomatic CS:"
replace abo = "lbw_preterm" if abo=="LBW/preterm" 
replace abo = "neonatal_death" if abo=="Neonatal death" 
replace abo = "stillbirth" if abo=="Stillbirth" 
replace abo = "cong_syph" if abo=="Early symptomatic CS" 
replace abo = "neurosyph" if abo=="Neurosyphilis"
replace abo = "hearloss" if abo=="Unilateral hearing loss"
replace abo = "normal" if abo=="Non-ABO birth"

gen analysis = "basecase"

reshape wide prob_uninf_ prob_untr_ prob_trtd_    , i(analysis) j(abo) string

drop prob_uninf_cong_syph prob_uninf_hearloss prob_uninf_neurosyph

assert prob_uninf_lbw_preterm + prob_uninf_neonatal_death + prob_uninf_stillbirth + prob_uninf_normal ==1
assert prob_untr_lbw_preterm + prob_untr_neonatal_death + prob_untr_stillbirth + prob_untr_cong_syph + prob_untr_neurosyph + prob_untr_hearloss + prob_untr_normal==1
assert prob_trtd_lbw_preterm + prob_trtd_neonatal_death + prob_trtd_stillbirth + prob_trtd_cong_syph + prob_trtd_neurosyph + prob_trtd_hearloss + prob_trtd_normal==1

compress 
save "$output\DECISION TREE\BASE FILE\probability_abo", replace

log close 

exit 

// end