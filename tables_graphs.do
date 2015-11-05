clear
cd "${STATAPATH}"

use "../use/marketsurveysummary.dta", clear


*******************************
*** SUPPLEMENTARY MATERIALS ***
*******************************

// Table S4. Survey results for the 18 replication studies.
preserve
bysort study: egen preqrep_meanall = mean(preqrep)
bysort study: egen preqrep_meanactive = mean(preqrep) if active==1

keep if active==1

gen holds_yes = (finalholdings>0)
gen holds_no = (finalholdings<0)

collapse result endprice preqrep_meanactive preqrep_meanall postqrep, by(study)

mkmat *, mat(summary) rowname(study)
local varlabels ""
forval i=1/18{
	local name: label study `i'
	local varlabels  `varlabels'  `i' "`name'"
}
display `"`varlabels'"'
estout matrix(summary, fmt(%12.2g %12.2g %12.2g %12.2f %12.2f %12.2f)) using "../tables/supmat_tab-s4.tex", ///
replace style(tex) ml(,none lhs(%)) coll(,none lhs(%)) ///
varlabels(1 "Abeler et al. (AER 2011)" "`varlabels'") ///
nolz

restore
