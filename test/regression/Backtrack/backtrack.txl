% Simple demonstration of backtracking in TXL
% J.R. Cordy, Queen's University, January 1996

% Given the edge list of a labelled directed graph, 
% e.g.
%       (a,b) (a,d) (b,c) (b,e) (c,f) (c,a) (d,e) (d,b) 
%       (e,f) (e,a) (f,c) (f,e)

% Followed by a path query,
% e.g.
%       ? (f,b)

% This program returns all the possible paths that answer the query,
% e.g.
%       f c a b
%       f c a d b
%       f e a b
%       f e a d b

comments
        '%
end comments

% include "TxlExternals"

define program
        [repeat pair] [NL] 
        ? [pair]
end define

define pair
        ( [id] , [id] )
end define

function main
        match [program]
                Pairs [repeat pair]
                ? (A [id] , B [id] )
        % We keep track of the path so far at all times
        construct StartPath [repeat id]
                A
        where
                Pairs [backtrack Pairs A B StartPath]
end function

function backtrack Pairs [repeat pair] X [id] Y [id] Path [repeat id]
        % Find an edge continuing from where we are so far (X)
        match * [pair]
                (X, Z [id])
        % That leads to a vertex not yet in our path
        where not
                Z [in Path]
        % The add it to the path
        construct NewPath [repeat id]
                Path [. Z]
        % And check to see if it is where we want to get,
        % or there is a path from it to where we want to get
        where
                Pairs [equals Z Y] [backtrack Pairs Z Y NewPath]
        % If we actually got there, print out the path
        where
                Pairs [equals Z Y]
        construct Output [repeat id]
                NewPath [print]
        % And continue the search for other longer paths
        where
                Pairs [backtrack Pairs Z Y NewPath]
end function

function equals A [id] B [id]
        deconstruct A
                B
        match [repeat pair]
                _ [repeat pair]
end function

function in Path [repeat id]
        match [id]
                A [id]
        deconstruct * [id] Path
                A
end function
