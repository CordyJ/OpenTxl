define program
        [repeat name]
end define

define name
        '# [id]
end define

function main
        construct Names [repeat name]
                '# 'Jim
                '# 'Jane
                '# 'Tom
                '# 'Nancy
        construct TheId [id]
                'Tom
        construct _ [id] _ [message "1"]
        deconstruct * [name] Names
                '# TheId
        construct _ [id] _ [message "2"]
        skipping [name]
        deconstruct * [name] Names
                '# TheId
        construct _ [id] _ [message "3"]
        where
                Names [containsName TheId]
        construct _ [id] _ [message "4"]
        match [program] _ [program]
end function

function containsName TheId [id]
        skipping [id]
        match * [id]
                TheId
end function
