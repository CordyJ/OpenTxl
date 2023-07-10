% OpenTxl Version 11 charset
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

% The character set tables.
% Define and initialize character class tables used by the input scanner and output printer.
% Rapid character classification using array subscripting is key to fast scanning of input.
% Output spacing tables determine the default spacing between output tokens based on character adjacency.

% Modification Log

% v11.0	Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%	Remodularized to improve maintainability

% v11.1	Added NBSP (ASCII 160) as space character and separator

% v11.2	Changed default ASCII Latin-1 alphabetics to remove â, Â and Ã, which conflict wiht UTF-8

module charset

    export 
    	% Character set properties and maps
	propertyT, mapT,
	% Scanner character classes
	digitP, alphaP, alphaidP, idP, upperP, upperidP, lowerP, loweridP, specialP, spaceP, uniformlyP, 
	addIdChar, addSpaceChar, 
	% TXL token pattern metacharacters
	repeaterP, optionalP, separatorP, metaP, magicP, 
	% Output spacing tables
	spaceBeforeP, spaceAfterP,
	% Upper/lower case maps
	uppercase, lowercase,
	% Stringlit/charlit escape characters
	stringlitEscapeChar, charlitEscapeChar, setEscapeChar,
	% XML encoding
	putXmlCode

    % Initialize character properties and maps
    type propertyT: array chr (0) .. chr (255) of boolean

    % Character classes for Extended ASCII (Latin-1)
    var digitP, alphaP, alphaidP, idP, upperP, upperidP, 
	lowerP, loweridP, specialP, repeaterP, optionalP, 
	separatorP, spaceP, metaP, magicP : propertyT

    % The false property, to initialize charset properties
    var falseP : propertyT
    for c : chr (0) .. chr (255)
	falseP (c) := false
    end for

    % Digits 
    digitP := falseP
    for d : '0' .. '9'
	digitP (d) := true
    end for

    % Upper case letters
    upperP := falseP
    % A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    for c : 'A' .. 'Z'
	upperP (c) := true
    end for
#if LATIN1 then
    % Have to fool T+, who thinks these are illegal characters
    var c1, cn : int
    % À Á Â Ã Ä Å Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö
    c1 := 192; cn := 214
    for c : chr (c1) .. chr (cn)
	upperP (c) := true
    end for
    #if UNICODE then
        % Latin-1 Â and Ã conflict with UTF-8
        upperP (chr (194)) := false
        upperP (chr (195)) := false
    #end if
    % Ø Ù Ú Û Ü Ý Þ
    c1 := 216; cn := 222
    for c : chr (c1) .. chr (cn)
	upperP (c) := true
    end for
    % Š, Œ, Ž, Ÿ
    c1 := 138; upperP (chr (c1)) := true
    c1 := 140; upperP (chr (c1)) := true
    c1 := 142; upperP (chr (c1)) := true
    c1 := 159; upperP (chr (c1)) := true
    % ß is both
    c1 := 223; upperP (chr (c1)) := true
#end if

    % Lower case letters
    lowerP := falseP
    % a b c d e f g h i j k l m n o p q r s t u v w x y z
    for c : 'a' .. 'z'
	lowerP (c) := true
    end for
#if LATIN1 then
    % à á â ã ä å æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö
    c1 := 224; cn := 246
    for c : chr (c1) .. chr (cn)
	lowerP (c) := true
    end for
    #if UNICODE then
        % Latin-1 â conflicts with UTF-8
        lowerP (chr (226)) := false
    #end if
    % ø ù ú û ü ý þ 
    c1 := 248; cn := 254
    for c : chr (c1) .. chr (cn)
	lowerP (c) := true
    end for
    % š, œ, ž, ÿ
    c1 := 154; lowerP (chr (c1)) := true
    c1 := 156; lowerP (chr (c1)) := true
    c1 := 158; lowerP (chr (c1)) := true
    c1 := 255; lowerP (chr (c1)) := true
    % ß is both
    c1 := 223; lowerP (chr (c1)) := true
#end if

    % Alphabetics = Upper case + Lower case
    alphaP := falseP
    for c : chr (0) .. chr (255)
	alphaP (c) := upperP (c) or lowerP (c)
    end for
    
    % Alphabetic identifiers = Alphabetics + underscore
    alphaidP := alphaP
    alphaidP ('_') := true
    
    % Identifiers = Alphabetic identifiers + Digits
    idP := falseP
    for c : chr (0) .. chr (255)
	idP (c) := alphaidP (c) or digitP (c)
    end for

    % Upper case identifiers = Upper case letters + Digits + underscore
    upperidP := falseP
    for c : chr (0) .. chr (255)
	upperidP (c) := upperP (c) or digitP (c)
    end for
    upperidP ('_') := true
    
    % Lower case identifiers = Lower case letters + Digits + underscore
    loweridP := falseP
    for c : chr (0) .. chr (255)
	loweridP (c) := lowerP (c) or digitP (c)
    end for
    loweridP ('_') := true
    
    % Special characters
    specialP := falseP
    % ! " # $ % & ' () * + , - .  /
    for c : '!' .. '/'
	specialP (c) := true
    end for
    % except quotes and parens
    specialP ('"') := false
    specialP ('\'') := false
    specialP ('(') := false
    specialP (')') := false
    % : ; < = > ?  @
    for c : ':' .. '@'
	specialP (c) := true
    end for
    % [ \ ] ^ _ `
    for c : '[' .. '`'
	specialP (c) := true
    end for
    % except brackets and backslash
    specialP ('[') := false
    specialP ('\\') := false
    specialP (']') := false
    % { | } ~
    for c : '{' .. '~'
	specialP (c) := true
    end for
#if LATIN1 then
    % € ‚ ƒ „ … † ‡ ˆ ‰ 
    c1 := 128; cn := 137
    for c : chr (c1) .. chr (cn)
	specialP (c) := true
    end for
    % ‹
    c1 := 139; specialP (chr (c1)) := true
    % ‘ ’ “ ” • – — ˜ ™ 
    c1 := 145; cn := 153
    for c : chr (c1) .. chr (cn)
	specialP (c) := true
    end for
    % ›
    c1 := 155; specialP (chr (c1)) := true
    % ¡ ¢ £ ¤ ¥ ¦ § ¨ © ª « ¬ ­ ® ¯ ° ± ² ³ ´ µ ¶ · ¸ ¹ º » ¼ ½ ¾ ¿
    c1 := 161; cn := 191
    for c : chr (c1) .. chr (cn)
	specialP (c) := true
    end for
    % ×
    c1 := 215; specialP (chr (c1)) := true
    % ÷
    c1 := 247; specialP (chr (c1)) := true
#end if

    % Separators
    separatorP := falseP
    separatorP (chr (0)) := true
    separatorP ('\t') := true
    separatorP ('\n') := true
    separatorP ('\f') := true
    separatorP ('\r') := true
    separatorP (' ') := true
#if LATIN1 then
    c1 := 160; separatorP (chr (c1)) := true
#end if
    
    % White space
    spaceP := falseP
    spaceP ('\t') := true
    spaceP ('\n') := true
    spaceP ('\f') := true
    spaceP ('\r') := true
    spaceP (' ') := true
#if LATIN1 then
    c1 := 160; spaceP (chr (c1)) := true
#end if
    

    % TXL token pattern metacharacters

    % TXL token pattern repeaters
    repeaterP := falseP
    repeaterP ('*') := true
    repeaterP ('+') := true
    
    % TXL token pattern optionals
    optionalP := falseP
    optionalP ('*') := true
    optionalP ('?') := true
    
    % TXL token pattern metacharacters
    metaP := falseP
    metaP ('#') := true
    metaP ('(') := true
    metaP (')') := true
    metaP ('*') := true
    metaP ('+') := true
    metaP ('?') := true
    metaP ('[') := true
    metaP ('\\') := true
    metaP (']') := true
    
    % TXL token pattern metacharacter magic codes
    magicP := falseP
    magicP (chr (0)) := true

    % TXL string and character literal quote escape characters
    % ' ' = none; '\\' = backslash; '\'' or '"' = ' for charlits, " for stringlits
    var stringlitEscapeChar : char := '\\'	% default \ to match default stringlit pattern
    var charlitEscapeChar : char := '\\'	% default \ to match default charlit pattern


    % TXL output spacing tables
    var spaceBeforeP, spaceAfterP : propertyT

    for c : chr (0) .. chr (255)
	spaceBeforeP (c) := true
	spaceAfterP (c) := true
    end for
    
    % By default, we always space before any token except those that begin with:
    spaceBeforeP ('\t') := false
    spaceBeforeP ('\n') := false
    spaceBeforeP ('\r') := false
    spaceBeforeP (' ') := false
    spaceBeforeP (')') := false
    spaceBeforeP (',') := false
    spaceBeforeP (';') := false
    spaceBeforeP ('.') := false
    spaceBeforeP (']') := false
    spaceBeforeP ('}') := false
#if LATIN1 then
    c1 := 160; spaceBeforeP (chr (c1)) := true
#end if
    
    % By default, we always space after any token except those that end with:
    spaceAfterP ('\t') := false
    spaceAfterP ('\n') := false
    spaceAfterP ('\r') := false
    spaceAfterP (' ') := false
    spaceAfterP ('(') := false
    spaceAfterP ('.') := false
    spaceAfterP ('[') := false
    spaceAfterP ('{') := false
#if LATIN1 then
    c1 := 160; spaceAfterP (chr (c1)) := true
#end if

    % Upper-to-lower and lower-to-upper case maps
    type mapT : array chr (0) .. chr (255) of char
    var uppercase, lowercase : mapT
    for i : chr (0) .. chr (255)
	uppercase (i) := i
	lowercase (i) := i
    end for
    % A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    for i : 'A' .. 'Z'
	lowercase (i) := chr (ord (i) - ord ('A') + ord ('a'))
    end for
    % a b c d e f g h i j k l m n o p q r s t u v w x y z
    for i : 'a' .. 'z'
	uppercase (i) := chr (ord (i) - ord ('a') + ord ('A'))
    end for

#if LATIN1 then
    % Have to fool T+, who thinks these are illegal characters
    var uc, lc : int
    % À Á Â Ã Ä Å Æ Ç È É Ê Ë Ì Í Î Ï Ð Ñ Ò Ó Ô Õ Ö
    % à á â ã ä å æ ç è é ê ë ì í î ï ð ñ ò ó ô õ ö
    uc := 192; lc := 224 
    c1 := uc; cn := 214
    for i : chr (c1) .. chr (cn)
	lowercase (i) := chr (ord (i) - uc + lc)
    end for
    c1 := lc; cn := 246
    for i : chr (c1) .. chr (cn)
	uppercase (i) := chr (ord (i) - lc + uc)
    end for
    % Ø Ù Ú Û Ü Ý Þ
    % ø ù ú û ü ý þ 
    uc := 216; lc := 248
    c1 := uc; cn := 222
    for i : chr (c1) .. chr (cn)
	lowercase (i) := chr (ord (i) - uc + lc)
    end for
    c1 := lc; cn := 254
    for i : chr (c1) .. chr (cn)
	uppercase (i) := chr (ord (i) - lc + uc)
    end for
    % Š š
    uc := 138; lc := 154
    lowercase (chr (uc)) := chr (lc)
    lowercase (chr (lc)) := chr (uc)
    % Œ œ
    uc := 140; lc := 156
    lowercase (chr (uc)) := chr (lc)
    lowercase (chr (lc)) := chr (uc)
    % Ž ž
    uc := 142; lc := 158
    lowercase (chr (uc)) := chr (lc)
    lowercase (chr (lc)) := chr (uc)
    % Ÿ ÿ
    uc := 159; lc := 255
    lowercase (chr (uc)) := chr (lc)
    lowercase (chr (lc)) := chr (uc)
#end if

    % Charset property test for entire strings

    function uniformlyP (tokenText : string, propertyP : propertyT) : boolean 
	for i : 1 .. length (tokenText)
	    var nextchar : char := tokenText (i)
	    if not propertyP (nextchar) then
		result false
	    end if
	end for
	result true
    end uniformlyP

    % Modify charset properties

    procedure addIdChar (c : char, setting : boolean)
	% Adding an identifier character affects several properties
	idP (c) := setting
	alphaidP (c) := setting
	upperidP (c) := setting
	loweridP (c) := setting
	spaceAfterP (c) := setting
    end addIdChar

    procedure addSpaceChar (c : char, setting : boolean)
	spaceP (c) := setting
    end addSpaceChar

    procedure setEscapeChar (c : char, setting : boolean)
	if setting then
	    stringlitEscapeChar := c
	    if stringlitEscapeChar = '\'' or stringlitEscapeChar = '"' then
	        stringlitEscapeChar := '"'
	        charlitEscapeChar := '\''
	    else
	        charlitEscapeChar := stringlitEscapeChar
	    end if
	else
	    stringlitEscapeChar := ' '
	    charlitEscapeChar := ' '
	end if
    end setEscapeChar

    % XML output encoding of special characters

    procedure putXmlCode (outstream : int, ls : string)
	for i : 1 .. length (ls)
	    var lsi := ls (i)
	    case ord (lsi) of
		label ord ('&'):
		    lsi := "&amp;"
		label ord ('<'):
		    lsi := "&lt;"
		label ord ('>'):
		    lsi := "&gt;"
		label ord ('"'):
		    lsi := "&quot;"
		label ord ('\''):
		    lsi := "&apos;"
		label:
	    end case
		
	    if outstream >= 0 then
		put : outstream, lsi ..
	    else 
		put lsi ..
	    end if
	end for
    end putXmlCode
end charset
