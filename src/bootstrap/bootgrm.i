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

const numBootstrapTokens :=     1083
var bootstrapToken := 0
const bootstrapTokens : array 1 .. numBootstrapTokens of nat1 := init (
    105, 118, 97, 94, 98, 107, 105, 105, 94, 97, 48, 98, 128, 97, 106, 98, 107, 105, 105, 48,
    97, 93, 98, 97, 94, 98, 107, 105, 105, 93, 97, 24, 98, 128, 97, 89, 98, 128, 97, 36,
    98, 107, 105, 105, 54, 97, 44, 98, 128, 97, 106, 98, 107, 105, 105, 44, 97, 52, 98, 97,
    54, 98, 107, 105, 105, 52, 97, 80, 98, 128, 97, 126, 98, 107, 105, 105, 80, 4, 4, 97,
    95, 98, 107, 105, 105, 95, 97, 126, 98, 128, 97, 112, 98, 107, 105, 105, 24, 97, 23, 98,
    97, 110, 98, 97, 68, 98, 97, 53, 98, 97, 81, 98, 97, 63, 98, 4, 107, 97, 23, 98,
    97, 13, 98, 107, 105, 105, 23, 4, 105, 128, 4, 120, 107, 105, 105, 68, 97, 26, 98, 128,
    97, 106, 98, 107, 105, 105, 26, 4, 8, 97, 64, 98, 107, 105, 105, 64, 4, 128, 128, 97,
    106, 98, 107, 105, 105, 63, 97, 17, 98, 128, 97, 106, 98, 107, 105, 105, 17, 97, 64, 98,
    4, 8, 107, 105, 105, 81, 97, 46, 98, 128, 97, 106, 98, 107, 105, 105, 46, 4, 128, 97,
    53, 98, 97, 81, 98, 107, 105, 105, 53, 97, 43, 98, 128, 97, 106, 98, 107, 105, 105, 43,
    97, 51, 98, 97, 53, 98, 107, 105, 105, 51, 97, 18, 98, 128, 97, 52, 98, 107, 105, 105,
    88, 4, 123, 128, 4, 109, 107, 105, 105, 89, 4, 123, 97, 110, 98, 97, 15, 98, 97, 74,
    98, 97, 70, 98, 97, 84, 98, 97, 71, 98, 97, 18, 98, 97, 75, 98, 97, 74, 98, 97,
    66, 98, 4, 107, 4, 123, 97, 13, 98, 107, 105, 105, 36, 4, 109, 97, 110, 98, 97, 15,
    98, 97, 74, 98, 97, 70, 98, 97, 84, 98, 97, 71, 98, 97, 18, 98, 97, 75, 98, 97,
    74, 98, 97, 66, 98, 4, 107, 4, 109, 97, 13, 98, 107, 105, 105, 84, 4, 122, 128, 4,
    114, 107, 105, 105, 66, 97, 19, 98, 128, 97, 106, 98, 107, 105, 105, 19, 4, 102, 97, 85,
    98, 107, 105, 105, 70, 97, 92, 98, 128, 97, 106, 98, 107, 105, 105, 92, 4, 125, 97, 18,
    98, 107, 105, 105, 74, 97, 45, 98, 128, 97, 106, 98, 107, 105, 105, 45, 97, 73, 98, 97,
    74, 98, 107, 105, 105, 73, 97, 21, 98, 128, 97, 22, 98, 128, 97, 20, 98, 128, 97, 38,
    98, 128, 97, 28, 98, 107, 105, 105, 21, 4, 103, 97, 110, 98, 97, 18, 98, 97, 85, 98,
    97, 13, 98, 107, 105, 105, 22, 97, 70, 98, 4, 104, 97, 69, 98, 97, 71, 98, 97, 65,
    98, 97, 110, 98, 97, 75, 98, 97, 13, 98, 107, 105, 105, 65, 97, 18, 98, 128, 97, 106,
    98, 107, 105, 105, 20, 97, 96, 98, 97, 69, 98, 97, 62, 98, 97, 29, 98, 97, 13, 98,
    107, 105, 105, 96, 4, 127, 128, 4, 100, 107, 105, 105, 69, 4, 115, 128, 97, 106, 98, 107,
    105, 105, 62, 4, 99, 128, 97, 106, 98, 107, 105, 105, 38, 4, 111, 97, 110, 98, 97, 65,
    98, 97, 75, 98, 97, 13, 98, 107, 105, 105, 28, 4, 108, 97, 110, 98, 97, 65, 98, 97,
    85, 98, 97, 13, 98, 107, 105, 105, 15, 97, 39, 98, 128, 97, 106, 98, 107, 105, 105, 39,
    97, 14, 98, 97, 15, 98, 107, 105, 105, 14, 97, 110, 98, 97, 18, 98, 107, 105, 105, 34,
    97, 41, 98, 128, 97, 106, 98, 107, 105, 105, 41, 97, 33, 98, 97, 34, 98, 107, 105, 105,
    33, 97, 110, 98, 4, 97, 97, 25, 98, 4, 98, 107, 105, 105, 75, 97, 35, 98, 107, 105,
    105, 85, 97, 30, 98, 107, 105, 105, 18, 4, 97, 97, 25, 98, 4, 98, 107, 105, 105, 25,
    97, 110, 98, 128, 97, 57, 98, 128, 97, 59, 98, 128, 97, 56, 98, 128, 97, 58, 98, 128,
    97, 55, 98, 128, 97, 16, 98, 128, 97, 67, 98, 128, 97, 83, 98, 128, 97, 50, 98, 128,
    97, 82, 98, 128, 97, 49, 98, 128, 97, 90, 98, 128, 97, 60, 98, 128, 97, 31, 98, 128,
    97, 78, 98, 128, 97, 76, 98, 107, 105, 105, 83, 4, 121, 97, 37, 98, 97, 72, 98, 107,
    105, 105, 50, 4, 113, 97, 37, 98, 97, 72, 98, 107, 105, 105, 72, 4, 5, 128, 97, 106,
    98, 107, 105, 105, 71, 4, 5, 128, 4, 3, 128, 4, 2, 128, 97, 106, 98, 107, 105, 105,
    82, 4, 121, 97, 37, 98, 4, 6, 107, 105, 105, 49, 4, 113, 97, 37, 98, 4, 6, 107,
    105, 105, 67, 4, 116, 97, 37, 98, 107, 105, 105, 16, 4, 101, 97, 37, 98, 107, 105, 105,
    59, 97, 106, 98, 97, 37, 98, 4, 5, 107, 105, 105, 56, 97, 106, 98, 97, 37, 98, 4,
    7, 107, 105, 105, 58, 97, 106, 98, 97, 37, 98, 4, 6, 107, 105, 105, 55, 97, 106, 98,
    97, 37, 98, 4, 7, 4, 6, 107, 105, 105, 57, 97, 106, 98, 97, 37, 98, 4, 12, 107,
    105, 105, 90, 97, 91, 98, 97, 37, 98, 107, 105, 105, 91, 4, 124, 128, 4, 9, 107, 105,
    105, 60, 97, 61, 98, 97, 37, 98, 107, 105, 105, 61, 4, 115, 128, 4, 129, 107, 105, 105,
    31, 4, 1, 107, 105, 105, 78, 97, 79, 98, 97, 37, 98, 107, 105, 105, 79, 4, 119, 128,
    4, 11, 107, 105, 105, 76, 97, 77, 98, 97, 37, 98, 107, 105, 105, 77, 4, 117, 128, 4,
    10, 107, 105, 105, 37, 97, 110, 98, 128, 97, 52, 98, 107, 105, 105, 35, 97, 42, 98, 128,
    97, 106, 98, 107, 105, 105, 42, 97, 32, 98, 97, 35, 98, 107, 105, 105, 32, 97, 33, 98,
    128, 97, 52, 98, 107, 105, 105, 30, 97, 40, 98, 128, 97, 106, 98, 107, 105, 105, 40, 97,
    27, 98, 97, 30, 98, 107, 105, 105, 27, 97, 29, 98, 128, 97, 52, 98, 107, 105, 105, 29,
    97, 110, 98, 97, 87, 98, 107, 105, 105, 87, 97, 47, 98, 128, 97, 106, 98, 107, 105, 105,
    47, 97, 86, 98, 97, 87, 98, 107, 105, 105, 86, 4, 97, 97, 126, 98, 97, 54, 98, 4,
    98, 107, 105
    )

const numBootstrapStrings :=      129
const bootstrapStrings: array 1 .. numBootstrapStrings of string (50) := init (
    "!", "#", "$", "'",
    "*", "+", ",", "...",
    ":", "<", ">", "?",
    "KEEP", "TXL_argument_", "TXL_arguments_", "TXL_attrDescription_",
    "TXL_barDotDotDot_", "TXL_bracketedDescription_", "TXL_byReplacement_", "TXL_conditionPart_",
    "TXL_constructPart_", "TXL_deconstructPart_", "TXL_defineOrRedefine_", "TXL_defineStatement_",
    "TXL_description_", "TXL_dotDotDotBar_", "TXL_expOrLit_", "TXL_exportPart_",
    "TXL_expression_", "TXL_expsAndLits_", "TXL_fenceDescription_", "TXL_firstOrLit_",
    "TXL_firstTime_", "TXL_firstTimes_", "TXL_firstsAndLits_", "TXL_functionStatement_",
    "TXL_idOrLiteral_", "TXL_importPart_", "TXL_indArguments_", "TXL_indExpsAndLits_",
    "TXL_indFirstTimes_", "TXL_indFirstsAndLits_", "TXL_indLiteralsAndBracketedDescriptions_", "TXL_indLiterals_",
    "TXL_indPart_", "TXL_indRepBarLiteralsAndBracketedDescriptions_", "TXL_indRuleCalls_", "TXL_indStatements_",
    "TXL_list1Description_", "TXL_listDescription_", "TXL_literalOrBracketedDescription_", "TXL_literal_",
    "TXL_literalsAndBracketedDescriptions_", "TXL_literals_", "TXL_newlist1Description_", "TXL_newlistDescription_",
    "TXL_newoptDescription_", "TXL_newrepeat1Description_", "TXL_newrepeatDescription_", "TXL_notDescription_",
    "TXL_not_", "TXL_optAll_", "TXL_optBarDotDotDot_", "TXL_optBar_",
    "TXL_optBracketedDescription_", "TXL_optByReplacement_", "TXL_optDescription_", "TXL_optDotDotDotBar_",
    "TXL_optNot_", "TXL_optSkippingBracketedDescription_", "TXL_optStarDollarHash_", "TXL_optStar_",
    "TXL_part_", "TXL_parts_", "TXL_pattern_", "TXL_popDescription_",
    "TXL_pop_", "TXL_pushDescription_", "TXL_push_", "TXL_quotedLiteral_",
    "TXL_repBarLiteralsAndBracketedDescriptions_", "TXL_repeat1Description_", "TXL_repeatDescription_", "TXL_replaceOrMatch_",
    "TXL_replacement_", "TXL_ruleCall_", "TXL_ruleCalls_", "TXL_ruleOrFunction_",
    "TXL_ruleStatement_", "TXL_seeDescription_", "TXL_see_", "TXL_skippingBracketedDescription_",
    "TXL_statement_", "TXL_statements_", "TXL_tokenOrKey_", "TXL_whereOrAssert_",
    "[", "]", "all", "assert",
    "attr", "by", "construct", "deconstruct",
    "define", "empty", "end", "export",
    "function", "id", "import", "key",
    "list", "match", "not", "opt",
    "pop", "program", "push", "redefine",
    "repeat", "replace", "rule", "see",
    "skipping", "token", "where", "|",
    "~"
    )

