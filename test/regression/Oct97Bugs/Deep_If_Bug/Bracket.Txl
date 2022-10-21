% LS Cobol Record Bracketing
% J.R. Cordy, July 1995

% Copyright 1995,1996 Legasys Corporation

% Revision history:

% 3.3	Removed erroneous '. after EJECT - JRC 22.8.95
% 3.3.2	Removed [uncommentEjects] rule, now handled by TXL scanner - JRC 14.9.95
% 3.5	Added handling of doubled and misplaced periods - JRC 19.10.95
%
% 4.0	Removed handling of doubled and misplaced periods.
%		Updated to handle 4.0 grammars.
%		Fixed bugs related to missing [comment]s in patterns - JRC 13.11.95
% 4.1	Radically redesigned reparsing rules for speed.
%		Added bracketing rule - JRC 17.11.95
% 4.2	Removed faster reparsing rules since the assumptions on which they
%		were based do not hold for our clients' disgusting code - JRC 17.12.95
% 4.3	Updated to take advantage of TXL 8.2 one-pass rules - JRC 16.5.96 
% 4.4	Reorganized to increase opportunities for garbage collection   - JRC/TD 22.5.96 
% 4.5	Changed to be main TXL program   - JRC 24.5.96 
% 4.6   Added Global Grammar Correction include - T.D.  June 17, 1996.
% 4.6   Added Global Grammar Correction include - T.D.  June 17, 1996.
% 4.7	Tuned for speed by adding intermediate one-pass rule to call chain - JRC 30.6.96
%
% 5.0	Complete rewrite to use outside-in strategy for better performance
%		Renamed Bracket.Txl to maintain our sanity
%		Fixed problems with creation of empty brackets for some non-groups - JRC 4.10.96
% 5.1	Added LS Cobol Boolean conversion operator ? to references to 88's - JRC 10.12.96
% 5.2   Fixed LS Cobol Boolean conversion operator ? to references to 88's to handle 88's
%       with copy id's appended to the name in the declaration DTC 3.1.97
% 6.0   TD Jan 20/97
%		 - update for grammar 7.0
%		 - treat 66 like 77. Next Time parsed, will be parsed correctly.
% 6.1	DTC Jan 20, 1997
%		 - update to take output file as a parameter and added parameter checking.
% 6.2	DTC Jan 31, 1997
%		 - update to end with [quit 0] to override writing to stdout since output file
%		   is passed as a parameter.
% 6.3	JRC	3 April 1997
%		 - strengthened inference of undeclared 88's from [condition_expression] to [condition_primary]
% 6.4	RATH May 08, 1997
%		 - added a pass to rename anonymous fields (eg 05 PIC X.) as LEGA-ANON-FIELD. 
%		 - removed the padding of level numbers with zeroes.
%		 - added verbosity checking


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	LSCobol standard grammar, overrides to support bracketing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

include "LSCobol7.Grammar"
include "GlobalOverrides.Grammar"
include "BracketOverrides.Grammar"
include "CheckParametersLib"



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This ruleset does three things:
%	(1) Normalizes level numbers, e.g., changes 1 to 01.
%	(2) Inserts bracketing to permanently document the record nesting structure
%	    for later transforms.
%	(3) Disambiguates Boolean expressions by inserting the explicit Boolean
%		conversion operator ? for references to 88's.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function main
	construct RuleVer [stringlit]
		_ [DoBannerIfVerbosityHighEnough]

	replace [program] 
		P [program]

    import argv [stringlit*]
    where
		argv [checkHasValue "-o" "BRK0002E"]
    construct OutputFile [stringlit]
		_ [GetValueAsStringLit "-o"]

	by
		P [unformatLevel1]
%		  [normalizeLevelNumbers] % Should not be changing level numbers.
		  [addRecordBrackets]
		  [reformatLevel1]
		  [addBooleanConversions]
		  [nameAnonymousFields]
		  %% [write OutputFile]
%		  [quit 0]
end function

function DoBannerIfVerbosityHighEnough
	import argv [repeat stringlit]
	
	construct VerbosityStr [stringlit]
		_ [GetValueAsStringLit "-v"]
		
	where not
		VerbosityStr [= ""]
		
	construct Verbosity [number]
		_ [parse VerbosityStr]
		
	where
		Verbosity [> 0]
	
	construct Message [stringlit]
		_ [+ "LSCobol Bracketing 6.4 (08 May 1997)"]
	  	  [print]
		
	match [stringlit]
		P [stringlit]
end function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This rule names anonymous fields (eg. 05 PIC X.) with a special _ANON name
% (eg. 05 LEGA-ANON-FIELD PIC X.).  Clean will then remove this special name.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule nameAnonymousFields
	replace [opt decl_name]
		% Nada		
	by
		'LEGA-ANON-FIELD
end rule

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These two rules play tricks with the grammatical category of 01 level numbers.
% [unformatLevel1] categorizes 01's as [number] so that the bracketing rules need 
% not special case them.  
% [reformatLevel1] recategorizes 01's as [level_1] in order to get proper 
% formatting in output.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function unformatLevel1
    construct New01 [level_number]
    	'01
    construct L101 [level_1]
    	'01
    construct Old01 [level_number]
    	L101
    replace [program]
        P [program]
    by
    	P [$ Old01 New01]
end function

function reformatLevel1
    construct Old01 [level_number]
    	'01
    construct L101 [level_1]
    	'01
    construct New01 [level_number]
    	L101
    replace [program]
        P [program]
    by
    	P [$ Old01 New01]
end function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [normalizeLevelNumbers] makes sure that any one digit level numbers are
% converted to standard two digit form.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function normalizeLevelNumbers
    construct UnnormalizedLevelNumbers [repeat level_number]
    	 '1 '2  '3  '4  '5  '6  '7  '8  '9
    construct NormalizedLevelNumbers [repeat level_number]
    	'01 '02 '03 '04 '05 '06 '07 '08 '09
    replace [program]
        P [program]
    by
        P [$ each UnnormalizedLevelNumbers NormalizedLevelNumbers]
end function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These rules do the actual bracketing.  
% The strategy is a direct implementation of the IBM Cobol level number rule.  
% If an immediately following item has a higher level number than an item, 
% then the first item is by definition a group regardless of its other attributes.  
% The group ends at the first following item with a level number
% less than or equal to the group item's level number.
% (*** This intepretation verified on the IBM Cobol/370 compiler - JRC/TD 4.10.96)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule addRecordBrackets
	replace $ [record_description]
		RD [record_description]
	by
		RD [addLevelNBrackets]
end rule

function addLevelNBrackets
	replace * [repeat record_item]
		N [number] Item [item_description]		
		MoreItems [repeat record_item]
	deconstruct * [level_number] MoreItems
		N2 [number]
	where all
		N2 [> N] [~= 77] [~= 66]
	by
		N Item 
			'[ MoreItems [headToLevel N] [addLevelNBrackets] ']
	    MoreItems [tailFromLevel N] [addLevelNBrackets]
end function

function headToLevel N [number]
	replace * [repeat record_item]
		N2 [number] Item [item_description]
		MoreItems [repeat record_item]
	where
		N2 [<= N] [= 77] [= 66]
	by
		% nada
end function

function tailFromLevel N [number]
	replace [repeat record_item]
		N2 [number] Item [item_description]
		MoreItems [repeat record_item]
	where all
		N2 [> N] [~= 77] [~= 66]
	by
		MoreItems [tailFromLevel N]
end function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [addBooleanConversions] adds ? operators to every reference to 88's as
% a Boolean condition.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function addBooleanConversions
	replace [program]
		P [program]
	construct level_88s [repeat level_88_description]
		_ [^ P]
	construct new_level_88s [repeat level_88_description]
		level_88s [removeCopyIds]
	by
		P [addBooleanConversionsFor88s_condition new_level_88s]
		  [addBooleanConversionsFor88s_arithmetic new_level_88s]
		  [checkForUndeclared88s]
end function

rule addBooleanConversionsFor88s_condition level_88s [repeat level_88_description]
    replace $ [condition_primary]
	    Id [id] Qualifiers [repeat qualifier] Subscript [opt subscript]
	deconstruct * [level_88_description] level_88s
		'88  Id Value [value_clause] '. 
	by
		'? Id Qualifiers Subscript
end rule

rule addBooleanConversionsFor88s_arithmetic level_88s [repeat level_88_description]
    replace $ [arithmetic_primary]
	    Id [id] Qualifiers [repeat qualifier] Subscript [opt subscript]
	deconstruct * [level_88_description] level_88s
		'88  Id Value [value_clause] '. 
	by
		'? Id Qualifiers Subscript
end rule

rule removeCopyIds
	replace $ [level_88_description]
		'88 OldId [id] Value [value_clause] '. 
	construct TextofOldId [stringlit]
		_ [quote OldId]
	construct Underscore [stringlit]
		"_"
	construct IndexofUnderScore [number]
		_ [index TextofOldId Underscore]
	where
		IndexofUnderScore [> 0]
	construct EndIndex [number]
		IndexofUnderScore [- 1]
	construct TextofNewId [stringlit]
		TextofOldId [: 1 EndIndex]	
	construct NewId [id]
		_ [unquote TextofNewId]
	by
		'88 NewId Value '. 
end rule
	
rule checkForUndeclared88s
	replace $ [condition_primary]
		Id [id]
	construct Message [stringlit] _ [+ "* BRK0001W - Undeclared 88 - "] [quote Id] [+" used in a condition expression"] [print]
	by
		? Id
end rule
