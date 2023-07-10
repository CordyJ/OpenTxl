% OpenTxl Version 11 limits
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

% TXL processor limits
% Maximum limits on sizes of parsing / transformation data structures and processing steps

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston


% Turing+ Limits

% Maximimum string length - unfortunately, this cannot be easily changed
const * maxTuringStringLength := 4095

% TXL Limits

% Maximum preprocessor depth
const * maxIfdefDepth := 32

% Maximimum line length - limits input and output line length
#if CHECKED then
    const * maxLineLength := 4095       % Turing limit
#else
    const * maxLineLength := 1048575    % 1 Mb - 1
#end if

% Maximum include file depth in a TXL program
const * maxIncludeDepth := 8

% Maximum defined symbols in the TXL bootstrap grammar
const * maxBootstrapSymbols := 100

% Maximum total defined symbols in a TXL program
const * maxSymbols := 16384 + (options.txlSize div 200) * 2048  % 16384, 18432 (200), 20480 (400) .. 26624 (1000)

% Maximum number of keywords in each of bootstrap and TXL program
const * maxKeys := 2048

% Maximum total compound tokens in a TXL program
const * maxCompoundTokens := 128

% Maximum different token patterns in a TXL program
const * maxTokenPatterns := 128
const * maxTokenPatternLinks := 25 * maxTokenPatterns

% Maximum total comment brackets in a TXL program
const * maxCommentTokens := 32  % (pairs)

% Maximum number of rules in a TXL program
const * maxRules := 4096 + (options.txlSize div 200) * 1024     % 4096, 5120 (200), 6144 (400) .. 9216 (1000)

% Number of parameters to a rule
const * maxParameters := 16
const * avgParameters := 4

% Number of local vars in a rule
const * maxLocalVars := 65535   % nat2
const * avgLocalVars := 128

% Maximum unique sub-rule calls in a rule
const * maxRuleCalls := 65535   % nat2

% Number of conditions, constructors and deconstructors preceding
% or following a pattern in a rule
const * maxParts := 65535       % nat2
const * avgParts := 64          % allow for very complex rule sets

% Maximum length of any rule pattern or replacement, in tokens
const * maxPatternTokens := 4096

% Maximum different token texts, including identifiers, strings and numbers,
% in entire TXL program - must be a power of 2!
% Note - if maxIdents ever exceeds 65536, we must change the width of tree nodes!
var vmaxIdents := 2048
loop
    exit when vmaxIdents >= options.txlSize * 1024 
            or vmaxIdents = 1048576
    vmaxIdents *= 2
end loop
const * maxIdents := vmaxIdents

% Maximum total characters in token texts
const * maxIdentChars := maxIdents * 32         % (statistical estimate of ratio)

% Maximum total length of any input,
% including each of: TXL bootstrap grammar, TXL program, input source
const * maxTokens := options.transformSize * 4000 

% Maximum number of lines in any single input,
% including each of: TXL bootstrap grammar, TXL program, input source
const * maxLines := maxTokens div 10

% Maximum parsing depth in any parse
% Normally should allow for the length of the whole input file
const * maxParseDepth := maxLines

% Maximum parsing depth without an accept before infinite recursion checking
% takes effect
const * maxBlindParseDepth := 10

% Maximum recursion levels before we assume it is infinite
const * maxLeftRecursion := 10

% Maximum parsing cycles in any parse
% Normally should allow for the length of the whole input file
const * maxParseCycles := min (1000000 + 100 * maxTokens, 500000000)

% Maximum number of alternatives in a choice or elements in a sequence
const * maxDefineKids := 65535  % nat2

% Maximum rule call depth
% Normally should allow for at least the length of the whole input file
% so that a recursive function can examine every line
const * maxCallDepth := maxParseDepth div 4

% Limits on total number of trees and kids in all trees
const * maxTrees := options.transformSize * 50000
const * maxKids := (maxTrees * 3) div 2

% Maximum TXL internal pre-reserved trees and kids
const * reservedTrees := 256
const * reservedKids := 256

% Limit on TXL recursion stack use 
var defaultStackUse : addressint := maxParseDepth * 128

% Can't use min() for this when machine might be 64 bit
if defaultStackUse > 256*1024*1024 then
    defaultStackUse := 256*1024*1024    % 256 Mb is most we are willing to use
end if

% We need at least these to run
const reservedStack := 1048576          % 1 mb
const minimumStack := 4194304           % 4 mb

% Do we have less than we'd like at this size?
if stackSize - reservedStack < defaultStackUse then
    % Yes, let's see how bad it is
    const oldStackUse : addressint := defaultStackUse
    defaultStackUse := stackSize - reservedStack
    if defaultStackUse >= minimumStack then
        if (not options.option (quiet_p)) and (not options.option (compile_p))  % we don't want to hear about it
                and (defaultStackUse < oldStackUse div 2 or options.option (verbose_p)) then
            error ("", "Stack limit less than recommended for TXL size (probable cause: shell stack limit)", WARNING, 911)
            error ("", "Recursion stack limit reduced from " + intstr (oldStackUse,1) 
                + " to " + intstr (defaultStackUse,1) + " to fit", INFORMATION, 913)
        end if
    else
        error ("", "Stack limit less than minimum for TXL size (probable cause: shell stack limit)", FATAL, 912)
    end if
end if

% This is what TXL will use as a limit
const * maxStackUse : addressint :=  defaultStackUse
