% Simple bubble sort in TXL
% N**3 complexity

define range
        [id*]
end define

define program
        [range] 
end define

function main
    replace [program]
	Elements [id*]
    by 
	Elements [bubblesort]
end function

rule bubblesort
    replace [id*]
	Elements [id*]
    where 
	Elements [?onestep 'dummy]
    by
	Elements [onestep]
end rule

function onestep 
    replace [id*]
        Id1 [id] Id2 [id] Rest [id*]
    construct Id1Id2 [id*]
	Id1 Id2
    construct NewElements [id*]
	Id1Id2 [swap] [. Rest]
    deconstruct NewElements 
	NewId1 [id] NewRest [id*]
    by
	NewId1 NewRest [onestep]
end function

function swap
    replace [id*]
	Id1 [id] Id2 [id]
    where
	Id1 [> Id2]
    by
	Id2 Id1
end function
