define program
        [repeat number]
end define

function main
    replace * [repeat number]
        1 Rest [repeat number]
    by
        1 Rest [. Rest] [main]
end function
