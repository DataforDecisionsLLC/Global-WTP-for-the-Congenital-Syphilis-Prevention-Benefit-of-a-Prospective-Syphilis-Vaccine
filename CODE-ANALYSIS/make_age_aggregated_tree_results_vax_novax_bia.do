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

/*
inputs:
tree_results_novax_bia.dta created in: make_tree_results_novax_bia.do
tree_results_vax_bia.dta created in: make_tree_results_vax_bia.do
raw_life_tables_females.dta created in: make_raw_life_tables_females.do 
wpp_single_age_population_females_15_49.dta created in: make_wpp_single_age_population_females_15_49.do
who_regions_income_groups.dta created in: make_who_regions_income_groups.do
outputs:
aggregated_tree_results_vax_novax_bia.dta 
*/

capture log close 
log using "$output\ANALYSIS\BIA\make_age_aggregated_tree_results_vax_novax_bia", text replace

gl r .03

////////////////////////////////////////////////////////////////////////////////
/////////////////// combine the vax vs novax tree results //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\tree_results_novax_bia", clear
sort country age
 
foreach x in cost daly {
	ren my_`x' `x'_novax
}

merge 1:1 country age year using "$output\\DECISION TREE\TREE RESULTS\tree_results_vax_bia"
assert _m==3 
drop _m 
sort country age 

foreach x in cost daly {
	ren my_`x' `x'_vax
}

replace year = 2030

save "$output\DECISION TREE\TREE RESULTS\tree_results_vax_novax_bia", replace 

////////////////////////////////////////////////////////////////////////////////
///////////////// map single-age costs and dalys to lifetables /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\LIFE TABLES\raw_life_tables_females", clear 
keep country year age L survivors_l
keep if year==2030
merge 1:1 country year age using  "$output\DECISION TREE\TREE RESULTS\tree_results_vax_novax_bia"
assert _m!=2
keep if _m==3 
drop _m 
sort country year age 
assert year==2030
compress 
save "$output\DECISION TREE\TREE RESULTS\tree_results_vax_novax_w_life_tables_bia", replace 

////////////////////////////////////////////////////////////////////////////////
///////////// compute discounted expected lifetime novax costs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\tree_results_vax_novax_w_life_tables_bia", clear
drop daly_* cost_vax

sort country year age

forvalues x = 15/15 {
	gen L_`x'=L
}

forvalues x = 15/15 {
	replace L_`x'=. if age<`x'
}

forvalues x = 15/15 {
	gen cost_novax_`x'=cost_novax
}

forvalues x = 15/15 {
	replace cost_novax_`x'=. if age<`x'
}

forvalues x = 15/15 {
	replace L_`x' = L_`x'*cost_novax_`x'
}

forvalues x = 15/15 {
	drop cost_novax_`x'
}

forvalues x = 15/15 {
	replace L_`x'= L_`x'/((1 + $r)^(age-`x'))
}

forvalues x = 15/15 {
	by country: egen T_`x' = total(L_`x')
}

forvalues x = 15/15 {
	gen LE_`x' = .
}

forvalues x = 15/15 {
	replace LE_`x' = T_`x'/survivors_l if age==`x'
}

gen LE=., before(survivors_l)

forvalues x = 15/15 {
	replace LE=LE_`x' if age==`x'
}

drop survivors_l L L_* T_* LE_* cost_novax
ren LE cost_novax

keep if age==15

sort country year age 
compress 

save "$output\DECISION TREE\TREE RESULTS\tree_results_cost_novax_collapsed_bia", replace 

////////////////////////////////////////////////////////////////////////////////
/////////////// compute discounted expected lifetime vax costs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\tree_results_vax_novax_w_life_tables_bia", clear
drop cost_novax daly_*

sort country year age

forvalues x = 15/15 {
	gen L_`x'=L
}

forvalues x = 15/15 {
	replace L_`x'=. if age<`x'
}

forvalues x = 15/15 {
	gen cost_vax_`x'=cost_vax
}

forvalues x = 15/15 {
	replace cost_vax_`x'=. if age<`x'
}

forvalues x = 15/15 {
	replace L_`x' = L_`x'*cost_vax_`x'
}

forvalues x = 15/15 {
	drop cost_vax_`x'
}

forvalues x = 15/15 {
	replace L_`x'= L_`x'/((1 + $r)^(age-`x'))
}

forvalues x = 15/15 {
	by country: egen T_`x' = total(L_`x')
}

forvalues x = 15/15 {
	gen LE_`x' = .
}

forvalues x = 15/15 {
	replace LE_`x' = T_`x'/survivors_l if age==`x'
}

gen LE=., before(survivors_l)

forvalues x = 15/15 {
	replace LE=LE_`x' if age==`x'
}

drop survivors_l L L_* T_* LE_* cost_vax
ren LE cost_vax

keep if age==15

sort country year age 
compress 

save "$output\DECISION TREE\TREE RESULTS\tree_results_cost_vax_collapsed_bia", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// combine the collapsed files; compute d_cost ///////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\tree_results_cost_novax_collapsed_bia", clear
merge 1:1 country year age using "$output\DECISION TREE\TREE RESULTS\tree_results_cost_vax_collapsed_bia"
assert _m==3 
drop _m 

gen d_cost = cost_novax - cost_vax
sum d_cost, d 

isid country 
sort country 

compress 
save "$output\ANALYSIS\BIA\age_aggregated_tree_results_vax_novax_bia", replace 

////////////////////////////////////////////////////////////////////////////////
/////////////// map on the population age 15 year olds in 2030 /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BIA\age_aggregated_tree_results_vax_novax_bia", clear 
assert year==2030

merge 1:1 country year using "$output\POPULATION\wpp_single_age_population_females_15_49", ///
keepusing(country year pop15)
assert _m!=1 
keep if _m==3 
drop _m 
sort country 

compress 
save "$output\ANALYSIS\BIA\age_aggregated_tree_results_vax_novax_bia", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////////// map on the income group //////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\GEO DATA\who_regions_income_groups", clear 
keep country income_group_1
duplicates drop 

merge 1:1 country using "$output\ANALYSIS\BIA\age_aggregated_tree_results_vax_novax_bia"
assert _m!= 2
keep if _m==3 
drop _m 
sort country

assert income_group_1 !="" 

assert year == 2030 
assert age==15 
drop year age 

ren d_cost d_cost_bia

save "$output\ANALYSIS\BIA\age_aggregated_tree_results_vax_novax_bia", replace

log close 

exit 

// end