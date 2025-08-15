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
log using "$output\FERTILITY\SENSITIVITY ANALYSIS\make_probability_pregnant_sensitivity_analysis", text replace 

/*
inputs:
wpp_single_age_fertility_rates_sensitivity_analysis.dta created in: make_wpp_single_age_fertility_rates_sensitivity_analysis.do
dhs_ratio_tb_lb.dta created in: make_probability_pregnant.do 
Huang_2008_figure_2.xlsx
outputs:
probability_pregnant_sensitivity_analysis.dta
*/

////////////////////////////////////////////////////////////////////////////////
////// multiply the single age ratios of total births to live births to the ////
////// single age fertility rates to compute the adjusted fertility rates //////
////////////////////////////////////////////////////////////////////////////////

use "$output\FERTILITY\SENSITIVITY ANALYSIS\wpp_single_age_fertility_rates_sensitivity_analysis", clear 

forvalues a = 15/49 {
	ren age_`a' fert_`a'
}

reshape long fert_, i(variant country year who_region income_group_1 ) j(age)
sort country year age variant 

merge m:1 country age using "$output\FERTILITY\dhs_ratio_tb_lb"
assert _m!=2 
keep if _m==3 
drop _m 
sort country year age variant
assert ratio_tb_lb>=1 & ratio_tb_lb<.
gen dhs_fert=fert_*ratio_tb_lb
drop fert_ ratio_tb_lb
order country year age dhs_fert
isid country year age variant
assert dhs_fert<. 
drop if year>2064
compress
save "$output\FERTILITY\SENSITIVITY ANALYSIS\dhs_adj_single_age_fertility_rates_sensitivity_analysis", replace

////////////////////////////////////////////////////////////////////////////////
//// map ratio of total births to live births for younger (age 15-34) and //////
////// older (age 35+) mothers from Huang to the single age fertility rates ////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\HUANG\Huang_2008_figure_2.xlsx", ///
clear sheet("import") first case(lower) cellrange(A1:K39)
keep if rownum=="totals" 
keep ratio_tb_lb_older ratio_tb_lb_younger

append using "$output\FERTILITY\SENSITIVITY ANALYSIS\wpp_single_age_fertility_rates_sensitivity_analysis"
sort country year variant 

replace ratio_tb_lb_older = ratio_tb_lb_older[_n-1] if _n>1 & ratio_tb_lb_older==.
replace ratio_tb_lb_younger = ratio_tb_lb_younger[_n-1] if _n>1 & ratio_tb_lb_younger==.

foreach a in older younger {
	assert ratio_tb_lb_`a'>1 & ratio_tb_lb_`a'<.
}

drop if country==""
order country variant

forvalues a = 15/49 {
	gen huang_fert_`a' = .
}

forvalues a = 15/34 {
	replace huang_fert_`a' = age_`a'*ratio_tb_lb_younger
}

forvalues a = 35/49 {
	replace huang_fert_`a' = age_`a'*ratio_tb_lb_older
}

keep variant country year who_region income_group_1 huang_fert_*
drop if year>2064 

forvalues a = 15/49 {
	assert huang_fert_`a' < .
}

reshape long huang_fert_, i(variant country who_region income_group_1 year) j(age)
reshape wide huang_fert_, i(variant country who_region income_group_1 age) j(year)
sort country age variant 

compress 
save "$output\FERTILITY\SENSITIVITY ANALYSIS\huang_adj_single_age_fertility_rates_sensitivity_analysis", replace

////////////////////////////////////////////////////////////////////////////////
////////////// combine the dhs and huang adjected fertility rates //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\FERTILITY\SENSITIVITY ANALYSIS\huang_adj_single_age_fertility_rates_sensitivity_analysis", clear 
reshape long huang_fert_, i(variant country who_region income_group_1 age) j(year)
ren huang_fert_ huang_fert

isid country year age variant 
sort country age year variant 
merge 1:1 variant country age year who_region income_group_1  using "$output\FERTILITY\SENSITIVITY ANALYSIS\dhs_adj_single_age_fertility_rates_sensitivity_analysis"
assert _m!=2 

tab who_region income_group_1 if _m==1 
tab country who_region if _m==1 & income_group_1=="Low income", m

sort country year age variant
keep if year>=2030 & year<=2064

qui sum age 
assert `r(min)'==15 
assert `r(max)'==49

qui sum year 
assert `r(min)'==2030
assert `r(max)'==2064

gen compare=dhs_fert/huang_fert
sum compare if _m==3 , d 

drop compare

gen adj_fert=. 
replace adj_fert=huang_fert if _m==1 & huang_fert<. 
replace adj_fert=dhs_fert if dhs_fert<. & adj_fert==.
assert adj_fert<.

keep variant country year age adj_fert who_region income_group_1

sum adj_fert if variant=="high",d
sum adj_fert if variant=="low",d

replace adj_fert=adj_fert/1000
sum adj_fert if variant=="high",d
sum adj_fert if variant=="low",d

ren adj_fert adj_fert_
reshape wide adj_fert_, i(country age year) j(variant) string

// convert fertility rates to a pregnancy probability

foreach v in high low {
	gen prob_preg_`v' = 1-exp(-1*adj_fert_`v')
}
 
foreach v in high low {
	sum prob_preg_`v', d
}

foreach v in high low {
	drop adj_fert_`v'
}

qui tab country 
di "There are `r(r)' countries"

compress 

save "$output\FERTILITY\SENSITIVITY ANALYSIS\probability_pregnant_sensitivity_analysis", replace 

log close 

exit 

// end 
