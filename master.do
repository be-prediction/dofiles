clear

// Eskil's path to parent folder:
global STATAPATH = "/Users/es.3386/Google Drive/Doktorand/Behavioral pred. markets/Stata/"

cd "${STATAPATH}"

*do "do-private/anonymize_data.do" // Not available to public
*do "dofiles/create_studydetails.do"  // Not available to public until results are official
do "dofiles/create_data.do"
