% Simulink multi-attribute block sorting - Quicksort version
% Jim Cordy, December 2012 (Revised March 2013)

% Using Simulink grammar
include "simulink.grm"

define potential_clone
    [system_element]
end define

define system_element
    'System '{				[NL][IN]
	[default_element_tree]		[EX]
    '}					[NL]
end define

% First form is the input parse, 
% second form is the Quicksort left-pivot-right tree structure we sort it into

define default_element_tree
	[repeat default_element]
    |	[default_element_tree] [opt default_element] [default_element_tree]
end define

redefine default_element
    	[default_single_element]
    |	[default_list_element]
end redefine

redefine default_list_element
	[system_element]
    |	...
end redefine

define xml_source_coordinate
    '< [SPOFF] 'source [SP] 'file=[stringlit] [SP] 'startline=[stringlit] [SP] 'endline=[stringlit] '> [SPON] [NL]
end define

define end_xml_source_coordinate
    [NL] '< [SPOFF] '/ 'source '> [SPON] [NL]
end define

define source_unit  
    [xml_source_coordinate]
        [potential_clone]
    [end_xml_source_coordinate]
end define

redefine program
    [repeat source_unit]
end redefine

% Main program

rule main 
    replace $ [system_element]
        'System '{				
	    Elements [default_element_tree]		
        '}					
    by
        'System '{				
	    Elements [sortElements]
        '}					
end rule

% Recursive multi-attribute Quicksort of model elements

function sortElements
    replace [default_element_tree]
	Pivot [default_element] UnsortedElements [repeat default_element+]
    construct Nil [repeat default_element]
	% (empty)
    construct Tree [default_element_tree]
	Nil Nil
    construct SortedTree [default_element_tree]
	Tree [partition Pivot each UnsortedElements]
    deconstruct SortedTree
        Left [default_element_tree] Right [default_element_tree]
    by
	Left [sortElements] Pivot Right [sortElements]
end function

% Each element goes either left or right depending on its relation to the pivot

function partition Pivot [default_element] Element [default_element]
    replace [default_element_tree]
	Left [default_element*] Right [default_element*]
    construct IfGreater [number]
	_ [isGreater Pivot Element]
    by
	Left [toLeft IfGreater Element] Right [toRight IfGreater Element]
end function

function toLeft IfGreater [number] ThisElement [default_element]
    deconstruct IfGreater
	1
    replace * [repeat default_element]
	Elements [repeat default_element]
    by
	Elements [. ThisElement]
end function

function toRight IfGreater [number] ThisElement [default_element]
    deconstruct not IfGreater
	1
    replace * [repeat default_element]
	Elements [repeat default_element]
    by
	Elements [. ThisElement]
end function

% Unified multi-attribute stable prioritized comparison 
% Returns 1 if any reordering criterion applies

function isGreater Element1 [default_element] Element2 [default_element]
    replace [number]
	Zero [number]
    by
	Zero	[greaterBySingleOrKind Element1 Element2]
	 	[greaterByBlockTypeOrName Element1 Element2]
	 	[greaterByPortName Element1 Element2]
	 	[greaterByLineSrcDst Element1 Element2]
	 	[greaterByBranchDst Element1 Element2]
end function

function greaterBySingleOrKind Element1 [default_element] Element2 [default_element]
    replace [number]
	Zero [number]
    by
	Zero [greaterBySingle Element1 Element2]
	     [orBothSingleAndGreaterByKind Element1 Element2]
	     [orBothListAndGreaterByKind Element1 Element2]
end function

function greaterBySingle Element1 [default_element] Element2 [default_element]
    replace [number]
	0
    deconstruct Element1
	_ [default_list_element]
    deconstruct Element2
	_ [default_single_element]
    by 
	1
end function

function orBothSingleAndGreaterByKind Element1 [default_element] Element2 [default_element]
    replace [number]
	0
    deconstruct Element1
	_ [default_single_element]
    deconstruct Element2
	_ [default_single_element]
    deconstruct * [id] Element1
	E1Id [id]
    deconstruct * [id] Element2
	E2Id [id]
    where
	E1Id [> E2Id]
    by
	1
end function

function orBothListAndGreaterByKind Element1 [default_element] Element2 [default_element]
    replace [number]
	0
    deconstruct Element1
	_ [default_list_element]
    deconstruct Element2
	_ [default_list_element]
    deconstruct * [id] Element1
	E1Id [id]
    deconstruct * [id] Element2
	E2Id [id]
    where
	E1Id [> E2Id]
    by
	1
end function

function greaterByPortName Element1 [default_element] Element2 [default_element]
    replace [number]
	0
    deconstruct Element1
        'Port '{					
                   PNum1 [default_element]
                  'Name     PN1 [stringlit]
                  PortBody1 [repeat default_element]
        '}

    deconstruct Element2
        'Port '{					
                   PNum2 [default_element]
                  'Name     PN2 [stringlit]
                   PortBody2 [repeat default_element]
        '}

    where
	PN1 [> PN2]
    by
	1
end function

function greaterByBranchDst Element1 [default_element] Element2 [default_element]
    replace [number]
	0
    deconstruct Element1 
        'Branch '{
                  BranchBody1 [repeat default_element]
        '}
    deconstruct Element2
        'Branch '{
                  BranchBody2 [repeat default_element]
        '}
   
    skipping [default_element] deconstruct * [default_element] BranchBody1
    	 'DstBlock   DB1 [stringlit]

    skipping [default_element] deconstruct * [default_element] BranchBody2
    	 'DstBlock   DB2 [stringlit]

    where
	DB1 [> DB2]
    by
	1
end function

function greaterByBlockTypeOrName Element1 [default_element] Element2 [default_element]
    replace [number]
	0
    deconstruct Element1
        'Block '{
    		'BlockType Type1 [id]
    		'Name    N1 [stringlit]
                BlockBody1 [repeat default_element]
        '}

    deconstruct Element2
        'Block '{
    		'BlockType Type2 [id]
    		'Name    N2 [stringlit]
                BlockBody2 [repeat default_element]
        '}

    where
	Type1 [> Type2] 
	      [orEqualAndNameGreater Type2 N1 N2]
    by
	1
end function

function orEqualAndNameGreater Type2 [id] N1 [stringlit] N2 [stringlit]
    match [id]
	Type2
    where
	N1 [> N2]
end function

function greaterByLineSrcDst Element1 [default_element] Element2 [default_element]
    replace [number]
	0
    deconstruct Element1
        'Line '{
		 LineBody1 [repeat default_element]
        '}

    deconstruct Element2
        'Line '{
                 LineBody2 [repeat default_element]
        '}

    skipping [default_element] deconstruct * [default_element] LineBody1
    	 'SrcBlock SB1 [stringlit]
    skipping [default_element] deconstruct * [default_element] LineBody2
    	 'SrcBlock SB2 [stringlit]
    skipping [default_element] deconstruct * [default_element] LineBody1
    	 'DstBlock DB1 [stringlit]
    skipping [default_element] deconstruct * [default_element] LineBody2
    	 'DstBlock DB2 [stringlit]

    where
	SB1 [> SB2] 
	    [orEqualAndDstGreater SB2 DB1 DB2]
    by
	1
end function

function orEqualAndDstGreater SB2 [stringlit] DB1 [stringlit] DB2 [stringlit]
    match [stringlit]
	SB2
    where
	DB1 [> DB2]
end function
