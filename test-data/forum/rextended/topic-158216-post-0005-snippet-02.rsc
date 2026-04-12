# Source: https://forum.mikrotik.com/t/sms-timestamp-system-date-and-case-sensitive/158216/5
# Post author: @rextended
# Extracted from: code-block

:put [$engdate2int "may/23/2022"]

:global a [$engdate2int "May/23/2022"]
:global b [$engdate2int "may/23/2022"]
:if ($a <  $b) do={:put "$a <  $b"} else={:put "$a !<  $b"}
:if ($a <= $b) do={:put "$a <= $b"} else={:put "$a !<= $b"}
:if ($a =  $b) do={:put "$a =  $b"} else={:put "$a !=  $b"}
:if ($a >= $b) do={:put "$a >= $b"} else={:put "$a !>= $b"}
:if ($a >  $b) do={:put "$a >  $b"} else={:put "$a !>  $b"}
:if ($a != $b) do={:put "$a != $b"} else={:put "$a !!= $b"}
