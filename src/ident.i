% OpenTxl Version 11 identifier/token table
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

% The identifier table
% Define and maintain the hash table for identifiers and other tokens.
% Although it's called the identifier table, all tokens are now hashed into this table.

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Modularized for easier maintenance and understanding 

module ident

    import error, var tree

    export idents, identKind, identTree, nIdents, nilIdent, 
        identText, nIdentChars, install, lookup, setKind

    const * nilIdent := 0       % we use the hash code for ASCII NUL (chr(0)) as the nil identifier

    % The identifier hash table - index is the hash code, entry is the address of the text in identText
    var idents : array 0 .. maxIdents - 1 of addressint
    % Symbol kind of the identifier
    var identKind : array 0 .. maxIdents - 1 of kindT
    % Shared tree optimization - all instances of an identifier share one tree node
    var identTree : array 0 .. maxIdents - 1 of treePT
    var nIdents := 0

    % The text of identifiers in the hash table, stored as consecutive strings 
    var identText : array 1 .. maxIdentChars + maxTuringStringLength + 1 of char
    var nIdentChars := 1

    % Initialize the table
    for i : 0 .. maxIdents - 1
        idents (i) := nilIdent
        identKind (i) := kindT.literal          % will be set by scanner when actually used
        identTree (i) := nilTree
    end for
    
    type (string,identText (1)) := " "          % need one character here as placeholder
    nIdentChars += 2

    idents (0) := addr (identText (2))  % ident 0 is the null token, with no characters in it
    identKind (0) := kindT.literal
    identTree (0) := nilTree
    nIdents := 1

    % New superfast hash function
    
    function hash (s : string) : nat
        type nat32768 : array 0 .. 32767 of nat1
        var register h : nat := length (s)
        var register j := h - 1
        if h > 0 then
            for i : 0 .. h shr 1
                h += h shl 1 + type (nat32768, s) (i)
                h += h shl 1 + type (nat32768, s) (j)
                j -= 1
            end for
        end if
        result h
    end hash
    
    % Choose an appropriate secondary hash - critical to performance!
    % By choosing the largest prime modulo table size, we are certain to hit every table element
    
    var secondaryHash := 11
    
    const nprimes := 10
    const primes : array 1 .. nprimes of int := 
        init (1021, 2027, 4091, 8191, 16381, 32003, 65003, 131009, 262007, 524047)

    for i : 1 .. nprimes
        exit when primes (i) > maxIdents
        secondaryHash := primes (i)
    end for
    
    % Look up an identifier in the identifier table and return its index.
    % Begin with the hash of the identifier, then add the secondary hash modulo table size until we find it 

    function lookup (ident : string) : tokenT
        % Begin with the hash, modulo table size
        var register identIndex : nat := hash (ident)
        identIndex and= maxIdents - 1
        const startIndex : nat := identIndex
    
        loop
            % If we hit the nil identifier, it isn't there
            if idents (identIndex) = nilIdent then
                result NOT_FOUND
            end if
    
            % Is this one it?
            exit when string@(idents (identIndex)) = ident
    
            % Nope, try the sedcondary hash
            identIndex += secondaryHash
            identIndex and= maxIdents - 1
    
            % If we've searched the whole table, it isn't in there
            if identIndex = startIndex then
                result NOT_FOUND
            end if
        end loop
    
        result identIndex
    end lookup

    % Install an identifier in the identifier table and return its index.
    % Begin with the hash of the identifier, then add the secondary hash modulo table size until we find it
    % or find an empty slot to put it in 

    function install (ident : string, kind : kindT) : tokenT
        % Begin with the hash, modulo table size
        var register identIndex : nat := hash (ident)
        identIndex and= maxIdents - 1
        const startIndex : nat := identIndex

        loop
            % Is this an empty slot? If so, install it here
            if idents (identIndex) = nilIdent then
                % Check for room to store its text
                const lengthid := length (ident)
                if nIdentChars + lengthid + 1 > maxIdentChars then
                    error ("", "Input too large (total text of unique tokens > " 
                        + intstr (maxIdentChars, 0) + " chars)"
                        + " (a larger size is required for this input)", LIMIT_FATAL, 101)
                end if

                % OK, store it
                type (string, identText (nIdentChars)) := ident
                idents (identIndex) := addr (identText (nIdentChars))
                identKind (identIndex) := kind          % default - may be changed
                nIdentChars += lengthid + 1
                nIdents += 1
                exit
            end if

            % If this one's it, then it's already in the table (or we just installed it above)
            exit when string@(idents (identIndex)) = ident
            
            % Use the secondary hash to try the next slot
            identIndex += secondaryHash
            identIndex and= maxIdents - 1
            
            % If we don't find it or an empty slot for it, then we're out of table space
            if identIndex = startIndex then
                error ("", "Input too large (total number of unique tokens > " 
                    + intstr (maxIdents, 0) + ")"
                    + " (a larger size is required for this input)", LIMIT_FATAL, 102)
            end if
        end loop

        % Shared tree optimization - we use the same tree node for every instance of the same identifier
        if identTree (identIndex) = nilTree then
            identTree (identIndex) := tree.newTreeInit (kind, identIndex, identIndex, 0, nilKid)
        end if

        result identIndex
    end install
    
    % We may discover that an identifier is of a different token kind later
    
    procedure setKind (indentIndex : tokenT, kind : kindT)
        identKind (indentIndex) := kind
        % Shared tree optimization - if the identifier is of a token kind, 
        % all instances of it are of the same kind
        assert identTree (indentIndex) not= nilTree
        tree.setKind (identTree (indentIndex), kind)
    end setKind

end ident
