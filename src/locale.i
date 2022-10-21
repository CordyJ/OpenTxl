% OpenTxl Version 11 localization
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

% TXL processor localization
% Localizes TXL process default paths, sizes and limits

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
% 	Retired obsolete hard time limit. 

% Default library location and subdirectory selector character
#if WIN then
    const * defaultLibrary := "C:/TXL/LIB"
    const * directoryChar := "/"	% (sic) - used by VS C
#else
    const * defaultLibrary := "/usr/local/lib/txl"
    const * directoryChar := "/"
#end if

% Maximum output line length (can be changed using command line option)
const * defaultOutputLineLength := 256

% Default size limit (approximate, in Mb)
const * defaultTxlSize := 64

% The following depend on OS details not visible in Turing+,
% so are passed to us from locale.c

% Clock resolution 
external var txl_clocks_per_second : int
const * clocksPerSecond := txl_clocks_per_second

% Available stack space
external function txl_stacksize : addressint
const * stackSize : addressint := txl_stacksize

