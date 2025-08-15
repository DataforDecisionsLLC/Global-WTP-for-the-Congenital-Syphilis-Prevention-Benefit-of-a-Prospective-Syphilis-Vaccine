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
log using "$output\POPULATION\make_population_males_females_denmark", text replace

/*
inputs:
WPP2022_POP_F01_3_POPULATION_SINGLE_AGE_FEMALE.xlsx
WPP2022_POP_F01_2_POPULATION_SINGLE_AGE_MALE.xlsx
outputs:
population_males_females_denmark.dta
*/

////////////////////////////////////////////////////////////////////////////////
//////// get the population of 15 year olds expressed in 1000s /////////////////
////////////////////////////////////////////////////////////////////////////////

////////////////////////////// females /////////////////////////////////////////

import excel using "$raw\WPP\WPP2022_POP_F01_3_POPULATION_SINGLE_AGE_FEMALE.xlsx", ///
clear sheet("import_estimates_all_ages") first case(lower) cellrange(C2:DB710)
drop type 
compress

keep if country=="Denmark"

forvalues a = 0/100 {
	ren age_`a' pop`a'
}

forvalues a = 0/100 {
	replace pop`a' = pop`a'*1000
}

gen sex="female", before(year)

compress 
save "$output\POPULATION\population_males_females_denmark", replace


import excel using "$raw\WPP\WPP2022_POP_F01_3_POPULATION_SINGLE_AGE_FEMALE.xlsx", ///
clear sheet("import_medium_variant_all_ages") first case(lower) cellrange(C2:DB18646)
drop type 
compress

keep if country=="Denmark"

forvalues a = 0/100 {
	ren age_`a' pop`a'
}

forvalues a = 0/100 {
	replace pop`a' = pop`a'*1000
}

gen sex = "female", before(year)

append using  "$output\POPULATION\population_males_females_denmark"
sort country year 
isid country year 

sort country year 
compress 

save  "$output\POPULATION\population_males_females_denmark", replace

//////////////////////////////// males /////////////////////////////////////////

import excel using "$raw\WPP\WPP2022_POP_F01_2_POPULATION_SINGLE_AGE_MALE.xlsx", ///
clear sheet("import_estimates") first case(lower) cellrange(C2:DB710)
drop type 
compress

keep if country=="Denmark"

forvalues a = 0/100 {
	ren age_`a' pop`a'
}

forvalues a = 0/100 {
	replace pop`a' = pop`a'*1000
}

gen sex="male", before(year)

append using  "$output\POPULATION\population_males_females_denmark"
sort country year sex
isid country year sex
compress 

save "$output\POPULATION\population_males_females_denmark", replace


import excel using "$raw\WPP\WPP2022_POP_F01_2_POPULATION_SINGLE_AGE_MALE.xlsx", ///
clear sheet("import_medium_variant") first case(lower) cellrange(C2:DB18646)
drop type 
compress

keep if country=="Denmark"

forvalues a = 0/100 {
	ren age_`a' pop`a'
}

forvalues a = 0/100 {
	replace pop`a' = pop`a'*1000
}

gen sex = "male", before(year)

append using  "$output\POPULATION\population_males_females_denmark"
sort country year sex
isid country year sex

compress 

save  "$output\POPULATION\population_males_females_denmark", replace

log close 

exit 

// end