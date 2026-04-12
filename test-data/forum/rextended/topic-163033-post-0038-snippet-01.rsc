# Source: https://forum.mikrotik.com/t/iterate-over-all-elements-of-an-array-of-unknown-dimension/163033/38
# Post author: @rextended
# Extracted from: code-block

:for i from=0 to=2 do={
    :if ($i = 2) do={
        :set ($ar1->i) ($ar2->i)
    }
}
