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
log using "$output\ECONOMIC DATA\INDIRECT COSTS\make_indirect_costs_cerebral_palsy", text replace

gl r .03

/*
inputs:
Congenital Syphilis Study-Indirect & intangible costs-2024-03-21.xlsx
wdi_forex.dta created in: make_acute_costs_series.do
fred_forex_euro.dta created in: make_acute_costs_series.do
wdi_gdp_deflators.dta created in: make_acute_costs_series.do
population_males_females_denmark.dta created in: make_population_males_females_denmark.do
raw_life_tables_australia_2019.dta created in: make_raw_life_tables_australia_2019.do
2019_pcgdp.dta created in: make_2019_pcgdp.do 
pcgdp_series.dta created in: make_pcgdp_series.do
outputs:
indirect_costs_cerebral_palsy.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////////////////////// read in the indirect costs ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/INDIRECT & INTANGIBLE COSTS/Congenital Syphilis Study-Indirect & intangible costs-2024-03-21.xlsx", ///
clear first sheet("INDIRECT COSTS") case(lower) cellrange(B1:K47)
keep if healthstate=="cerebral palsy"
keep if donor=="yes"
drop donor
ren discountedlifetimecostsonl discounted
ren costscoveredperspective notes

split currency, parse("")
ren currency1 year 
destring year, replace
drop currency 
ren currency2 currency

replace country = "United States" if country=="US" 
replace country = "United Kingdom" if country=="UK" 

order healthstate source country cost duration incremental discounted year currency

compress 
save "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// create a file of currencies for conversion //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors", clear 
keep country currency year
duplicates drop
sort country currency year
compress
save "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_currencies", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////// map on the forex and gdp deflators ///////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_currencies", clear 
drop if country=="Denmark"

merge m:1 country using "$output\FOREX\wdi_forex"
assert _m!=1 
keep if _m==3 
drop _m 

forvalues y = 2000/2022 {
	ren yr`y' forex_`y'
}

reshape long forex_, i(country currency year) j(forex)
sort country year 
gen keepme=0 
replace keepme=1 if year==forex 
replace keepme=1 if forex==2019 
keep if keepme==1 
drop keepme 
ren year currency_year 
reshape wide forex_, i(country currency currency_year) j(forex)
ren currency_year year 

compress 
save "$output\ECONOMIC DATA\INDIRECT COSTS\forex_deflators", replace

use  "$output\FOREX\fred_forex_euro", clear
drop forex_euro_2019 
keep if inlist(year,2000, 2019)
ren forex_euro forex_ 
gen country="Denmark"
gen currency_year=2000
gen currency="Euros"
reshape wide forex_, i(country currency currency_year) j(year) 
ren currency_year year 
append using "$output\ECONOMIC DATA\INDIRECT COSTS\forex_deflators" 
sort country 

gen forex=. , before(forex_2000)
replace forex=forex_2000 if forex_2000<.
replace forex=forex_2003 if forex_2003<.
replace forex=forex_2007 if forex_2007<.
replace forex=forex_2016 if forex_2016<.
keep country year currency forex forex_2019 

compress 
save "$output\ECONOMIC DATA\INDIRECT COSTS\forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
/////////////////// map on the GDP deflators from WDI data /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\forex_deflators", clear
merge m:1 country using "$output\ECONOMIC DATA\wdi_gdp_deflators"
assert _m!=1 
keep if _m==3 
drop _m 
sort country year

forvalues y = 2000/2022 {
	ren yr`y' deflator_`y'
}

reshape long deflator_, i(country currency year) j(deflator)
sort country year deflator 
gen keepme=0 
replace keepme=1 if year==deflator 
replace keepme=1 if deflator==2019 
keep if keepme==1 
drop keepme 

reshape wide deflator_, i(country currency year forex forex_2019) j(deflator)

gen deflator=. , before(deflator_2000)
replace deflator=deflator_2000 if deflator_2000<.
replace deflator=deflator_2003 if deflator_2003<.
replace deflator=deflator_2007 if deflator_2007<.
replace deflator=deflator_2016 if deflator_2016<.
keep country year currency forex forex_2019 deflator deflator_2019

compress 
save "$output\ECONOMIC DATA\INDIRECT COSTS\forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
///////////// map the currency conversion factors to the costs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors", clear

merge m:1 country currency year using "$output\ECONOMIC DATA\INDIRECT COSTS\forex_deflators"
assert _m==3 
drop _m 

order healthstate country cost duration incremental discounted

compress 
save "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_w_forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////// convert baseyear USDs to LCUs ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_w_forex_deflators", clear
replace cost = cost*forex if currency=="USD" & country!="United States"

////////////////////////////////////////////////////////////////////////////////
///////// convert baseyear LCUs to 2019 LCUs using local GDP deflator //////////
////////////////////////////////////////////////////////////////////////////////

gen inflation_adj = deflator_2019/deflator

levelsof year, local(year)
foreach y of local year {
	di "The currency year is `y'"
	tab country if year==`y'
	sum inflation_adj if year==`y'
}

gen cost_2019_LCU = cost*inflation_adj

drop deflator* cost forex inflation_adj

////////////////////////////////////////////////////////////////////////////////
////////////////////// convert 2019 LCUs to 2019 USDs //////////////////////////
////////////////////////////////////////////////////////////////////////////////

gen indirect_cost_2019_USD = cost_2019_LCU/forex_2019

drop year currency forex_2019 cost_2019_LCU

gen sex=""
replace sex = "male" if notes=="Table III. productivity costs, men"
replace sex = "female" if notes=="Table III. productivity costs, women"

order healthstate country indirect_cost_2019_USD

compress

save "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors_2019_USD", replace

////////////////////////////////////////////////////////////////////////////////
/// compute population-wtd average cost for Denmark across males and females ///
////////////////////////////////////////////////////////////////////////////////

use "$output\POPULATION\population_males_females_denmark", clear
keep if year==2019
reshape long pop, i(country year sex) j(age)
collapse (sum) pop, by(country year sex)
egen tot_pop=total(pop)
gen pop_wt = pop/tot_pop
keep country sex pop_wt

merge 1:m country sex using "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors_2019_USD"
keep if _m ==3 
drop _m 

egen cost=total(pop_wt*indirect_cost_2019_USD)
drop pop_wt sex indirect_cost_2019_USD
ren cost indirect_cost_2019_USD

order healthstate country indirect_cost_2019_USD duration discounted incremental notes
replace notes = "Table III. Total lifetime costs minus total health-care costs"
duplicates drop

append using "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors_2019_USD" 
drop if country=="Denmark" & inlist(sex,"male","female")
drop sex

sort country 

save "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors_2019_USD", replace

////////////////////////////////////////////////////////////////////////////////
// compute discounted present value of lifetime productivity costs: Australia //
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors_2019_USD", clear 
keep if country=="Australia" & duration=="annual"
gen year=2019
merge 1:m country year using "$output\LIFE TABLES\raw_life_tables_australia_2019", ///
keepusing(country year age L survivors_l)
assert _m==3
drop _m  

keep country year age indirect_cost_2019_USD L survivors_l
replace indirect_cost_2019_USD=0 if age<15
replace indirect_cost_2019_USD=0 if age>64

compress 
save "$output\ECONOMIC DATA\INDIRECT COSTS\cp_annual_productivity_costs_australia_w_life_tables", replace

clear 
capture erase "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_cp_australia" 
save          "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_cp_australia"  , emptyok replace 

capture program drop le 
program le 
version 18.0
set more off
set type double 
args year

use "$output\ECONOMIC DATA\INDIRECT COSTS\cp_annual_productivity_costs_australia_w_life_tables", clear 

keep if year==`year'
sort country year age

forvalues x = 0/0 {
	gen L_`x'=L
}

forvalues x = 0/0 {
	replace L_`x'=. if age<`x'
}

forvalues x = 0/0 {
	gen indirect_cost_`x'=indirect_cost_2019_USD
}

forvalues x = 0/0 {
	replace indirect_cost_`x'=. if age<`x'
}

forvalues x = 0/0 {
	replace L_`x' = L_`x'*indirect_cost_`x'
}

forvalues x = 0/0 {
	drop indirect_cost_`x'
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

drop survivors_l L L_* T_* LE_* indirect_cost_2019_USD
ren LE cost

keep if age==0

compress 

append using "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_cp_australia"  
sort country year age 
save         "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_cp_australia"  , replace 

end

le 2019

use "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_cp_australia" , clear
drop age year 
ren cost indirect_cost_2019_USD
gen healthstate="cerebral palsy"
gen duration="lifetime"
gen discounted = .0155
gen incremental = "yes"
gen notes = "Average lifetime expected discounted labor market cost per patient"
gen source = "Access economics 2008"

append using "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors_2019_USD"
drop if duration=="annual"
drop if country=="Australia" & source=="Tonmukayakui et al 2018"
sort country duration 
compress 
save "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors_2019_USD" , replace 

////////////////////////////////////////////////////////////////////////////////
/// adjust lifetime costs in US downward to exclude lost productivity due to ///
// premature death based on fatal and non-fatal cost proportions in Australia //
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors_2019_USD", clear
keep if country=="Australia"
keep country indirect_cost_2019_USD notes 
gen prod=""
replace prod="nonfatal" if notes=="Average lifetime expected discounted labor market cost per patient"
replace prod="fatal" if regexm(notes,"premature death") 
drop notes 
egen tot_cost=total(indirect_cost_2019_USD)
gen cost_share=indirect_cost_2019_USD/tot_cost 
egen check=total(cost_share)
list check
drop check 
keep if prod=="nonfatal"
ren cost_share non_fatal_share 
keep non_fatal_share 

append using "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_donors_2019_USD"
replace non_fatal_share  = non_fatal_share[_n-1] if _n>1 & non_fatal_share ==.
drop if country==""
replace indirect_cost_2019_USD = indirect_cost_2019_USD*non_fatal_share if country=="United States"

drop if country=="Australia" &  regexm(notes,"premature death") 
compress 

save "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_nonfatal_costs_donors_2019_USD" , replace 

////////////////////////////////////////////////////////////////////////////////
///////////////////////////////// map 2019 PCGDP ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\ECONOMIC DATA\2019_pcgdp", clear 
ren yr2019_pcgdp_current_2019USD pcgdp2019usd

merge 1:m country using "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_nonfatal_costs_donors_2019_USD"
assert _m !=2 
keep if _m==3 
drop _m 

order healthstate country pcgdp2019usd indirect_cost_2019_USD duration discounted incremental notes

sort country duration 
compress

save "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_nonfatal_costs_donors_2019_USD", replace

////////////////////////////////////////////////////////////////////////////////
/////////////// compute nonfatal costs as a percent of 2019 pcgdp //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_nonfatal_costs_donors_2019_USD", clear

gen pct_pcgdp = indirect_cost_2019_USD/pcgdp2019usd
order healthstate country pcgdp2019usd indirect_cost_2019_USD pct_pcgdp duration discounted incremental notes source
sort country source 

// compute the median percentage

egen med_pct_pcgdp = median(pct_pcgdp)

keep med_pct_pcgdp 
duplicates drop 
list 

save "$output\ECONOMIC DATA\INDIRECT COSTS\median_indirect_nonfatal_cost_cerebral_palsy", replace 

////////////////////////////////////////////////////////////////////////////////
///// map median percentage to the pcgdp series and compute indirect costs /////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\INDIRECT COSTS\median_indirect_nonfatal_cost_cerebral_palsy", clear 
append using "$output\ECONOMIC DATA\pcgdp_series"

replace med_pct_pcgdp = med_pct_pcgdp[_n-1] if _n>1 & med_pct_pcgdp==.

drop if country==""

gen indirect_costs_cerebral_palsy = med_pct_pcgdp*pcgdp

keep country year indirect_costs_cerebral_palsy 

sort country year 
qui tab country 
di "There are `r(r)' countries in the series"
// 189 countries

compress

save "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_cerebral_palsy", replace

log close 

exit 

// end