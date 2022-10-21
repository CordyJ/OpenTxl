all:	clock.CTxl gtml.CTxl

check.CTxl:	clock.Grammar check.Txl
	txlc check

clock.CTxl:	clock.Grammar gtml.Grammar unravelFunDefs.i clock.Txl \
		coalesceEquations.i depattern.i fixupExpressions.i toGtml.i \
		doImports.i
	txlc clock

gtml.CTxl:	clock.Grammar gtmlcps.Grammar addContinuationParameter.i \
		introduceCpsRequests.i optimize.i gtml.Txl
	txlc gtml

ms.CTxl:	clock.Grammar rvl.Grammar ms.Txl
	txlc ms

ct.CTxl:	ct.Grammar ct.Txl
	txlc ct
