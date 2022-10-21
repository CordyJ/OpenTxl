
% Define a very simple grammar.  This should work untouched
% with TXL 1.3r4 or 2.2r1b.

define program
  [repeat declaration]
end define

define initializer
  [id] '= [id]
end define

define declaration
   [initializer]
 | [id]
end define

% Define rules.  By design, this code should cause any
% initializer phrase (composed of [id] = [id]) to be
% replaced by the ID SUBSTITUTE.  When this translation
% is run on a program which looks like:
%
%    initializer noninitializer init1 = init2
%
% the output should read:
%
%    initializer noninitializer SUBSTITUTE
%
% However, in TXL 1.3r4 or 2.2r1b, the output reads:
%
% SUBSTITUTE noninitializer SUBSTITUTE
%
% The match in hasInitializer will match /both/
% any ID 'initializer' and any phrase which is parsed as
% an [initializer].

function hasInitializer
    match * [initializer]
       a1 [initializer]
end function

rule replaceInitializers
  replace $ [declaration]
    d [declaration]
  where
    d [hasInitializer]
  by
    'SUBSTITUTE
end rule

function main
  replace [program]
     P [repeat declaration]
  by
     P [replaceInitializers]
end function
