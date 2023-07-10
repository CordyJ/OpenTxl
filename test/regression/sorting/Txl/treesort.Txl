% Fast grammar-based tree sorting
% Andrew Malton, Queen's University, August 1995

% A very fast but still relatively simple sort in TXL.
% Roughly, this uses grammatical tree structure to 
% implement a Quicksort.

% The paradigm of this algorithm, as may be seen in the main rule,
% is continual replacement of unsorted lists by a structure which is
% partially sorted but still contains unsorted parts.  As in Quicksort,
% the partially sorted structure contains a left subrange, a pivot, 
% and a right subrange. All the elements of the right subrange are
% greater than the pivot; all the other elements are in the left subrange.

% When there are no unpartitioned subranges, the fringe is sorted : this can
% be proved by induction on the depth of the range, given that the rule
% [partition] below preserves the invariant in the previous paragraph.

define range
        [id *]                  % An unpartitioned range
    |   [range] [id] [range]    % A partitioned range
end define

define program
        [range]
end define

% The main rule, as described above, replaces all occurrences of unpartitioned
% ranges with partitioned ones, until none of the former remains.

rule main
    % Find an unpartitioned range with at least two things in it.
    replace [range] 
        Pivot [id] List [repeat id +]

    % Make a partitioned range with nothing in it but the pivot...
    construct Nil [id *]
        % (empty)
    construct Sub [range] 
        Nil Pivot Nil

    % ...and pop each element of List into the appropriate place.
    by 
        Sub [partition each List]
end rule


% [partition N] is called once for every N in a list, and transforms a
% partitioned range by prepending N to the left or right, as required.

function partition N [id]
    replace [range] 
        Left [id *] Pivot [id] Right [id *]
    by 
        Left [toLeft Pivot N] 
        Pivot 
        Right [toRight Pivot N]
end function


% [toLeft P N] prepends N to the left range, if required.

function toLeft Pivot [id] N [id]
    where 
        N [< Pivot]
    replace [id *] 
        List [id *]
    by 
        N List
end function


% [toRight P N] prepends N to the right range, if required.

function toRight Pivot [id] N [id]
    where not 
        N [< Pivot]
    replace [id *] 
        List [id *]
    by 
        N List
end function

