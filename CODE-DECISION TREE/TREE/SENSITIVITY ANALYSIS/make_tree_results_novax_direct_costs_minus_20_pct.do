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
log using "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\make_tree_results_novax_direct_costs_minus_20_pct", text replace

/*
inputs:
analytical_data_ihme_countries_age15_cohort_direct_costs_minus_20_pct.dta created in: make_analytical_data_ihme_countries_age15_cohort_direct_costs_minus_20_pct.do
outputs:
tree_results_novax_direct_costs_minus_20_pct.dta
*/

clear
capture erase "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_novax_direct_costs_minus_20_pct.dta"
save          "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_novax_direct_costs_minus_20_pct", replace emptyok

capture prog drop get_tree_results
prog def get_tree_results
version 18.0 
set more off
set type double
clear all 
drop _all
args country age 

gl output "$root\OUTPUT"

use "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_direct_costs_minus_20_pct", clear 

keep if country=="`country'" & age==`age'
assert _N==1

di "**************************************************************************"
di "The country is `country' and the age is `age'"
di "**************************************************************************"

////////////////////////////////////////////////////////////////////////////////
//////// set up the scalars for invariant terminal node probabilities //////////
////////////////////////////////////////////////////////////////////////////////

// Probs for term nodes, uninfected (A')

scalar prob_uninf_lbw_preterm = prob_uninf_lbw_preterm
scalar prob_uninf_neonatal_death = prob_uninf_neonatal_death
scalar prob_uninf_stillbirth = prob_uninf_stillbirth
scalar prob_uninf_normal = prob_uninf_normal  
assert scalar(prob_uninf_lbw_preterm) + scalar(prob_uninf_neonatal_death) + scalar(prob_uninf_stillbirth) + scalar(prob_uninf_normal) ==1

// Probs for term nodes, infected & untreated (B1, B2, B3, B4)

scalar prob_untr_lbw_preterm = prob_untr_lbw_preterm
scalar prob_untr_neonatal_death = prob_untr_neonatal_death
scalar prob_untr_stillbirth = prob_untr_stillbirth
scalar prob_untr_cong_syph = prob_untr_cong_syph
scalar prob_untr_neurosyph = prob_untr_neurosyph
scalar prob_untr_hearloss = prob_untr_hearloss
scalar prob_untr_normal = prob_untr_normal
assert scalar(prob_untr_lbw_preterm) + scalar(prob_untr_neonatal_death) + scalar(prob_untr_stillbirth) + scalar(prob_untr_cong_syph) + scalar(prob_untr_neurosyph) + scalar(prob_untr_hearloss) + scalar(prob_untr_normal)==1 

// Probs for term nodes, infected & treated (B')

scalar prob_trtd_lbw_preterm = prob_trtd_lbw_preterm
scalar prob_trtd_neonatal_death = prob_trtd_neonatal_death
scalar prob_trtd_stillbirth = prob_trtd_stillbirth
scalar prob_trtd_cong_syph = prob_trtd_cong_syph  
scalar prob_trtd_neurosyph = prob_trtd_neurosyph
scalar prob_trtd_hearloss = prob_trtd_hearloss
scalar prob_trtd_normal = prob_trtd_normal
assert scalar(prob_trtd_lbw_preterm) + scalar(prob_trtd_neonatal_death) + scalar(prob_trtd_stillbirth) + scalar(prob_trtd_cong_syph) + scalar(prob_trtd_neurosyph) + scalar(prob_trtd_hearloss) + scalar(prob_trtd_normal)==1 

////////////////////////////////////////////////////////////////////////////////
///////////// set up the node probabilities that are variable //////////////////
////////////////////////////////////////////////////////////////////////////////

scalar prob_survive = prob_survive
scalar prob_die = prob_die 

scalar prob_inf = prob_syph_novax  
scalar prob_noinf = prob_no_syph_novax  

scalar prob_preg_noinf = prob_preg
scalar prob_preg_inf   = prob_preg

scalar prob_nopreg_noinf = prob_no_preg  
scalar prob_nopreg_inf   = prob_no_preg 

scalar prob_anc = prob_anc 
scalar prob_no_anc = prob_no_anc 
scalar prob_screened = prob_testing
scalar prob_notscreened = prob_no_testing 
scalar prob_true_pos =  prob_true_pos 
scalar prob_false_neg = prob_false_neg 
scalar prob_mom_treated = prob_treatment
scalar prob_mom_nottreated = prob_no_treatment 

////////////////////////////////////////////////////////////////////////////////
////////////////////////// set up the payoff values ////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Payoff values for term nodes, uninfected (A')

scalar cost_uninf_lbw_preterm = cost_lbwpt  
scalar cost_uninf_neonatal_death = cost_nd 
scalar cost_uninf_stillbirth = cost_stillbirth
scalar cost_uninf_normal = cost_nonABO 

scalar daly_uninf_lbw_preterm = preterm_dalys
scalar daly_uninf_neonatal_death = neonatal_dalys
scalar daly_uninf_stillbirth = stillbirth_dalys
scalar daly_uninf_normal = 0  

// Payoff values for term nodes, infected and treated (B')

scalar cost_trtd_lbw_preterm = cost_lbwpt 
scalar cost_trtd_neonatal_death = cost_nd 
scalar cost_trtd_stillbirth = cost_stillbirth
scalar cost_trtd_cong_syph = cost_cs 
scalar cost_trtd_neurosyph = cost_neurosyph 
scalar cost_trtd_hearloss = cost_hearingloss 
scalar cost_trtd_normal = cost_nonABO  

scalar daly_trtd_lbw_preterm = preterm_dalys
scalar daly_trtd_neonatal_death = neonatal_dalys
scalar daly_trtd_stillbirth = stillbirth_dalys
scalar daly_trtd_cong_syph = early_symp_cs_dalys 
scalar daly_trtd_neurosyph = late_symp_ns_dalys 
scalar daly_trtd_hearloss = late_symp_hl_dalys 
scalar daly_trtd_normal = 0  

// Payoff values for term nodes, infected and untreated (B1, B2, B3, B4)

scalar cost_untr_lbw_preterm = cost_lbwpt
scalar cost_untr_neonatal_death = cost_nd 
scalar cost_untr_stillbirth = cost_stillbirth
scalar cost_untr_cong_syph = cost_cs  
scalar cost_untr_neurosyph = cost_neurosyph  
scalar cost_untr_hearloss = cost_hearingloss 
scalar cost_untr_normal = cost_nonABO  

scalar daly_untr_lbw_preterm = preterm_dalys 
scalar daly_untr_neonatal_death = neonatal_dalys
scalar daly_untr_stillbirth = stillbirth_dalys
scalar daly_untr_cong_syph = early_symp_cs_dalys 
scalar daly_untr_neurosyph = late_symp_ns_dalys 
scalar daly_untr_hearloss = late_symp_hl_dalys 
scalar daly_untr_normal = 0 

////////////////////////////////////////////////////////////////////////////////
////////////////////////////// build the tree //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

clear

tree init cost daly

tree create woman 
tree node woman, term(die) int(survive)

tree node woman survive, int(noinf inf)
tree node woman survive noinf, int(preg) term(nopreg)
tree node woman survive noinf preg, term(lbw_preterm neonatal_death stillbirth normal)

tree node woman survive inf, int(preg) term(nopreg)

tree node woman survive inf preg, int(basic_anc no_basic_anc)

tree node woman survive inf preg basic_anc, int(cs_screening no_cs_screening)
tree node woman survive inf preg basic_anc cs_screening, int(true_pos false_neg)
tree node woman survive inf preg basic_anc cs_screening true_pos, int(cs_treat no_cs_treat)

tree node woman survive inf preg basic_anc no_cs_screening, ///
	term(lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal)

tree node woman survive inf preg basic_anc cs_screening false_neg, ///
	term(lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal)

tree node woman survive inf preg basic_anc cs_screening true_pos cs_treat, ///
	term(lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal)

tree node woman survive inf preg basic_anc cs_screening true_pos no_cs_treat, ///
	term(lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal)

tree node woman survive inf preg no_basic_anc, ///
	term(lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal)
	

////////////////////////////////////////////////////////////////////////////////
/////////////// map parameter values to the tree nodes /////////////////////////
////////////////////////////////////////////////////////////////////////////////

tree setvals woman die,     prob(scalar(prob_die)) cost(0) daly(0) 
tree setvals woman survive, prob(scalar(prob_survive))

tree setvals woman survive noinf, prob(scalar(prob_noinf))
tree setvals woman survive noinf nopreg, prob(scalar(prob_nopreg_noinf)) cost(0) daly(0) 
tree setvals woman survive noinf preg, prob(scalar(prob_preg_noinf))

foreach outcome in lbw_preterm neonatal_death stillbirth normal {
	tree setvals woman survive noinf preg `outcome', prob(scalar(prob_uninf_`outcome')) cost(scalar(cost_uninf_`outcome')) daly(scalar(daly_uninf_`outcome'))
}

tree setvals woman survive inf, prob(scalar(prob_inf))
tree setvals woman survive inf nopreg, prob(scalar(prob_nopreg_inf)) cost(0) daly(0) 
tree setvals woman survive inf preg, prob(scalar(prob_preg_inf)) 

tree setvals woman survive inf preg basic_anc,    prob(scalar(prob_anc))
tree setvals woman survive inf preg no_basic_anc, prob(scalar(prob_no_anc))

tree setvals woman survive inf preg basic_anc cs_screening,    prob(scalar(prob_screened))
tree setvals woman survive inf preg basic_anc no_cs_screening, prob(scalar(prob_notscreened))

tree setvals woman survive inf preg basic_anc cs_screening true_pos,  prob(scalar(prob_true_pos))
tree setvals woman survive inf preg basic_anc cs_screening false_neg, prob(scalar(prob_false_neg))

tree setvals woman survive inf preg basic_anc cs_screening true_pos cs_treat,    prob(scalar(prob_mom_treated))
tree setvals woman survive inf preg basic_anc cs_screening true_pos no_cs_treat, prob(scalar(prob_mom_nottreated))

foreach outcome in lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal {
	tree setvals woman survive inf preg basic_anc cs_screening true_pos cs_treat `outcome', ///
		prob(scalar(prob_trtd_`outcome')) cost(scalar(cost_trtd_`outcome')) daly(scalar(daly_trtd_`outcome'))
		}

foreach outcome in lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal {
	tree setvals woman survive inf preg basic_anc cs_screening true_pos no_cs_treat `outcome', ///
		prob(scalar(prob_untr_`outcome')) cost(scalar(cost_untr_`outcome')) daly(scalar(daly_untr_`outcome'))
}

foreach outcome in lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal {
	tree setvals woman survive inf preg basic_anc cs_screening false_neg `outcome', ///
		prob(scalar(prob_untr_`outcome')) cost(scalar(cost_untr_`outcome')) daly(scalar(daly_untr_`outcome'))
}

foreach outcome in lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal {
	tree setvals woman survive inf preg basic_anc no_cs_screening `outcome', ///
		prob(scalar(prob_untr_`outcome')) cost(scalar(cost_untr_`outcome')) daly(scalar(daly_untr_`outcome'))
}

foreach outcome in lbw_preterm neonatal_death stillbirth cong_syph neurosyph hearloss normal {
	tree setvals woman survive inf preg no_basic_anc `outcome', ///
		prob(scalar(prob_untr_`outcome')) cost(scalar(cost_untr_`outcome')) daly(scalar(daly_untr_`outcome'))
}


confirm var __nodename  __branch_head __branch_tail __next prob cost daly

tempfile tree 
save `tree'

////////////////////////////////////////////////////////////////////////////////
//////////////////////////// evaluate the tree /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

set more off
use `tree' 

tree eval

tree des
capture noisily tree values, at(woman)

gen country = "`country'"
gen year = 2030 + (`age'-15) 
gen age = `age'

gen my_cost = scalar(v_cost)
gen my_daly = scalar(v_daly)

keep country year age my_cost my_daly
duplicates drop 
assert _N==1 

append using "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_novax_direct_costs_minus_20_pct.dta"
sort country age 
compress
save         "$output\DECISION TREE\TREE RESULTS\SENSITIVITY ANALYSIS\tree_results_novax_direct_costs_minus_20_pct.dta", replace 

end 

use "$output\DECISION TREE\BASE FILE\SENSITIVITY ANALYSIS\analytical_data_ihme_countries_age15_cohort_direct_costs_minus_20_pct", clear 
levelsof country, local(country) 

foreach cc of local country {
	forvalues a=15/49 {
	/* country, age */
		get_tree_results "`cc'" `a'
	}
}

log close 
exit 

// end