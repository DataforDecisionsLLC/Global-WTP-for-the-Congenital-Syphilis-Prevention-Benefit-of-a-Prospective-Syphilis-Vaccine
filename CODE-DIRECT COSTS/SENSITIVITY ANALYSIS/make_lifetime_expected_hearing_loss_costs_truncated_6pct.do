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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_lifetime_expected_hearing_loss_costs_truncated_6pct", text replace

gl r .06

/*
inputs:
single_age_hearing_loss_costs_w_life_tables.dta created in: make_lifetime_expected_hearing_loss_costs_truncated.do
outputs:
lifetime_expected_hearing_loss_costs_truncated_6pct.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////////// compute expected lifetime medical costs for hearing loss /////////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated_6pct" 
save          "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated_6pct" , emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\ECONOMIC DATA\DIRECT COSTS\single_age_hearing_loss_costs_w_life_tables", clear 

keep if year==`year'
sort country year age

drop if age > (2080-year)

forvalues x = 0/0 {
	gen L_`x'=L
}

forvalues x = 0/0 {
	replace L_`x'=. if age<`x'
}

forvalues x = 0/0 {
	gen med_cost_`x'=cost_hearing_loss
}

forvalues x = 0/0 {
	replace med_cost_`x'=. if age<`x'
}

forvalues x = 0/0 {
	replace L_`x' = L_`x'*med_cost_`x'
}

forvalues x = 0/0 {
	drop med_cost_`x'
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

drop survivors_l L L_* T_* LE_* cost_hearing_loss
ren LE cost

keep if age==0

compress 

append using "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated_6pct" 
sort country year age 
save         "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated_6pct"  , replace 

end

forvalues y = 2030/2064 {
	le `y'
}

use "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated_6pct" , clear 
assert age==0 
drop age 
gen healthstate="hearing loss"
gen duration="lifetime"
gen incremental="yes"
gen discounted=.03
order country year healthstate cost duration incremental discounted

save "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated_6pct" , replace 

log close 

exit 

// end