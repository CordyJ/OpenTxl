define program
    [repeat atom]
end define

define atom
    a | b
end define

rule main
    replace [repeat atom]
	b a Rest [repeat atom]
    by
	a b Rest
end rule
