
define program 
    [repeat token] 
end define 

rule main 
    replace $ [token] 
	'% 
    construct Base [token] 
	'% 
    by 
	Base [parse "%"] 
end rule
