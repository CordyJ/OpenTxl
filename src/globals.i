% OpenTxl Version 11 globals
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

% List of modules and other globals granted to sub-modules by main txl.t

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
% 	Retired obsolete hard time limit. 


% Global symbols granted to all child modules
grant 
    var charset, var ident, var symbol, var options, var scanner,
    var tree, var tree_ops, txltree, 
    var inputTokens, var currentTokenIndex, var lastTokenIndex, var failTokenIndex, var kindType, typeKind,
    var parser, var inputGrammarTreeTP, var unparser, 
    var rule, var mainRule,
    error, predefinedParseError, patternError, parseInterruptError, parseStackError, stackBase, 
    var fileNames, var nFiles, var exitcode, externalType
    
