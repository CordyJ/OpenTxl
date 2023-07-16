% Accepts source lines of a TXL program, and creates a 
% multi-numbered listing, numbering only the non-blank, non-comment lines.

% Include files are resolved, and non-blank, non-comment lines are numbered
% with source file depth, logical line number within file, and 
% logical line number in program, for example:
%
%     Depth    Local  Global	Source
%     -----    -----  ------	------
%				% Include line defines
%	1	22	55	include "linedefs.def"
%				% Line defines file version 3.5
%				
%	2	1	56	define interestingline
%	2	2	57		[includeline]
%	2	3	58	    |	[nonblankline]
%	2	4	59	end define

% As a good example run, try:
%	txl RS.Txl linenum.Txl > RS.listing

#pragma -char -width 2048

tokens
	blankline	"[ 	]*\n"
	commentline	"[ 	]*%#n*\n"
	includeline	"[ 	]*include[ 	]*\"#\"*\"[ 	]*\n"
	nonblankline	"#n+\n"
end tokens

define program
	[repeat line]
end define

define line
	[blankline] 
    |	[TAB_25] [commentline] 
    |	[interestingline] 
    |	[number] [TAB_9] [number] [TAB_17] [opt number] [TAB_25] [interestingline]
end define

define interestingline
	[includeline]
    |	[nonblankline]
end define

function main
	replace [program]
		Lines [repeat line]
	by
		Lines [resolveIncludes 1] [numberLines 1] [numberGlobalLines]
end function

rule numberLines D [number]
	export LN [number]
		0
	replace $ [line]
		L [interestingline] 
	import LN
	export LN
		LN [+ 1]
	by
		D LN L 
end rule

rule numberGlobalLines 
	export GN [number]
		0
	replace $ [line]
		D [number] LN [number] L [interestingline] 
	import GN
	export GN
		GN [+ 1]
	by
		D LN GN L 
end rule

rule resolveIncludes Depth [number]
	replace $ [repeat line]
		IncludeLine [includeline] 
		RestOfLines [repeat line]
	construct IncludeFileName [stringlit]
		_ [extractFileName IncludeLine]
	construct IncludeFileLines [repeat line]
		_ [read IncludeFileName]
	construct DepthPlus1 [number]
		Depth [+ 1]
	construct ResolvedIncludeLine [repeat line]
		IncludeLine
	by
		IncludeLine 
		IncludeFileLines [resolveIncludes DepthPlus1] [numberLines DepthPlus1]
		    [. RestOfLines]
end rule

function extractFileName IncludeLine [includeline]
	construct IncludeLineAsString [stringlit]
		_ [unparse IncludeLine]
	construct FileNameStart [number]
		_ [index IncludeLineAsString ''"'] [+ 1]
	assert FileNameStart [> 1]
	construct FileNameTail [stringlit]
		IncludeLineAsString [: FileNameStart 999]
	construct FileNameEnd [number]
		_ [index FileNameTail ''"'] [- 1]
	construct FileName [stringlit]
		FileNameTail [: 1 FileNameEnd]
	replace [stringlit]
		_ [stringlit]
	by
		FileName
end function
