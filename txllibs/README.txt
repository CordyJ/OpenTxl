TXL Utility Function Libraries
J.R. Cordy, January 2025

These libraries extend the built-in functions of TXL with other useful functions.
To use them in your project, use an include statement to include them.

include "stringutils.rul"

    This library extends the [stringlit] built-in functions with the following additional functions,
    where String, Pattern and Replacement are [stringlit]s and Number is a [number].

    String [subst Pattern Replacement]
        returns a copy of String with Replacement subsituted for the first instance of Pattern in String, if any

    String [substglobal Pattern Replacement]
        returns a copy of String with Replacement subsituted for every instance of Pattern in String, if any

    String [substleft Pattern Replacement]
        returns a copy of String with Replacement subsituted for the instance of Pattern at the beginning of String, if any

    String [substright Pattern Replacement]
        returns a copy of String with Replacement subsituted for the instance of Pattern at the end of String, if any

    Number [count String Pattern]
        returns the number of instances of Pattern in String

    Number [lastindex String Pattern]
        returns the index of the last instance of Pattern in String
            
include "filenameutils.rul"

    This library extends the [stringlit] built-in functions with the following additional functions for manipulating 
    Unix and Windows file paths, where FilePath is a [stringlit].

    FilePath [filename]
        returns the last element of the file path, e.g., "z.w" of "/x/y/z.w"

    FilePath [filedir]
        returns the directory containing the last element of the file path, e.g., "/x/y" of "/x/y/z.w"

    FilePath [filerootname]
        returns the root name of the last element of the file path, e.g., "z" of "/x/y/z.w"

    FilePath [filetype]
        returns the file type extension of the last element of the file path, e.g., "w" of "/x/y/z.w"

    FilePath [filereverse]
        returns the file path in reverse order, e.g., "z.w/y/x/" for "/x/y/z.w"

