% OpenTxl Version 11 error codes
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

% Txl processor error codes
% Part 1 of error handling: needed by options.i and others.
% Part 2 fully defines error reporting routines later, in synerr.i

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston


% Error message handling
forward procedure error (context : string, message : string, severity : int, code : int)

% Error severity
const * INFORMATION := 0
const * WARNING := 1
const * LIMIT_WARNING := 2

const * DEFERRED := 10

const * FATAL := 20
const * LIMIT_FATAL := 21
const * INTERNAL_FATAL := 22

% Exceptions
const * outOfTrees := 951
const * outOfKids := 952
const * parseTooDeep := 961
const * cutPoint := 962
const * stackLimitReached := 971
const * timeLimitReached := 972
const * cycleLimitReached := 973

% Source file names
const * maxFiles := 1024
var fileNames : array 1 .. maxFiles of string
var nFiles := 0

% Stack exhaustion detection
var stackBase : addressint

procedure setStackBase
    % Initialize physical recursion stack limitation
    var dummy : int
    stackBase := addr (dummy) + 4096  % reserve 4k for interrupts etc.
end setStackBase

setStackBase

