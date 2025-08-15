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
log using "$output\MANUSCRIPT\make_gavi_country_table", text replace

/*
inputs:
gavi_status_2030.dta created in: make_gavi_status_2030.do 
outputs:
gavi_country_table.xlsx
*/

use "$output\ECONOMIC DATA\GNI\gavi_status_2030", clear
drop if inlist(country, "North Korea", "Syria")

sort country 

order country gavi_status_2024 pcgni_2030

export excel using "$output\MANUSCRIPT\gavi_country_table.xlsx", ///
first(var) sheet("stata") sheetreplace 

log close 

exit 

// end 