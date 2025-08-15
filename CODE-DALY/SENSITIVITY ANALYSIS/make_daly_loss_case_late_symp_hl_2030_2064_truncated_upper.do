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
log using "$output\DALY\UPPER\make_daly_loss_case_late_symp_hl_2030_2064_truncated_upper", text replace 

gl r .03
gl analysis discounted 

/*
inputs:
late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022_upper.dta created in: make_GBD_2021_congenital_syphilis_upper_lower.do
raw_life_tables.dta created in: make_raw_life_tables.do
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
outputs:
daly_loss_case_late_symp_hl_2030_2064_truncated.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////////////// get the IHME data and keep only the vars needed //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\GBD 2021\CS\late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022_upper", clear

drop if regexm(age,"neonatal")

keep if unit=="Number"
assert condition=="Late symptomatic congenital syphilis, unilateral hearing loss"
drop unit condition 

ren value_prevalence number_prevalence 
ren value_ylds number_ylds 

gen sortme=. 
replace sortme=1 if age=="Under 1"
replace sortme=2 if age=="1 to 4"
replace sortme=3 if age=="5 to 9"
replace sortme=4 if age=="10 to 14"
replace sortme=5 if age=="15 to 19"
replace sortme=6 if age=="20 to 24"
replace sortme=7 if age=="25 to 29"
replace sortme=8 if age=="30 to 34"
replace sortme=9 if age=="35 to 39"
replace sortme=10 if age=="40 to 44"
replace sortme=11 if age=="45 to 49"
replace sortme=12 if age=="50 to 54"
replace sortme=13 if age=="55 to 59"
replace sortme=14 if age=="60 to 64"
replace sortme=15 if age=="65 to 69"
replace sortme=16 if age=="70 to 74"
replace sortme=17 if age=="75 to 79"
replace sortme=18 if age=="80 to 84"
replace sortme=19 if age=="85 to 89"
replace sortme=20 if age=="90 to 94"
replace sortme=21 if age=="95 and above"

assert sortme<.
sort country year sortme 

sort country year sortme 
isid country year age

qui tab country 
di "There are `r(r)' countries"

keep if year==2022

compress
save "$output\IHME\GBD 2021\CS\late_symp_hl_10_99_years_year2022_upper", replace

////////////////////////////////////////////////////////////////////////////////
/// compute ylds per case; expand to single age assuming ylds and prevalence /// 
////// are uniformly distributed acress integer ages within an age group ///////
////////////////////////////////////////////////////////////////////////////////

use "$output\IHME\GBD 2021\CS\late_symp_hl_10_99_years_year2022_upper", clear

gen yld_case = number_ylds/number_prevalence

replace age = "0" if age=="Under 1"
replace age = "95 to 100" if age=="95 and above"
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

replace yld_case=0 if age<10

order country year 
sort country year age 

compress
save "$output\IHME\GBD 2021\CS\late_symp_hl_10_99_years_year2022_single_ages_upper", replace

////////////////////////////////////////////////////////////////////////////////
///////////////// map single age ylds per case to life tables //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\LIFE TABLES\raw_life_tables", clear 
keep country year age L survivors_l
keep if year==2022
merge 1:1 country year age using "$output\IHME\GBD 2021\CS\late_symp_hl_10_99_years_year2022_single_ages_upper"
assert _m!=2
keep if _m==3 
drop _m 
sort country year age 
order country year age yld_case L survivors_l

compress 
save "$output\DALY\UPPER\late_symp_hl_10_99_years_year2022_single_ages_w_life_tables", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////////// compute expected lifetime YLDs //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\UPPER\late_symp_hl_10_99_years_year2022_single_ages_w_life_tables", clear

assert year==2022
sort country year age

drop if age > (2080-year)

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

save  "$output\DALY\UPPER\yld_loss_case_late_symp_hl_birthyear_2022_truncated"   , replace 

////////////////////////////////////////////////////////////////////////////////
/////////// extrapolate ylds to 2064 using constant the 2022 values ////////////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\DALY\UPPER\daly_loss_case_late_symp_hl_2030_2064_truncated.dta"
save          "$output\DALY\UPPER\daly_loss_case_late_symp_hl_2030_2064_truncated.dta", replace emptyok

capture prog drop project_dalys
prog project_dalys
version 18.0 
set more off
set type double
args country  

use if country=="`country'" using "$output\DALY\UPPER\yld_loss_case_late_symp_hl_birthyear_2022_truncated" , clear
expand 43 
sort country birth_year 
by country: replace birth_year  = birth_year[_n-1] + 1 if _n>1
sort country birth_year 
by   country: assert birth_year == 2064 if _n==_N 

assert yld_case<. 
ren yld_case late_symp_hl_dalys

order country birth_year late_symp_hl_dalys
drop if birth_year<2030

append using "$output\DALY\UPPER\daly_loss_case_late_symp_hl_2030_2064_truncated.dta"
sort country birth_year 
compress 
save         "$output\DALY\UPPER\daly_loss_case_late_symp_hl_2030_2064_truncated.dta", replace  

end 

use "$output\DALY\UPPER\yld_loss_case_late_symp_hl_birthyear_2022_truncated", clear 

levelsof country , local(country)
foreach c of local country {
	 project_dalys "`c'"
}

////////////////////////////////////////////////////////////////////////////////
////////////////// map on the region-income classifications ////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\UPPER\daly_loss_case_late_symp_hl_2030_2064_truncated.dta", clear

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
save "$output\DALY\UPPER\daly_loss_case_late_symp_hl_2030_2064_truncated.dta", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////////////// summary stats ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\UPPER\daly_loss_case_late_symp_hl_2030_2064_truncated.dta", clear 

levelsof who_region, local(region)
foreach g of local region {
	di "*********** The who region is `g'*****************"
	sum late_symp_hl_dalys if who_region == "`g'" , d
}

log close 

exit 

// end