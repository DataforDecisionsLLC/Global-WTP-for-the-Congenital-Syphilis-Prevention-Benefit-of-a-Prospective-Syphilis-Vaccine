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
tree_results_novax_`sa'.dta created in: make_tree_results_novax_`sa'.do
tree_results_vax_`sa'.dta created in: make_tree_results_vax_`sa'.do
raw_life_tables_females.dta created in: make_raw_life_tables_females.do 
pcgdp_series.dta created in: make_pcgdp_series.do
wpp_single_age_population_females_15_49.dta created in: make_wpp_single_age_population_females_15_49.do 
who_regions_income_groups.dta created in: make_who_regions_income_groups.do
outputs:
age_aggregated_tree_results_vax_novax_`sa'.dta
*/

capture program drop tree_results
program tree_results
version 18.0
set more off
set type double 
args sa r_cost r_daly k

capture log close 
log using "$output\ANALYSIS\SENSITIVITY ANALYSIS\make_age_aggregated_tree_results_vax_novax_`sa'", text replace

////////////////////////////////////////////////////////////////////////////////
/////////////////// combine the vax vs novax tree results //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_novax_`sa'", clear
sort country age
 
foreach x in cost daly {
	ren my_`x' `x'_novax
}

merge 1:1 country age year using "$output\\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_vax_`sa'"
assert _m==3 
drop _m 
sort country age 

foreach x in cost daly {
	ren my_`x' `x'_vax
}

replace year = 2030

save "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_vax_novax_`sa'", replace 

////////////////////////////////////////////////////////////////////////////////
///////////////// map single-age costs and dalys to lifetables /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\LIFE TABLES\raw_life_tables_females", clear 
keep country year age L survivors_l
keep if year==2030
merge 1:1 country year age using  "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_vax_novax_`sa'"
assert _m!=2
keep if _m==3 
drop _m 
sort country year age 
assert year==2030
compress 

save "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_vax_novax_`sa'_w_life_tables", replace 

////////////////////////////////////////////////////////////////////////////////
///////////// compute discounted expected lifetime novax costs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_vax_novax_`sa'_w_life_tables", clear
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
	replace L_`x'= L_`x'/((1 + `r_cost')^(age-`x'))
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

save "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_cost_novax_collapsed_`sa'", replace 

////////////////////////////////////////////////////////////////////////////////
/////////////// compute discounted expected lifetime vax costs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_vax_novax_`sa'_w_life_tables", clear
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
	replace L_`x'= L_`x'/((1 + `r_cost')^(age-`x'))
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

save "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_cost_vax_collapsed_`sa'", replace 

////////////////////////////////////////////////////////////////////////////////
///////////// compute discounted expected lifetime novax dalys /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_vax_novax_`sa'_w_life_tables", clear
drop cost_* daly_vax

sort country year age

forvalues x = 15/15 {
	gen L_`x'=L
}

forvalues x = 15/15 {
	replace L_`x'=. if age<`x'
}

forvalues x = 15/15 {
	gen daly_novax_`x'=daly_novax
}

forvalues x = 15/15 {
	replace daly_novax_`x'=. if age<`x'
}

forvalues x = 15/15 {
	replace L_`x' = L_`x'*daly_novax_`x'
}

forvalues x = 15/15 {
	drop daly_novax_`x'
}

forvalues x = 15/15 {
	replace L_`x'= L_`x'/((1 + `r_daly')^(age-`x'))
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

drop survivors_l L L_* T_* LE_* daly_novax
ren LE daly_novax

keep if age==15

sort country year age 
compress 

save "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_daly_novax_collapsed_`sa'", replace 

////////////////////////////////////////////////////////////////////////////////
///////////// compute discounted expected lifetime vax dalys ///////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_vax_novax_`sa'_w_life_tables", clear
drop cost_* daly_novax

sort country year age

forvalues x = 15/15 {
	gen L_`x'=L
}

forvalues x = 15/15 {
	replace L_`x'=. if age<`x'
}

forvalues x = 15/15 {
	gen daly_vax_`x'=daly_vax
}

forvalues x = 15/15 {
	replace daly_vax_`x'=. if age<`x'
}

forvalues x = 15/15 {
	replace L_`x' = L_`x'*daly_vax_`x'
}

forvalues x = 15/15 {
	drop daly_vax_`x'
}

forvalues x = 15/15 {
	replace L_`x'= L_`x'/((1 + `r_daly')^(age-`x'))
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

drop survivors_l L L_* T_* LE_* daly_vax
ren LE daly_vax

keep if age==15

sort country year age 
compress 

save "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_daly_vax_collapsed_`sa'", replace 

////////////////////////////////////////////////////////////////////////////////
//////// combine the collapsed files; compute d_cost and d_daly ////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_cost_novax_collapsed_`sa'", clear
merge 1:1 country year age using "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_cost_vax_collapsed_`sa'"
assert _m==3 
drop _m 
merge 1:1 country year age using "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_daly_novax_collapsed_`sa'"
assert _m==3 
drop _m 
merge 1:1 country year age using "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_daly_vax_collapsed_`sa'"
assert _m==3 
drop _m 

foreach x in cost daly {
	gen d_`x' = `x'_novax - `x'_vax
}

isid country 
sort country 

compress 
save "$output\ANALYSIS\SENSITIVITY ANALYSIS\age_aggregated_tree_results_vax_novax_`sa'", replace 

////////////////////////////////////////////////////////////////////////////////
////////// map on 2030 pcgdp; compute wtp and wtp as a % of pcgdp //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\SENSITIVITY ANALYSIS\age_aggregated_tree_results_vax_novax_`sa'", clear 

assert year == 2030 
merge 1:1 country year using "$output\ECONOMIC DATA\pcgdp_series", keepusing(country year pcgdp)
assert _m!=1 
assert year!=2030 if _m==2 
keep if _m==3 
drop _m 
sort country 

gen wtp = (`k'*pcgdp*d_daly) + d_cost

sum wtp, d


gen pct_pcgdp = wtp/pcgdp

sum pct_pcgdp, d 

order country d_cost d_daly pcgdp wtp pct_pcgdp

compress 
save "$output\ANALYSIS\SENSITIVITY ANALYSIS\age_aggregated_tree_results_vax_novax_`sa'", replace 

////////////////////////////////////////////////////////////////////////////////
/////////////// map on the population age 15 year olds in 2030 /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\SENSITIVITY ANALYSIS\age_aggregated_tree_results_vax_novax_`sa'", clear 
assert year==2030

merge 1:1 country year using "$output\POPULATION\wpp_single_age_population_females_15_49", ///
keepusing(country year pop15)
assert _m!=1 

keep if _m==3 
drop _m 
sort country 

compress 
save "$output\ANALYSIS\SENSITIVITY ANALYSIS\age_aggregated_tree_results_vax_novax_`sa'", replace 

////////////////////////////////////////////////////////////////////////////////
///////////////////////// map on the income group //////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\GEO DATA\who_regions_income_groups", clear 
keep country income_group_1
duplicates drop 

merge 1:1 country using "$output\ANALYSIS\SENSITIVITY ANALYSIS\age_aggregated_tree_results_vax_novax_`sa'"
assert _m!= 2
keep if _m==3 
drop _m 
sort country

assert income_group_1 !="" 

assert year == 2030 
assert age==15 
drop year age 

save "$output\ANALYSIS\SENSITIVITY ANALYSIS\age_aggregated_tree_results_vax_novax_`sa'", replace 

log close 

end 

// sa, r_cost, r_daly, k

tree_results govt_costs .03 .03 .6
tree_results 0pct_health_0pct_costs 0 0 1
tree_results 0pct_health_3pct_costs .03 0 1
tree_results 6pct_health_6pct_costs .06 .06 1
tree_results direct_costs_minus_20_pct .03 .03 1
tree_results direct_costs_plus_20_pct .03 .03 1
tree_results fertility_high .03 .03 1
tree_results fertility_low .03 .03 1
tree_results indirect_costs_minus_20_pct .03 .03 1
tree_results indirect_costs_plus_20_pct .03 .03 1
tree_results lower .03 .03 1
tree_results prob_abo .03 .03 1
tree_results true_positive .03 .03 1
tree_results upper .03 .03 1
tree_results ve50_wane10 .03 .03 1
tree_results ve50_wane5 .03 .03 1
tree_results ve80_wane10 .03 .03 1
tree_results who_emtct .03 .03 1

exit 

// end