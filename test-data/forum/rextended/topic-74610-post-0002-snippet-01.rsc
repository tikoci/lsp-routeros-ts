# Source: https://forum.mikrotik.com/t/script-find-where-routing-mark-stops-work-routeros6-7/74610/2
# Post author: @rextended
# Extracted from: code-block

/ip route
:foreach route in=[find] do={
    :local mark [get $route routing-mark]
    :if ([:typeof $mark] = "nil")  do={
        :put "no routing-mark"
    } else={
        :put "has routing-mark $mark"
    }
}
