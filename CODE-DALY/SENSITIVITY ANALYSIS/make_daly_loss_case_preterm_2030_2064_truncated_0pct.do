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
log using "$output\DALY\make_daly_loss_case_preterm_2030_2064_truncated_0pct", text replace 

gl r 0
gl analysis 0pct 

/*
inputs:
raw_life_tables.dta created in: make_raw_life_tables.do
deaths_prevalence_ylds_preterm.dta created in: make_daly_loss_case_preterm_2030_2064_truncated.do
ylds_case_preterm_w_life_tables.dta created in: make_daly_loss_case_preterm_2030_2064_truncated.do
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
outputs:
daly_loss_case_preterm_2030_2064_truncated_0pct.dta
*/

////////////////////////////////////////////////////////////////////////////////
//////////////////// compute life expectancy for ages 0-4 //////////////////////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\DALY\le_preterm_$analysis" 
save          "$output\DALY\le_preterm_$analysis" , emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\LIFE TABLES\raw_life_tables", clear
keep country year age survivors_l L
ren year birth_year

keep if birth_year==`year'
keep country birth_year age survivors_l L
sort country birth_year age

drop if age > (2080-birth_year)

forvalues x = 0/4 {
	gen L_`x'=L
}

forvalues x = 0/4 {
	replace L_`x'=. if age<`x'
}

forvalues x = 0/4 {
	replace L_`x'= L_`x'/((1 + $r)^(age-`x'))
}

forvalues x = 0/4 {
	by country birth_year: egen T_`x' = total(L_`x')
}

forvalues x = 0/4 {
	gen LE_`x' = .
}

forvalues x = 0/4 {
	replace LE_`x' = T_`x'/survivors_l if age==`x'
}

gen LE=., before(survivors_l)

forvalues x = 0/4 {
	replace LE=LE_`x' if age==`x'
}

drop survivors_l L L_* T_* LE_* 
ren LE le_$analysis

keep if age<=4

append using "$output\DALY\le_preterm_$analysis"  
sort country birth_year age 
save         "$output\DALY\le_preterm_$analysis" , replace 

end

forvalues y = 2030/2050 {
	le `y'
}

////////////////////////////////////////////////////////////////////////////////
/////////////////// Combine life expectancy with deaths ////////////////////////
/// Compute deaths per case using the number of cases in the birth year ////////
///// Collapse to the country birth cohort level by summing the product of /////
//////////// life expectancy and deaths per case  acress ages 0-4. /////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\DALY\le_preterm_$analysis" , clear
sort country birth_year age
assert age<=4
assert birth_year>=2030 & birth_year<=2050

merge 1:1 country birth_year age using "$output\DALY\deaths_prevalence_ylds_preterm", ///
keepusing(country birth_year age year number_deaths number_prevalence) 
assert number_deaths==. if age>4
drop if age>4
assert _m==3
drop _m 

gen birth_cases=.
replace birth_cases = number_prevalence if year==birth_year 

gen yll_$analysis = le_$analysis*number_deaths

collapse (sum) yll_$analysis (min) birth_cases, by(country birth_year)

gen yll_case = yll_$analysis/birth_cases
sum yll_case, d

keep country birth_year yll_case
sort  country birth_year

compress 

save  "$output\DALY\ylls_case_preterm_collapsed_0pct.dta", replace

////////////////////////////////////////////////////////////////////////////////
// Compute expected discounted lifetime YLDs per case for each birth cohort ////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\DALY\ylds_case_preterm_truncated_0pct.dta"
save          "$output\DALY\ylds_case_preterm_truncated_0pct.dta" , emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\DALY\ylds_case_preterm_w_life_tables", clear 

keep if birth_year==`year'
sort country birth_year age

drop if age > (2080-birth_year)

forvalues x = 0/0 {
	gen L_`x'=L
}

forvalues x = 0/0 {
	replace L_`x'=. if age<`x'
}

forvalues x = 0/0 {
	gen yld_case_`x'=yld_case
}

forvalues x = 0/0 {
	replace yld_case_`x'=. if age<`x'
}

forvalues x = 0/0 {
	replace L_`x' = L_`x'*yld_case_`x'
}

forvalues x = 0/0 {
	drop yld_case_`x'
}

forvalues x = 0/0 {
	replace L_`x'= L_`x'/((1 + $r)^(age-`x'))
}

forvalues x = 0/0 {
	by country birth_year: egen T_`x' = total(L_`x')
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

drop survivors_l L L_* T_* LE_* yld_case
ren LE yld_case

compress 

keep if age==0

compress 

append using "$output\DALY\ylds_case_preterm_truncated_0pct.dta"
sort country birth_year age 
save         "$output\DALY\ylds_case_preterm_truncated_0pct.dta" , replace 

end

forvalues y = 2030/2050 {
	le `y'
}

////////////////////////////////////////////////////////////////////////////////
///////////////// combine ylls per case and ylds per case and //////////////////
///////////////////////// extrapolate these to year 2064 ///////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\ylds_case_preterm_truncated_0pct.dta", clear 
assert age==0 
drop age 
sum yld_case, d 

merge 1:1 country birth_year using "$output\DALY\ylls_case_preterm_collapsed_0pct.dta"
assert _m==3 
drop _m 

sort country birth_year 

save "$output\DALY\ylls_&_ylds_case_preterm_truncated_0pct.dta", replace

////////////////////////////////////////////////////////////////////////////////
/////////// extrapolate ylls/case & ylds/case to 2064 using 2050 values ////////
///////////////////////// and compute dalys/case ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\DALY\daly_loss_case_preterm_2030_2064_truncated_0pct.dta"
save          "$output\DALY\daly_loss_case_preterm_2030_2064_truncated_0pct.dta", replace emptyok

capture prog drop project_dalys
prog project_dalys
version 18.0 
set more off
set type double
args country  

use if country=="`country'" using "$output\DALY\ylls_&_ylds_case_preterm_truncated_0pct.dta", clear
gen expand=0 
replace expand=15 if birth_year==2050 
expand expand 
sort country birth_year 
by country: replace birth_year  = birth_year[_n-1] + 1 if expand==15
sort country birth_year 
by   country: assert birth_year == 2064 if _n==_N 
drop expand

assert yll_case<. 
assert yld_case<. 

gen preterm_dalys = yll_case + yld_case

order country birth_year preterm_dalys yll_case yld_case

append using "$output\DALY\daly_loss_case_preterm_2030_2064_truncated_0pct.dta"
sort country birth_year 
compress 
save "$output\DALY\daly_loss_case_preterm_2030_2064_truncated_0pct.dta", replace  

end 

use "$output\DALY\ylls_&_ylds_case_preterm_truncated_0pct.dta", clear 

levelsof country , local(country)
foreach c of local country {
	 project_dalys "`c'"
}

////////////////////////////////////////////////////////////////////////////////
////////////////// map on the region-income classifications ////////////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\DALY\daly_loss_case_preterm_2030_2064_truncated_0pct.dta", clear

merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert _m==3 
drop _m 
sort country birth_year

gen region_income="" 
replace region_income ="AFRO_LIC" if who_region=="AFRO" & income_group_1=="Low income"
replace region_income ="AFRO_MIC" if who_region=="AFRO" & income_group_1=="Middle Income"
replace region_income ="AFRO_HIC" if who_region=="AFRO" & income_group_1=="High Income"

replace region_income ="AMRO_LIC" if who_region=="AMRO" & income_group_1=="Low income"
replace region_income ="AMRO_MIC" if who_region=="AMRO" & income_group_1=="Middle Income"
replace region_income ="AMRO_HIC" if who_region=="AMRO" & income_group_1=="High Income"

replace region_income ="EMRO_LIC" if who_region=="EMRO" & income_group_1=="Low income"
replace region_income ="EMRO_MIC" if who_region=="EMRO" & income_group_1=="Middle Income"
replace region_income ="EMRO_HIC" if who_region=="EMRO" & income_group_1=="High Income"

replace region_income ="EURO_HIC" if who_region=="EURO" & income_group_1=="High Income"
replace region_income ="EURO_MIC" if who_region=="EURO" & income_group_1=="Middle Income"

replace region_income ="SEARO_LIC" if who_region=="SEARO" & income_group_1=="Low income"
replace region_income ="SEARO_MIC" if who_region=="SEARO" & income_group_1=="Middle Income"

replace region_income ="WPRO_HIC" if who_region=="WPRO" & income_group_1=="High Income"
replace region_income ="WPRO_MIC" if who_region=="WPRO" & income_group_1=="Middle Income"
assert region_income!=""

compress 
save "$output\DALY\daly_loss_case_preterm_2030_2064_truncated_0pct.dta", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////////////// summary statistics ////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\daly_loss_case_preterm_2030_2064_truncated_0pct.dta", clear 

levelsof income_group_1, local(income)
foreach g of local income {
	di "*********** The income group is `g'***************"
	sum preterm_dalys if income_group_1 == "`g'", d
}

levelsof income_group_1, local(income)
foreach g of local income {
	forvalues b = 2023/2057 {
		di "*********** The income group is `g'***************"
		di "********* The birth cohort is `b' ****************"
		sum preterm_dalys if income_group_1 == "`g'" & birth_year== `b'
	}
}

log close 
exit 

// end