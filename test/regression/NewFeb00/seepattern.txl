define program
        [repeat thing]
end define

define thing
        [idthing]
    |   [see number] [numberthing]
end define

define idthing
        [id]
end define

define numberthing
        [number]
end define

function main
        match [program]
                P [program]
        deconstruct * [numberthing] P
                N [numberthing]
        construct T [thing]
                N
end function
