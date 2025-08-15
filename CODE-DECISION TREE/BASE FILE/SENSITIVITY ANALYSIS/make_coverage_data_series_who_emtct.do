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
log using "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\make_coverage_data_series_who_emtct", text replace

/*
inputs:
coverage_data_series.dta created in: make_coverage_data_series.do
outputs:
coverage_data_series_who_emtct.dta
*/

////////////////////////////////////////////////////////////////////////////////
// recode all coverage parameters to 95% if <95% following WHO guidelines for //
//// the elimination of mother-to-child transmission of congenital syphilis //// 
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\coverage_data_series", clear

drop *_no_*

foreach var in anc testing treatment {
	replace prob_`var' = .95 if  prob_`var'<.95
}

foreach var in anc testing treatment {
	assert prob_`var' >=.95
}

foreach var in anc testing treatment {
	gen prob_no_`var' = 1 - prob_`var'
}

foreach var in anc testing treatment {
	assert prob_no_`var' <.
}

foreach var in anc testing treatment {
	sum prob_no_`var'
	assert `r(min)'==0
	assert `r(max)'==.05
}

qui sum year 
assert `r(min)'==2030 
assert `r(max)'==2064

order country year prob_anc prob_no_anc prob_testing prob_no_testing prob_treatment prob_no_treatment

qui tab country 
di "There are `r(r)' countries"

compress 
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\coverage_data_series_who_emtct", replace 

////////////////////////////////////////////////////////////////////////////////
/// identify countries that already meet WHO guidelines for EMTMT of syphilis //
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\coverage_data_series", clear
drop year
duplicates drop 
drop *_no_*
gen check=0 
replace check=1 if prob_anc>=.95 & prob_testing>=.95 & prob_treatment >=.95 
tab check , m 

keep if check==1
drop check  
sort country 

foreach var in prob_anc prob_testing prob_treatment {
	sum `var' 
	assert `r(min)'>=.95
}

compress 
save "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\countries_already_meeting_who_emtct", replace 

log close 

exit 

// end