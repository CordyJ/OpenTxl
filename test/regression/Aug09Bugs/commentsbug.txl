comments 
                 /*  */ 
        |       'Comment: 
end comments 

define program 
    [day] 
end define 

define day 
        [number] 
        | 'Sunday | 'Monday | 'Tuesday' 
        | 'Wednesday | 'Thursday | 'Friday      | 'Saturday 
        | 'Sun | 'Mon | 'Tue | 'Wed     | 'Thu | 'Fri | 'Sat 
end define 

define year 
                [number] 
end define 

function main 
    match [program] _ [program] 
end function
