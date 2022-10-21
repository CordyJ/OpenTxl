% Simple bubble sort in TXL
% N**3 complexity

define range
        [id*]
end define

define program
        [range] 
end define

rule main
    replace [id*]
        Id1 [id] Id2 [id] Rest [id*]
    where
	Id1 [> Id2]
    by
        Id2 Id1 Rest
end rule
