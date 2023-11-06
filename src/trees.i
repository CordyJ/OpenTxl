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

% The TXL tree module
% Defines and maintains the parse tree structures used to represent grammar trees, 
% parse trees, rule pattern trees and rule replacement trees.  

% Modification Log

% v11.0 Initial revision, revised from FreeTXL 10.8b (c) 1988-2022 Queen's University at Kingston
%       Modularized for easier maintenance and understanding 

% v11.2 Added shallow extract [^/]


% Trees are structured as tree nodes and kids, in the traditional Lisp cons() fashion

% I.E., the tree:         Is represented as:
%
%             X                 X--+-------------+
%            / \                   |             |
%           Y   Z                  Y--+--+--+    Z
%          /|\                        |  |  |
%         / | \                       A  B  C--+--+
%        A  B  C                               |  |
%             / \                              D  E
%            D   E

% where each label is a tree node, and each tree has a sequential list of kids (+'s) 
% linking to the child tree nodes of the tree.

% Kinds of trees in TXL - defined in tokens.i
% type * kindT :
%    packed enum (
%       % structuring trees
%           order, choose, repeat, list,
%       % structure generator trees
%           leftchoose, generaterepeat, generatelist, lookahead, push, pop,
%       % the empty tree
%           empty, 
%       % leaf trees 
%           literal, stringlit, charlit, token, id, upperlowerid, upperid, 
%           lowerupperid, lowerid, number, floatnumber, decimalnumber, 
%           integernumber, comment, key, space, newline, srclinenumber, srcfilename,
%       % user specified leaves
%           usertoken1, usertoken2, usertoken3, usertoken4, usertoken5, 
%           usertoken6, usertoken7, usertoken8, usertoken9, usertoken10,
%           usertoken11, usertoken12, usertoken13, usertoken14, usertoken15, 
%           usertoken16, usertoken17, usertoken18, usertoken19, usertoken20,
%           usertoken21, usertoken22, usertoken23, usertoken24, usertoken25, 
%           usertoken26, usertoken27, usertoken28, usertoken29, usertoken30,
%       % special trees 
%           firstTime, subsequentUse, expression, lastExpression, ruleCall, 
%           undefined)

% Tree nodes and kids are represented by their integer indices in the trees() and kids() arrays respectively
% type * treePT : int           % defined in tokens.i   
type * kidPT : int

% Null tree and kid indices
const * nilTree := 0
const * nilKid := 0

% The shared empty tree
var tree_emptyTP : treePT       % initialized by shared.i

% Tree availability flag for use in garbage collection - any positive number not in the legal range
const * AVAILABLE := 999999999
const * NILMARK := - AVAILABLE
assert AVAILABLE > maxTrees and AVAILABLE > maxKids

% Current tree node and kid allocation strategy - two are implemented:
%       simple =   sequential allocation in the trees() and kids() arrays, haven't run out yet
%       scavenge = have run out and done a garbage collection, so search for first fit
const * simple := 0
const * scavenge := 1

% Error message construction outside of procedures, to avoid using stack space
const * outOfTreesMessage := "Out of tree space - " + intstr (maxTrees, 1) + " trees have been allocated."
const * outOfKidsMessage := "Out of kid space - " + intstr (maxKids, 1) + " kids have been allocated."

% Number of children of a tree node
type * countT : nat2            %  0 .. maxDefineKids

% Used in grammar analysis
type * derivesT : packed enum (yes, no, dontknow)

% Tree node type
type * parseTreeT :
    record
        % order of these fields matters, to minimize node size
        kind : kindT
    #if not NOCOMPILE then
        derivesEmpty : derivesT % used only in grammar analysis (compdef-analyze.i)
    #end if
        count : countT          % how many children, or number of choice alternative
        name : tokenT           % normalized name or literal value
        rawname : tokenT        % original name or literal value
        kidsKP : kidPT          % list of children, or 'each' indicator
    end record

module tree

    import
        options, error, stackBase, kindType, tree_emptyTP

    export
        allocationStrategy, trees, kids, treeCount, kidCount, 
        newTree, newTreeClone, newTreeInit, cloneTree, setKind, setName, setRawName, setKids, setCount, 
        newKid, newKids, setKidTree,
        beginUserTreeSpace, firstUserTree, firstUserKid,

        % For garbage collector only
        setTreeCount, setKidCount, setAllocationStrategy,

    #if not NOCOMPILE then
        % For grammar analyzer only
        setDerivesEmpty,
    #end if

        % General tree operations - used everywhere
        makeOneKid, makeTwoKids, makeThreeKids, makeFourKids, makeFiveKids, 
        kidTP, kid1TP, kid2TP, kid3TP, kid4TP, kid5TP, kid6TP, kid7TP,
        plural_emptyP, plural_firstTP, plural_restTP,

        % Fast whole tree operations - used in transformer and predefineds   
        sameTrees, copyTree, extract, substitute, substituteLiteral

    #if CHECKED then
        % Performance of TXL is critically limited by the size of parse tree nodes.
        % In order to avoid multiple memory fetches per node, the size should be exactly
        % (or factor of 2 of) the aligned width of the memory interace of the computer,
        % typically 16 bytes in a modern machine. 
        assert size (parseTreeT) = 16   % bytes
    #end if

    var kids : array 0..maxKids of treePT
    var trees : array 0..maxTrees of parseTreeT

    % initialize trees so that we can tell if they are permanent
    % (this is unnecessary in modern systems that pre-initialize static memory to 0)
    %% for it : 1 .. maxTrees
    %%     trees (it).kind := kindT.empty
    %% end for

    var treeCount, maxTreeCount := 0
    var kidCount := 0

    % current allocation strategy
    % two are implemented - 
    %   simple = haven't run out yet, so linearly use unused cells
    %   scavenge = have done a garbage collection, so search for first fit
    var allocationStrategy := simple

    % Garbage collector needs to be able to set these
    procedure setTreeCount (count : int)
        treeCount := count
    end setTreeCount 

    procedure setKidCount (count : int)
        kidCount := count
    end setKidCount 

    procedure setAllocationStrategy (strategy : int)
        allocationStrategy := strategy
    end setAllocationStrategy

    % next free tree/kid search starting point (when scavenging)
    var lookTree := 0
    var lookKid := 0

    % Tree allocation routines -
    % For speed, we simply linearly eat space without ever freeing anything!
    % Until our new alternative garbage scavenging kicks in ...

    function newTree : treePT
        var nt := nilTree

        if allocationStrategy = simple then
            % Haven't yet done a garbage collection, using simple linear allocation
            loop
                if treeCount = maxTrees then
                    % Ran out - cause a garbage collection
                    if not options.option (quiet_p) then
                        error ("", outOfTreesMessage, DEFERRED, 981)
                    end if
                    quit : outOfTrees
                end if

                treeCount += 1
                
                exit when treeCount > maxTreeCount 
                    or trees (treeCount).kind < firstLiteralKind
            end loop

            nt := treeCount

            if treeCount > maxTreeCount then
                maxTreeCount := treeCount
            end if

        else
            % Done a garbage collection, using first fit search allocation
            var lt, startLook := lookTree
            loop
                lt += 1

                if lt > maxTrees then
                    lt := 1
                end if

                if trees (lt).kidsKP = AVAILABLE then
                    nt := lt
                    treeCount += 1
                    lookTree := lt
                    exit
                end if

                exit when lt = startLook
            end loop

            if nt = nilTree then
                % Ran out - cause a garbage collection
                if not options.option (quiet_p) then
                    error ("", outOfTreesMessage, DEFERRED, 981)
                end if
                quit : outOfTrees
            end if
        end if

        % Found an available one
        assert nt not= nilTree
        trees (nt).kidsKP := nilKid

        result nt
    end newTree

    procedure cloneTree (nt : treePT, ot : treePT)
        trees (nt) := trees (ot)
    end cloneTree

    function newTreeClone (ot : treePT) : treePT
        var nt := newTree 
        trees (nt) := trees (ot)
        result nt
    end newTreeClone

    function newTreeInit (kind : kindT, name : tokenT, rawname : tokenT, 
            count : countT, kidsKP : kidPT) : treePT
        var nt := newTree 
        trees (nt).kind := kind
        trees (nt).name := name
        trees (nt).rawname := rawname
        trees (nt).count := count
        trees (nt).kidsKP := kidsKP
        result nt
    end newTreeInit

    procedure setKind (t : treePT, kind : kindT)
        trees (t).kind := kind
    end setKind

    procedure setName (t : treePT, name : tokenT)
        trees (t).name := name
    end setName

    procedure setRawName (t : treePT, rawname : tokenT)
        trees (t).rawname := rawname
    end setRawName

    procedure setKids (t : treePT, kidsKP : kidPT) 
        trees (t).kidsKP := kidsKP
    end setKids

    procedure setCount (t : treePT, count : countT) 
        trees (t).count := count
    end setCount

    #if not NOCOMPILE then
        % Used only in grammar analysis
        procedure setDerivesEmpty (t : treePT, setting : derivesT)
            trees (t).derivesEmpty := setting
        end setDerivesEmpty
    #end if

    function newKid : kidPT
        var nk := nilKid

        if allocationStrategy = simple then
            % Haven't yet done a garbage collection, using simple linear allocation

            if kidCount = maxKids then
                % Ran out - cause a garbage collection
                if not options.option (quiet_p) then
                    error ("", outOfKidsMessage, DEFERRED, 984)
                end if
                quit : outOfKids
            end if

            kidCount += 1
            nk := kidCount

        else
            % Done a garbage collection, using first fit search allocation
            var lk, startLook := lookKid
            loop
                lk += 1

                if lk > maxKids then
                    lk := 1
                end if

                if kids (lk) = AVAILABLE then
                    nk := lk
                    kidCount += 1
                    lookKid := lk
                    exit
                end if

                exit when lk = startLook
            end loop

            if nk = nilKid then
                % Ran out - cause a garbage collection
                if not options.option (quiet_p) then
                    error ("", outOfKidsMessage, DEFERRED, 984)
                end if
                quit : outOfKids
            end if
        end if

        % Found an available one
        assert nk not= nilKid
        kids (nk) := nilTree

        result nk
    end newKid

    function newKids (count : int) : kidPT
        var nk := nilKid

        if allocationStrategy = simple then
            % Haven't yet done a garbage collection, using simple linear allocation

            if kidCount + count > maxKids then
                % Ran out - cause a garbage collection
                if not options.option (quiet_p) then
                    error ("", outOfKidsMessage, DEFERRED, 984)
                end if
                quit : outOfKids
            end if

            nk := kidCount + 1
            kidCount += count

        else
            % Done a garbage collection, using first fit search allocation
            var lk, startLook := lookKid
            loop
                lk += 1

                if lk + count - 1 > maxKids then
                    exit when startLook >= lk
                    lk := 1
                end if

                if kids (lk) = AVAILABLE then

                    if count = 1 then
                        nk := lk
                        kidCount += 1
                        lookKid := lk
                        exit

                    elsif count = 2 then
                        % Avoid loop overhead
                        if kids (lk + 1) = AVAILABLE then
                            nk := lk
                            kidCount += 2
                            lk += 1
                            lookKid := lk
                            exit
                        else
                            lk += 1
                        end if

                    else
                        const lkend := lk + count - 1
                        var lkn := lk + 1
                        loop
                            if kids (lkn) not= AVAILABLE then
                                lk := lkn
                                exit
                            end if
                            
                            if lkn = lkend then
                                nk := lk
                                kidCount += count
                                lookKid := lkend
                                exit
                            end if
                            
                            lkn += 1
                        end loop
                    end if
                end if

                exit when nk not= nilKid or lk = startLook
            end loop

            if nk = nilKid then
                % Ran out - cause a garbage collection
                if not options.option (quiet_p) then
                    error ("", outOfKidsMessage, DEFERRED, 984)
                end if
                quit : outOfKids
            end if
        end if

        % Found an available set
        assert nk not= nilKid 
        for k : nk .. nk + count - 1
            kids (k) := nilTree
        end for

        result nk
    end newKids

    procedure setKidTree (k : kidPT, t : treePT)
        kids (k) := t
    end setKidTree

    % When storing a compiled TXL program, we can throw away trees previously used in 
    % the TXL bootstrap and program compile, since they won't be used again.

    % Used only by the compiled program Load/Store facilty to compress the tree space.
    var firstUserTree, firstUserKid := 0

    procedure beginUserTreeSpace
        firstUserTree := treeCount
        firstUserKid := kidCount
    end beginUserTreeSpace

    % General tree operations

    % Fast whole tree operations - used in transformer and predefineds   

    function sameTrees (tree1TP, tree2TP : treePT) : boolean

        % Stack use limitation - to avoid crashes
        var dummy : int
        if stackBase - addr (dummy) > maxStackUse then 
            quit : stackLimitReached
        end if

        case trees (tree1TP).kind of
            label kindT.empty :
                result trees (tree2TP).kind = kindT.empty

            label kindT.choose :
                result trees (tree1TP).name = trees (tree2TP).name and
                        trees (tree1TP).kind = trees (tree2TP).kind and
                        sameTrees (kids (trees (tree1TP).kidsKP), kids (trees (tree2TP).kidsKP))

            label kindT.order, kindT.repeat, kindT.list :
                if trees (tree1TP).name = trees (tree2TP).name and
                        trees (tree1TP).kind = trees (tree2TP).kind then
                    var tree1KidsKP := trees (tree1TP).kidsKP
                    var tree2KidsKP := trees (tree2TP).kidsKP
                    assert trees (tree1TP).count = trees (tree2TP).count
                    for k : 1 .. trees (tree1TP).count
                        if not sameTrees (kids (tree1KidsKP), kids (tree2KidsKP)) then
                            result false
                        end if

                        tree1KidsKP += 1
                        tree2KidsKP += 1
                    end for

                    result true

                else
                    result false
                end if

            label:
                result trees (tree1TP).kind = trees (tree2TP).kind and
                    trees (tree1TP).name = trees (tree2TP).name
        end case
    end sameTrees

    procedure real_copyTree (originalTP : treePT, var copyTP : treePT)
        pre originalTP not= nilTree
            and originalTP >= 0 and originalTP <= maxTrees

        % Stack use limitation - to avoid crashes
        if stackBase - addr (originalTP) > maxStackUse then 
            quit : stackLimitReached
        end if

        % optimize by sharing all literals 
        case trees (originalTP).kind of

            label
                % These are always ok.
                    kindT.empty, kindT.literal, kindT.key, kindT.token,
                    kindT.stringlit, kindT.charlit, kindT.number, kindT.floatnumber, 
                    kindT.decimalnumber, kindT.integernumber,
                    kindT.id, kindT.upperlowerid, kindT.upperid,
                    kindT.lowerupperid, kindT.lowerid, kindT.comment, kindT.space, kindT.newline,
                    kindT.srclinenumber, kindT.srcfilename,
                    kindT.usertoken1, kindT.usertoken2, kindT.usertoken3, kindT.usertoken4, kindT.usertoken5, 
                    kindT.usertoken6, kindT.usertoken7, kindT.usertoken8, kindT.usertoken9, kindT.usertoken10,
                    kindT.usertoken11, kindT.usertoken12, kindT.usertoken13, kindT.usertoken14, kindT.usertoken15, 
                    kindT.usertoken16, kindT.usertoken17, kindT.usertoken18, kindT.usertoken19, kindT.usertoken20,
                    kindT.usertoken21, kindT.usertoken22, kindT.usertoken23, kindT.usertoken24, kindT.usertoken25, 
                    kindT.usertoken26, kindT.usertoken27, kindT.usertoken28, kindT.usertoken29, kindT.usertoken30,
                % These depend on the fact that the transformer
                % does not actually change the original tree values 
                % when matching patterns.
                    kindT.firstTime, kindT.subsequentUse,
                % These depend on the fact that the transformer
                % does not actually substitute anything into a rule call
                % subtree when implementing the call.
                    kindT.expression, kindT.lastExpression, kindT.ruleCall :
                copyTP := originalTP

            label kindT.choose, kindT.leftchoose :
                % Cannot be blindly shared, and always has a child
                copyTP := newTreeClone (originalTP) 
                trees (copyTP).kidsKP := newKid
                real_copyTree (kids (trees (originalTP).kidsKP), kids (trees (copyTP).kidsKP))

            label kindT.order, kindT.repeat, kindT.list :
                % Cannot be blindly shared, and always has children
                copyTP := newTreeClone (originalTP)
                
                % pre-reserve the kid kids to keep them contiguous 
                var copyKidsKP := newKids (trees (originalTP).count)
                trees (copyTP).kidsKP := copyKidsKP
                
                % now copy the kids over
                var originalKidsKP := trees (originalTP).kidsKP 
                for k : 1 .. trees (originalTP).count
                    real_copyTree (kids (originalKidsKP), kids (copyKidsKP))
                    originalKidsKP += 1
                    copyKidsKP += 1
                end for
                
                #if PARANOID then
                    assert sameTrees (originalTP, copyTP)
                #end if

            label :
                error ("", "Fatal TXL error in copyTree", INTERNAL_FATAL, 971)
        end case

    end real_copyTree
    
    procedure copyTree (originalTP : treePT, var copyTP : treePT)
        pre originalTP not= nilTree

        % The following logic forces the copy to be done to a temporary, 
        % without destroying the original target tree until the copy is completely successfully done.
        % This makes copyTree an atomic operation, which is necessary for garbage collection.
        
        var atomicCopyTP : treePT := nilTree
        real_copyTree (originalTP, atomicCopyTP)
        copyTP := atomicCopyTP
        
    end copyTree

    % General tree operations - used everywhere
    function kidTP (which : nat, parentTP : treePT) : treePT
        pre which >= 1
        result kids (trees (parentTP).kidsKP + which - 1)
    end kidTP

    function kid1TP (treeP : treePT) : treePT
        result kids (trees (treeP).kidsKP)
    end kid1TP

    function kid2TP (treeP : treePT) : treePT
        result kids (trees (treeP).kidsKP + 1)
    end kid2TP

    function kid3TP (treeP : treePT) : treePT
        result kids (trees (treeP).kidsKP + 2)
    end kid3TP

    function kid4TP (treeP : treePT) : treePT
        result kids (trees (treeP).kidsKP + 3)
    end kid4TP

    function kid5TP (treeP : treePT) : treePT
        result kids (trees (treeP).kidsKP + 4)
    end kid5TP

    function kid6TP (treeP : treePT) : treePT
        result kids (trees (treeP).kidsKP + 5)
    end kid6TP

    function kid7TP (treeP : treePT) : treePT
        result kids (trees (treeP).kidsKP + 6)
    end kid7TP

    procedure makeOneKid (parentTP : treePT, babyTP : treePT)
        trees (parentTP).kidsKP := newKid
        kids (trees (parentTP).kidsKP) := babyTP
        trees (parentTP).count := 1
    end makeOneKid

    procedure makeTwoKids (parentTP : treePT, buddyTP : treePT, sisTP : treePT)
        trees (parentTP).kidsKP := newKids (2)
        trees (parentTP).count := 2
        kids (trees (parentTP).kidsKP) := buddyTP
        kids (trees (parentTP).kidsKP + 1) := sisTP
    end makeTwoKids

    procedure makeThreeKids (parentTP : treePT, kid1TP : treePT, kid2TP : treePT, kid3TP : treePT)
        trees (parentTP).kidsKP := newKids (3)
        trees (parentTP).count := 3
        kids (trees (parentTP).kidsKP) := kid1TP
        kids (trees (parentTP).kidsKP + 1) := kid2TP
        kids (trees (parentTP).kidsKP + 2) := kid3TP
    end makeThreeKids

    procedure makeFourKids (parentTP : treePT, kid1TP : treePT, kid2TP : treePT, kid3TP : treePT, kid4TP : treePT)
        trees (parentTP).kidsKP := newKids (4)
        trees (parentTP).count := 4
        kids (trees (parentTP).kidsKP) := kid1TP
        kids (trees (parentTP).kidsKP + 1) := kid2TP
        kids (trees (parentTP).kidsKP + 2) := kid3TP
        kids (trees (parentTP).kidsKP + 3) := kid4TP
    end makeFourKids

    procedure makeFiveKids (parentTP : treePT, kid1TP : treePT, kid2TP : treePT, kid3TP : treePT, kid4TP : treePT, kid5TP : treePT)
        trees (parentTP).kidsKP := newKids (5)
        trees (parentTP).count := 5
        kids (trees (parentTP).kidsKP) := kid1TP
        kids (trees (parentTP).kidsKP + 1) := kid2TP
        kids (trees (parentTP).kidsKP + 2) := kid3TP
        kids (trees (parentTP).kidsKP + 3) := kid4TP
        kids (trees (parentTP).kidsKP + 4) := kid5TP
    end makeFiveKids

    function plural_emptyP (pluralTP : treePT) : boolean
        result trees (kids (trees (pluralTP).kidsKP)).kind = kindT.empty
    end plural_emptyP

    function plural_firstTP (pluralTP : treePT) : treePT
        result kids (trees (kids (trees (pluralTP).kidsKP)).kidsKP)
    end plural_firstTP

    function plural_restTP (pluralTP : treePT) : treePT
        result kids (trees (kids (trees (pluralTP).kidsKP)).kidsKP + 1)
    end plural_restTP

    var extract_XT, extract_repeatXT : tokenT

    procedure real_extract (scopeTP : treePT, mustCopy : boolean, recursive : boolean, var resultRepeatTP : treePT)

        % Stack use limitation - to avoid crashes
        if stackBase - addr (scopeTP) > maxStackUse then 
            quit : stackLimitReached
        end if
        
        % extract all the occurences of things of type [X]
        % from the scope and append them to a result [repeat X].
        var nextResultRepeatTP : treePT := resultRepeatTP
        var mustCopyKids := mustCopy

        if (trees (scopeTP).name = extract_XT 
                        and trees (scopeTP).kind < kindT.empty)         % don't mistake token for type - JRC 10.4c
                or kindType (ord (trees (scopeTP).kind)) = extract_XT   % unless that's what we're looking for
            then
            % append onto the end of the result so far
            var repeatTP := newTreeInit (kindT.repeat, extract_repeatXT, extract_repeatXT, 2, trees (resultRepeatTP).kidsKP)    % re-use empty kids

            % we must copy the extracted tree so as not to create any DAGs
            % unless we are explicitly told it is ok
            var scopeCopyTP : treePT := scopeTP
            if mustCopy then
                copyTree (scopeTP, scopeCopyTP)
            else 
                mustCopyKids := true
            end if
        
            makeTwoKids (resultRepeatTP, scopeCopyTP, repeatTP)

            nextResultRepeatTP := repeatTP

            % If it's a shallow extract, don't look inside
            if not recursive then
                return
            end if
        end if

        if trees (scopeTP).kind = kindT.choose then
                real_extract (kids (trees (scopeTP).kidsKP), mustCopyKids, recursive, nextResultRepeatTP)
        elsif trees (scopeTP).kind = kindT.order or trees (scopeTP).kind = kindT.repeat or trees (scopeTP).kind = kindT.list then
                var register scopeKidsKP := trees (scopeTP).kidsKP
                for k : 1 .. trees (scopeTP).count
                    real_extract (kids (scopeKidsKP), mustCopyKids, recursive, nextResultRepeatTP)
                    loop
                        exit when kids (trees (nextResultRepeatTP).kidsKP) = tree_emptyTP 
                        nextResultRepeatTP := kid2TP (nextResultRepeatTP)
                    end loop
                    scopeKidsKP += 1
                end for
        end if
    end real_extract

    procedure extract (XT : tokenT, repeatXT : tokenT, scopeTP : treePT, mustCopy : boolean, recursive : boolean, var resultRepeatTP : treePT)

        % extract all the occurences of things of type [X]
        % from the scope and append them to a result [repeat X].

        % begin by looking up all the necessary type names
        extract_XT := XT                
        extract_repeatXT := repeatXT    

        % The following logic forces the extract to be done to a temporary, 
        % without destroying the original target tree until the extract is completely successfully done.
        % This makes extract an atomic operation, which is necessary for garbage collection.
        
        % create the default (empty) result
        var atomicResultRepeatTP := newTreeInit (kindT.repeat, extract_repeatXT, extract_repeatXT, 0, nilKid)
        makeTwoKids (atomicResultRepeatTP, tree_emptyTP, tree_emptyTP)

        % now do the actual extraction
        real_extract (scopeTP, mustCopy, recursive, atomicResultRepeatTP)
        resultRepeatTP := atomicResultRepeatTP
        
    end extract

    procedure substitute (oldTP : treePT, newTP : treePT, var scopeTP : treePT)

        % Stack use limitation - to avoid crashes
        if stackBase - addr (oldTP) > maxStackUse then 
            quit : stackLimitReached
        end if

        % substitute all occurrences of old by new
        if sameTrees (scopeTP, oldTP) then
            % we must copy the new tree so as not to create any DAGs
            copyTree (newTP, scopeTP)
            % don't do it inside the subsituted one!
        elsif trees (scopeTP).kind = kindT.choose then
            substitute (oldTP, newTP, kids (trees (scopeTP).kidsKP))
        elsif trees (scopeTP).kind = kindT.order then
            var scopeKidsKP := trees (scopeTP).kidsKP
            for k : 1 .. trees (scopeTP).count
                substitute (oldTP, newTP, kids (scopeKidsKP))
                scopeKidsKP += 1
            end for
        elsif trees (scopeTP).kind = kindT.repeat or trees (scopeTP).kind = kindT.list then
            var scopeKidsKP := trees (scopeTP).kidsKP
            assert scopeKidsKP not= nilKid
            
            if trees (oldTP).name = trees (scopeTP).name then
                substitute (oldTP, newTP, kids (scopeKidsKP))
                substitute (oldTP, newTP, kids (scopeKidsKP + 1))
            else
                loop
                    substitute (oldTP, newTP, kids (scopeKidsKP))
                    exit when trees (kids (scopeKidsKP + 1)).kind = kindT.empty
                    scopeKidsKP := trees (kids (scopeKidsKP + 1)).kidsKP
                end loop
            end if
        end if
    end substitute

    procedure substituteLiteral (oldTP : treePT, newTP : treePT, var scopeTP : treePT)

        % Stack use limitation - to avoid crashes
        if stackBase - addr (oldTP) > maxStackUse then 
            quit : stackLimitReached
        end if

        % substitute all occurrences of literal/id/number/stringlit old by new
        if trees (scopeTP).kind = kindT.choose then
            var register skipTP := scopeTP
            loop
                exit when trees (kids (trees (skipTP).kidsKP)).kind not= kindT.choose
                skipTP := kids (trees (skipTP).kidsKP)
            end loop
            substituteLiteral (oldTP, newTP, kids (trees (skipTP).kidsKP))
        elsif trees (scopeTP).kind = kindT.order then
            var register scopeKidsKP := trees (scopeTP).kidsKP
            for k : 1 .. trees (scopeTP).count
                substituteLiteral (oldTP, newTP, kids (scopeKidsKP))
                scopeKidsKP += 1
            end for
        elsif trees (scopeTP).kind = kindT.repeat or trees (scopeTP).kind = kindT.list then
            var scopeKidsKP := trees (scopeTP).kidsKP
            assert scopeKidsKP not= nilKid
            loop
                substituteLiteral (oldTP, newTP, kids (scopeKidsKP))
                exit when trees (kids (scopeKidsKP + 1)).kind = kindT.empty
                scopeKidsKP := trees (kids (scopeKidsKP + 1)).kidsKP
            end loop
        elsif trees (scopeTP).kind = trees (oldTP).kind 
                and trees (scopeTP).name = trees (oldTP).name then
            % will this work?
            % yes, for literals we always share
            scopeTP := newTP
            % don't do it inside the subsituted one!
        end if
    end substituteLiteral

end tree
