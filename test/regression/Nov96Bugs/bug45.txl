        define word
                OLD | NEW
        end define
        
        define parenthesis
                ( [word] )
        end define
        
        define phrase
                [word]
        |       [parenthesis]
        end define
        
        define root
                [repeat phrase]
        end define
        
        rule main
                skipping [parenthesis]
                replace $ [word]
                        OLD
                by
                        NEW
        end rule
