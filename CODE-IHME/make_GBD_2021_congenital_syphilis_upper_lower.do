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
early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022.dta created in: make_GBD_2021_congenital_syphilis.do 
late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022.dta created in: make_GBD_2021_congenital_syphilis.do 
late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022.dta created in: make_GBD_2021_congenital_syphilis.do 
outputs:
early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022_lower.dta 
early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022_upper.dta 
late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022_lower.dta 
late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022_upper.dta 
late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022_lower.dta 
late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022_upper.dta
*/

capture log close
log using "$output\IHME\GBD 2021\CS\make_GBD_2021_congenital_syphilis_upper_lower", text replace

////////////////////////////////////////////////////////////////////////////////
////////////////////// prepare data for analysis ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/////////////////// early_symptomatic_cs_infectious_syndrome ///////////////////

use "$raw\IHME\GBD 2021\CS\early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022", clear 

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite value upper 

replace measure = lower(measure)
ren lower value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit
compress 

save "$output\IHME\GBD 2021\CS\early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022_lower", replace 

use "$raw\IHME\GBD 2021\CS\early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022", clear 

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite value lower 

replace measure = lower(measure)
ren upper value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit
compress 

save "$output\IHME\GBD 2021\CS\early_symptomatic_cs_infectious_syndrome_incidence_prevalence_ylds_2019_2022_upper", replace 

/////////////////////////////////// neurosyphilis //////////////////////////////

use "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022", clear

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite value upper 

replace measure = lower(measure)
ren lower value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit
compress 

save "$output\IHME\GBD 2021\CS\late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022_lower", replace 

use "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022", clear

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite value lower 

replace measure = lower(measure)
ren upper value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit
compress 

save "$output\IHME\GBD 2021\CS\late_symptomatic_cs_neurosyphilis_prevalence_ylds_2019_2022_upper", replace 
 
////////////////////////// unilateral_hearing_loss /////////////////////////////

use "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022", clear 

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite value upper 

replace measure = lower(measure)
ren lower value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit

destring value_prevalence, replace 
destring value_ylds, replace

assert value_prevalence>0 & value_prevalence<. if value_ylds>0 & value_ylds<. & unit=="Number"

compress 

save "$output\IHME\GBD 2021\CS\late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022_lower", replace 

use "$raw\IHME\GBD 2021\CS\late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022", clear 

ren location country 
assert sex=="Both"
assert datasuite=="GBD"
drop sex datasuite value lower 

replace measure = lower(measure)
ren upper value_ 
reshape wide value_, i(country year age unit) j(measure) string 

order country year age unit

destring value_prevalence, replace 
destring value_ylds, replace

assert value_prevalence>0 & value_prevalence<. if value_ylds>0 & value_ylds<. & unit=="Number"

compress 

save "$output\IHME\GBD 2021\CS\late_symptomatic_cs_unilateral_hearing_loss_prevalence_ylds_2019_2022_upper", replace 

log close 

exit 

// end