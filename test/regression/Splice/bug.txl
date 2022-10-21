% demonstrates a bug in the implementation of [.]
% and other splices - this is one of many manifestations.

define program
    [repeat number]
end define

function main
    replace [program]
	RN [repeat number]
    construct RN2 [repeat number]
	44 55
    construct RN3 [repeat number]
	RN [. RN2] 
    by
	RN [. RN2] [. RN3]
end function
