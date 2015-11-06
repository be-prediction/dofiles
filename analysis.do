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
	ttest abs_pre==abs_surv
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
