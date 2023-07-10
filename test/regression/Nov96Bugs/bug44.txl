        define root
                [repeat id+]
        end define
        
        function main
                replace [root]
                        R [root]
                by
                        R [bug]
        end function
        
        rule bug
                replace [repeat id]
                        X [id]
                        More [repeat id]
                by
                        More
        end rule
