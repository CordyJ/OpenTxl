/*
% OpenTxl Version 11 OS-dependent locale parameters
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

% This file handles TXL localizations that are OS-dependent and must be done in C 
% Provides clock resolution and process stack limits to locale.i

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%	Moved non-OS dependent limits to locale.i
*/

/* Clock resolution */
#include <time.h>
int txl_clocks_per_second = CLOCKS_PER_SEC;

/* Stack limit */
#ifndef WIN
    #include <sys/resource.h>
#endif

unsigned long txl_stacksize ()
{
    #define TXL_DEFAULT_STACKSIZE  8388608  		/* 8Mb */
    unsigned long stacksize = TXL_DEFAULT_STACKSIZE;	/* We link at this size on Windows */
    
    #ifndef WIN
	struct rlimit limit;
	int errcode;
	
	/* See what we have */
	errcode = getrlimit (RLIMIT_STACK, &(limit));
	/* If it's not enough, ask for our default */
	if (limit.rlim_cur < TXL_DEFAULT_STACKSIZE) {
	    limit.rlim_cur = TXL_DEFAULT_STACKSIZE;
	    errcode = setrlimit (RLIMIT_STACK, &(limit));
	};
	/* See what we really have now */
	errcode = getrlimit (RLIMIT_STACK, &(limit));
	stacksize = limit.rlim_cur;
    #endif

    return (stacksize);
}
