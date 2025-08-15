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
log using  "$output\DECISION TREE\BASE FILE\make_prob_neurosyphilis", text replace

/*
inputs:
late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022.dta created in: make_GBD_2021_congenital_syphilis.do 
syphilis_birth_cases_2009_2022.dta created in: make_syphilis_birth_cases_2009_2022.do 
outputs:
Birth probabilities for treated and untreated infected mothers.xlsx; "prob_untr_neurosyph" tab
*/

////////////////////////////////////////////////////////////////////////////////
//////// get neurosyphilis prevalence for children through age 4 ///////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\IHME\GBD 2021\CS\late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022", clear

drop if unit=="Rate (per 100,000)"
keep if age =="1 to 4"

replace value_prevalence = value_prevalence/4
keep country year value_prevalence 
ren value_prevalence neuro_prevalence

replace year = year-1

merge 1:1 country year using "$output\IHME\GBD 2021\SYPHILIS\syphilis_birth_cases_2009_2022"
assert _m!=1
keep if _m==3 
drop _m 

sort country year 
drop if neuro_prevalence==0

replace year = year+1

gen prob_untr_neurosyph = neuro_prevalence/birth_syphilis_cases

forvalues y = 2019/2022 {
	di "********* The year is `y' *********"
	sum prob_untr_neurosyph if year==`y', d
}

sum prob_untr_neurosyph, d 

gen med_prob_untr_neurosyph = `r(p50)'
keep med_prob_untr_neurosyph 
duplicates drop 
list 

export excel using "$output\DECISION TREE\BASE FILE\Birth probabilities for treated and untreated infected mothers.xlsx", ///
first(var) sheet("prob_untr_neurosyph") sheetreplace 

log close 

exit 

// end