% Convert Tiny Imperative Language "for" statements to "while" form
% Jim Cordy, August 2005

% This program converts all "for" statements in a TIL program to
% their equivalent "while" form

% Some details assumed:
%
% - It is not clear whether TIL is scoped or not.  We assume not
%   since there is no explicit scoping statement in the language.
%
% - The "for" statement of TIL is a "declaring for".
%   We assume this means it automatically declares its control variable.
%
% These assumptions can be trivially changed here if TIL changes.

% Based on the TIL grammar
include "TIL.grm"

% Preserve comments in output
include "TILCommentOverrides.Grm"

% Rule to convert every "for" statement
rule main
    % Capture each "for" statement, in its statement sequence context 
    % so that we can replace it with multiple statements
    replace [statement*]
	'for Id [id] := Expn1 [expression] 'to Expn2 [expression] 'do
	    Statements [statement*]
	'end
	MoreStatements [statement*]

    % Need a unique new identifier for the upper bound
    construct UpperId [id]
    	Id [_ 'Upper] [!]

    % Construct the iterator
    construct IterateStatement [statement]
	Id := Id + 1;

    % Replace the whole thing
    by
	'var Id;
	Id := Expn1;
	'var UpperId;
	UpperId := (Expn2) + 1;
	'while Id - UpperId 'do
	    Statements [. IterateStatement]
	'end
	MoreStatements
end rule
