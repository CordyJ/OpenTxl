        define root
                [list thing] ;
        end define
        
        define thing
                [opt id]
        end define
        
        function main
                match * [root] X [root]
        end function
