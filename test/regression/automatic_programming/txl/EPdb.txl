% Ryman metaprogram for creating C entry point array glue from GL library spec
% J.R. Cordy, 10.11.91

% hacked-up working grammars for prototyping purposes
include "Fspecs.grm"
include "CEParray.grm"

% silly main rule currently required by TXL to specify the database scope
function main
    replace [program] DB [repeat functionSpec_or_CEParray] 
    by                DB [createCEParray]
end function

% The real work happens here -
% this one is a TXL function, which means it is instantiated exactly once.
function createCEParray

    % transform the entire database into the entry point array corresponding
    replace [repeat functionSpec_or_CEParray]
        DB [repeat functionSpec_or_CEParray]

    % we begin with an empty entrypoint array, then merge in the entries
    construct EmptyEParray [list EParrayEntry]
        % empty

    % the final null entry
    construct Null [EParrayEntry]
        {"", 0}

    by
        % here is the C declaration we are generating
        struct
        {
            char name[];
            int *addr;
        } func[] =
        {
            %      add an entry for each function 
            %             in the database
            %             --------^-------  end with the null entry
            %             |              |   -------^-------
            %             |              |   |             |
            EmptyEParray [addEntry each DB] [, Null]
            %                      ----
        };
end function

function addEntry FS [functionSpec_or_CEParray]
    % find one entry in e database
    deconstruct FS
        FNS [functionNameSpec]
        RPS [repeat parameterSpec]
        ORS [opt returnsSpec]
        OFS [opt failsSpec]

    % get the name of the function from the entry
    deconstruct FNS
        'function ( F [id] ).

    % the prefix for the corresponding glue routine name
    construct MPRO [id]
        'mpro_

    % sigh, quote needs a string to work on
    construct SF [stringlit]
        ""

    % append the new entry for this function to the C entry point array 
    replace [list EParrayEntry]
        EPlist [list EParrayEntry]

    % the new entry point array entry
    construct NewEntry [EParrayEntry]
        % make a string literal 
        % of the function name  concatenate the
        %     ---^---     function name with 'mpro_'
        %     |     |          ----^-----
        %     |     |          |        |
        { SF [quote F] , MPRO [_ F] }

    by
        EPlist [, NewEntry] 
end function

% standard TXL predefined rules
% external function quote Id [id]
