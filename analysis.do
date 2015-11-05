clear
set more off

use "../use/marketsurveysummary.dta", clear
sort study userid


********************************************************************************
*** IMPORTANT REMARKS
********************************************************************************
*** This do-file computes all the results of the google-docs draft of the paper
*** in a sequential order. To avoid any problems when updating the google-docs
*** file, I copied the draft into a Word file and numbered each single result.
*** The Word file this do-file refers to has been uploaded to the "do-files" 
*** folder of the git-repository.

*** Each result is stored as local variable. So just run the do-file and all
*** results will be displayed in Stata's result window within a loop.
********************************************************************************


/// [1] Number of significant Replications
preserve
	collapse result, by(study)
	sum      result
	
	local r1 : display %9.0f r(mean)*18
	local l1 = "number of significant replications (in absolute terms)"
restore


/// [2]
preserve
	* effect size variables not yet part of the data set
	gen effectsize = rnormal(0.6,0.1) 
	
	collapse effectsize result, by(study)
	sum      effectsize if result == 1
	
	local r2 : display %9.2f r(mean)*100
	local l2 = "average relative effect size of replicated studies (in percent)"
restore


/// [3]
preserve
	gen      suc_pred = 0
	replace  suc_pred = 1 if endprice > 0.5 & result==1
	replace  suc_pred = 1 if endprice < 0.5 & result==0
	
	collapse suc_pred, by(study)
	sum      suc_pred
	
	local r3 : display %9.2f r(mean)*100
	local l3 = "successful predictions by market prices (in %)"
restore


/// [4]
  local r4 : display %9.2f `r1'/18*100
	local l4 = "number of significant replications (in %)"

/*
SHOULD WE REALLY DO DUPLICATES OR WILL THIS BE CONFUSING IN THE END
(WILL INCREASE MAINTENANCE IN KEEPING TRACK)?
/// [5]
	local r5 : display %9.0f `r1'
	local l5 = "number of significant replications (in absolute terms)"


/// [6]
	local r6 : display %9.2f `r1'/18*100
	local l6 = "number of significant replications (in %)"
*/	
	
/// [7]
	local r7 = "what does the CI refer to?"
	local l7 = "lower bound of confidence interval of sig. replications"
	
	
/// [8]
	local r8 = "what does the CI refer to?"
	local l8 = "upper bound of confidence interval of sig. replications"
	

/// [9]
preserve
	* effect size variables not yet part of the data set
	gen effectsize = rnormal(0.6,0.1) 
	
	collapse effectsize result, by(study)
	sum      effectsize if result == 1
	
	local r9 : display %9.2f r(mean)*100
	local l9 = "average relative effect size of replicated studies (in %)"
restore


/// [10]
preserve
	* effect size variables not yet part of the data set
	gen effectsize = rnormal(0.6,0.1) 
	
	collapse effectsize result, by(study)
	sum      effectsize if result == 1
	
	local r10 : display %9.2f r(sd)*100
	local l10 = "SD of relative effect size of replicated studies (in %)"
restore


/// [11]
preserve
	* effect size variables not yet part of the data set
	gen effectsize = rnormal(0.6,0.1) 
	
	collapse effectsize result, by(study)
	sum      effectsize if result == 1
	
	local r11 : display %9.2f r(min)*100
	local l11 = "minimum relative effect size of replicated studies (in %)"
restore


/// [12]
preserve
	* effect size variables not yet part of the data set
	gen effectsize = rnormal(0.6,0.1) 
	
	collapse effectsize result, by(study)
	sum      effectsize if result == 1
	
	local r12 : display %9.2f r(max)*100
	local l12 = "maximum relative effect size of replicated studies (in %)"
restore


/// [13]
	local r13 = "data from psychology replications needed"
	local l13 = "chi² value of frequency comparison with psych.rep."


/// [14]
	local r14 = "data from psychology replications needed"
	local l14 = "p-value of frequency comparison (chi²) with psych.rep."


/// [15]
preserve
	collapse porig prep, by(study)
	pwcorr   porig prep, sig obs

	local r15 : display %9.3f r(rho)
	local l15 = "pearson correlation of original and replication p-values"
restore


/// [16]
preserve
	collapse porig prep, by(study)
	pwcorr   porig prep, sig obs
	
	local    t = (abs(r(rho)) * sqrt(r(N) - 2)) / (sqrt(1 - abs(r(rho))^2))
	local    p = 2*ttail(r(N)-2,`t')
	
	local r16 : display %9.3f `p'
	local l16 = "p-value of correlation of original and replication p-values"
restore


/// [17]
preserve
	collapse norig prep, by(study)
	pwcorr   norig prep, sig obs

	local r17 : display %9.3f r(rho)
	local l17 = "pearson correlation of original n- and replication p-values"
restore


/// [18]
preserve
	collapse norig prep, by(study)
	pwcorr   norig prep, sig obs
	
	local    t = (abs(r(rho)) * sqrt(r(N) - 2)) / (sqrt(1 - abs(r(rho))^2))
	local    p = 2*ttail(r(N)-2,`t')
	
	local r18 : display %9.3f `p'
	local l18 = "p-value of correlation of original n- and replication p-values"
restore


/// [19]
preserve
	collapse endprice, by(study)
	sum      endprice

	local r19 : display %9.2f r(mean)*100
	local l19 = "mean prediction market final price (in %)"
restore


/// [20]
preserve
	collapse endprice, by(study)
	sum      endprice

	local r20 : display %9.2f r(min)*100
	local l20 = "lowest prediction market final price (in %)"
restore


/// [21]
preserve
	collapse endprice, by(study)
	sum      endprice

	local r21 : display %9.2f r(max)*100
	local l21 = "highest prediction market final price (in %)"
restore


/// [22]
	local r22 : display %9.2f `r19'
	local l22 = "expected replications (in %)"


/// [23]
preserve
	collapse result, by(study)
	sum      result

	local r23 : display %9.2f r(mean)*100
	local l23 = "replication rate (in %)"
restore


/// [24]
preserve
	collapse endprice result, by(study)
	gen      correctly_predicted = 0
	replace  correctly_predicted = 1 if endprice > 0.5 & result == 1
	replace  correctly_predicted = 1 if endprice < 0.5 & result == 0
	sum      correctly_predicted

	local r24 : display %9.2f r(mean)*100
	local l24 = "correctly predicted by final price (in %)"
restore


/// [25]
  local r25 : display %9.0f `r24'*0.18
	local l25 = "number of correctly predicted studies (in absolute terms)"


/// [26]
preserve
	collapse endprice result, by(study)
	gen      correctly_predicted = 0
	replace  correctly_predicted = 1 if endprice > 0.5 & result == 1
	replace  correctly_predicted = 1 if endprice < 0.5 & result == 0
	bitest   correctly_predicted == 0.5, detail

	local r26 : display %9.3f r(p)
	local l26 = "(two-sided p-value of binomial test (correctly predicted = 0.5)"
restore


/// [27]
preserve
	collapse endprice result, by(study)
  
	replace result=2 if result==0
	esize   twosample endprice, by(result) pbcorr
	
	local r27 : display %9.3f r(r_pb)
	local l27 = "point-biserial correlation coefficient"
restore


/// [28]
preserve
	collapse endprice result, by(study)

	replace result=2 if result==0
	ttest   endprice, by(result)
	
	local r28 : display %9.3f r(p)
	local l28 = "p-value of point-biserial correlation"
restore


/// [29]
  reg   result endprice, robust
	
	local r29 : display %9.3f _b[endprice]
	local l29 = "coefficient of endprice in LPM"
	
	
/// [30]
	reg   result endprice, robust
	test  endprice = 0
	
	local r30 : display %9.3f r(p)
	local l30 = "p-value for coefficient test different from 0"


/// [31]
	reg   result endprice, robust
	test  endprice = 1
	
	local r31 : display %9.3f r(p)
	local l31 = "p-value for coefficient test different from 1"


/// [32]
	reg   result endprice, robust
	
	local r32 : display %9.3f _b[_cons]
	local l32 = "coefficient of constant in LPM"


/// [33]
	reg   result endprice, robust
	
	local r33 : display %9.3f _b[_cons]/_se[_cons]
	local l33 = "t-value of coefficient of constant in LPM"
	
	
/// [34]
	reg   result endprice, robust
	test  _cons = 0
	
	local r34 : display %9.3f r(p)
	local l34 = "p-value for coefficient test different from 0"


/// [35]
preserve
	keep if active==1 // Only keep traders who traded on the market
	collapse preqrep result, by(study)
	
	gen      correctly_predicted = 0
	replace  correctly_predicted = 1 if preqrep > 0.5 & result == 1
	replace  correctly_predicted = 1 if preqrep < 0.5 & result == 0
	
	sum      correctly_predicted
	
	local r35 : display %9.2f r(mean)*100
	local l35 = "survey mean correctly predicted (in %)"	
restore


/// [36]
	local r36 : display %9.0f `r35'*0.18
	local l36 = "number of studies correctly predicted by surveys"


/// [37]
preserve
	keep if active==1 // Only keep traders who traded on the market
	collapse preqrep result, by(study)
	
	gen      correctly_predicted = 0
	replace  correctly_predicted = 1 if preqrep > 0.5 & result == 1
	replace  correctly_predicted = 1 if preqrep < 0.5 & result == 0
	bitest   correctly_predicted == 0.5, detail

	local r37 : display %9.3f r(p)
	local l37 = "(two-sided p-value of binomial test (correctly predicted = 0.5)"
restore


/// [38]
preserve
	keep if active==1 // Only keep traders who traded on the market
	collapse endprice preqrep result, by(study)

	local r38 = "to clarify: absolute prediction error"
	local l38 = "t-value of paired t-test (absolute prediction error)"
restore


/// [39]
preserve
	keep if active==1 // Only keep traders who traded on the market
	collapse endprice preqrep result, by(study)

	local r39 = "to clarify: absolute prediction error"
	local l39 = "p-value of paired t-test (absolute prediction error)"
restore

/// [40] mean/median replication power


******************
*** UNNUMBERED ***
******************

/// SM "The Pearson correlation between the market prices and the pre-market survey"
preserve
	keep if active==1 // Only keep traders who traded on the market
	collapse preqrep endprice, by(study)
	pwcorr preqrep endprice, sig obs
restore

/// SM "market price and survey range and a mean"
preserve
	keep if active==1 // Only keep traders who traded on the market
	collapse preqrep endprice, by(study)
	sum preqrep endprice
restore

/// SM "The point-biserial correlation coefficient between the pre-survey and the outcome of the replication"
preserve
	keep if active==1 // Only keep traders who traded on the market
	collapse preqrep result, by(study)
  
	replace result=2 if result==0
	esize   twosample preqrep, by(result) pbcorr
	
	pwcorr result preqrep, sig obs
restore

/// SM "The absolute prediction error pre-market survey"




********************************************************************************
*** Display Results ***
********************************************************************************
global n = 39
forvalues i = 1 (1) $n {
	dis "------------------------------------------------------------------------"
	dis "Result [`i']: `l`i''"
	dis "`r`i''"
	dis "------------------------------------------------------------------------"
}


