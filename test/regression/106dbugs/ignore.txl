#pragma --multiline

% ignore tokens should not apply when compiling TXL source

tokens
    ignore    "&\c*"
end tokens

define program
    [repeat token]
end define

function main
    match [program] 
	% this SHOULD be a syntax error!
	_ [program] & garbage
end function

