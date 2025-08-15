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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_pcgdp_series", text replace

/*
inputs:
P_Data_Extract_From_World_Development_Indicators-PCGDP_&_current_health_expenditures.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do
P_Data_Extract_From_World_Development_Indicators-PCGDP constant USDs & constant LCUs.xlsx
WEOOct2019all_import.xlsx
outputs:
pcgdp_series.dta 
*/

////////////////////////////////////////////////////////////////////////////////
/////////////////////// get the PCGDP series from the WDI //////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using ///
"$raw\WDI\P_Data_Extract_From_World_Development_Indicators-PCGDP_&_current_health_expenditures.xlsx", ///
clear sheet("Data") cellrange(A1:AL869) first case(lower)

keep if inlist(seriesname,"GDP per capita (current LCU)","GDP per capita (current US$)")
gen series="" , before(seriesname)
replace series = "current_lcu" if seriesname=="GDP per capita (current LCU)"
replace series = "current_usd" if seriesname=="GDP per capita (current US$)"
tab seriesname series, m

drop countrycode seriescode seriesname
ren countryname country

forvalues y = 1989/2022 {
	replace yr`y'="" if yr`y'==".."
} 

forvalues y = 1989/2022 {
	destring yr`y', replace
} 

compress

qui tab country, m 
di "There are `r(r)' countries"

replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "Faeroe Islands" if country=="Faroe Islands"
replace country = "Congo" if country=="Congo, Rep."
replace country = "Bahamas" if regexm(country,"Bahamas")
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Democratic Republic of Congo" if country=="Congo, Dem. Rep."
replace country = "Egypt" if regexm(country,"Egypt")
replace country = "Gambia" if regexm(country,"Gambia")
replace country = "Hong Kong" if regexm(country,"Hong Kong")
replace country = "Iran" if regexm(country,"Iran, Islamic Rep.")
replace country = "South Korea" if country=="Korea, Rep."
replace country = "North Korea" if country=="Korea, Dem. People's Rep."
replace country = "Kyrgyzstan" if country=="Kyrgyz Republic"
replace country = "Laos" if country=="Lao PDR"
replace country = "Macao" if regexm(country,"Macao")
replace country = "Micronesia (country)" if regexm(country,"Micronesia")
replace country = "Russia" if country=="Russian Federation"
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Saint Kitts and Nevis" if country=="St. Kitts and Nevis"
replace country = "Saint Lucia" if country=="St. Lucia"
replace country = "Saint Vincent and the Grenadines" if country=="St. Vincent and the Grenadines"
replace country = "Saint Martin" if country=="St. Martin (French part)"
replace country = "Turkey" if country=="Turkiye"
replace country = "Yemen" if country=="Yemen, Rep."
replace country = "Palestine" if country=="West Bank and Gaza"
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Czech Republic" if country=="Czechia"
replace country = "Democratic Republic of the Congo" if country=="Democratic Republic of Congo"
replace country = "Federated States of Micronesia" if country=="Micronesia (country)"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "Russian Federation" if country=="Russia"
replace country = "Swaziland" if country=="Eswatini"
replace country = "The Bahamas" if country=="Bahamas"
replace country = "The Gambia" if country=="Gambia"
replace country = "Vietnam" if country=="Viet Nam"

merge m:1 country using  "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert country == "Taiwan" if _m==2
keep if _m==3 
drop _m 

order country who_region income_group_1
isid country series 
qui tab country 
di "There are `r(r)' countries with WDI data"

compress 

save "$output\ECONOMIC DATA\wdi_pcgdp_series_raw", replace 


import excel using ///
"$raw\WDI\P_Data_Extract_From_World_Development_Indicators-PCGDP constant USDs & constant LCUs.xlsx", ///
clear sheet("Data") cellrange(A1:AL437) first case(lower)

gen series="" , before(seriesname)
replace series = "constant_lcu" if seriesname=="GDP per capita (constant LCU)"
replace series = "constant_2015_usd" if seriesname=="GDP per capita (constant 2015 US$)"
tab seriesname series, m

drop countrycode seriescode seriesname
ren countryname country

forvalues y = 1989/2022 {
	replace yr`y'="" if yr`y'==".."
} 

forvalues y = 1989/2022 {
	destring yr`y', replace
} 

compress

qui tab country, m 
di "There are `r(r)' countries"

replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "Faeroe Islands" if country=="Faroe Islands"
replace country = "Congo" if country=="Congo, Rep."
replace country = "Bahamas" if regexm(country,"Bahamas")
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Democratic Republic of Congo" if country=="Congo, Dem. Rep."
replace country = "Egypt" if regexm(country,"Egypt")
replace country = "Gambia" if regexm(country,"Gambia")
replace country = "Hong Kong" if regexm(country,"Hong Kong")
replace country = "Iran" if regexm(country,"Iran, Islamic Rep.")
replace country = "South Korea" if country=="Korea, Rep."
replace country = "North Korea" if country=="Korea, Dem. People's Rep."
replace country = "Kyrgyzstan" if country=="Kyrgyz Republic"
replace country = "Laos" if country=="Lao PDR"
replace country = "Macao" if regexm(country,"Macao")
replace country = "Micronesia (country)" if regexm(country,"Micronesia")
replace country = "Russia" if country=="Russian Federation"
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Saint Kitts and Nevis" if country=="St. Kitts and Nevis"
replace country = "Saint Lucia" if country=="St. Lucia"
replace country = "Saint Vincent and the Grenadines" if country=="St. Vincent and the Grenadines"
replace country = "Saint Martin" if country=="St. Martin (French part)"
replace country = "Turkey" if country=="Turkiye"
replace country = "Yemen" if country=="Yemen, Rep."
replace country = "Palestine" if country=="West Bank and Gaza"
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Czech Republic" if country=="Czechia"
replace country = "Democratic Republic of the Congo" if country=="Democratic Republic of Congo"
replace country = "Federated States of Micronesia" if country=="Micronesia (country)"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "Russian Federation" if country=="Russia"
replace country = "Swaziland" if country=="Eswatini"
replace country = "The Bahamas" if country=="Bahamas"
replace country = "The Gambia" if country=="Gambia"
replace country = "Vietnam" if country=="Viet Nam"

merge m:1 country using  "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert country == "Taiwan" if _m==2
keep if _m==3
drop _m 

order country who_region income_group_1

append using "$output\ECONOMIC DATA\wdi_pcgdp_series_raw"

order country who_region income_group_1
sort country series 
isid country series 
qui tab country 
di "There are `r(r)' countries with WDI data"

compress 
save "$output\ECONOMIC DATA\wdi_pcgdp_series_raw", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// drop country series with all missing data /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\wdi_pcgdp_series_raw", clear 
egen numyears = rownonmiss(yr1989 yr1990 yr1991 yr1992 yr1993 yr1994 yr1995 yr1996 yr1997 yr1998 yr1999 yr2000 yr2001 yr2002 yr2003 yr2004 yr2005 yr2006 yr2007 yr2008 yr2009 yr2010 yr2011 yr2012 yr2013 yr2014 yr2015 yr2016 yr2017 yr2018 yr2019 yr2020 yr2021 yr2022)
sort country series 
list country series if numyears==0, sepby(country) 

drop if numyears==0 
drop numyears 
qui tab country 
di "There are `r(r)' countries with WDI data"

compress 
save "$output\ECONOMIC DATA\wdi_pcgdp_series_raw", replace 

////////////////////////////////////////////////////////////////////////////////
////////////////// compute geometric mean using constant LCUs //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\wdi_pcgdp_series_raw", clear
keep if series=="constant_lcu" 
qui tab country 
di "There are `r(r)' countries with WDI data"
  
reshape long yr, i(country who_region income_group_1) j(pcgdp)
ren pcgdp year 
ren yr pcgdp  
drop if year>2019
drop if pcgdp==.

qui tab country 
di "There are `r(r)' countries with WDI data"

// confirm that each series is sequential 

sort country year 
gen flag=0 
by country : replace flag =1 if year != year[_n-1] + 1 & _n>1 
by country : gen run = sum(flag)
by country : egen look = max(flag==1)
drop if look==1 & run==0
drop flag look run 

sort country year 
by country : assert year ==year[_n-1] + 1 if _n>1 

qui tab country 
di "There are `r(r)' countries with WDI data"

compress 
gen growth=. 
sort country year 
by country: replace growth = pcgdp/pcgdp[_n-1] if _n>1

by country: drop if _n==1
assert growth<. 
gen geo_mean=.

levelsof country, local(country) 
foreach c of local country {
	ameans growth if country =="`c'"
	replace geo_mean = `r(mean_g)' if country =="`c'" 
}

by country: keep if _n==1 
keep country who_region income_group_1 geo_mean
compress 

count 

save  "$output\ECONOMIC DATA\wdi_pcgdp_geometric_mean_constant_lcu", replace

////////////////////////////////////////////////////////////////////////////////
// use the geometric mean of pcgdp growth to project pcgdp from 2030 to 2064 ///
////////////////////////////////////////////////////////////////////////////////

use  "$output\ECONOMIC DATA\wdi_pcgdp_series_raw", clear 
keep if series=="current_usd"
keep country yr2022
drop if yr2022==. 
count 

merge 1:1 country using "$output\ECONOMIC DATA\wdi_pcgdp_geometric_mean_constant_lcu"
keep if _m==3 
drop _m 
compress
sort country 
expand 43 

gen year=2022, before(yr2022)
sort country year 
by country: replace year = year[_n-1] + 1 if _n>1
sort country year 
by country: assert year==2064 if _n==_N 

gen pcgdp=. 
by country: replace pcgdp=yr2022 if _n==1
by country: replace pcgdp=pcgdp[_n-1]*geo_mean if _n>1

order country year pcgdp who_region income_group_1
keep country year pcgdp who_region income_group_1
compress 
save "$output\ECONOMIC DATA\wdi_pcgdp_series", replace 

////////////////////////////////////////////////////////////////////////////////
/////////////// get IMF data for countries with missing WDI data ///////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\ECONOMIC DATA\wdi_pcgdp_series_raw", clear 
keep if series=="current_usd"
keep country yr2022
keep if yr2022==. 
count 

keep country 
list, sep(0)

/*
1. countries not in database (Taiwan) 
2. countries in the database but with all missing data (North Korea)
3. countries with missing 2019 data: Eritrea, South Sudan, Venezuela
4. countries with everything except 2022 baseyear data for projections: Afghanistan, Bhutan, Cuba, Lebanon, Monaco, 
   Palau, San Marino, Syria, Tonga, Turkmenistan.     
*/

import excel using "$raw\IMF\WEOOct2019all_import.xlsx", ///
clear cellrange(A2:AP8732) first case(lower) sheet("1989-2024")

keep if regexm(subjectdescriptor, "Gross domestic product per capita")
keep if inlist(units,"National currency","U.S. dollars")

assert scale =="Units"
drop subjectnotes countryseriesspecificnotes scale 
compress

gen series="" , before(subjectdescriptor)
replace series = "current_lcu" if subjectdescriptor=="Gross domestic product per capita, current prices" & units == "National currency"
replace series = "current_usd" if subjectdescriptor=="Gross domestic product per capita, current prices" & units == "U.S. dollars"
replace series = "constant_lcu" if subjectdescriptor=="Gross domestic product per capita, constant prices" & units == "National currency"

drop subjectdescriptor units

replace country = "Taiwan" if regexm(country,"Taiwan")
tab country if regexm(country,"Korea")

gen keepme=0 
replace keepme=1 if inlist(country,"Taiwan","Eritrea","South Sudan","Venezuela")
replace keepme=1 if inlist(country,"Afghanistan", "Bhutan","Lebanon","Palau","San Marino","Tonga","Turkmenistan")
keep if keepme==1 
drop keepme

forvalues y=1989/2024 {
	replace year_`y'="" if year_`y'=="n/a"
}

forvalues y=1989/2024 {
	destring year_`y', replace
}

forvalues y=1989/2024 {
	ren year_`y' yr`y'
}

compress 

egen numyears = rownonmiss(yr1989 yr1990 yr1991 yr1992 yr1993 yr1994 yr1995 yr1996 yr1997 yr1998 yr1999 yr2000 yr2001 yr2002 yr2003 yr2004 yr2005 yr2006 yr2007 yr2008 yr2009 yr2010 yr2011 yr2012 yr2013 yr2014 yr2015 yr2016 yr2017 yr2018 yr2019 yr2020 yr2021 yr2022)
sort country series 
assert numyears>0
drop numyears

save "$output\ECONOMIC DATA\imf_pcgdp_series_raw", replace 

////////////////////////////////////////////////////////////////////////////////
///////////////////// compute geometric mean using constant LCUs ///////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\imf_pcgdp_series_raw", clear
keep if series=="constant_lcu" 
  
reshape long yr, i(country) j(year)
ren yr pcgdp 
drop if year>2019
drop if pcgdp==.

// confirm that each series is sequential 

sort country year 
by country : assert year ==year[_n-1] + 1 if _n>1 

compress 
gen growth=. 
sort country year 
by country: replace growth = pcgdp/pcgdp[_n-1] if _n>1
by country: drop if _n==1
assert growth<. 
gen geo_mean=.

levelsof country, local(country) 
foreach c of local country {
	ameans growth if country =="`c'"
	replace geo_mean = `r(mean_g)' if country =="`c'" 
}

by country: keep if _n==1 
keep country geo_mean
compress 

sum geo_mean, d

save  "$output\ECONOMIC DATA\imf_pcgdp_geometric_mean_constant_lcu", replace

////////////////////////////////////////////////////////////////////////////////
// use the geometric mean of pcgdp growth to project pcgdp from 2030 to 2064 ///
////////////////////////////////////////////////////////////////////////////////

use  "$output\ECONOMIC DATA\imf_pcgdp_series_raw", clear 
keep if series=="current_usd"
assert country =="Venezuela" if yr2022==. 
keep country yr2022
drop if yr2022==. 

merge 1:1 country using "$output\ECONOMIC DATA\imf_pcgdp_geometric_mean_constant_lcu"
assert country == "Venezuela" if _m==2
keep if _m==3 
drop _m 
compress
sort country 
expand 43 

gen year=2022, before(yr2022)
sort country year 
by country: replace year = year[_n-1] + 1 if _n>1
sort country year 
by country: assert year==2064 if _n==_N 

gen pcgdp=. 
by country: replace pcgdp=yr2022 if _n==1
by country: replace pcgdp=pcgdp[_n-1]*geo_mean if _n>1

order country year pcgdp 
keep country year pcgdp 
compress 
save "$output\ECONOMIC DATA\imf_pcgdp_series", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// map on the who region and income group classification /////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\imf_pcgdp_series", clear 

merge m:1 country using  "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country who_region income_group_1)
assert _m!=1
keep if _m==3 
drop _m 

sort country year 
order country year pcgdp who_region income_group_1
compress 
save "$output\ECONOMIC DATA\imf_pcgdp_series", replace 

////////////////////////////////////////////////////////////////////////////////
/////////////////////// combine the wdi and imf series /////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\imf_pcgdp_series", clear 
append using "$output\ECONOMIC DATA\wdi_pcgdp_series" 
sort country year 
isid country year
assert pcgdp <. 

qui tab country 
di "There are `r(r)' countries with WDI data"

count if inlist(country,"Cuba", "North Korea", "Venezuela", "Syria", "Monaco" )
assert r(N)==0

compress 
save  "$output\ECONOMIC DATA\pcgdp_series", replace 

log close 

exit 

// end