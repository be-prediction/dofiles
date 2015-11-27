clear
cd "${STATAPATH}"

use "../use/marketsurveysummary.dta", clear

******************
*** MAIN PAPER ***
******************

// Table 1. Replication results
preserve
	collapse ref eorig erep erel porig prep result, by(study)
	sort ref
	foreach var in porig prep{
		replace `var' = 0.00001 if `var'<=0.00001
		format `var' %12.6f
	}
	label def result 1 "Yes" 0 "No"
	label values result result
	outsheet using "../tables/tab-1.csv", replace noquote comma	
restore


// Fig 1. Replication results 95% confidence intervals of normalized standardized replication
// effectsizes (correlation coefficient r).
preserve 
	collapse ref ereprel ereprell ereprelu, by(study)
	sort ref
	gen order = 19-_n
	gen errorl = abs(ereprell-ereprel)
	gen erroru = abs(ereprel-ereprelu)
	// Update labels:
	forval s=1/18{
		local name: label study `s'
		qui sum ref if study==`s'
		local ref = r(mean)
		local newname = subinstr(subinstr("`name'", " (", ", ", .), ")", "", .) + " (`ref')"
		label define study `s' "`newname'", modify
	}
	drop ereprel? ref
	outsheet using "../graphs/fig-1.csv", replace noquote delimiter(";")
restore


// Fig 2. Normalized meta-analytic estimates of effect sizes combining the original and replication studies. 
// 95% confidence intervals of standardized effect sizes (correlation coefficient r).
preserve 
	collapse ref emetarel emetarell emetarelu, by(study)
	drop if emetarel==.
	sort ref
	gen order = 19-_n
	gen errorl = abs(emetarell-emetarel)
	gen erroru = abs(emetarel-emetarelu)
	// Update labels:
	forval s=1/18{
		local name: label study `s'
		qui sum ref if study==`s'
		local ref = r(mean)
		local newname = subinstr(subinstr("`name'", " (", ", ", .), ")", "", .) + " (`ref')"
		label define study `s' "`newname'", modify
	}
	drop emetarel? ref
	outsheet using "../graphs/fig-2.csv", replace noquote delimiter(";")
restore


// Fig 3. A comparison of different reproducibility indicators between experimental economics
// and psychological sciences (the Reproducibility Project Psychology)
use "../use/marketsurveysummary.dta", clear
	
	mat drop _all

	mat def econ = [.,.,.\.,.,.\.,.,.\.,.,.\.,.,.\.,.,.]
	mat def psych = econ
	
	mat def pvalues = [.\.\.\.\.\.]
	
	/// [33a] Replicated with P<0.05 in original direction
	preserve
		keep if active==1
		collapse result, by(study)
		sum result

		local e = r(mean)
		local eN = r(N)
		local eSE = sqrt((`e'*(1-`e'))/`eN')
		 
		mat def econ[1,1]=`e'
		mat def econ[1,2]=`eSE'
		mat def econ[1,3]=`eN'
		
		local p = 35/97 
		local pN = 97
		local pSE = sqrt((`p'*(1-`p'))/`pN')
		mat def psych[1,1]=`p'
		mat def psych[1,2]=`pSE'
		mat def psych[1,3]=`pN'
		
		prtesti `eN' `e' `pN' `p'
		mat def pvalues[1,1]=2*(1-normal(abs(r(z))))
	restore
	
	/// [33b] Original effect size within replication 95% CI
	preserve
		keep if active==1
		collapse eorig erepl erepu, by(study)
		gen originrepci = (eorig>=erepl & eorig<=erepu)
		sum originrepci
		local e = r(mean)
		local eN = r(N)
		local eSE = sqrt((`e'*(1-`e'))/`eN')
		mat def econ[2,1]=`e'
		mat def econ[2,2]=`eSE'
		mat def econ[2,3]=`eN'
		
		local p = 45/95
		local pN = 95
		local pSE = sqrt((`p'*(1-`p'))/`pN')
		mat def psych[2,1]=`p'
		mat def psych[2,2]=`pSE'
		mat def psych[2,3]=`pN'
		
		prtesti `eN' `e' `pN' `p'
		mat def pvalues[2,1]=2*(1-normal(abs(r(z))))
	restore
	
	/// [33c] Meta-analytic estimate significant in the original direction
	preserve
		keep if active==1
		collapse emetal, by(study)
		gen metasig = (emetal>0)
		sum metasig
		local e = r(mean)
		local eN = r(N)
		local eSE = sqrt((`e'*(1-`e'))/`eN')
		mat def econ[3,1]=`e'
		mat def econ[3,2]=`eSE'
		mat def econ[3,3]=`eN'
		
		local p = 51/75
		local pN  = 75
		local pSE = sqrt((`p'*(1-`p'))/`pN')
		mat def psych[3,1]=`p'
		mat def psych[3,2]=`pSE'
		mat def psych[3,3]=`pN'
		
		prtesti `eN' `e' `pN' `p'
		mat def pvalues[3,1]=2*(1-normal(abs(r(z))))
	restore
	
	/// [33d] Replication effect-size (% of original effect size)
	preserve
		keep if active==1
		collapse erep eorig, by(study)
		gen rele = erep/eorig
		sum rele
		local e = r(mean)
		local eN = r(N)
		local eSE = r(sd)/sqrt(`eN')
		mat def econ[4,1]=`e'
		mat def econ[4,2]=`eSE'
		mat def econ[4,3]=`eN'
		
		mean rele 
		
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
		local pSE = r(sd)/sqrt(`pN')
		mat def psych[4,1]=`p'
		mat def psych[4,2]=`pSE'
		mat def psych[4,3]=`pN'
		
		gen project = 2
		mkmat rele project, matrix(rele_psych)
		
		mat def compare = [rele_econ \ rele_psych]
		
		clear
		svmat compare, names(col)
		
		ranksum rele, by(project) // Two-sample Wilcoxon rank-sum (Mann-Whitney) test
		mat def pvalues[4,1]=2*(1-normal(abs(r(z))))
	restore
	
	/// [33e] Prediction markets beliefs about replication
	preserve
		keep if active==1
		collapse endprice, by(study)
		sum endprice
		local e = r(mean)
		local eN = r(N)
		local eSE = r(sd)/sqrt(`eN')
		mat def econ[5,1]=`e'
		mat def econ[5,2]=`eSE'
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
		local pSE = r(sd)/sqrt(`pN')
		mat def psych[5,1]=`p'
		mat def psych[5,2]=`pSE'
		mat def psych[5,3]=`pN'
		
		gen project = 2
		mkmat endprice project, matrix(endprice_psych)
	
		mat def compare = [endprice_econ \ endprice_psych]
		
		clear
		svmat compare, names(col)
		
		ranksum endprice, by(project) // Two-sample Wilcoxon rank-sum (Mann-Whitney) test
		mat def pvalues[5,1]=2*(1-normal(abs(r(z))))
	restore
	
	
	/// [33f] Survey beliefs about replication
	preserve
		keep if active==1
		collapse preqrep, by(study)
		sum preqrep
		local e = r(mean)
		local eN = r(N)
		local eSE = r(sd)/sqrt(`eN')
		mat def econ[6,1]=`e'
		mat def econ[6,2]=`eSE'
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
		local pSE = r(sd)/sqrt(`pN')
		mat def psych[6,1]=`p'
		mat def psych[6,2]=`pSE'
		mat def psych[6,3]=`pN'
		
		gen project = 2
		mkmat preqrep project, matrix(preqrep_psych)
	
		mat def compare = [preqrep_econ \ preqrep_psych]
		
		clear
		svmat compare, names(col)
		
		ranksum preqrep, by(project) // Two-sample Wilcoxon rank-sum (Mann-Whitney) test
		mat def pvalues[6,1]=2*(1-normal(abs(r(z))))
	restore
	
	
	mat def compare = [econ,psych,pvalues]
	
	clear
	svmat compare
	
	rename compare1 e
	rename compare2 eSE
	rename compare3 eN
	rename compare4 p
	rename compare5 pSE
	rename compare6 pN
	rename compare7 pvalue
		
	label def measurename 1 "Replicated P$<$0.05" ///
	2 "Original within 95\% CI" ///
	3 "Meta-estimate P$<$0.05" ///
	4 "Relative effect size" ///
	5 "Prediction markets beliefs" ///
	6 "Survey beliefs"
	gen measure = _n
	label values measure measurename
	
	foreach var in e p{
		gen `var'CI = invnormal(0.975)*`var'SE if measure<=3 // Should really be using correction  +0.5/`var'N
		replace `var'CI = invt(`var'N-1, 0.975)*`var'SE if measure>=4
	}
	
	gen sig = ""
	replace sig = "" if pvalue>0.05
	replace sig = "\textbf{*}" if pvalue<=0.05 & pvalue>0.01
	replace sig = "\textbf{**}" if pvalue<0.01
	
	gen pval = ""
	replace pval = "P$=$0" + string(round(pvalue*1000)/1000)
	replace pval = "P$<$0.001" if pvalue<0.001
	
	sort p
	gen order = _n
	
	drop ?N pvalue
	
	outsheet using "../graphs/fig-3.csv", replace noquote comma
	
use "../use/marketsurveysummary.dta", clear


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
		mat def summary[`i',2] = r(p)
		
		qui spearman `var' norig
		mat def summary[`i',3] = r(rho)
		mat def summary[`i',4] = r(p)
		
		local i = `i'+1
	}
	
	clear
	svmat summary
	rename summary1 porig
	rename summary2 porig_pval
	rename summary3 norig
	rename summary4 norig_pval
	
	foreach var in porig_pval norig_pval{
		replace `var' = 2 if `var'<=0.01 & `var'<1
		replace `var' = 1 if `var'<=0.05 & `var'<1
		replace `var' = 0 if `var'>0.05 & `var'<1
	}
	
	foreach var in porig_pval norig_pval{
		tostring `var', replace
		replace `var' = "" if `var'=="0"
		replace `var' = "*" if `var'=="1"
		replace `var' = "**" if `var'=="2"
	}
	
	label def measurename 1 "Replicated P$<$0.05" ///
	2 "Original within 95\% CI" ///
	3 "Meta-estimate P$<$0.05" ///
	4 "Relative effect size" ///
	5 "Prediction markets beliefs" ///
	6 "Survey beliefs"
	gen measure = _n
	label values measure measurename
	
	// Based on order of figure 3
	gen order = .
	replace order = 1 if measure==1
	replace order = 2 if measure==4
	replace order = 3 if measure==2
	replace order = 4 if measure==6
	replace order = 5 if measure==5
	replace order = 6 if measure==3
	sort order
	
	outsheet using "../graphs/fig-4.csv", replace noquote comma

restore



*******************************
*** SUPPLEMENTARY MATERIALS ***
*******************************

// Table S1. Prediction market results for the 18 replication studies
preserve
	collapse ref porig eorig prep erep result erel erel_ns, by(study)
	sort ref
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
	collapse  ref result endprice poworig powrep_plan powrep_act p0 p1 p2, by(study)
	sort ref
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

	collapse ref result endprice preqrepmeanactive preqrepmeanall postqrep, by(study)
	sort ref
	label def result 1 "Yes" 0 "No"
	label values result result
	outsheet using "../tables/tab-s4.csv", replace noquote comma
restore

// Table S5. Additional prediciton market results for the 18 replication studies.
preserve
	keep if active==1
	collapse ref result endprice volume investedpoints traders transactions, by(study)
	sort ref
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
	collapse ref finalholdings, by(study userid)
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
	
	keep ref tempid holdingtype
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

// Fig S5. Prediction markets beliefs and survey beliefs
preserve
	collapse ref endprice preqrep result, by(study)
	sort endprice
	gen order = _n
	
	outsheet using "../graphs/fig-s5.csv", replace noquote comma
	outsheet using "../graphs/fig-s5_rep.csv" if result==1, replace noquote comma
	outsheet using "../graphs/fig-s5_norep.csv" if result==0, replace noquote comma	
restore


// Fig S6. Probability of a hypothesis being "true" at three different stages of testing
preserve
	local j=0
	forval i=0/3{
		local if
		if `i'==2{
			local if "if result==0"
		}
		else if `i'==3{
			local if "if result==1"
			local j = 2
		}
		egen lw`i' = min(p`j') `if'
		egen uw`i' = max(p`j') `if'
		egen med`i' = pctile(p`j') `if', p(50)
		egen lq`i' = pctile(p`j') `if', p(25)
		egen uq`i' = pctile(p`j') `if', p(75)
		local j = `j' + 1
	}
	
	collapse ?w? med? ?q?
	
	gen temp = _n
	reshape long lw uw med lq uq, j(prior) i(temp)
	drop temp
	outsheet using "../graphs/fig-s6.csv", replace noquote comma
restore
