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
input:
geo_data.xlsx
outputs:
regions.dta
*/ 

capture log close
log using "$output\GEO DATA\make_regions", text replace

import excel using "$raw\GEO DATA\geo_data.xlsx", ///
clear sheet("geo_data") cellrange(A1:M220) first case(lower)

drop iso3code ldcs developeddeveloping

ren countryname country
ren unregions un_region
ren unsubregion un_subregion
ren unicefregion1 unicef_region
ren whoregion2 who_region
ren worldbankincomegroupcombined income_group_1
ren h income_group_2
ren worldbankregions world_bank_region
ren mdgregion mdg_region
ren sdgregion sdg_region

drop if mi(country)

compress
save "$output\GEO DATA\regions.dta", replace

log close

exit

// end