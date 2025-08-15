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
log using "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\make_ihme_2022_to_2050_all_ages", text replace 

/*
inputs:
Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-12-30.xlsx
Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-21-44.xlsx
Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-23-01.xlsx
Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-24-07.xlsx
Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-25-10.xlsx 
outputs:
ihme_2022_to_2050_all_ages_reference_scenario.dta 
ihme_2022_to_2050_all_ages_safer_environment_scenario.dta 
ihme_2022_to_2050_all_ages_improved_behavioral_scenario.dta 
ihme_2022_to_2050_all_ages_combined_scenario.dta 
ihme_2022_to_2050_all_ages_improved childhood nutrition&vax_scenario.dta 
*/

////////////////////////////////////////////////////////////////////////////////
//////////////////////////// import the raw ihme data //////////////////////////
////////////////////////////////////////////////////////////////////////////////

// 1. reference forecasting scenario
import excel using "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-12-30.xlsx", clear first case(lower)

isid location year age measure unit 
sort location year age measure unit 
compress 

assert inlist(forecastscenario, "Past estimate","Reference")
save "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_reference_scenario", replace

// 2. safer environment forecasting scenario
import excel using "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-21-44.xlsx", clear first case(lower)

isid location year age measure unit 
sort location year age measure unit 
compress 

assert forecastscenario=="Safer environment"
save "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_safer_environment_scenario", replace

// 3. improved behavioral forecasting scenario
import excel using "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-23-01.xlsx", clear first case(lower)

isid location year age measure unit 
sort location year age measure unit 
compress 

assert forecastscenario=="Improved behavioral and metabolic risk factors"
save "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_improved_behavioral_scenario", replace

// 4. combined forecasting scenario
import excel using "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-24-07.xlsx", clear first case(lower)

isid location year age measure unit 
sort location year age measure unit 
compress 

assert forecastscenario=="Combined"
save "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_combined_scenario", replace

// 5. improved childhood nutrition and vaccination forecasting scenario
import excel using "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\Data Explorer - Data - Neonatal preterm birth - Deaths, YLDs, Incidence, Prevalence - Number in China, North...  2024-06-24 15-25-10.xlsx", clear first case(lower)

isid location year age measure unit 
sort location year age measure unit 
compress 

assert forecastscenario=="Improved childhood nutrition and vaccination"
save "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_improved childhood nutrition&vax_scenario", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////// keep only the vars needed ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// 1. reference forecasting scenario

use "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_reference_scenario", clear 

assert sex=="Both"
assert datasuite=="GBD"
drop sex lower upper datasuite

ren location country 
qui tab country 
di "There are `r(r)' countries"

isid  country age year measure unit 
sort  country year age measure unit 
order country year age measure unit value

destring value ,replace

compress 

assert inlist(forecastscenario, "Past estimate","Reference")
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario", replace

// 2. safer environment forecasting scenario

use "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_safer_environment_scenario", clear 

assert sex=="Both"
assert datasuite=="GBD"
drop sex lower upper datasuite

ren location country 
qui tab country 
di "There are `r(r)' countries"

isid  country age year measure unit 
sort  country year age measure unit 
order country year age measure unit value

destring value ,replace

compress 

assert forecastscenario=="Safer environment"
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_safer_environment_scenario", replace

// 3. improved behavioral forecasting scenario

use "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_improved_behavioral_scenario", clear

assert sex=="Both"
assert datasuite=="GBD"
drop sex lower upper datasuite

ren location country 
qui tab country 
di "There are `r(r)' countries"

isid  country age year measure unit 
sort  country year age measure unit 
order country year age measure unit value

destring value ,replace

compress 

assert forecastscenario=="Improved behavioral and metabolic risk factors"
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_improved_behavioral_scenario", replace

// 4. combined forecasting scenario

use "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_combined_scenario", clear

assert sex=="Both"
assert datasuite=="GBD"
drop sex lower upper datasuite

ren location country 
qui tab country 
di "There are `r(r)' countries"

isid  country age year measure unit 
sort  country year age measure unit 
order country year age measure unit value

destring value ,replace

compress 

assert forecastscenario=="Combined"
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_combined_scenario", replace

// 5. improved childhood nutrition and vaccination forecasting scenario

use "$raw\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_improved childhood nutrition&vax_scenario", clear

assert sex=="Both"
assert datasuite=="GBD"
drop sex lower upper datasuite

ren location country 
qui tab country 
di "There are `r(r)' countries"

isid  country age year measure unit 
sort  country year age measure unit 
order country year age measure unit value

destring value ,replace

compress 

assert forecastscenario=="Improved childhood nutrition and vaccination"
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_improved childhood nutrition&vax_scenario", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// collapse daily measures in first year of life ///////////////
////////////////////////////////////////////////////////////////////////////////

// 1. reference forecasting scenario
 
use "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario", clear

keep if inlist(age,"0 to 6 days (early neonatal)","7 to 27 days (late neonatal)","28 to 364 days (post neonatal)")
collapse (sum) value, by(condition country year measure unit forecastscenario)
gen age = "Under 1"

append using "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario"
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
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_reference_scenario", replace

// 2. safer environment forecasting scenario

use "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_safer_environment_scenario", clear

keep if inlist(age,"0 to 6 days (early neonatal)","7 to 27 days (late neonatal)","28 to 364 days (post neonatal)")
collapse (sum) value, by(condition country year measure unit forecastscenario)
gen age = "Under 1"

append using "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_safer_environment_scenario"
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

assert forecastscenario=="Safer environment"
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_safer_environment_scenario", replace

// 3. improved behavioral forecasting scenario

use "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_improved_behavioral_scenario", clear

keep if inlist(age,"0 to 6 days (early neonatal)","7 to 27 days (late neonatal)","28 to 364 days (post neonatal)")
collapse (sum) value, by(condition country year measure unit forecastscenario)
gen age = "Under 1"

append using "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_improved_behavioral_scenario"
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

assert forecastscenario=="Improved behavioral and metabolic risk factors"
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_improved_behavioral_scenario", replace

// 4. combined forecasting scenario

use "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_combined_scenario", clear

keep if inlist(age,"0 to 6 days (early neonatal)","7 to 27 days (late neonatal)","28 to 364 days (post neonatal)")
collapse (sum) value, by(condition country year measure unit forecastscenario)
gen age = "Under 1"

append using "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_combined_scenario"
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

assert forecastscenario=="Combined"
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_combined_scenario", replace

// 5. improved childhood nutrition and vaccination forecasting scenario
 
use "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_improved childhood nutrition&vax_scenario", clear

keep if inlist(age,"0 to 6 days (early neonatal)","7 to 27 days (late neonatal)","28 to 364 days (post neonatal)")
collapse (sum) value, by(condition country year measure unit forecastscenario)
gen age = "Under 1"

append using "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_improved childhood nutrition&vax_scenario"
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

assert forecastscenario=="Improved childhood nutrition and vaccination"
save "$output\IHME\GBD 2021\NEONATAL PRETERM BIRTH\ihme_2022_to_2050_all_ages_improved childhood nutrition&vax_scenario", replace

log close 

exit 

// end