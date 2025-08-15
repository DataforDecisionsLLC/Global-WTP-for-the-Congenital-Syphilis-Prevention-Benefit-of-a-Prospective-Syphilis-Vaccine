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

gl r .06
gl analysis 6pct 

capture log close
log using "$output\DALY\make_dalys_sb_nd_discounted_$analysis", text replace

/*
inputs: 
raw_life_tables.dta created in: make_raw_life_tables.do
outputs:
dalys_sb_nd_discounted_6pct.dta 
*/

////////////////////////////////////////////////////////////////////////////////
//////////////////// compute the discounted life expectancy ////////////////////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\DALY\LE_$analysis" 
save          "$output\DALY\LE_$analysis", emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\LIFE TABLES\raw_life_tables", clear 

keep if year==`year'
keep country year age survivors_l L
sort country year age

drop if age > (2080-year)

forvalues x = 0/0 {
	gen L_`x'=L
}

forvalues x = 0/0 {
	replace L_`x'=. if age<`x'
}

forvalues x = 0/0 {
	replace L_`x'= L_`x'/((1 + $r)^(age-`x'))
}

forvalues x = 0/0 {
	by country year: egen T_`x' = total(L_`x')
}

forvalues x = 0/0 {
	gen LE_`x' = .
}

forvalues x = 0/0 {
	replace LE_`x' = T_`x'/survivors_l if age==`x'
}

gen LE=., before(survivors_l)

forvalues x = 0/0 {
	replace LE=LE_`x' if age==`x'
}

drop survivors_l L L_* T_* LE_*

keep if age==0 
ren LE le_$analysis

compress 

append using "$output\DALY\LE_$analysis" 
sort country year age 
save         "$output\DALY\LE_$analysis", replace 

end

forvalues y = 2030/2064 {
	le `y'
}

////////////////////////////////////////////////////////////////////////////////
//// compute the life expectancy for neonatal death by subtracting 28/365.25 ///
//////////////////////// from the full life expecntancy ////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\LE_$analysis", clear
gen neonatal_dalys = le_$analysis - (28/365.25)
ren le_$analysis stillbirth_dalys

assert age==0 
drop age

save "$output\DALY\dalys_sb_nd_discounted_$analysis", replace 

log close 
exit 

// end