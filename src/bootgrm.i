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

const numBootstrapTokens :=     1089
var bootstrapToken := 0
const bootstrapTokens : array 1 .. numBootstrapTokens of nat1 := init (
    107, 120, 99, 96, 100, 109, 107, 107, 96, 99, 48, 100, 130, 99, 108, 100, 109, 107, 107, 48,
    99, 95, 100, 99, 96, 100, 109, 107, 107, 95, 99, 24, 100, 130, 99, 91, 100, 130, 99, 36,
    100, 109, 107, 107, 54, 99, 44, 100, 130, 99, 108, 100, 109, 107, 107, 44, 99, 52, 100, 99,
    54, 100, 109, 107, 107, 52, 99, 81, 100, 130, 99, 128, 100, 109, 107, 107, 81, 4, 4, 99,
    97, 100, 109, 107, 107, 97, 99, 128, 100, 130, 99, 114, 100, 109, 107, 107, 24, 99, 23, 100,
    99, 112, 100, 99, 68, 100, 99, 53, 100, 99, 82, 100, 99, 63, 100, 4, 109, 99, 23, 100,
    99, 13, 100, 109, 107, 107, 23, 4, 107, 130, 4, 122, 109, 107, 107, 68, 99, 26, 100, 130,
    99, 108, 100, 109, 107, 107, 26, 4, 8, 99, 64, 100, 109, 107, 107, 64, 4, 130, 130, 99,
    108, 100, 109, 107, 107, 63, 99, 17, 100, 130, 99, 108, 100, 109, 107, 107, 17, 99, 64, 100,
    4, 8, 109, 107, 107, 82, 99, 46, 100, 130, 99, 108, 100, 109, 107, 107, 46, 4, 130, 99,
    53, 100, 99, 82, 100, 109, 107, 107, 53, 99, 43, 100, 130, 99, 108, 100, 109, 107, 107, 43,
    99, 51, 100, 99, 53, 100, 109, 107, 107, 51, 99, 18, 100, 130, 99, 52, 100, 109, 107, 107,
    90, 4, 125, 130, 4, 111, 109, 107, 107, 91, 4, 125, 99, 112, 100, 99, 15, 100, 99, 75,
    100, 99, 70, 100, 99, 75, 100, 99, 66, 100, 4, 109, 4, 125, 99, 13, 100, 109, 107, 107,
    36, 4, 111, 99, 112, 100, 99, 15, 100, 99, 75, 100, 99, 70, 100, 99, 75, 100, 99, 66,
    100, 4, 109, 4, 111, 99, 13, 100, 109, 107, 107, 70, 99, 85, 100, 130, 99, 108, 100, 109,
    107, 107, 85, 99, 71, 100, 99, 86, 100, 99, 72, 100, 99, 18, 100, 99, 76, 100, 109, 107,
    107, 86, 4, 124, 130, 4, 116, 109, 107, 107, 66, 99, 19, 100, 130, 99, 108, 100, 109, 107,
    107, 19, 4, 104, 99, 87, 100, 109, 107, 107, 71, 99, 94, 100, 130, 99, 108, 100, 109, 107,
    107, 94, 4, 127, 99, 18, 100, 109, 107, 107, 75, 99, 45, 100, 130, 99, 108, 100, 109, 107,
    107, 45, 99, 74, 100, 99, 75, 100, 109, 107, 107, 74, 99, 21, 100, 130, 99, 22, 100, 130,
    99, 20, 100, 130, 99, 38, 100, 130, 99, 28, 100, 109, 107, 107, 21, 4, 105, 99, 112, 100,
    99, 18, 100, 99, 87, 100, 99, 13, 100, 109, 107, 107, 22, 99, 71, 100, 4, 106, 99, 69,
    100, 99, 72, 100, 99, 65, 100, 99, 112, 100, 99, 76, 100, 99, 13, 100, 109, 107, 107, 65,
    99, 18, 100, 130, 99, 108, 100, 109, 107, 107, 20, 99, 98, 100, 99, 69, 100, 99, 62, 100,
    99, 29, 100, 99, 13, 100, 109, 107, 107, 98, 4, 129, 130, 4, 102, 109, 107, 107, 69, 4,
    117, 130, 99, 108, 100, 109, 107, 107, 62, 4, 101, 130, 99, 108, 100, 109, 107, 107, 38, 4,
    113, 99, 112, 100, 99, 65, 100, 99, 76, 100, 99, 13, 100, 109, 107, 107, 28, 4, 110, 99,
    112, 100, 99, 65, 100, 99, 87, 100, 99, 13, 100, 109, 107, 107, 15, 99, 39, 100, 130, 99,
    108, 100, 109, 107, 107, 39, 99, 14, 100, 99, 15, 100, 109, 107, 107, 14, 99, 112, 100, 99,
    18, 100, 109, 107, 107, 34, 99, 41, 100, 130, 99, 108, 100, 109, 107, 107, 41, 99, 33, 100,
    99, 34, 100, 109, 107, 107, 33, 99, 112, 100, 4, 99, 99, 25, 100, 4, 100, 109, 107, 107,
    76, 99, 35, 100, 109, 107, 107, 87, 99, 30, 100, 109, 107, 107, 18, 4, 99, 99, 25, 100,
    4, 100, 109, 107, 107, 25, 99, 112, 100, 130, 99, 57, 100, 130, 99, 59, 100, 130, 99, 56,
    100, 130, 99, 58, 100, 130, 99, 55, 100, 130, 99, 16, 100, 130, 99, 67, 100, 130, 99, 84,
    100, 130, 99, 50, 100, 130, 99, 83, 100, 130, 99, 49, 100, 130, 99, 92, 100, 130, 99, 60,
    100, 130, 99, 31, 100, 130, 99, 79, 100, 130, 99, 77, 100, 109, 107, 107, 84, 4, 123, 99,
    37, 100, 99, 73, 100, 109, 107, 107, 50, 4, 115, 99, 37, 100, 99, 73, 100, 109, 107, 107,
    73, 4, 5, 130, 99, 108, 100, 109, 107, 107, 72, 4, 5, 130, 4, 3, 130, 4, 2, 130,
    99, 108, 100, 109, 107, 107, 83, 4, 123, 99, 37, 100, 4, 6, 109, 107, 107, 49, 4, 115,
    99, 37, 100, 4, 6, 109, 107, 107, 67, 4, 118, 99, 37, 100, 109, 107, 107, 16, 4, 103,
    99, 37, 100, 109, 107, 107, 59, 99, 108, 100, 99, 37, 100, 4, 5, 109, 107, 107, 56, 99,
    108, 100, 99, 37, 100, 4, 7, 109, 107, 107, 58, 99, 108, 100, 99, 37, 100, 4, 6, 109,
    107, 107, 55, 99, 108, 100, 99, 37, 100, 4, 7, 4, 6, 109, 107, 107, 57, 99, 108, 100,
    99, 37, 100, 4, 12, 109, 107, 107, 92, 99, 93, 100, 99, 37, 100, 109, 107, 107, 93, 4,
    126, 130, 4, 9, 109, 107, 107, 60, 99, 61, 100, 99, 37, 100, 109, 107, 107, 61, 4, 117,
    130, 4, 131, 109, 107, 107, 31, 4, 1, 109, 107, 107, 79, 99, 80, 100, 99, 37, 100, 109,
    107, 107, 80, 4, 121, 130, 4, 11, 109, 107, 107, 77, 99, 78, 100, 99, 37, 100, 109, 107,
    107, 78, 4, 119, 130, 4, 10, 109, 107, 107, 37, 99, 112, 100, 130, 99, 52, 100, 109, 107,
    107, 35, 99, 42, 100, 130, 99, 108, 100, 109, 107, 107, 42, 99, 32, 100, 99, 35, 100, 109,
    107, 107, 32, 99, 33, 100, 130, 99, 52, 100, 109, 107, 107, 30, 99, 40, 100, 130, 99, 108,
    100, 109, 107, 107, 40, 99, 27, 100, 99, 30, 100, 109, 107, 107, 27, 99, 29, 100, 130, 99,
    52, 100, 109, 107, 107, 29, 99, 112, 100, 99, 89, 100, 109, 107, 107, 89, 99, 47, 100, 130,
    99, 108, 100, 109, 107, 107, 47, 99, 88, 100, 99, 89, 100, 109, 107, 107, 88, 4, 99, 99,
    128, 100, 99, 54, 100, 4, 100, 109, 107
    )

const numBootstrapStrings :=      131
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
    "TXL_optBracketedDescription_", "TXL_optByPart_", "TXL_optDescription_", "TXL_optDotDotDotBar_",
    "TXL_optNot_", "TXL_optReplaceOrMatchPart_", "TXL_optSkippingBracketedDescription_", "TXL_optStarDollarHash_",
    "TXL_optStar_", "TXL_part_", "TXL_parts_", "TXL_pattern_",
    "TXL_popDescription_", "TXL_pop_", "TXL_pushDescription_", "TXL_push_",
    "TXL_quotedLiteral_", "TXL_repBarLiteralsAndBracketedDescriptions_", "TXL_repeat1Description_", "TXL_repeatDescription_",
    "TXL_replaceOrMatchPart_", "TXL_replaceOrMatch_", "TXL_replacement_", "TXL_ruleCall_",
    "TXL_ruleCalls_", "TXL_ruleOrFunction_", "TXL_ruleStatement_", "TXL_seeDescription_",
    "TXL_see_", "TXL_skippingBracketedDescription_", "TXL_statement_", "TXL_statements_",
    "TXL_tokenOrKey_", "TXL_whereOrAssert_", "[", "]",
    "all", "assert", "attr", "by",
    "construct", "deconstruct", "define", "empty",
    "end", "export", "function", "id",
    "import", "key", "list", "match",
    "not", "opt", "pop", "program",
    "push", "redefine", "repeat", "replace",
    "rule", "see", "skipping", "token",
    "where", "|", "~"
    )

