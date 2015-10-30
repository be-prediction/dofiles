clear
cd "${STATAPATH}"

use "use/marketsurveysummary.dta", clear

replace result = 3 if result ==.

/* Data for graphs 
-------------------------*/
collapse endprice preqrep postqrep porig eorig prep erep powrep_plan result p0 p1 p2, by(study)
gen releorig = 1
gen relerep = erep/eorig
replace relerep = 3 if relerep>3
sort relerep
gen releorder = _n
sort endprice
gen priceorder = _n
replace prep = round(prep,0.01)
gen preprest = prep
replace preprest = 0.1 if preprest>0.1
gen prepmarker = ""
replace prepmarker = "*" if prep<=0.05
replace prepmarker = "square*" if prep>0.05


preserve
keep if result==1
outsheet using "graphs/studysummary_repyes.dat", replace nolabel noquote comma
restore
preserve
keep if result==0
outsheet using "graphs/studysummary_repno.dat", replace nolabel noquote comma
restore
preserve
keep if result==3
outsheet using "graphs/studysummary_repunknown.dat", replace nolabel noquote comma
restore


outsheet using "graphs/studysummary.dat", replace nolabel noquote comma



/* Data for boxplots
-------------------------*/
*use "scrambled/marketsurveysummary_scrambled.dta", clear
use "use/marketsurveysummary.dta", clear
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
outsheet using "graphs/priorbox.dat", replace nolabel noquote comma



/* Time series for markets
---------------------------------*/
use "use/transactions.dta", clear
sort study timestamp

// Add beginning and end prices
local newtot = _N + 36
set obs `newtot'
forval i = 1/18{
	replace study = `i' if _n == _N+1-`i'
	replace price = .5 if _n == _N+1-`i'
	replace timestamp = clock("20150423020000", "YMDhms") if _n == _N+1-`i'
	replace netsales = 0 if _n == _N+1-`i'
	// End:
	replace study = `i' if _n == _N+1-`i'-18
	replace timestamp = clock("20150504020000", "YMDhms") if _n == _N+1-`i'-18
}
bysort study (timestamp): replace netsales = netsale[_n-1] if _n==_N & netsales==.
bysort study (timestamp): replace price = price[_n-1] if _n==_N & price==.


forval study=1/18{
	local name: label study `study'
	qui sum study if study==`study'
	local studyno = r(mean)
	twoway (connected price timestamp if study==`study', mcolor(green) msize(vsmall) msymbol(circle)) ///
	, ytitle(Price) yscale(range(0 1)) ylabel(#10, angle(forty_five)) yline(0.5, lpattern(dash) lcolor(gray)) ///
	xtitle(Timestamp) xlabel(#20, angle(forty_five) grid) xmtick(none, labels) ///
	title(`name') subtitle(Study `studyno') legend(order(1 "Price"))
	graph export "graphs/study`studyno'_timeseries.png", replace
}



/* Results summary table (before results)
---------------------------------*/
use "use/marketsurveysummary.dta", clear
collapse endprice preqrep postqrep porig prep result p0 p1 p2, by(study)
/*
tostring result, replace
replace result = "Yes" if result=="1"
replace result = "No" if result=="0"
replace result = "NA" if result=="."
*/

mkmat *, mat(summary) rowname(study)
local varlabels ""
forval i=1/18{
	local name: label study `i'
	local varlabels  `varlabels'  `i' "`name'"
}
display `"`varlabels'"'
estout matrix(summary, fmt(%12.2g %12.2f %12.2f %12.2f %12.3f %12.3f %12.0f %12.2f %12.2f %12.2f)) using "tables/resultssummary.tex", ///
replace style(tex) ml(,none lhs(%)) coll(,none lhs(%)) ///
varlabels(1 "Abeler et al. (AER 2011)" "`varlabels'") ///
nolz


/* Market summary table (before results)
---------------------------------*/
use "use/marketsurveysummary.dta", clear
gen holds_yes = (finalholdings>0)
gen holds_no = (finalholdings<0)
collapse traders transactions (sum) holds_yes (sum) holds_no (mean) endsales endprice, by(study)
mkmat *, mat(summary) rowname(study)
local varlabels ""
forval i=1/18{
	local name: label study `i'
	local varlabels  `varlabels'  `i' "`name'"
}
display `"`varlabels'"'
estout matrix(summary, fmt(%12.2g %12.2g %12.2g %12.2g %12.2g %12.2f %12.2f)) using "tables/marketsummary.tex", ///
replace style(tex) ml(,none lhs(%)) coll(,none lhs(%)) ///
varlabels(1 "Abeler et al. (AER 2011)" "`varlabels'") ///
nolz
