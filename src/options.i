% OpenTxl Version 11 options
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

% TXL processor command line handling and option flags

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Removed old COBOL option flags
%       Retired old ".Txl" and ".Grm" source file conventions 


% TXL option flags
const * firstOption := 0
const * parse_print_p := 0
const * apply_print_p := 1
const * attr_p := 2
const * tree_print_p := 3
const * rule_print_p := 4
const * result_tree_print_p := 5
const * boot_parse_p := 6               % Obsolete -- JRC 16.9.95
const * verbose_p := 7
const * quiet_p := 8
const * compile_p := 9
const * load_p := 10
const * stack_print_p := 11
const * grammar_print_p := 12
const * raw_p := 13
const * txl_p := 14
const * sharing_p := 15
const * comment_token_p := 16
const * width_p := 17
const * usage_p := 18
const * tokens_p := 19
const * size_p := 20
const * indent_p := 23
const * darren_p := 25
const * analyze_p := 26
const * pattern_print_p := 27
const * upper_p := 29
const * lower_p := 30
const * charinput_p := 31
const * notabnl_p := 32
const * xmlout_p := 33
const * newline_p := 34
const * case_p := 35
const * multiline_p := 36
const * nlcomments_p := 37
const * lastOption := 37

% TXL program exit code
var exitcode := 0

module options
    import
        var charset, error

    export 
        option, setOption, processOptionsString,
        inputSourceFileName, outputSourceFileName,
        txlSourceFileName, txlCompiledFileName,
        optionSpChars, optionIdChars, updatedChars,   
        progArgs, nProgArgs, txlLibrary, txlIncludeLibs, nTxlIncludeLibs, 
        txlSize, transformSize,
        setIfdefSymbol, lookupIfdefSymbol, unsetIfdefSymbol,
        outputLineLength, setOutputLineLength, indentIncrement, setIndentIncrement 

    % Option flags
    var option : array firstOption .. lastOption of boolean
    for opt : firstOption .. lastOption
        option (opt) := false
    end for

    procedure setOption (opt : firstOption .. lastOption, setting : boolean)
        option (opt) := setting
    end setOption

    % Default to multiline tokens - JRC 10.4d
    option (multiline_p) := true

    % Default to no newlines on [TAB_NN] - JRC 10.5e
    option (notabnl_p) := true

    % Command line specified file names
    var txlSourceFileName, inputSourceFileName := ""               
    var txlCompiledFileName, outputSourceFileName := ""

    % Maximum output line length and indent
    var outputLineLength := defaultOutputLineLength
    var indentIncrement := 4

    procedure setOutputLineLength (lineLength : int)
        outputLineLength := lineLength
    end setOutputLineLength

    procedure setIndentIncrement (increment : int)
        indentIncrement := increment
    end setIndentIncrement

    % TXL library
    var txlLibrary := defaultLibrary

    % TXL include libraries
    const maxTxlIncludeLibs := 10       % cannot be in limits.i since we precede it
    var txlIncludeLibs : array 1 .. maxTxlIncludeLibs of string
    var nTxlIncludeLibs := 2
    txlIncludeLibs (1) := "txl"
    txlIncludeLibs (2) := txlLibrary

    % Optional character maps
    var optionIdChars, optionSpChars := ""

    % Flag changes to character maps to scanner
    var updatedChars := false

    % TXL dynamic size limit (in Mb)
    var txlSize, transformSize := defaultTxlSize

    % TXL program arguments
    const * maxProgramArguments := 32   % cannot be in limits.i since we precede it
    var nProgArgs := 0
    var progArgs : array 1 .. maxProgramArguments of string

    % TXL preprocessor symbols
    const * maxIfdefSymbols := 64       % cannot be in limits.i since we precede it
    var ifdefSymbols : array 1 .. maxIfdefSymbols of string
    var nIfdefSymbols := 0

    procedure setIfdefSymbol (symbol : string)
        if nIfdefSymbols < maxIfdefSymbols then
            nIfdefSymbols += 1
            ifdefSymbols (nIfdefSymbols) := symbol
        else
            error ("", "Too many preprocessor symbols (> " + intstr (maxIfdefSymbols, 0) + ")", LIMIT_FATAL, 154)
        end if
    end setIfdefSymbol
   
    function lookupIfdefSymbol (symbol : string) : int
        for i : 1 .. nIfdefSymbols
            if ifdefSymbols (i) = symbol then
                result i
            end if
        end for
        result 0
    end lookupIfdefSymbol
   
    procedure unsetIfdefSymbol (symbol : string)
        const symbolIndex := lookupIfdefSymbol (symbol)
        if symbolIndex not= 0 then
            ifdefSymbols (symbolIndex) := ""
        else
            % No need for error message in this case; just do nothing
        end if
    end unsetIfdefSymbol

    % Usage message
    #if not STANDALONE then
        const usage := "txl [txloptions] [-o outputfile] inputfile [txlfile] [- progoptions]"
    #else
        const usage := "Command arguments: [-s N] [-w N] [-o outputfile] [progoptions] inputfile"
    #end if

    procedure useerror (pragma : boolean)
        if pragma then
            error ("", "Unrecognized command line option in #pragma", DEFERRED, 946)
        end if
        #if not STANDALONE then
            put : 0, version
            put : 0, "Usage:  ", usage
            put : 0, "(for more information use txl -help)" 
        #else
            put : 0, usage
        #end if
        quit
    end useerror

    % TXL command help
    procedure help
        #if not STANDALONE then
            put : 0, version
            put : 0, "Usage:  txl [txloptions] [-o outputfile] inputfile [txlfile] [- progoptions]"
            put : 0, ""
            put : 0, "'txl' invokes the TXL processor to transform an input file using a TXL program."
            put : 0, "The input file to be transformed is 'inputfile' and the TXL program to"
            put : 0, "transform it is 'txlfile'.  The 'txlfile' must be named ending in '.txl',"
            put : 0, "and is normally either in the present working directory, the 'txl' subdirectory"
            put : 0, "of the present working directory, or the TXL library ('", txlLibrary, "')."
            put : 0, "If no 'txlfile' is given, it is inferred from the suffix of the input file."
            put : 0, "e.g., inputfile 'test.c' infers txlfile 'c.txl'."
            put : 0, ""
            put : 0, "Command options:"
            put : 0, "  -q               Quiet - turn off all information messages"
            put : 0, "  -v               Verbose - more detail in information messages"
        #if not NOLOADSTORE then
            put : 0, "  -c               Compile program to TXL byte code file 'txlfile.ctxl'"
            put : 0, "  -l               Load and run TXL byte code file 'txlfile.ctxl'"
        #end if
            put : 0, "  -d <symbol>      Define preprocessor symbol <symbol>"
            put : 0, "  -i <dir>         Add <dir> to the TXL include file search path"
            put : 0, "  -comment         Parse comments in input (default ignored)"
            put : 0, "  -char            Parse white space and newlines in input (default ignored)"
            put : 0, "  -newline         Parse newlines in input (default ignored)"
            put : 0, "  -multiline       Allow multiline tokens (default yes)"
            put : 0, "  -token           Ignore white space in input (separates input only - default)"
            put : 0, "  -id '<chars>'    Add each of <chars> to the identifier character set"
            put : 0, "  -sp '<chars>'    Add each of <chars> to the white space character set"
            put : 0, "  -esc '<char>'    Use <char> as the literal string escape character"
            put : 0, "  -upper           Shift input to upper case (except inside literals)"
            put : 0, "  -lower           Shift input to lower case (except inside literals)"
            put : 0, "  -case            Ignore case in input (but do not change it)"
            put : 0, "  -txl             Use TXL input lexical conventions"
            put : 0, "  -attr            Show attributes in output source (default invisible)"
            put : 0, "  -raw             Output source in raw (unspaced) form"
            put : 0, "  -w <width>       Wrap output source lines at <width> characters (default 128)"
            put : 0, "  -in <width>      Use output indent width of <width> characters (default 4)"
            put : 0, "  -tabnl           [TAB_nn] may force line wrap (default no)"
            put : 0, "  -xml             Output as XML parse tree"
            put : 0, "  -s <size>        Expand TXL tree space memory to <size> Mb (default 32)"
            put : 0, "  -analyze         Analyze grammar and rule set for ambiguities (slow)"
            put : 0, "  -u               Show TXL tree space memory usage statistics"
            put : 0, "  -o <file>        Write output to <file> (default standard output)"
            put : 0, "  -no<option>      Turn off <option> (e.g., -noraw)"
            put : 0, "  - <progoptions>  Pass <progoptions> to TXL program in global variable 'argv'"
            put : 0, ""
            put : 0, "Debugging options, output to standard error stream:"
            put : 0, "  -Dscan           Show scanner input tokens"
            put : 0, "  -Dparse          Show parser input parse tree"
            put : 0, "  -Dresult         Show transformer final result parse tree"
            put : 0, "  -Dgrammar        Show grammar as a parse tree schema"
            put : 0, "  -Dpattern        Show pattern and replacement parse tree schemas"
            put : 0, "  -Drules          Show names of rules as they are applied"
            put : 0, "  -Dapply          Show trace of transformations by rules"
        #if DEBUG then
            put : 0, "  -V               Show TXL version"
            put : 0, "  -Dtrees          Show partial parse trees as we parse (verbose)"
            put : 0, "  -Dstack          Show parse stack state at backtrack limit" 
            put : 0, "  -Dsharing        Show subtree sharing information (only if -Drules)"
            put : 0, "  -Dall            Turn on all debugging option (deadly verbose)"
        #end if
        #else
            put : 0, usage
        #end if
    end help

    procedure processOption (arg, arg2 : string, var argnum : int, setting : boolean, pragma : boolean)

        % Process an option flag
        const arglength := length (arg)

        if arg (1) not= "-" or arglength < 2 then
            return
        end if
            
        % All options are unique in first 2 characters
        const optionchar : char := arg (2)
        var optionchar2 : char := ' '
        if arglength > 2 then
            optionchar2 := arg (3)
        end if

        if (optionchar = 'h' or arg = "--help") and not pragma then
            % -h[elp], --help
            help
            quit

        elsif optionchar = 'V' and not pragma then
            % -V[ersion]
            put : 0, version 
            quit

        elsif optionchar = 'v' then
            % -v[erbose]
            option (verbose_p) := setting
            option (quiet_p) := not setting

        elsif optionchar = 'q' then
            % -q[uiet]
            option (quiet_p) := setting
            option (verbose_p) := not setting

        elsif optionchar = 'o' then
            % -o[utfile]
            argnum += 1
            if arg2 not= "" then
                outputSourceFileName := arg2
            end if

        elsif optionchar = 'w' then
            % -w[idth] <width>
            argnum += 1
            if arg2 not= "" then
                var newWidthString := arg2
                var newWidth := 0
                loop
                    exit when length (newWidthString) = 0 or
                        newWidthString (1) < '0' or newWidthString (1) > '9'
                    newWidth := newWidth * 10 + ord (newWidthString (1)) - ord ('0')
                    newWidthString := newWidthString (2 .. *)
                end loop
                outputLineLength := max (20, newWidth)
                option (width_p) := setting
            end if

        elsif optionchar = 's' and (optionchar2 = 'i' or optionchar2 = ' ') then
            % -s <size>, -si[ze] <size>
            argnum += 1
            if arg2 not= "" then
                var newSizeString := arg2
                var newSize := 0
                loop
                    exit when length (newSizeString) = 0 or
                        newSizeString (1) < '0' or newSizeString (1) > '9'
                    newSize := newSize * 10 + ord (newSizeString (1)) - ord ('0')
                    newSizeString := newSizeString (2 .. *)
                end loop
                if newSize < 1 then 
                    newSize := 1
                elsif newSize > 10000 then
                    newSize := 10000
                end if
                txlSize := newSize
                transformSize := newSize
                option (size_p) := setting
            end if

        elsif optionchar = 'x' then
            % -x[ml]
            option (xmlout_p) := setting

        % Flags that might be used or negated dynamically using [pragma] in a standalone app
        elsif optionchar = 't' and optionchar2 = 'o' then
            % -to[ken]
            option (charinput_p) := not setting
            option (raw_p) := option (charinput_p)

        elsif optionchar = 'c' and optionchar2 = 'h' then
            % -ch[ar]
            option (charinput_p) := setting
            option (raw_p) := option (charinput_p)

        elsif optionchar = 'r' and optionchar2 = 'a' then
            % -ra[w]
            option (raw_p) := setting

        elsif optionchar = 'n' and optionchar2 = 'e' then
            % -ne[wline]
            option (newline_p) := setting

        elsif (optionchar = 'L' or (optionchar = 'd' and optionchar2 = 'i')) and not pragma then
            % -L <libdir>, -di[r] <libdir>
            argnum += 1
            if arg2 not= "" then
                txlLibrary := arg2
                txlIncludeLibs (nTxlIncludeLibs) := txlLibrary
            end if

        elsif (optionchar = 'i' or optionchar = 'I') and optionchar2 = ' ' and not pragma then
            % -i <includedir>, -I <includedir>
            argnum += 1
            if arg2 not= "" then
                if nTxlIncludeLibs = maxTxlIncludeLibs then
                    error ("", "Too many -i include directories (> " + intstr (maxTxlIncludeLibs, 0) + ")", LIMIT_FATAL, 941)
                end if
                nTxlIncludeLibs += 1
                txlIncludeLibs (nTxlIncludeLibs) := txlIncludeLibs (nTxlIncludeLibs - 1)
                txlIncludeLibs (nTxlIncludeLibs - 1) := arg2
            end if

        elsif optionchar = 'a' and optionchar2 = 'n' then
            % -an[alyze]
            option (analyze_p) := setting

        elsif optionchar = 'a' and optionchar2 = 't' then
            % -at[tributes]
            option (attr_p) := setting

        elsif optionchar = 'r' and optionchar2 = 'a' then
            % -ra[w]
            option (raw_p) := setting

        elsif optionchar = 't' and optionchar2 = 'o' then
            % -to[ken]
            option (charinput_p) := not setting
            option (raw_p) := option (charinput_p)

        elsif optionchar = 't' and arg = "-tabnl" then
            % -tabnl
            option (notabnl_p) := not setting

        elsif optionchar = 't' and optionchar2 = 'x' then
            % -tx[l]
            option (txl_p) := setting

        elsif optionchar = 'i' and optionchar2 = 'n' then
            % -in[dent] <indentwidth>
            argnum += 1
            if arg2 not= "" then
                var newIndentString := arg2
                var newIndent := 0
                loop
                    exit when length (newIndentString) = 0 or
                        newIndentString (1) < '0' or newIndentString (1) > '9'
                    newIndent := newIndent * 10 + ord (newIndentString (1)) - ord ('0')
                    newIndentString := newIndentString (2 .. *)
                end loop
                indentIncrement := min (10, newIndent)
                option (indent_p) := setting
            end if

        elsif optionchar = 'u' and optionchar2 = 'u' then
            % -up[percase]
            option (upper_p) := setting

        elsif optionchar = 'u' and (optionchar2 = 's' or optionchar2 = ' ') then
            % -u, -us[age]
            option (usage_p) := setting

        elsif optionchar = 'c' and optionchar2 = 'o' then
            % -co[mment]
            option (comment_token_p) := setting

        elsif optionchar = 'c' and optionchar2 = 'h' then
            % -ch[ar]
            option (charinput_p) := setting
            option (raw_p) := option (charinput_p)

        elsif optionchar = 'c' and optionchar2 = 'a' then
            % -ca[se]
            option (case_p) := setting

    #if not NOLOADSTORE then
        elsif optionchar = 'c' and optionchar2 = ' ' and not pragma then
            % -c
            option (compile_p) := setting
    #end if

        elsif optionchar = 'n' and optionchar2 = 'e' then
            % -ne[wline]
            option (newline_p) := setting

        elsif optionchar = 'm' then
            % -m[ultiline]
            option (multiline_p) := setting

        elsif optionchar = 'i' and optionchar2 = 'd' then
            % -id[chars] '<idchars>'
            argnum += 1
            if arg2 not= "" then
                optionIdChars := arg2
                for idc : 1 .. length (optionIdChars)
                    const idchar : char := optionIdChars (idc)
                    charset.addIdChar (idchar, setting)
                end for
                updatedChars := true
            end if

        elsif optionchar = 's' and optionchar2 = 'p' then
            % -sp[chars] '<spchars>'
            argnum += 1
            if arg2 not= "" then
                optionSpChars := arg2
                for spc : 1 .. length (optionSpChars)
                    const spchar : char := optionSpChars (spc)
                    charset.addSpaceChar (spchar, setting) 
                end for
                updatedChars := true
            end if

        elsif optionchar = 'e' then
            % -e[scapechar] '<escapechar>'
            argnum += 1
            if arg2 not= "" then
                charset.setEscapeChar (arg2 (1), setting)
            end if

        elsif optionchar = 'd' then
            % -d[efine] SYMBOL
            argnum += 1
            if arg2 not= "" then
                setIfdefSymbol (arg2)
            end if

        elsif optionchar = 'l' and optionchar2 = 'o' then
            % -lo[wercase]
            option (lower_p) := setting
            
    #if not NOLOADSTORE then
        elsif optionchar = 'l' and optionchar2 = ' ' and not pragma then
            % -l
            option (load_p) := setting
    #end if

        elsif optionchar = 'D' then
            % -Doption, debugging flag
            const dbarg := arg (3 .. *)

            if dbarg = "parse" then
                option (parse_print_p) := setting
            elsif dbarg = "pattern" or dbarg = "patterns" then
                option (pattern_print_p) := setting
            elsif dbarg = "apply" then
                option (apply_print_p) := setting
            elsif dbarg = "rules" then
                option (rule_print_p) := setting
            elsif dbarg = "result" or dbarg = "final" then
                option (result_tree_print_p) := setting
        #if DEBUG then
            elsif dbarg = "boot" then
                option (boot_parse_p) := setting
        #end if
            elsif dbarg = "grammar" then
                option (grammar_print_p) := setting
            elsif dbarg = "sharing" then
                option (sharing_p) := setting
            elsif dbarg = "trees" then
                option (tree_print_p) := setting
            elsif dbarg = "stack" then
                option (stack_print_p) := setting
            elsif dbarg = "scan" or dbarg = "tokens" then
                option (tokens_p) := setting
            elsif dbarg = "all" then
                option (parse_print_p) := setting
                option (apply_print_p) := setting
                option (tree_print_p) := setting
                option (rule_print_p) := setting
                option (result_tree_print_p) := setting
                option (tokens_p) := setting

            else
                error ("", "Unrecognized debugging option '" + arg + "'", FATAL, 943)
            end if

        elsif optionchar = 'Z' then
            % Darren's dump-all debugging trace
            option (darren_p) := setting

        elsif optionchar = 'n' and optionchar2 = 'o' then
            % -noOPTION
            const noarg := "-" + arg (4 .. *)
            processOption (noarg, arg2, argnum, false, pragma)

        elsif optionchar = '-' and length (arg) > 2 then
            % --OPTION
            const noarg := "-" + arg (3 .. *)
            processOption (noarg, arg2, argnum, false, pragma)

        else
            #if STANDALONE then
                % Must be a user argument
                if nProgArgs < maxProgramArguments then
                    nProgArgs += 1
                    progArgs (nProgArgs) := "\"" + arg + "\""
                end if
            #else
                % Bad option flag
                useerror (pragma)
            #end if
        end if
    end processOption


    procedure processOptionsString (optionsString : string)
        
        % Handle #pragma or [pragma] options string
        updatedChars := false   % flag character map changes to scanner - JRC 10.4d
        var nextchar := 1
        var optionsStringLength := length (optionsString)
        loop
            exit when nextchar > optionsStringLength
            
            if optionsString (nextchar) = '-' then
                var option := optionsString (nextchar .. *)
                var option2 := ""
                var lengthoption2 := 0
                const spaceindex := index (option, " ")
                if spaceindex not= 0 then
                    option := option (1 .. spaceindex - 1)
                    option2 := optionsString (nextchar + spaceindex .. *)
                    if index (option2, " ") not= 0 then
                        option2 := option2 (1 .. index (option2, " ") - 1)
                    elsif option2 (*) = "\n" then
                        option2 := option2 (1 .. *-1)
                    end if
                    lengthoption2 := length (option2)
                    if index (option2, "'") = 1 or index (option2, "\"") = 1 then
                        option2 := option2 (2 .. *-1)
                    end if
                elsif option (*) = "\n" then
                    option := option (1 .. *-1)
                end if
                
                nextchar += length (option)
                
                var optionsaccepted := 1
                
                processOption (option, option2, optionsaccepted, true, true)
                
                if option2 not= "" and optionsaccepted > 1 then
                    nextchar += 1 + lengthoption2
                end if
                
            else
                nextchar += 1
            end if
        end loop
    end processOptionsString


    #if STANDALONE then
        procedure ctxlgettxlsize (target : addressint)
            external var TXL_CTXL: addressint
            type bytearray : array 0 .. 999999999 of nat1
            type dummyint : int
            const intsize := size (dummyint)
            var ctxlptr := intsize
            for b : 0 .. intsize - 1
                bytearray@(target) (b) := bytearray@(TXL_CTXL) (ctxlptr)
                ctxlptr += 1
            end for
        end ctxlgettxlsize
    #end if


    % TXL command line handling
    include "%system"

    var argcount := nargs

    % Perhaps they simply want to know how to use TXL
    if argcount = 0 then
        useerror (false)
    end if
    
    #if STANDALONE then
        % Standalone applications are by default quiet
        option (quiet_p) := true
    #end if

    % Handle command line args, see if they make sense
    var argnum := 1
    nProgArgs := 0
    loop
        exit when argnum > argcount

        var arg := fetcharg (argnum)
                
        if length (arg) > 1 and arg (1) = "-" then
            % A TXL command line option
            if argnum < argcount then
                processOption (arg, fetcharg (argnum + 1), argnum, true, false)
            else
                processOption (arg, "", argnum, true, false)
            end if

        elsif arg = "-" then
            % TXL program's own arguments follow
            for progargnum : argnum + 1 .. argcount
                exit when nProgArgs = maxProgramArguments
                nProgArgs += 1
                progArgs (nProgArgs) := "\"" + fetcharg (progargnum) + "\""
            end for
            exit

        else
            % Input or TXL program file name
            if inputSourceFileName = "" and arg not= "" then
                inputSourceFileName := arg

            #if STANDALONE then
                % Must be a user argument
                elsif nProgArgs < maxProgramArguments then
                    nProgArgs += 1
                    progArgs (nProgArgs) := "\"" + arg + "\""
            #else
                % Should be the TXL program file name
                elsif txlSourceFileName = "" and arg not= "" then
                    txlSourceFileName := arg
                else
                    % Screwed up argument files
                    useerror (false)
            #end if
            
            end if
        end if

        argnum += 1
    end loop
    
    if inputSourceFileName = "" and txlSourceFileName = "" then
        useerror (false)
    end if

    #if not STANDALONE then
        % Object source file and TXL source file reversed when used with #! - JRC 11.12.07
        if txlSourceFileName not= "" and index (txlSourceFileName, ".txl") = 0 and  
                (index (inputSourceFileName, ".txl") not= 0 or index (inputSourceFileName, ".ctxl") not= 0) then 
            const oldTxlSourceFileName := txlSourceFileName
            txlSourceFileName := inputSourceFileName
            inputSourceFileName := oldTxlSourceFileName
        end if

        % Infer TXL program file name if necessary
        if txlSourceFileName = "" then
            if option (compile_p) and index (inputSourceFileName, ".txl") not= 0 then
                % Only TXL file name given for compile
                txlSourceFileName := inputSourceFileName
                inputSourceFileName := ""
                
            else
                % Must infer TXL file name for input dialect
                assert inputSourceFileName not= ""
                var s := length (inputSourceFileName)
                loop
                    exit when s = 1 or inputSourceFileName (s - 1) = "."
                    s -= 1
                end loop
                txlSourceFileName := inputSourceFileName (s .. *) + ".txl"
            end if
        end if
        
        assert length (txlSourceFileName) >= 4

        % Make sure we can find and open the TXL program file 
        var sf := 0
        open : sf, txlSourceFileName, get

        if sf = 0 then
            % Perhaps it is lower case
            const oldTxlSourceFileName := txlSourceFileName
            txlSourceFileName := txlSourceFileName (1 .. length (txlSourceFileName) - 4) + ".txl"
            open : sf, txlSourceFileName, get
            if sf = 0 then
                txlSourceFileName := oldTxlSourceFileName
            end if
        end if

        if sf = 0 then
            % Perhaps it is just a grammar
            const oldTxlSourceFileName := txlSourceFileName
            txlSourceFileName := txlSourceFileName (1 .. length (txlSourceFileName) - 4) + ".grm"
            open : sf, txlSourceFileName, get
            if sf = 0 then
                txlSourceFileName := oldTxlSourceFileName
            end if
        end if

        if sf = 0 then
            % Perhaps it is in one of the library directories
            const oldTxlSourceFileName := txlSourceFileName
            open : sf, txlSourceFileName, get
            for i : 1 .. nTxlIncludeLibs
                txlSourceFileName := txlIncludeLibs (i) + directoryChar + oldTxlSourceFileName
                open : sf, txlSourceFileName, get
                exit when sf not= 0
                % Perhaps it is in lower case
                txlSourceFileName := txlSourceFileName (1 .. length (txlSourceFileName) - 4) + ".txl"
                open : sf, txlSourceFileName, get
                exit when sf not= 0
                % Perhaps it is just a grammar
                txlSourceFileName := txlSourceFileName (1 .. length (txlSourceFileName) - 4) + ".grm"
                open : sf, txlSourceFileName, get
                exit when sf not= 0
            end for
            if sf = 0 then
                txlSourceFileName := oldTxlSourceFileName
            end if
        end if
        
        % Make sure we actually found it
        if sf = 0 then
            error ("", "Can't find TXL program file '" + txlSourceFileName + "'", FATAL, 944)
        end if
            
        assert sf not= 0
        close : sf

        #if not NOLOADSTORE then
            % Infer compiled program file name if necessary
            if option (compile_p) or option (load_p) then
                const sflength := length (txlSourceFileName)
                if sflength > 4 and 
                        (txlSourceFileName (sflength - 3 .. *) = ".txl" 
                         or txlSourceFileName (sflength - 3 .. *) = ".grm") then
                    txlCompiledFileName := txlSourceFileName (1 .. sflength - 3) + "ctxl"
                else
                    txlCompiledFileName := txlSourceFileName 
                end if
            end if

            % If loading, attempt to open the compiled program file and get size
            if option (load_p) then
                var tf : int
                open : tf, txlCompiledFileName, read
                if tf = 0 then
                    error ("", "Can't open TXL load file '" + txlCompiledFileName + "'", FATAL, 945)
                end if
                var mn : int
                read : tf, mn
                read : tf, txlSize
                if not option (size_p) then
                    transformSize := txlSize
                end if
                close : tf
            end if
        #end if

    #else
        % Standalone program - get the compiled size from the compiled byte array 
        option (load_p) := true
        ctxlgettxlsize (addr (txlSize))
        if not option (size_p) then
            transformSize := txlSize
        end if
    #end if

end options
