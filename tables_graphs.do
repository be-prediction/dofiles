clear
cd "${STATAPATH}"

use "../use/marketsurveysummary.dta", clear

******************
*** MAIN PAPER ***
******************

// Table 1. Replication results
preserve
collapse eorig erep erel porig prep result, by(study)
mkmat *, mat(summary) rowname(study)
local varlabels ""
forval i=1/18{
	local name: label study `i'
	local varlabels  `varlabels'  `i' "`name'"
}
display `"`varlabels'"'
estout matrix(summary, fmt(%12.2g %12.2f %12.2f %12.2f %12.3g %12.3g %12.2g)) ///
using "../tables/tab-1.tex", ///
replace style(tex) ml(,none lhs(%)) coll(,none lhs(%)) ///
varlabels(1 "Abeler et al. (AER 2011)" "`varlabels'") ///
nolz
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

gen originrepci = 46/97 // Original effect size within replication 95% CI (from RPP-paper)
qui sum originrepci
mat def summary[rownumb(summary,"originrepci"), 2] = r(mean)

gen metasig = 66/97 // Meta-analytic estimate significant in the original direction (from RPP-paper)
qui sum metasig
mat def summary[rownumb(summary,"metasig"), 2] = r(mean)

use "../use/rpp-data.dta", clear
keep t_rr t_ro
foreach var in t_rr t_ro{
	replace `var'="" if `var'=="NA"
	destring `var', replace
}

*** !NOTE! ***
* The original effect size mean is slightly different
* from what's reported in the RPP paper, don't know why

gen rele = t_rr/t_ro
collapse rele
qui sum rele
mat def summary[rownumb(summary,"rele"), 2] = r(mean)

* Combined
clear
svmat summary
rename summary1 econ
rename summary2 psych

gen measure = ""
replace measure = "Replication rate" if _n==1
replace measure = "Original within CI" if _n==2
replace measure = "Meta rate" if _n==3
replace measure = "Rel. effect size" if _n==4
replace measure = "Market" if _n==5
replace measure = "Survey" if _n==6

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

mat def summary = [.,.\.,.\.,.\.,.\.,.\.,.]
local i=1
foreach var in result originrepci metasig rele endprice preqrep{
	qui spearman `var' porig
	mat def summary[`i',1] = r(rho)
	qui spearman `var' norig
	mat def summary[`i',2] = r(rho)
	local i=`i'+1
}

clear
svmat summary
rename summary1 porig
rename summary2 norig

replace porig = abs(porig)

gen measure = ""
replace measure = "Replication rate" if _n==1
replace measure = "Original within CI" if _n==2
replace measure = "Meta rate" if _n==3
replace measure = "Rel. effect size" if _n==4
replace measure = "Market" if _n==5
replace measure = "Survey" if _n==6

outsheet using "../graphs/fig-4.csv", replace noquote comma

restore



*******************************
*** SUPPLEMENTARY MATERIALS ***
*******************************

// Table S1. Prediction market results for the 18 replication studies
preserve
collapse porig eorig prep erep result erel, by(study)

mkmat *, mat(summary) rowname(study)
local varlabels ""
forval i=1/18{
	local name: label study `i'
	local varlabels  `varlabels'  `i' "`name'"
}
display `"`varlabels'"'
estout matrix(summary, fmt(%12.2g %12.2f %12.2f %12.2f %12.2f %12.2g %12.2f)) ///
using "../tables/supmat_tab-s1.tex", ///
replace style(tex) ml(,none lhs(%)) coll(,none lhs(%)) ///
varlabels(1 "Abeler et al. (AER 2011)" "`varlabels'") ///
nolz

restore

// Table S3. Prediction market results for the 18 replication studies
preserve
collapse result endprice poworig powrep_plan p0 p1 p2, by(study)

mkmat *, mat(summary) rowname(study)
local varlabels ""
forval i=1/18{
	local name: label study `i'
	local varlabels  `varlabels'  `i' "`name'"
}
display `"`varlabels'"'
estout matrix(summary, fmt(%12.2g %12.2g %12.2f %12.2f %12.2f %12.2f %12.2f %12.2f)) ///
using "../tables/supmat_tab-s3.tex", ///
replace style(tex) ml(,none lhs(%)) coll(,none lhs(%)) ///
varlabels(1 "Abeler et al. (AER 2011)" "`varlabels'") ///
nolz

restore


// Table S4. Survey results for the 18 replication studies.
preserve
bysort study: egen preqrep_meanall = mean(preqrep)
bysort study: egen preqrep_meanactive = mean(preqrep) if active==1

keep if active==1

collapse result endprice preqrep_meanactive preqrep_meanall postqrep, by(study)

mkmat *, mat(summary) rowname(study)
local varlabels ""
forval i=1/18{
	local name: label study `i'
	local varlabels  `varlabels'  `i' "`name'"
}
display `"`varlabels'"'
estout matrix(summary, fmt(%12.2g %12.2g %12.2g %12.2f %12.2f %12.2f)) ///
using "../tables/supmat_tab-s4.tex", ///
replace style(tex) ml(,none lhs(%)) coll(,none lhs(%)) ///
varlabels(1 "Abeler et al. (AER 2011)" "`varlabels'") ///
nolz

restore


// Table S5. Additional prediciton market results for the 18 replication studies.
preserve
keep if active==1


collapse result endprice volume traders transactions, by(study)

mkmat *, mat(summary) rowname(study)
local varlabels ""
forval i=1/18{
	local name: label study `i'
	local varlabels  `varlabels'  `i' "`name'"
}
display `"`varlabels'"'
estout matrix(summary, fmt(%12.2g %12.2g %12.2f %12.2f %12.2g %12.2g)) ///
using "../tables/supmat_tab-s5.tex", ///
replace style(tex) ml(,none lhs(%)) coll(,none lhs(%)) ///
varlabels(1 "Abeler et al. (AER 2011)" "`varlabels'") ///
nolz
restore


// Fig S3. Comparison of survey responses and prediction market prices.
preserve
keep if active==1
collapse result endprice preqrep, by(study)
reg preqrep endprice
mat def b=e(b)'
mat colnames b=linearfit
svmat b, names(col)
outsheet using "../graphs/fig-s3.csv", replace noquote comma
restore


// Fig S4. Comparison of original and replication effect sizes
preserve
collapse result eorig erep, by(study)
outsheet using "../graphs/fig-s4.csv", replace noquote comma
restore
