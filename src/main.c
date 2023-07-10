/*
% OpenTxl Version 11 standalone application stub
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

% The TXL standalone application stub
% This main function initializes the minimal T+ library and runs the standalone TXL engine 
% to execute the bytecode in compiled TXL applications created by the TXL compiler command txlc

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
*/

// Minimal Turing+ library
#include "tpluslib/TL.h"

// The main function of the standalone TXL engine and bytecode
extern void TProg();

// C main function 
int main (int argc, char **argv)
{
    // Initialize the minimal Turing+ library
    TL_initialize (argc, argv);

    // Global uncaught exception handler
    if (setjmp (TL_handlerArea->quit_env)) {
        // Exceptional exit
        TL_finalize ();
        exit (TL_handlerArea->quitCode);
    }

    // Run the standalone TXL engine and bytecode
    TProg ();

    // Normal exit
    TL_finalize ();
    exit (0);
}
