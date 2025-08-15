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
log using "$output\ECONOMIC DATA\INDIRECT COSTS\make_lifetime_expected_indirect_costs_hearing_loss_truncated_6pct", text replace

gl r .06

/*
inputs:
single_age_indirect_hearing_loss_costs_w_life_tables.dta created in: make_lifetime_expected_indirect_costs_hearing_loss_truncated.do
outputs:
lifetime_expected_productivity_costs_hearing_loss_truncated_6pct.dta 
lifetime_expected_education_costs_hearing_loss_truncated_6pct.dta 
lifetime_expected_indirect_costs_hearing_loss_truncated_6pct.dta 
*/

////////////////////////////////////////////////////////////////////////////////
// compute expected discounted present value of lifetime productivity costs ////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_hearing_loss_truncated_6pct" 
save          "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_hearing_loss_truncated_6pct" , emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\ECONOMIC DATA\INDIRECT COSTS\single_age_indirect_hearing_loss_costs_w_life_tables", clear 
drop cost_edu

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
	gen indirect_cost_`x'=cost_prod
}

forvalues x = 0/0 {
	replace indirect_cost_`x'=. if age<`x'
}

forvalues x = 0/0 {
	replace L_`x' = L_`x'*indirect_cost_`x'
}

forvalues x = 0/0 {
	drop indirect_cost_`x'
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

drop survivors_l L L_* T_* LE_* cost_prod
ren LE prod_cost

keep if age==0

compress 

append using "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_hearing_loss_truncated_6pct" 
sort country year age 
save         "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_hearing_loss_truncated_6pct"    , replace 

end

forvalues y = 2030/2064 {
	le `y'
}

////////////////////////////////////////////////////////////////////////////////
////// compute discounted present value of lifetime education costs ////////////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_education_costs_hearing_loss_truncated_6pct" 
save          "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_education_costs_hearing_loss_truncated_6pct" , emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\ECONOMIC DATA\INDIRECT COSTS\single_age_indirect_hearing_loss_costs_w_life_tables", clear
drop cost_prod

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
	gen indirect_cost_`x'=cost_edu
}

forvalues x = 0/0 {
	replace indirect_cost_`x'=. if age<`x'
}

forvalues x = 0/0 {
	replace L_`x' = L_`x'*indirect_cost_`x'
}

forvalues x = 0/0 {
	drop indirect_cost_`x'
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

drop survivors_l L L_* T_* LE_* cost_edu
ren LE edu_cost

keep if age==0

compress 

append using "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_education_costs_hearing_loss_truncated_6pct"  
sort country year age 
save         "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_education_costs_hearing_loss_truncated_6pct" , replace 

end

forvalues y = 2030/2064 {
	le `y'
}

////////////////////////////////////////////////////////////////////////////////
////////////////// combine productivity and education costs ////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_hearing_loss_truncated_6pct"  , clear
merge 1:1 country year age using "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_education_costs_hearing_loss_truncated_6pct" 
assert _m==3 
drop _m 
sort country year age 

assert age==0 
drop age 
gen healthstate="hearing loss"
gen duration="lifetime"
gen incremental="yes"
gen discounted=.03
order country year healthstate *_cost duration incremental discounted

save "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_indirect_costs_hearing_loss_truncated_6pct" , replace 

log close 

exit 

// end