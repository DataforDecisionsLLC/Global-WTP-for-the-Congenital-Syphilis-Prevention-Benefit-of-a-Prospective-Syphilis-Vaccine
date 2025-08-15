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
log using "$output\LIFE TABLES\make_raw_life_tables_australia_2019", text replace

/*
inputs: 
LIFE TABLES\WPP2022_MORT_F06_1_SINGLE_AGE_LIFE_TABLE_ESTIMATES_BOTH_SEXES_import.xlsx
outputs:
raw_life_tables_australia_2019.dta
*/

////////////////////////////////////////////////////////////////////////////////
/////////////// read in UN single-age life tables 2015-2021 estimates //////////
////////////////////////////////////////////////////////////////////////////////

import excel using "$raw\LIFE TABLES\WPP2022_MORT_F06_1_SINGLE_AGE_LIFE_TABLE_ESTIMATES_BOTH_SEXES_import.xlsx", ///
clear sheet("Australia 2019") cellrange(C2:Q103)  first 
assert type=="Country/Area"
drop type
compress
save "$output\LIFE TABLES\raw_life_tables_australia_2019", replace 

log close 

exit 

// end