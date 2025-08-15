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
age_aggregated_tree_results_vax_novax_truncated.dta created in: make_age_aggregated_tree_results_vax_novax_truncated.do
wtp_3xpcgdp.dta created in: make_wtp_3xpcgdp.do  
age_aggregated_tree_results_vax_novax_`sa'.dta created in: make_age_aggregated_tree_results_vax_novax_sensitivity_analyses.do
outputs:
unwtd_wtp_50_graph_basefile.dta
Tornado diagram.doc
*/

////////////////////////////////////////////////////////////////////////////////
///////////////////////////// construct graph basefile /////////////////////////
////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////// basecase //////////////////////////////////

use "$output\ANALYSIS\BASECASE\age_aggregated_tree_results_vax_novax_truncated", clear 
keep country wtp

egen unwtd_wtp_50 = pctile(wtp),p(50)
gen analysis = "basecase"

keep analysis unwtd_wtp_50
duplicates drop 
assert _n==1 
order analysis
save         "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_median_wtp.dta", replace 

//////////////////// value DALY gains at 3 times PCGDP /////////////////////////

use "$output\ANALYSIS\BASECASE\wtp_3xpcgdp" , clear 
keep country wtp

egen unwtd_wtp_50 = pctile(wtp),p(50)
gen analysis = "3xpcgdp"

keep analysis unwtd_wtp_50
duplicates drop 
assert _n==1 
order analysis

append using "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_median_wtp.dta"
save         "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_median_wtp.dta", replace 

//////////////////////////// sensitivity analyses //////////////////////////////

capture program drop results
program results
version 18.0
set more off
set type double 
args sa

use "$output\ANALYSIS\SENSITIVITY ANALYSIS\age_aggregated_tree_results_vax_novax_`sa'", clear 
keep country wtp
egen unwtd_wtp_50 = pctile(wtp),p(50)
gen analysis = "`sa'"

keep analysis unwtd_wtp_50
duplicates drop 
assert _n==1 
order analysis

append using "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_median_wtp.dta"
save         "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_median_wtp.dta", replace 

end 

results age20_cohort
results age25_cohort
results 0pct_health_0pct_costs
results 0pct_health_3pct_costs
results 6pct_health_6pct_costs
results direct_costs_minus_20_pct
results direct_costs_plus_20_pct 
results fertility_high
results fertility_low
results indirect_costs_minus_20_pct 
results indirect_costs_plus_20_pct
results lower 
results prob_abo 
results true_positive
results upper
results ve50_wane10
results ve50_wane5
results ve80_wane10
results who_emtct

use "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_median_wtp.dta", clear 

gen sortme=. 
replace sortme = 1 if analysis == "basecase" 
replace sortme = 2 if analysis == "3xpcgdp" 
replace sortme = 3 if analysis == "age20_cohort" 
replace sortme = 4 if analysis == "age25_cohort" 
replace sortme = 5 if analysis == "0pct_health_3pct_costs" 
replace sortme = 6 if analysis == "0pct_health_0pct_costs" 
replace sortme = 7 if analysis == "6pct_health_6pct_costs" 
replace sortme = 8 if analysis == "ve80_wane10" 
replace sortme = 9 if analysis == "ve50_wane5" 
replace sortme = 10 if analysis == "ve50_wane10" 
replace sortme = 11 if analysis == "lower" 
replace sortme = 12 if analysis == "upper" 
replace sortme = 13 if analysis == "fertility_high" 
replace sortme = 14 if analysis == "fertility_low" 
replace sortme = 15 if analysis == "prob_abo" 
replace sortme = 16 if analysis == "true_positive" 
replace sortme = 17 if analysis == "who_emtct" 
replace sortme = 18 if analysis == "direct_costs_minus_20_pct" 
replace sortme = 19 if analysis == "direct_costs_plus_20_pct" 
replace sortme = 20 if analysis == "indirect_costs_minus_20_pct" 
replace sortme = 21 if analysis == "indirect_costs_plus_20_pct" 

assert sortme<. 
sort sortme

save "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_median_wtp.dta", replace 

///////////////// compute % change in WTP relative to basecase /////////////////

use "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_median_wtp.dta", clear

drop if analysis =="3xpcgdp"

gen bar=""
replace bar = "Age 20 vaccine administration (137%)" if analysis == "age20_cohort"
replace bar = "Age 25 vaccine administration (125%)" if analysis == "age25_cohort"
replace bar = "Discount health only at 0% (240%)" if analysis == "0pct_health_3pct_costs"
replace bar = "Discount health and costs at 6% (50%)" if analysis == "6pct_health_6pct_costs"
replace bar = "Discount health and costs at 0% (221%)" if analysis == "0pct_health_0pct_costs"
replace bar = "VE 80%; waning 10% (61%)" if analysis == "ve80_wane10"
replace bar = "VE 50%; waning 5% (63%)" if analysis == "ve50_wane5"
replace bar = "VE 50%; waning 10% (38%)" if analysis == "ve50_wane10"
replace bar = "GBD lower estimates (41%)" if analysis == "lower"
replace bar = "GBD upper estimates (191%)" if analysis == "upper"
replace bar = "Fertility rates increase (124%)" if analysis == "fertility_high"
replace bar = "Fertility rates decrease (73%)" if analysis == "fertility_low"
replace bar = "Alternative ABO probabilities (49%)" if analysis == "prob_abo"
replace bar = "Probability of a false negative syphilis test in LICs decreases from 0.14 to the 0.005 probability used for MICs and HICs (100%)" if analysis == "true_positive"
replace bar = "WHO-recommended ANC-related rates (66%)" if analysis == "who_emtct"
replace bar = "Direct costs decrease 20% (102%)" if analysis == "direct_costs_minus_20_pct"
replace bar = "Direct costs increase 20% (97%)" if analysis == "direct_costs_plus_20_pct"
replace bar = "Indirect costs decrease 20% (99.7%)" if analysis == "indirect_costs_minus_20_pct"
replace bar = "Indirect costs increase 20% (100.3%)" if analysis == "indirect_costs_plus_20_pct"

assert bar == "" if analysis == "basecase"
assert analysis == "basecase" if bar==""

gen basecase_wtp=.
replace basecase_wtp=unwtd_wtp_50 if analysis=="basecase"
replace basecase_wtp=basecase_wtp[1] if basecase_wtp==.
gen diff_wtp = (unwtd_wtp_50-basecase_wtp)/basecase_wtp
gen pct = unwtd_wtp_50/basecase_wtp
drop basecase_wtp

gen benefit = "wtp"
order benefit

order analysis benefit unwtd_wtp_50 diff_wtp pct
sort pct 

save "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_wtp_50_graph_basefile", replace 

////////////////////////////////////////////////////////////////////////////////
//////////////////////////////// bar charts ////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

use "$output\ANALYSIS\SENSITIVITY ANALYSIS\unwtd_wtp_50_graph_basefile", clear 

#delimit ;
graph hbar diff_wtp, over(bar, label(nolabels)) nolabel
blabel(group, position(outside) size(tiny) gap(half_tiny))
bar(1, bcolor(eltblue))
ylabel(-0.99 " "
-0.75 "25%"
-0.50 "50%"
-0.25 "75%"
-0.10 "90%"
0	 "Basecase 100%"
0.10 "110%"
0.25 "125%"
0.50 "150%"
0.75 "175%"
1.0  "200%"
1.25 "225%"
1.50 "250%"
1.75 " ", labsize(tiny) angle(45))
yline(0, lpattern(solid) lcolor(black))
ytitle("")
title({stSerif:Figure 2. One-way sensitivity analysis:}, size(small)) 
subtitle({stSerif:Percentage impact on unweighted median willingness-to-pay across all countries}, size(small))
aspectratio(.35)
legend(position(6) rows(1) order(1 "WTP") size(vsmall))
note(
"Abbreviations and definitions:" 
"ANC=antenatal care; GBD=Global Burden of Disease Study 2021; ABO=adverse birth outcome; LICs=low-income countries;" 
"MICs=middle-income countries; HICs=high-income countries; VE=vaccine efficacy; UNWPP=United Nations World Population Prospects."
"ANC-related rates include: receiving basic ANC, syphilis testing for ANC enrollees, and syphilis treatment for ANC enrollees with a positive test result." 
"Description of analyses:"
"Alternative ABO probabilities replace base-case values with ABO probabilities based on Qin et al. (2014)."
"Fertility rates are decreased (increased) by replacing UNWPP median fertility rates used in the base case with its low (high) variants."
"GBD lower (upper) estimates replace GBD 2021 mean estimates used in the base case with its lower (upper) bound estimates."
"WHO-recommended ANC-related rates replace Korenromp et al. (2019) values used in base case with those recommended by WHO (2021).", size(vsmall))
;
#delimit cr



log close 
exit 

// end
