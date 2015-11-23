clear
cd "${STATAPATH}"

use "../use/marketsurveysummary.dta", clear

******************
*** MAIN PAPER ***
******************

// Table 1. Replication results
preserve
	collapse eorig erep erel porig prep result, by(study)
	foreach var in porig prep{
		replace `var' = 0.00001 if `var'<=0.00001
		format `var' %12.6f
	}
	gen ref = study
	order ref, after(study)
	label def result 1 "Yes" 0 "No"
	label values result result
	outsheet using "../tables/tab-1.csv", replace noquote comma	
restore


// Fig 1. Replication results 95% confidence intervals of normalized standardized replication
// effectsizes (correlation coefficient r).
preserve 
	collapse ereprel ereprell ereprelu, by(study)
	drop if ereprel==.
	sort ereprel
	gen order = 19-study
	gen errorl = abs(ereprell-ereprel)
	gen erroru = abs(ereprel-ereprelu)
	drop ereprel?
	outsheet using "../graphs/fig-1.csv", replace noquote comma
restore


// Fig 2. Normalized meta-analytic estimates of effect sizes combining the original and replication studies. 
// 95% confidence intervals of standardized effect sizes (correlation coefficient r).
preserve 
	collapse emetarel emetarell emetarelu, by(study)
	drop if emetarel==.
	sort emetarel
	gen order = 19-study
	gen errorl = abs(emetarell-emetarel)
	gen erroru = abs(emetarel-emetarelu)
	drop emetarel?
	outsheet using "../graphs/fig-2.csv", replace noquote comma
restore


// Fig 3. A comparison of different reproducibility indicators between experimental economics
// and psychological sciences (the Reproducibility Project Psychology)
preserve
	
	* Econ
	keep if active==1
	collapse result eorig erep emeta erepl erepu emetal emetau endprice preqrep, by(study)
	
	sum result // Replicated with P<0.05 in original direction
	gen originrepci = (eorig>=erepl & eorig<=erepu) // Original effect size within replication 95% CI
	gen metasig = (emetal>0) // Meta-analytic estimate significant in the original direction
	gen rele = erep/eorig // Replication effect-size (% of original effect size)
	sum endprice // Prediction markets beliefs about replication
	sum preqrep // Survey beliefs about replication
	
	collapse result originrepci metasig rele endprice preqrep
	
	mkmat *, matrix(summary)
	mat def summary = [summary \ [.,.,.,.,.,.]]'
	
	* Psych
	use "../use/rpp-market-data.dta", clear
	
	collapse endprice preqrep
	replace endprice=endprice/100 // Prediction markets beliefs about replication
	qui sum endprice
	mat def summary[rownumb(summary,"endprice"), 2] = r(mean)
	
	replace preqrep=preqrep/100 // Survey beliefs about replication
	qui sum preqrep
	mat def summary[rownumb(summary,"preqrep"), 2] = r(mean)
	
	gen result = 35/97 // Replicated with P<0.05 in original direction (from RPP-paper)
	qui sum result
	mat def summary[rownumb(summary,"result"), 2] = r(mean)
	
	gen originrepci = 45/95 // Original effect size within replication 95% CI (from RPP-paper)
	qui sum originrepci
	mat def summary[rownumb(summary,"originrepci"), 2] = r(mean)
	
	gen metasig = 51/75 // Meta-analytic estimate significant in the original direction (from RPP-paper)
	qui sum metasig
	mat def summary[rownumb(summary,"metasig"), 2] = r(mean)
	
	use "../use/rpp-data.dta", clear
	keep studynum t_rr t_ro t_pval_user t_pval_useo
	
	foreach var in t_rr t_ro t_pval_useo{
		replace `var'="" if `var'=="NA"
		destring `var', replace
	}
	
	*** !NOTE! ***
	* The original effect size mean is slightly different
	* from what's reported in the RPP paper, this is not an error
	* as same thing is given with original R scripts and current data
	
	gen rele = t_rr/t_ro
	qui sum rele if studynum!=26 & studynum!=89 & studynum!=135
	mat def summary[rownumb(summary,"rele"), 2] = r(mean)
	
	* Combined
	clear
	svmat summary
	rename summary1 econ
	rename summary2 psych
	
	gen measure = _n
	
	outsheet using "../graphs/fig-3.csv", replace noquote comma
	
restore


// Fig 4. The Spearman correlation between the original p-value 
// and the original sample size and different reproducibility indicators.
preserve
	keep if active==1
	collapse result eorig erep emeta erepl erepu emetal emetau endprice preqrep porig norig, by(study)
	
	sum result // Replicated with P<0.05 in original direction
	gen originrepci = (eorig>=erepl & eorig<=erepu) // Original effect size within replication 95% CI
	gen metasig = (emetal>0) // Meta-analytic estimate significant in the original direction
	gen rele = erep/eorig // Replication effect-size (% of original effect size)
	sum endprice // Prediction markets beliefs about replication
	sum preqrep // Survey beliefs about replication
	
	keep result originrepci metasig rele endprice preqrep porig norig
	
	mat def summary = [.,.,.,.\.,.,.,.\.,.,.,.\.,.,.,.\.,.,.,.\.,.,.,.]
	local i=1
	foreach var in result originrepci metasig rele endprice preqrep{
		qui spearman `var' porig
		mat def summary[`i',1] = r(rho)
		if r(p)<=0.05{
			mat def summary[`i',2] = 1
		}
		else{
			mat def summary[`i',2] = 0
		}
		qui spearman `var' norig
		mat def summary[`i',3] = r(rho)
		if r(p)<=0.05{
			mat def summary[`i',4] = 1
		}
		else{
			mat def summary[`i',4] = 0
		}
		local i=`i'+1
	}
	
	clear
	svmat summary
	rename summary1 porig
	rename summary2 porig_sig
	rename summary3 norig
	rename summary4 norig_sig
	
	foreach var in porig_sig norig_sig{
		tostring `var', replace
		replace `var' = "" if `var'=="0"
		replace `var' = "*" if `var'=="1"
	}
	
	gen measure = _n
	
	outsheet using "../graphs/fig-4.csv", replace noquote comma

restore



*******************************
*** SUPPLEMENTARY MATERIALS ***
*******************************

// Table S1. Prediction market results for the 18 replication studies
preserve
	collapse porig eorig prep erep result erel, by(study)
	gen ref = study
	order ref, after(study)
	label def result 1 "Yes" 0 "No"
	label values result result
	foreach var in porig prep{
		replace `var' = 0.00001 if `var'<=0.00001
		format `var' %12.6f
	}
	outsheet using "../tables/tab-s1.csv", replace noquote comma
restore

// Table S3. Prediction market results for the 18 replication studies
preserve
	collapse result endprice poworig powrep_plan powrep_act p0 p1 p2, by(study)
	gen ref = study
	order ref, after(study)
	label def result 1 "Yes" 0 "No"
	label values result result
	rename powrep_plan powrepplan
	rename powrep_act powrepact
	replace powrepact=. if powrepact==powrepplan
	outsheet using "../tables/tab-s3.csv", replace noquote comma
restore

// Table S4. Survey results for the 18 replication studies.
preserve
	bysort study: egen preqrepmeanall = mean(preqrep)
	bysort study: egen preqrepmeanactive = mean(preqrep) if active==1

	keep if active==1

	collapse result endprice preqrepmeanactive preqrepmeanall postqrep, by(study)
	gen ref = study
	order ref, after(study)
	label def result 1 "Yes" 0 "No"
	label values result result
	outsheet using "../tables/tab-s4.csv", replace noquote comma
restore

// Table S5. Additional prediciton market results for the 18 replication studies.
preserve
	keep if active==1
	collapse result endprice volume investedpoints traders transactions, by(study)
	gen ref = study
	order ref, after(study)
	label def result 1 "Yes" 0 "No"
	label values result result
	outsheet using "../tables/tab-s5.csv", replace noquote comma
restore

// Table S6.
preserve
	keep if active==1
	collapse result eorig erep emeta erepl erepu emetal emetau endprice preqrep porig norig, by(study)

	gen originrepci = (eorig>=erepl & eorig<=erepu) // Original effect size within replication 95% CI
	gen metasig = (emetal>0) // Meta-analytic estimate significant in the original direction
	gen rele = erep/eorig // Replication effect-size (% of original effect size)
	
	keep result originrepci metasig rele endprice preqrep porig norig
	order result originrepci metasig rele endprice preqrep porig norig

	spearman *
	mat def rho = r(Rho)
	mat def p = r(P)
	clear
	svmat rho
	svmat p
	
	// Format
	gen order = _n
	gen type = 1
	set obs 16
	replace order = _n - 8 if order==.
	replace type=2 if type==.
	forval i = 1/8{
		forval j = 1/8{
			if `j'<=`i'{
				replace rho`j'=p`j'[`i'] if _n==[8+`i']
			}
			else{
				replace rho`j'=. if _n==[`i']
			}
		}
		format rho`i' %12.3f
	}
	drop p?
	sort order type
	
	forval i=1/8{
		tostring rho`i', replace force u
		replace rho`i' = "" if rho`i'=="."
		replace rho`i' = "("+ rho`i' + ")" if type==2 & rho`i'!=""
	}
	
	label def measures 1 "Replicated P<0.05" 2 "Original within 95<CI" 3 "Meta-estimate P<0.05" ///
	4 "Relative effect size" 5 "Prediction markets beliefs" 6 "Survey beliefs" ///
	7 "Original p-value" 8 "Original sample size"
	label values order measures
	order order
	replace order=. if type==2
	drop type

	outsheet using "../tables/tab-s6.csv", replace noquote comma
restore

// Fig S1. Comparison of original and replication effect sizes
preserve
	collapse result eorig erep, by(study)
	outsheet using "../graphs/fig-s1.csv", replace noquote comma
restore

// Fig S3. Final positions per participant and market.
preserve
	keep if active==1
	collapse finalholdings, by(study userid)
	gen int holdingtype=.
	replace holdingtype=1 if finalholdings>0
	replace holdingtype=-1 if finalholdings<0
	replace holdingtype=0 if finalholdings==0
	sort userid study
	
	local i = 1
	forval j=-1(1)1{
		gen temp = (holdingtype==`j')
		bysort userid: egen type`i' = total(temp)
		drop temp
		local i=`i'+1
		
	}
	gsort type2 -type3 type1 userid	
	
	gen int tempid = .
	forval id = 1/97{
		replace tempid = `id' if (`id'-1)*18<_n & _n<=`id'*18
	}
	
	keep study tempid holdingtype
	outsheet using "../graphs/fig-s3.csv", replace noquote comma nolab
restore
	
// Fig S4. Comparison of survey responses and prediction market prices.
preserve
	keep if active==1
	collapse result endprice preqrep, by(study)
	reg preqrep endprice
	mat def b=e(b)'
	mat colnames b=linearfit
	svmat b, names(col)
	outsheet using "../graphs/fig-s4.csv", replace noquote comma
restore



