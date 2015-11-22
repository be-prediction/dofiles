clear
set more off

use "../use/marketsurveysummary.dta", clear
sort study userid



/// [1] Number of significant Replications, with confidence interval
preserve
	collapse result, by(study)
	display "Number of successful replications:"
	count if result ==1
	mean result
restore


/// [2] Pre-market survey statistics
preserve
	keep if active==1
	collapse preqrep, by(study)
	sum preqrep, d
	mean preqrep
restore

/// [3] Mean/median planned power of replications
preserve
	sum powrep_plan, d
restore


/// [4] Pearson correlation between market price and replication outcome
preserve
	collapse endprice result, by(study)
	pwcorr endprice result, sig
restore


/// [5] Pearson’s Chi2 test of replication rates: RPP vs. BERP
preserve
	clear
	local totobs = 97 + 18
	set obs `totobs'
	gen study =(_n>97)
	label define studyname 0 "RPP" 1 "BERP"
	label val study studyname
	gen result = .
	replace result = (_n <= 35) if study==0
	replace result = (_n <= 108) if study==1
	label define resultname 0 "Not replicated" 1 "Replicated"
	label val result resultname
	tabulate study result, chi2
restore


/// [6] Pearson correlation between original p-value and replication outcome
preserve
	collapse porig result, by(study)
	pwcorr porig result, sig
restore
	
	
/// [7] Number of studies with original p-value <0.01 that didn't replicate
preserve
	collapse porig result, by(study)
	// 0.0099 to take care of floating point problems
	count if porig<=0.0099
	count if porig<=0.0099 & result==0
restore


/// [8] Pearson correlation between original sample size and replication outcome
preserve
	collapse norig result, by(study)
	pwcorr norig result, sig
restore
	
	
/// [9] Market participant statistics
preserve
	collapse active postfinished, by(userid)
	count
	count if active==1
	count if active==1 & postfinished==1
restore
	
	
/// [10] Prediction market final price statistics, with confidence interval
preserve
	collapse endprice, by(study)
	sum endprice, d
	mean endprice
restore


/// [11] Pearson correlation between pre-market survey and replication outcome
preserve
	keep if active==1
	collapse preqrep result, by(study)
	pwcorr preqrep result, sig
restore


/// [12] Pearson correlation between pre-market survey and final market prices
preserve
	keep if active==1
	collapse preqrep endprice, by(study)
	pwcorr preqrep endprice, sig
restore


// [13] Absolute prediction error comparison between pre-market survey and final market prices
preserve
	keep if active==1
	collapse preqrep endprice result, by(study)
	gen abs_price = abs(endprice-result)
	gen abs_pre = abs(preqrep-result)
	ttest abs_price==abs_pre
restore


/// [14] Post-market survey statistics
preserve
	keep if postfinished==1
	collapse postqrep, by(study)
	sum postqrep, d
	mean postqrep
restore


/// [15] Pearson correlation between pre- and post-market survey
preserve
	bysort study: egen preqrep_mean = mean(preqrep) if active==1
	bysort study: egen postqrep_mean = mean(postqrep) if postfinished==1
	collapse preqrep_mean postqrep_mean, by(study)
	pwcorr preqrep_mean postqrep_mean, sig
restore


/// [16] Pearson correlation between post-market survey and replication outcome
preserve
	keep if postfinished==1
	collapse postqrep result, by(study)
	pwcorr  postqrep result, sig
restore


// [17] Absolute prediction error comparison between pre- and post-market survey
preserve
	bysort study: egen preqrep_mean = mean(preqrep) if active==1
	bysort study: egen postqrep_mean = mean(postqrep) if postfinished==1
	collapse preqrep_mean postqrep_mean result, by(study)
	gen abs_pre = abs(preqrep_mean-result)
	gen abs_post = abs(postqrep_mean-result)
	ttest abs_pre==abs_post
restore


// [18] Absolute prediction error comparison between post-market survey and final market prices
preserve
	keep if postfinished==1
	collapse postqrep endprice result, by(study)
	gen abs_price = abs(endprice-result)
	gen abs_post = abs(postqrep-result)
	ttest abs_price==abs_post
restore


/// [19] Pearson correlation between pre-market survey (traders) and pre-market survey (all)
preserve
	bysort study: egen preqrep_meanall = mean(preqrep)
	bysort study: egen preqrep_meanactive = mean(preqrep) if active==1
	collapse preqrep_meanactive preqrep_meanall, by(study)
	pwcorr preqrep_meanactive preqrep_meanall, sig
restore


/// [20] Pre-market survey statistics (all)
preserve
	collapse preqrep, by(study)
	sum preqrep, d
	mean preqrep
restore


/// [21] Pearson correlation between pre-market survey (all) and replication outcome
preserve
	collapse preqrep result, by(study)
	pwcorr preqrep result, sig
restore


/// [22] Power simulations of relation between market price and replication outcomes
use "../use/marketsurveysummary.dta", clear
collapse endprice, by(study)

/* Pearson correlation estimation */
set seed 1392393485
local num_iterations = 10000
local tot_os = 0
local tot_ts = 0
local tot_tsneg = 0
local tot_est = 0
local ok_iterations = 0
forval i = 1/`num_iterations'{
	preserve
	qui gen rand = uniform()
	qui gen result = (endprice >= rand)
	qui pwcorr endprice result
	local est = r(rho)
	if `est'!=.{
		local t = `est'/sqrt((1-`est'^2)/16)
		local pos = 1-t(16, `t') // One tailed t-test of positive correlation
		local pts = 2*(1-t(16, abs(`t'))) // Two tailed t-test of difference from 0
		if `pos'<=0.025{
			local tot_os = `tot_os' + 1
		}
		if `pts'<=0.05{
			local tot_ts = `tot_ts' + 1
		}
		if `pts'<=0.05 & `est'<0{
			local tot_tsneg = `tot_tsneg' + 1
		}
		local tot_est = `tot_est' + `est'	
		local ok_iterations = `ok_iterations' + 1
	}
	restore
}
local share_os = `tot_os'/`ok_iterations'
local share_ts = `tot_ts'/`ok_iterations'
local share_tsneg = `tot_tsneg'/`ok_iterations'
local mean = `tot_est'/`ok_iterations'

display "Ok iterations: "  `ok_iterations'
display "Power one sided (alpha=0.025): " `share_os' " (count=" `tot_os' ")"
display "Power two sided (alpha=0.050): " `share_ts' " (count=" `tot_ts' ")"
display "Difference: " `share_tsneg' " (count=" `tot_tsneg' ")"
display "Mean: " `mean'

use "../use/marketsurveysummary.dta", clear


/// [23] Pearson correlation between original sample size and replication outcome
preserve
	collapse norig result, by(study)
	pwcorr norig result, sig
restore


/// [24] Test if actual replication rate deviates from expected (based on power)
preserve
	collapse result powrep_plan, by(study)
	qui sum powrep_plan
	local powrep_planmean=r(mean)
	prtest result == `powrep_planmean'
restore


/// [25] Mean number of original effect sizes within the 95% CI of the effect size estimate in the replication
preserve
	collapse eorig erepl erepu, by(study)
	gen within = (erepl<=eorig & eorig<=erepu)
	mean within
restore

/// [26] Mean number of original effect sizes within the 95% CI of the effect size estimate in the replication
/// (inlcuding de CLippel et al.)
preserve
	collapse eorig erep erepl erepu, by(study)
	gen within = (erepl<=eorig & eorig<=erepu)
	replace within = 1 if erep>0 & erepl>eorig
	mean within
restore


/// [27] Standardized effect size statistics
preserve
	collapse erep eorig erel, by(study)
	sum erep eorig erel
restore


/// [28] Paired t-test of mean standardized effect size in replication and original
preserve
	collapse erep eorig, by(study)
	ttest erep==eorig
	
	// Non parametric equivalent:
	//signrank erep=eorig
restore


/// [29] Normalized standardized effect size statistics
preserve
	collapse ereprel erep eorig, by(study)
	qui sum erep
	local erepmean = r(mean)
	qui sum eorig
	local eorigmean = r(mean)
	local avg = `erepmean'/`eorigmean'
	display "erepmean/eorigmean = " `avg'
	mean ereprel
restore


/// [30] Test if replication rate differs from market price
preserve
	collapse result endprice, by(study)
	qui sum endprice
	ttest endprice==result
	
	// Non-parametric equivalent:
	*signrank result=endprice	
restore


/// [31] Test if replication rate differs from pre-market survey
preserve
	keep if active==1
	collapse result preqrep, by(study)
	ttest preqrep==result
	
	// Non-parametric equivalent:
	*signrank preqrep=result
restore


/// [32] Meta-effect statistics
preserve
	collapse emeta emetal, by(study)
	gen sigmeta = (0<emetal)
	mean sigmeta
restore


/// [33] Difference in reproducibility between BERP and RPP across the six indicators
preserve

	/* Data gathering
	----------------------------*/
	mat drop _all

	* Econ
	keep if active==1
	collapse result eorig erep emeta erepl erepu emetal emetau endprice preqrep, by(study)
	
	// Replicated with P<0.05 in original direction
	sum result
	mat def econ = (nullmat(econ) \ [r(mean), ., e(N)])
	
	// Original effect size within replication 95% CI
	gen originrepci = (eorig>=erepl & eorig<=erepu)
	sum originrepci
	mat def econ = (nullmat(econ) \ [r(mean), ., e(N)])
	
	// Meta-analytic estimate significant in the original direction
	gen metasig = (emetal>0)
	sum metasig
	mat def econ = (nullmat(econ) \ [r(mean), ., e(N)])
	
	// Replication effect-size (% of original effect size)
	gen rele = erep/eorig
	sum rele
	mat def econ = (nullmat(econ) \ [r(mean), r(sd), e(N)])
	
	// Prediction markets beliefs about replication
	sum endprice
	mat def econ = (nullmat(econ) \ [r(mean), r(sd), e(N)])
	
	// Survey beliefs about replication
	sum preqrep
	mat def econ = (nullmat(econ) \ [r(mean), r(sd), e(N)])
	
	
	* Psych replications
	// Replicated with P<0.05 in original direction (from RPP-paper)
	local mean = 35/97 
	local obs = 97
	mat def psych = (nullmat(psych) \ [`mean', ., `obs'])
	
	// Original effect size within replication 95% CI (from RPP-paper)
	local mean = 45/95
	local obs = 95
	mat def psych = (nullmat(psych) \ [`mean', ., `obs'])
	
	// Meta-analytic estimate significant in the original direction (from RPP-paper)
	local mean = 51/75
	local obs = 75
	mat def psych = (nullmat(psych) \ [`mean', ., `obs'])
	
	
	
	use "../use/rpp-data.dta", clear
	*** !NOTE! ***
	* The original effect size mean is slightly different
	* from what's reported in the RPP paper, this is not an error
	* as same thing is given with original R scripts and current data
	
	keep studynum t_rr t_ro t_pval_user t_pval_useo
	
	foreach var in t_rr t_ro t_pval_useo{
		replace `var'="" if `var'=="NA"
		destring `var', replace
	}
	
	// Replication effect-size (% of original effect size)
	gen rele = t_rr/t_ro
	qui sum rele if studynum!=26 & studynum!=89 & studynum!=135
	mat def psych = (nullmat(psych) \ [r(mean), r(sd), r(N)])
	
	* Psych market data
	use "../use/rpp-market-data.dta", clear
	keep study endprice preqrep
	
	// Prediction markets beliefs about replication
	replace endprice=endprice/100
	qui sum endprice
	mat def psych = (nullmat(psych) \ [r(mean), r(sd), r(N)])
	
	// Survey beliefs about replication
	replace preqrep=preqrep/100
	qui sum preqrep
	mat def psych = (nullmat(psych) \ [r(mean), r(sd), r(N)])
	
	* Combined
	clear
	svmat econ
	rename econ1 e
	rename econ2 eSD
	rename econ3 eN
	
	svmat psych
	rename psych1 p
	rename psych2 pSD
	rename psych3 pN
	
	gen diff = e -p
	
	
	/* Tests
	----------------------------*/
	local sig = 0
	forval n = 1/6{
		local eN = eN[`n']
		local e = e[`n']
		local pN = pN[`n']
		local p = p[`n']
		if `n'==1{
			display ""
			display "Replicated with P<0.05 in original direction"
		}
		else if `n'==2{
			display ""
			display "Original effect size within replication 95% CI"
		}
		else if `n'==3{
			display ""
			display "Meta-analytic estimate significant in the original direction"
		}
		else if `n'==4{
			display ""
			display "Replication effect-size (% of original effect size)"
		}
		else if `n'==5{
			display ""
			display "Prediction markets beliefs about replication:"
		}
		else if `n'==6{
			display ""
			display "Survey beliefs about replication:"
		}
		// For the binary variables:
		if `n'<=3{
			prtesti `eN' `e' `pN' `p'
			if  2*(1-normal(abs(r(z))))<=0.05{
				local sig = `sig' + 1
			}
		}
		// For the non-binary variables:
		else{
			local eSD = eSD[`n']
			local pSD = pSD[`n']
			ttesti `eN' `e' `eSD' `pN' `p' `pSD', unequal
			if  r(p)<=0.05{
				local sig = `sig' + 1
			}
		}
	}
	display "Number significant: " `sig'
	
	qui sum diff
	display "Average difference across all 6 indicators: " r(mean)
	
	
restore


/// [34] Prediction market demographics
preserve
	collapse age gender yiacad position nationality_reg country_reg active, by(userid)
	label values nationality_reg regions
	label values country_reg regions
	label values gender gender
	label values position position2
	keep if active==1
	
	tab position
	mean yiacad
	tab country_reg
restore


/// [35] Prediction market transaction details
preserve
	collapse traders transactions volume investedpoints, by(study)
	sum volume, d
	sum investedpoints, d
restore


/// [36] RPP pearson correlation between market price and replication outcome
preserve
	use "../use/rpp-market-data.dta", clear
	pwcorr endprice resultrep, sig
restore


/// [37] RPP pearson correlation between pre-market survey and replication outcome
preserve
	use "../use/rpp-market-data.dta", clear
	pwcorr preqrep resultrep, sig
restore
