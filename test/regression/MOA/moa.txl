% TXL implementation of MOA reduction rules 
% J.R. Cordy & M.A. Jenkins, Queen's University, September 1993

include "MOA.grm"

rule main
    replace [program]
	PGM [program]
    construct NewPGM [program]
	PGM [normalize]
	    [reduce] 
	    [denormalize]
    where not
	NewPGM [= PGM]
    by
	NewPGM
end rule



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% normalization/denormalization rules
% - expand all literal vectors and scalars to their shaped array forms
% - replace all references to named constants with their literal array values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function normalize
    replace [program]
	PGM [program]
    by
	PGM [foldNegations]
	    [normalizeScalarDeclarations]
	    [normalizeArrayDeclarations]
	    [normalizeScalarConstants]
	    [normalizeVectorConstants]
	    [expandNamedConstants]
end function

rule foldNegations
    replace [signed_number]
	- AbsN [number]
    construct N [number]
	_ [- AbsN]
    by 
	N
end rule

rule normalizeScalarConstants
    replace [factor]
	N [number]
    by
	^0 <> < N >
end rule

rule normalizeVectorConstants
    replace [constant_value]
	C [constant_value]
    deconstruct C
	< CElements [repeat number_or_referenced_name] >
    construct Clength [number]
	_ [count CElements]
    by
	^1 < Clength > < CElements >
end rule

function count Elements [repeat number_or_referenced_name]
    deconstruct Elements
	First [number_or_referenced_name]
	Rest [repeat number_or_referenced_name]
    replace [number]
	N [number]
    by
	N [+ 1] [count Rest]
end function

rule normalizeScalarDeclarations
    replace [declared_name_and_definition] 
	X [id] T [scalar_type]
    by
	X ^0 <> T
end rule

rule normalizeArrayDeclarations
    replace [constant_definition] 
	const X [id] S [array_shape] T [scalar_type] = V [vector_value] ;
    by
	const X S T = S V ;
end rule

rule expandNamedConstants 
    replace [repeat definition_or_statement]
	const X [id] Xshape [opt array_shape] Xtype [scalar_type] = 
	    Xvalue [constant_value] ;
	Rest [repeat definition_or_statement]
    construct FX [factor]
	X
    construct FXvalue [factor]
	( Xvalue )
    by
	Rest [$ FX FXvalue]
end rule

function denormalize
    replace [program]
	PGM [program]
    by
	PGM [denormalizeScalarConstants]
	    [denormalizeVectorConstants]
	    [denormalizeDeclarations]
end function

rule denormalizeScalarConstants
    replace [factor]
	^0 <> < N [number] >
    by
	N
end rule

rule denormalizeVectorConstants
    replace [factor]
	^1 < N [number] > V [vector_value]
    by
	V 
end rule

rule denormalizeDeclarations
    replace [declared_name_and_definition] 
	X [id] ^0 <> T [scalar_type]
    by
	X T 
end rule



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOA reduction rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rule reduce
    replace [program]
	PGM [program]

    % construct the result of the next iteration
    construct NewPGM [program]
	PGM [psi]
	    [distribute]
	    [concatenate]
	    [take]
	    [drop]

    % if it is the same as it was, we have reached a fixed point
    where not
	NewPGM [= PGM]

    % otherwise replace and try again
    by
       NewPGM
end rule



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% psi reduction rules
% the entire set of these must be done properly in the translation step.
% but for now, we implement only psi constant folding -- JRC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function psi
    replace [program]
	PGM [program]
    by
	PGM [normalizeScalarPsi]
	    [foldPsi]	    	
	    [eliminateRedundantParens]
end function

rule normalizeScalarPsi
    replace [expression]
	^0 <> < N [number] > psi A [factor]
    by
	^1 <1> <N> psi A
end rule

rule foldPsi
    replace [expression]
	^1 <1> < I [number] > psi A [array_value]
    % construct a factor to hold the result of subscripting
    construct Zero [factor]
	0
    % now subscript and replace the factor with the element value
    by
	Zero [subscript A I]	
end rule

rule eliminateRedundantParens
    replace [factor]
	( F [factor] )
    by
	F
end rule



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% artihmetic operation rules
% - distribute operations across psi expressions
% - fold constant arithmetic operations 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function distribute
    replace [program]
	PGM [program]
    by
	PGM [distributeAopX PGM]
	    [distributeXopA PGM]
	    [distributeAopB PGM]
	    [foldOperations]
end function

rule distributeAopX PGM [program]
    replace [expression]
	P [factor] psi ( A [factor] Op [arithmetic_operator] X [factor] )
    where
	X [isScalar PGM]
    where not 
	A [isScalar PGM]
    by
	(P psi A) Op X
end rule

rule distributeXopA PGM [program]
    replace [expression]
	P [factor] psi ( X [factor] Op [arithmetic_operator] A [factor] )
    where
	X [isScalar PGM]
    where not 
	A [isScalar PGM]
    by
	X Op (P psi A)
end rule

rule distributeAopB PGM [program]
    replace [expression]
	P [factor] psi ( A [factor] Op [arithmetic_operator] B [factor] )
    construct Ashape [factor]
	A [shape PGM]
    construct Bshape [factor]
	B [shape PGM]
    where
	Ashape [= Bshape]
    by
	(P psi A) Op (P psi B)
end rule

rule foldOperations 
    replace [expression]
	A [array_value] Op [arithmetic_operator] B [array_value]
    deconstruct A
	AShape [array_shape] < AElements [repeat number_or_referenced_name] > 
    deconstruct B
	AShape < BElements [repeat number_or_referenced_name] > 
    construct ResultElements [repeat number_or_referenced_name]
	_ [foldOperationAndAppend Op each AElements BElements]
    by
	AShape < ResultElements >
end rule

function foldOperationAndAppend Op [arithmetic_operator] 
	E1 [number_or_referenced_name] E2 [number_or_referenced_name]
    deconstruct E1 
	N1 [number]
    deconstruct E2 
	N2 [number]
    replace [repeat number_or_referenced_name]
	ResultSoFar [repeat number_or_referenced_name]
    construct N3 [number]
	N1 [foldAdd Op N2] 
	   [foldSubtract Op N2] 
	   [foldMultiply Op N2] 
	   [foldDivide Op N2]
    construct E3 [number_or_referenced_name]
	N3
    by
	ResultSoFar [. E3]
end function

function foldAdd Op [arithmetic_operator] N2 [number]
    deconstruct Op
	+
    replace [number]
	N1 [number]
    by
	N1 [+ N2]
end function

function foldSubtract Op [arithmetic_operator] N2 [number]
    deconstruct Op
	-
    replace [number]
	N1 [number]
    by
	N1 [- N2]
end function

function foldMultiply Op [arithmetic_operator] N2 [number]
    deconstruct Op
	*
    replace [number]
	N1 [number]
    by
	N1 [* N2]
end function

function foldDivide Op [arithmetic_operator] N2 [number]
    deconstruct Op
	/
    replace [number]
	N1 [number]
    by
	N1 [/ N2]
end function



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% concatenation rules
% - convert scalar operands
% - simplify psi of cats
% - fold constant concatenations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function concatenate
    replace [program]
	PGM [program]
    by
	PGM [normalizeAcatScalar PGM]
	    [normalizeScalarCatA PGM]
	    [simplifyCat PGM]
	    [foldCat]
end function

rule normalizeAcatScalar PGM [program]
    replace [expression]
	A [factor] cat X [factor] 	
    where
	X [isScalar PGM]
    % for now, we insist that X be a literal integer since we have no general
    % vector constructor operation -- JRC
    deconstruct X
	^0 <> < N [number] >
    by
	A cat ^1 <1> <N>
end rule

rule normalizeScalarCatA PGM [program]
    replace [expression]
	X [factor] cat A [factor] 	
    where
	X [isScalar PGM]
    % for now, we insist that X be a literal integer since we have no general
    % vector constructor operation -- JRC
    deconstruct X
	^0 <> < N [number] >
    by
	^1 <1> <N> cat A
end rule

rule simplifyCat PGM [program]
    replace [expression]
	^1 <1> < I [number] > psi ( A [factor] cat B [factor] )

    % A cat B simplification applies iff 1 drop shape(A) = 1 drop shape(B)
    construct ShapeA [factor]
	A [shape PGM]
    deconstruct ShapeA
	^1 < ADim [number] > < AFirstExtent [number] 
		ARestExtents [repeat number_or_referenced_name] >
    construct ShapeB [factor]
	B [shape PGM]
    deconstruct ShapeB
	^1 < ADim > < BFirstExtent [number_or_referenced_name] ARestExtents >

    % we guess that the result is an index of A ...
    construct Result [expression]
	^1 <1> < I > psi A

    % ... and then correct for the assumption if necessary
    by
	Result [simplifyCat_case2 B PGM]
end rule

function simplifyCat_case2 B [factor] PGM [program]
    % we guessed this result so far ...
    replace [expression]
	^1 <1> < I [number] > psi A [factor]

    % ... but if I >= 1 take shape(A) then we guessed wrong 
    construct ShapeA [factor]
	A [shape PGM]
    deconstruct ShapeA
	^1 < ADim [number] > < AFirstExtent [number] 
		ARestExtents [repeat number_or_referenced_name] >
    where
	I [>= AFirstExtent]

    % so replace the result with the B case
    by
	^1 <1> < I [- AFirstExtent] > psi B
end function

rule foldCat
    replace [expression]
	A [array_value] cat B [array_value]
    deconstruct A
	^DimA [number] < AFirstExtent [number] 
	    ARestExtents [repeat number_or_referenced_name] >
		< AElements [repeat number_or_referenced_name] > 
    deconstruct B
	^DimA < BFirstExtent [number] ARestExtents > 
	    < BElements [repeat number_or_referenced_name] > 
    by
	^DimA < AFirstExtent [+ BFirstExtent] ARestExtents > 
	    < AElements [. BElements] >
end rule



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% take rules
% - convert unit vector to scalar operands
% - simplify psi of takes
% - fold constant takes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function take
    replace [program]
	PGM [program]
    by
	PGM [normalizeUnitVectorTakeA]
	    [simplifyTake PGM]
	    [foldTake]
end function

rule normalizeUnitVectorTakeA 
    replace [expression]
	^1 <1> < N [number] > take A [factor] 	
    by
	^0 <> < N > take A
end rule

rule simplifyTake PGM [program]
    replace [expression]
	^1 <1> < Index [number] > psi ( ^0 <> < N [number] > take A [factor] )
    by
	^1 <1> < Index  [reverseIfNegative N A PGM] > psi A
end rule

function reverseIfNegative N [number] A [factor] PGM [program]
    % if N < 0 then we must use reverse indexing
    where
	N [< 0]
    % get the shape of A
    construct ShapeA [factor]
	A [shape PGM]
    deconstruct ShapeA
	^1 < ADim [number] > < AFirstExtent [number] 
		ARestExtents [repeat number_or_referenced_name] >
    % replace the index with the reverse index 
    replace [number]
	Index [number] 
    by
	AFirstExtent [+ N] [+ Index]
end function

rule foldTake
    replace [expression]
	^0 <> < N [number] > take A [array_value]
    deconstruct A
	^Dim [number] < FirstExtent [number] 
	    RestOfExtents [repeat number_or_referenced_name] >
		< Elements [repeat number_or_referenced_name] > 
    construct AbsN [number]
	N [abs]
    by
	^Dim < AbsN RestOfExtents > 
	    < Elements [foldTakeForward N FirstExtent RestOfExtents] 
		       [foldTakeBackward N FirstExtent RestOfExtents] >
end rule

function foldTakeForward N [number] FirstExtent [number] 
	RestOfExtents [repeat number_or_referenced_name]
    where
	N [>= 0]
    replace [repeat number_or_referenced_name]
	Elements [repeat number_or_referenced_name]
    % can only fold takes of arrays without symbolic extents
    construct NumericRestOfExtents [repeat number]
	_ [^ RestOfExtents]
    % compute element length of first dimension
    construct One [number]
	1
    construct FirstDimElementLength [number]
	One [* each NumericRestOfExtents]
    % compute number of elements in selected slice
    construct NumberOfElements [number]
	FirstDimElementLength [* N]
    by
	Elements [takeLeadingElements NumberOfElements]
end function

function foldTakeBackward N [number] FirstExtent [number] 
	RestOfExtents [repeat number_or_referenced_name]
    where
	N [< 0]
    replace [repeat number_or_referenced_name]
	Elements [repeat number_or_referenced_name]
    % can only fold takes of arrays without symbolic extents
    construct NumericRestOfExtents [repeat number]
	_ [^ RestOfExtents]
    % compute element length of first dimension
    construct One [number]
	1
    construct FirstDimElementLength [number]
	One [* each NumericRestOfExtents]
    % compute number of elements in selected slice
    construct AbsN [number]
	N [abs]
    construct NumberOfElements [number]
	FirstDimElementLength [* AbsN]
    % and drop the total number of elements minus the elements selected
    construct NRestOfExtents [repeat number]
	_ [^ RestOfExtents]
    construct TotalElements [number]
	FirstExtent [* each NRestOfExtents]
    construct DroppedElements [number]
	TotalElements [- NumberOfElements]
    by
	Elements [dropLeadingElements DroppedElements]
end function



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% drop rules
% - convert unit vector to scalar operands
% - simplify psi of drops
% - fold constant drops
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function drop
    replace [program]
	PGM [program]
    by
	PGM [normalizeUnitVectorDropA]
	    [simplifyDrop PGM]
	    [foldDrop]
end function

rule normalizeUnitVectorDropA
    replace [expression]
	^1 <1> < N [number] > drop A [factor] 	
    by
	^0 <> < N > drop A
end rule

rule simplifyDrop PGM [program]
    replace [expression]
	^1 <1> < Index [number] > psi ( ^0 <> < N [number] > drop A [factor] )
    by
	^1 <1> < Index  [shiftIfPositive N A PGM] > psi A
end rule

function shiftIfPositive N [number] A [factor] PGM [program]
    % if N >= 0 then we must use shift indexing
    where
	N [>= 0]
    % replace the index with the shifted index 
    replace [number]
	Index [number] 
    by
	N [+ Index]
end function

rule foldDrop
    replace [expression]
	^0 <> < N [number] > drop A [array_value]
    deconstruct A
	^Dim [number] < FirstExtent [number] 
	    RestOfExtents [repeat number_or_referenced_name] >
		< Elements [repeat number_or_referenced_name] > 
    construct AbsN [number]
	N [abs]
    by
	^Dim < FirstExtent [- AbsN] RestOfExtents > 
	    < Elements [foldDropForward N FirstExtent RestOfExtents] 
		       [foldDropBackward N FirstExtent RestOfExtents] >
end rule

function foldDropForward N [number] FirstExtent [number] 
	RestOfExtents [repeat number_or_referenced_name]
    where
	N [>= 0]
    replace [repeat number_or_referenced_name]
	Elements [repeat number_or_referenced_name]
    % can only fold drops of arrays without symbolic extents
    construct NumericRestOfExtents [repeat number]
	_ [^ RestOfExtents]
    % compute element length of first dimension
    construct One [number]
	1
    construct FirstDimElementLength [number]
	One [* each NumericRestOfExtents]
    % compute number of elements to be dropped
    construct NumberOfElements [number]
	FirstDimElementLength [* N]
    by
	Elements [dropLeadingElements NumberOfElements]
end function

function foldDropBackward N [number] FirstExtent [number] 
	RestOfExtents [repeat number_or_referenced_name]
    where
	N [< 0]
    replace [repeat number_or_referenced_name]
	Elements [repeat number_or_referenced_name]
    % can only fold drops of arrays without symbolic extents
    construct NumericRestOfExtents [repeat number]
	_ [^ RestOfExtents]
    % compute element length of first dimension
    construct One [number]
	1
    construct FirstDimElementLength [number]
	One [* each NumericRestOfExtents]
    % compute number of elements to be dropped
    construct AbsN [number]
	N [abs]
    construct NumberOfElements [number]
	FirstDimElementLength [* AbsN]
    % and take the total number of elements minus the elements dropped
    construct NRestOfExtents [repeat number]
	_ [^ RestOfExtents]
    construct TotalElements [number]
	FirstExtent [* each NRestOfExtents]
    construct TakenElements [number]
	TotalElements [- NumberOfElements]
    by
	Elements [takeLeadingElements TakenElements]
end function



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% auxiliary helper functions
% - these are used by the above rulesets and are expected to be useful in 
%   future rules
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function shape PGM [program]
    replace [factor]
	AF [factor]
    by
	AF [shapeConstant] [shapeName PGM]
end function

function shapeName PGM [program]
    replace [factor]
	A [id]
    deconstruct * [declared_name_and_definition] PGM
	A ^ Dim [number] < Extents [repeat number_or_referenced_name] > 
	    T [scalar_type]
    by
	^1 < Dim > < Extents >
end function

function shapeConstant 
    replace [factor]
	^ Dim [number] < Extents [repeat number_or_referenced_name] > 
	    Value [vector_value]
    by
	^1 < Dim > < Extents >
end function

function isScalar PGM [program]
    % is X a scalar?
    match [factor]
	X [factor]
    construct Xshape [factor]
	X [shape PGM]
    deconstruct Xshape
	^1 <0> <>
end function

function subscript Array [array_value] Index [number]
    deconstruct Array
	^ Dim [number] 
	    < FirstExtent [number_or_referenced_name]
	      RestOfExtents [repeat number_or_referenced_name] >
	    < Elements [repeat number_or_referenced_name] >
    % can only subscript arrays without symbolic extents
    construct NumericRestOfExtents [repeat number]
	_ [^ RestOfExtents]
    % compute element length of first dimension
    construct One [number]
	1
    construct FirstDimElementLength [number]
	One [* each NumericRestOfExtents]
    % compute first index of selected slice
    construct FirstIndex [number]
	FirstDimElementLength [* Index]
    % now compute the slice
    replace [factor]
	_ [factor]
    by
	^Dim [- 1] < RestOfExtents > 
	    < Elements [selectElements FirstIndex FirstDimElementLength] >
end function

function selectElements FirstIndex [number] ElementLength [number]
    replace [repeat number_or_referenced_name]
	Elements [repeat number_or_referenced_name]
    by
	Elements [dropLeadingElements FirstIndex]
		 [takeLeadingElements ElementLength]
end function
	
function dropLeadingElements N [number]
    where 
	N [> 0]
    construct Nminus1 [number]
	N [- 1]
    replace [repeat number_or_referenced_name]
	First [number_or_referenced_name]
	Rest [repeat number_or_referenced_name]
    by
	Rest [dropLeadingElements Nminus1]
end function

function takeLeadingElements N [number]
    replace [repeat number_or_referenced_name]
	Elements [repeat number_or_referenced_name]
    construct NewElements [repeat number_or_referenced_name]
	_ [appendElements N Elements] 
    by
	NewElements
end function

function appendElements N [number] Elements [repeat number_or_referenced_name]
    where
	N [> 0]
    construct Nminus1 [number]
	N [- 1]
    deconstruct Elements
	FirstElement [number_or_referenced_name]
	RestOfElements [repeat number_or_referenced_name]
    replace [repeat number_or_referenced_name]
	ElementsSoFar [repeat number_or_referenced_name]
    by
        ElementsSoFar [. FirstElement] [appendElements Nminus1 RestOfElements]
end function

function abs
    replace [number]
	N [number]
    where
	N [< 0]
    construct AbsN [number]
	_ [- N]
    by
	AbsN
end function
