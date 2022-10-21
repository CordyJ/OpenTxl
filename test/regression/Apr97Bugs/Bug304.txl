% Example of Legasys bug #304
%
% Apparently, [TAB_nn] fails to tab when it is the first thing on a line
% (that is, when it immediately follows a [NL]).
% 
% It also appears to move the cursor to position nn+1 instead of nn.
% 
% Evidence: the specification
% 
%         define program
%                 [repeat line]
%         end define
% 
%         define line
%                 FOO [TAB_10] BAR [NL]
%         |       [TAB_10] BAR [NL]
%         |       [TAB_10] BLAT
%         |       [NL] [number] [NL]    % show column positions
%         end define
% 
%         function main
%                 match [program]
%                         P [program]
%         end function
% 
% for the input
% 
%         12345678901234567890
%         FOO BAR
%         BAR
%         BLAT
%         BLAT
%         FOO BAR
%         BAR
% 
% specifies the output
% 
%         12345678901234567890
%         FOO      BAR
%                  BAR
%                  BLAT
%                  BLAT FOO
%                  BAR
%                  BAR
% 
% but actually produces the output
% 
%         12345678901234567890
%         FOO       BAR
%         BAR
%         BLAT      BLAT FOO
%                   BAR
%         BAR
% 
% 
% This is version 1.9d2, by the way.
% 
% Andrew

#pragma -tabnl

        define program
                [repeat line]
        end define

        define line
                FOO [TAB_10] BAR [NL]
        |       [TAB_10] BAR [NL]
        |       [TAB_10] BLAT
        |       [NL] [number] [NL]    % show column positions
        end define

        function main
                match [program]
                        P [program]
        end function
