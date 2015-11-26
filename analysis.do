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


/// [4] Correlation between market price and replication outcome
preserve
	collapse endprice result, by(study)
	spearman endprice result // Spearman
	pwcorr endprice result, sig // Pearson
restore


/// [5] -> Already included in [33]


/// [6] Correlation between original p-value and replication outcome
preserve
	collapse porig result, by(study)
	spearman porig result // Spearman
	*pwcorr porig result, sig // Pearson
restore
	
	
/// [7] Number of studies with original p-value <0.01 that didn't replicate
preserve
	collapse porig result, by(study)
	// 0.0099 to take care of floating point problems
	count if porig<=0.0099
	count if porig<=0.0099 & result==0
restore


/// [8] Correlation between original sample size and replication outcome
preserve
	collapse norig result, by(study)
	spearman norig result // Spearman
	*pwcorr norig result, sig // Pearson
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


/// [11] Correlation between pre-market survey and replication outcome
preserve
	keep if active==1
	collapse preqrep result, by(study)
	spearman preqrep result // Spearman
	pwcorr preqrep result, sig // Pearson
restore


/// [12] Correlation between pre-market survey and final market prices
preserve
	keep if active==1
	collapse preqrep endprice, by(study)
	spearman preqrep endprice // Spearman
	*pwcorr preqrep endprice, sig // Pearson
restore


// [13] Absolute prediction error comparison between pre-market survey and final market prices
preserve
	keep if active==1
	collapse preqrep endprice result, by(study)
	gen abs_price = abs(endprice-result)
	gen abs_pre = abs(preqrep-result)
	signrank abs_price=abs_pre // Wilcoxon matched-pairs signed-ranks test
	*ttest abs_price==abs_pre // Paired t-test
restore


/// [14] Post-market survey statistics
preserve
	keep if postfinished==1
	collapse postqrep, by(study)
	sum postqrep, d
	mean postqrep
restore


/// [15] Correlation between pre- and post-market survey
preserve
	bysort study: egen preqrep_mean = mean(preqrep) if active==1
	bysort study: egen postqrep_mean = mean(postqrep) if postfinished==1
	collapse preqrep_mean postqrep_mean, by(study)
	spearman preqrep_mean postqrep_mean // Spearman
	*pwcorr preqrep_mean postqrep_mean, sig // Pearson
restore


/// [16] Correlation between post-market survey and replication outcome
preserve
	keep if postfinished==1
	collapse postqrep result, by(study)
	spearman postqrep result // Spearman
	*pwcorr  postqrep result, sig // Pearson
restore


// [17] Absolute prediction error comparison between pre- and post-market survey
preserve
	bysort study: egen preqrep_mean = mean(preqrep) if active==1
	bysort study: egen postqrep_mean = mean(postqrep) if postfinished==1
	collapse preqrep_mean postqrep_mean result, by(study)
	gen abs_pre = abs(preqrep_mean-result)
	gen abs_post = abs(postqrep_mean-result)
	signrank abs_pre=abs_post // Wilcoxon matched-pairs signed-ranks test
	*ttest abs_pre==abs_post // Paired t-test
restore


// [18] Absolute prediction error comparison between post-market survey and final market prices
preserve
	keep if postfinished==1
	collapse postqrep endprice result, by(study)
	gen abs_price = abs(endprice-result)
	gen abs_post = abs(postqrep-result)
	signrank abs_price=abs_post // Wilcoxon matched-pairs signed-ranks test
	*ttest abs_price==abs_post // Paired t-test
restore


/// [19] Correlation between pre-market survey (traders) and pre-market survey (all)
preserve
	bysort study: egen preqrep_meanall = mean(preqrep)
	bysort study: egen preqrep_meanactive = mean(preqrep) if active==1
	collapse preqrep_meanactive preqrep_meanall, by(study)
	spearman preqrep_meanactive preqrep_meanall // Spearman
	*pwcorr preqrep_meanactive preqrep_meanall, sig // Pearson
restore


/// [20] Pre-market survey statistics (all)
preserve
	collapse preqrep, by(study)
	sum preqrep, d
	mean preqrep
restore


/// [21] Correlation between pre-market survey (all) and replication outcome
preserve
	collapse preqrep result, by(study)
	spearman preqrep result // Spearman
	*pwcorr preqrep result, sig // Pearson
restore


/// [22] Power simulations of relation between market price and replication outcomes
use "../use/marketsurveysummary.dta", clear
collapse endprice, by(study)

/* Correlation estimation */
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
	qui spearman endprice result // Spearman
	*qui pwcorr endprice result // Pearson
	local est = r(rho)
	if `est'!=.{
		local t = `est'/sqrt((1-(`est')^2)/16)
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


/// [23] Correlation between original sample size and replication outcome
preserve
	collapse norig result, by(study)
	spearman norig result // Spearman
	*pwcorr norig result, sig // Pearson
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


/// [28] Test of mean standardized effect size in replication and original
preserve
	collapse erep eorig, by(study)
	*ttest erep==eorig // Paired t-test 
	signrank erep=eorig //  Wilcoxon matched-pairs signed-ranks test
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
	signrank endprice=result //  Wilcoxon matched-pairs signed-ranks test	
	*ttest endprice==result // Paired t-test 
restore


/// [31] Test if replication rate differs from pre-market survey
preserve
	keep if active==1
	collapse result preqrep, by(study)
	signrank preqrep=result //  Wilcoxon matched-pairs signed-ranks test	
	*ttest preqrep==result // Paired t-test
restore


/// [32] Meta-effect statistics
preserve
	collapse emeta emetal, by(study)
	gen sigmeta = (0<emetal)
	mean sigmeta
restore


/// [33] Difference in reproducibility between BERP and RPP across the six indicators
*** ! NOTE ***
* The Chi-square test is equivalent to
* a test of proportions in the case of
* two samples and two binary variables.
* For programming convenience, we simply
* obtain the Chi-square statistic by
* squaring the z-statistics form a test
* of proportions.
	mat drop _all
	
	mat def econ = [.,.,.\.,.,.\.,.,.\.,.,.\.,.,.\.,.,.]
	mat def psych = econ
	
	/// [33a] Replicated with P<0.05 in original direction
	preserve
		keep if active==1
		collapse result, by(study)
		sum result
		local e = r(mean)
		local eN = r(N)
		mat def econ[1,1]=`e'
		mat def econ[1,3]=`eN'
		
		local p = 35/97 
		local pN = 97
		mat def psych[1,1]=`p'
		mat def psych[1,3]=`pN'
		
		prtesti `eN' `e' `pN' `p'
		display "Chi2=" r(z)^2
	restore
	
	/// [33b] Original effect size within replication 95% CI
	preserve
		keep if active==1
		collapse eorig erepl erepu, by(study)
		gen originrepci = (eorig>=erepl & eorig<=erepu)
		sum originrepci
		local e = r(mean)
		local eN = r(N)
		mat def econ[2,1]=`e'
		mat def econ[2,3]=`eN'
		
		local p = 45/95
		local pN = 95
		mat def psych[2,1]=`p'
		mat def psych[2,3]=`pN'
		
		prtesti `eN' `e' `pN' `p'
		display "Chi2=" r(z)^2
	restore
	
	/// [33c] Meta-analytic estimate significant in the original direction
	preserve
		keep if active==1
		collapse emetal, by(study)
		gen metasig = (emetal>0)
		sum metasig
		local e = r(mean)
		local eN = r(N)
		mat def econ[3,1]=`e'
		mat def econ[3,3]=`eN'
		
		local p = 51/75
		local pN  = 75
		mat def psych[3,1]=`p'
		mat def psych[3,3]=`pN'
		
		prtesti `eN' `e' `pN' `p'
		display "Chi2=" r(z)^2
	restore
	
	/// [33d] Replication effect-size (% of original effect size)
	preserve
		keep if active==1
		collapse erep eorig, by(study)
		gen rele = erep/eorig
		sum rele
		local e = r(mean)
		local eN = r(N)
		local eSD = r(sd)
		mat def econ[4,1]=`e'
		mat def econ[4,2]=`eSD'
		mat def econ[4,3]=`eN'
		
		gen project = 1
		mkmat rele project, matrix(rele_econ)
		
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
		gen rele = t_rr/t_ro
		keep if studynum!=26 & studynum!=89 & studynum!=135 & rele!=.
		sum rele 
		local p = r(mean)
		local pN = r(N)
		local pSD = r(sd)
		mat def psych[4,1]=`p'
		mat def psych[4,2]=`pSD'
		mat def psych[4,3]=`pN'
		
		gen project = 2
		mkmat rele project, matrix(rele_psych)
		
		mat def compare = [rele_econ \ rele_psych]
		
		clear
		svmat compare, names(col)
		
		ranksum rele, by(project) // Two-sample Wilcoxon rank-sum (Mann-Whitney) test
		*ttesti `eN' `e' `eSD' `pN' `p' `pSD', unequal // Two-sample t test with unequal variances
	restore
	
	/// [33e] Prediction markets beliefs about replication
	preserve
		keep if active==1
		collapse endprice, by(study)
		sum endprice
		local e = r(mean)
		local eN = r(N)
		local eSD = r(sd)
		mat def econ[5,1]=`e'
		mat def econ[5,2]=`eSD'
		mat def econ[5,3]=`eN'
		
		gen project = 1
		mkmat endprice project, matrix(endprice_econ)

		use "../use/rpp-market-data.dta", clear
		keep endprice
		keep if endprice!=.
		replace endprice=endprice/100
		sum endprice
		local p = r(mean)
		local pN = r(N)
		local pSD = r(sd)
		mat def psych[5,1]=`p'
		mat def psych[5,2]=`pSD'
		mat def psych[5,3]=`pN'
		
		gen project = 2
		mkmat endprice project, matrix(endprice_psych)
	
		mat def compare = [endprice_econ \ endprice_psych]
		
		clear
		svmat compare, names(col)
		
		ranksum endprice, by(project) // Two-sample Wilcoxon rank-sum (Mann-Whitney) test
		*ttesti `eN' `e' `eSD' `pN' `p' `pSD', unequal // Two-sample t test with unequal variances
	restore
	
	
	/// [33f] Survey beliefs about replication
	preserve
		keep if active==1
		collapse preqrep, by(study)
		sum preqrep
		local e = r(mean)
		local eN = r(N)
		local eSD = r(sd)
		mat def econ[6,1]=`e'
		mat def econ[6,2]=`eSD'
		mat def econ[6,3]=`eN'
		
		gen project = 1
		mkmat preqrep project, matrix(preqrep_econ)

		use "../use/rpp-market-data.dta", clear
		keep preqrep
		keep if preqrep!=.
		replace preqrep=preqrep/100
		sum preqrep
		local p = r(mean)
		local pN = r(N)
		local pSD = r(sd)
		mat def psych[6,1]=`p'
		mat def psych[6,2]=`pSD'
		mat def psych[6,3]=`pN'
		
		gen project = 2
		mkmat preqrep project, matrix(preqrep_psych)
	
		mat def compare = [preqrep_econ \ preqrep_psych]
		
		clear
		svmat compare, names(col)
		
		ranksum preqrep, by(project) // Two-sample Wilcoxon rank-sum (Mann-Whitney) test
		*ttesti `eN' `e' `eSD' `pN' `p' `pSD', unequal // Two-sample t test with unequal variances
	restore
	
	
	/// [33+] Average difference across all 6 indicators
	preserve
		clear
		svmat econ
		svmat psych
		gen diff=econ1-psych1
		sum diff
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


/// [36] RPP correlation between market price and replication outcome
preserve
	use "../use/rpp-market-data.dta", clear
	*spearman endprice resultrep // Spearman
	pwcorr endprice resultrep, sig // Pearson
restore


/// [37] RPP correlation between pre-market survey and replication outcome
preserve
	use "../use/rpp-market-data.dta", clear
	*spearman preqrep resultrep // Spearman
	pwcorr preqrep resultrep, sig // Pearson
restore


/// [38] Correlation between original and replication standardized effect sizes
preserve
	collapse eorig erep, by(study)
	spearman eorig erep // Spearman
	*pwcorr eorig erep, sig // Pearson
restore


/// [39] Final holdings statistics (bulls/bears)
preserve
	keep if active==1
	collapse finalholdings, by(study userid)
	drop if finalholdings==0 // Only keep markets for which user has holdings
	gen int holdingtype=.
	replace holdingtype=1 if finalholdings>0
	replace holdingtype=-1 if finalholdings<0
	
	collapse (sum) holdingtype (count) finalholdings, by(userid)
	qui sum if holdingtype==-finalholdings
	local bears=r(N)
	qui sum if holdingtype==finalholdings
	local bulls=r(N)
	display "Bears: " `bears'
	display "Bulls: " `bulls'
restore
