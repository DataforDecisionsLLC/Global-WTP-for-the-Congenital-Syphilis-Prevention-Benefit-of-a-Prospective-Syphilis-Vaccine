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
log using "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\make_ihme_2022_to_2050_all_ages_upper_lower", text replace 

/*
inputs:
ihme_2022_to_2050_all_ages_reference_scenario.dta created in: make_ihme_2022_to_2050_all_ages.do 
outputs:
ihme_2022_to_2050_all_ages_reference_scenario_upper.dta 
ihme_2022_to_2050_all_ages_reference_scenario_lower.dta 
*/

////////////////////////////////////////////////////////////////////////////////
////////////////////// keep only the vars needed ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/////////////////////////// lower bound estimates //////////////////////////////

use "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_reference_scenario", clear 

assert sex=="Both"
assert datasuite=="GBD"
drop sex value upper datasuite

ren lower value
ren location country 
qui tab country 
di "There are `r(r)' countries"

isid  country age year measure unit 
sort  country year age measure unit 
order country year age measure unit value

destring value ,replace

compress 

assert inlist(forecastscenario, "Past estimate","Reference")
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario_lower", replace

/////////////////////////// upper bound estimates //////////////////////////////

use "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_reference_scenario", clear 

assert sex=="Both"
assert datasuite=="GBD"
drop sex value lower datasuite

ren upper value
ren location country 
qui tab country 
di "There are `r(r)' countries"

isid  country age year measure unit 
sort  country year age measure unit 
order country year age measure unit value

destring value ,replace

compress 

assert inlist(forecastscenario, "Past estimate","Reference")
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario_upper", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// collapse daily measures in first year of life ///////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////// lower bound estimates ///////////////////////////////
 
use "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario_lower", clear

keep if inlist(age,"0 to 6 days (early neonatal)","7 to 27 days (late neonatal)","28 to 364 days (post neonatal)")
collapse (sum) value, by(condition country year measure unit forecastscenario)
gen age = "Under 1"

append using "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario_lower"
drop if inlist(age,"0 to 6 days (early neonatal)","7 to 27 days (late neonatal)","28 to 364 days (post neonatal)")

gen sortme=. 
replace sortme=1 if age=="Under 1"
replace sortme=2 if age=="1 to 4"
replace sortme=3 if age=="5 to 9"
replace sortme=4 if age=="10 to 14"
replace sortme=5 if age=="15 to 19"
replace sortme=6 if age=="20 to 24"
replace sortme=7 if age=="25 to 29"
replace sortme=8 if age=="30 to 34"
replace sortme=9 if age=="35 to 39"
replace sortme=10 if age=="40 to 44"
replace sortme=11 if age=="45 to 49"
replace sortme=12 if age=="50 to 54"
replace sortme=13 if age=="55 to 59"
replace sortme=14 if age=="60 to 64"
replace sortme=15 if age=="65 to 69"
replace sortme=16 if age=="70 to 74"
replace sortme=17 if age=="75 to 79"
replace sortme=18 if age=="80 to 84"
replace sortme=19 if age=="85 to 89"
replace sortme=20 if age=="90 to 94"
replace sortme=21 if age=="95 and above"
assert sortme<.
sort country year sortme measure unit

compress 

assert inlist(forecastscenario, "Past estimate","Reference")
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario_lower", replace

////////////////////////// upper bound estimates ///////////////////////////////
 
use "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario_upper", clear

keep if inlist(age,"0 to 6 days (early neonatal)","7 to 27 days (late neonatal)","28 to 364 days (post neonatal)")
collapse (sum) value, by(condition country year measure unit forecastscenario)
gen age = "Under 1"

append using "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario_upper"
drop if inlist(age,"0 to 6 days (early neonatal)","7 to 27 days (late neonatal)","28 to 364 days (post neonatal)")

gen sortme=. 
replace sortme=1 if age=="Under 1"
replace sortme=2 if age=="1 to 4"
replace sortme=3 if age=="5 to 9"
replace sortme=4 if age=="10 to 14"
replace sortme=5 if age=="15 to 19"
replace sortme=6 if age=="20 to 24"
replace sortme=7 if age=="25 to 29"
replace sortme=8 if age=="30 to 34"
replace sortme=9 if age=="35 to 39"
replace sortme=10 if age=="40 to 44"
replace sortme=11 if age=="45 to 49"
replace sortme=12 if age=="50 to 54"
replace sortme=13 if age=="55 to 59"
replace sortme=14 if age=="60 to 64"
replace sortme=15 if age=="65 to 69"
replace sortme=16 if age=="70 to 74"
replace sortme=17 if age=="75 to 79"
replace sortme=18 if age=="80 to 84"
replace sortme=19 if age=="85 to 89"
replace sortme=20 if age=="90 to 94"
replace sortme=21 if age=="95 and above"
assert sortme<.
sort country year sortme measure unit

compress 

assert inlist(forecastscenario, "Past estimate","Reference")
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario_upper", replace


log close 

exit 

// end