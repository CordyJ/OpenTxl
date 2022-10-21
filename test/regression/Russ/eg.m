;
split :: [char] -> [[char]]
;
split input
      = split' [] input
{
        where
        split' sofar (a:input)
              = sofar : split input, if a = '\n'
              = split' (sofar ++ [a]) input, otherwise
        split' sofar []
              = no_blank sofar []                       || No extra blank lines!
}
