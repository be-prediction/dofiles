clear

// Eskil's path to parent folder:
global STATAPATH = "/Users/es.3386/Google Drive/Doktorand/Behavioral pred. markets/Stata/"

cd "${STATAPATH}"

*do "do-private/anonymize_data.do"
do "dofiles/create_studydetails.do"
do "dofiles/create_data.do"
