% Delivered-To: cordy@legasys.on.ca
% X-Sender: malton@choya.forest.legasys.on.ca
% Mime-Version: 1.0
% Date: Thu, 25 Feb 1999 12:27:20 -0500
% To: cordy
% From: Andrew Malton <malton@legasys.on.ca>
% Subject: Key ids parse as [token] during [reparse]
% 
% Jim, I have discovered the following problem with token and reparse.
% I discovered it during experiments with robust parsing.  I use [token] to
% handle the last-chance case, and usually it works very well.
% 
% However, during [reparse], those key ids which were refused as [token] during
% the initial [read] are accepted as [token] during [reparse].  This renders
% my multi-phase robust parsing design unimplementable.
% 
% Here is very simple example.

        keys
                KEY
        end keys

        define program
                [repeat anything]
        end define

        define anything
                [token]
        |       [NL] [IN] KEY [EX] [NL]
        end define

% (If KEY were written first, of course, the problem would not be illustrated.
% There is another reason, which I added a postscript about.)
% 
% Using a simple program

        function main
                replace [program]
                        Program [program]
                by
                        Program [reparse Program]
        end function


% and input stream
% 
%       THE KEY (TO IT ALL) IS: DO NOT KEY THE KEY!
% 
% we get the expected output
% 
%       THE
%               KEY
%       (TO IT ALL) IS : DO NOT
%               KEY
%       THE
%               KEY
%       !
% 
% but if the program ends
% 
%                       Program
%                               [reparse Program]
% 
% then we get the surprising output
% 
%       THE KEY (TO IT ALL) IS : DO NOT KEY THE KEY !
% 
% showing that the KEY tokens were accepted by [token] during reparse.
% 
% Andrew
% 
% 
% PS.  In the real situation I want [anything] to be described as like
% 
%       define anything
%               [token] [token] [token] [token] [token] [token] [token] [token]
%       |       [token]
%       end define
% 
% because this allows the parser to grab chunks at a time, instead of only
% one token.
% Experiments showed that if I don't do this, then at size S, the stack is of
% size (S * 112.5) Kb, and this allows exactly (S * 720) tokens to be parsed as
% [repeat token].  That is not enough.  However, for each extra '[token]' in the
% above, I get the equivalent of an extra -size 50 (i.e. 36 000 tokens) parsable.
% The above definition, with eight, allows a quarter of a million tokens on
% input,
% which seems enough.
% 
% But if I iterate '[token]' like that, then I hvae to know that [token] won't
% eat keys.  Which it doesn't on input, but does on [reparse].
% 
% A
% 
% ===========================================================
%  Dr. Andrew J. Malton          email: malton@legasys.on.ca
%  Legasys Corp.                 Phone: +1 (613) 545-1190
%  Kingston, Canada              Fax:   +1 (613) 545-1477
%           http://www.ls-2000.com/legasys.html
% ===========================================================
