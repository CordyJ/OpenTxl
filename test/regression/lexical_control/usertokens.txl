% Demo of the use of the *very dangerous* ability to 
% define your own input token lexical conventions.

tokens
    % These define new input tokens
    hexnumber	"[\dabcdefABCDEF]+H"
    octalnumber	"0[01234567]*"

    % This extends the default definition for [id]
    % to allow identifiers with -, +, #, $ or % in them.
    % If we had not used + before the pattern string, this
    % would *replace* the defintion for [id],
    % a very dangerous thing to do since the TXL program 
    % itself might itself not be scannable using the new definition.
    id		+ "[\i-\+\#$%]+"
end tokens

define program
    [thing*] 
end define

define thing
    [id] | [number] | [hexnumber] | [octalnumber]
end define

rule main
    replace [thing*]
	H [hexnumber]
	Rest [thing*]
    by
	0777
	Rest
end rule
