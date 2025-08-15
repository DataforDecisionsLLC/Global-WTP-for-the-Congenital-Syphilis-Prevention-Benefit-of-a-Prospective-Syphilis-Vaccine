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
log using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\make_probability_infected_vax_novax_age25_cohort", text replace

/*
inputs:
GBD_2021_syphilis_incidence_rates_single_age.dta created in: make_probability_infected_vax_novax.do
outputs:
probability_infected_vax_novax_age25_cohort.dta
*/

////////////////////////////////////////////////////////////////////////////////
////// keep the age-year pairs for the cohort aged 25 cohort in year 2030 //////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_single_age", clear

// distribute the number of cases equally across all five single ages in an age group 

replace value_number = value_number/5

sort country year age 
gen age_year = strofreal(age) + "_" + strofreal(year)
order country age year age_year

gen keepme=0 
replace keepme=1 if inlist(age_year, ///
"24_2029",  ///
"25_2030",  ///
"26_2031",  ///
"27_2032",  ///
"28_2033",  ///
"29_2034",  ///
"30_2035",  ///
"31_2036",  ///
"32_2037")  ///

replace keepme=1 if inlist(age_year, ///
"33_2038",  ///
"34_2039",  ///
"35_2040",  ///
"36_2041",  ///
"37_2042",  ///
"38_2043",  ///
"39_2044",  ///
"40_2045",  ///
"41_2046")  ///

replace keepme=1 if inlist(age_year, ///
"42_2047",  ///
"43_2048",  ///
"44_2049",  ///
"45_2050")  ///

replace keepme=1 if year==2050 & age>45 & age<=49

keep if keepme==1 
drop keepme age_year
sort country age 
by country: replace year = year[_n-1] + 1 if year==2050 & age>45

isid country year
sort country year 

qui sum age 
assert `r(min)'==24 
assert `r(max)'==49

qui sum year 
assert `r(min)'==2029
assert `r(max)'==2054

compress 
save "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_age25_cohort", replace

////////////////////////////////////////////////////////////////////////////////
////// compute incidence rates and probability of infection under no vax ///////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_age25_cohort", clear

replace value_rate = value_rate/100000
gen pop=value_number/value_rate

sort country age 
by country: gen pooled_pop = pop + pop[_n-1]
by country: gen pooled_cases = value_number + value_number[_n-1]
gen pooled_inc = (pooled_cases/pooled_pop)
assert pooled_inc<. if age>24
gen prob_syph_novax = 1-(exp(-pooled_inc))

drop if age==24

qui sum age 
assert `r(min)'==25 
assert `r(max)'==49

qui sum year 
assert `r(min)'==2030
assert `r(max)'==2054

drop value_number value_rate pop pooled_pop pooled_cases

drop if inlist(country,"American Samoa","Bermuda","Cook Islands","Greenland","Guam","Northern Mariana Islands","Puerto Rico")
drop if inlist(country,"Tokelau","United States Virgin Islands")

compress 
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_infected_novax_age25_cohort", replace

////////////////////////////////////////////////////////////////////////////////
///////// compute incidence rates and probability of infection under vax ///////
//////////////// vaccine efficacy: 80% immediately after vax'n /////////////////
//////////////////////////// waning: 5% annual decline /////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\GBD 2021\SYPHILIS\GBD_2021_syphilis_incidence_rates_age25_cohort", clear

replace value_rate = value_rate/100000
gen pop=value_number/value_rate

sort country year
by country: egen time=seq(), from(0) to (45)
replace time=time-1 
replace time=. if age==24
order country time
gen rve=0
replace rve=100 if time==0
by country: replace rve=.95*rve[_n-1] if time>0
gen base=.8
gen ve=(rve/100)*base

gen iv=(1-ve)*value_number
replace iv = value_number if age==24

sort country age 
by country: gen pooled_pop = pop + pop[_n-1]
by country: gen pooled_cases = iv + iv[_n-1]
gen pooled_inc = (pooled_cases/pooled_pop)
assert pooled_inc<. if age>24
gen prob_syph_vax = 1-(exp(-pooled_inc))

drop if age==24
assert prob_syph_vax<. 

qui sum age 
assert `r(min)'==25 
assert `r(max)'==49

qui sum year 
assert `r(min)'==2030
assert `r(max)'==2054

drop value_number value_rate pop pooled_pop pooled_cases ///
rve base ve pooled_inc iv time

drop if inlist(country,"American Samoa","Bermuda","Cook Islands","Greenland","Guam","Northern Mariana Islands","Puerto Rico")
drop if inlist(country,"Tokelau","United States Virgin Islands")

merge 1:1 country age year using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_infected_novax_age25_cohort"
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
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\probability_infected_vax_novax_age25_cohort", replace

log close 

exit 

// end