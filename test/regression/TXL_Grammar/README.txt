Validated TXL Basis Grammar for TXL 10.5
Version 1.0, Feb 2009

Copyright 2009 James R. Cordy
Licensed under the MIT open source license, see source for details.

Description:
    TXL transformation grammar and pretty-printer for version 10.5 of 
    TXL itself.  Handles and preserves comments and TXL preprocessor 
    statements.

    Note: Pretty printing is an approximation since we cannot guess
    what the formatting conventions for the target language used in 
    defines, patterns and replacements looks like.  All TXL syntax 
    is properly formatted in standard form.

Authors:
    J.R. Cordy, Queen's University

Examples:
    txl Examples/calculator.txl
    txl Examples/cpp.grm
