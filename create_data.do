clear
cd "${STATAPATH}"


// Parameters
global b = 100
global k = 1


/* Clean RPP data
---------------------------------------------------------*/
import delimited "../raw/rpp_data.csv", encoding(ISO-8859-1)
save "../use/rpp-data.dta", replace


/* Clean RPP market data
---------------------------------------------------------*/
import excel "../raw/rpp-market-data.xlsx", sheet("table_ZRoutvA(1).csv") firstrow clear
rename Hypothesis study
rename C hypothesis
rename Outcomeoforiginalstudy resultorig
rename Outcomeofreplicationyesno resultrep
rename Marketprice endprice
rename Surveyresult preqrep
rename Weightedsurveyresult preqrep_w
rename OriginalN norig
rename Originalpower poworig
rename ReplicationN nrep
rename Replicationpower powrep
rename Replicationpvalue prep
rename NumberOfTrades transactions
rename Vol volume
drop A sdev_survey

foreach var in resultorig resultrep preqrep preqrep_w nrep p2{
	replace `var' = "" if `var'=="NA"
	destring `var', replace
}

foreach var in resultorig resultrep{
	replace `var'="1" if `var'=="Yes"
	replace `var'="0" if `var'=="No"
	destring `var', replace
}

replace prep = "0.001" if prep=="<0.001"
replace prep = "0.00001" if prep=="<0.00001"
destring prep, replace

save "../use/rpp-market-data.dta", replace


/* Create trader-list
---------------------------------------------------------*/
use "../raw/prediction-market-user-final-credit.dta", clear
gen int active=(credit<100)
drop credit

save "../use/activetraders.dta", replace


/* Clean final holdings
---------------------------------------------------------*/
use "../raw/prediction-market-user-share-positions", clear

gen int study =.
replace study=1 if market=="Abeler et al. (AER 2011)"
replace study=2 if market=="Ambrus and Greiner (AER 2012)"
replace study=3 if market=="Bartling et al. (AER 2012)"
replace study=4 if market=="Charness and Dufwenberg (AER 2011)"
replace study=5 if market=="Chen and Chen (AER 2011)"
replace study=6 if market=="de Clippel et al. (AER 2014)"
replace study=7 if market=="Duffy and Puzzello (AER 2014)"
replace study=8 if market=="Dulleck et al. (AER 2011)"
replace study=9 if market=="Fehr et al. (AER 2013)"
replace study=10 if market=="Friedman and Oprea (AER 2012)"
replace study=11 if market=="Fudenberg et al. (AER 2012)"
replace study=12 if market=="Huck et al. (AER 2011)"
replace study=13 if market=="Ifcher and Zarghamee (AER 2011)"
replace study=14 if market=="Kessler and Roth (AER 2012)"
replace study=15 if market=="Kirchler et al (AER 2012)"
replace study=16 if market=="Kogan et al. (AER 2011)"
replace study=17 if market=="Kuziemko et al. (QJE 2014)"
replace study=18 if market=="Marzilli Ericson and Fuster (QJE 2011)"

drop market

label define study 1 "Abeler et al. (AER 2011)" ///
2 "Ambrus and Greiner (AER 2012)" ///
3 "Bartling et al. (AER 2012)" ///
4 "Charness and Dufwenberg (AER 2011)" ///
5 "Chen and Chen (AER 2011)" ///
6 "de Clippel et al. (AER 2014)" ///
7 "Duffy and Puzzello (AER 2014)" ///
8 "Dulleck et al. (AER 2011)" ///
9 "Fehr et al. (AER 2013)" ///
10 "Friedman and Oprea (AER 2012)" ///
11 "Fudenberg et al. (AER 2012)" ///
12 "Huck et al. (AER 2011)" ///
13 "Ifcher and Zarghamee (AER 2011)" ///
14 "Kessler and Roth (AER 2012)" ///
15 "Kirchler et al (AER 2012)" ///
16 "Kogan et al. (AER 2011)" ///
17 "Kuziemko et al. (QJE 2014)" ///
18 "Marzilli Ericson and Fuster (QJE 2011)"

label values study study

save "../use/finalholdings.dta", replace


/* Clean final credit
---------------------------------------------------------*/
use "../raw/prediction-market-user-final-credit", clear
save "../use/finalcredit.dta", replace


/* Clean pre-market survey data
---------------------------------------------------------*/
use "../raw/pre-market-survey.dta", clear
keep v8 v9 v10 q* userid
drop q1

rename v8 startdate
rename v9 enddate
rename v10 finished
rename q2 position
label variable position "Academic position"
rename q3 yiacad
label variable yiacad "Years in academia"
rename q4 age
label variable age "Age"
rename q5 gender
label variable gender "Gender"
rename q6 affiliation
label variable affiliation "Affiliation"
rename q7 country
label variable country "Country of residence"
rename q8 nationality
label variable nationality "Nationality"
rename q9 core
label variable core "Core fields of research"

local i=1
local study = 1
foreach var of varlist q* {
	if `i'>5{
		local i = 1
		local study = `study'+1
	}
	if `i'==1{
		local q="a"
	}
	else if `i'==2{
		local q="b"
	}
	else if `i'==3{
		local q="c"
	}
	else if `i'==4{
		local q="d"
	}
	else if `i'==5{
		local q="e"
	}
	rename `var' q`q'`study'
	local i = `i'+1
}

destring finished, replace
destring yiacad, replace
destring age, replace
destring q*, replace

gen double startdate2 = clock(startdate, "YMDhms")
order startdate2, after(startdate)
format startdate2 %tc
label variable startdate "Start date"
drop startdate
rename startdate2 startdate

gen double enddate2 = clock(enddate, "YMDhms")
order enddate2, after(enddate)
format enddate2 %tc
label variable enddate "Start date"
drop enddate
rename enddate2 enddate


// Only used finished survey for participants who've started many
duplicates tag userid, generate(dup)
drop if finished==0 & dup!=0
drop dup


// Keep only last survey for participants who finished more than one (!)
duplicates tag userid, generate(dup)
bysort userid finished (enddate): gen last=(_n==_N)
drop if dup==1 & finished==1 & last!=1
drop last dup


// Only keep participants who were invited to the market
merge 1:1 userid using "../use/activetraders.dta"
drop _merge
label variable active "Active trader in the markets"
keep if active!=.


// Save
preserve
drop q*
save "../temp/pre-market-survey-wide.dta", replace
restore


// Reshape long
drop startdate enddate position yiacad age gender affiliation country nationality core active finished

reshape long qa qb qc qd qe, i(userid) j(study)

rename qa preqrep
label variable preqrep "Likelihood of hypothesis to replicate (1st survey)"
rename qb preqrepcon
label variable preqrepcon "Confidence in likelihood of hypothesis to replicate (1st survey)"
rename qc qpri
label variable qpri "Final trading price (1st survey)"
rename qd qpricon
label variable qpricon "Confidence in final trading price (1st survey)"
rename qe qkno
label variable qkno "Knowledge of topic (1st survey)"

merge m:1 userid using "../temp/pre-market-survey-wide.dta"
drop _merge

rename startdate prestartdate
label variable prestartdate "Start date of first survey"
rename enddate preenddate
label variable preenddate "End date of first survey"
rename finished prefinished
label variable prefinished "First survey finished"


// Rescale likelihood answers from 0-100 to 0-1
replace preqrep = preqrep/100

save "../use/pre-market-survey.dta", replace


/* Clean post-market survey data
---------------------------------------------------------*/
use "../raw/post-market-survey.dta", clear
keep v8 v9 v10 q* userid
drop q1
drop q104 // Free text answers

rename v8 startdate
rename v9 enddate
rename v10 finished

local i=1
local study = 1
foreach var of varlist q* {
	if `i'>2{
		local i = 1
		local study = `study'+1
	}
	if `i'==1{
		local q="a"
	}
	else if `i'==2{
		local q="c"
	}
	rename `var' q`q'`study'
	local i = `i'+1
}

destring finished, replace
destring q*, replace

gen double startdate2 = clock(startdate, "YMDhms")
order startdate2, after(startdate)
format startdate2 %tc
label variable startdate "Start date"
drop startdate
rename startdate2 startdate

gen double enddate2 = clock(enddate, "YMDhms")
order enddate2, after(enddate)
format enddate2 %tc
label variable enddate "Start date"
drop enddate
rename enddate2 enddate


// Only used finished survey for participants who've started many
duplicates tag userid, generate(dup)
drop if finished==0 & dup!=0
drop dup


// Keep only last survey for participants who finished more than one (!)
duplicates tag userid, generate(dup)
bysort userid finished (enddate): gen last=(_n==_N)
drop if dup==1 & finished==1 & last!=1
drop last dup


// Only keep participants who were traded in the markets
merge 1:1 userid using "../use/activetraders.dta"
drop _merge
label variable active "Active trader in the markets"
drop if active == 0


// Reshape long
reshape long qa qc, i(startdate enddate finished userid) j(study)

rename startdate poststartdate
label variable poststartdate "Start date of second survey"
rename enddate postenddate
label variable postenddate "End date of second survey"
rename finished postfinished
label variable postfinished "Second survey finished"

rename qa postqrep
label variable postqrep "Likelihood of hypothesis to replicate (2nd survey)"
rename qc postqrepcon
label variable postqrepcon "Confidence in likelihood of hypothesis to replicate (2nd survey)"


// Rescale likelihood answers from 0-100 to 0-1
replace postqrep = postqrep/100

save "../use/post-market-survey.dta", replace



/* Clean transaction data
---------------------------------------------------------*/
use "../raw/prediction-market-transactions.dta", clear

merge m:1 userid using "../raw/prediction-market-user-final-credit.dta", keep(match master)
drop _merge

rename tranasctionid transactionid

gen int study =.
replace study=1 if market=="Abeler et al. (AER 2011)"
replace study=2 if market=="Ambrus and Greiner (AER 2012)"
replace study=3 if market=="Bartling et al. (AER 2012)"
replace study=4 if market=="Charness and Dufwenberg (AER 2011)"
replace study=5 if market=="Chen and Chen (AER 2011)"
replace study=6 if market=="de Clippel et al. (AER 2014)"
replace study=7 if market=="Duffy and Puzzello (AER 2014)"
replace study=8 if market=="Dulleck et al. (AER 2011)"
replace study=9 if market=="Fehr et al. (AER 2013)"
replace study=10 if market=="Friedman and Oprea (AER 2012)"
replace study=11 if market=="Fudenberg et al. (AER 2012)"
replace study=12 if market=="Huck et al. (AER 2011)"
replace study=13 if market=="Ifcher and Zarghamee (AER 2011)"
replace study=14 if market=="Kessler and Roth (AER 2012)"
replace study=15 if market=="Kirchler et al (AER 2012)"
replace study=16 if market=="Kogan et al. (AER 2011)"
replace study=17 if market=="Kuziemko et al. (QJE 2014)"
replace study=18 if market=="Marzilli Ericson and Fuster (QJE 2011)"

label define study 1 "Abeler et al. (AER 2011)" ///
2 "Ambrus and Greiner (AER 2012)" ///
3 "Bartling et al. (AER 2012)" ///
4 "Charness and Dufwenberg (AER 2011)" ///
5 "Chen and Chen (AER 2011)" ///
6 "de Clippel et al. (AER 2014)" ///
7 "Duffy and Puzzello (AER 2014)" ///
8 "Dulleck et al. (AER 2011)" ///
9 "Fehr et al. (AER 2013)" ///
10 "Friedman and Oprea (AER 2012)" ///
11 "Fudenberg et al. (AER 2012)" ///
12 "Huck et al. (AER 2011)" ///
13 "Ifcher and Zarghamee (AER 2011)" ///
14 "Kessler and Roth (AER 2012)" ///
15 "Kirchler et al (AER 2012)" ///
16 "Kogan et al. (AER 2011)" ///
17 "Kuziemko et al. (QJE 2014)" ///
18 "Marzilli Ericson and Fuster (QJE 2011)"

label values study study
order userid study, after(market)
drop market

foreach var in "numshares" "netsales" "price"{
	replace `var'="" if `var'=="NULL"
	destring `var', replace
}

drop if numshares==. // Drop failed transactions (CHECK THIS)

replace timestamped = substr(timestamped,1,19)
gen double timestamp = clock(timestamped, "YMDhms")
order timestamp, after(timestamped)
format timestamp %tc
label variable timestamp "Transaction time"
drop timestamped

/* Note: These seem to have been mislabeled in original data, CHECK THIS */
rename buy1orsell1 direction
label variable direction "Increase (1) or decrease (-1) position"
label define direction 1 "Increase" -1 "Decrease"
label values direction direction
rename increase1ordecreaseposition1 ordertype
label variable ordertype "Buy new shares (1) or sell existing shares (-1)"
label define ordertype 1 "Buy" -1 "Sell"
label values ordertype ordertype
order ordertype, before(direction)


/* Add share positions */
bysort userid study (transactionid): egen finalholdings = total(numshares)
label var finalholdings "User's final holdings in the market"


/* Correct cash position calculations */
bysort study userid (timestamp): gen userholdings = numshares if _n==1
gen returned = 0
gen invested = 0
gen cash = .
bysort userid study (timestamp): replace invested = points if _n==1
bysort userid study (timestamp): gen first=(_n==1)
label var returned "Increase in cash holdings from transaction"
label var invested "Decrease in cash holdings from transaction"
label var cash "User's cash holdings"
label var userholdings "User's share holdings in the market"
forval n = 1/2080{
	if first[`n']!=1{
		replace userholdings= userholdings[`n'-1]+numshares[`n'] if [_n]==`n'
		if ordertype[`n']==1{
		// User is buying new shares (and thus doesn't already hold in position)
			replace invested=points[`n'] if [_n]==`n'
		}
		else if ordertype[`n']==-1 & abs(numshares[`n'])<=abs(userholdings[`n'-1]){
		// User is selling fewer shares than currently holding
			replace returned=points[`n'] if [_n]==`n'
		}	
		else if ordertype[`n']==-1 & abs(numshares[`n'])>abs(userholdings[`n'-1]){
		// User is selling more shares than currently holding (i.e. investing some in other direction)
			local newinvestment = abs(abs(userholdings[`n'-1])-abs(numshares[`n']))
			local S2 = netsales[`n']
			local S1 = netsales[`n'] - `newinvestment' * direction[`n']
			if direction[`n']==-1{
				// Share overshoot is invested in NO
				local investment = abs(${b}*${k}*(ln(1+exp(-`S2'/${b}))-ln(1+exp(-`S1'/${b}))))
			}
			else if direction[`n']==1{
				// Share overshoot is invested in YES
				local investment = abs(${b}*${k}*(ln(1+exp(`S2'/${b}))-ln(1+exp(`S1'/${b}))))
			}
			replace invested = round(`investment',0.01) if [_n]==`n' // Rounding to match original calculations CHECK THIS
			replace returned = points[`n']-round(`investment',0.01) if [_n]==`n'
		}
		else {
			display as error "Conditions not exhaustive"
			exit 111
		}
	}
}
drop first

bysort userid (timestamp): replace cash=round(100-invested,0.1) if _n==1
bysort userid (timestamp): replace cash=round(cash[_n-1]-invested+returned,0.1) if _n!=1
replace cash = round(cash,0.1)

/* Check that final cash is correct */
//bysort userid (timestamp): gen final=(_N==_n)
//bro credit cash if final==1 & credit!=cash
/* Small differences due to rounding issues with selling for tiny share positions, overall fine. */

save "../use/transactions.dta", replace

/* Gen study summary */
preserve

drop if numshares==.
sort userid study timestamp

gen volume = abs(numshares)

collapse (last) timestamp (last) price (count) transactionid  (last) netsales (sum) volume, by(userid study)
sort study timestamp
collapse (last) price (count) userid (sum) transactionid (last) netsales (sum) volume, by(study)

rename price endprice
label var endprice "Final price"
rename userid traders
label var traders "Number of traders in the market"
rename transactionid transactions
label var transactions "Number of transactions in the market"
rename netsales endsales
label var endsales "Final sales in the market"
label var volume "Number of shares traded in the market"

save "../temp/studysummary.dta", replace

restore


/* Gen trader summary */
preserve
bysort userid study (timestamp): gen investmentworth = invested if _n==1
bysort userid study (timestamp): replace investmentworth = max(investmentworth[_n-1]+invested-returned,0) if _n!=1
sort userid study timestamp
bysort userid study: egen meantokens = mean(invested) if invested!=0
collapse (count) transactionid (sum) direction (last) finalholdings (last) investmentworth (max) meantokens, by(userid study)
rename transactionid C
rename direction S
gen int decreasecount = . // a
gen int increasecount = . // b
replace decreasecount = (C-S)/2
replace increasecount = decreasecount + S

// To get how many increase/decrease transactions were made
// -a + b = S
//  a + b = C
//  S + a = b
//  a + S + a = C => a = (C - S)2

drop C S

/* Check that finalholdings are correct */
// merge 1:1 userid study using "use/finalholdings.dta", keep(match master)
/* finalholdings are exactly the same result as those in "prediction-market-user-share-positions" */

/* Add system's final credit */
merge m:1 userid using "../use/finalcredit.dta", keep(match master)
drop _merge
rename credit finalcredit

label var meantokens "Average tokens invested"
label var decreasecount "Number of user decrease transactions"
label var increasecount "Number of user increase transactions"
label var finalcredit "User's final credit"
label var finalholding "User's final share holdings in market"
label var investmentworth "Purchasing price of user's final share holdings"

save "../temp/tradersummary.dta", replace

restore


/* Combine surveys and add trader and study summaries
---------------------------------------------------------*/
use "../use/pre-market-survey.dta", clear
label values study study

merge 1:1 userid study using "../use/post-market-survey.dta"
drop _merge

order active userid study preqrep preqrepcon postqrep postqrepcon qpri qpricon qkno age gender yiacad position affiliation country nationality core  prestartdate preenddate prefinished poststartdate postenddate postfinished

replace yiacad = "5" if yiacad=="Currently PhD Candidate at McGill University, expected graduation Spring 2015"
replace yiacad = "14" if yiacad=="do not have a PhD, 14 years teaching "
replace yiacad = "" if yiacad=="N/A"
destring yiacad, replace

replace gender="" if gender=="-99"
replace gender="0" if gender=="Female"
replace gender="1" if gender=="Male"
label define gender 0 "Female" 1 "Male"
destring gender, replace
label values gender gender

replace position="" if position=="-99"
encode position, gen(position2)
order position2, after(position)
drop position
rename position2 position

gen premin = (preenddate - prestartdate)/(1000*60)
label variable premin "Minutes spent on 1st survey"
gen postmin = (postenddate - poststartdate)/(1000*60)
label variable postmin "Minutes spent on 2st survey"
order premin postmin, after(qkno)


/* Add study summary */
merge m:1 study using "../temp/studysummary.dta", keep(match master)
order endprice traders transactions volume endsales, after(study)
drop _merge

/* Add trader summary */
merge 1:1 userid study using "../temp/tradersummary.dta", keep(match master)
drop _merge
bysort userid: egen temp = max(finalcredit)
replace temp = 100 if temp==.
replace finalcredit=temp
drop temp
replace finalholdings=0 if finalholdings==.
replace decreasecount=0 if decreasecount==.
replace increasecount=0 if increasecount==.
replace meantokens=0 if meantokens==.
replace investmentworth=0 if investmentworth==.

order finalholdings finalcredit increasecount decreasecount meantokens investmentworth, after(qkno)

/* Add study details */
merge m:1 study using "../use/studydetails.dta", keep(match master)
drop _merge


/* Add priors */
gen p1 = (endprice-a1)/(powrep_plan-a1) // Since all replicated findings are positive, use planned power as that's what traders knew
gen p0 = p1*a0/(p1*a0+(1-p1)*poworig) // Since all replicated findings are positive
gen p2 = .
replace p2 = ((endprice-a1)*powrep_plan)/(endprice*(powrep_plan-a1)) if result==1
replace p2 = ((endprice-a1)*(1-powrep_plan))/((1-endprice)*(powrep_plan-a1)) if result==0
order p1 p2, after(p0)


/* Create relative effect sizes */
gen erel = erep/eorig
label var erel "Relative effect size (r) of replication to original"


/* Save */
save "../use/marketsurveysummary.dta", replace
