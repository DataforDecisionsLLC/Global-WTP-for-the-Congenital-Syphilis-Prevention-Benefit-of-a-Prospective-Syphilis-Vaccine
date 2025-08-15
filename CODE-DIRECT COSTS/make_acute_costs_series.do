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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_acute_costs_series", text replace

/*
inputs:
Congenital Syphilis Study-Gross acute direct costs-20231116.xlsx
EXUSEU-import.xlsx
P_Data_Extract_From_World_Development_Indicators-forex CS direct costs.xlsx
P_Data_Extract_From_World_Development_Indicators-GDP deflators CS direct costs.xlsx
2019_pcgdp.dta created in: make_2019_pcgdp.do 
pcgdp_series.dta created in: make_pcgdp_series.do
nonABO_acute_costs_series.dta created in: make_nonABO_acute_costs_series.do
outputs:
wdi_forex.dta
fred_forex_euro.dta 
wdi_gdp_deflators.dta
median_gross_acute_costs.xlsx
acute_costs_series.dta
*/

////////////////////////////////////////////////////////////////////////////////
///////////////////////// read in the direct costs /////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/DIRECT COSTS/Congenital Syphilis Study-Gross acute direct costs-20231116.xlsx", ///
clear first sheet("GROSS ACUTE DIRECT COSTS") case(lower) cellrange(A2:M91)

keep if donor=="yes"
assert control_cost==. if incremental=="Not incremental"
assert control_cost<. if incremental=="Incremental"
keep donor lookup healthstate country pcgdp2019usd currency control_cost gross_acute_cost

split currency, parse("")
ren currency1 year 
destring year, replace
drop currency 
ren currency2 currency

replace country = "United States" if country=="US" 
replace country = "United Kingdom" if country=="UK" 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\direct_costs_donors_2019_USD", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// create a file of currencies for conversion //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\direct_costs_donors_2019_USD", clear 
keep country currency year
duplicates drop
sort country currency year
compress
save "$output\ECONOMIC DATA\DIRECT COSTS\cs_direct_cost_currencies", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////// get the U.S. / EURO forex from FRED ///////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/FOREX/EXUSEU-import.xlsx", ///
clear first case(lower) cellrange(A11:B251)

gen month=month(observation_date)
gen year=year(observation_date)
keep if month==12
drop observation_date month
ren exuseu forex_euro
gen forex_euro_2019=.
replace forex_euro_2019=forex_euro[_N]
assert forex_euro_2019==forex_euro if year ==2019
order year forex_euro forex_euro_2019
replace forex_euro = 1/forex_euro
replace forex_euro_2019 = 1/forex_euro_2019
compress
save "$output\FOREX\fred_forex_euro", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////////////// get forex from the WDI data ///////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/WDI/P_Data_Extract_From_World_Development_Indicators-forex CS direct costs.xlsx", ///
clear first sheet("Data") case(lower) cellrange(A1:AA210)
assert seriesname=="Official exchange rate (LCU per US$, period average)"
keep countryname yr*
ren countryname country
replace country="Iran" if country =="Iran, Islamic Rep."
replace country="South Korea" if country =="Korea, Rep."
replace country="Russia" if country =="Russian Federation"

forvalues y = 2000/2022 {
	replace yr`y'="" if yr`y'==".."
}

forvalues y = 2000/2022 {
	destring yr`y',replace
}

compress
save "$output\FOREX\wdi_forex", replace

use "$output\ECONOMIC DATA\DIRECT COSTS\cs_direct_cost_currencies", clear 
keep country 
duplicates drop 

merge 1:1 country using "$output\FOREX\wdi_forex"
assert _m!=1 
keep if _m==3 
drop _m 

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\cs_direct_cost_currencies"
assert _m==3 
drop _m 

order country year currency
sort country year 

forvalues y = 2000/2022 {
	ren yr`y' forex_`y'
}

drop if currency=="INT$"

reshape long forex_, i(country currency year) j(forex)
sort country year 
keep if year==forex 
drop forex
ren forex_ forex

// get the 2019 forex 

merge m:1 country using "$output\FOREX\wdi_forex", keepusing(country yr2019)
assert _m!=1 
keep if _m==3 
drop _m 
ren yr2019 forex_2019
sort country year 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////////// get GDP deflators from WDI data /////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw/WDI/P_Data_Extract_From_World_Development_Indicators-GDP deflators CS direct costs.xlsx", ///
clear first sheet("Data") case(lower) cellrange(A1:AA210)
assert seriesname=="GDP deflator (base year varies by country)"
keep countryname yr*
ren countryname country
replace country="Iran" if country =="Iran, Islamic Rep."
replace country="South Korea" if country =="Korea, Rep."
replace country="Russia" if country =="Russian Federation"

forvalues y = 2000/2022 {
	replace yr`y'="" if yr`y'==".."
}

forvalues y = 2000/2022 {
	destring yr`y',replace
}

compress
save "$output\ECONOMIC DATA\wdi_gdp_deflators", replace

use "$output\ECONOMIC DATA\DIRECT COSTS\cs_direct_cost_currencies", clear 
keep country 
duplicates drop 

merge 1:1 country using "$output\ECONOMIC DATA\wdi_gdp_deflators"
assert _m!=1 
keep if _m==3 
drop _m 

merge 1:m country using "$output\ECONOMIC DATA\DIRECT COSTS\cs_direct_cost_currencies"
assert _m==3 
drop _m 

order country year currency
sort country year 

forvalues y = 2000/2022 {
	ren yr`y' deflator_`y'
}

drop if currency=="INT$"

reshape long deflator_, i(country currency year) j(deflator)
sort country year 
keep if year==deflator 
drop deflator
ren deflator_ deflator

// get the 2019 deflator 

merge m:1 country using "$output\ECONOMIC DATA\wdi_gdp_deflators", keepusing(country yr2019)
assert _m!=1 
keep if _m==3 
drop _m 
ren yr2019 deflator_2019
sort country year 

// map to the forex file 

merge 1:1 country currency year using  "$output\ECONOMIC DATA\DIRECT COSTS\forex_deflators"
assert _m==3 
drop _m 
sort country year 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
///////////// map the currency conversion factors to the costs /////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\direct_costs_donors_2019_USD", clear

merge m:1 country currency year using "$output\ECONOMIC DATA\DIRECT COSTS\forex_deflators"
assert _m==3 
drop _m 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\cs_direct_costs_w_forex_deflators", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////// convert baseyear USDs to LCUs ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\cs_direct_costs_w_forex_deflators", clear

replace gross_acute_cost = gross_acute_cost*forex if currency=="USD" & country!="United States"
replace control_cost =  control_cost*forex        if currency=="USD" & country!="United States"

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

gen gross_acute_cost_2019_LCU = gross_acute_cost*inflation_adj
gen control_cost_2019_LCU = control_cost*inflation_adj

drop deflator* gross_acute_cost control_cost inflation_adj

////////////////////////////////////////////////////////////////////////////////
////////////////////// convert 2019 LCUs to 2019 USDs //////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach c in gross_acute control {
	gen `c'_cost_2019_USD = `c'_cost_2019_LCU/forex_2019
}

keep healthstate country gross_acute_cost_2019_USD control_cost_2019_USD lookup pcgdp2019usd
sort country healthstate  

assert gross_acute_cost_2019_USD<.
assert control_cost_2019_USD==. if inlist(country,"China","Iran","Brazil","Rwanda")
assert control_cost_2019_USD==. if lookup=="9_clinical_CS_US_2011_USD"

ren gross_acute_cost_2019_USD  gross_cost_2019_USD

gen duration = "acute"
gen donor=1

order donor healthstate country duration gross_cost_2019_USD control_cost_2019_USD lookup

compress

sort healthstate country 

save "$output\ECONOMIC DATA\DIRECT COSTS\gross_acute_costs_donors_2019_USD", replace

////////////////////////////////////////////////////////////////////////////////
// map 2019 PCGDP from all IHME countries to direct costs for donor countries //
////////////////////////////////////////////////////////////////////////////////

use  "$output\ECONOMIC DATA\2019_pcgdp", clear 
ren yr2019_pcgdp_current_2019USD pcgdp2019usd

merge 1:m country pcgdp2019usd using "$output\ECONOMIC DATA\DIRECT COSTS\gross_acute_costs_donors_2019_USD"
assert _m !=2 
replace donor=0 if _m==1
drop _m

order healthstate donor lookup country 
sort  healthstate country

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\gross_acute_costs_donors_&_target_countries", replace

////////////////////////////////////////////////////////////////////////////////
/////////////// compute the median percent pcgdp of direct costs ///////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\gross_acute_costs_donors_&_target_countries", clear
keep if donor==1 
gen pct_pcgdp = gross_cost_2019_USD/pcgdp2019usd
order healthstate country pcgdp2019usd gross_cost_2019_USD pct_pcgdp control_cost_2019_USD WHO_region income

sort healthstate country 
by healthstate: egen med_pct_pcgdp = median(pct_pcgdp)

export excel lookup country gross_cost_2019_USD pcgdp2019usd pct_pcgdp  med_pct_pcgdp using "$output\ECONOMIC DATA\DIRECT COSTS\median_gross_acute_costs.xlsx", first(var) sheet("stata") sheetreplace 

by healthstate: keep if _n==1

keep healthstate med_pct_pcgdp
list healthstate med_pct_pcgdp

replace healthstate="preterm" if healthstate=="LBW/preterm" 
replace healthstate="cs" if healthstate=="live born with clinical CS" 
replace healthstate="nd" if healthstate=="neonatal death" 

list 

ren med_pct_pcgdp med_pct_pcgdp_ 
gen eye = 1 
reshape wide med_pct_pcgdp_, i(eye) j(healthstate) string
drop eye 

compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\median_gross_acute_costs", replace 

////////////////////////////////////////////////////////////////////////////////
/////// map medians to the pcgdp series and compute direct costs ///////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\median_gross_acute_costs", clear 
append using "$output\ECONOMIC DATA\pcgdp_series"

foreach m in med_pct_pcgdp_cs med_pct_pcgdp_nd med_pct_pcgdp_preterm {
	replace `m' = `m'[_n-1] if _n>1 & `m'==.
}

drop if country==""

gen acute_cost_lbwpt = med_pct_pcgdp_preterm*pcgdp
gen acute_cost_cs = med_pct_pcgdp_cs*pcgdp
gen acute_cost_nd = med_pct_pcgdp_nd*pcgdp

keep country year acute_* 

merge 1:1 country year using "$output\ECONOMIC DATA\DIRECT COSTS\nonABO_acute_costs_series"
assert _m==3 
drop _m 
sort country year 

sort country year 
qui tab country 
di "There are `r(r)' countries in the series"
// 189 countries

// set acute stage cost of a stillbirth equal to the cost of a nonABO birth

gen acute_cost_stillbirth_15_19 = acute_cost_nonABO_15_19 
gen acute_cost_stillbirth_20_49 = acute_cost_nonABO_20_49

compress

save "$output\ECONOMIC DATA\DIRECT COSTS\acute_costs_series", replace

log close 

exit 

// end
