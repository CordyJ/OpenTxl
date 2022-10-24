# OpenTxl Version 11 boot build process
# J.R. Cordy, July 2022

# Copyright 2022, James R. Cordy and others

# This process converts the Txl language boot grammar to a pre-scanned table 
# that can be rapidly loaded into the Txl parser

BOOTSTRAP=Txl-11-bootstrap

all: clean bootgrm.i

${BOOTSTRAP}.tokens: ${BOOTSTRAP}.grm
	txl -q ${BOOTSTRAP}.grm tools/bootToTokens.txl > ${BOOTSTRAP}.tokens

${BOOTSTRAP}.tokentable: ${BOOTSTRAP}.tokens
	sort -u ${BOOTSTRAP}.tokens > ${BOOTSTRAP}.tokentable

${BOOTSTRAP}.tokenfinds: ${BOOTSTRAP}.tokens
	cp ${BOOTSTRAP}.tokens ${BOOTSTRAP}.tokenfinds
	sed -e "s/.*/grep -n '&' ${BOOTSTRAP}.tokentable/" -e "s/\[/\\\\[/" -e "s/]/\\\\]/" -e "s/\./\\\\./g" -e "s/\*/\\\\*/" -e "s/'\"'\"'/\"\\\\\"\\\\'\\\\\"\"/" < ${BOOTSTRAP}.tokens > ${BOOTSTRAP}.tokenfinds

${BOOTSTRAP}.tokenindexes: ${BOOTSTRAP}.tokens ${BOOTSTRAP}.tokentable ${BOOTSTRAP}.tokenfinds
	sh ${BOOTSTRAP}.tokenfinds | sed 's/:.*//' > ${BOOTSTRAP}.tokenindexes

${BOOTSTRAP}.tokenarray: ${BOOTSTRAP}.tokentable
	cat ${BOOTSTRAP}.tokentable | sed 's/$$/,/' | paste -d ' ' - - - - | sed -e 's/^/    /' -e '$$s/, *$$//' > ${BOOTSTRAP}.tokenarray

${BOOTSTRAP}.tokenindexarray: ${BOOTSTRAP}.tokenindexes
	cat ${BOOTSTRAP}.tokenindexes | sed 's/$$/,/' | paste -d ' ' - - - - - - - - - - - - - - - - - - - - | sed -e 's/^/    /' -e '$$s/, *$$//' > ${BOOTSTRAP}.tokenindexarray

define editscript
ntokens=`wc -l < ${BOOTSTRAP}.tokentable`
nindexes=`wc -l < ${BOOTSTRAP}.tokenindexes`
ex - bootgrm.i << EOF
/%%BOOTFILE%%/s//${BOOTSTRAP}.grm/
/%%NUMTOKENS%%/s//$$ntokens/
/%%NUMINDEXES%%/s//$$nindexes/
/%%BOOTINDEXES%%/r ${BOOTSTRAP}.tokenindexarray
/%%BOOTINDEXES%%/d
/%%BOOTTOKENS%%/r ${BOOTSTRAP}.tokenarray
/%%BOOTTOKENS%%/d
w
q
EOF
endef
export editscript

bootgrm.i: templates/bootgrm-template.i ${BOOTSTRAP}.tokens ${BOOTSTRAP}.tokentable ${BOOTSTRAP}.tokenarray ${BOOTSTRAP}.tokenindexarray
	cp templates/bootgrm-template.i bootgrm.i
	eval "$$editscript"
	/bin/rm -f ${BOOTSTRAP}.token*

clean:
	/bin/rm -f ${BOOTSTRAP}.token* bootgrm.i
