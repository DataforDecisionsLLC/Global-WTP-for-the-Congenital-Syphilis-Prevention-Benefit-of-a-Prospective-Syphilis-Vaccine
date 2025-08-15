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
probability_abo_sensitivity_analysis.dta
*/

capture log close 
log using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\make_probability_abo_sensitivity_analysis", text replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// get data for infected & untreated mothers /////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$output\DECISION TREE\BASE FILE\Birth probabilities for treated and untreated infected mothers.xlsx", ///
clear sheet("Table S3 w ns & hl-import") first cellrange(C5:G16) case(lower)

keep c_3 c_7
ren c_3 abo 
ren c_7 prob_untr_

replace abo = strtrim(abo)
drop if abo==""
assert prob_untr_<. 
assert _N==7

replace abo = "lbw_preterm" if abo=="LBW/preterm" 
replace abo = "neonatal_death" if abo=="Neonatal deaths" 
replace abo = "stillbirth" if abo=="Stillbirth" 
replace abo = "cong_syph" if abo=="CS" 
replace abo = "neurosyph" if abo=="Neurosyphilis"
replace abo = "hearloss" if abo=="Hearing loss"
replace abo = "normal" if abo=="Non-ABO birth"

gen analysis = "sensitivity"
order analysis

compress 
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_abo_sensitivity_analysis", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// get data for infected & treated mothers /////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$output\DECISION TREE\BASE FILE\Birth probabilities for treated and untreated infected mothers.xlsx", ///
clear sheet("Table S3 w ns & hl-import") first cellrange(C18:G29) case(lower)

keep c_3 c_7
ren c_3 abo 
ren c_7 prob_trtd_

replace abo = strtrim(abo)
drop if abo==""

assert prob_trtd_<. 
assert _N==7

replace abo = "lbw_preterm" if abo=="LBW/preterm" 
replace abo = "neonatal_death" if abo=="Neonatal deaths" 
replace abo = "stillbirth" if abo=="Stillbirth" 
replace abo = "cong_syph" if abo=="CS" 
replace abo = "neurosyph" if abo=="Neurosyphilis"
replace abo = "hearloss" if abo=="Hearing loss"
replace abo = "normal" if abo=="Non-ABO birth"

gen analysis = "sensitivity"
order analysis
merge 1:1 analysis abo using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_abo_sensitivity_analysis"
assert _m==3 
drop _m 

compress 
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_abo_sensitivity_analysis", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////// get data for uninfected mothers /////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$output\DECISION TREE\BASE FILE\Birth probabilities for treated and untreated infected mothers.xlsx", ///
clear sheet("Table S3 w ns & hl-import") first cellrange(C31:F42) case(lower)

keep c_3 c_6
ren c_3 abo 
ren c_6 prob_uninf_

replace abo = strtrim(abo)
drop if abo==""

assert prob_uninf_<. 
assert _N==4

replace abo = "lbw_preterm" if abo=="LBW/preterm" 
replace abo = "neonatal_death" if abo=="Neonatal deaths" 
replace abo = "stillbirth" if abo=="Stillbirth" 
replace abo = "normal" if abo=="Non-ABO birth"

gen analysis = "sensitivity"
order analysis
merge 1:1 analysis abo using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_abo_sensitivity_analysis"
assert _m!=1
assert inlist(abo,"cong_syph","hearloss","neurosyph") if _m==2
drop _m 

reshape wide prob_uninf_ prob_untr_ prob_trtd_    , i(analysis) j(abo) string

drop prob_uninf_cong_syph prob_uninf_hearloss prob_uninf_neurosyph

assert prob_uninf_lbw_preterm + prob_uninf_neonatal_death + prob_uninf_stillbirth + prob_uninf_normal ==1
assert prob_untr_lbw_preterm + prob_untr_neonatal_death + prob_untr_stillbirth + prob_untr_cong_syph + prob_untr_neurosyph + prob_untr_hearloss + prob_untr_normal==1
assert prob_trtd_lbw_preterm + prob_trtd_neonatal_death + prob_trtd_stillbirth + prob_trtd_cong_syph + prob_trtd_neurosyph + prob_trtd_hearloss + prob_trtd_normal==1

compress 
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_abo_sensitivity_analysis", replace

log close 

exit 

// end