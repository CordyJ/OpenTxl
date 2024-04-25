% OpenTxl Version 11 scanner
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

% The TXL input scanner.
% Reads input as text and breaks it into an array of tokens, as defined by the TXL or object language grammar.

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Removed unused external rule statement.
%       Removed old COBOL specializations.

% v11.3 Fixed lookahead source line number bug.
%       Fixed multiple nl-comments source line number bug.
%       Added support for all standard line endings LF, CR, CR-LF

module scanner

    import 
        var charset, var ident, var inputTokens, 
        var lastTokenIndex, var fileNames, var nFiles, 
        var options, error, var kindType

    export 
        tokenize,
        keyP, 

        % and for stats, load/store only
        compoundTokens, nCompounds, compoundIndex,      
        commentStart, commentEnd, nComments,
        patternEntryT, tokenPatterns, nPatterns, patternIndex, patternNLCommentIndex, 
        patternLink, nPatternLinks, 
        keywordTokens, nKeys, nTxlKeys, lastKey 

    % Compound literal tokens
    type * compoundT :
        record
            length_ : int
            literal : string 
        end record
    
    var compoundTokens : array 1 .. maxCompoundTokens + 1 of compoundT % (sic)
    var nCompounds := 0
    var compoundIndex : array chr (0) .. chr (255) of int

    % Comment brackets
    var commentStart, commentEnd : array 1 .. maxCommentTokens of tokenT
    var nComments := 0

    % Token Pattern Table
    % Holds both TXL and object language token tokenPatterns
    type * patternCodeT : 0 .. 1000     % int2 subrange
    type * patternT : array 1 .. maxTuringStringLength + 1 of patternCodeT
    type * patternEntryT :
        record
            kind : kindT
            name : tokenT
            pattern : patternT
            length_ : int
            next : int
        end record

    var nPatterns, nPredefinedPatterns := 0
    var tokenPatterns : array 1 .. maxTokenPatterns of patternEntryT
    var patternIndex : array chr (0) .. chr (255) of int
    var patternNLCommentIndex := 0
    var nPatternLinks := 0
    var patternLink : array 1 .. maxTokenPatternLinks of int
    var nextUserTokenKind : kindT := firstUserTokenKind

    % Magic characters
    const * EOF := chr (4)      % ASCII/Unicode EOT
    const * EOS := chr (0)      % ASCII/Unicode NUL

    % Token pattern characters - these codes must be distinct from any in extended ASCII or Unicode
    const * EOSPAT := 0

    % Ranges used in standard 16-bit Unicode
    %    00 .. FF               (000 .. 255):           ASCII
    % 01 00 .. 01 7F    (256 .. 383):           Latin Extended-A
    % 01 80 .. 02 4F    (384 .. 591):           Latin Extended-B
    % 1E 02 .. 1E F3    (7682 .. 7923):         Latin Extended Addiional
    % 2C 60 .. 2C 7F    (11360 .. 11391):       Latin Extended-C
    % A7 20 .. A7 FF    (42784 .. 43007):       Latin Extended-D
    % AB 30 .. AB 6F    (43824 .. 43887):       Latin Extended-E

#if UNICODE then
    % Automatically recogzining theses, since they don't conflict with ASCII
    % For the first few UTF-16 codes compatible with ASCII, we automatically change any two byte 
    % Unicode character C beginning with these to sequence pattern (C) 
    const * UNICODEA := chr (16#01)
    const * UNICODEB := chr (16#02)
    const * UNICODEN := chr (16#08)             % ASCII BS - after this conflict with TAB
    const * UNICODEX := chr (16#1E)

    % Not automatically supporting these yet, since they conflict
    % const * UNICODEC := 16#2C
    % const * UNICODED := 16#A7
    % const * UNICODEF := 16#AB
#end if

    % Reserved TXL Pattern Codes - closest to 0 avoiding above
    const * PATTERN := 600

    % meta-character classes and special characters, \n, \t, \d, \a, ...
    const * NEWLINE :=  PATTERN + 0
    const * TAB :=      PATTERN + 1
    const * DIGIT :=    PATTERN + 2
    const * ALPHA :=    PATTERN + 3
    const * ID :=       PATTERN + 4
    const * UPPER :=    PATTERN + 5
    const * UPPERID :=  PATTERN + 6
    const * LOWER :=    PATTERN + 7
    const * LOWERID :=  PATTERN + 8
    const * SPECIAL :=  PATTERN + 9
    const * ANY :=      PATTERN + 10
    const * ALPHAID :=  PATTERN + 11
    const * RETURN :=   PATTERN + 12

    % complements of above, #t, #n, #d, #a, ...
    const * NOTNEWLINE :=       PATTERN + 20
    const * NOTTAB :=           PATTERN + 21
    const * NOTDIGIT :=         PATTERN + 22
    const * NOTALPHA :=         PATTERN + 23
    const * NOTID :=            PATTERN + 24
    const * NOTUPPER :=         PATTERN + 25
    const * NOTUPPERID :=       PATTERN + 26
    const * NOTLOWER :=         PATTERN + 27
    const * NOTLOWERID :=       PATTERN + 28
    const * NOTSPECIAL :=       PATTERN + 29
    const * NOTANY :=           PATTERN + 30
    const * NOTALPHAID :=       PATTERN + 31
    const * NOTRETURN :=        PATTERN + 32

    % #... negated pattern
    const * NOT :=              PATTERN + 40

    % [...], #[...] choice, negated choice
    const * CHOICE :=   PATTERN + 41
    const * NOTCHOICE :=        PATTERN + 42

    % (...), #(...) sequence, negated sequence
    const * SEQUENCE :=         PATTERN + 43
    const * NOTSEQUENCE :=      PATTERN + 44

    % :..., #:... lookahed, negated lookahead
    const * LOOKAHEAD :=        PATTERN + 45
    const * NOTLOOKAHEAD :=     PATTERN + 46

    % \\... escaped character
    const * ESCAPE :=   PATTERN + 47

    % Meta-character to pattern code maps
    const * nPatternChars := 13
    const * patternChars : array 1 .. nPatternChars of char := 
        init ('d', 'a', 'u', 'i', 'A', 'I', 'b', 'j', 's', 'c', 'n', 'r', 't')
    const * patternCodes : array 1 .. nPatternChars of patternCodeT := 
        init (DIGIT, ALPHA, ALPHAID, ID, UPPER, UPPERID, LOWER, LOWERID, SPECIAL, ANY, NEWLINE, RETURN, TAB)
    const * patternNotCodes : array 1 .. nPatternChars of patternCodeT := 
        init (NOTDIGIT, NOTALPHA, NOTALPHAID, NOTID, NOTUPPER, NOTUPPERID, NOTLOWER, 
              NOTLOWERID, NOTSPECIAL, EOSPAT, NOTNEWLINE, NOTRETURN, NOTTAB)

    % Keyword Table
    % Holds both TXL and object language keywordTokens
    var keywordTokens : array 1 .. maxKeys of tokenT  
    var nKeys, nTxlKeys, lastKey := 0

    function keyP (token : tokenT) : boolean
        var register lo : nat := 1
        var register hi : nat := nKeys 
        loop
            exit when lo > hi

            const mid : nat := (lo + hi) div 2
            const register kwtmid : tokenT := keywordTokens (mid)

            if token < kwtmid then
                hi := mid - 1
            elsif token > kwtmid then
                lo := mid + 1
            else
                result true
            end if
        end loop

        result false
    end keyP

    % T+ standard input stream
    var stdin := -2

    % Current input file
    var inputStream : int := 0

    % TXL source include facility
    var includeStack : array 1 .. maxIncludeDepth of 
        record
            file : int
            filenum : int
            linenum : int
        end record
    var includeDepth := 0

    % Directory context for includes
    var sourceFileDirectory := ""

    % Input text buffer
    % the + maxTuringStringLength + 1 is for type cheats
    const inputBufferFactor := 2        % must be >= 2 - JRC 7.6.08
                                        % doesn't have to be big any more - JRC 6.4.12
    % Use variable buffer size, to force dynamic allocation for efficiency
    var lineBufferSize := maxLineLength*inputBufferFactor + maxTuringStringLength + 1
    var inputline : array 1 .. lineBufferSize of char   
    inputline (1) := EOS

    var nextinputline := ""
    var nextlength := 0
    var inputchar : int

    % Current input file number
    var filenum : int

    % Current input line number
    var linenum : int

    % Kind of source file - TXL source must be scanned specially due to its multi-language context
    var txlSource : boolean
    var fileInput : boolean

    % Text buffer for [parse] predefined function - 
    % length must match the type longstring in predef.i
    var sourceText : char (maxLineLength + maxTuringStringLength + 1)
    
    % Only give the max input lines warning once 
    var warnedLines := false

    % Add a scanned token to the inputTokens array
    procedure installToken (kind : kindT, token : tokenT, rawtoken : tokenT)
        lastTokenIndex += 1

        if lastTokenIndex >= maxTokens then  % (sic)
            error ("", "Input too large (total length > " + intstr (maxTokens, 1) + " tokens)"
                + " (a larger size is required for this input)", LIMIT_FATAL, 141)
        end if

        if linenum > maxLines then  
            if not warnedLines then
                error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                    "Input file too long (> " + intstr (maxLines, 1) + " lines)"
                    + " (a larger size should be used for this input)", LIMIT_WARNING, 142)
                warnedLines := true
            end if
        end if

        bind var inputToken to inputTokens (lastTokenIndex)
        inputToken.token := token
        inputToken.rawtoken := rawtoken
        inputToken.kind := kind
        inputToken.linenum := filenum * maxLines + linenum

        ident.setKind (token, kind)
        ident.setKind (rawtoken, kind)

        % Debugging output from -Dtokens
        if options.option (tokens_p) and not txlSource then
            put : 0, "<" ..
            if char@(ident.idents (kindType (ord (kind)))) = '*' then
                put : 0, string@(ident.idents (kindType (ord (kind))) + 1) ..
            else
                put : 0, string@(ident.idents (kindType (ord (kind)))) ..
            end if
            put : 0, " text=\"" ..
            charset.putXmlCode (0, string@(ident.idents (rawtoken)))
            put : 0, "\"/>"
        end if
    end installToken
 

    % Get the next buffer of input text from the input source
    procedure getInputLine

        if fileInput then

            if options.option (multiline_p) and not txlSource then

                % Object language input can have multiline tokens, so we buffer many lines of text at once
                % Default for object languages

                if (inputStream = stdin and eof) or eof (inputStream) then

                    % End of input
                    if length (type (string, inputline)) = 0 then
                        inputline (1) := EOF
                        inputline (2) := EOS
                    end if
                    
                else

                    % Refill buffer
                    var lengthSoFar := length (type (string, inputline))
                    loop
                        exit when lengthSoFar >= maxLineLength*inputBufferFactor
                        
                        if inputStream = stdin then
                            get type (string, inputline (lengthSoFar + 1)) : *
                        else
                            get : inputStream, type (string, inputline (lengthSoFar + 1)) : *
                        end if
                        
                        var bufferlength := length (type (string, inputline (lengthSoFar + 1)))
                        
                        if bufferlength = maxTuringStringLength then
                            var nextIndex := lengthSoFar + bufferlength
                            loop
                                var buffer : string
                                if inputStream = stdin then
                                    get buffer : *
                                else
                                    get : inputStream, buffer : *
                                end if
                                
                                bufferlength := length (buffer)
                                
                                if nextIndex - 1 + bufferlength - lengthSoFar > maxLineLength then
                                    error ("", "Input line too long (> " + intstr (maxLineLength, 1) + " characters)", LIMIT_FATAL, 144)
                                end if
   
                                type (string, inputline (nextIndex + 1)) := buffer
                                
                                nextIndex += bufferlength
                                
                                exit when bufferlength not= maxTuringStringLength
                            end loop
                            lengthSoFar := nextIndex
                        else
                            lengthSoFar += bufferlength
                        end if
                            
                        type (string, inputline (lengthSoFar + 1)) := "\n"
                        lengthSoFar += 1
                        
                        exit when (inputStream = stdin and eof) or eof (inputStream)
                    end loop    

                end if

            else  % not options.option (multiline), or txlSource

                % Object language without multiline tokens, or txl language itself
                
                if (inputStream = stdin and eof) or eof (inputStream) then
                    % End of input
                    inputline (1) := EOF
                else
                
                    % Single line free-form input
                    if inputStream = stdin then
                        get type (string, inputline) : *
                    else
                        get : inputStream, type (string, inputline) : *
                    end if
                    
                    if length (type (string, inputline)) = maxTuringStringLength then
                        % The single line is longer than our max string length, so continue reading it

                        if not txlSource then
                            var nextIndex := maxTuringStringLength + 1
                            loop
                                var buffer : string
                                if inputStream = stdin then
                                    get buffer : *
                                else
                                    get : inputStream, buffer : *
                                end if
                                
                                const bufferlength := length (buffer)
                                
                                if nextIndex - 1 + bufferlength > maxLineLength then
                                    error ("", "Input line too long (> " + intstr (maxLineLength, 1) + " characters)", LIMIT_FATAL, 144)
                                end if

                                type (string, inputline (nextIndex)) := buffer
                                exit when bufferlength not= maxTuringStringLength
                                nextIndex += maxTuringStringLength
                            end loop
                        else
                            % TXL source programs are limited to max string length lines
                            error ("", "TXL program line too long (> " + intstr (maxTuringStringLength - 1, 1) + " characters)", LIMIT_FATAL, 145)
                        end if
                    end if
                    
                   type (string, inputline) += "\n"
                end if

            end if
                
        else    % not fileInput

            % String text to scan, from the [parse] predefined function

            if sourceText (1) not= EOF or sourceText (2) not= EOS then
                type (string, inputline) := type (string, sourceText)
                type (string, inputline) += "\n"  % always give newline in new regimen
                % Mark the end of the string as end of input
                sourceText (1) := EOF
                sourceText (2) := EOS

            else
                % Make sure we only give EOF if we've already processed the text
                inputline (1) := EOF
                inputline (2) := EOS
            end if
        end if
        
        % Begin at the first character in the buffer
        inputchar := 1

    end getInputLine


    % TXL language include file facility
    % Maintain a stack of currently open files, reading input from the top file

    procedure PushInclude
        % Get the new include file name from the TXL include statement, and be sure we align on a line boundary
        var newFileName := type (string, inputline (inputchar))

        % Strip quotes from the file name
        if index (newFileName, "\"") not= 0 then
            newFileName := newFileName (index (newFileName, "\"")+1..*)
        end if

        if index (newFileName, "\"") not= 0 then
            newFileName := newFileName (1..index (newFileName, "\"")-1)
        end if

        % Remember what directory we started in!
        const oldNewFileName := newFileName
        newFileName := sourceFileDirectory + newFileName

        % Open the new included source file
        if nFiles = maxFiles then
            error ("", "Too many source include files (>" + intstr (maxFiles, 1) + ")", LIMIT_FATAL, 149)
        end if
        
        var newInputStream : int
        open : newInputStream, newFileName, get
        
        for i : 1 .. options.nTxlIncludeLibs
            exit when newInputStream not= 0
            newFileName := options.txlIncludeLibs (i) + directoryChar + oldNewFileName
            open : newInputStream, newFileName, get
        end for

        if newInputStream = 0 then
            error ("", "Unable to find include file '" + oldNewFileName + "'", FATAL, 150)
        end if

        % Push old source file onto the include stack
        if includeDepth = maxIncludeDepth then
            error ("", "Include file nesting too deep (>" + intstr (maxIncludeDepth, 1) + ")", LIMIT_FATAL, 151)
        end if

        includeDepth += 1
        bind var is to includeStack (includeDepth) 
        is.file := inputStream
        is.filenum := filenum
        is.linenum := linenum

        nFiles += 1
        fileNames (nFiles) := newFileName

        filenum := nFiles
        inputStream := newInputStream

        % Start reading from the new include file
        linenum := 0
        getInputLine

    end PushInclude

    procedure PopInclude
        % Revert to the previous source file after end of file on the included file
        pre includeDepth > 0
        close : inputStream

        % Continue where we left off in the previous file (i.e., following the TXL include statement)
        bind is to includeStack (includeDepth) 
        inputStream := is.file 
        filenum := is.filenum 
        linenum := is.linenum

        includeDepth -= 1

        type (string, inputline) := "\n"        % remember to count the include line
        inputchar := 1
    end PopInclude


    % We need scanToken when opening a file, in case the first line is an object language comment
    % See detailed explanation below
    forward function scanToken (pattern : patternT, startpos, endpos : int, test : boolean) : boolean

    procedure openFile (fileNameOrText : string)
        % Open a main TXL or object language input source file, or string input for [parse]
        nFiles := 1

        if fileInput then
            % Open a TXL or object language input source file
            fileNames (1) := fileNameOrText

            % Standard input is already open
            if fileNameOrText = "" or fileNameOrText = "stdin" or fileNameOrText = "STDIN" then
                inputStream := stdin
            else
                open : inputStream, fileNameOrText, get
            end if

            if inputStream = 0 then
                error ("", "Unable to open source file '" + fileNameOrText + "'", FATAL, 152)
            end if

            % Remember the main source file's directory path, for context in processing TXL include files
            if index (fileNameOrText, "/") not= 0 or index (fileNameOrText, "\\") not= 0 then
                sourceFileDirectory := fileNameOrText
                loop
                    exit when sourceFileDirectory (*) = "/" or sourceFileDirectory (*) = "\\" 
                    sourceFileDirectory := sourceFileDirectory (1 .. *-1)
                end loop
            end if

        else
            % Input from a string of text to be scanned and parsed using [parse]
            fileNames (1) := "(no file)"
            type (string, sourceText) := fileNameOrText
        end if
        
        % Very special case, for object languages with first column marker comments of the form
        %       * this is a comment
        % for example in Snobol, when specified using a token pattern of the form
        %       comment  "\n\*#n*"

        if options.option (multiline_p) and not txlSource then
            % If newline comments are allowed, there is an implicit newline at the beginning of the file
            if options.option (nlcomments_p) and options.option (newline_p) and not options.option (charinput_p) then
                type (string, inputline) := "\n"
            else
                inputline (1) := EOS
            end if
        end if

        % Initialize the input text buffer
        filenum := 1
        linenum := 0

        getInputLine

        % We begin scanning on line 1 
        linenum := 1

        % Continuing the very special case outlined above, we only need the implicit newline 
        % if the input actually begins with a newline comment

        if options.option (multiline_p) and not txlSource then
            if options.option (nlcomments_p) and options.option (newline_p) and not options.option (charinput_p) then
                % Do we have a leading newline comment?
                var nlpatindex := patternIndex ('\n')
                assert nlpatindex not= 0
                var leadingNLcomment := false
                loop
                    bind pp to tokenPatterns (patternLink (nlpatindex))
                    if pp.kind = kindT.comment and scanToken (pp.pattern, 1, pp.length_, true) then
                        leadingNLcomment := true
                    end if
                    nlpatindex += 1
                    exit when leadingNLcomment or patternLink (nlpatindex) = 0
                end loop
                                
                if leadingNLcomment then
                    % If so, keep the implicit newline, but it's on line 0 
                    linenum := 0
                    inputchar := 1
                else
                    % Skip the implicit newline, and we begin on line 1
                    linenum := 1
                    inputchar := 2
                end if
            end if
        end if

    end openFile

    procedure closeFile
        % Close the main input file
        if fileInput and inputStream not= stdin then
            close : inputStream
            inputStream := 0
        end if
    end closeFile

    
    % TXL Preprocessor module 
    % Conditional compilation handling for TXL, providing #define, #ifdef, #else, #endif
    % See handlePreprocessorDirective below for details
    
    % Stack of currently nested #ifdefs
    var ifdefStack : array 1 .. maxIfdefDepth of boolean
    var ifdefFile : array 1 .. maxIfdefDepth of int
    var ifdefTop := 0
    
    procedure synchronizePreprocessor
        if ifdefTop > 0 and ifdefFile (ifdefTop) = filenum then
            error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                "Preprocessor syntax error: missing #endif directive", FATAL, 153)     
            ifdefTop := 0
        end if
    end synchronizePreprocessor
    
    procedure pushIfdef (symbol : string, negated : boolean)
        const symbolIndex := options.lookupIfdefSymbol (symbol)
        if ifdefTop < maxIfdefDepth then
            ifdefTop += 1
            ifdefFile (ifdefTop) := filenum
            if negated then
                ifdefStack (ifdefTop) := (symbolIndex = 0)
            else
                ifdefStack (ifdefTop) := (symbolIndex not= 0)
            end if
        else
            error ("", "#ifdef nesting too deep (>" + intstr (maxIfdefDepth, 0) + " levels deep)", LIMIT_FATAL, 155)     
        end if
    end pushIfdef
    
    procedure popIfdef 
        if ifdefTop > 0 then
            ifdefTop -= 1
        else
            error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                "Preprocessor syntax error: too many #endif directives (no matching #if)", FATAL, 156)     
        end if
    end popIfdef
    
    function trueIfdef : boolean
        pre ifdefTop > 0
        result ifdefStack (ifdefTop)
    end trueIfdef
    
    const pMatchingElsifElseOrEndif := 1
    const pMatchingEndif := 2
    
    procedure flushLinesUntilPreprocessorDirective (whichDirective : int)
        loop
            getInputLine
            linenum += 1        % JRC 25.5.20
            exit when inputline (inputchar) = EOF
            if index (type (string, inputline (inputchar)), "#") not= 0 then
                const startchar := inputchar
                % Skip blanks
                loop
                    exit when not charset.spaceP (inputline (inputchar))
                    inputchar += 1
                end loop
                % See if it is a preprocessor line
                if inputline (inputchar) = '#' then
                    % Skip #
                    inputchar += 1
                    % Skip blanks
                    loop
                        exit when not charset.spaceP (inputline (inputchar))
                        inputchar += 1
                    end loop
                    % See if this is the one
                    if index (type (string, inputline (inputchar)), "end") = 1
                            or whichDirective = pMatchingElsifElseOrEndif 
                                and (index (type (string, inputline (inputchar)), "elsif") = 1
                                    or index (type (string, inputline (inputchar)), "elif") = 1
                                    or index (type (string, inputline (inputchar)), "else") = 1) then
                        inputchar := startchar
                        exit
                    elsif index (type (string, inputline (inputchar)), "if") = 1 then
                        flushLinesUntilPreprocessorDirective (pMatchingEndif)
                    end if
                end if
            end if
        end loop
        if inputline (inputchar) = EOF then
            error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                "Preprocessor syntax error: missing #endif directive", FATAL, 157)     
        end if
    end flushLinesUntilPreprocessorDirective
    
    forward procedure sortTokenPatterns
    
    procedure handlePreprocessorDirective
        pre inputline (inputchar) = '#'
        
        % TXL preprocessor directives
        %
        %       #pragma -arg ...                                        Set command line arguments
        %
        %       #def[ine] SYM                                           Define symbol
        %       #undef[ine] SYM                                         Undefine symbol
        %
        %       #if[n][def] SYM { [[and|or] SYM } [then]                If symbol defined
        %       #els[e]if[n][def] SYM { [[and|or] SYM } [then]          Elsif symbol defined
        %       #else
        %       #end[if]
        %
        %       #! ...                                                  Unix kernel directive
        
        % Skip #
        inputchar += 1
        
        % Skip blanks
        loop
            exit when not charset.spaceP (inputline (inputchar))
            inputchar += 1
        end loop
        
        % Which directive do we have?
        if index (type (string, inputline (inputchar)), "def") = 1 
                or index (type (string, inputline (inputchar)), "undef") = 1 then
            % #def[ine] SYM
            % #undef[ine] SYM
            const define := inputline (inputchar) = 'd'
            loop
                exit when inputline (inputchar) = EOS or charset.spaceP (inputline (inputchar))
                inputchar += 1
            end loop
            % Skip blanks
            loop
                exit when not charset.spaceP (inputline (inputchar))
                inputchar += 1
            end loop
            % Get symbol
            var startchar := inputchar
            loop
                exit when not charset.idP (inputline (inputchar))
                inputchar += 1
            end loop
            var symbol := type (string, inputline) (startchar .. inputchar-1)
            if symbol = "" then
                error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                    "Preprocessor syntax error: missing symbol in #define or #undefine directive", FATAL, 158) 
            end if
            % Define or undefine it
            if define then
                options.setIfdefSymbol (symbol)
            else
                options.unsetIfdefSymbol (symbol)
            end if
            % Discard line
            getInputLine
            linenum += 1        % JRC 25.5.20
            
        elsif index (type (string, inputline (inputchar)), "if") = 1
                or index (type (string, inputline (inputchar)), "elsif") = 1
                or index (type (string, inputline (inputchar)), "elif") = 1
                or index (type (string, inputline (inputchar)), "elseif") = 1 then
            % #el[s][e]if[n][def] [not] SYM [then]      
            % #if[n][def] [not] SYM [then]
            const firstif := inputline (inputchar) = 'i'
            const ifindex := index (type (string, inputline (inputchar)), "if")
            assert ifindex not= 0
            var negated := inputline (inputchar - 1 + ifindex + 2) = 'n'
            loop
                exit when inputline (inputchar) = EOS or charset.spaceP (inputline (inputchar))
                inputchar += 1
            end loop
            % Skip blanks
            loop
                exit when not charset.spaceP (inputline (inputchar))
                inputchar += 1
            end loop
            % Get symbol
            var startchar := inputchar
            loop
                exit when not charset.idP (inputline (inputchar))
                inputchar += 1
            end loop
            var symbol := type (string, inputline) (startchar .. inputchar-1)
            if symbol = "" then
                error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                    "Preprocessor syntax error: missing symbol in #if or #elsif directive", FATAL, 159) 
            end if
            % Check for 'if not SYM'
            if symbol = "not" then
                negated := not negated
                % Skip blanks
                loop
                    exit when not charset.spaceP (inputline (inputchar))
                    inputchar += 1
                end loop
                % Get symbol
                startchar := inputchar
                loop
                    exit when not charset.idP (inputline (inputchar))
                    inputchar += 1
                end loop
                symbol := type (string, inputline) (startchar .. inputchar-1)
                if symbol = "" then
                    error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                        "Preprocessor syntax error: missing symbol in #if or #elsif directive", FATAL, 159) 
                end if
            end if
            % Test it
            if firstif then
                pushIfdef (symbol, negated)
                if not trueIfdef then
                    % Trash the true part
                    flushLinesUntilPreprocessorDirective (pMatchingElsifElseOrEndif)
                else
                    % Discard line
                    getInputLine
                    linenum += 1        % JRC 25.5.20
                end if
            else
                if ifdefTop = 0 then
                    error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                        "Preprocessor syntax error: #else or #elsif not nested inside #if", FATAL, 161) 
                end if
                if trueIfdef then 
                    % Trash the false part
                    flushLinesUntilPreprocessorDirective (pMatchingEndif)
                else
                    % The previous alternatives were false; try this one
                    popIfdef
                    pushIfdef (symbol, negated)
                    if not trueIfdef then
                        % Trash the true part
                        flushLinesUntilPreprocessorDirective (pMatchingElsifElseOrEndif)
                    else
                        % Discard line
                        getInputLine
                        linenum += 1    % JRC 25.5.20
                    end if
                end if
            end if
    
        elsif index (type (string, inputline (inputchar)), "else") = 1 then
            % #else
            if ifdefTop = 0 then
                error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                    "Preprocessor syntax error: #else or #elsif not nested inside #if", FATAL, 161) 
            end if
            if trueIfdef then
                % Trash the false part
                flushLinesUntilPreprocessorDirective (pMatchingEndif)
            else
                % Discard line
                getInputLine
                linenum += 1    % JRC 25.5.20
            end if
    
        elsif index (type (string, inputline (inputchar)), "end") = 1 then
            % #end[if]
            popIfdef
            % Discard line
            getInputLine
            linenum += 1        % JRC 25.5.20
            
        elsif index (type (string, inputline (inputchar)), "pragma") = 1 then
            % #pragma -ARG ...
            options.processOptionsString (type (string, inputline (inputchar)))
    
            % Discard line
            getInputLine
            linenum += 1        % JRC 25.5.20
            
            % If character maps were updated, reset scanner links - JRC 10.4d
            if options.updatedChars then
                sortTokenPatterns
            end if
            
        elsif inputline (inputchar) = '!' then
            % #! ... Unix kernel directivee - just discard the line
            getInputLine
            linenum += 1        % JRC 25.5.20

        else
            error ("line " + intstr (linenum + 1, 1) + " of " + fileNames (filenum),
                "Preprocessor directive syntax error at or near:\n    " + type (string, inputline (inputchar)), FATAL, 163) 
        end if
        
    end handlePreprocessorDirective

        
    procedure skipTxlComment
        pre inputline (inputchar) = '%' 
        
        % Multiline comment %( )% or %( )% - JRC 22.9.07
        if inputline (inputchar + 1) = '(' or inputline (inputchar + 1) = '{' then
            var comend : string := ")%"
            if inputline (inputchar + 1) = '{' then
                comend := "}%"
            end if
            
            var comindex : int
            loop
                comindex := index (type (string, inputline (inputchar)), comend)
                exit when comindex not= 0
                getInputLine
                linenum += 1  % JRC 23.9.08
                exit when inputline (inputchar) = EOF
            end loop
            
            if inputline (inputchar) = EOF then
                error ("at end of " + fileNames (filenum), 
                        "Syntax error - comment ends at end of file", FATAL, 164)
            end if

            inputchar := comindex + 2   % JRC 2.2.15

            % No, keep rest of line after )% - JRC 2.2.16
            /***
            % Note that multiline comments end in )% or }%, which for consistency implies that
            % the rest of the last line is comment also - JRC 22.9.07
        
            % Discard line
            getInputLine
            linenum += 1  % JRC 23.9.08
            ***/

        else
            % SIngle line comment - discard line
            getInputLine
            linenum += 1  % JRC 23.9.08
        end if
        
    end skipTxlComment

    procedure skipSeparators
        if options.option (multiline_p) and not txlSource then
            loop
                % Skip blanks
                if not options.option (charinput_p) then
                    loop
                        exit when not charset.spaceP (inputline (inputchar))
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                    end loop
                end if
                
                % See if we need to get a new line
                 
                % Make sure that there is always at least one full maxLineLength lookahead
                % when scanning the next token - JRC 7.6.08
                assert inputBufferFactor >= 2
                
                if fileInput and inputchar > maxLineLength*(inputBufferFactor-1) then
                    #if CHECKED then
                        for i : 1 .. length (type (string, inputline (inputchar))) + 1  % (sic)
                            inputline (i) := inputline (inputchar + i - 1)
                        end for
                    #else
                        % Don't try this at home, kids!
                        type (string, inputline) := type (string, inputline (inputchar))
                    #end if

                    getInputLine
                    
                    if (not charset.spaceP (inputline (inputchar))) or options.option (charinput_p) then
                        return
                    end if
                    
                elsif inputline (inputchar) = EOS then
                    inputline (1) := EOS
                    getInputLine
                    
                    if (not charset.spaceP (inputline (inputchar))) or options.option (charinput_p) then
                        return
                    end if
                    
                else 
                    return
                end if
            end loop
        
        else
            assert txlSource or not options.option (multiline_p)
            
            loop
                % Skip blanks
                const beginningOfLine := inputchar = 1
                if txlSource or not options.option (charinput_p) then
                    loop
                        exit when not charset.spaceP (inputline (inputchar))
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                    end loop
                end if
                
                % See if we need to get a new line
                if inputline (inputchar) = EOS then
                    getInputLine
                    exit when inputline (inputchar) = EOF
                    
                % Check for TXL comments and preprocessor directives
                elsif txlSource then
                    if inputline (inputchar) = '%' then
                        skipTxlComment
                    elsif beginningOfLine and inputline (inputchar) = '#' then
                        handlePreprocessorDirective
                    else
                        return
                    end if
                
                else 
                    return
                end if
            end loop
        end if
    end skipSeparators


    body function scanToken % (pattern : patternT, startpos, endpos : int, test : boolean) : boolean

        % Walk through pattern
        var pos := startpos
        const startchar := inputchar
        const startlinenum := linenum

        loop
            var pat: patternCodeT := pattern (pos)
            var fail := true

            case pat of

                % Character class

                label DIGIT :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when not charset.digitP (inputline (inputchar))
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label ALPHA :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when not charset.alphaP (inputline (inputchar))
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label ALPHAID :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when not charset.alphaidP (inputline (inputchar))
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label ID :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when not charset.idP (inputline (inputchar))
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label UPPER :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when not charset.upperP (inputline (inputchar))
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label UPPERID :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when not charset.upperidP (inputline (inputchar))
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label LOWER :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when not charset.lowerP (inputline (inputchar))
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label LOWERID :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when not charset.loweridP (inputline (inputchar))
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label SPECIAL :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when not charset.specialP (inputline (inputchar))
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label ANY :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NEWLINE :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when inputline (inputchar) not= '\n'
                        inputchar += 1
                        linenum += 1
                        fail := false
                        exit when not repeated
                    end loop

                label RETURN :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when inputline (inputchar) not= '\r'
                        inputchar += 1
                        if inputline (inputchar) not= '\n' and inputline (inputchar) not= EOS then
                            linenum += 1
                        end if
                        fail := false
                        exit when not repeated
                    end loop

                label TAB :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when inputline (inputchar) not= '\t'
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop


                % Inverted character class

                label NOTDIGIT :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when charset.digitP (inputline (inputchar)) or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTALPHA :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when charset.alphaP (inputline (inputchar)) or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTALPHAID :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when charset.alphaidP (inputline (inputchar)) or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTID :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when charset.idP (inputline (inputchar)) or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTUPPER :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when charset.upperP (inputline (inputchar)) or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTUPPERID :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when charset.upperidP (inputline (inputchar)) or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTLOWER :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when charset.lowerP (inputline (inputchar)) or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTLOWERID :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when charset.loweridP (inputline (inputchar)) or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTSPECIAL :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when charset.specialP (inputline (inputchar)) or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTNEWLINE :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when inputline (inputchar) = '\n' or inputline (inputchar) = EOS
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTRETURN :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when inputline (inputchar) = '\r' or inputline (inputchar) = EOS
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label NOTTAB :
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when inputline (inputchar) = '\t' or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop

                label CHOICE :
                    % Choice - a set of alternative subpatterns
                    pos += 1
                    const len := pattern (pos)

                    % Calculate range of alternative subpatterns in pattern
                    const altsubsstartpos := pos + 1
                    const altsubsendpos := pos + len 

                    % Skip choice
                    pos += len + 2
                    const repeated := charset.repeaterP (chr (pattern (pos)))

                    loop
                        % Try each alternative subpattern
                        var substartpos := altsubsstartpos
                        var subfail := true
                        const startinputchar := inputchar 

                        loop
                            exit when substartpos > altsubsendpos

                            % Isolate the alternative subpattern
                            const spat := pattern (substartpos) 
                            var subendpos := substartpos

                            % If the alternative is non-trivial, find the end of it
                            case spat of
                                label CHOICE, NOTCHOICE, SEQUENCE, NOTSEQUENCE :
                                    subendpos := substartpos + pattern (substartpos + 1) + 2
                                label ESCAPE, NOT :
                                    subendpos += 1
                                label :
                            end case

                            % If it has a repeat indicator, include that
                            if charset.repeaterP (chr (pattern (subendpos + 1))) then
                                subendpos += 1
                            end if

                            % Now see if we can scan one of those
                            if scanToken (pattern, substartpos, subendpos, test) then
                                subfail := false
                                exit
                            end if

                            % Otherwise move on to the next alternative
                            substartpos := subendpos + 1
                        end loop

                        % If all alternatives failed, no sense going on
                        exit when subfail

                        % Otherwise we found at least one
                        fail := false

                        exit when not repeated

                        % don't repeat a null forever!
                        exit when inputchar = startinputchar
                    end loop

                label NOTCHOICE : % #[...]
                    % Negated choice - a set of alternative subpatterns,
                    % all of which must fail in order to accept a single character
                    pos += 1
                    const len := pattern (pos)

                    % Calculate range of alternative subpatterns in pattern
                    const altsubsstartpos := pos + 1
                    const altsubsendpos := pos + len 

                    % Skip choice
                    pos += len + 2
                    const repeated := charset.repeaterP (chr (pattern (pos)))

                    loop
                        % Try each alternative subpattern - if any succeeds, we are done
                        var substartpos := altsubsstartpos
                        var subfail := true
                        const startinputchar := inputchar 
                        const substartlinenum := linenum 

                        loop
                            exit when substartpos > altsubsendpos

                            % Isolate the alternative subpattern
                            const spat := pattern (substartpos) 
                            var subendpos := substartpos

                            % If the alternative is non-trivial, find the end of it
                            case spat of
                                label CHOICE, NOTCHOICE, SEQUENCE, NOTSEQUENCE :
                                    subendpos := substartpos + pattern (substartpos + 1) + 2
                                label ESCAPE, NOT :
                                    subendpos += 1
                                label :
                            end case

                            % If it has a repeat indicator, include that
                            if charset.repeaterP (chr (pattern (subendpos + 1))) then
                                subendpos += 1
                            end if

                            % Now see if we can scan one of those
                            if scanToken (pattern, substartpos, subendpos, test) then
                                subfail := false
                                exit
                            end if

                            % Otherwise move on to the next alternative
                            substartpos := subendpos + 1
                        end loop

                        % If any alternative succeeded, we are done
                        if not subfail then
                            inputchar := startinputchar
                            linenum := substartlinenum
                            exit
                        end if

                        % Otherwise we found at least one - remember and accept it
                        exit when inputline (inputchar) = EOS

                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1

                        fail := false

                        exit when not repeated
                    end loop

                label SEQUENCE :
                    % Sequence - a grouped subpattern
                    pos += 1
                    const len := pattern (pos)

                    % Calculate end of subpattern
                    const substartpos := pos + 1
                    const subendpos := pos + len

                    % Skip sequence
                    pos += len + 2
                    const repeated := charset.repeaterP (chr (pattern (pos)))

                    % Now step through the sequence
                    loop
                        % scanToken accepts a whole sequence anyway, so this is easy
                        exit when not scanToken (pattern, substartpos, subendpos, test)

                        % If we are here, then the sequence succeeded at least once
                        fail := false

                        exit when not repeated
                    end loop

                label NOTSEQUENCE : % #(...)
                    % Negated sequence - a sequence that must fail in order to accept a single character
                    pos += 1
                    const len := pattern (pos)

                    % Calculate range of alternative subpatterns in pattern
                    const substartpos := pos + 1
                    const subendpos := pos + len 

                    % Skip sequence
                    pos += len + 2
                    const repeated := charset.repeaterP (chr (pattern (pos)))

                    loop
                        var subfail := true
                        const startinputchar := inputchar 

                        % See if we can scan the sequence
                        if scanToken (pattern, substartpos, subendpos, test) then
                            subfail := false
                        end if

                        % If the sequence succeeded, we are done
                        if not subfail then
                            inputchar := startinputchar
                            exit
                        end if

                        % Otherwise we found at least one - remember and accept it
                        exit when inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false

                        exit when not repeated
                    end loop
                    
                label LOOKAHEAD :  % \:...
                    % Lookahead - test end of pattern 
                    const substartpos := pos + 1
                    const subendpos := endpos

                    pos := endpos + 1   % skip lookahead pattern

                    var subfail := true
                    const lookinputchar := inputchar 
                    const looklinenum := linenum

                    % See if we can scan the lookahead
                    if scanToken (pattern, substartpos, subendpos, test) then
                        subfail := false
                    end if

                    % Either way, we back up
                    inputchar := lookinputchar
                    linenum := looklinenum

                    if not subfail then
                        % The lookahead succeeded
                        exit
                    else
                        % The lookahead failed
                    end if

                label NOTLOOKAHEAD :  % #\:...
                    % Inverted lookahead - test not end of pattern 
                    const substartpos := pos + 1
                    const subendpos := endpos

                    pos := endpos + 1   % skip lookahead pattern

                    var subfail := true
                    const lookinputchar := inputchar 
                    const looklinenum := linenum

                    % See if we can scan the lookahead
                    if scanToken (pattern, substartpos, subendpos, test) then
                        subfail := false
                    end if

                    % Either way, we back up
                    inputchar := lookinputchar
                    linenum := looklinenum

                    if subfail then
                        % The inverted lookahead succeeded
                        exit
                    else
                        % The inverted lookahead failed
                    end if

                label ESCAPE :
                    % Escaped meta-character
                    pat := pattern (pos + 1)
                    pos += 2
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when ord (inputline (inputchar)) not= pat
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop


                label NOT  :
                    % Inverted character
                    pat := pattern (pos + 1)
                    pos += 2
                    const repeated := charset.repeaterP (chr (pattern (pos))) 
                    loop
                        exit when ord (inputline (inputchar)) = pat or inputline (inputchar) = EOS
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop


                label :
                    % Literal character
                    pos += 1
                    const repeated := charset.repeaterP (chr (pattern (pos)))
                    loop
                        exit when ord (inputline (inputchar)) not= pat
                        if inputline (inputchar) = '\n' then
                            linenum += 1
                        end if
                        if inputline (inputchar) = '\r' then
                            if inputline (inputchar + 1) = '\n' then
                                inputchar += 1
                            end if
                            linenum += 1
                        end if
                        inputchar += 1
                        fail := false
                        exit when not repeated
                    end loop
            end case


            if charset.optionalP (chr (pattern (pos))) then 
                % The pattern allows null matches - so ok no matter what!
                pos += 1

            else
                % The pattern requires us to accept something
                if pattern (pos) = ord ('+') then
                    pos += 1
                end if

                % If we failed to do that, back up so we can try another alternative
                if fail then
                    if not test then
                        inputchar := startchar
                    end if
                    linenum := startlinenum

                    result false
                end if
            end if

            exit when pos > endpos
        end loop

        result true
    end scanToken


    function scanCompoundLiteral (litindex : int) : boolean
        var i := litindex
        bind inp to type (string, inputline (inputchar))
        #if CHECKED then
            const inplength := length (inp)
        #end if
        loop
            begin
                bind lit to compoundTokens (i)

            #if CHECKED then
                if inplength >= lit.length_ and inp (1 .. lit.length_) = lit.literal then       
            #else
                if inp (1 .. lit.length_) = lit.literal then    % Hup! Dangerous, but buffer has extra - JRC 16 June 08
            #end if
                    inputchar += lit.length_
                    result true
                end if
            end

            i += 1

            exit when i > nCompounds or compoundTokens (i).literal (1) not= inp (1)
        end loop

        result false
    end scanCompoundLiteral


    function commentindex (commentstarttoken : tokenT) : int
        for c : 1 .. nComments
            if commentstarttoken = commentStart (c) then
                result c
            end if
        end for
        result 0
    end commentindex


    procedure scanComment (startchararg : int, comindex : int)
        var startchar := startchararg
        var comtoken : tokenT

        /*** JRC 1.5.08
        % New multiline logic
        if options.option (multiline_p) and not txlSource then
        ***/

            var indent := ""
            var comend := string@(ident.idents (commentEnd (comindex)))
            
            if commentEnd (comindex) = NOT_FOUND then
                comend := "\n"
            end if
            
            var firstline : boolean := true
            var comstartlength := length (string@(ident.idents (commentStart (comindex))))
            
            loop
                if startchar > maxLineLength*(inputBufferFactor-1) then
                    #if CHECKED then
                        for i : 1 .. length (type (string, inputline (startchar))) + 1  % (sic)
                            inputline (i) := inputline (startchar + i - 1)
                        end for
                    #else
                        % Don't try this at home, kids!
                        type (string, inputline) := type (string, inputline (startchar))
                    #end if
                    getInputLine
                    startchar := inputchar
                elsif inputline (inputchar) = EOS then
                    inputline (1) := EOS
                    getInputLine
                    startchar := inputchar
                end if
                            
                var comendindex := index (type (string, inputline (startchar)), comend)
                if firstline and comendindex not=0 and comendindex <= comstartlength then
                    comendindex := index (type (string, inputline (startchar + comstartlength)), comend) 
                    if comendindex not= 0 then
                        comendindex += comstartlength
                    end if
                end if
                
                const newlineindex := index (type (string, inputline (startchar)), "\n")

                if inputline (startchar) not= EOF and newlineindex not= 0 and (comendindex not= 0 => (newlineindex < comendindex)) then

                    % We're continuing
                    if options.option (comment_token_p) then
                        % Include newline in internal commment lines - JRC 10.5a
                        % Can't use string operations here, because they are limited
                        % to 255 chars - so cheat by truncating manually - JRC 10.5f
                        const savedchar := inputline (startchar + newlineindex)
                        inputline (startchar + newlineindex) := EOS
                        if length (type (string, inputline (startchar))) > (maxTuringStringLength - length (indent)) then
                            comtoken := ident.install (type (string, inputline (startchar)), kindT.comment)
                        else
                            % Safe to concatenate
                            comtoken := ident.install (indent + type (string, inputline (startchar)), kindT.comment)
                        end if
                        installToken (kindT.comment, comtoken, comtoken)
                        inputline (startchar + newlineindex) := savedchar
                    end if
                    
                    linenum += 1

                    inputchar := startchar + newlineindex
                    
                    % Unless it was a line comment
                    exit when commentEnd (comindex) = NOT_FOUND

                    if options.option (comment_token_p) 
                            and not options.option (charinput_p) then   % don't trim or indent raw comments - JRC 11.6.99
                        loop
                            exit when (not charset.spaceP (inputline (inputchar))) or inputline (inputchar) = '\n'
                                or inputline (inputchar) = '\r'
                            inputchar += 1
                        end loop
                        indent :=  "   "
                    end if
                    
                elsif comendindex not= 0 then

                    % We're done
                    if options.option (comment_token_p) then
                        % Can't use string operations here, because they are limited
                        % to 255 chars - so cheat by truncating manually - JRC 10.5f
                        var lencomend := length (comend)
                        if comend = "\n" then
                            linenum += 1
                            lencomend := 0
                        end if
                        const savedchar := inputline (startchar + comendindex + lencomend - 1) 
                        inputline (startchar + comendindex + lencomend - 1) := EOS
                        if length (type (string, inputline (startchar))) > (maxTuringStringLength - length (indent)) then
                            comtoken := ident.install (type (string, inputline (startchar)), kindT.comment)
                        else
                            % Safe to concatenate
                            comtoken := ident.install (indent + type (string, inputline (startchar)), kindT.comment)
                        end if
                        installToken (kindT.comment, comtoken, comtoken)
                        inputline (startchar + comendindex + lencomend - 1) := savedchar

                    end if

                    inputchar := startchar + comendindex + length (comend) - 1
                    
                    % Line-ended comment should not include newline in new logic - JRC 10.5b
                    if comend = "\n" then
                        if options.option (comment_token_p) then
                            linenum -= 1
                        end if
                        inputchar -= 1
                    end if
                    %
                    
                    exit
                    
                else
                    % What the heck?
                    assert comendindex = 0

                    if inputline (startchar) = EOF then
                        error ("at end of " + fileNames (filenum), "Syntax error - comment ends at end of file", FATAL, 164)
                    else
                        error ("", "Input line too long (> " + intstr (maxLineLength, 1) + " characters)", LIMIT_FATAL, 144)
                    end if
                end if
                
                startchar := inputchar
                firstline := false
            end loop

    end scanComment


    procedure sortCompoundTokens
        % Step 1. Bubblesort compoundTokens to ascending order by first character
        for decreasing k : nCompounds .. 2
            var swap := false
            for j : 2 .. k
                if compoundTokens (j - 1).literal (1) > compoundTokens (j).literal (1) then
                    const temp := compoundTokens (j - 1)
                    compoundTokens (j - 1) := compoundTokens (j)
                    compoundTokens (j) := temp
                    swap := true
                end if
            end for
            exit when not swap
        end for

        % Step 2. Sort compoundTokens within first character in descending order of length
        loop
            var swap := false
            for k : 1 .. nCompounds - 1
                if compoundTokens (k).literal (1) = compoundTokens (k + 1).literal (1) then
                    if compoundTokens (k).length_ < compoundTokens (k + 1).length_ then
                        const temp := compoundTokens (k + 1)
                        compoundTokens (k + 1) := compoundTokens (k)
                        compoundTokens (k) := temp
                        swap := true
                    end if
                end if
            end for
            exit when not swap
        end loop

        % Mark end of compoundTokens
        compoundTokens (nCompounds + 1).literal := chr (255)  % (sic)
        compoundTokens (nCompounds + 1).length_ := 1

        % Step 3. Build the literal index table
        var k := 1
        for c : chr (0) .. chr (255)
            if k <= nCompounds and compoundTokens (k).literal (1) = c then
                compoundIndex (c) := k
                loop
                    k += 1
                    exit when k > nCompounds or compoundTokens (k).literal (1) > c
                end loop
            else
                compoundIndex (c) := 0
            end if
        end for
    end sortCompoundTokens


    procedure sortKeywords (firstkey : int)
        % Step 1. Move active keyword set to beginning of keywords
        if firstkey > 1 then
            var kk := 0
            for k : firstkey .. lastKey
                kk += 1
                keywordTokens (kk) := keywordTokens (k)
            end for
            nKeys := kk
        end if

        % Step 2. Bubblesort active keyword tokens to ascending order
        for decreasing k : nKeys .. 2
            var swap := false
            for j : 2 .. k
                if keywordTokens (j - 1) > keywordTokens (j) then
                    const temp := keywordTokens (j - 1)
                    keywordTokens (j - 1) := keywordTokens (j)
                    keywordTokens (j) := temp
                    swap := true
                end if
            end for
            exit when not swap
        end for
    end sortKeywords


    procedure linkpattern (c : char, p : int)
        % If this pattern can begin with character c ...
        inputline (1) := c 
        inputline (2) := EOS
        inputchar := 1

        if scanToken (tokenPatterns (p).pattern, 1, tokenPatterns (p).length_, true) then
            % (just want side effect on inputchar)
        end if

        %  ... then we need to link it in as an alternative
        if inputchar not= 1 then
            nPatternLinks += 1

            if nPatternLinks >= maxTokenPatternLinks then  % (sic)
                error ("", "Too many token patterns (links) (>" 
                    + intstr (maxTokenPatternLinks, 1) + ")", LIMIT_FATAL, 166)
            end if

            if patternIndex (c) = 0 then
                % It is the first pattern that can begin with this character 
                patternIndex (c) := nPatternLinks
            end if

            patternLink (nPatternLinks) := p
        end if
    end linkpattern


    body procedure sortTokenPatterns
        % This routine and linkpattern() use the first two characters 
        % in inputline for temporary pattern tests
        const saveinputline1 := inputline (1)
        const saveinputline2 := inputline (2)
        const saveinputchar := inputchar

        for p : 1 .. nPatterns 
            % If this pattern can accept the null string, something's wrong ...
            inputline (1) := EOS
            inputchar := 1
    
            if scanToken (tokenPatterns (p).pattern, 1, tokenPatterns (p).length_, true) then
                error ("", "Token pattern for '" + string@(ident.idents (tokenPatterns (p).name))
                    + "' accepts the null string", WARNING, 165) 
            end if
        end for

        % Build the pattern index table
        nPatternLinks := 0

        for c : chr (0) .. chr (255)
            patternIndex (c) := 0

            % User tokenPatterns take precedence, but in order specified
            for p : nPredefinedPatterns + 1 .. nPatterns
                linkpattern (c, p)
            end for

            % Then predefined tokenPatterns
            for p : 1 .. nPredefinedPatterns 
                linkpattern (c, p)
            end for

            if patternIndex (c) not= 0 then
                % Mark end of possibilities
                nPatternLinks += 1
                patternLink (nPatternLinks) := 0

                % Consolidate lists
                if c > chr (0) and patternIndex (chr (ord (c) - 1)) not= 0 then
                    var l1 := patternIndex (chr (ord (c) - 1))
                    var l2 := patternIndex (c)
                    var same := true
                    loop
                        if patternLink (l1) not= patternLink (l2) then
                            same := false
                            exit
                        end if

                        exit when patternLink (l1) = 0

                        l1 += 1
                        l2 += 1
                    end loop

                    if same then
                        nPatternLinks := patternIndex (c) - 1
                        patternIndex (c) := patternIndex (chr (ord (c) - 1))
                    end if
                end if
            end if
        end for

        % Restore state of inputline after temporary pattern tests
        inputline (1) := saveinputline1
        inputline (2) := saveinputline2
        inputchar := saveinputchar
    end sortTokenPatterns


    procedure setTokenPattern (p : int, kind : kindT, name : string, pattern : string)
        const patternlength := length (pattern)
        var encodedpattern : patternT

        % Brackets stack to match [ ] and ( ) in patterns
        var brackets : array 1 .. maxTuringStringLength + 1 of 
            record
                closebracket : char
                index : int
            end record
        var bracketstop := 0
        
        var i,j := 1
        loop
            exit when i > patternlength 

            var pi : char := pattern (i)
            var encodedpi := ord (pi)

            if pi = '\\' or (pi = '#' and (patternlength > i => (pattern (i+1) not= '[' and pattern (i+1) not= '('))) then
                if i = patternlength then
                    error ("", "Syntax error in token pattern for '" + name + "' (\\ or # at end of pattern)", FATAL, 167)
                end if

                if pi = '\\' then
                    i += 1
                    pi := pattern (i)
                    encodedpi := ord (pi)
                    
                    var code : patternCodeT := EOSPAT

                    for c : 1 .. nPatternChars
                        if patternChars (c) = pi then
                            code := patternCodes (c)
                            exit
                        end if
                    end for

                    if code = EOSPAT then
                        if (not charset.metaP (pi)) and pi not= '"' and pi not= ':' then
                            error ("", "Escaped character \\" + pi + " in token pattern for '" 
                                + name + "' is not a valid token pattern meta-character", WARNING, 169)
                        end if

                        if pi = ':' then
                            % new lookahead metacharacter - JRC 10.5e
                            if bracketstop > 0 then
                                error ("", "Syntax error in token pattern for '" 
                                    + name + "' (lookahead test \\: must be a trailing pattern)", FATAL, 181)
                            end if
                            encodedpi := LOOKAHEAD
                        else
                            encodedpattern (j) := ESCAPE
                            j += 1
                        end if
                    else
                        encodedpi := code
                    end if

                else
                    assert pi = '#' 
                    i += 1
                    pi := pattern (i)

                    if pi = '\\' and i < patternlength then
                        i += 1
                        pi := pattern (i)
                    end if

                    encodedpi := ord (pi)

                    var code : patternCodeT := EOSPAT

                    for c : 1 .. nPatternChars
                        if patternChars (c) = pi then
                            code := patternNotCodes (c)
                            exit
                        end if
                    end for

                    if code = EOSPAT then
                        if pi = ':' then
                            % negated lookahead #: or #\:
                            if bracketstop > 0 then
                                error ("", "Syntax error in token pattern for '" 
                                    + name + "' (lookahead test \\: must be a trailing pattern)", FATAL, 181)
                            end if
                            encodedpi := NOTLOOKAHEAD
                        else
                            % not of a regular character
                            encodedpattern (j) := NOT 
                            j += 1
                        end if
                    else
                        encodedpi := code
                    end if
                end if

            elsif pi = '[' or (pi = '#' and patternlength > i and pattern (i+1) = '[') then
                if pi = '#' then
                    i += 1
                    encodedpattern (j) := NOTCHOICE
                else
                    encodedpattern (j) := CHOICE
                end if
                j += 1
                bracketstop += 1
                brackets (bracketstop).closebracket := ']'
                brackets (bracketstop).index := j
                pi := EOS
                encodedpi := EOSPAT

            elsif pi = '(' or (pi = '#' and patternlength > i and pattern (i+1) = '(') then
                if pi = '#' then
                    i += 1
                    encodedpattern (j) := NOTSEQUENCE
                else
                    encodedpattern (j) := SEQUENCE
                end if
                j += 1
                bracketstop += 1
                brackets (bracketstop).closebracket := ')'
                brackets (bracketstop).index := j
                pi := EOS
                encodedpi := EOSPAT

            elsif pi = ']' or pi = ')' then
                if bracketstop > 0 and brackets (bracketstop).closebracket = pi then
                    const len := j - brackets (bracketstop).index - 1
                    assert encodedpattern (brackets (bracketstop).index) = EOSPAT
                    encodedpattern (brackets (bracketstop).index) := len
                    bracketstop -= 1
                else
                    error ("", "Syntax error in token pattern for '" + name + "' (unbalanced () or [])", FATAL, 170)
                end if
                encodedpi := ord (pi)
                
            % Handle magic characters by automatically escaping them - this enables full 8-bit character set handling - JRC 10.4d
            elsif charset.magicP (pi) then
                encodedpattern (j) := ESCAPE
                j += 1
                encodedpi := ord (pi)
            %
            end if

            encodedpattern (j) := encodedpi
            j += 1
            i += 1
        end loop

        if bracketstop > 0 then
            error ("", "Syntax error in token pattern for '" + name + "' (unbalanced () or [])", FATAL, 170)
        end if

        encodedpattern (j) := EOSPAT
        
        % Multiline logic
        if name = "comment" and encodedpattern (1) = NEWLINE then
            options.setOption (nlcomments_p, true)
            patternNLCommentIndex := p
        end if
        %

        % Install the token pattern definition
        bind var tp to tokenPatterns (p)
        tp.kind := kind
        tp.name := ident.install (name, kindT.id)
        if kind >= firstUserTokenKind and kind <= lastUserTokenKind then
            kindType (ord (kind)) := tp.name
        end if
        tp.pattern := encodedpattern
        tp.length_ := j - 1
        tp.next := 0
    end setTokenPattern


    % Patterns for predefined tokens
    var idPattern, numberPattern, stringlitPattern, charlitPattern := 0

    procedure defaultTokenPatterns
        % Default predefined token classes
        setTokenPattern (1, kindT.stringlit, "stringlit", "\"[(\\\\\\c)#\"]*\"")
        setTokenPattern (2, kindT.charlit, "charlit", "'[(\\\\\\c)#']*'")
        setTokenPattern (3, kindT.id, "id", "\\u\\i*")
        setTokenPattern (4, kindT.number, "number", "\\d+(.\\d+)?([eE][+-]?\\d+)?")
        
        % These two actually only take effect when -char or -newline is specified
        setTokenPattern (5, kindT.space, "space", "[    ]+")
        setTokenPattern (6, kindT.newline, "newline", "\n")

        % This one allows for ignoring input - intentionally undefined to begin with
        setTokenPattern (7, kindT.empty, "ignore", "\"$%&*/ UNDEFINED /*&%$\"")

        % Number of predefined token classes
        nPatterns := 7
        nPredefinedPatterns := nPatterns

        % The [id] pattern, which must allow for TXL keywords
        idPattern := 3

        % The [stringlit] and [charlit] patterns
        stringlitPattern := 1
        assert stringlitPattern < idPattern     % allow for leading letter overrides (e.g., L"foo") - JRC 7.6.21
        charlitPattern := 2
        assert charlitPattern < idPattern       % allow for leading letter overrides (e.g., U'foo') - JRC 7.6.21

        % The [number] pattern
        numberPattern := 4
        assert idPattern < numberPattern        % allow for leading digit overrides (e.g., 3a) - JRC 7.6.21

        % Link in the defaults
        sortTokenPatterns

        % Default TXL keywords
        keywordTokens (1) := ident.install ("[", kindT.literal)
        keywordTokens (2) := ident.install ("]", kindT.literal)
        keywordTokens (3) := ident.install ("|", kindT.literal)
        keywordTokens (4) := ident.install ("end", kindT.id)
        keywordTokens (5) := ident.install ("keys", kindT.id)
        keywordTokens (6) := ident.install ("define", kindT.id)
        keywordTokens (7) := ident.install ("repeat", kindT.id)
        keywordTokens (8) := ident.install ("list", kindT.id)
        keywordTokens (9) := ident.install ("opt", kindT.id)
        keywordTokens (10) := ident.install ("rule", kindT.id)
        keywordTokens (11) := ident.install ("function", kindT.id)
        keywordTokens (13) := ident.install ("replace", kindT.id)
        keywordTokens (14) := ident.install ("by", kindT.id)
        keywordTokens (15) := ident.install ("match", kindT.id)
        keywordTokens (16) := ident.install ("skipping", kindT.id)
        keywordTokens (17) := ident.install ("construct", kindT.id)
        keywordTokens (18) := ident.install ("deconstruct", kindT.id)
        keywordTokens (19) := ident.install ("where", kindT.id)
        keywordTokens (20) := ident.install ("not", kindT.id)
        keywordTokens (21) := ident.install ("include", kindT.id)
        keywordTokens (22) := ident.install ("comments", kindT.id)
        keywordTokens (23) := ident.install ("compounds", kindT.id)
        keywordTokens (24) := ident.install ("tokens", kindT.id)
        keywordTokens (25) := ident.install ("all", kindT.id)
        keywordTokens (26) := ident.install ("import", kindT.id)
        keywordTokens (27) := ident.install ("export", kindT.id)
        keywordTokens (28) := ident.install ("assert", kindT.id)
        keywordTokens (29) := ident.install ("...", kindT.literal)
        nKeys := 29
        nTxlKeys := 29
        lastKey := 29

        % Link in the defaults
        sortKeywords (1)
    end defaultTokenPatterns


    procedure expectend (expectedword : string)
        skipSeparators
        const startchar := inputchar
        loop
            exit when not charset.idP (inputline (inputchar))
            inputchar += 1
        end loop
        const gotword := type (string, inputline) (startchar .. inputchar - 1) 
        if gotword not= expectedword then
            error ("line " + intstr (linenum, 1) + " of " + fileNames (filenum), 
                "Syntax error - expected 'end " + expectedword + "', got 'end " +
                gotword + "'", FATAL, 172)
        end if
    end expectend


    function isId (id : string) : boolean
        for i : 1 .. length (id)
            const idi : char := id (i)
            if not charset.idP (idi) then
                result false
            end if
        end for
        result true
    end isId


    procedure setCompoundToken (literal : string)
        if length (literal) = 1 then
            % It is already a literal!
            return
        end if

        if nCompounds = maxCompoundTokens then
            error ("", "Too many compound literals (>" + intstr (maxCompoundTokens, 1) + ")", LIMIT_FATAL, 173)
        end if

        nCompounds += 1
        compoundTokens (nCompounds).literal := literal
        compoundTokens (nCompounds).length_ := length (literal)
    end setCompoundToken


    procedure setKeyword (keyword : string)
        if lastKey = maxKeys then
            error ("", "Too many keywords (>" + intstr (maxKeys, 1) + ")", LIMIT_FATAL, 174)
        end if

        lastKey += 1

        if options.option (case_p) then
            var lowerKeyword := ""
            for i : 1 .. length (keyword)
                type char4095 : char (4095)
                lowerKeyword += charset.lowercase (type (char4095, keyword) (i))
            end for
            keywordTokens (lastKey) := ident.install (lowerKeyword, kindT.id)
        else
            keywordTokens (lastKey) := ident.install (keyword, kindT.id)
        end if
    end setKeyword


    procedure processCompoundTokens
        % User defined compound tokens
        loop
            skipSeparators

            if inputline (inputchar) = '\'' then
                % Quoted literal 
                inputchar += 1
            end if

            exit when inputline (inputchar) = EOF 

            const startchar := inputchar
            loop
                exit when charset.separatorP (inputline (inputchar))
                inputchar += 1
            end loop

            const literal := type (string, inputline) (startchar .. inputchar - 1)

            exit when literal = "end"

            setCompoundToken (literal)
        end loop

        expectend ("compounds")

        sortCompoundTokens
    end processCompoundTokens


    procedure processCommentBrackets
        % User defined comment conventions
        loop
            skipSeparators

            if inputline (inputchar) = '\'' then
                % Quoted comment 
                inputchar += 1
            end if

            exit when inputline (inputchar) = EOF 

            var startchar := inputchar
            loop
                exit when charset.separatorP (inputline (inputchar))
                inputchar += 1
            end loop

            var commentbracket := type (string, inputline) (startchar .. inputchar - 1)

            exit when commentbracket = "end"

            if isId (commentbracket) then
                setKeyword (commentbracket)
            elsif length (commentbracket) > 1 then
                setCompoundToken (commentbracket)
            end if

            if nComments = maxCommentTokens then
                error ("", "Too many comment conventions (>" + intstr (maxCommentTokens, 1) + ")", LIMIT_FATAL, 175)
            end if

            nComments += 1
            commentStart (nComments) := ident.install (commentbracket, kindT.literal)

            loop
                exit when not charset.spaceP (inputline (inputchar))
                inputchar += 1
            end loop

            if inputline (inputchar) not= EOS and inputline (inputchar) not= '%' then

                if inputline (inputchar) = '\'' then
                    % Quoted comment 
                    inputchar += 1
                end if

                if inputline (inputchar) not= EOF and inputline (inputchar) not= EOS then

                    startchar := inputchar
                    loop
                        exit when charset.separatorP (inputline (inputchar))
                        inputchar += 1
                    end loop

                    commentbracket := type (string, inputline) (startchar .. inputchar - 1)
    
                    /**** No reason for comment end bracket to be a keyword or compound - JRC 20.6.12
                    if isId (commentbracket) then
                        setKeyword (commentbracket)
                    elsif length (commentbracket) > 1 then
                        setCompoundToken (commentbracket)
                    end if
                    ****/

                    commentEnd (nComments) := ident.install (commentbracket, kindT.literal)

                else
                    commentEnd (nComments) := NOT_FOUND
                end if

            else
                commentEnd (nComments) := NOT_FOUND
            end if
        end loop

        expectend ("comments")

        sortCompoundTokens
    end processCommentBrackets


    procedure processKeywordTokens
        % User defined keywords
        loop
            skipSeparators

            var quoted := false

            if inputline (inputchar) = '\'' then
                % Quoted key 
                inputchar += 1
                quoted := true
            end if

            exit when inputline (inputchar) = EOF 

            const startchar := inputchar
            loop
                exit when charset.separatorP (inputline (inputchar))
                inputchar += 1
            end loop

            const key := type (string, inputline) (startchar .. inputchar - 1)

            exit when key = "end" and not quoted

            setKeyword (key)
        end loop

        expectend ("keys")

        % We should not link these in with sortKeywords until we are done 
        % scanning the entire TXL program, because the keywords specified by 
        % the user do not take effect until we are actually scanning object 
        % language source, such as tokenPatterns, replacements, or input.
    end processKeywordTokens


    procedure processTokenPatterns
        % User defined tokens
        var name := ""
        loop
            skipSeparators

            exit when inputline (inputchar) = EOF 
            
            if (inputline (inputchar) = '|' or inputline (inputchar) = '+') and name not= "" then
                % Another alternative for the previous token (handled below)
            else
                % A new or extended old token
                var startchar := inputchar
                loop
                    exit when not charset.idP (inputline (inputchar))
                    inputchar += 1
                end loop

                name := type (string, inputline) (startchar .. inputchar - 1)
            
                if name = "" then
                    error ("", "Syntax error in token pattern definition (expected token name, got '"
                        + type (string, inputline) (startchar .. *) + "')", FATAL, 176)
                end if
            end if

            exit when name = "end" 

            skipSeparators

            exit when inputline (inputchar) = EOF

            % See if we are extending an existing token
            var extension := false

            % Allow elipsis for consistency with extended defines
            if inputline (inputchar) = '.' and inputline (inputchar + 1) = '.' 
                    and inputline (inputchar + 2) = '.' then
                inputchar += 3
                skipSeparators
            end if
                
            % (+ allowed for backward compatibility)
            if inputline (inputchar) = '|' or inputline (inputchar) = '+' then    
                extension := true
                inputchar += 1
                skipSeparators
                exit when inputline (inputchar) = EOF
            end if

            var startchar := inputchar

            if inputline (inputchar) = '"' then
                var lastchar := '"'
                inputchar += 1
                loop
                    exit when inputline (inputchar) = '"' 
                    exit when inputline (inputchar) = EOS
                    inputchar += 1
                    if inputline (inputchar - 1) = '\\' and inputline (inputchar) not= EOS then
                        inputchar += 1
                    end if
                end loop
                if inputline (inputchar) = '"' then
                    inputchar += 1
                end if
            end if

            var pattern := type (string, inputline) (startchar .. inputchar - 1)
            
            if pattern = "\"\"" then
                % Intentionally undefined token
                pattern := "\"$%&*/ UNDEFINED /*&%$\""
            end if

            if length (pattern) < 3 or pattern (1) not= '"' or pattern (*) not= '"' then
                error ("", "Syntax error in token pattern definition (expected pattern string, got '"
                    + type (string, inputline) (startchar .. *) + "')", FATAL, 177)
            end if

            pattern := pattern (2 .. * - 1)

            % It is either an override, an extension, or a new token
            var newp := 0
            var kind := kindT.undefined

            % See if it is an override or extension
            for p : 1 .. nPatterns
                if string@(ident.idents (tokenPatterns (p).name)) = name then
                    % redefinition or extension of a predefined or previously defined token
                    if not extension then
                        newp := p
                    end if
                    kind := tokenPatterns (p).kind
                    exit
                end if
            end for
            
            % Possibly an override or extension of comments
            if name = "comment" then
                kind := kindT.comment
            end if

            % May need a new slot
            if newp = 0 then
                if nPatterns = maxTokenPatterns then
                    error ("", "Too many user-defined token patterns (>" 
                        + intstr (maxTokenPatterns, 1) + ")", LIMIT_FATAL, 178)
                end if

                nPatterns += 1
                newp := nPatterns
            end if
            
            % May need a new kind
            if kind = kindT. undefined then
                if nextUserTokenKind = lastUserTokenKind then
                    error ("", "Too many user-defined token kinds (>30)", LIMIT_FATAL, 179) 
                end if
                
                kind := nextUserTokenKind
                % Work around T+ succ bug
                nextUserTokenKind := type (kindT, (ord (nextUserTokenKind) + 1)) %% succ (nextUserTokenKind)
            end if

        #if UNICODE then
            % Automatically sequence any two-byte Unicodes
            var i := 1
            loop
                exit when i >= length (pattern)         % (sic)
                const pi : char := pattern (i)
                if ((pi >= UNICODEA and pi <= UNICODEN) or pi = UNICODEX) 
                        and (i = 1 or pattern (i - 1) not= "(" ) then
                    % Automatically convert to two-character sequence since we process input by byte
                    assert length (pattern) > i
                    pattern := pattern (1 .. i - 1) + "(" + pattern (i .. i + 1) + ")" + pattern (i + 2 .. *)
                    i += 4
                else
                    i += 1
                end if
            end loop
        #end if

            % Fill in the entry
            setTokenPattern (newp, kind, name, pattern)

            % If the new entry overrides [id], check that it is still valid
            if newp = idPattern and not extension then
                type (string, inputline) := "function "  % (sic)
                inputchar := 1

                const idscan := scanToken (tokenPatterns (idPattern).pattern, 1, tokenPatterns (idPattern).length_, false) 

                if not (idscan and inputchar = length ("function") + 1) then
                    error ("", "Token pattern for [id] does not allow TXL keywords", FATAL, 180)
                end if
            end if
        end loop

        expectend ("tokens")

        sortTokenPatterns
    end processTokenPatterns


    procedure tokenize (fileNameOrText : string, isFile, isTxlSource : boolean)

        % What are we tokenizing?
        fileInput := isFile         % true => an input file to open, false => a single string to scan (for [parse])
        txlSource := isTxlSource    % Scanning a TXL program itself?
        warnedLines := false

        % Initialize the default token patterns once
        if txlSource then
            defaultTokenPatterns
        end if
        
        % [pragma "-id"] may change the leading character maps
        if options.updatedChars then
            sortTokenPatterns
        end if
                
        % If newlines are tokens, they aren't white space
        if options.option (newline_p) and (not txlSource) then
            charset.addSpaceChar ('\n', false)
            charset.addSpaceChar ('\r', false)
        else
            % in case we're dynamically switching - JRC 10.5d
            charset.addSpaceChar ('\n', true)
            charset.addSpaceChar ('\r', true)
        end if

        % Open the file to scan and tokenize
        openFile (fileNameOrText)

        % Empty the array of scanned tokens 
        lastTokenIndex := 0

        % TXL programs and source files need to be scanned specially due to their multi-language nature
        const processingTxl : boolean := txlSource or options.option (txl_p)

        % Keep track of the token and previous token as we scan
        var token, previoustoken, rawtoken : tokenT := NOT_FOUND

        loop
            % Skip white space and comments 
            loop 
                skipSeparators
                exit when inputline (1) not= EOF

                % If we hit the end of an input file, check we're not crossing file boundaries
                synchronizePreprocessor

                % If we're at the end of an include file, time to continue the previous file
                exit when includeDepth = 0
                PopInclude
            end loop
            
            % We're done when we hit EOF on the main input file
            assert inputline (1) = EOF => includeDepth = 0
            exit when inputline (1) = EOF
            
            % Otherwise, there is more text left to scan
            var kind := kindT.undefined
            var startchar := inputchar

            % Keep track of the previous token, for context
            if previoustoken = quote_T then
                previoustoken := NOT_FOUND
            else
                previoustoken := token
            end if

            % To begin, we don't know what the next token is
            token := NOT_FOUND
            rawtoken := token

            % Step 1. See if it is a defined compound literal
            const litindex := compoundIndex (inputline (inputchar)) 
            
            if litindex not= 0 and 
                    % Make sure we don't mistake a TXL ... for a user token
                    (processingTxl =>   
                        ((inputline (inputchar) not= '.' or inputline (inputchar + 1) not= '.' 
                                or inputline (inputchar + 2) not= '.') 
                         or previoustoken = quote_T)) then

                if scanCompoundLiteral (litindex) then
                    % It is a compound literal token
                    kind := kindT.literal
                    token := ident.install (type (string, inputline) (startchar .. inputchar-1), kindT.literal)
                    rawtoken := token
                end if
            end if

            % Step 2. If not, see if it matches a token pattern
            if kind = kindT.undefined then
                assert inputchar = startchar

                % Handle quotes specially
                if processingTxl and inputline (inputchar) = '\'' and previoustoken not= quote_T then
                    % The first quote is always simply itself in TXL

                else
                    % Perhaps it is an id, number, string, or user tokentext 
                    var patindex := patternIndex (inputline (inputchar))

                    if patindex not= 0 then
                        loop
                            bind pp to tokenPatterns (patternLink (patindex))

                            if scanToken (pp.pattern, 1, pp.length_, false) then

                                % Aha!  Got one
                                kind := pp.kind
                                
                                % In TXL itself, user defined tokens must be quoted
                                if txlSource and ((kind >= firstUserTokenKind and previoustoken not= quote_T) 
                                        or pp.name = ignore_T) then

                                    % Back up, if we rejected an unquoted user token
                                    kind := kindT.undefined
                                    inputchar := startchar
                                    
                                else
                                    % Collect and classify the token's text
                                    var endchar := inputchar - 1
                                    
                                    % Fast in place substr to hash arbitrary length token text
                                    const oldchar := inputline (endchar + 1)
                                    inputline (endchar + 1) := EOS      % (hep!)
                                    
                                    % If working in case insensitive mode, need original raw text also
                                    if options.option (case_p) then
                                        rawtoken := ident.install (type (string, inputline (startchar)), kindT.id)
                                    end if
                                    
                                    % Normalize if lower, upper or case insensitive
                                    if (options.option (upper_p) or options.option (lower_p) or options.option (case_p)) 
                                            and (kind not= kindT.charlit and kind not= kindT.stringlit) 
                                            and not (txlSource and previoustoken not= quote_T) then
                                        if options.option (upper_p) then
                                            for i : startchar .. endchar
                                                inputline (i) := charset.uppercase (inputline (i))
                                            end for
                                        else
                                            assert options.option (lower_p) or options.option (case_p)
                                            for i : startchar .. endchar
                                                inputline (i) := charset.lowercase (inputline (i))
                                            end for
                                        end if
                                    end if
                                                                    
                                    token := ident.install (type (string, inputline (startchar)), kindT.id)
                                    
                                    % If not case insensitive, original = normalized
                                    if not options.option (case_p) then
                                        rawtoken := token
                                    end if

                                    % Undo fast in place substr to hash arbitrary length token text
                                    inputline (endchar + 1) := oldchar
    
                                    % If it is an id then it might be a keyword
                                    if processingTxl => previoustoken not= quote_T then
                                        if keyP (token) then
                                            kind := kindT.key
                                        end if
                                    end if
    
                                    exit
                                end if
                            end if

                            % Back up and try next possibility
                            assert inputchar = startchar
                            patindex += 1

                            exit when patternLink (patindex) = 0
                        end loop
                    end if
                end if
            end if

            % Step 3. If it isn't a compound and doesn't match any token pattern,
            % it must be a single character token
            if kind = kindT.undefined then
                assert inputchar = startchar
                kind := kindT.literal
                token := ident.install (type (string, inputline) (inputchar), kindT.literal)
                rawtoken := token
                if inputline (inputchar) = '\n' then
                    linenum += 1
                end if
                if inputline (inputchar) = '\r' then
                    if inputline (inputchar + 1) = '\n' then
                        inputchar += 1
                    end if
                    linenum += 1
                end if
                inputchar += 1
                
                % Warn if not expecting a quote token - JRC 21.8.07
                if inputline (startchar) = '"' or (inputline (startchar) = '\'' and not processingTxl) then
                    if options.option (verbose_p) and ((inputline (startchar) = '"' and chr (tokenPatterns (stringlitPattern).pattern (1)) = '"') or
                            (inputline (startchar) = '\'' and chr (tokenPatterns (charlitPattern).pattern (1)) = '\'')) then
                        error ("", "Unmatched opening quote accepted as literal token", WARNING, 168)
                    end if
                end if

                % Funny object language or TXL keyword 
                if keyP (token) then
                    % An artificial keyword
                    kind := kindT.key
                end if

                % If we are processing TXL, it might be a TXL special keyword
                if processingTxl then
                    if keyP (token) then
                        % A TXL artificial keyword
                        kind := kindT.key

                    elsif token = quote_T and inputline (inputchar) = '%' then
                        % A quoted TXL comment character - could be a compound
                        const pcindex := compoundIndex ('%')
                        const pcchar := inputchar
                        
                        if pcindex not= 0 and scanCompoundLiteral (pcindex) then
                            % Quoted compound literal 
                            kind := kindT.literal
                            token := ident.install (type (string, inputline) (pcchar .. inputchar-1), kindT.literal)
                            rawtoken := token
                        else
                            % Quoted TXL comment character
                            previoustoken := quote_T
                            token := ident.install ("%", kindT.literal)
                            rawtoken := token
                            startchar := inputchar    % remember beginning of % in case a user comment
                            inputchar += 1
                        end if

                    elsif token = underscore_T then
                        % TXL anonymous variable that the language doesn't think is an [id]
                        kind := kindT.id
                        
                    elsif token = dot_T and previoustoken not= quote_T
                            and inputline (inputchar) = '.' and inputline (inputchar + 1) = '.' then
                        % TXL special define extension marker '...'
                        token := dotDotDot_T
                        rawtoken := token
                        kind := kindT.key
                        inputchar += 2
                    end if

                    % If we are actually processing a TXL program,
                    % it might be a special TXL rule name
                    if txlSource and previoustoken = openbracket_T then
                        const tokenchar := inputline (startchar)
                        if (inputline (inputchar) = '=' and (tokenchar = '~' 
                                or tokenchar = '<' or tokenchar = '>'))
                            or (inputline (inputchar) = '/' and tokenchar = '\^') then
                            % ~=, <=, >= or ^/ rule call in TXL
                            inputchar += 1
                            token := ident.install (type (string, inputline) (startchar .. inputchar - 1), kindT.literal)
                            rawtoken := token
                        elsif tokenchar = '?' then
                            % A query rule call in TXL
                            skipSeparators
                            startchar := inputchar - 1
                            inputline (startchar) := '?'        % make sure the ? rule name has no spaces in it
                            if charset.alphaidP (inputline (inputchar)) then
                                loop
                                    exit when not charset.idP (inputline (inputchar))
                                    inputchar += 1
                                end loop
                                token := ident.install (type (string, inputline) (startchar .. inputchar - 1), kindT.id)
                                rawtoken := token
                                kind := kindT.id
                            end if
                        end if
                    end if
                end if
            end if

            % If this is a TXL program, we have to handle the special sections
            if txlSource then
                if kind = kindT.key and previoustoken not= quote_T then

                    if token = keys_T then
                        processKeywordTokens
                        kind := kindT.undefined

                    elsif token = compounds_T then
                        processCompoundTokens
                        kind := kindT.undefined

                    elsif token = comments_T then
                        processCommentBrackets
                        kind := kindT.undefined

                    elsif token = tokens_T then
                        processTokenPatterns
                        kind := kindT.undefined

                    elsif token = include_T then
                        PushInclude
                        kind := kindT.undefined
                    end if
                    
                elsif previoustoken = quote_T and (kind = kindT.literal or kind = kindT.key) then
                    % A quoted object language comment
                    const comindex := commentindex (token)

                    if comindex not= 0 then 
                        scanComment (startchar, comindex)
                        kind := kindT.undefined
                    end if
                end if

            else
                % Processing object source - check for user comment
                if (kind = kindT.literal or kind = kindT.key) and (not (previoustoken = quote_T and processingTxl)) then 
                    const comindex := commentindex (token)

                    if comindex not= 0 then 
                        scanComment (startchar, comindex)
                        kind := kindT.undefined
                    end if
                    
                elsif kind = kindT.comment then
                    % User pattern for comment
                    if not options.option (comment_token_p) then
                        kind := kindT.undefined
                    end if
                end if

            end if

            % If we still have something, add it to the database
            if kind not= kindT.undefined 
                    and kind not=kindT.empty then       % An ignored token - JRC 10.5e
                assert token not= NOT_FOUND
                % Add it to the token database
                installToken (kind, token, rawtoken)
            end if
        end loop

        % Keywords from the keys section need sorting for efficiency
        if txlSource then
            sortKeywords (nTxlKeys + 1)
        end if

        % End the token array with an empty token to mark end of file
        lastTokenIndex += 1
        bind var inputToken to inputTokens (lastTokenIndex)
        inputToken.token := empty_T
        inputToken.rawtoken := empty_T
        inputToken.kind := kindT.empty
        inputToken.linenum := filenum * maxLines + linenum

        % Close the input file
        closeFile

    end tokenize

end scanner
