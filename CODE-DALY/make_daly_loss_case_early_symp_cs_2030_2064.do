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
log using "$output\DALY\make_daly_loss_case_early_symp_cs_2030_2064", text replace 

gl r .03
gl analysis discounted 

/*
inputs:
early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022.dta created in: make_GBD_2021_congenital_syphilis.do
raw_life_tables.dta created in: make_raw_life_tables.do
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
outputs:
early_symp_cs_0_4_years_year2022_single_ages_w_life_tables.dta
daly_loss_case_early_symp_cs_2030_2064.dta 
*/

////////////////////////////////////////////////////////////////////////////////
///////////////// get the IHME data and keep only the vars needed //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\GBD 2021\CS\early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022", clear 
keep if inlist(age,"Under 1","1 to 4")

keep if unit=="Number"
assert condition=="Early symptomatic congenital syphilis, infectious syndrome"
replace value_incidence=0 if value_incidence==.
assert value_incidence==0 
drop unit condition value_incidence

ren value_prevalence number_prevalence 
ren value_ylds number_ylds 

gen sortme=. 
replace sortme=1 if age=="Under 1"
replace sortme=2 if age=="1 to 4"

sort country year sortme 
isid country year age

qui tab country 
di "There are `r(r)' countries"

keep if year==2022

compress
save "$output\IHME\GBD 2021\CS\early_symp_cs_0_4_years_year2022", replace

////////////////////////////////////////////////////////////////////////////////
/// compute ylds per case; expand to single age assuming ylds and prevalence /// 
////// are uniformly distributed acress integer ages within an age group ///////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\GBD 2021\CS\early_symp_cs_0_4_years_year2022", clear

gen yld_case = number_ylds/number_prevalence
drop number_prevalence number_ylds 

replace age = "0" if age=="Under 1"
split age, parse("to") 
destring age1, replace 
destring age2, replace 
gen diff= age2 - age1 + 1
replace diff=0 if age1==0
expand diff 
sort country year sortme
by   country year sortme: replace age1 = age1[_n-1] + 1 if _n>1
by   country year sortme: assert age1==age2 if _n==_N & age1>0

drop age age2 diff sortme 
ren age1 age 

order country year 
sort country year age 

compress
save "$output\IHME\GBD 2021\CS\early_symp_cs_0_4_years_year2022_single_ages", replace

////////////////////////////////////////////////////////////////////////////////
///////////////// map single age ylds per case to life tables //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\LIFE TABLES\raw_life_tables", clear 
keep country year age L survivors_l
keep if year==2022
merge 1:1 country year age using "$output\IHME\GBD 2021\CS\early_symp_cs_0_4_years_year2022_single_ages"
assert _m!=2
keep if _m==3 
drop _m 
sort country year age 
order country year age yld_case L survivors_l

compress 
save "$output\DALY\early_symp_cs_0_4_years_year2022_single_ages_w_life_tables", replace

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

save  "$output\DALY\yld_loss_case_early_symp_cs_birthyear_2022"   , replace 

////////////////////////////////////////////////////////////////////////////////
///////////// extrapolate ylds/case to 2064 using the 2022 values //////////////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\DALY\daly_loss_case_early_symp_cs_2030_2064.dta"
save          "$output\DALY\daly_loss_case_early_symp_cs_2030_2064.dta", replace emptyok

capture prog drop project_dalys
prog project_dalys
version 18.0 
set more off
set type double
args country  

use if country=="`country'" using "$output\DALY\yld_loss_case_early_symp_cs_birthyear_2022" , clear
expand 43 
sort country birth_year 
by country: replace birth_year  = birth_year[_n-1] + 1 if _n>1
sort country birth_year 
by   country: assert birth_year == 2064 if _n==_N 

assert yld_case<. 
ren yld_case early_symp_cs_dalys

order country birth_year early_symp_cs_dalys
drop if birth_year<2030

append using "$output\DALY\daly_loss_case_early_symp_cs_2030_2064.dta"
sort country birth_year 
compress 
save         "$output\DALY\daly_loss_case_early_symp_cs_2030_2064.dta", replace  

end 

use "$output\DALY\yld_loss_case_early_symp_cs_birthyear_2022", clear 

levelsof country , local(country)
foreach c of local country {
	 project_dalys "`c'"
}

////////////////////////////////////////////////////////////////////////////////
////////////////// map on the region-income classifications ////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\daly_loss_case_early_symp_cs_2030_2064.dta", clear

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
save "$output\DALY\daly_loss_case_early_symp_cs_2030_2064.dta", replace


use "$output\DALY\daly_loss_case_early_symp_cs_2030_2064.dta", clear 

levelsof who_region, local(region)
foreach g of local region {
	di "*********** The who region is `g'*****************"
	sum early_symp_cs_dalys if who_region == "`g'", d
}

log close 

exit 

// end