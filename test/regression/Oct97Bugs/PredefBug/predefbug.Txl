% Use of predefned functions as ? rules does not work.
define program
        [repeat number]
end define

function main
        match [program]
                P [program]
        where
                P [?reparse P]
end function