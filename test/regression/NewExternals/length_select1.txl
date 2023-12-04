define program 
	[repeat thingie+] : [number] [number]
    |	[repeat thingie+]
end define

define thingie
    [number] | [id]
end define

% % % external rule print
% % % external rule length R [any]
% % % external rule select L [number] U [number]

rule main
    replace [program]
	RT [repeat thingie+] : Lower [number] Upper [number]
    construct RTlength [number]
	_ [length RT] [print]
    by
	RT [select Lower Upper]
end rule

    
