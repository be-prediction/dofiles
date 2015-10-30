clear
cd "${STATAPATH}"

use "use/marketsurveysummary.dta", clear
collapse endprice preqrep* post* result, by(study)
reg result endprice
test endprice==1
