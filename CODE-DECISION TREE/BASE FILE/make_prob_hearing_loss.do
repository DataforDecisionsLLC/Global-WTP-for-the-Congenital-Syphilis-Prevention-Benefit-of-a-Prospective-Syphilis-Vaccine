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
log using  "$output\DECISION TREE\BASE FILE\make_prob_hearing_loss", text replace

/*
inputs:
late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022.dta created in: make_GBD_2021_congenital_syphilis.do
syphilis_birth_cases_2009_2022.dta created in: make_syphilis_birth_cases_2009_2022.do 
outputs: 
Birth probabilities for treated and untreated infected mothers.xlsx; "prob_untr_hearing_loss" tab
*/

////////////////////////////////////////////////////////////////////////////////
/////////////// map hearing loss prevalence for children aged 10 ///////////////
//////////////// to syphilis birth cases 10 years earlier //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\GBD 2021\CS\late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022", clear 

drop if unit=="Rate (per 100,000)"
keep if age =="10 to 14"

drop value_ylds condition unit age  

replace value_prevalence = value_prevalence/5
keep country year value_prevalence 
ren value_prevalence hl_prevalence
replace year = year-10

merge 1:1 country year using "$output\IHME\GBD 2021\SYPHILIS\syphilis_birth_cases_2009_2022"
assert _m!=1
keep if _m==3 
drop _m 

drop if hl_prevalence==.

replace year = year+10

sort country year 

gen prob_hearing_loss = hl_prevalence/birth_syphilis_cases

forvalues y = 2019/2022 {
	di "********* The year is `y' *********"
	sum prob_hearing_loss if year==`y', d
}

sum prob_hearing_loss, d

gen med_prob_untr_hearing_loss = `r(p50)'
keep med_prob_untr_hearing_loss
duplicates drop 
list 

export excel using "$output\DECISION TREE\BASE FILE\Birth probabilities for treated and untreated infected mothers.xlsx", ///
first(var) sheet("prob_untr_hearing_loss") sheetreplace 

log close 

exit 

// end