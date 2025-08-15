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
log using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\make_probability_infected_vax_novax_ve50_wane5", text replace

/*
inputs:
GBD_2021_syphilis_incidence_rates_age15_cohort.dta created in: make_probability_infected_vax_novax.do
probability_infected_novax.dta created in: make_probability_infected_vax_novax.do
outputs:
probability_infected_vax_novax_ve50_wane5.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////// compute incidence rates and probability of infection under vax ///////
//////////////// vaccine efficacy: 50% immediately after vax'n /////////////////
//////////////////////////// waning: 5% annual decline /////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_age15_cohort", clear

replace value_rate = value_rate/100000
gen pop=value_number/value_rate

sort country year
by country: egen time=seq(), from(0) to (45)
replace time=time-1 
replace time=. if age==14
order country time
gen rve=0
replace rve=100 if time==0
by country: replace rve=.95*rve[_n-1] if time>0
gen base=.5
gen ve=(rve/100)*base

gen iv=(1-ve)*value_number
replace iv = value_number if age==14

sort country age 
by country: gen pooled_pop = pop + pop[_n-1]
by country: gen pooled_cases = iv + iv[_n-1]
gen pooled_inc = (pooled_cases/pooled_pop)
assert pooled_inc<. if  age>14
gen prob_syph_vax = 1-(exp(-pooled_inc))

drop if age==14
assert prob_syph_vax<. 

qui sum age 
assert `r(min)'==15 
assert `r(max)'==49

qui sum year 
assert `r(min)'==2030
assert `r(max)'==2064

drop value_number value_rate pop pooled_pop pooled_cases ///
rve base ve pooled_inc iv time

drop if inlist(country,"American Samoa","Bermuda","Cook Islands","Greenland","Guam","Northern Mariana Islands","Puerto Rico")
drop if inlist(country,"Tokelau","United States Virgin Islands")

merge 1:1 country age year using "$output\DECISION TREE\BASE FILE\probability_infected_novax"
assert _m==3 
drop _m pooled_inc

sort country year 
isid country year 

gen check = prob_syph_vax/prob_syph_novax

levelsof age, local(age)
foreach a of local age {
	di "The age is `a'"
	sum check if age==`a'
}

drop check

assert prob_syph_vax<. 
assert prob_syph_novax<.

compress 
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_infected_vax_novax_ve50_wane5", replace

log close 

exit 

// end