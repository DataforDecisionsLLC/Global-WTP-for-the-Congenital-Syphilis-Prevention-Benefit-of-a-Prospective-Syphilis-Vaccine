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
log using "$output\ECONOMIC DATA\DIRECT COSTS\make_who_choice_extrapolations", text replace

/*
inputs:
who_choice_2019USDs.dta created in: make_who_choice_2019USDs.do
outputs:
who_choice_extrapolations.dta 
*/

////////////////////////////////////////////////////////////////////////////////
///////////////////// get ihme countries not in WHO CHOICE /////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_2019USDs", clear
gen keepme=0 
replace keepme=1 if prim_hosp_2019USD==.
replace keepme=1 if tert_hosp_2019USD==.
keep if keepme==1 
keep has_data country pcgdp2019usd 
isid country 
sort country 
drop if pcgdp2019usd==.
count 

save "$output\ECONOMIC DATA\DIRECT COSTS\ihme_countries_not_in_who_choice", replace

////////////////////////////////////////////////////////////////////////////////
//////////////// combine donor and target countries ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_2019USDs", clear
keep if has_data==2 
keep has_data country pcgdp2019usd prim_hosp_2019USD tert_hosp_2019USD
replace has_data=1  
append using "$output\ECONOMIC DATA\DIRECT COSTS\ihme_countries_not_in_who_choice"
sort has_data country
gen needmatch=""
replace needmatch=country if has_data==0
egen index=group(needmatch)
gen keepme=0
replace keepme=1 if has_data==1 
assert pcgdp2019usd<.
order has_data country pcgdp2019usd prim_hosp_2019USD tert_hosp_2019USD needmatch index keepme
compress

save "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_matchpool", replace

////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// IMPUTATIONS ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

clear
capture erase "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_matches.dta"
save          "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_matches.dta", replace emptyok

////////////////////////////////////////////////////////////////////////////////
///////////// nn matching to donors by yr2019_pcgdp_current_2019USD ////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_matchpool" , clear

levelsof index, local(enn) 
foreach n of local enn {
	use "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_matchpool" , clear
	replace keepme=1 if index==`n'	
	keep if keepme==1
	drop keepme index

	sort has_data
	assert has_data==0 if _n==1 
	assert has_data==1 if _n>1
	gen index=_n
	replace index=index-1
	order index

	levelsof index, local(cty)
	foreach c of local cty {
		gen gdp_`c' = .
		replace gdp_`c' = pcgdp2019usd if index==`c' & has_data==1
	}

	replace gdp_0 = pcgdp2019usd[1]
	assert  gdp_0 == pcgdp2019usd if has_data==0

	levelsof index, local(cty)
	foreach c of local cty {
		gen diff_`c' = .
		replace diff_`c' = abs(gdp_0 - gdp_`c') if index==`c' & has_data==1
	}

	gen distance=.
	levelsof index, local(cty)
	foreach c of local cty {
		replace distance = diff_`c' if index==`c' & has_data==1
	}

	egen match = min(distance)
	gen keepme=0
	replace keepme=1 if has_data==0 | match == distance
	keep if keepme==1
	drop gdp_* diff_* index distance match keepme needmatch
	
	replace prim_hosp_2019USD=prim_hosp_2019USD[_n+1] if prim_hosp_2019USD==. & prim_hosp_2019USD[_n+1]<. & has_data==0 & has_data[_n+1]==1
	replace tert_hosp_2019USD=tert_hosp_2019USD[_n+1] if tert_hosp_2019USD==. & tert_hosp_2019USD[_n+1]<. & has_data==0 & has_data[_n+1]==1

	sort has_data
	gen ratio=pcgdp2019usd[1]/pcgdp2019usd[2]
	gen match=country[_n+1] if has_data==0
	keep if has_data==0	
	append using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_matches.dta",
	sort country 
	compress 
	save         "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_matches.dta", replace	
}

////////////////////////////////////////////////////////////////////////////////
///////////////////// examine the matches and ratios ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

use   "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_matches.dta", clear
sort country 
sum ratio, d

merge 1:1 has_data country pcgdp2019usd using "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_matchpool"
assert _m!=1 
assert has_data==0 if _m==3
drop _m 

isid country
count 

ren has_data donor
order donor match country ratio pcgdp2019usd prim_hosp_2019USD tert_hosp_2019USD

keep if donor ==0 
replace prim_hosp_2019USD=prim_hosp_2019USD*ratio 
replace tert_hosp_2019USD=tert_hosp_2019USD*ratio

assert prim_hosp_2019USD<. 
assert tert_hosp_2019USD<.

keep country pcgdp2019usd prim_hosp_2019USD tert_hosp_2019USD

sort country 
compress 
save "$output\ECONOMIC DATA\DIRECT COSTS\who_choice_extrapolations", replace

log close 

exit 

// end