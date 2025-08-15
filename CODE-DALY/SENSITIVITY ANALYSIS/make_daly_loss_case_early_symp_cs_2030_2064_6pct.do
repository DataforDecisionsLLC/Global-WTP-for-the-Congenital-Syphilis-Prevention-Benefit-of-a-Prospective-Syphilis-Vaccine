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
log using "$output\DALY\make_daly_loss_case_early_symp_cs_2030_2064_6pct", text replace 

gl r .06
gl analysis 6pct

/*
inputs:
early_symp_cs_0_4_years_year2022_single_ages_w_life_tables.dta created in: make_daly_loss_case_early_symp_cs_2030_2064.do
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
outputs:
daly_loss_case_early_symp_cs_2030_2064_6pct.dta 
*/

////////////////////////////////////////////////////////////////////////////////
////////////////////////// compute expected lifetime YLDs //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\early_symp_cs_0_4_years_year2022_single_ages_w_life_tables", clear

assert year==2022
sort country year age

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

drop survivors_l L L_* T_* LE_* yld_case
ren LE yld_case

compress 

keep if age==0
assert age==0 
drop age 

sort country year
ren year birth_year

compress 

save  "$output\DALY\yld_loss_case_early_symp_cs_birthyear_2022_$analysis"   , replace 

////////////////////////////////////////////////////////////////////////////////
///////////// extrapolate ylds/case to 2064 using the 2022 values //////////////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\DALY\daly_loss_case_early_symp_cs_2030_2064_$analysis.dta"
save          "$output\DALY\daly_loss_case_early_symp_cs_2030_2064_$analysis.dta", replace emptyok

capture prog drop project_dalys
prog project_dalys
version 18.0 
set more off
set type double
args country  

use if country=="`country'" using "$output\DALY\yld_loss_case_early_symp_cs_birthyear_2022_$analysis" , clear
expand 43 
sort country birth_year 
by country: replace birth_year  = birth_year[_n-1] + 1 if _n>1
sort country birth_year 
by   country: assert birth_year == 2064 if _n==_N 

assert yld_case<. 
ren yld_case early_symp_cs_dalys

order country birth_year early_symp_cs_dalys
drop if birth_year<2030

append using "$output\DALY\daly_loss_case_early_symp_cs_2030_2064_$analysis.dta"
sort country birth_year 
compress 
save         "$output\DALY\daly_loss_case_early_symp_cs_2030_2064_$analysis.dta", replace  

end 

use "$output\DALY\yld_loss_case_early_symp_cs_birthyear_2022_$analysis", clear 

levelsof country , local(country)
foreach c of local country {
	 project_dalys "`c'"
}

////////////////////////////////////////////////////////////////////////////////
////////////////// map on the region-income classifications ////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\daly_loss_case_early_symp_cs_2030_2064_$analysis.dta", clear

merge m:1 country using "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert _m!=2 
keep if _m==3 
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
save "$output\DALY\daly_loss_case_early_symp_cs_2030_2064_$analysis.dta", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////////////// summary statistics ////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\daly_loss_case_early_symp_cs_2030_2064_$analysis.dta", clear 

levelsof who_region, local(region)
foreach g of local region {
	di "*********** The who region is `g'*****************"
	sum early_symp_cs_dalys if who_region == "`g'", d
}

log close 

exit 

// end