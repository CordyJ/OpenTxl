define program
        [repeat id]
end define

function main
        import TXLargs [repeat stringlit]
        construct _ [repeat stringlit]
                TXLargs [putp "args are: '%'"]
        import TXLprogram [stringlit]
        construct _ [stringlit]
                TXLprogram [putp "program name is: '%'"]
        import TXLinput [stringlit]
        construct _ [stringlit]
                TXLinput [putp "input name is: '%'"]
        import TXLexitcode [number]
        construct _ [number]
                TXLexitcode [putp "exitcode is: %"]
        match [program] _ [program]
end function
