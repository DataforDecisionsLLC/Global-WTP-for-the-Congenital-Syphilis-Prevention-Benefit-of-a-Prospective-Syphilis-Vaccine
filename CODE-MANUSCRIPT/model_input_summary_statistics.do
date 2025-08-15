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
log using "$output\MANUSCRIPT\model_input_summary_statistics", text replace

/*
inputs:
probability_infected_vax_novax.dta created in: make_probability_infected_vax_novax.do 
daly_loss_case_preterm_2030_2064_truncated.dta created in: make_daly_loss_case_preterm_2030_2064_truncated.dta 
dalys_sb_nd_discounted.dta created in: make_dalys_sb_nd_discounted.do
daly_loss_case_early_symp_cs_2030_2064.dta created in: make_daly_loss_case_early_symp_cs_2030_2064.do 
daly_loss_case_late_symp_hl_2030_2064_truncated.dta created in: make_daly_loss_case_late_symp_hl_2030_2064_truncated.do 
daly_loss_case_late_symp_ns_2030_2064_truncated.dta created in: make_daly_loss_case_late_symp_ns_2030_2064_truncated.do 
probability_pregnant.dta created in: make_probability_pregnant.do 
analytical_data_ihme_countries_age15_cohort_truncated.dta created in: make_analytical_data_ihme_countries_age15_cohort_truncated.do 
probability_abo.dta created in: make_probability_abo.do 
acute_costs_series.dta created in: make_acute_costs_series.do 
post_acute_costs_series_truncated.dta created in: make_post_acute_costs_series_truncated.do
indirect_costs_cerebral_palsy.dta created in: make_indirect_costs_cerebral_palsy.do 
lifetime_expected_productivity_costs_hearing_loss_truncated.dta created in: make_lifetime_expected_indirect_costs_hearing_loss_truncated.do 
le_preterm_discounted.dta created in: make_daly_loss_case_preterm_2030_2064_truncated.do 
pcgdp_series.dta created in: make_pcgdp_series.do 
gnipc_study_countries_2022_USDs.dta created in: make_gavi_status_2030.do 
outputs:
model_input_summary_statistic.xlsx 
*/

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////// 2022 pcgni //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in pcgni_2022_USD {
	
	use "$output\ECONOMIC DATA\GNI\gnipc_study_countries_2022_USDs", clear 
	drop if inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")		
	ren yr2022 pcgni_2022_USD 

	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 

	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////// 2022 pcgdp //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in pcgdp_2022_USD  {
	
	use "$output\ECONOMIC DATA\pcgdp_series", clear
	assert !inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")		
	keep if year==2022
	ren pcgdp pcgdp_2022_USD 

	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 

	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
//////////////////////// discounted truncated life-expectancy //////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DALY\le_preterm_discounted", clear
keep if age ==0 
ren birth_year year 
drop age 

merge 1:1 country year using "$output\DALY\dalys_sb_nd_discounted", keepusing(country year stillbirth_dalys)
drop if year>2050 
assert _m==3 
drop _m 
sort country year 

gen check = le_discounted/stillbirth_dalys
sum check , d

use "$output\DALY\dalys_sb_nd_discounted", clear 
drop if inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")
drop neonatal_dalys

ren stillbirth_dalys le_discounted

foreach var in le_discounted {
	
	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 

	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
/////////////////////////// indirect costs costs ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in indirect_costs_neurosyph  {
	
	use "$output\ECONOMIC DATA\INDIRECT COSTS\indirect_costs_cerebral_palsy", clear
	assert !inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")		
	drop if year<2030
	ren indirect_costs_cerebral_palsy indirect_costs_neurosyph
	sort country year

	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 

	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

foreach var in indirect_costs_hearingloss  {
	
	use "$output\ECONOMIC DATA\INDIRECT COSTS\lifetime_expected_productivity_costs_hearing_loss_truncated" , clear
	assert !inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")		
	drop if year<2030
	
	keep country year prod_cost
	ren prod_cost indirect_costs_hearingloss
	sort country year

	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 

	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
//////////////////////// post-acute stage direct costs /////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in lifetime_cost_hearingloss lifetime_cost_lbwpt lifetime_cost_neurosyph lifetime_cost_nonABO {
	
	use "$output\ECONOMIC DATA\DIRECT COSTS\post_acute_costs_series_truncated", clear
	assert !inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")		

	sort country year

	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 

	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
//////////////////////// acute stage direct costs //////////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in acute_cost_lbwpt acute_cost_cs acute_cost_nd acute_cost_nonABO_15_19 acute_cost_nonABO_20_49 acute_cost_stillbirth_15_19 acute_cost_stillbirth_20_49 {
	
	use "$output\ECONOMIC DATA\DIRECT COSTS\acute_costs_series", clear 
	assert !inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")		
	keep if year==2030
	sort country year

	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 
	
	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
/////////////////////// probabilitities of ABOs ////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\probability_abo", clear 
	
reshape long prob_ , i(analysis) j(parameter) string
drop analysis 
ren prob_ mean_ 

append using "$output\MANUSCRIPT\model_input_summary_statistics"	

order parameter min_ max_ med_ mean_
compress 
save "$output\MANUSCRIPT\model_input_summary_statistics", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////// probabilitities of false positive test ////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in prob_false_neg {
	
	use "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear 
	assert !inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")
	
	collapse (min) min_`var' = `var' (max) max_`var' = `var' 
	
	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
//////////////// probabilitities of: ANC, testing & treatment //////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in prob_anc prob_testing prob_treatment {
	
	use "$output\DECISION TREE\BASE FILE\analytical_data_ihme_countries_age15_cohort_truncated", clear 
	assert !inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")
	
	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 
	
	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
//////////////////////// probability of pregnancy //////////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in prob_preg {
	
	use "$output\FERTILITY\probability_pregnant", clear 
	drop if inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")
	
	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 
	
	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
////////////////// late symptomatic syphilis: neurosyphilis ////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in late_symp_ns_dalys {
	
	use "$output\DALY\daly_loss_case_late_symp_ns_2030_2064_truncated.dta", clear 	
	drop if inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")
	
	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 
	
	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
//////////////////// late symptomatic syphilis: hearing loss ///////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in late_symp_hl_dalys {
	
	use "$output\DALY\daly_loss_case_late_symp_hl_2030_2064_truncated.dta", clear
	drop if inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")
		
	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 
	
	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
//////////////////// early symptomatic congenital syphilis /////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in early_symp_cs_dalys {
	
	use "$output\DALY\daly_loss_case_early_symp_cs_2030_2064.dta", clear 
	drop if inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")
	
	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 
	
	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
//////////////// stillbirth and neonatal death dalys ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in stillbirth_dalys neonatal_dalys {
	
	use "$output\DALY\dalys_sb_nd_discounted", clear 
	drop if inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")
	
	collapse (min) min_`var' = `var' (max) max_`var' = `var' (mean) mean_`var' = `var' (median) med_`var' = `var' 
	
	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// LBW/preterm ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

foreach var in yld_case yll_case preterm_dalys {
	
	use "$output\DALY\daly_loss_case_preterm_2030_2064_truncated.dta", clear 
	drop if inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")
	
	collapse (min) min_`var'_preterm = `var' (max) max_`var'_preterm = `var' (mean) mean_`var'_preterm = `var' (median) med_`var'_preterm = `var' 
	
	gen eye=1
    reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

	drop eye 
	
	append using "$output\MANUSCRIPT\model_input_summary_statistics"	
	compress 
	save "$output\MANUSCRIPT\model_input_summary_statistics", replace 
}

////////////////////////////////////////////////////////////////////////////////
//////////////////////////// syphilis incidence ////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\DECISION TREE\BASE FILE\probability_infected_vax_novax", clear 

keep country age year prob_syph_novax
drop if inlist(country,"Cuba","Monaco","North Korea","Syria","Venezuela")

collapse (min) min_prob_syph_novax = prob_syph_novax (max) max_prob_syph_novax = prob_syph_novax (mean) mean_prob_syph_novax = prob_syph_novax (median) med_prob_syph_novax = prob_syph_novax 

gen eye=1
reshape long min_ max_ mean_ med_ , i(eye) j(parameter) string

drop eye 

append using "$output\MANUSCRIPT\model_input_summary_statistics"	
compress 
save "$output\MANUSCRIPT\model_input_summary_statistics", replace 

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////// export //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use  "$output\MANUSCRIPT\model_input_summary_statistics", clear 

foreach var in min max mean med {
	ren `var'_ `var'
}

export excel using "$output\MANUSCRIPT\model_input_summary_statistics.xlsx", ///
first(var) sheet("parameters") sheetreplace 

log close 

exit 

// end 