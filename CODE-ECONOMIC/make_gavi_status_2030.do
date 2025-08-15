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

/*
inputs:
P_Data_Extract_From_World_Development_Indicators-GNI.xlsx
ihme_country_list_syphilis_with_geo.dta created in: make_ihme_country_list_syphilis.do 
wdi_pcgdp_geometric_mean_constant_lcu.dta created in: make_pcgdp_series.do 
imf_pcgdp_geometric_mean_constant_lcu.dta created in: make_pcgdp_series.do
gavi_eligible_countries.dta created in: make_gavi_eligible_countries.do 
P_Data_Extract_From_World_Development_Indicators-PCGDP constant USDs & constant LCUs.xlsx
imf_pcgdp_series_raw.dta created in: make_pcgdp_series.do  
outputs:
gavi_status_2030.dta 
*/

capture log close 
log using "$output\ECONOMIC DATA\GNI\make_gavi_status_2030", text replace

////////////////////////////////////////////////////////////////////////////////
/////////////////////// get gni per capita from WDI ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\WDI\P_Data_Extract_From_World_Development_Indicators-GNI.xlsx", clear sheet("import") first case(lower)

compress
keep if inlist(seriesnam,"GNI per capita, Atlas method (current US$)","GNI per capita (current LCU)","GNI per capita (constant 2015 US$)","GNI per capita (constant LCU)")

gen series="" , before(seriesname)
replace series = "current_lcu" if seriesname=="GNI per capita (current LCU)"
replace series = "current_usd" if seriesname=="GNI per capita, Atlas method (current US$)"
replace series = "constant_lcu" if seriesname=="GNI per capita (constant LCU)"
replace series = "constant_2015_usd" if seriesname=="GNI per capita (constant 2015 US$)"
tab seriesname series, m

tab seriesname series, m

drop countrycode seriesname seriescode 
ren countryname country

forvalues y = 1989/2022 {
	replace yr`y'="" if yr`y'==".."
}

forvalues y = 1989/2022 {
	destring yr`y', replace 
}

qui tab country, m 
di "There are `r(r)' countries"

replace country = "Syria" if country=="Syrian Arab Republic"
replace country = "Faeroe Islands" if country=="Faroe Islands"
replace country = "Congo" if country=="Congo, Rep."
replace country = "Brunei" if country=="Brunei Darussalam"
replace country = "Cape Verde" if country=="Cabo Verde"
replace country = "Democratic Republic of the Congo" if country=="Congo, Dem. Rep."
replace country = "Egypt" if regexm(country,"Egypt")
replace country = "Hong Kong" if regexm(country,"Hong Kong")
replace country = "Iran" if regexm(country,"Iran, Islamic Rep.")
replace country = "South Korea" if country=="Korea, Rep."
replace country = "Kyrgyzstan" if country=="Kyrgyz Republic"
replace country = "Laos" if country=="Lao PDR"
replace country = "Macao" if regexm(country,"Macao")
replace country = "Federated States of Micronesia" if regexm(country,"Micronesia")
replace country = "Slovakia" if country=="Slovak Republic"
replace country = "Saint Kitts and Nevis" if country=="St. Kitts and Nevis"
replace country = "Saint Lucia" if country=="St. Lucia"
replace country = "Saint Vincent and the Grenadines" if country=="St. Vincent and the Grenadines"
replace country = "Turkey" if country=="Turkiye"
replace country = "Yemen" if country=="Yemen, Rep."
replace country = "Palestine" if country=="West Bank and Gaza"
replace country = "Czech Republic" if country=="Czechia"
replace country = "Macedonia" if country=="North Macedonia"
replace country = "Swaziland" if country=="Eswatini"
replace country = "The Bahamas" if country=="Bahamas, The"
replace country = "The Gambia" if country=="Gambia, The"
replace country = "North Korea" if country=="Korea, Dem. People's Rep."
replace country = "Venezuela" if country=="Venezuela, RB"
replace country = "Vietnam" if country=="Viet Nam"

save "$output\ECONOMIC DATA\GNI\gnipc_all_countries", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// filter gnipc series to the study countries //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\GNI\gnipc_all_countries", clear 
merge m:1 country using  "$output\IHME\SYPHILIS\ihme_country_list_syphilis_with_geo", keepusing(country)

assert country == "Taiwan" if _m == 2 
drop if _m ==1 
drop _m 
sort country 
order country

qui tab country 
di "There are `r(r)' study countries"

compress 
save "$output\ECONOMIC DATA\GNI\gnipc_study_countries", replace

////////////////////////////////////////////////////////////////////////////////
///////////////////////// get pcgni in current 2022 USD ////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\GNI\gnipc_study_countries", clear 
keep if series=="current_usd"
// extrapolate the 2021, 2020, or 2019 pcgni to countries with missing 2022 data 
replace yr2022 = yr2021 if yr2022==.  & yr2021 <.
replace yr2022 = yr2020 if yr2022==.  & yr2021 ==. & yr2020 <.
replace yr2022 = yr2019 if yr2022==.  & yr2021 ==. & yr2020 ==. & yr2019<.
keep country yr2022

count 

compress 
save "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs", replace

////////////////////////////////////////////////////////////////////////////////
//////////////// map on the geometric mean of pcgdp growth /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\imf_pcgdp_geometric_mean_constant_lcu",clear 
keep country geo_mean
ren geo_mean imf_geo_mean 

merge 1:1 country using "$output\ECONOMIC DATA\wdi_pcgdp_geometric_mean_constant_lcu", keepusing(country geo_mean)
sort country 
isid country 

replace geo_mean = imf_geo_mean if geo_mean==. & imf_geo_mean<.
drop _m imf_geo_mean

count 

merge 1:1 country using "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs"
sort country 
list if _m<3 

drop _m 
count 

compress 
save "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs", replace

////////////////////////////////////////////////////////////////////////////////
///////////////// map on the current gavi-eligibility status ///////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\gavi_eligible_countries", clear 
merge 1:1 country using "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs"
assert _m!=1 
drop _m 
sort country 
ren gavi_eligibility gavi_status

compress 
save "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs", replace

////////////////////////////////////////////////////////////////////////////////
////////////////// get the gavi countries with missing yr2022 pcgni ////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs", clear 
keep if gavi_status !=""
keep if yr2022==. 
drop yr2022
list , sep(0)

/*
South Sudan and Yemen have a growth rate <1; thus, we can assume their 
Gavi-status will not change between 2022 and 2024.
North Korea is not a study country.
*/

////////////////////////////////////////////////////////////////////////////////
////////////// get all available pcgni and pcgdp data for Eritrea //////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\GNI\gnipc_study_countries", clear 
keep if country=="Eritrea"

order country series

egen numyears = rownonmiss(yr1989 yr1990 yr1991 yr1992 yr1993 yr1994 yr1995 yr1996 yr1997 yr1998 yr1999 yr2000 yr2001 yr2002 yr2003 yr2004 yr2005 yr2006 yr2007 yr2008 yr2009 yr2010 yr2011 yr2012 yr2013 yr2014 yr2015 yr2016 yr2017 yr2018 yr2019 yr2020 yr2021 yr2022)
drop if numyears==0 
drop numyears 

egen numyears = rowtotal(yr1989 yr1990 yr1991 yr1992 yr1993 yr1994 yr1995 yr1996 yr1997 yr1998 yr1999 yr2000 yr2001 yr2002 yr2003 yr2004 yr2005 yr2006 yr2007 yr2008 yr2009 yr2010 yr2011 yr2012 yr2013 yr2014 yr2015 yr2016 yr2017 yr2018 yr2019 yr2020 yr2021 yr2022)

drop if numyears==0 
drop numyears 

reshape long yr, i(country series) j(year)
ren yr pcgni

drop if pcgni==. 

collapse (mean) pcgni , by(country series)

compress 
save "$output\ECONOMIC DATA\GNI\wdi_mean_pcgni_Eritrea", replace 


import excel using ///
"$raw\WDI\P_Data_Extract_From_World_Development_Indicators-PCGDP constant USDs & constant LCUs.xlsx", ///
clear sheet("Data") first case(lower)

ren countryname country
drop countrycode seriescode

keep if country == "Eritrea"

forvalues y = 1989/2022 {
	replace yr`y'="" if yr`y'==".."
} 

forvalues y = 1989/2022 {
	destring yr`y', replace
} 

egen numyears = rownonmiss(yr1989 yr1990 yr1991 yr1992 yr1993 yr1994 yr1995 yr1996 yr1997 yr1998 yr1999 yr2000 yr2001 yr2002 yr2003 yr2004 yr2005 yr2006 yr2007 yr2008 yr2009 yr2010 yr2011 yr2012 yr2013 yr2014 yr2015 yr2016 yr2017 yr2018 yr2019 yr2020 yr2021 yr2022)

drop if numyears==0 
drop numyears 

gen series="" , before(seriesname)
replace series = "constant_lcu" if seriesname=="GDP per capita (constant LCU)"
replace series = "constant_2015_usd" if seriesname=="GDP per capita (constant 2015 US$)"
tab seriesname series, m

drop seriesname

reshape long yr, i(country series) j(year)
ren yr pcgdp

drop if pcgdp==. 

collapse (mean) pcgdp , by(country series)

compress 

merge 1:1 country series using "$output\ECONOMIC DATA\GNI\wdi_mean_pcgni_Eritrea"
keep if _m==3 
drop _m 

compress 

save "$output\ECONOMIC DATA\GNI\wdi_mean_pcgni_mean_pcgdp_Eritrea", replace 

////////////////////////////////////////////////////////////////////////////////
//////////// construct yr2022 PCGNI in Eritrea using the ratio of //////////////
// mean pcgni and mean pcgdp in constant LCUs multiplied by pcgdp 2022 USDs  ///
//////////// available data for countries with missing yr2022 pcgni ////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\imf_pcgdp_series_raw", clear 
keep if country=="Eritrea"
keep if series == "current_usd"
keep country yr2022

merge 1:1 country using  "$output\ECONOMIC DATA\GNI\wdi_mean_pcgni_mean_pcgdp_Eritrea"
assert _m==3 
drop _m 

gen pcgni_2022USDs = yr2022*(pcgni/pcgdp)
keep country pcgni_2022USDs

merge 1:1 country using "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs"
replace yr2022 = pcgni_2022USDs if country=="Eritrea"
drop _m pcgni_2022USDs
sort country 

ren gavi_status gavi_status_2024

save "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs", replace 

////////////////////////////////////////////////////////////////////////////////
/////// use the geometric mean of pcgdp growth to project pcgni to 2030 ////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs", clear 

expand 9 

gen year=2022, before(yr2022)
sort country year 
by country: replace year = year[_n-1] + 1 if _n>1
sort country year 
by country: assert year==2030 if _n==_N 

gen pcgni=. 
by country: replace pcgni=yr2022 if _n==1
by country: replace pcgni=pcgni[_n-1]*geo_mean if _n>1
keep if year>=2028

by country: assert _N==3
by country: egen mean_pcgni = mean(pcgni)

keep if year==2030
order country gavi_status_2024 year mean_pcgni
keep  country gavi_status_2024 year mean_pcgni
compress 

ren mean_pcgni pcgni_2030 
drop year 

save "$output\ECONOMIC DATA\GNI\2030_pcgni_in_2022_USDs", replace 

////////////////////////////////////////////////////////////////////////////////
/// identify gavi-eligible status in 2030 based on a threshold of $1,730  //////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\GNI\2030_pcgni_in_2022_USDs", clear 

gen gavi_status_2030 =. 
replace gavi_status_2030 = 1 if pcgni_2030<=1730
replace gavi_status_2030 = 1 if gavi_status_2030 ==. & pcgni_2030==. & gavi_status_2024== "Initial self-financing"

keep if gavi_status_2030==1 

save "$output\ECONOMIC DATA\GNI\gavi_status_2030", replace 

log close 

exit 

// end