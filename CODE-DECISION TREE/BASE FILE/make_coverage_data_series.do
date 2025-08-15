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
log using "$output\DECISION TREE\BASE FILE\make_coverage_data_series", text replace

/*
inputs:
coverage_data_ihme_countries.dta created in: make_coverage_data_ihme_countries.do
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
outputs:
coverage_data_series.dta 
*/

use "$output\DECISION TREE\BASE FILE\coverage_data_ihme_countries", clear
qui tab country 
di "There are `r(r)' countries"

// drop records with missng values for all anc1 variables 
egen check_anc1=rownonmiss(anc1_unicef anc1_koren anc1_who_15_19 anc1_who_20_49)

drop if check_anc1==0 
drop check 

qui tab country 
di "There are `r(r)' countries"

order country year *_koren *_unicef *_who  

////////////////////////////////////////////////////////////////////////////////
////////////////// rule 1: use Korenromp whereever possible ////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\coverage_data_ihme_countries", clear
qui tab country 
di "There are `r(r)' countries"

keep country year *_koren
drop if anc1_koren==. 
drop if testing_koren==. 
drop if treatment_koren==. 
tab year , m 
drop if year==2012
isid country 
count 

save "$output\DECISION TREE\BASE FILE\coverage_data_series", replace 

////////////////////////////////////////////////////////////////////////////////
// rule 2: for countries not in Korenromp, use unicef for anc 1 and ////////////
///////////////////////// WHO for testing and treatment ////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\coverage_data_ihme_countries", clear 
keep country 
duplicates drop 
merge 1:1 country using "$output\DECISION TREE\BASE FILE\coverage_data_series"
list country if _m==1 
assert country =="Taiwan" if _m==1
keep if _m ==1 
keep country 

merge 1:m country using "$output\DECISION TREE\BASE FILE\coverage_data_ihme_countries"
assert _m !=1 
keep if _m==3 
drop _m *_koren

egen check=rownonmiss(anc1_unicef anc1_who_15_19 anc1_who_20_49 testing_who treatment_who)
assert check==0 

////////////////////////////////////////////////////////////////////////////////
// rule 3: for Taiwan, use the region-income average from Korenromp ////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\coverage_data_series", clear 
merge 1:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert country=="Taiwan" if _m==2 
list _m country country who_region income_group_1 if _m==2 
drop _m
keep if who_region=="WPRO" & income_group_1=="High Income"
sort country who_region income_group_1
list, sep(0)
drop if country=="Taiwan"
collapse (mean) anc1_koren testing_koren treatment_koren
gen country = "Taiwan" 
gen year = 2016
order country year 
append using  "$output\DECISION TREE\BASE FILE\coverage_data_series"
isid country 
count 

save "$output\DECISION TREE\BASE FILE\coverage_data_series", replace 

////////////////////////////////////////////////////////////////////////////////
////////////////////////// extrapolate to 2064 /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\DECISION TREE\BASE FILE\coverage_data_series", clear 

replace year = 2030
expand 35 

sort country year 
by country: replace year = year[_n-1] + 1 if _n>1
sort country year 
by country: assert year==2064 if _n==_N 

compress 
save "$output\DECISION TREE\BASE FILE\coverage_data_series", replace 

////////////////////////////////////////////////////////////////////////////////
///// compute the probabilities of: no_anc, no_testing , and no_treatment //////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\coverage_data_series", clear

ren anc1_koren prob_anc

foreach var in testing treatment {
	ren `var'_koren prob_`var'
}

foreach var in testing treatment {
	assert prob_`var'<.
}

foreach var in anc testing treatment {
	gen prob_no_`var' = 1 - prob_`var'
}

foreach var in anc testing treatment {
	assert prob_no_`var' <.
}

qui sum year 
assert `r(min)'==2030 
assert `r(max)'==2064

order country year prob_anc prob_no_anc prob_testing prob_no_testing prob_treatment prob_no_treatment

compress 
save "$output\DECISION TREE\BASE FILE\coverage_data_series", replace 

log close 

exit 

// end