% Antoniol et al heuristic to resolve all #ifs in C programs
% Jim Cordy, Feb 2008

% Comments out all preprocessor statements, and all #elsif and #else parts
% to leave the body of the then part of all #ifs only

% Still some small remaining bugs that need to be hand-fixed - JRC 28.4.08

#pragma -char -comment -esc '\\' -width 32767

comments
	/* */
end comments

compounds
	//
end compounds

tokens
    % A preprocessor line is one beginning with a # and then anything to end of line (\n#n*)
    % If the line ends in backslash, then it continues on the next line (\\\n)
    % Comments are assumed to be part of the preprocessor line (/\*#[(\*/)]*\*/)
    ifdef_line  	  	"[ 	]*\# *if[(\\\n)(/\*#[(\*/)]*\*/)#n]*"
    elsedef_line  	  	"[ 	]*\# *else[(\\\n)(/\*#[(\*/)]*\*/)#n]*"
    elsifdef_line  	  	"[ 	]*\# *elsif[(\\\n)(/\*#[(\*/)]*\*/)#n]*"
    endifdef_line  	  	"[ 	]*\# *endif[(\\\n)(/\*#[(\*/)]*\*/)#n]*"
    other_preprocessor_line	"[ 	]*\#[(\\\n)(/\*#[(\*/)]*\*/)#n]*"
    % Anything else, including line comments, is just a text line to us
    other_line			"#n+"
end tokens

define program
    [repeat line]
end define

define line
	[ifdef]
    | 	[opt //] [other_preprocessor_line] [newline]
    | 	[opt //] [any_other_line] [newline]
end define

define ifdef
	[opt //] [ifdef_line] [newline]
	    [repeat line]
	[repeat elsif_part]
	[opt else_part]
	[opt //] [endifdef_line] [newline]
end define

define elsif_part
	[opt //] [elsifdef_line]  [newline]
	    [repeat line]
end define

define else_part
	[opt //] [elsedef_line]  [newline]
	    [repeat line]
end define

define any_other_line
	[repeat not_newline] 
end define

define not_newline
	[long_comment]
    | 	[not ifdef_token] [not newline] [token]
end define

define long_comment
	[repeat comment_NL] [comment]
end define

define comment_NL
	[comment] [NL]
end define

define ifdef_token
	[ifdef_line]   
    | 	[elsedef_line]   
    | 	[elsifdef_line]   
    | 	[endifdef_line]
end define

function main
	replace [program]
		P [program]
	deconstruct * [newline] P
		NewlineToken [newline]
	construct Newline [stringlit]
		_ [quote NewlineToken]
	export Newline
	by
		P [commentOutPreprocessors]
		  [commentOutIf0s]
		  [resolveIfdefs]
end function

rule resolveIfdefs
	replace [ifdef]
	    IfDef [ifdef_line] NL [newline]
		ThenLines [repeat line]
	    Elsifs [repeat elsif_part]
	    Else [opt else_part]
	    EndIf [endifdef_line] _ [newline]
	by
	    // IfDef [commentContinuationsIfDef] NL 
		ThenLines 
	    Elsifs [commentOut]
	    Else [commentOut]
	    // EndIf[commentContinuationsEndIfDef] NL
end rule

rule commentOutIf0s
	replace [ifdef]
	    IfDef [ifdef_line] NL [newline]
		ThenLines [repeat line]
	    EndIf [endifdef_line] _ [newline]
	where
	    IfDef [grep "if 0"]
	by
	    // IfDef [commentContinuationsIfDef] NL 
		ThenLines [commentOut] 
	    // EndIf[commentContinuationsEndIfDef] NL
end rule

rule commentOutPreprocessors
	replace [line]
	    PrepLine [other_preprocessor_line] NL [newline]
	by
	    // PrepLine [commentContinuationsPrepLine] NL
end rule

rule commentOut
	replace [opt //]
	by
	    //
end rule

rule commentContinuationsIfDef
	import Newline [stringlit]
	replace $ [ifdef_line]
		IfDef [ifdef_line]
	construct NewlineIndex [number]
		_ [index IfDef Newline]
	deconstruct not NewlineIndex
		0
	construct PreNewline [ifdef_line]
		IfDef [: 1 NewlineIndex]
	construct NewlinePlus1 [number]
		NewlineIndex [+1]
	construct PostNewline [ifdef_line]
		IfDef [: NewlinePlus1 9999] [commentContinuationsIfDef]
	by
		PreNewline [+ "//"] [+ PostNewline] 
end rule

rule commentContinuationsEndIfDef
	import Newline [stringlit]
	replace $ [endifdef_line]
		EndIfDef [endifdef_line]
	construct NewlineIndex [number]
		_ [index EndIfDef Newline]
	deconstruct not NewlineIndex
		0
	construct PreNewline [endifdef_line]
		EndIfDef [: 1 NewlineIndex]
	construct NewlinePlus1 [number]
		NewlineIndex [+1]
	construct PostNewline [endifdef_line]
		EndIfDef [: NewlinePlus1 9999] [commentContinuationsEndIfDef]
	by
		PreNewline [+ "//"] [+ PostNewline] 
end rule

rule commentContinuationsPrepLine
	import Newline [stringlit]
	replace $ [other_preprocessor_line]
		PrepLine [other_preprocessor_line]
	construct NewlineIndex [number]
		_ [index PrepLine Newline]
	deconstruct not NewlineIndex
		0
	construct PreNewline [other_preprocessor_line]
		PrepLine [: 1 NewlineIndex]
	construct NewlinePlus1 [number]
		NewlineIndex [+1]
	construct PostNewline [other_preprocessor_line]
		PrepLine [: NewlinePlus1 9999] [commentContinuationsPrepLine]
	by
		PreNewline [+ "//"] [+ PostNewline] 
end rule
