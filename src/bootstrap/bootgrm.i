% OpenTxl Version 11 bootstrap template
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

% This file automatically generated from: Txl-11-bootstrap.grm

const numBootstrapTokens :=     1104
var bootstrapToken := 0
const bootstrapTokens : array 1 .. numBootstrapTokens of nat1 := init (
    23, 37, 7, 128, 8, 25, 23, 23, 128, 7, 80, 8, 14, 7, 24, 8, 25, 23, 23, 80,
    7, 127, 8, 7, 128, 8, 25, 23, 23, 127, 7, 56, 8, 14, 7, 123, 8, 14, 7, 68,
    8, 25, 23, 23, 85, 7, 75, 8, 14, 7, 24, 8, 25, 23, 23, 75, 7, 83, 8, 7,
    85, 8, 25, 23, 23, 83, 7, 113, 8, 14, 7, 45, 8, 25, 23, 23, 113, 6, 6, 7,
    129, 8, 25, 23, 23, 129, 7, 45, 8, 14, 7, 31, 8, 25, 23, 23, 56, 7, 55, 8,
    7, 28, 8, 7, 100, 8, 7, 86, 8, 7, 114, 8, 7, 96, 8, 6, 25, 7, 55, 8,
    7, 30, 8, 25, 23, 23, 55, 6, 23, 14, 6, 39, 25, 23, 23, 100, 7, 58, 8, 14,
    7, 24, 8, 25, 23, 23, 58, 6, 5, 7, 95, 8, 25, 23, 23, 95, 6, 14, 14, 7,
    24, 8, 25, 23, 23, 96, 7, 49, 8, 14, 7, 24, 8, 25, 23, 23, 49, 7, 95, 8,
    6, 5, 25, 23, 23, 114, 7, 78, 8, 14, 7, 24, 8, 25, 23, 23, 78, 6, 14, 7,
    86, 8, 7, 114, 8, 25, 23, 23, 86, 7, 76, 8, 14, 7, 24, 8, 25, 23, 23, 76,
    7, 84, 8, 7, 86, 8, 25, 23, 23, 84, 7, 50, 8, 14, 7, 83, 8, 25, 23, 23,
    122, 6, 42, 14, 6, 27, 25, 23, 23, 123, 6, 42, 7, 28, 8, 7, 47, 8, 7, 107,
    8, 7, 102, 8, 7, 107, 8, 7, 98, 8, 6, 25, 6, 42, 7, 30, 8, 25, 23, 23,
    68, 6, 27, 7, 28, 8, 7, 47, 8, 7, 107, 8, 7, 102, 8, 7, 107, 8, 7, 98,
    8, 6, 25, 6, 27, 7, 30, 8, 25, 23, 23, 102, 7, 119, 8, 14, 7, 24, 8, 25,
    23, 23, 119, 7, 103, 8, 7, 118, 8, 7, 105, 8, 7, 50, 8, 7, 108, 8, 25, 23,
    23, 118, 6, 41, 14, 6, 33, 25, 23, 23, 98, 7, 51, 8, 14, 7, 24, 8, 25, 23,
    23, 51, 6, 20, 7, 117, 8, 25, 23, 23, 103, 7, 126, 8, 14, 7, 24, 8, 25, 23,
    23, 126, 6, 44, 7, 50, 8, 7, 97, 8, 7, 97, 8, 7, 97, 8, 7, 97, 8, 7,
    97, 8, 25, 23, 23, 107, 7, 77, 8, 14, 7, 24, 8, 25, 23, 23, 77, 7, 106, 8,
    7, 107, 8, 25, 23, 23, 106, 7, 53, 8, 14, 7, 54, 8, 14, 7, 52, 8, 14, 7,
    70, 8, 14, 7, 60, 8, 25, 23, 23, 53, 6, 21, 7, 28, 8, 7, 50, 8, 7, 117,
    8, 7, 30, 8, 25, 23, 23, 54, 7, 103, 8, 6, 22, 7, 101, 8, 7, 105, 8, 7,
    97, 8, 7, 28, 8, 7, 108, 8, 7, 30, 8, 25, 23, 23, 97, 7, 50, 8, 14, 7,
    24, 8, 25, 23, 23, 52, 7, 130, 8, 7, 101, 8, 7, 94, 8, 7, 61, 8, 7, 30,
    8, 25, 23, 23, 130, 6, 131, 14, 6, 18, 25, 23, 23, 101, 6, 34, 14, 7, 24, 8,
    25, 23, 23, 94, 6, 17, 14, 7, 24, 8, 25, 23, 23, 70, 6, 29, 7, 28, 8, 7,
    97, 8, 7, 108, 8, 7, 30, 8, 25, 23, 23, 60, 6, 26, 7, 28, 8, 7, 97, 8,
    7, 117, 8, 7, 30, 8, 25, 23, 23, 47, 7, 71, 8, 14, 7, 24, 8, 25, 23, 23,
    71, 7, 46, 8, 7, 47, 8, 25, 23, 23, 46, 7, 28, 8, 7, 50, 8, 25, 23, 23,
    67, 7, 74, 8, 14, 7, 24, 8, 25, 23, 23, 74, 7, 66, 8, 7, 67, 8, 25, 23,
    23, 66, 7, 28, 8, 6, 7, 7, 57, 8, 6, 8, 25, 23, 23, 108, 7, 65, 8, 25,
    23, 23, 117, 7, 62, 8, 25, 23, 23, 50, 6, 7, 7, 57, 8, 6, 8, 25, 23, 23,
    57, 7, 28, 8, 14, 7, 89, 8, 14, 7, 91, 8, 14, 7, 88, 8, 14, 7, 90, 8,
    14, 7, 87, 8, 14, 7, 48, 8, 14, 7, 99, 8, 14, 7, 116, 8, 14, 7, 82, 8,
    14, 7, 115, 8, 14, 7, 81, 8, 14, 7, 125, 8, 14, 7, 93, 8, 14, 7, 63, 8,
    14, 7, 112, 8, 14, 7, 110, 8, 25, 23, 23, 116, 6, 40, 7, 69, 8, 7, 104, 8,
    25, 23, 23, 82, 6, 32, 7, 69, 8, 7, 104, 8, 25, 23, 23, 104, 6, 9, 14, 7,
    24, 8, 25, 23, 23, 105, 6, 9, 14, 6, 16, 14, 6, 10, 14, 7, 24, 8, 25, 23,
    23, 115, 6, 40, 7, 69, 8, 6, 11, 25, 23, 23, 81, 6, 32, 7, 69, 8, 6, 11,
    25, 23, 23, 99, 6, 35, 7, 69, 8, 25, 23, 23, 48, 6, 19, 7, 69, 8, 25, 23,
    23, 91, 7, 24, 8, 7, 69, 8, 6, 9, 25, 23, 23, 88, 7, 24, 8, 7, 69, 8,
    6, 1, 25, 23, 23, 90, 7, 24, 8, 7, 69, 8, 6, 11, 25, 23, 23, 87, 7, 24,
    8, 7, 69, 8, 6, 1, 6, 11, 25, 23, 23, 89, 7, 24, 8, 7, 69, 8, 6, 4,
    25, 23, 23, 125, 7, 124, 8, 7, 69, 8, 25, 23, 23, 124, 6, 43, 14, 6, 2, 25,
    23, 23, 93, 7, 92, 8, 7, 69, 8, 25, 23, 23, 92, 6, 34, 14, 6, 15, 25, 23,
    23, 63, 6, 3, 25, 23, 23, 112, 7, 111, 8, 7, 69, 8, 25, 23, 23, 111, 6, 38,
    14, 6, 13, 25, 23, 23, 110, 7, 109, 8, 7, 69, 8, 25, 23, 23, 109, 6, 36, 14,
    6, 12, 25, 23, 23, 69, 7, 28, 8, 14, 7, 83, 8, 25, 23, 23, 65, 7, 73, 8,
    14, 7, 24, 8, 25, 23, 23, 73, 7, 64, 8, 7, 65, 8, 25, 23, 23, 64, 7, 66,
    8, 14, 7, 83, 8, 25, 23, 23, 62, 7, 72, 8, 14, 7, 24, 8, 25, 23, 23, 72,
    7, 59, 8, 7, 62, 8, 25, 23, 23, 59, 7, 61, 8, 14, 7, 83, 8, 25, 23, 23,
    61, 7, 28, 8, 7, 121, 8, 25, 23, 23, 121, 7, 79, 8, 14, 7, 24, 8, 25, 23,
    23, 79, 7, 120, 8, 7, 121, 8, 25, 23, 23, 120, 6, 7, 7, 45, 8, 7, 85, 8,
    6, 8, 25, 23
    )

const numBootstrapStrings :=      131
const bootstrapStrings: array 1 .. numBootstrapStrings of string (50) := init (
    ",", ":", "!", "?",
    "...", "'", "[", "]",
    "*", "#", "+", "<",
    ">", "|", "~", "$",
    "all", "assert", "attr", "by",
    "construct", "deconstruct", "define", "empty",
    "end", "export", "function", "id",
    "import", "KEEP", "key", "list",
    "match", "not", "opt", "pop",
    "program", "push", "redefine", "repeat",
    "replace", "rule", "see", "skipping",
    "token", "TXL_argument_", "TXL_arguments_", "TXL_attrDescription_",
    "TXL_barDotDotDot_", "TXL_bracketedDescription_", "TXL_byReplacement_", "TXL_conditionPart_",
    "TXL_constructPart_", "TXL_deconstructPart_", "TXL_defineOrRedefine_", "TXL_defineStatement_",
    "TXL_description_", "TXL_dotDotDotBar_", "TXL_expOrLit_", "TXL_exportPart_",
    "TXL_expression_", "TXL_expsAndLits_", "TXL_fenceDescription_", "TXL_firstOrLit_",
    "TXL_firstsAndLits_", "TXL_firstTime_", "TXL_firstTimes_", "TXL_functionStatement_",
    "TXL_idOrLiteral_", "TXL_importPart_", "TXL_indArguments_", "TXL_indExpsAndLits_",
    "TXL_indFirstsAndLits_", "TXL_indFirstTimes_", "TXL_indLiterals_", "TXL_indLiteralsAndBracketedDescriptions_",
    "TXL_indPart_", "TXL_indRepBarLiteralsAndBracketedDescriptions_", "TXL_indRuleCalls_", "TXL_indStatements_",
    "TXL_list1Description_", "TXL_listDescription_", "TXL_literal_", "TXL_literalOrBracketedDescription_",
    "TXL_literals_", "TXL_literalsAndBracketedDescriptions_", "TXL_newlist1Description_", "TXL_newlistDescription_",
    "TXL_newoptDescription_", "TXL_newrepeat1Description_", "TXL_newrepeatDescription_", "TXL_not_",
    "TXL_notDescription_", "TXL_optAll_", "TXL_optBar_", "TXL_optBarDotDotDot_",
    "TXL_optBracketedDescription_", "TXL_optByPart_", "TXL_optDescription_", "TXL_optDotDotDotBar_",
    "TXL_optNot_", "TXL_optReplaceOrMatchPart_", "TXL_optSkippingBracketedDescription_", "TXL_optStar_",
    "TXL_optStarDollarHash_", "TXL_part_", "TXL_parts_", "TXL_pattern_",
    "TXL_pop_", "TXL_popDescription_", "TXL_push_", "TXL_pushDescription_",
    "TXL_quotedLiteral_", "TXL_repBarLiteralsAndBracketedDescriptions_", "TXL_repeat1Description_", "TXL_repeatDescription_",
    "TXL_replacement_", "TXL_replaceOrMatch_", "TXL_replaceOrMatchPart_", "TXL_ruleCall_",
    "TXL_ruleCalls_", "TXL_ruleOrFunction_", "TXL_ruleStatement_", "TXL_see_",
    "TXL_seeDescription_", "TXL_skippingBracketedDescription_", "TXL_statement_", "TXL_statements_",
    "TXL_tokenOrKey_", "TXL_whereOrAssert_", "where"
    )

