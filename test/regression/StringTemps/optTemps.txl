% Optimize string temps used in Turing Plus-generated C source
% by moving them from local to global
% J.R. Cordy, Queen's U., August 1993

include "ANSIC.grm"

% Make this silly language easier to deal with for this transform
% by modfying the grammar 

redefine compound_statement
    { 					[IN] [NL] 
	[declarationsandstatements] 	[EX] 
    } [opt ';] 				[NL] 
end redefine

define declarationsandstatements
        [repeat declarationorstatement]
end define

define declarationorstatement
	[declaration]
    |	[statement]
    |	[preprocessor]	[NL]
    |	[comment] [NL] [repeat comment_NL]
end define

% Now the ruleset

function main
    replace [program]
	P [program]
    by
	P [convertUnsignedCharTemps]
	  [extractStringTemps]
	  [optimizeStringTemps]
end function

rule convertUnsignedCharTemps
    replace [declaration]
	unsigned char UUX [identifier] '[ N [number] '] ;
    where 
	UUX [isTuringTempName]
    by
	TLSTRING UUX ;
end rule

function isTuringTempName
    % See if a C identifier is a Turing temporary name (of the form '__xNNNN')
    match [identifier]
	UUX [id]
    construct UUX3 [id]
	UUX [: 1 3]
    deconstruct UUX3
	'__x
end function

function extractStringTemps
    replace * [repeat externaldefinition+]
	P [repeat externaldefinition+]
    construct StringTempDeclarations [repeat declaration]
	_ [^ P] [removeNonStringTemps] 
    construct NullExternalDeclarations [repeat externaldefinition+]
	'# 'define STRINGTEMPOPT	1
    construct StringTempExternalDeclarations [repeat externaldefinition+]
	NullExternalDeclarations [appendExternalDefinition each StringTempDeclarations]
    by
	StringTempExternalDeclarations [. P]
end function

function appendExternalDefinition SD [declaration]
    deconstruct SD
	TLSTRING UUX [identifier] ;
    construct SED [externaldefinition]
	static TLSTRING UUX ;
    replace [repeat externaldefinition+]
	ED [repeat externaldefinition+]
    by
	ED [. SED]
end function

rule removeNonStringTemps
    replace [repeat declaration]
	DD [declaration]
	Rest [repeat declaration]
    where not
	DD [isStringTempDeclaration] 
    by
	Rest
end rule

function isStringTempDeclaration
    match [declaration]
	'TLSTRING UUX [identifier] ;
    where 
	UUX [isTuringTempName]
end function

rule optimizeStringTemps
    replace [repeat declarationorstatement]
	{
	    'TLSTRING UUX [identifier] ;
	    Scope [repeat declarationorstatement]
	};
	Rest [repeat declarationorstatement]
    where 
	UUX [isTuringTempName]
    by
	Scope [. Rest]
end rule

