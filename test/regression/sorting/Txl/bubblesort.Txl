% A simple but slow bubble sort in TXL.
% Fine for small, almost sorted sequences,
% but painfully slow for large input.
% The implementation actually turns out to be O(n**3)
% because of the search step involved in the rule.

define program
    [repeat id]
end define

rule main
    replace [repeat id]
        Id1 [id] Id2 [id] Rest [repeat id]
    where 
        Id1 [> Id2]
    by
        Id2 Id1 Rest 
end rule
