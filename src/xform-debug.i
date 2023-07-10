% OpenTxl Version 11 debugger
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

% The TXL command line interactive debugger.
% Runs the user's TXL transformation step by step with tracing as directed from the command line.

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Remodularized to improve maintainability
%       Fixed bug finding redefines when showing define source

module debugger

    import 
        charset, ident, rule, options, unparser,
        callEnvironment, callDepth
        
    export 
        isbreakpoint, breakpoint

    % Global tracing controls
    var nsteps := 0
    var matchfinding, localtracing := false
    var localrulename, matchrulename : tokenT
    var localdepth := 0

    % Rules we are breakpointing at
    const maxbreakpoints := 10
    var breakpoints : array 1 .. maxbreakpoints of tokenT
    var nbreakpoints := 0

    procedure setbreakpoint (ruleName : tokenT)
        % Is it already set?
        for bp : 1 .. nbreakpoints
            if breakpoints (bp) = ruleName then
                put : 0, "  Breakpoint already set at rule ", string@(ident.idents (ruleName))
                return
            end if
        end for

        % Are there too many?
        if nbreakpoints >= maxbreakpoints then
            put : 0, "  ? Too many breakpoints"
            return
        end if

        % Add it
        nbreakpoints += 1
        breakpoints (nbreakpoints) := ruleName

        put : 0, "  Breakpoint set at rule ", string@(ident.idents (ruleName))

    end setbreakpoint

    procedure clearbreakpoint (ruleName : tokenT)

        % Is it set?
        var bp := 1
        loop
            exit when bp > nbreakpoints or breakpoints (bp) = ruleName
            bp += 1
        end loop

        if bp > nbreakpoints then
            put : 0, "  ? Rule not being breakpointed"
            return
        end if

        % Remove it
        nbreakpoints -= 1
        for b : bp .. nbreakpoints
            breakpoints (b) := breakpoints (b + 1)
        end for

        put : 0, "  Breakpoint cleared at rule ", string@(ident.idents (ruleName))

    end clearbreakpoint

    function isrealbreakpoint (ruleName : tokenT) : boolean
        % Is this rule an explicitly set breakpoint?
        for bp : 1 .. nbreakpoints
            if breakpoints (bp) = ruleName then
                result true
            end if
        end for
        result false
    end isrealbreakpoint

    function isbreakpoint (ruleName : tokenT) : boolean
        % Is this rule a breakpoint, either because it's explicitly set or because we're tracing it
        if nsteps > 0 or matchfinding and (matchrulename = ruleName or matchrulename = empty_T)
                or localtracing and localrulename = ruleName then
            result true
        else
            result isrealbreakpoint (ruleName)
        end if
    end isbreakpoint

    procedure findruleordefine (sourceFileName, sourceDirectory : string, rdId : string,
            var rdfilename : string, var rdline : int)

        % NOTE: This routine needs to be reprogrammed to be more precise! - JRC

        % This is tricky, since we must find the LAST definition!
        % We do that by searching from the beginning of the spec to the end, exploring included files and 
        % setting the line and filename whenever we hit a definition.

        % Can we open the main source file?
        var sourceFile := 0
        open : sourceFile, sourceFileName, get

        if sourceFile = 0 then
           put : 0, "  ? Unable to open ", sourceFileName
           return
        end if

        % OK, try to find the rule or define in it
        var sourceLine := 0
        loop
            exit when eof (sourceFile)

            var line : string
            get : sourceFile, line : *
            sourceLine += 1

            const ruleFunctionDefineIndex := index (line, "rule") + index (line, "function") + index (line, "define")
            const includeIndex := index (line, "include") 

            % Is this the one?
            if ruleFunctionDefineIndex not= 0 and index (line, rdId) > ruleFunctionDefineIndex + 1 then
                const restOfLineIndex := index (line, rdId) + length (rdId)
                const restOfLine := line (restOfLineIndex .. *)
                const foundit := restOfLine = "" or restOfLine (1) = " " or restOfLine (1) = "\t"
                if foundit then
                    rdfilename := sourceFileName
                    rdline := sourceLine
                end if

            % If not, is this an include statement?
            elsif includeIndex not= 0 
                    and index (line, "\"") > includeIndex + 1 then
                % If so, can we open the included file?
                var includeFileName := line
                includeFileName := 
                    includeFileName (index (includeFileName, "\"") + 1 .. *)
                includeFileName := 
                    includeFileName (1 .. index (includeFileName, "\"") - 1)
                includeFileName := sourceDirectory + includeFileName

                var includeDirectory := ""
                if index (sourceFileName, directoryChar) not= 0 then
                    includeDirectory := includeFileName
                    loop
                        exit when includeDirectory (*) = directoryChar
                        includeDirectory := includeDirectory (1 .. *-1)
                    end loop
                end if

                % Look for it in the included file
                findruleordefine (includeFileName, includeDirectory, rdId, rdfilename, rdline)
            end if
        end loop

        close : sourceFile

    end findruleordefine

    % Find source of rule or define
    procedure showruleordefine (rdId : string)

        % Find and show the source of a rule or define in the TXL program 
        var sourceFileName := options.txlSourceFileName
        const sflength := length (sourceFileName)
        if sflength > 4 and (sourceFileName (sflength - 4 .. *) = ".ctxl") then
            sourceFileName := sourceFileName (1 .. sflength - 4) + "txl"
            var sourceFile := 0
            open : sourceFile, sourceFileName, get
            if sourceFile = 0 then
                sourceFileName := sourceFileName (1 .. sflength - 4) + "Txl"
            else
                close (sourceFile)
            end if
        end if

        var sourceDirectory := ""
        if index (sourceFileName, directoryChar) not= 0 then
            sourceDirectory := sourceFileName
            loop
                exit when sourceDirectory (*) = directoryChar
                sourceDirectory := sourceDirectory (1 .. *-1)
            end loop
        end if

        % find the definition of the rule or define
        var rdfilename := ""
        var rdline := 0

        findruleordefine (sourceFileName, sourceDirectory, rdId, rdfilename, rdline)

        % OK, now rdfile and rdline must be the definition
        if rdline = 0 then
            put : 0, "  ? Couldn't find rule or define of that name"

        else
            var rdfile : int
            open : rdfile, rdfilename, get

            var line : string
            for ln : 1 .. rdline
                get : rdfile, line : *
            end for

            loop
                put : 0, line
                exit when eof (rdfile) 
                    or index (line, "end define") not= 0 
                    or index (line, "end redefine") not= 0 
                    or index (line, "end rule") not= 0
                    or index (line, "end function") not= 0
                get : rdfile, line : *
            end loop

            close : rdfile
        end if

    end showruleordefine


    procedure dbhelp
        put : 0, ""
        put : 0, "        TXL Debugger Commands"
        put : 0, ""
        put : 0, "  rules             list names of all rules "
        put : 0, "  rule              list name of current rule"
        put : 0, "  set/clr [RULE]    set/clear breakpoint at 'RULE' (default current)"
        put : 0, "  showbps           list names of all rule breakpoints"
        put : 0, "  scope             print current scope of application"
        put : 0, "  match[context]    print current pattern match (with or without scope context)"
        put : 0, "  result            print result of current replacement or rule"
        put : 0, "  vars              list names of all current visible TXL variables"
        put : 0, "  VAR or 'VAR       print current binding of TXL variable 'VAR'"
        put : 0, "  tree VAR          print tree of current binding of variable 'VAR'"
        put : 0, "  where             print current rule name and execution state"
        put : 0, "  show [RULDEF]     print source of rule/define 'RULDEF' (default current)"
        put : 0, "  run               continue execution until next breakpoint"
        put : 0, "  next or .         continue execution until next statement of current rule"
        put : 0, "  /[RULE]           continue until next pattern match of 'RULE' (default current)"
        put : 0, "  //                continue until next pattern match of any rule"
        put : 0, "  step [N] or <CR>  step trace execution for N (default 1) steps"
        put : 0, "  in RULE[-N] CMD   execute debugger command 'CMD' in context of rule 'RULE'"
        put : 0, "  help              print out this help summary"
        put : 0, "  quit              exit TXL"
    end dbhelp


    % "Darren" mode provides auto-tracing of the entire transformation,
    % dumping complete state information at every step, invoked using the "-Z" command line option
    % Designed to support Darren Cousineau's obsolete windowed interactive debugging application,
    % but still useful for debugging complex transformations by hand.

    const maxDarrenCommands := 5
    var darrenCommands : array DBkind of array 1 .. maxDarrenCommands of string (12) :=
        init (
                % startup
                init ("step", "", "", "", ""),
                % shutdown
                init ("step", "", "", "", ""),
                % ruleEntry
                init ("vars", "scope", "tree scope", "%vars", "step"),
                % ruleExit
                init ("step", "", "", "", ""),
                % matchEntry
                init ("match", "tree match", "%vars", "step", ""),
                % matchExit
                init ("result", "tree result", "step", "", ""),
                % deconstructExit
                init ("%vars", "step", "", "", ""),
                % constructEntry
                init ("step", "", "", "", ""),
                % constructExit
                init ("%vars", "step", "", "", ""),
                % conditionExit
                init ("step", "", "", "", ""),
                % importExit
                init ("step", "", "", "", ""),
                % exportEntry
                init ("step", "", "", "", ""),
                % exportExit
                init ("step", "", "", "", ""),
                % historyCommand
                init ("step", "", "", "", "")
        )
    var darrenIndex := 0
    var darrenLocal, darrenLastLocal := 0
    var darrenTree := false
    
    
    % Command buffer for looking into history
    var historyCommand := ""
    

    procedure breakpoint (kind : DBkind, ruleName : tokenT, partRef : 0 .. maxLocalVars,
            scope : treePT, ruleEnvironment : ruleEnvironmentT, success : boolean)

        bind localVars to localsListT@(ruleEnvironment.localsListAddr)

        if kind = DBkind.startup or kind = DBkind.shutdown then
            % initializing or exiting

        elsif (kind = DBkind.constructEntry or kind = DBkind.constructExit)
                and string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)) (1) = '_' then
            % internal anonymous construct
            return
            
        elsif localtracing then
            % we're waiting to get back to the interesting rule
            if ruleName not= localrulename then
                return
            else
                if kind = DBkind.ruleEntry then
                    localdepth += 1
                elsif kind = DBkind.ruleExit then
                    localdepth -= 1
                 end if
                if localdepth = 0 then
                    localtracing := false
                else
                    return
                 end if 
            end if

        elsif matchfinding then
            % we're searching for a rule match
            if not (kind = DBkind.matchEntry 
                    and (ruleName = matchrulename or matchrulename = empty_T)) then
                return
            end if
        end if

        case kind of
            label DBkind.startup :
                dbhelp

            label DBkind.shutdown :
                put : 0, "  Exiting TXL program"

            label DBkind.ruleEntry :
                if isrealbreakpoint (ruleName) then
                    % we got here on a breakpointed rule
                    put : 0, "  >> Breakpoint"
                    nsteps := 0
                    matchfinding := false
                end if
                
                put : 0, "  Applying rule ", string@(ident.idents (ruleName))
                
                if options.option (darren_p) then
                    darrenLocal := 1
                    darrenLastLocal := localVars.nformals
                end if

            label DBkind.ruleExit :
                put : 0, "  Exiting rule ", string@(ident.idents (ruleName)) ..
                if success then
                    put : 0, " (succeeded)"
                else
                    put : 0, " (failed)"
                end if

            label DBkind.matchEntry :
                put : 0, "  Matched main pattern of rule ", string@(ident.idents (ruleName))
                
                if options.option (darren_p) then
                    darrenLocal := localVars.nformals + 1
                    darrenLastLocal := localVars.nformals
                    loop
                        exit when darrenLastLocal = localVars.nlocals 
                            or valueTP (ruleEnvironment.valuesBase + darrenLastLocal + 1) = nilTree
                        darrenLastLocal += 1
                    end loop
                end if

            label DBkind.matchExit :
                put : 0, "  Done replacement of pattern match of rule ", string@(ident.idents (ruleName))

            label DBkind.constructEntry:
                put : 0, "  Entering construct of ", 
                    string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                    string@(ident.idents (ruleName))

            label DBkind.constructExit:
                put : 0, "  Exiting construct of ", 
                    string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                    string@(ident.idents (ruleName))
                
                if options.option (darren_p) then
                    darrenLocal := partRef
                    darrenLastLocal := partRef
                end if

            label DBkind.deconstructExit:
                put : 0, "  Exiting deconstruct of ", 
                    string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                    string@(ident.idents (ruleName)) ..
                if success then
                    put : 0, " (succeeded)"
                else
                    put : 0, " (failed)"
                end if
                
                if options.option (darren_p) then
                    loop
                        exit when darrenLastLocal = localVars.nlocals 
                            or valueTP (ruleEnvironment.valuesBase + darrenLastLocal + 1) = nilTree
                        darrenLastLocal += 1
                    end loop
                end if

            label DBkind.conditionExit:
                put : 0, "  Exiting where condition on ", 
                    string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                    string@(ident.idents (ruleName)) ..
                if success then
                    put : 0, " (succeeded)"
                else
                    put : 0, " (failed)"
                end if
                
                if options.option (darren_p) then
                    darrenLastLocal := localVars.nformals + 1
                    loop
                        exit when darrenLastLocal = localVars.nlocals
                            or valueTP (ruleEnvironment.valuesBase + darrenLastLocal + 1) = nilTree
                        darrenLastLocal += 1
                    end loop
                    darrenLocal := darrenLastLocal + 1
                end if

            label DBkind.importExit:
                put : 0, "  Exiting import of ", 
                    string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                    string@(ident.idents (ruleName)) ..
                if success then
                    put : 0, " (succeeded)"
                else
                    put : 0, " (failed)"
                end if

            label DBkind.exportEntry:
                put : 0, "  Entering export of ", 
                    string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                    string@(ident.idents (ruleName))

            label DBkind.exportExit:
                put : 0, "  Exiting export of ", 
                    string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                    string@(ident.idents (ruleName)) ..
                if success then
                    put : 0, " (succeeded)"
                else
                    put : 0, " (failed)"
                end if

            label DBkind.historyCommand:
                % (don't say anything!)
        end case

        if nsteps > 0 then
            nsteps -= 1
            if nsteps > 0 then
                return
            end if
        end if

        nsteps := 0
        matchfinding := false
        
        if options.option (darren_p) then
            darrenIndex := 1
            darrenTree := false
        end if
        
        % Debugger command processor
        loop
            if kind not= DBkind.historyCommand then
                put : 0, "TXLDB >> " ..
            end if
            
            % Flush all output streams to keep synchronous
            external "TL_TLI_TLIFS" procedure flushstreams
            flushstreams
                
            var command : string

            if options.option (darren_p) then
                command := darrenCommands (kind) (darrenIndex)
                if command = "%vars" then
                    loop
                        exit when darrenLocal > darrenLastLocal 
                            or string@(ident.idents (rule.ruleLocals (localVars.localBase + darrenLocal).name)) (1) not= "_"
                        darrenLocal += 1
                    end loop
                    if darrenLocal <= darrenLastLocal then
                        if darrenTree then
                            command := "tree " + string@(ident.idents (rule.ruleLocals (localVars.localBase + darrenLocal).name))
                            darrenTree := false
                            darrenLocal += 1
                        else
                            command := string@(ident.idents (rule.ruleLocals (localVars.localBase + darrenLocal).name))
                            darrenTree := true
                        end if
                    else
                        darrenIndex += 1
                        command := darrenCommands (kind) (darrenIndex)
                        darrenIndex += 1
                        darrenTree := false
                    end if
                else
                    darrenIndex += 1
                end if
                put : 0, command
            elsif kind = DBkind.historyCommand then
                exit when historyCommand = ""
                command := historyCommand
                historyCommand := ""
            elsif eof then 
                command := "quit"
            else
                get command : *
            end if

            if command = "rules" then
                var outlength := 0
                for r : 1..rule.nRules
                    if outlength + length (string@(ident.idents (rule.rules (r).name))) + 2 > 78 then
                        put : 0, ""
                        outlength := 0
                    end if
                    put : 0, "  ", string@(ident.idents (rule.rules (r).name)) ..
                    outlength += length (string@(ident.idents (rule.rules (r).name))) + 2
                end for
                put : 0, ""

            elsif command = "rule" then
                put : 0, "  ", string@(ident.idents (ruleName))

            elsif command = "step" or command = "" or index (command, "step ") = 1 then
                % trace for one or more steps
                if index (command, " ") not= 0 then
                    command := command (6..*)
                    nsteps := 0
                    loop
                        exit when command = "" or command (1) < "0" or command (1) > "9"
                        nsteps := nsteps * 10 + ord (command (1)) - ord ("0")
                        command := command (2..*)
                    end loop
                    if nsteps = 0 then 
                        put : 0, "  ? Bad step count"
                    else
                        exit
                    end if
                else
                    nsteps := 1
                    exit
                end if

            elsif command = "next" or command = "." then
                % trace this rule only
                localtracing := true
                localrulename := ruleName
                localdepth := 0
                exit
                
            elsif command = "run" or command = "go" or command = "continue" then
                exit

            elsif command = "//" then
                matchfinding := true
                matchrulename := empty_T
                exit

            elsif index (command, "/") = 1 then
                var setrulename := ruleName
                if length (command) > 1 then
                    const ruleId := command (2 .. *)
                    setrulename := ident.lookup (ruleId)
                end if
                
                var found := false
                for r : 1..rule.nRules
                    if rule.rules (r).name = setrulename then
                        found := true
                        matchfinding := true
                        matchrulename := setrulename
                        exit
                    elsif r = rule.nRules then
                        put : 0, "  ? No such rule"
                        exit
                    end if
                end for
                
                exit when found

            elsif command = "set" or index (command, "set ") = 1 then
                var ruleId : string
                if index (command, " ") not= 0 then
                    ruleId := command (5 .. *)
                else
                    ruleId := string@(ident.idents (ruleName))
                end if
                const setRuleName := ident.lookup (ruleId)
                for r : 1..rule.nRules
                    if rule.rules (r).name = setRuleName then
                        setbreakpoint (setRuleName)
                        exit
                    elsif r = rule.nRules then
                        put : 0, "  ? No such rule"
                        exit
                    end if
                end for

            elsif command = "clear" or command = "clr" 
                    or index (command, "clear ") = 1  or index (command, "clr ") = 1 then
                var ruleId : string
                const spindex := index (command, " ")
                if spindex not= 0 then
                    ruleId := command (spindex + 1 .. *)
                else
                    ruleId := string@(ident.idents (ruleName))
                end if
                const clearRuleName := ident.lookup (ruleId)
                for r : 1..rule.nRules
                    if rule.rules (r).name = clearRuleName then
                        clearbreakpoint (clearRuleName)
                        exit
                    elsif r = rule.nRules then
                        put : 0, "  ? No such rule"
                        exit
                    end if
                end for

            elsif command = "showbps" then
                var outlength := 0
                for bp : 1 .. nbreakpoints
                    if outlength + length (string@(ident.idents (breakpoints (bp)))) + 2 > 78 then
                        put : 0, ""
                        outlength := 0
                    end if
                    put : 0, "  ", string@(ident.idents (breakpoints (bp))) ..
                    outlength += length (string@(ident.idents (breakpoints (bp)))) + 2 
                end for
                put : 0, ""

            elsif command = "show" or index (command, "show ") = 1 then
                var rdId : string
                if index (command, " ") not= 0 then
                    rdId := command (6 .. *)
                    loop
                        exit when rdId = "" or rdId (1) not= " "
                        rdId := rdId (2 .. *)
                    end loop
                else
                    rdId := string@(ident.idents (ruleName))
                end if
                showruleordefine (rdId)

            elsif command = "scope" or command = "tree scope" then
                var foundit := false
                
                if options.option (darren_p) and callDepth > 1 then
                    bind prevLocalVars to localsListT@(callEnvironment (callDepth - 1).localsListAddr)
                    for prevlocal : 1 .. prevLocalVars.nlocals
                        if valueTP (callEnvironment (callDepth - 1).valuesBase + prevlocal) = scope 
                                and string@(ident.idents (rule.ruleLocals (prevLocalVars.localBase + prevlocal).name)) (1) not= '_' then
                            put : 0, "  (= <", string@(ident.idents (rule.ruleLocals (prevLocalVars.localBase + prevlocal).name)), ">)"
                            foundit := true
                            exit
                        end if
                    end for
                end if
                   
                if not foundit then
                    const treeWanted := index (command, "tree") = 1

                    if treeWanted then
                        command := command (index (command, " ") + 1 .. *)
                    end if

                    if kind not= DBkind.matchExit and kind not= DBkind.ruleExit 
                            and kind not= DBkind.shutdown then
                        if treeWanted then
                            unparser.printParse (ruleEnvironment.scopeTP, 0, 0)
                        else
                            unparser.printLeaves (ruleEnvironment.scopeTP, 0, false)
                        end if
                        put : 0, ""
                    else
                        put : 0, "  ? No scope in this context"
                    end if
                end if
            
            elsif command = "match" or command = "matchcontext" or command = "tree match" then

                if options.option (darren_p) and scope = ruleEnvironment.scopeTP then
                    put : 0, "  (= <scope>)"
                else
                    const treeWanted := index (command, "tree") = 1
                    
                    if treeWanted then
                        command := command (index (command, " ") + 1 .. *)
                    end if

                    if kind = DBkind.matchEntry then
                        if treeWanted then
                            unparser.printParse (scope, 0, 0)
                        else
                            if command = "matchcontext" then
                                unparser.printMatch (ruleEnvironment.scopeTP, scope, 0, false)
                            else
                                unparser.printLeaves (scope, 0, false)
                            end if
                        end if
                        put : 0, ""
                    else
                        put : 0, "  ? No match in this context"
                    end if
                end if

            elsif command = "result" or command = "tree result" then
                if options.option (darren_p) and scope = ruleEnvironment.scopeTP then
                    put : 0, "  (= <scope>)"
                else
                    const treeWanted := index (command, "tree") = 1

                    if treeWanted then
                        command := command (index (command, " ") + 1 .. *)
                    end if

                    if kind = DBkind.matchExit or kind = DBkind.ruleExit 
                            or kind = DBkind.constructExit or kind = DBkind.shutdown then
                        if treeWanted then
                            unparser.printParse (scope, 0, 0)
                        else
                            unparser.printLeaves (scope, 0, false)
                        end if
                        put : 0, ""
                    else
                        put : 0, "  ? No result in this context"
                    end if
                end if

            elsif command = "vars" then
                for localIndex : 1 .. localVars.nlocals
                    if string@(ident.idents (rule.ruleLocals (localVars.localBase + localIndex).name)) (1) not= "_" then
                        put : 0, "  ", string@(ident.idents (rule.ruleLocals (localVars.localBase + localIndex).name)),
                            " [", string@(ident.idents (rule.ruleLocals (localVars.localBase + localIndex).typename)), "]" ..
                    end if
                end for
                put : 0, ""

            elsif command = "state" or command = "where" then
                case kind of
                    label DBkind.startup :
                        put : 0, "  Applying main rule"
                    label DBkind.shutdown :
                        put : 0, "  Exiting main rule"
                    label DBkind.ruleEntry :
                        put : 0, "  Applying rule ", string@(ident.idents (ruleName))
                    label DBkind.ruleExit :
                        put : 0, "  Exiting rule ", string@(ident.idents (ruleName)) ..
                        if success then
                            put : 0, " (succeeded)"
                        else
                            put : 0, " (failed)"
                        end if
                    label DBkind.matchEntry :
                        put : 0, "  Matched pattern of rule ", string@(ident.idents (ruleName))
                    label DBkind.matchExit :
                        put : 0, "  Done replacement of pattern match of rule ", string@(ident.idents (ruleName)) ..
                        if success then
                            put : 0, " (succeeded)"
                        else
                            put : 0, " (failed)"
                        end if
                    label DBkind.constructEntry:
                        put : 0, "  Entering construct of ", 
                            string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                            string@(ident.idents (ruleName))
                    label DBkind.constructExit:
                        put : 0, "  Exiting construct of ", 
                            string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                            string@(ident.idents (ruleName))
                    label DBkind.deconstructExit:
                        put : 0, "  Exiting deconstruct of ", 
                            string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                            string@(ident.idents (ruleName)) ..
                        if success then
                            put : 0, " (succeeded)"
                        else
                            put : 0, " (failed)"
                        end if
                    label DBkind.conditionExit:
                        put : 0, "  Exiting where condition on ", 
                            string@(ident.idents (rule.ruleLocals (localVars.localBase + partRef).name)), ", in rule ", 
                            string@(ident.idents (ruleName)) ..
                        if success then
                            put : 0, " (succeeded)"
                        else
                            put : 0, " (failed)"
                        end if
                end case
                
                for decreasing c : callDepth - 1 .. 1
                    put : 0, "    called from ", string@(ident.idents (callEnvironment (c).name))
                end for

            elsif command = "help" or command = "?" then
                dbhelp

            elsif command = "exit" or command = "quit" or command = "bye" then
                put : 0, "  Exiting TXL"
                quit : 1
                
            elsif index (command, "in ") = 1 then
                % perform a debugger command on a previous rule's context
                var ruleId := command (4 .. *)
                const spindex := index (ruleId, " ") 
                if spindex not= 0 then
                    historyCommand := ruleId (spindex + 1 .. *)
                    ruleId := ruleId (1 .. spindex - 1)
                    const minusindex := index (ruleId, "-")
                    var instance := 0
                    if minusindex not= 0 then
                        var instancestring := ruleId (minusindex + 1 .. *)
                        ruleId := ruleId (1 .. minusindex - 1)
                        loop
                            exit when instancestring = "" or instancestring (1) < "0" or instancestring (1) > "9"
                            instance := instance * 10 + ord (instancestring (1)) - ord ("0")
                            instancestring := instancestring (2..*)
                        end loop
                        if instance = 0 then 
                            put : 0, "  ? Bad instance number"
                        end if
                    end if
                    % find the previous rule's context and issue the command
                    for decreasing c : callDepth .. 1
                        if string@(ident.idents (callEnvironment (c).name)) = ruleId then
                            if instance > 0 then
                                instance -= 1
                            else
                                % recursive call, with previous context
                                breakpoint (DBkind.historyCommand, callEnvironment (c).name, 0,
                                    callEnvironment (c).scopeTP, callEnvironment (c), success)
                                exit
                            end if
                        elsif c = 1 then
                            put : 0, "  ? No such rule in history"
                        end if
                    end for
                end if

            elsif length (command) > 0 then
                const treeWanted := index (command, "tree ") = 1
                if treeWanted then
                    command := command (index (command, " ") + 1 .. *)
                end if

                if command (1) = "'" then
                    command := command (2..*)
                end if

                const c : char := command (1)

                if command = "" or not charset.alphaP (c) then
                    put : 0, "  ? bad command ('help' for list of commands)"
                else
                    var found := false
                    for localIndex : 1 .. localVars.nlocals
                        if string@(ident.idents (rule.ruleLocals (localVars.localBase + localIndex).name)) = command then
                            if valueTP (ruleEnvironment.valuesBase + localIndex) = nilTree then
                                put : 0, "  ? unbound"
                            else
                                if options.option (darren_p) and valueTP (ruleEnvironment.valuesBase + localIndex) = ruleEnvironment.scopeTP then
                                    put : 0, "  (= <scope>)"
                                else
                                    if treeWanted then
                                        unparser.printParse (valueTP (ruleEnvironment.valuesBase + localIndex), 0, 0)
                                    else
                                        unparser.printLeaves (valueTP (ruleEnvironment.valuesBase + localIndex), 0, false)
                                    end if
                                    put : 0, ""
                                end if
                            end if
                            found := true
                            exit
                        end if
                    end for
                    if not found then
                        put : 0, "  ? No such variable in the context (or bad command)"
                    end if
                end if

            else
                % normally can't get here, but what the hey ...
                put : 0, "  ? bad command ('help' for list of commands)"
            end if
        end loop

    end breakpoint

end debugger
