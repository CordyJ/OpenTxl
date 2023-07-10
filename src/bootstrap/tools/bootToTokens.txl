% OpenTxl Version 11 bootstrap grammar
% J.R. Cordy, July 2022

% Copyright 2022, James R. Cordy and others

% Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
% and associated documentation files (the “Software”), to deal in the Software without restriction, 
% including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
% and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, 
% subject to the following conditions:

% The above copyright notice and this permission notice shall be included in all copies 
% or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
% INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE 
% AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

% Abstract

% This utility program is used in creating the pre-scanned TXL boostrap grammar (bootgrm.i)
% to create an initialized array of the tokens of a TXL grammar as string literals.

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b.

comments
        '%
end comments

tokens
        quote           "'"
        dotdotdot       "..."
end tokens

define program
        [repeat token_NL]
end define

define token_NL
        [token_or_string] [NL]
end define

define token_or_string
        [token]
    |   [stringlit]
end define

function main
        replace [program] 
                Tokens [repeat token_NL]
        by
                Tokens [convertToStrings]
end function

rule convertToStrings
        replace $ [token_or_string]
                T [token_or_string]
        construct S [stringlit]
                _ [quote T]
        by
                S       
end rule
