% OpenTxl Version 11 profiiler
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

% The TXL rule and grammar profile analyzer
% Analyzes and outputs a summary table of the raw profile data produced by a TXL run
% Usage: txlapr [-parse | -rules] [-time] [-space] [-calls] [-cycles] [-percall]

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Reprogrammed and remodularized to improve maintainability

put : 0, "OpenTxl Profiler v11.0 (20.10.22) (c) 2022 James R. Cordy and others" 

include "%system"

% Get command line options
var infile := 0
var parse := false
var bytime, byspace, bycalls, bycycles, byname, byeff, percall:= false

% Default profile rules by time
bytime := true

% Each command line option
for a : 1 .. nargs
    const arg := fetcharg (a)

    if arg = "-time" then
        bytime := true
        byname := false
        byspace := false
        bycalls := false
        bycycles := false
        byeff := false

    elsif arg = "-space" then
        bytime := false
        byname := false
        byspace := true
        bycalls := false
        bycycles := false
        byeff := false

    elsif arg = "-calls" then
        bytime := false
        byname := false
        byspace := false
        bycalls := true
        bycycles := false
        byeff := false

    elsif arg = "-cycles" then
        bytime := false
        byname := false
        byspace := false
        bycalls := false
        bycycles := true
        byeff := false

    elsif arg = "-eff" then
        bytime := false
        byname := false
        byspace := false
        bycalls := false
        bycycles := false
        byeff := true

    elsif arg = "-percall" then
        percall := true

    elsif arg = "-parse" then
        parse := true

    elsif index (arg, "-") = 1 then
        put : 0, "TXL Profiler: Invalid flag '", arg, "' (options are -parse, -time, -space, -calls, -cycles, -eff, -percall)"
        quit

    else
        % Explicitly given previous profile file
        if infile = 0 then
            open : infile, arg, get
            if infile = 0 then
                put : 0, "TXL Profiler: Unable to open TXL profile file '", arg, "'"
                quit
            end if
        else
            put : 0, "TXL Profiler: Only one TXL profile file allowed"
            quit
        end if
    end if
end for

% Implicit default profile file 
if infile = 0 then
    if parse then
        open : infile, "txl.pprofout", get
    else
        open : infile, "txl.rprofout", get
    end if
    if infile = 0 then
        put : 0, "TXL Profiler: Unable to open TXL profile file 'txl.rprofout' or 'txl.pprofout'"
        put : 0, "  (Probable cause: errors in profiled TXL run)"
        quit
    end if
end if


% Rule statistics
const maxrules := 4096  
var nrules := 0
var rules :
    array 1..maxrules of 
        record
            name : string       % rule/nonterm name
            calls : nat         % total calls
            matches : nat       % total calls that matched
            searchcycles : nat  % total search cycles / parse cycles
            matchcycles : nat   % total match cycles / backtrack cycles
            time : nat          % total time units
            trees : nat         % total trees
            kids : nat          % total kids
        end record

% Flush title
var dummy : string
get : infile, dummy : *

% Get stats from profile file
for r : 1 .. maxrules
    exit when eof (infile)
    bind var rule to rules (r)
    get : infile, rule.name, rule.calls, rule.matches, rule.searchcycles, 
        rule.matchcycles, rule.time, rule.trees, rule.kids
    if parse and index (rule.name, "repeat__") = 1 or index (rule.name, "list__") = 1 then
        const zindex := index (rule.name, "__")
        rule.name := rule.name (1 .. zindex - 1) + " " + rule.name (zindex + 2 .. *)
    end if
    nrules += 1
    get : infile, skip
end for
close : infile

% Sort rules/nonterms by time or as desired
for i : 1 .. nrules - 1
    for decreasing j : nrules - 1 .. i
        var jeff, j1eff : real
        if parse and byeff then
            if rules (j).searchcycles > 0 then
                jeff := (rules (j).trees / rules (j).searchcycles) * 100
            else
                jeff := 0
            end if
            if rules (j+1).searchcycles > 0 then
                j1eff := (rules (j+1).trees / rules (j+1).searchcycles) * 100
            else
                j1eff := 0
            end if
        end if
        if (byname and (rules (j).name > rules (j+1).name)) 
                or (bytime and (rules (j).time < rules (j+1).time))
                or (byspace and (rules (j).trees + rules (j).kids < rules (j+1).trees + rules (j+1).kids))
                or (parse and bycycles and rules (j).searchcycles < rules (j+1).searchcycles)
                or ((not parse) and bycycles and (rules (j).searchcycles + rules (j).matchcycles < rules (j+1).searchcycles + rules (j+1).matchcycles))
                or (bycalls and (rules (j).calls < rules (j+1).calls)) 
                or (parse and byeff and jeff > j1eff)
                then
            const temp := rules (j)
            rules (j) := rules (j+1)
            rules (j+1) := temp
        end if
    end for
end for


% Output stats
var total : nat := 0
if bytime then
    total := rules (1).time
elsif byspace then
    total := rules (1).trees + rules (1).kids
elsif bycycles then
    if parse then
        total := rules (1).searchcycles
    else
        total := rules (1).searchcycles + rules (1).matchcycles
    end if
end if

if percall then
    % Scale time/cycles per call to rule/nonterm
    if parse then
        put "                                                              KID CELLS            TREE NODES             TIME                 PARSE CYCLES             BACKTRACK CYCLES   "
    else
        put "                                                              KID CELLS            TREE NODES             TIME                 SEARCH CYCLES               MATCH CYCLES    "
    end if

    put "     NAME                      PCT    CALLS    MATCHED     total  per call      total  per call      total  per call         total     per call         total     per call "
    put "     ----                      ---    -----     -----      -----  --------      -----  --------      -----  --------         -----     --------         -----     -------- "
    
    for i : 1 .. nrules
        bind r to rules (i)

        if r.calls not= 0 then
            put r.name (1 .. min (30, length (r.name))) : 30 ..

            if total not= 0 then
                var percent := 0
                if bytime then
                    percent := round ((r.time / total) * 100)
                elsif byspace then
                    percent := round (((r.trees + r.kids) / total) * 100)
                elsif bycycles then
                    if parse then
                        percent := round ((r.searchcycles / total) * 100)
                    else
                        percent := round (((r.searchcycles + r.matchcycles) / total) * 100)
                    end if
                end if
                put percent : 3, "%" ..
            else
                put "" : 4 ..
            end if

            put r.calls : 8, r.matches : 10, 
                r.kids : 12, r.kids div r.calls : 9, 
                r.trees : 12, r.trees div r.calls : 9,
                r.time : 12, r.time div r.calls : 9,
                r.searchcycles : 15, r.searchcycles div r.calls : 12,
                r.matchcycles : 15, r.matchcycles div r.calls : 12
        end if
    end for

else
    % Total time/cycles per rule/nonterm
    if parse then
        put "     NAME                      PCT    CALLS    MATCHED     CELLS       NODES       TIME      CYCLES   BACKTRACKS  EFFICIENCY"
        put "     ----                      ---    -----     -----      -----       -----      ------    --------  ----------  ----------"
    else
        put "     NAME                      PCT    CALLS    MATCHED     CELLS       NODES       TIME     SEARCHES     MATCHES"
        put "     ----                      ---    -----     -----      -----       -----      ------    --------     -------"
    end if
    
    for i : 1 .. nrules
        bind r to rules (i)

        if r.calls not= 0 then
            put r.name (1 .. min (30, length (r.name))) : 30 ..

            if total not= 0 then
                var percent := 0

                if bytime then
                    percent := round ((r.time / total) * 100)
                elsif byspace then
                    percent := round (((r.trees + r.kids) / total) * 100)
                elsif bycycles then
                    if parse then
                        percent := round ((r.searchcycles / total) * 100)
                    else
                        percent := round (((r.searchcycles + r.matchcycles) / total) * 100)
                    end if
                end if

                put percent : 3, "%" ..
            else
                put "" : 4 ..
            end if

            put r.calls : 8, r.matches : 10, 
                r.kids : 12, r.trees : 12, r.time : 12, r.searchcycles : 12, r.matchcycles : 12 ..

            if parse then
                const efficiency : real := (r.trees / r.searchcycles) * 100
                put efficiency : 12 : 3
            else
                put ""
            end if
        end if
    end for
end if

