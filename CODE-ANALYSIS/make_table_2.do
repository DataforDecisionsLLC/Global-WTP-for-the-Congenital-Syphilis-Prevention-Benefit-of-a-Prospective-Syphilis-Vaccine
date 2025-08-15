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
age_aggregated_tree_results_vax_novax_truncated.dta created in: make_age_aggregated_tree_results_vax_novax_truncated.do
gavi_status_2030.dta created in: make_gavi_status_2030.do
age_aggregated_tree_results_vax_novax_govt_cost.dta created in: make_age_aggregated_tree_results_vax_novax_sensitivity_analysis.do 
age_aggregated_tree_results_vax_novax_bia.dta created in: make_age_aggregated_tree_results_vax_novax_bia.do
wtp_3xpcgdp.dta created in: make_wtp_3xpcgdp.do  
outputs:
Table 2.xlsx
*/

capture log close 
log using "$output\ANALYSIS\make_table_2", text replace

////////////////////////////////////////////////////////////////////////////////
//////////////////////////// unwtd WTP all countries ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BASECASE\age_aggregated_tree_results_vax_novax_truncated", clear 
isid country 
count 

keep country wtp

egen unwtd_wtp_min = min(wtp)
egen unwtd_wtp_10 = pctile(wtp),p(10)
egen unwtd_wtp_25 = pctile(wtp),p(25)
egen unwtd_wtp_50 = pctile(wtp),p(50)
egen unwtd_wtp_75 = pctile(wtp),p(75)
egen unwtd_wtp_90 = pctile(wtp),p(90)
egen unwtd_wtp_max = max(wtp)

keep unwtd_*
duplicates drop 
assert _n==1 

export excel using "$output\ANALYSIS\Table 2.xlsx", ///
first(var) sheet("unwtd_wtp_global") sheetreplace  

////////////////////////////////////////////////////////////////////////////////
//////////////////// population-weighted WTP all countries /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BASECASE\age_aggregated_tree_results_vax_novax_truncated", clear 
isid country 
count 

keep country wtp pop15

gen pop=.
replace pop=round(pop15)

sum wtp [fweight=pop], d

gen wtd_wtp_min = `r(min)'
gen wtd_wtp_10 = `r(p10)'
gen wtd_wtp_25 = `r(p25)'
gen wtd_wtp_50 = `r(p50)'
gen wtd_wtp_75 = `r(p75)'
gen wtd_wtp_90 = `r(p90)'
gen wtd_wtp_max = `r(max)'

keep wtd_*
duplicates drop 
assert _n==1 

export excel using "$output\ANALYSIS\Table 2.xlsx", ///
first(var) sheet("wtd_wtp_global") sheetreplace  

//////////////////////////// check the weights /////////////////////////////////

use "$output\ANALYSIS\BASECASE\age_aggregated_tree_results_vax_novax_truncated", clear 
isid country 
count 

keep country wtp pop15
gen pop=.
replace pop=round(pop15)

egen pop15_global=total(pop) 
gen pop_wt = pop/pop15_global
egen check = total(pop_wt)
sum check, d 
drop check 

egen wtd_avg_wtp = total(wtp*pop_wt)

keep wtd_avg_wtp 
duplicates drop 
list 

////////////////////////////////////////////////////////////////////////////////
///////////////////////////// unwtd WTP across LMICs ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BASECASE\age_aggregated_tree_results_vax_novax_truncated", clear 
isid country 
count 

keep if inlist(income_group_1,"Low income","Middle Income")
tab income_group_1,m
assert `r(r)'==2

keep country wtp

egen unwtd_wtp_min = min(wtp)
egen unwtd_wtp_10 = pctile(wtp),p(10)
egen unwtd_wtp_25 = pctile(wtp),p(25)
egen unwtd_wtp_50 = pctile(wtp),p(50)
egen unwtd_wtp_75 = pctile(wtp),p(75)
egen unwtd_wtp_90 = pctile(wtp),p(90)
egen unwtd_wtp_max = max(wtp)

keep unwtd_*
duplicates drop 
assert _n==1 

export excel using "$output\ANALYSIS\Table 2.xlsx", ///
first(var) sheet("unwtd_wtp_LMICs") sheetreplace 

////////////////////////////////////////////////////////////////////////////////
///////////////////////////// unwtd WTP across HICs ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BASECASE\age_aggregated_tree_results_vax_novax_truncated", clear 
isid country 
count 

keep if inlist(income_group_1,"High Income")
tab income_group_1,m
assert `r(r)'==1

keep country wtp

egen unwtd_wtp_min = min(wtp)
egen unwtd_wtp_10 = pctile(wtp),p(10)
egen unwtd_wtp_25 = pctile(wtp),p(25)
egen unwtd_wtp_50 = pctile(wtp),p(50)
egen unwtd_wtp_75 = pctile(wtp),p(75)
egen unwtd_wtp_90 = pctile(wtp),p(90)
egen unwtd_wtp_max = max(wtp)

keep unwtd_*
duplicates drop 
assert _n==1 

export excel using "$output\ANALYSIS\Table 2.xlsx", ///
first(var) sheet("unwtd_wtp_HICs") sheetreplace   

////////////////////////////////////////////////////////////////////////////////
////////////////////// unwtd Gavi eligible countries ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\GNI\gavi_status_2030", clear 
assert gavi_status_2030 ==1

keep country gavi_status_2030
count 

merge 1:1 country using "$output\ANALYSIS\BASECASE\age_aggregated_tree_results_vax_novax_truncated", ///
keepusing(country wtp)

list country if _m==1

keep if _m==3 
drop _m 

isid country 
count 

egen unwtd_wtp_min = min(wtp)
egen unwtd_wtp_10 = pctile(wtp),p(10)
egen unwtd_wtp_25 = pctile(wtp),p(25)
egen unwtd_wtp_50 = pctile(wtp),p(50)
egen unwtd_wtp_75 = pctile(wtp),p(75)
egen unwtd_wtp_90 = pctile(wtp),p(90)
egen unwtd_wtp_max = max(wtp)

keep unwtd_*
duplicates drop 
assert _n==1 

export excel using "$output\ANALYSIS\Table 2.xlsx", ///
first(var) sheet("unwtd_wtp_Gavi_countries") sheetreplace   

////////////////////////////////////////////////////////////////////////////////
////////// unwtd expected cost impacts and DALY gains all countries ////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BASECASE\age_aggregated_tree_results_vax_novax_truncated", clear 
isid country 
count 

keep country d_cost d_daly

replace d_cost = -1*d_cost 

egen unwtd_d_cost_min = min(d_cost)
egen unwtd_d_cost_10 = pctile(d_cost),p(10)
egen unwtd_d_cost_25 = pctile(d_cost),p(25)
egen unwtd_d_cost_50 = pctile(d_cost),p(50)
egen unwtd_d_cost_75 = pctile(d_cost),p(75)
egen unwtd_d_cost_90 = pctile(d_cost),p(90)
egen unwtd_d_cost_max = max(d_cost)

egen unwtd_d_daly_min = min(d_daly)
egen unwtd_d_daly_10 = pctile(d_daly),p(10)
egen unwtd_d_daly_25 = pctile(d_daly),p(25)
egen unwtd_d_daly_50 = pctile(d_daly),p(50)
egen unwtd_d_daly_75 = pctile(d_daly),p(75)
egen unwtd_d_daly_90 = pctile(d_daly),p(90)
egen unwtd_d_daly_max = max(d_daly)

keep unwtd_*
duplicates drop 
assert _n==1 

export excel using "$output\ANALYSIS\Table 2.xlsx", ///
first(var) sheet("unwtd_costs_dalys_global") sheetreplace  

////////////////////////////////////////////////////////////////////////////////
////////////// unwtd WTP all countries under payer perspective /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\SENSITIVITY ANALYSIS\age_aggregated_tree_results_vax_novax_govt_costs" , clear  
isid country 
count 

keep country wtp

egen unwtd_wtp_min = min(wtp)
egen unwtd_wtp_10 = pctile(wtp),p(10)
egen unwtd_wtp_25 = pctile(wtp),p(25)
egen unwtd_wtp_50 = pctile(wtp),p(50)
egen unwtd_wtp_75 = pctile(wtp),p(75)
egen unwtd_wtp_90 = pctile(wtp),p(90)
egen unwtd_wtp_max = max(wtp)

keep unwtd_*
duplicates drop 
assert _n==1 

export excel using "$output\ANALYSIS\Table 2.xlsx", ///
first(var) sheet("unwtd_wtp_global_payer") sheetreplace  

////////////////////////////////////////////////////////////////////////////////
////////////////////////// unwtd WTP all countries BIA /////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BIA\age_aggregated_tree_results_vax_novax_bia", clear 
keep country d_cost_bia 
isid country 
count 

replace d_cost_bia = -1*d_cost_bia 

egen unwtd_d_cost_bia_min = min(d_cost_bia)
egen unwtd_d_cost_bia_10 = pctile(d_cost_bia),p(10)
egen unwtd_d_cost_bia_25 = pctile(d_cost_bia),p(25)
egen unwtd_d_cost_bia_50 = pctile(d_cost_bia),p(50)
egen unwtd_d_cost_bia_75 = pctile(d_cost_bia),p(75)
egen unwtd_d_cost_bia_90 = pctile(d_cost_bia),p(90)
egen unwtd_d_cost_bia_max = max(d_cost_bia)

keep unwtd_*
duplicates drop 
assert _n==1 

export excel using "$output\ANALYSIS\Table 2.xlsx", ///
first(var) sheet("unwtd_cost_bia")sheetreplace 

////////////////////////////////////////////////////////////////////////////////
////// unwtd WTP all countries setting WTP per DALY at 3 times PCGDP ///////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\BASECASE\wtp_3xpcgdp" , clear

isid country 
count 

keep country wtp

egen unwtd_wtp_min = min(wtp)
egen unwtd_wtp_10 = pctile(wtp),p(10)
egen unwtd_wtp_25 = pctile(wtp),p(25)
egen unwtd_wtp_50 = pctile(wtp),p(50)
egen unwtd_wtp_75 = pctile(wtp),p(75)
egen unwtd_wtp_90 = pctile(wtp),p(90)
egen unwtd_wtp_max = max(wtp)

keep unwtd_*
duplicates drop 
assert _n==1 

export excel using "$output\ANALYSIS\Table 2.xlsx", ///
first(var) sheet("unwtd_wtp_3xpcgdp") sheetreplace  

log close 

exit 

// end