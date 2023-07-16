% Trivial demonstration of a paradigm for adding attributes
% without changing the concrete output.

% We demonstrate with the example of attributing every token in
% the input with an attribute indicating if it is a representation
% of the number 1,  e.g., 1, one, "one", "1".

define program
	[repeat attributedtoken]
end define

% The attribution could be attached to any nonterminal at all.
% In this case, for demonstration purposes we simply attribute
% the base token types [id], [number] and [stringlit].

% [attribute] below should not be [opt attribute], which is more intuitive,
% since TXL's ordered parsing would then check first for the case when the 
% attribute is present.  Since our attributes derive [empty], this would 
% attribute every input token on the initial parse.  Instead, we insist 
% that an [attribute] be present, and have it derive [empty] as its first 
% alternative.

define attributedtoken
	[unattributedtoken] [attribute]
end define

define unattributedtoken
	[id]
    |	[number]
    |	[stringlit]
end define

% We exploit TXL's ordered ambiguous parsing to avoid
% accidentally parsing any part of the input as an attribute.
% Putting [empty] as the first alternative characterizes this
% define as an attribute.
% The order of these alternatives is essential.

define attribute
	[empty]
    |	[ONE]
    % and any number of others ...
end define

% Each attribute must itself derive [empty] so as not to change output.

define ONE
	[empty]
end define

% external function debug
% external function print
% external function message M [stringlit]

function main
    replace [program]
	Input [repeat attributedtoken]
    by
	% Show the original input ...
	Input [message '"Original input:"] [print]	
	    % ... we can see the attribution with [debug] ...
	    [attributeOnes] [message '"Attributed tree:"] [debug] 
	    % ... and demonstrate by converting all tokens attributed ONE to 1
	    [normalizeOnes] [message '"Normalized output:"] 
end function

rule attributeOnes
    replace [attributedtoken]
	AT [attributedtoken]
    where
	AT [?attributeids] [?attributestrings] [?attributenumbers]
    by
	AT [attributeids]
	   [attributestrings]
	   [attributenumbers]
end rule

function attributeids
    % We only attribute those ids that are equal to ONE
    replace [attributedtoken]
	Id [id]
    where
	Id [= 'one] 
    construct ONEattribute [ONE]
	% empty
    by
	Id ONEattribute
end function

function attributestrings
    % We only attribute those strings that are equal to ONE
    replace [attributedtoken]
	S [stringlit]
    where
	S [= '"1"] [= '"one"]
    construct ONEattribute [ONE]
	% empty
    by
	S ONEattribute
end function

function attributenumbers
    % We attribute those number that are equal to ONE
    replace [attributedtoken]
	N [number]
    where
	N [= 1] 
    construct ONEattribute [ONE]
	% empty
    by
	N ONEattribute
end function

rule normalizeOnes
    % We turn everything attributed as ONE into the literal number 1.
    replace [attributedtoken]
	T [unattributedtoken] Attr [ONE]
    by
	1
end rule
