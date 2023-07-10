define program
    [repeat token]
end define

#pragma -comment
comments
        '%
end comments

function main
    % should allow comparison of different types of text tokens
    construct Id [id]
        'Jim
    construct String [stringlit]
        "Jim"
    construct Char [charlit]
        ''Jim'
    construct Comment [comment]
        '% Jim
    % test mixes
    where Id [= 'Jim]
    where not Id [< "Jim"]
    where not Id [> ''Jim']
    where not Id [= Comment]

    where String [= 'Jim]
    where not String [< "Jim"]
    where not String [> ''Jim']
    where not String [= Comment]

    where Char [= 'Jim]
    where not Char [< "Jim"]
    where not Char [> ''Jim']
    where not Char [= Comment]

    where not Comment [= 'Jim]
    where not Comment [< "% Jim"]
    where not Comment [> ''% Jim']
    where Comment [= Comment]

    replace [program]
        _ [program]
    by
        42
end function
