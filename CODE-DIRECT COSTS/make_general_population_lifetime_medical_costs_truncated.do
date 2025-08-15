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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_general_population_lifetime_medical_costs_truncated", text replace

gl r .03

/*
inputs:
medical_expenditures_percent_GDP.dta created in: make_medical_expenditures_percent_GDP.do
pcgdp_trajectory_birth_cohort.dta created in: make_lifetime_expected_hearing_loss_costs.do 
raw_life_tables.dta created in: make_raw_life_tables.do
outputs:
single_age_general_population_annual_medical_costs_w_life_tables.dta
general_population_lifetime_medical_costs_truncated.dta
*/

////////////////////////////////////////////////////////////////////////////////
//// map medical expenditures as a % of gdp to age-specific pcgdp series ///////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\medical_expenditures_percent_GDP", clear
keep country 
isid country 
count 
 
use "$output\ECONOMIC DATA\DIRECT COSTS\pcgdp_trajectory_birth_cohort.dta", clear 
keep country 
duplicates drop 
count 

use "$output\ECONOMIC DATA\DIRECT COSTS\medical_expenditures_percent_GDP", clear
merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\pcgdp_trajectory_birth_cohort.dta"

assert inlist(country, "Cuba","Monaco","Syria","Venezuela") if _m==1 
keep if _m==3 
drop _m 
sort country birth_year age 

gen gen_pop_medical_exp=pctgdp*pcgdp
assert has_pct_gdp<. 

keep  country birth_year year age gen_pop_medical_exp 
order country birth_year year age gen_pop_medical_exp 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\general_population_annual_medical_costs_per_capita_single_ages", replace 

////////////////////////////////////////////////////////////////////////////////
////////////////// map single age medical expenses to life tables //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\LIFE TABLES\raw_life_tables", clear 
keep country year age L survivors_l
drop if year>2064 
drop if year<2030
drop if age>99
ren year birth_year 

merge 1:1 country birth_year age using "$output\ECONOMIC DATA\DIRECT COSTS\general_population_annual_medical_costs_per_capita_single_ages"
assert inlist(country, "Cuba","Monaco","North Korea","Syria","Venezuela") if _m==1 

keep if _m==3 
drop _m year 

ren birth_year year 
sort country  year age 
order country year age gen_pop_medical_exp L survivors_l

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\single_age_general_population_annual_medical_costs_w_life_tables", replace

////////////////////////////////////////////////////////////////////////////////
// compute expected lifetime medical costs in general population for newborns //
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated" 
save          "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated" , emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\ECONOMIC DATA\DIRECT COSTS\single_age_general_population_annual_medical_costs_w_life_tables", clear 

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
	gen med_cost_`x'=gen_pop_medical_exp
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

drop survivors_l L L_* T_* LE_* gen_pop_medical_exp
ren LE cost

compress 

keep if age==0

compress 

append using "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated" 
sort country year age 
save         "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated"   , replace 

end

forvalues y = 2030/2064 {
	le `y'
}

use "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated"  , clear 
assert age==0 
drop age 
gen healthstate="non-ABO"
gen duration="lifetime"
gen incremental="no"
gen discounted=.03
order country year healthstate cost duration incremental discounted

save "$output\ECONOMIC DATA\DIRECT COSTS\general_population_lifetime_medical_costs_truncated" , replace 

log close 

exit 

// end