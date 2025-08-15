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
log using  "$output\IHME\GBD 2021\SYPHILIS\make_syphilis_birth_cases_2009_2022", text replace

/*
inputs:
Data Explorer - Data - Syphilis - Incidence - Number in China, North Korea, Taiwan, Cambodia, Indonesia, Lao...  2024-04-04 09-34-42.xlsx
outputs: 
syphilis_birth_cases_2009_2022.dta 
*/

////////////////////////////////////////////////////////////////////////////////
/////// get syphilis cases for children in birth year from 2009-2022 ///////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\IHME\GBD 2021\SYPHILIS\Data Explorer - Data - Syphilis - Incidence - Number in China, North Korea, Taiwan, Cambodia, Indonesia, Lao...  2024-04-04 09-34-42.xlsx", clear first case(lower) 

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite lower upper 

assert measure == "Incidence"
assert age =="Birth"
assert unit == "Number"
ren value birth_syphilis_cases 
drop age measure unit condition 

compress 

save "$output\IHME\GBD 2021\SYPHILIS\syphilis_birth_cases_2009_2022", replace 

log close 

exit 

// end