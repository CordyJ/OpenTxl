keys
        JIM
end keys

define program
        [repeat item]
end define

define item
        [token] | [key]
end define

function main
        replace * [key]
                K [key]
        by
                K [changeTo 'foobar]
end function

function changeTo Id [id]
        replace [any]
                _ [any]
        deconstruct Id
                AnyId [any]
        by
                AnyId
end function
