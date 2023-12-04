type * elementType : int
module Stack
    export (Push, Pop, Top)
    const maxDepth := 6
    var s : array 1 .. maxDepth of elementType
    var stackTop : 0 .. maxDepth := 0

    procedure Push (value : elementType)
	if stackTop < maxDepth then
	    stackTop += 1
	    s (stackTop) := value
	else
	    put "ERROR Push"
	    quit 
	    end if
    end Push

    procedure Pop
	if stackTop > 0 then
	    stackTop -= 1
	else
	    put "ERROR Pop"
	    quit 
	end if
    end Pop

    function Top : elementType
	assert stackTop > 0
	result s (stackTop)
    end Top
end Stack

procedure Pause
    put "Hit return to continue " ..
    var x : string (1)
    get x : 1
end Pause

Stack.Push (10)
Stack.Push (5)
Stack.Push (-6)
Stack.Push (14); Pause
Stack.Pop
Stack.Pop
Stack.Push (99); Pause
