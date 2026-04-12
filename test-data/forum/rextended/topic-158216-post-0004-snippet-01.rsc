# Source: https://forum.mikrotik.com/t/sms-timestamp-system-date-and-case-sensitive/158216/4
# Post author: @rextended
# Extracted from: code-block

:global a "May/23/2022"
:global b "May/23/2022"
:if ($a <  $b) do={:put "$a <  $b"} else={:put "$a !<  $b"}
:if ($a <= $b) do={:put "$a <= $b"} else={:put "$a !<= $b"}
:if ($a =  $b) do={:put "$a =  $b"} else={:put "$a !=  $b"}
:if ($a >= $b) do={:put "$a >= $b"} else={:put "$a !>= $b"}
:if ($a >  $b) do={:put "$a >  $b"} else={:put "$a !>  $b"}
:if ($a != $b) do={:put "$a != $b"} else={:put "$a !!= $b"}
