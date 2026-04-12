# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/6
# Post author: @rextended
# Extracted from: code-block

:global test {{"A";"D";"I";"P";"Y"};{"B";"C";"H";"O";"X"};{"E";"F";"G";"N";"W"};{"J";"K";"L";"M";"V"};{"Q";"R";"S";"T";"U"}}

:foreach x in=$test do={
    :foreach y in=$x do={
        :put "$[:find $test $x],$[:find $x $y] = $y"
    }
}
