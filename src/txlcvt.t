% OpenTxl Version 11 bytecode converter
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

% The TXL bytecode converter
% Converts a TXL compiled bytecode file to a standalone C byte array 
% for inclusion in a standalone application

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Reprogrammed and remodularized to improve maintainability

include "%system"

const usage := "Usage: txlcvt [-e] file.ctxl"

% Runtime assertion checker
procedure insist (cond : boolean, message : string)
    if not cond then
        put : 0, "TXL Bytecode Converter: ", message
        quit
    end if
end insist

% Process command line options
var embedded := false
var filearg := 1

if fetcharg (1) = "-e" then
    embedded := true
    filearg := 2
end if

% Get the compiled .ctxl bytecode file
var ctxlfile := fetcharg (filearg)
insist (ctxlfile not= "", usage)
var ctxlname := ctxlfile (1 .. index (ctxlfile, ".") - 1) + "_"
const cbytefile := ctxlname + "TXL.c"

if not embedded then
    ctxlname := "TXL_"
end if

var instream, outstream := 0
open : instream, ctxlfile, read
insist (instream not= 0, "Unable to open " + ctxlfile)

% Read the TXL bytecode file and output it as C initialized array source 
% for the standalone application
open : outstream, cbytefile, put
insist (outstream not= 0, "Unable to create " + cbytefile)

put : outstream, "/* TXL virtual machine byte code */" 
put : outstream, ""

put : outstream, "unsigned char " + ctxlname + "TXL [] = {"

for b : 1 .. 999999999
    exit when eof (instream)
    if b mod 20 = 0 then
        put : outstream, ""
    end if
    var byte : nat1
    read : instream, byte : 1
    const byteval : int := byte
    put : outstream, byteval, "," ..
end for

put : outstream, "0};"

put : outstream, ""
put : outstream, "unsigned char *" + ctxlname + "CTXL = " + ctxlname + "TXL;"

