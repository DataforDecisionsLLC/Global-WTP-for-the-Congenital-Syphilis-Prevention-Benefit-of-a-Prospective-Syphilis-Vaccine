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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_lifetime_expected_hearing_loss_costs_truncated", text replace

gl r .03

/*
inputs:
Congenital Syphilis Study-Post-acute direct costs-20231204.xlsx
P_Data_Extract_From_World_Development_Indicators-LCU per international $.xlsx 
wdi_forex.dta created in: make_acute_costs_2019_USD.do 
wdi_gdp_deflators.dta created in: make_acute_costs_2019_USD.do 
2019_pcgdp.dta created in: make_2019_pcgdp.do 
pcgdp_series.dta created in: make_pcgdp_series.do 
raw_life_tables.dta created in: make_raw_life_tables.do
outputs:
pcgdp_trajectory_birth_cohort.dta
single_age_hearing_loss_costs_w_life_tables.dta
lifetime_expected_hearing_loss_cost_truncated.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////////////////////// read in the direct costs /////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/DIRECT COSTS/Congenital Syphilis Study-Post-acute direct costs-20231204.xlsx", ///
clear first sheet("WHO hearing loss Tables 5&6") case(lower) cellrange(A1:G29)
replace location_type = strtrim(location_type)
keep if location_type=="country"
 
drop location_type prevalence cost_a
assert currency=="2015 int$"
ren location country 

qui tab country 
di "There are `r(r)' donor countries" 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_costs_donors_raw", replace

////////////////////////////////////////////////////////////////////////////////
///////////////// get the LCUs per Int$ rates from the WDI data ////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/WDI/P_Data_Extract_From_World_Development_Indicators-LCU per international $.xlsx", ///
clear first sheet("Data") case(lower) cellrange(A1:L218)
assert seriesname=="PPP conversion factor, GDP (LCU per international $)"
keep countryname yr*
ren countryname country
replace country="Iran" if country =="Iran, Islamic Rep."
replace country="South Korea" if country =="Korea, Rep."
replace country="Russia" if country =="Russian Federation"

keep country yr2015
ren yr2015 ppp_2015
replace ppp_2015 = "" if ppp_2015==".."
destring ppp_2015, replace

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_costs_donors_raw"
assert _m!=2 
keep if _m==3 
drop _m 
sort country age 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////////////// get the 2019 forex from WDI //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\FOREX\wdi_forex", clear 
keep country yr2019
ren yr2019 forex_2019

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_forex_deflators"
assert _m!=2 
keep if _m==3 
drop _m 
sort country age 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////////// get GDP deflators from WDI data /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\wdi_gdp_deflators", clear
keep country yr2015 yr2019 
foreach y in 2015 2019 {
	ren yr`y' deflator_`y'
}

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_forex_deflators"
assert _m!=2 
keep if _m==3 
drop _m 
sort country age 
keep country deflator_2015 deflator_2019 forex_2019 ppp_2015 age currency cost_case_a

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////// convert baseyear Int$ to LCUs ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_forex_deflators", clear
replace cost_case_a = cost_case_a*ppp_2015

////////////////////////////////////////////////////////////////////////////////
///////// convert baseyear LCUs to 2019 LCUs using local GDP deflator //////////
////////////////////////////////////////////////////////////////////////////////

gen inflation_adj = deflator_2019/deflator_2015
sum inflation_adj , d 

gen hearing_loss_cost_2019_LCU = cost_case_a*inflation_adj
drop deflator* cost_case_a inflation_adj currency ppp_2015

////////////////////////////////////////////////////////////////////////////////
////////////////////// convert 2019 LCUs to 2019 USDs //////////////////////////
////////////////////////////////////////////////////////////////////////////////

gen hearing_loss_cost_2019_USD = hearing_loss_cost_2019_LCU/forex_2019
drop hearing_loss_cost_2019_LCU forex_2019 

assert hearing_loss_cost_2019_USD<.
sort country age 

qui tab country 
di "There are `r(r)' donor countries" 

gen donor=1 , before(country)
gen healthstate="hearing loss", before(donor)
gen duration="annual" 
gen incremental="yes"

replace country = "Russian Federation" if country=="Russia"

replace age = "0_17" if age=="0-17"
replace age = "ge_15" if age=="15+"
ren hearing_loss_cost_2019_USD hearing_loss_cost_2019_USD_ 
reshape wide hearing_loss_cost_2019_USD_ , i(country donor healthstate incremental duration) j(age) string
count 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_costs_donors_2019_USD", replace

////////////////////////////////////////////////////////////////////////////////
// map 2019 PCGDP from all IHME countries to direct costs for donor countries //
////////////////////////////////////////////////////////////////////////////////

use  "$output\ECONOMIC DATA\2019_pcgdp", clear 
ren yr2019_pcgdp_current_2019USD pcgdp2019usd

merge 1:1 country using "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_costs_donors_2019_USD"
assert _m !=2 
replace donor=0 if _m==1
drop _m

order healthstate donor country pcgdp2019usd hearing_loss_cost_2019_USD* duration incremental
sort  healthstate country 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_costs_donors_&_target_countries", replace

////////////////////////////////////////////////////////////////////////////////
//////// compute the percent pcgdp of direct costs for hearing loss ////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\hearing_loss_costs_donors_&_target_countries", clear
keep if donor==1 
gen pct_pcgdp_0_17 = hearing_loss_cost_2019_USD_0_17/pcgdp2019usd
gen pct_pcgdp_ge_15 = hearing_loss_cost_2019_USD_ge_15/pcgdp2019usd

order healthstate country pcgdp2019usd hearing_loss_cost_2019_USD_0_17 hearing_loss_cost_2019_USD_ge_15 ///
pct_pcgdp_0_17 pct_pcgdp_ge_15 duration incremental WHO_region income
sort healthstate country
egen med_pct_0_17 = median(pct_pcgdp_0_17)
egen med_pct_ge_15 = median(pct_pcgdp_ge_15)
list med_pct_0_17 med_pct_ge_15 in 1

keep med_pct_0_17 med_pct_ge_15
duplicates drop 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\median_hearing_loss_costs", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////// expand pcgdp series to singles ages //////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\pcgdp_series", clear 
drop who_region income_group_1
isid country year 

gen age = 0, before(pcgdp)
expand 100 
sort country year 
by country year: replace age = age[_n-1] + 1 if _n>1
by country year: assert age==99 if _n==_N 

isid country year age 
order country year age 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\pcgdp_series_single_ages", replace

////////////////////////////////////////////////////////////////////////////////
////// create lifetime trajectories of pcgdp for births from 2022 to 2064 /////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\ECONOMIC DATA\DIRECT COSTS\pcgdp_trajectory_birth_cohort.dta"
save          "$output\ECONOMIC DATA\DIRECT COSTS\pcgdp_trajectory_birth_cohort.dta", replace emptyok

capture prog drop birth_pcgdp
prog birth_pcgdp
version 18.0 
set more off
set type double
args cohort 

use  "$output\ECONOMIC DATA\DIRECT COSTS\pcgdp_series_single_ages", clear 

gen keepme=. 
replace keepme = 1 if age==	0 & year==`cohort'

forvalues a = 1/100 {
	qui replace keepme = 1 if age==	`a' & year==`cohort' + `a'
}

keep if keepme==1 
drop keepme
gen birth_year=`cohort'

gen expand=0 
sort country birth_year age
by   country birth_year: replace expand = 100-age if _n==_N 
expand expand 

sort country birth_year age
by   country birth_year: replace age = age[_n-1] + 1 if expand == 100-age & year==2064 & birth_year<2064
by   country birth_year: replace age = age[_n-1] + 1 if birth_year==2064 & _n>1
by   country birth_year: assert age==99 if _n==_N

drop expand 

append using "$output\ECONOMIC DATA\DIRECT COSTS\pcgdp_trajectory_birth_cohort.dta"
sort country birth_year age
order country birth_year age
save         "$output\ECONOMIC DATA\DIRECT COSTS\pcgdp_trajectory_birth_cohort.dta", replace 

end 

forvalues b = 2030/2064 {
	birth_pcgdp `b'
}

////////////////////////////////////////////////////////////////////////////////
//////// map cost % pcgdp to age-specific pcgdp series and compute costs ///////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\median_hearing_loss_costs", clear 

append using "$output\ECONOMIC DATA\DIRECT COSTS\pcgdp_trajectory_birth_cohort.dta"

foreach m in med_pct_0_17 med_pct_ge_15 {
	replace `m' = `m'[_n-1] if _n>1 & `m'==.
}

drop if country==""
isid country birth_year age 
sort country birth_year age 

gen cost_hearing_loss=. 
replace cost_hearing_loss = pcgdp*med_pct_0_17 if age<=17 
replace cost_hearing_loss = pcgdp*med_pct_ge_15 if age>17

drop med_* pcgdp year 
ren birth_year year

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\single_age_hearing_loss_costs", replace

////////////////////////////////////////////////////////////////////////////////
/////////////////// map single-age costs to lifetables /////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\LIFE TABLES\raw_life_tables", clear 
keep country year age L survivors_l
merge 1:1 country year age using "$output\ECONOMIC DATA\DIRECT COSTS\single_age_hearing_loss_costs"
assert _m!=2
keep if _m==3 
drop _m 
sort country year age 
order country year age cost_hearing_loss L survivors_l

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\single_age_hearing_loss_costs_w_life_tables", replace 

////////////////////////////////////////////////////////////////////////////////
///////////// compute expected lifetime medical costs for hearing loss /////////
////////////////////////////////////////////////////////////////////////////////

clear 
capture erase "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated" 
save          "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated" , emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\ECONOMIC DATA\DIRECT COSTS\single_age_hearing_loss_costs_w_life_tables", clear 

keep if year==`year'
sort country year age

drop if age > (2080-year)

forvalues x = 0/0 {
	gen L_`x'=L
}

forvalues x = 0/0 {
	replace L_`x'=. if age<`x'
}

forvalues x = 0/0 {
	gen med_cost_`x'=cost_hearing_loss
}

forvalues x = 0/0 {
	replace med_cost_`x'=. if age<`x'
}

forvalues x = 0/0 {
	replace L_`x' = L_`x'*med_cost_`x'
}

forvalues x = 0/0 {
	drop med_cost_`x'
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

drop survivors_l L L_* T_* LE_* cost_hearing_loss
ren LE cost

keep if age==0

compress 

append using "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated" 
sort country year age 
save         "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated"  , replace 

end

forvalues y = 2030/2064 {
	le `y'
}

use "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated" , clear 
assert age==0 
drop age 
gen healthstate="hearing loss"
gen duration="lifetime"
gen incremental="yes"
gen discounted=.03
order country year healthstate cost duration incremental discounted

save "$output\ECONOMIC DATA\DIRECT COSTS\lifetime_expected_hearing_loss_costs_truncated" , replace 

log close 

exit 

// end