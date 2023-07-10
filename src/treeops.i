% OpenTxl Version 11 parse tree handling operations
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

% TXL parse tree handling operations

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston

module tree_ops

    import 
        var tree, var ident, error, emptyTP, charset, kindType, stackBase

    export 
        % List and repeat deconstructors - used in compiler, transformer and predefineds
        isListOrRepeat, lengthListOrRepeat, isEmptyListOrRepeat, listOrRepeatFirstTP, 
        listOrRepeatRestTP, isListOrRepeatType, listOrRepeatBaseType, 

        % Tree type matchers - used in compiler, transformer and predefineds
        treeIsTypeP, literalTypeName


    % List and repeat deconstructors - used in compiler, transformer and predefineds

    function isListOrRepeat (listOrRepeatTP : treePT) : boolean
        % Is the tree node a [list X] or [repeat X] ?
        bind name to string@(ident.idents (tree.trees (listOrRepeatTP).name))
        if type (char, name) = 'r' then
            result type (char (7), name) = 'repeat_' 
        elsif type (char, name) = 'l' then
            result type (char (5), name) = 'list_'
        else
            result false
        end if
    end isListOrRepeat

    function lengthListOrRepeat (listOrRepeatTP : treePT) : int
        % Return the number of elements in a [list X] or [repeat X] 
        pre isListOrRepeat (listOrRepeatTP)

        bind name to type (char (8), string@(ident.idents (tree.trees (listOrRepeatTP).name)))

        if tree.trees (tree.kids (tree.trees (listOrRepeatTP).kidsKP)).kind = kindT.empty then
            result 0
        else
            var repeatCount := 1
            var runTP : treePT

            if name (8) = '1' then
                runTP := tree.kid2TP (listOrRepeatTP)
            else
                runTP := tree.kid2TP (tree.kids (tree.trees (listOrRepeatTP).kidsKP))
            end if

            loop
                exit when tree.plural_emptyP (runTP)
                repeatCount += 1
                runTP := tree.plural_restTP (runTP)
            end loop

            result repeatCount
        end if
    end lengthListOrRepeat

    function isEmptyListOrRepeat (listOrRepeatTP : treePT) : boolean
        pre isListOrRepeat (listOrRepeatTP)
        result tree.trees (tree.kids (tree.trees (listOrRepeatTP).kidsKP)).kind = kindT.empty
    end isEmptyListOrRepeat

    function listOrRepeatFirstTP (listOrRepeatTP : treePT) : treePT
        pre isListOrRepeat (listOrRepeatTP)
        result tree.kid1TP (listOrRepeatTP)
    end listOrRepeatFirstTP

    function listOrRepeatRestTP (listOrRepeatTP : treePT) : treePT
        pre isListOrRepeat (listOrRepeatTP)
        % repeat_?_X
        result tree.kid2TP (listOrRepeatTP)
    end listOrRepeatRestTP

    function isListOrRepeatType (listOrRepeatType : tokenT) : boolean
        bind name to string@(ident.idents (listOrRepeatType))
        if type (char, name) = 'r' then
            result type (char (7), name) = 'repeat_' 
        elsif type (char, name) = 'l' then
            result type (char (5), name) = 'list_'
        else
            result false
        end if
    end isListOrRepeatType 

    function listOrRepeatBaseType (listOrRepeatType: tokenT) : tokenT
        pre isListOrRepeatType (listOrRepeatType)

        var typeName := string@(ident.idents (listOrRepeatType))
        const tname : char (8) := typeName (1 .. 8)

        if tname (1) = 'l' then
            % list_?_X
            typeName := typeName (8 .. *)
        else
            assert tname (1) = 'r'
            % repeat_?_X
            typeName := typeName (10 .. *)
        end if

        const identIndex := ident.install (typeName, kindT.id)

        result identIndex
    end listOrRepeatBaseType

    % Tree type matchers - used in compiler, transformer and predefineds

    function treeIsTypeP (treeP : treePT, typeT : tokenT) : boolean
        % used only in matching variables (typeT) to patterns (treeP) when parsing patterns
        if tree.trees (treeP).kind not= kindT.literal 
                and (tree.trees (treeP).name = typeT or typeT = any_T or kindType (ord (tree.trees (treeP).kind)) = typeT) then
            result true
        elsif tree.trees (treeP).kind = kindT.repeat or tree.trees (treeP).kind = kindT.generaterepeat then
            % Type cheat - valid only because the identText table has a cheat buffer zone on the end
            type char7 : char (7)
            type char8 : char (8)
            result char7@(ident.idents (typeT)) = 'repeat_' and 
                % Watch out for this type cheat ... really implementing a tail substring
                string@(ident.idents (tree.trees (treeP).name) + 10) = string@(ident.idents (typeT) + 10)
                    and (char8@(ident.idents (typeT)) (8) = '1' => tree.trees (tree.kid1TP (treeP)).kind not= kindT.empty)
        elsif tree.trees (treeP).kind = kindT.list or tree.trees (treeP).kind = kindT.generatelist then
            % Type cheat - valid only because the identText table has a cheat buffer zone on the end
            type char5 : char (5)
            type char6 : char (6)
            result char5@(ident.idents (typeT)) = 'list_' and 
                % Watch out for this type cheat ... really implementing a tail substring
                string@(ident.idents (tree.trees (treeP).name) + 8) = string@(ident.idents (typeT) + 8)
                    and (char6@(ident.idents (typeT)) (6) = '1' => tree.trees (tree.kid1TP (treeP)).kind not= kindT.empty)
        end if
        result false
    end treeIsTypeP

    function literalTypeName (kind : kindT) : tokenT
        % used in compiling rules and external function [parse]
        result kindType (ord (kind))
    end literalTypeName

end tree_ops
