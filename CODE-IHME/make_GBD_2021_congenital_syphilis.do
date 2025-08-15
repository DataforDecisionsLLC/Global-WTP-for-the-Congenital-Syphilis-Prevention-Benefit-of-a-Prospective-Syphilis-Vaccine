set more off
clear all
set type double
set excelxlsxlargefile on
version 18

/*
Instructions: Users need to replace "...." with the appropriate file path.
*/ 

gl root   "...."
gl raw    "$root\RAW DATA"
gl output "$root\OUTPUT"

/*
inputs:
Data Explorer - Data - Asymptomatic congenital syphilis - Incidence, Prevalence, YLDs - Number, Rate (per...  2024-04-02 17-22-22.xlsx
Data Explorer - Data - Early symptomatic congenital syphilis, infectious syndrome - Prevalence, Incidence,...  2024-04-03 12-16-01.xlsx
Data Explorer - Data - Early symptomatic congenital syphilis, slight disfigurement - Prevalence, YLDs, Incid...  2024-04-02 20-38-59.xlsx
Data Explorer - Data - Late symptomatic congenital syphilis, interstitial keratitis - YLDs, Prevalence - Num...  2024-04-02 18-48-01.xlsx
Data Explorer - Data - Late symptomatic congenital syphilis, neurosyphilis - YLDs, Prevalence - Number, Rate...  2024-04-02 18-22-12.xlsx
Data Explorer - Data - Late symptomatic congenital syphilis, slight disfigurement - Prevalence, YLDs - Rate...  2024-04-03 08-29-58.xlsx
Data Explorer - Data - Late symptomatic congenital syphilis, unilateral hearing loss - Prevalence, YLDs...  2024-06-24 18-43-34.xlsx
outputs:
asymptomatic_cs_incidence_prevalence_ylds_2019_2022.dta 
early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022.dta 
early_symptomatic_cs_slight_disfigurement_incidence_prevalence_ylds_2019_2022.dta 
late_symptomatic_cs_interstitial_keratitis_prevalence_ylds_2019_2022.dta 
late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022.dta 
late_symptomatic_cs_slight_disfigurement_prevalence_ylds_2019_2022.dta 
late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022.dta
*/

capture log close
log using "$output\IHME\GBD 2021\CS\make_GBD_2021_congenital_syphilis", text replace

////////////////////////////////////////////////////////////////////////////////
////////////////////// read in the raw IHME data ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/////////////////// 1.Asymptomatic congenital syphilis /////////////////////////

import excel using "$raw\IHME\GBD 2021\CS\Data Explorer - Data - Asymptomatic congenital syphilis - Incidence, Prevalence, YLDs - Number, Rate (per...  2024-04-02 17-22-22.xlsx", clear first case(lower) 

compress 
save "$raw\IHME\GBD 2021\CS\asymptomatic_cs_incidence_prevalence_ylds_2019_2022", replace 

/////// 2. Early symptomatic congenital syphilis, infectious syndrome //////////

import excel using "$raw\IHME\GBD 2021\CS\Data Explorer - Data - Early symptomatic congenital syphilis, infectious syndrome - Prevalence, Incidence,...  2024-04-03 12-16-01.xlsx", clear first case(lower) 

compress 
save "$raw\IHME\GBD 2021\CS\early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022", replace 

/////// 3. Early symptomatic congenital syphilis, slight disfigurement /////////

import excel using "$raw\IHME\GBD 2021\CS\Data Explorer - Data - Early symptomatic congenital syphilis, slight disfigurement - Prevalence, YLDs, Incid...  2024-04-02 20-38-59.xlsx", clear first case(lower) 

compress 
save "$raw\IHME\GBD 2021\CS\early_symptomatic_cs_slight_disfigurement_incidence_prevalence_ylds_2019_2022", replace 

/////// 4. Late symptomatic congenital syphilis, interstitial keratitis ////////

import excel using "$raw\IHME\GBD 2021\CS\Data Explorer - Data - Late symptomatic congenital syphilis, interstitial keratitis - YLDs, Prevalence - Num...  2024-04-02 18-48-01.xlsx", clear first case(lower)

compress 
save "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_interstitial_keratitis_prevalence_ylds_2019_2022", replace

////////// 5. Late symptomatic congenital syphilis, neurosyphilis //////////////

import excel using "$raw\IHME\GBD 2021\CS\Data Explorer - Data - Late symptomatic congenital syphilis, neurosyphilis - YLDs, Prevalence - Number, Rate...  2024-04-02 18-22-12.xlsx", clear first case(lower)

compress 
save "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022", replace

////////// 6. Late symptomatic congenital syphilis, slight disfigurement //////////

import excel using "$raw\IHME\GBD 2021\CS\Data Explorer - Data - Late symptomatic congenital syphilis, slight disfigurement - Prevalence, YLDs - Rate...  2024-04-03 08-29-58.xlsx", clear first case(lower) 

compress 
save "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_slight_disfigurement_prevalence_ylds_2019_2022", replace

//////// 7. Late symptomatic congenital syphilis, unilateral hearing loss //////

import excel using "$raw\IHME\GBD 2021\CS\Data Explorer - Data - Late symptomatic congenital syphilis, unilateral hearing loss - Prevalence, YLDs...  2024-06-24 18-43-34.xlsx", clear first case(lower) 

compress 
save "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022", replace

////////////////////////////////////////////////////////////////////////////////
////////////////////// prepare data for analysis ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$raw\IHME\GBD 2021\CS\asymptomatic_cs_incidence_prevalence_ylds_2019_2022", clear 

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite lower upper 

replace measure = lower(measure)
ren value value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit

compress 

save "$output\IHME\GBD 2021\CS\asymptomatic_cs_incidence_prevalence_ylds_2019_2022", replace 

////////////////////////////////////////////////////////////////////////////////

use "$raw\IHME\GBD 2021\CS\early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022", clear 

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite lower upper 

replace measure = lower(measure)
ren value value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit
compress 

save "$output\IHME\GBD 2021\CS\early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022", replace 

////////////////////////////////////////////////////////////////////////////////

use "$raw\IHME\GBD 2021\CS\early_symptomatic_cs_slight_disfigurement_incidence_prevalence_ylds_2019_2022", clear

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite lower upper 

replace measure = lower(measure)
ren value value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit
compress 

save "$output\IHME\GBD 2021\CS\early_symptomatic_cs_slight_disfigurement_incidence_prevalence_ylds_2019_2022", replace 

////////////////////////////////////////////////////////////////////////////////

use "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_interstitial_keratitis_prevalence_ylds_2019_2022", clear 

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite lower upper 

replace measure = lower(measure)
ren value value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit
compress 

save "$output\IHME\GBD 2021\CS\late_symptomatic_cs_interstitial_keratitis_prevalence_ylds_2019_2022", replace 

////////////////////////////////////////////////////////////////////////////////

use "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022", clear

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite lower upper 

replace measure = lower(measure)
ren value value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit
compress 

save "$output\IHME\GBD 2021\CS\late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022", replace 

//////////////////////////////////////////////////////////////////////////////// 

use "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_slight_disfigurement_prevalence_ylds_2019_2022", clear

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite lower upper 

replace measure = lower(measure)
ren value value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit
compress 

save "$output\IHME\GBD 2021\CS\late_symptomatic_cs_slight_disfigurement_prevalence_ylds_2019_2022", replace 

//////////////////////////////////////////////////////////////////////////////// 

use "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022", clear 

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite lower upper 

replace measure = lower(measure)
ren value value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit

destring value_prevalence, replace 
destring value_ylds, replace

assert value_prevalence>0 & value_prevalence<. if value_ylds>0 & value_ylds<. & unit=="Number"

compress 

save "$output\IHME\GBD 2021\CS\late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022", replace 

log close 

exit 

// end